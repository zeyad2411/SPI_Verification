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


    function new(string name = "SPI_Slave_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        sb_export = new("sb_export", this); 
        sb_fifo = new("sb_fifo", this); 
        
       
    endfunction 

    function void connect_phase(uvm_phase phase); 
        super.connect_phase(phase); 
        sb_export.connect(sb_fifo.analysis_export); 
    endfunction

    task run_phase(uvm_phase phase); 
        super.run_phase(phase); 
        forever begin
            sb_fifo.get(seq_item_sb);
             if( seq_item_sb.rx_valid != seq_item_sb.rx_valid_gm  ||  seq_item_sb.rx_data != seq_item_sb.rx_data_gm ||
              seq_item_sb.MISO != seq_item_sb.MISO_gm || seq_item_sb.cs_sva != seq_item_sb.cs_sva_gm ) begin
					`uvm_error("run_phase", $sformatf("Comparsion Failed , Transaction recieved by the DUT: %s  ",seq_item_sb.convert2string()  ))
					error_count++;
				end
				else begin
					correct_count++; 
					`uvm_info("run_phase",$sformatf("Correct shift_Reg out: %s",seq_item_sb.convert2string()),UVM_HIGH)
				end
            
            
        end
    endtask : run_phase 

   




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