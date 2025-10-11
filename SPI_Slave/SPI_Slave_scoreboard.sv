package SPI_Slave_scoreboard_pkg;
import uvm_pkg::*;
import SPI_Slave_monitor_pkg::*;
import SPI_Slave_seq_item_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class SPI_Slave_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(SPI_Slave_scoreboard) 
    uvm_analysis_export #(SPI_Slave_seq_item) sb_export;
    uvm_tlm_analysis_fifo #(SPI_Slave_seq_item) sb_fifo;
    SPI_Slave_seq_item seq_item_sb; 

    int error_count = 0;
    int correct_count = 0; 

    // Reference model state variables
    logic [2:0] ref_cs, ref_ns;  // Using 3-bit logic to match shared_pkg encoding
    logic ref_add_exist;
    logic [3:0] ref_counter_in;
    logic [2:0] ref_counter_out;
    logic [7:0] ref_tx_reg;
    logic ref_start_out;
    logic ref_rx_valid;
    logic [9:0] ref_rx_data;
    logic ref_MISO;

    function new(string name = "SPI_Slave_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        sb_export = new("sb_export", this); 
        sb_fifo = new("sb_fifo", this); 
        
        // Initialize reference model state
        ref_cs = IDLE;
        ref_ns = IDLE;
        ref_add_exist = 0;
        ref_counter_in = 4'b0;
        ref_counter_out = 3'b0;
        ref_tx_reg = 8'b0;
        ref_start_out = 0;
        ref_rx_valid = 0;
        ref_rx_data = 10'b0;
        ref_MISO = 0;
    endfunction 

    function void connect_phase(uvm_phase phase); 
        super.connect_phase(phase); 
        sb_export.connect(sb_fifo.analysis_export); 
    endfunction

    task run_phase(uvm_phase phase); 
        super.run_phase(phase); 
        forever begin
            sb_fifo.get(seq_item_sb);
            SPI_ref_model(seq_item_sb);
            check_outputs(seq_item_sb);
        end
    endtask : run_phase 

    // Reference model task - mimics the golden RTL module
    task SPI_ref_model(SPI_Slave_seq_item seq_item_chk);
        // Step 1: State memory update (sequential logic)
        if (!seq_item_chk.rst_n) begin
            ref_cs = IDLE;
        end
        else begin
            ref_cs = ref_ns;
        end

        // Step 2: Next state logic (combinational logic)
        case (ref_cs)
            IDLE: begin
                ref_ns = (seq_item_chk.SS_n == 0) ? CHK_CMD : IDLE;
            end
            
            CHK_CMD: begin
                if (seq_item_chk.SS_n == 1) 
                    ref_ns = IDLE;
                else if (seq_item_chk.MOSI == 0)
                    ref_ns = WRITE;
                else
                    ref_ns = (ref_add_exist) ? READ_DATA : READ_ADD;
            end

            WRITE: begin
                ref_ns = (seq_item_chk.SS_n == 1) ? IDLE : WRITE;
            end
            
            READ_ADD: begin
                ref_ns = (seq_item_chk.SS_n == 1) ? IDLE : READ_ADD;
            end
            
            READ_DATA: begin
                ref_ns = (seq_item_chk.SS_n == 1) ? IDLE : READ_DATA;
            end
            
            default: begin
                ref_ns = IDLE;
            end
        endcase

        // Step 3: Output logic and counters (sequential logic)
        if (!seq_item_chk.rst_n) begin
            ref_add_exist = 0;
            ref_counter_in = 4'b0;
            ref_counter_out = 3'b0;
            ref_rx_valid = 0;
            ref_rx_data = 10'b0;
            ref_MISO = 0;
            ref_start_out = 0;
            ref_tx_reg = 8'b0;
        end
        else begin
            // Default: rx_valid is pulsed for one cycle
            ref_rx_valid = 0;
            
            if (seq_item_chk.SS_n) begin
                // When SS_n is high (idle), reset counters
                ref_counter_in = 4'b0;
                ref_counter_out = 3'b0;
                ref_start_out = 0;
            end
            else begin
                // SS_n is low (active transaction)
                case (ref_cs)
                    IDLE: begin
                        ref_counter_in = 0;
                        ref_counter_out = 0;
                    end
                    
                    WRITE: begin
                        // Shift in MOSI data
                        if (ref_counter_in < 10) begin
                            ref_rx_data = {ref_rx_data[8:0], seq_item_chk.MOSI};
                            ref_counter_in = ref_counter_in + 1;
                        end
                        
                        // Assert rx_valid when 10 bits received
                        if (ref_counter_in == 9)
                            ref_rx_valid = 1;
                    end
                    
                    READ_ADD: begin
                        // Shift in MOSI data
                        if (ref_counter_in < 10) begin
                            ref_rx_data = {ref_rx_data[8:0], seq_item_chk.MOSI};
                            ref_counter_in = ref_counter_in + 1;
                        end
                        
                        // Assert rx_valid when 10 bits received
                        if (ref_counter_in == 9)
                            ref_rx_valid = 1;
                        
                        // Set address exists flag
                        ref_add_exist = 1;
                    end
                    
                    READ_DATA: begin
                        // Shift in MOSI data
                        if (ref_counter_in < 10) begin
                            ref_rx_data = {ref_rx_data[8:0], seq_item_chk.MOSI};
                            ref_counter_in = ref_counter_in + 1;
                        end
                        
                        // Assert rx_valid when 10 bits received
                        if (ref_counter_in == 9)
                            ref_rx_valid = 1;
                        
                        // Clear address exists flag (non-blocking for task)
                        ref_add_exist = 0;
                        
                        // Load tx_data when tx_valid is high
                        if (seq_item_chk.tx_valid) begin
                            ref_tx_reg = seq_item_chk.tx_data;
                            ref_start_out = 1;
                        end
                    end
                    
                    default: begin
                        // Do nothing
                    end
                endcase
                
                // MISO shift-out handling
                if (ref_start_out && (ref_counter_out < 8)) begin
                    ref_MISO = ref_tx_reg[7 - ref_counter_out];
                    ref_counter_out = ref_counter_out + 1;
                end
                else if (ref_counter_out >= 8) begin
                    ref_start_out = 0;
                end
            end
        end
    endtask: SPI_ref_model

    function void check_outputs(SPI_Slave_seq_item seq_item_chk);
        bit error_found = 0;

        // Check rx_valid
        if (seq_item_chk.rx_valid !== ref_rx_valid) begin
            `uvm_error("RX_VALID_MISMATCH", 
                $sformatf("rx_valid mismatch! DUT: %0b, REF: %0b, Time: %0t", 
                seq_item_chk.rx_valid, ref_rx_valid, $time));
            error_found = 1;
        end

        // Check rx_data (only when rx_valid is high)
        if (ref_rx_valid || seq_item_chk.rx_valid) begin
            if (seq_item_chk.rx_data !== ref_rx_data) begin
                `uvm_error("RX_DATA_MISMATCH", 
                    $sformatf("rx_data mismatch! DUT: 0x%0h, REF: 0x%0h, Time: %0t", 
                    seq_item_chk.rx_data, ref_rx_data, $time));
                error_found = 1;
            end
        end

        // Check MISO (only when not in IDLE and SS_n is low)
        if (!seq_item_chk.SS_n && ref_cs != IDLE) begin
            if (seq_item_chk.MISO !== ref_MISO) begin
                `uvm_error("MISO_MISMATCH", 
                    $sformatf("MISO mismatch! DUT: %0b, REF: %0b, State: %s, Time: %0t", 
                    seq_item_chk.MISO, ref_MISO, get_state_name(ref_cs), $time));
                error_found = 1;
            end
        end

        if (error_found) begin
            error_count++;
            //`uvm_info("SCOREBOARD", 
               // $sformatf("Transaction FAILED | SS_n: %0b, MOSI: %0b, State: %s, rst_n: %0b", 
                //seq_item_chk.SS_n, seq_item_chk.MOSI, get_state_name(ref_cs), seq_item_chk.rst_n), UVM_HIGH);
        end
        else begin
            correct_count++;
            //`uvm_info("SCOREBOARD", 
               // $sformatf("Transaction PASSED | rx_valid: %0b, rx_data: 0x%0h, MISO: %0b, State: %s", 
                //ref_rx_valid, ref_rx_data, ref_MISO, get_state_name(ref_cs)), UVM_HIGH);
        end
    endfunction

    // Helper function to convert state encoding to string
    function string get_state_name(logic [2:0] state);
        case (state)
            IDLE:      return "IDLE";
            WRITE:     return "WRITE";
            CHK_CMD:   return "CHK_CMD";
            READ_ADD:  return "READ_ADD";
            READ_DATA: return "READ_DATA";
            default:   return "UNKNOWN";
        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("REPORT", "==============================================", UVM_LOW);
        `uvm_info("REPORT", "        SCOREBOARD FINAL REPORT", UVM_LOW);
        `uvm_info("REPORT", "==============================================", UVM_LOW);
        `uvm_info("REPORT", $sformatf("Total Successful Transactions: %0d", correct_count), UVM_LOW);
        `uvm_info("REPORT", $sformatf("Total Failed Transactions    : %0d", error_count), UVM_LOW);
        `uvm_info("REPORT", "==============================================", UVM_LOW);
        
        if (error_count == 0) begin
            `uvm_info("REPORT", "***          TEST PASSED          ***", UVM_LOW);
        end
        else begin
            `uvm_error("REPORT", "***          TEST FAILED          ***");
        end
        `uvm_info("REPORT", "==============================================", UVM_LOW);
    endfunction
endclass : SPI_Slave_scoreboard
endpackage : SPI_Slave_scoreboard_pkg