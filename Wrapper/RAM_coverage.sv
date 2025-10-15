package RAM_coverage_pkg;
import uvm_pkg::*;
import RAM_monitor_pkg::*;
import RAM_seq_item_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class RAM_coverage extends uvm_component;
    `uvm_component_utils(RAM_coverage)
   
    uvm_analysis_export #(RAM_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(RAM_seq_item) cov_fifo;
    RAM_seq_item seq_item_cov;

    

    covergroup cvr_grp;

    cp_posible_vlaues : coverpoint seq_item_cov.din[9:8]  {
      bins write_addr = {2'b00};
      bins write_data = {2'b01};
      bins read_addr  = {2'b10};
      bins read_data  = {2'b11};
    } 

    cp_trans_type : coverpoint seq_item_cov.din[9:8] iff (seq_item_cov.rx_valid == 1) {
      option.auto_bin_max = 0;
      bins write_data_after_addr = (2'b00 => 2'b01);
      bins read_data_after_addr = (2'b10 => 2'b11);
      bins full_seq = (2'b00 => 2'b01 => 2'b10 => 2'b11);
    }

    cp_rx : coverpoint seq_item_cov.rx_valid {
        bins rx_valid_0 = {0};
        bins rx_valid_1 = {1};
        }

    cp_tx : coverpoint seq_item_cov.tx_valid {
        bins tx_valid_0 = {0};
        bins tx_valid_1 = {1};
        }

    cr : cross cp_posible_vlaues , cp_rx, cp_tx{
        option.cross_auto_bin_max = 0;
        bins read_rx_high = binsof(cp_posible_vlaues.read_data) && binsof(cp_rx.rx_valid_1);
        bins write_rx_high = binsof(cp_posible_vlaues.write_data) && binsof(cp_rx.rx_valid_1);
        bins read_rx_low = binsof(cp_posible_vlaues.read_addr) && binsof(cp_rx.rx_valid_1);
        bins write_rx_low = binsof(cp_posible_vlaues.write_addr) && binsof(cp_rx.rx_valid_1);
        bins read_tx_high = binsof(cp_posible_vlaues.read_data) && binsof(cp_tx.tx_valid_1);

    }
    
      

    endgroup

    function new(string name = "RAM_coverage", uvm_component parent = null);
        super.new(name, parent);
        cvr_grp = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_export = new("cov_export", this);
        cov_fifo = new("cov_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cov_export.connect(cov_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            cov_fifo.get(seq_item_cov);         
            // Sample coverage
            cvr_grp.sample();

        end
    endtask


endclass

endpackage