package SPI_Slave_coverage_pkg;
import uvm_pkg::*;
import SPI_Slave_monitor_pkg::*;
import SPI_Slave_seq_item_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class SPI_Slave_coverage extends uvm_component;
    `uvm_component_utils(SPI_Slave_coverage)
   
    uvm_analysis_export #(SPI_Slave_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(SPI_Slave_seq_item) cov_fifo;
    SPI_Slave_seq_item seq_item_cov;

    // Variables to track SS_n transitions for sequence coverage
    logic prev_SS_n = 1;
    int ss_n_low_count = 0;
    bit normal_transaction_complete = 0;
    bit extended_transaction_complete = 0;

    // Variable to track MOSI command bits (first 3 bits of transaction)
    logic [2:0] mosi_cmd = 3'b000;
    int mosi_bit_count = 0;
    bit mosi_cmd_valid = 0;  // NEW: Flag to indicate valid command capture

    covergroup cvr_grp;

        // Constraint 1: Coverpoints on rx_data[9:8] - all possible values and transitions
        rx_data_cvp: coverpoint seq_item_cov.rx_data[9:8] {
            bins addr_or_cmd   = {2'b00};  // Address or command
            bins write_data    = {2'b01};  // Write data
            bins read_addr     = {2'b10};  // Read address
            bins read_data     = {2'b11};  // Read data
        }

        rx_valid_cvp: coverpoint seq_item_cov.rx_valid {
            bins valid   = {1};
            bins invalid = {0};
        }

        // Transition coverage for rx_data[9:8]
        rx_data_trans_cvp: coverpoint seq_item_cov.rx_data[9:8] iff (seq_item_cov.rx_valid == 1) {
            bins addr_to_write     = (2'b00 => 2'b01);  // WRITE_ADDR -> WRITE_DATA
            bins addr_to_read_addr = (2'b00 => 2'b10);  // WRITE_ADDR -> READ_ADDR
            bins addr_to_read_data = (2'b00 => 2'b11);  // WRITE_ADDR -> READ_DATA
            bins write_to_addr     = (2'b01 => 2'b00);  // WRITE_DATA -> WRITE_ADDR
            bins write_to_read     = (2'b01 => 2'b10);  // WRITE_DATA -> READ_ADDR
            bins read_addr_to_data = (2'b10 => 2'b11);  // READ_ADDR -> READ_DATA
            bins read_data_to_addr = (2'b11 => 2'b00);  // READ_DATA -> WRITE_ADDR
            bins read_data_to_read_addr = (2'b11 => 2'b10);  // READ_DATA -> READ_ADDR
            bins same_addr         = (2'b00 => 2'b00);  // Repeated address
            bins same_write        = (2'b01 => 2'b01);  // Repeated write
            bins same_read_addr    = (2'b10 => 2'b10);  // Repeated read address
            bins same_read_data    = (2'b11 => 2'b11);  // Repeated read data
        }

        // Constraint 2: SS_n transaction duration coverage
        SS_n_cvp: coverpoint seq_item_cov.SS_n {
            bins high = {1};
            bins low  = {0};
            bins high_to_low = (1 => 0);  // Transaction start
            bins low_to_high = (0 => 1);  // Transaction end
        }

        // Normal transaction: 1 -> 0 [*13] -> 1
        normal_trans_cvp: coverpoint normal_transaction_complete {
            bins normal_transaction_done = {1};
        }

        // Extended transaction (READ_DATA): 1 -> 0 [*23] -> 1
        extended_trans_cvp: coverpoint extended_transaction_complete {
            bins extended_transaction_done = {1};
        }

        // Constraint 3: MOSI command validation (first 3 bits)
        // ONLY sample when we have a valid command captured
        MOSI_cvp: coverpoint mosi_cmd iff (mosi_cmd_valid) {
            option.auto_bin_max = 0;
            bins write_addr  = {3'b000};  // Write Address
            bins write_data  = {3'b001};  // Write Data
            bins read_addr   = {3'b110};  // Read Address
            bins read_data   = {3'b111};  // Read Data
            // Invalid commands
            illegal_bins invalid_cmd = {3'b010, 3'b011, 3'b100, 3'b101};
        }

        // Constraint 4: Cross coverage between SS_n and MOSI
        // ONLY cross when MOSI command is valid
        cross SS_n_cvp, MOSI_cvp iff (mosi_cmd_valid) {
            option.cross_auto_bin_max = 0;
            // Only cover meaningful combinations during active transactions
            // When SS_n is low (active), all valid commands should be covered
            bins write_addr_active  = binsof(SS_n_cvp.low) && binsof(MOSI_cvp.write_addr);
            bins write_data_active  = binsof(SS_n_cvp.low) && binsof(MOSI_cvp.write_data);
            bins read_addr_active   = binsof(SS_n_cvp.low) && binsof(MOSI_cvp.read_addr);
            bins read_data_active   = binsof(SS_n_cvp.low) && binsof(MOSI_cvp.read_data);
            
            // When SS_n is high (inactive), MOSI commands are don't care
            // Exclude these to focus on legal operation scenarios
            ignore_bins inactive_dont_care = binsof(SS_n_cvp.high);
        }

    endgroup

    function new(string name = "SPI_Slave_coverage", uvm_component parent = null);
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
            
            // Track SS_n sequence for transaction duration
            track_ss_n_sequence();
            
            // Track MOSI command bits (first 3 bits of transaction)
            track_mosi_command();
            
            // Sample coverage
            cvr_grp.sample();
            
            // Update previous state
            prev_SS_n = seq_item_cov.SS_n;
        end
    endtask

    // Function to track SS_n sequences for normal and extended transactions
    function void track_ss_n_sequence();
        // Detect start of transaction (1 -> 0)
        if (prev_SS_n == 1 && seq_item_cov.SS_n == 0) begin
            ss_n_low_count = 1;  // Start counting
            normal_transaction_complete = 0;
            extended_transaction_complete = 0;
            mosi_bit_count = 0;  // Reset MOSI bit counter
            mosi_cmd_valid = 0;  // Reset valid flag
        end
        // Count consecutive low cycles
        else if (seq_item_cov.SS_n == 0 && prev_SS_n == 0) begin
            ss_n_low_count++;
        end
        // Detect end of transaction (0 -> 1)
        else if (prev_SS_n == 0 && seq_item_cov.SS_n == 1) begin
            // Check if it matches normal transaction pattern (13 cycles low)
            if (ss_n_low_count == 12) begin
                normal_transaction_complete = 1;
                `uvm_info("COVERAGE", $sformatf("Normal transaction completed: SS_n low for %0d cycles", ss_n_low_count), UVM_HIGH)
            end
            // Check if it matches extended transaction pattern (23 cycles low)
            else if (ss_n_low_count == 22) begin
                extended_transaction_complete = 1;
                `uvm_info("COVERAGE", $sformatf("Extended transaction completed: SS_n low for %0d cycles", ss_n_low_count), UVM_HIGH)
            end
            ss_n_low_count = 0;  // Reset counter
            mosi_cmd_valid = 0;  // Invalidate command after transaction ends
        end
    endfunction

    // Function to track MOSI command (first 3 bits of transaction)
    function void track_mosi_command();
        // When SS_n goes low, start capturing MOSI bits
        if (prev_SS_n == 1 && seq_item_cov.SS_n == 0) begin
            mosi_bit_count = 0;
            mosi_cmd = 3'b000;
            mosi_cmd_valid = 0;
        end 
        // Capture MOSI bits while SS_n is low and we haven't captured all 3 bits yet
        else if (seq_item_cov.SS_n == 0 && mosi_bit_count < 3) begin
            mosi_cmd[2 - mosi_bit_count] = seq_item_cov.MOSI;  // MSB first
            mosi_bit_count++;
            
            // Mark command as valid once we've captured all 3 bits
            if (mosi_bit_count == 3) begin
                mosi_cmd_valid = 1;
                `uvm_info("COVERAGE", $sformatf("MOSI command captured: %3b", mosi_cmd), UVM_HIGH)
            end
        end
    endfunction

endclass

endpackage