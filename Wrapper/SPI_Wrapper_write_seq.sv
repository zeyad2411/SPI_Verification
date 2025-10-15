package SPI_Wrapper_write_seq_pkg;
    import SPI_Wrapper_seq_item_pkg::*;
    import shared_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class SPI_Wrapper_write_seq extends uvm_sequence #(SPI_Wrapper_seq_item);
        `uvm_object_utils(SPI_Wrapper_write_seq)
        
        SPI_Wrapper_seq_item seq_item;

        function new(string name = "SPI_Wrapper_write_seq");
            super.new(name);
        endfunction

        task body;
            repeat (10000) begin
                seq_item = SPI_Wrapper_seq_item::type_id::create("seq_item");
                start_item(seq_item);
                seq_item.read_only_seq_c.constraint_mode(0);
                seq_item.write_only_seq_c.constraint_mode(1);
                seq_item.mixed_rw_seq_c.constraint_mode(0);
                assert(seq_item.randomize());
                finish_item(seq_item);
            end
        endtask
    endclass

endpackage
