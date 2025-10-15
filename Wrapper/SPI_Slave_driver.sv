package SPI_Slave_driver_pkg;
import uvm_pkg::*;
import SPI_Slave_config_pkg::*;
import SPI_Slave_seq_item_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class SPI_Slave_driver extends uvm_driver #(SPI_Slave_seq_item);
    `uvm_component_utils(SPI_Slave_driver)
    
    virtual SPI_Slave_if SPI_Slave_vif;
    SPI_Slave_seq_item stim_seq_item;
    SPI_Slave_config SPI_Slave_cfg;

    function new(string name = "SPI_Slave_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(SPI_Slave_config)::get(this, "", "CFG", SPI_Slave_cfg)) begin
            `uvm_fatal("build_phase", "Driver - Unable to get configuration object")
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        SPI_Slave_vif = SPI_Slave_cfg.SPI_Slave_vif;
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            stim_seq_item = SPI_Slave_seq_item::type_id::create("stim_seq_item");
            seq_item_port.get_next_item(stim_seq_item);
            SPI_Slave_vif.MOSI = stim_seq_item.MOSI;
            SPI_Slave_vif.rst_n = stim_seq_item.rst_n;
            SPI_Slave_vif.SS_n = stim_seq_item.SS_n;
            SPI_Slave_vif.tx_valid = stim_seq_item.tx_valid;
            SPI_Slave_vif.tx_data = stim_seq_item.tx_data;
            @(negedge SPI_Slave_vif.clk);
            seq_item_port.item_done();
            `uvm_info("run_phase", stim_seq_item.convert2string_stimulus(), UVM_HIGH)
        end
    endtask
endclass
endpackage
