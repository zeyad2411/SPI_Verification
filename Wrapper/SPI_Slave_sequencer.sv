package SPI_Slave_sequencer_pkg;
import SPI_Slave_seq_item_pkg::*;
import shared_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class SPI_Slave_sequencer extends uvm_sequencer #(SPI_Slave_seq_item);
`uvm_component_utils(SPI_Slave_sequencer);

 function new(string name = "SPI_Slave_sequencer" , uvm_component parent = null);
    super.new(name , parent);  
endfunction

endclass
endpackage