package RAM_agent_pkg;
import RAM_monitor_pkg::*;
import RAM_driver_pkg::*;
import RAM_sequencer_pkg::*;
import RAM_config_pkg::*;
import shared_pkg::*;
import RAM_seq_item_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class RAM_agent extends uvm_agent;
    `uvm_component_utils(RAM_agent)
    
    RAM_sequencer sqr;
    RAM_driver drv;
    RAM_monitor mon;
    RAM_config RAM_cfg;
    uvm_analysis_port #(RAM_seq_item) agt_ap;

    function new(string name = "RAM_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(RAM_config)::get(this, "", "CFG", RAM_cfg)) begin
            `uvm_fatal("build_phase", "Unable to get configuration object")
        end

        mon = RAM_monitor::type_id::create("mon", this);
        agt_ap = new("agt_ap", this);
        if (RAM_cfg.is_active == UVM_ACTIVE) begin
        sqr = RAM_sequencer::type_id::create("sqr", this);
        drv = RAM_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.RAM_vif = RAM_cfg.RAM_vif;
        mon.mon_ap.connect(agt_ap);
        
        if (RAM_cfg.is_active == UVM_ACTIVE) begin
        drv.RAM_vif = RAM_cfg.RAM_vif;
        drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass
endpackage