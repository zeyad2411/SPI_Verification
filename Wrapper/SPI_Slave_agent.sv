package SPI_Slave_agent_pkg;
import SPI_Slave_monitor_pkg::*;
import SPI_Slave_driver_pkg::*;
import SPI_Slave_sequencer_pkg::*;
import SPI_Slave_config_pkg::*;
import shared_pkg::*;
import SPI_Slave_seq_item_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class SPI_Slave_agent extends uvm_agent;
    `uvm_component_utils(SPI_Slave_agent)
    
    SPI_Slave_sequencer sqr;
    SPI_Slave_driver drv;
    SPI_Slave_monitor mon;
    SPI_Slave_config SPI_Slave_cfg;
    uvm_analysis_port #(SPI_Slave_seq_item) agt_ap;

    function new(string name = "SPI_Slave_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(SPI_Slave_config)::get(this, "", "CFG_S", SPI_Slave_cfg)) begin
            `uvm_fatal("build_phase", "Unable to get configuration object")
        end

        mon = SPI_Slave_monitor::type_id::create("mon", this);
        agt_ap = new("agt_ap", this);
        if (SPI_Slave_cfg.is_active == UVM_ACTIVE) begin
        sqr = SPI_Slave_sequencer::type_id::create("sqr", this);
        drv = SPI_Slave_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.SPI_Slave_vif = SPI_Slave_cfg.SPI_Slave_vif;
        mon.SPI_gm_vif = SPI_Slave_cfg.SPI_gm_vif;
        mon.mon_ap.connect(agt_ap);
        
        if (SPI_Slave_cfg.is_active == UVM_ACTIVE) begin
        drv.SPI_Slave_vif = SPI_Slave_cfg.SPI_Slave_vif;
        drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass
endpackage