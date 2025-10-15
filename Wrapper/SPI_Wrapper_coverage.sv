package SPI_Wrapper_coverage_pkg;
import uvm_pkg::*;
import SPI_Wrapper_monitor_pkg::*;
import SPI_Wrapper_seq_item_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class SPI_Wrapper_coverage extends uvm_component;
    `uvm_component_utils(SPI_Wrapper_coverage)
   
    uvm_analysis_export #(SPI_Wrapper_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(SPI_Wrapper_seq_item) cov_fifo;
    SPI_Wrapper_seq_item seq_item_cov;


    covergroup cvr_grp;

        // Constraint 1: SS_n transaction duration coverage
        SS_n_cvp: coverpoint seq_item_cov.SS_n {
            bins high = {1};
            bins low  = {0};
            bins high_to_low = (1 => 0);  // Transaction start
            bins low_to_high = (0 => 1);  // Transaction end
        }

    endgroup

    function new(string name = "SPI_Wrapper_coverage", uvm_component parent = null);
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