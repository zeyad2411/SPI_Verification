package SPI_Slave_monitor_pkg;
import uvm_pkg::*;
import shared_pkg::*;
import SPI_Slave_config_pkg::*;
import SPI_Slave_seq_item_pkg::*;
`include "uvm_macros.svh"
class SPI_Slave_monitor extends uvm_monitor;
    `uvm_component_utils(SPI_Slave_monitor)
    
    virtual SPI_Slave_if SPI_Slave_vif;
    SPI_Slave_seq_item rsp_seq_item;
    uvm_analysis_port #(SPI_Slave_seq_item) mon_ap;

    function new(string name = "SPI_Slave_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            rsp_seq_item = SPI_Slave_seq_item::type_id::create("rsp_seq_item");
            @(negedge SPI_Slave_vif.clk);
            rsp_seq_item.MOSI = SPI_Slave_vif.MOSI;
            rsp_seq_item.rst_n = SPI_Slave_vif.rst_n;
            rsp_seq_item.SS_n = SPI_Slave_vif.SS_n;
            rsp_seq_item.tx_valid = SPI_Slave_vif.tx_valid;
            rsp_seq_item.tx_data = SPI_Slave_vif.tx_data;
            rsp_seq_item.MISO = SPI_Slave_vif.MISO;
            rsp_seq_item.rx_data = SPI_Slave_vif.rx_data;
            rsp_seq_item.rx_valid = SPI_Slave_vif.rx_valid;
            mon_ap.write(rsp_seq_item);
            `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_HIGH)
        end
    endtask
endclass
endpackage
