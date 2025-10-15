package SPI_Wrapper_agent_pkg;
import SPI_Wrapper_monitor_pkg::*;
import SPI_Wrapper_driver_pkg::*;
import SPI_Wrapper_sequencer_pkg::*;
import SPI_Wrapper_config_pkg::*;
import shared_pkg::*;
import SPI_Wrapper_seq_item_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class SPI_Wrapper_agent extends uvm_agent;
    `uvm_component_utils(SPI_Wrapper_agent)
    
    SPI_Wrapper_sequencer sqr;
    SPI_Wrapper_driver drv;
    SPI_Wrapper_monitor mon;
    SPI_Wrapper_config SPI_Wrapper_cfg;
    uvm_analysis_port #(SPI_Wrapper_seq_item) agt_ap;

    function new(string name = "SPI_Wrapper_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(SPI_Wrapper_config)::get(this, "", "CFG_W", SPI_Wrapper_cfg)) begin
            `uvm_fatal("build_phase", "Unable to get configuration object")
        end

        mon = SPI_Wrapper_monitor::type_id::create("mon", this);
        agt_ap = new("agt_ap", this);
        if (SPI_Wrapper_cfg.is_active == UVM_ACTIVE) begin
        sqr = SPI_Wrapper_sequencer::type_id::create("sqr", this);
        drv = SPI_Wrapper_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.SPI_Wrapper_vif = SPI_Wrapper_cfg.SPI_Wrapper_vif;
        mon.SPI_Wrapper_gm_vif = SPI_Wrapper_cfg.SPI_Wrapper_GM_vif;
        mon.mon_ap.connect(agt_ap);
        
        if (SPI_Wrapper_cfg.is_active == UVM_ACTIVE) begin
        drv.SPI_Wrapper_vif = SPI_Wrapper_cfg.SPI_Wrapper_vif;
        drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass
endpackage