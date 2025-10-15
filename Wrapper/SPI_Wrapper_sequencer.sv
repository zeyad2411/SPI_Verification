package SPI_Wrapper_sequencer_pkg;
import SPI_Wrapper_seq_item_pkg::*;
import shared_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class SPI_Wrapper_sequencer extends uvm_sequencer #(SPI_Wrapper_seq_item);
`uvm_component_utils(SPI_Wrapper_sequencer);

 function new(string name = "SPI_Wrapper_sequencer" , uvm_component parent = null);
    super.new(name , parent);  
endfunction

endclass
endpackage