package SPI_Wrapper_rst_seq_pkg;
import uvm_pkg::*;
import shared_pkg::*;
import SPI_Wrapper_seq_item_pkg::*;
`include "uvm_macros.svh"
class SPI_Wrapper_rst_seq extends uvm_sequence #(SPI_Wrapper_seq_item);

`uvm_object_utils (SPI_Wrapper_rst_seq) ;

    SPI_Wrapper_seq_item seq_item ;


 function new ( string name = "SPI_Wrapper_rst_seq") ;
   super.new (name) ;
 endfunction 

 task body; 
 seq_item = SPI_Wrapper_seq_item::type_id::create("seq_item");
 start_item(seq_item) ;
 seq_item.rst_n = 0 ;
 finish_item(seq_item);
 endtask 
endclass
endpackage