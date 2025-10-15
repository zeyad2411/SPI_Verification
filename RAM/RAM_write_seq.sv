package RAM_write_seq_pkg;
import uvm_pkg::*;
import shared_pkg::*;
import RAM_seq_item_pkg::*;
`include "uvm_macros.svh"
class RAM_write_seq extends uvm_sequence #(RAM_seq_item);
 `uvm_object_utils(RAM_write_seq);
 RAM_seq_item seq_item;

 function new(string name = "RAM_write_seq");
    super.new(name);  
endfunction

task body;
repeat(1000) begin
seq_item = RAM_seq_item::type_id::create("seq_item");
    start_item(seq_item);
    seq_item.r_c.constraint_mode (0);
    seq_item.w_c.constraint_mode (1);
    seq_item.w_r_c.constraint_mode (0);
    seq_item.rx_c.constraint_mode (1);
    seq_item.rst_c.constraint_mode (1);
    assert(seq_item.randomize());
    finish_item(seq_item);
end
endtask
endclass
endpackage