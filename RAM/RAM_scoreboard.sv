package RAM_scoreboard_pkg;
import uvm_pkg::*;
import RAM_monitor_pkg::*;
import RAM_seq_item_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class RAM_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(RAM_scoreboard) 
    uvm_analysis_export #(RAM_seq_item) sb_export;
    uvm_tlm_analysis_fifo #(RAM_seq_item) sb_fifo;
    RAM_seq_item seq_item_sb; 

    int error_count = 0;
    int correct_count = 0; 

    logic [7:0] dout_ref;
    logic      tx_valid_ref;

    reg [7:0] MEM_ref [255:0];

    reg [7:0] Rd_Addr_ref, Wr_Addr_ref;

   

    function new(string name = "RAM_scoreboard", uvm_component parent = null);
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
            RAM_ref_model(seq_item_sb);
            if(seq_item_sb.dout != dout_ref || seq_item_sb.tx_valid != tx_valid_ref ) begin
					`uvm_error("run_phase", $sformatf("Comparsion Failed , Transaction recieved by the DUT: %s While
						the reference out: dout_ref = 0b%0b , tx_valid_ref = 0b%0b ",seq_item_sb.convert2string(),dout_ref , tx_valid_ref   ))
					error_count++;
				end
				else begin
					correct_count++; 
					`uvm_info("run_phase",$sformatf("Correct shift_Reg out: %s",seq_item_sb.convert2string()),UVM_HIGH)
				end
            
        end
    endtask : run_phase 

    task RAM_ref_model(RAM_seq_item seq_item_sb);
      
	if (!seq_item_sb.rst_n) begin 
		tx_valid_ref = 1'b0; 
		dout_ref     = 8'b0;
        Rd_Addr_ref  = 8'b0;
        Wr_Addr_ref  = 8'b0;
	end 

    else begin 
        tx_valid_ref = 1'b0; 
	   
       if (seq_item_sb.rx_valid) begin 

		if (seq_item_sb.din[9:8] == 2'b00  )
			Wr_Addr_ref = seq_item_sb.din[7:0];
        else if (seq_item_sb.din[9:8] == 2'b01)
			MEM_ref[Wr_Addr_ref] = seq_item_sb.din[7:0];
        else if (seq_item_sb.din[9:8] == 2'b10 )
            Rd_Addr_ref = seq_item_sb.din[7:0];
		else if (seq_item_sb.din[9:8] == 2'b11) begin 
			tx_valid_ref = 1'b1;
			dout_ref     = MEM_ref[Rd_Addr_ref];
		end
	end 
    end
endtask


    

    

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
endclass : RAM_scoreboard
endpackage : RAM_scoreboard_pkg