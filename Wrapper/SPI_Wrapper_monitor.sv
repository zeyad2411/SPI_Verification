package SPI_Wrapper_monitor_pkg;
    import SPI_Wrapper_seq_item_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"   
    class SPI_Wrapper_monitor extends uvm_monitor;
        `uvm_component_utils(SPI_Wrapper_monitor)

        virtual SPI_Wrapper_if SPI_Wrapper_vif; // virtual interface
        virtual SPI_Wrapper_GM_if SPI_Wrapper_gm_vif; // virtual interface of the golden model
        SPI_Wrapper_seq_item rsp_seq_item_main; // main sequence item used for reference model in scoreboard and for coverage collector
        SPI_Wrapper_seq_item rsp_seq_item_next; // sequence item used for next state task in scoreboard
        uvm_analysis_port #(SPI_Wrapper_seq_item) mon_ap;

        function new(string name = "SPI_Wrapper_monitor", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // building share point
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon_ap = new("mon_ap", this);
        endfunction
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                rsp_seq_item_main = SPI_Wrapper_seq_item::type_id::create("rsp_seq_item_main");
                    begin
                        @(negedge SPI_Wrapper_vif.clk); // negedge
                        rsp_seq_item_main.rst_n = SPI_Wrapper_vif.rst_n;
                        rsp_seq_item_main.MOSI = SPI_Wrapper_vif.MOSI;
                        rsp_seq_item_main.SS_n = SPI_Wrapper_vif.SS_n;
                        rsp_seq_item_main.MISO = SPI_Wrapper_vif.MISO;
                        rsp_seq_item_main.MISO_gm = SPI_Wrapper_gm_vif.MISO_gm; // golden model signal from interface of the golden model
                        mon_ap.write(rsp_seq_item_main);
                        `uvm_info("run_phase", rsp_seq_item_main.convert2string(), UVM_HIGH);
                    end
            end
        endtask
    endclass
endpackage