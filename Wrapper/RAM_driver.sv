package RAM_driver_pkg;
import uvm_pkg::*;
import RAM_config_pkg::*;
import RAM_seq_item_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class RAM_driver extends uvm_driver #(RAM_seq_item);
    `uvm_component_utils(RAM_driver)
    
    virtual RAM_if RAM_vif;
    RAM_seq_item stim_seq_item;
    RAM_config RAM_cfg;

    function new(string name = "RAM_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(RAM_config)::get(this, "", "CFG", RAM_cfg)) begin
            `uvm_fatal("build_phase", "Driver - Unable to get configuration object")
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        RAM_vif = RAM_cfg.RAM_vif;
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            stim_seq_item = RAM_seq_item::type_id::create("stim_seq_item");
            seq_item_port.get_next_item(stim_seq_item);
            RAM_vif.din = stim_seq_item.din;
            RAM_vif.rx_valid = stim_seq_item.rx_valid;
            RAM_vif.rst_n = stim_seq_item.rst_n;
            
            
            
            @(negedge RAM_vif.clk);
            seq_item_port.item_done();
            `uvm_info("run_phase", stim_seq_item.convert2string_stimulus(), UVM_HIGH)
        end
    endtask
endclass
endpackage
