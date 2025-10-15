package SPI_Wrapper_driver_pkg;
    import shared_pkg::*;
    import SPI_Wrapper_config_pkg::*;
    import SPI_Wrapper_seq_item_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"    
    class SPI_Wrapper_driver extends uvm_driver #(SPI_Wrapper_seq_item);
        `uvm_component_utils(SPI_Wrapper_driver)

        virtual SPI_Wrapper_if SPI_Wrapper_vif; // virtual interface
        SPI_Wrapper_seq_item stim_seq_item; // sequence item

        function new(string name = "SPI_Wrapper_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                stim_seq_item = SPI_Wrapper_seq_item::type_id::create("stim_seq_item");
                seq_item_port.get_next_item(stim_seq_item);
                SPI_Wrapper_vif.rst_n = stim_seq_item.rst_n;
                SPI_Wrapper_vif.MOSI = stim_seq_item.MOSI;
                SPI_Wrapper_vif.SS_n = stim_seq_item.SS_n;
                @(negedge SPI_Wrapper_vif.clk);
                seq_item_port.item_done();
            `uvm_info("run_phase", stim_seq_item.convert2string_stimulus(), UVM_HIGH)
            end
        endtask
    endclass
endpackage
            