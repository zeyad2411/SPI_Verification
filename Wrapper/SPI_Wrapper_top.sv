import SPI_Wrapper_test_pkg::*;
import SPI_Wrapper_env_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

module SPI_Wrapper_top();
    bit clk;

    initial begin
        forever #10 clk = ~clk;
    end

    // Interfaces
    SPI_Wrapper_if SPI_Wrapperif (clk);
    SPI_Slave_if SPI_Slaveif (clk);
    RAM_if RAMif (clk);
    SPI_Wrapper_GM_if Wrapper_GM_if(clk);
    SPI_gm_if SPI_gm_if (clk);

    // DUT Instantiation
    SPI_Wrapper DUT (
        .clk(SPI_Wrapperif.clk),
        .rst_n(SPI_Wrapperif.rst_n),
        .MOSI(SPI_Wrapperif.MOSI),
        .SS_n(SPI_Wrapperif.SS_n),
        .MISO(SPI_Wrapperif.MISO)
    );

    // Golden Model Instantiation
    SPI_Wrapper_GM Wrapper_GM (
        .clk(SPI_Wrapperif.clk),
        .rst_n(SPI_Wrapperif.rst_n),
        .MOSI(SPI_Wrapperif.MOSI),
        .SS_n(SPI_Wrapperif.SS_n),

        .MISO(Wrapper_GM_if.MISO_gm) 
    );

    // Binding assertions at wrapper level
    bind SPI_Wrapper SPI_Wrapper_SVA SPI_Wrapper_assertions (
        .clk(clk),
        .MOSI(MOSI),
        .rst_n(rst_n),
        .SS_n(SS_n),
        .MISO(MISO),
        .cs(cs_sva)
    );

 
  SLAVE_GM GM (
    .clk(clk),
    .rst_n(Wrapper_GM.rst_n),
    .MOSI(Wrapper_GM.MOSI),
    .SS_n(Wrapper_GM.SS_n),
    .tx_valid(Wrapper_GM.tx_valid),
    .tx_data(Wrapper_GM.tx_data),

    .rx_data(SPI_gm_if.rx_data_gm),
    .rx_valid(SPI_gm_if.rx_valid_gm),
    .MISO(SPI_gm_if.MISO_gm),
    .cs_sva(SPI_gm_if.cs_sva_gm)
  );
    

    // UVM Configuration Database
    initial begin
        uvm_config_db #(virtual SPI_Wrapper_if)::set(null, "uvm_test_top", "SPI_Wrapper_V", SPI_Wrapperif);
        uvm_config_db #(virtual SPI_Wrapper_GM_if)::set(null, "uvm_test_top", "SPI_Wrapper_GM_V", Wrapper_GM_if);
        uvm_config_db#(virtual SPI_gm_if)::set(null , "uvm_test_top" , "SPI_gm_IF" , SPI_gm_if);
        uvm_config_db #(virtual SPI_Slave_if)::set(null, "uvm_test_top", "SPI_Slave_V", SPI_Slaveif);
        uvm_config_db #(virtual RAM_if)::set(null, "uvm_test_top", "RAM_V", RAMif);
        run_test ("SPI_Wrapper_test");
    end

    //=============================
    // Slave Interface Connections (Passive Monitoring)
    //=============================
    // Clock is already connected through interface constructor
    assign SPI_Slaveif.rst_n     = SPI_Wrapperif.rst_n;
    assign SPI_Slaveif.MOSI      = SPI_Wrapperif.MOSI;
    assign SPI_Slaveif.SS_n      = SPI_Wrapperif.SS_n;  
    assign SPI_Slaveif.MISO      = SPI_Wrapperif.MISO;
    
    // Internal signals from DUT
    assign SPI_Slaveif.tx_valid  = DUT.tx_valid;
    assign SPI_Slaveif.tx_data   = DUT.tx_data;
    assign SPI_Slaveif.rx_valid  = DUT.rx_valid;
    assign SPI_Slaveif.rx_data   = DUT.rx_data;

    assign SPI_Slaveif.cs_sva    = DUT.cs_sva;  // FSM state for monitoring

    //=============================
    // RAM Interface Connections (Passive Monitoring)
    //=============================
    // Clock is already connected through interface constructor
    assign RAMif.rst_n           = DUT.rst_n;
    assign RAMif.rx_valid        = DUT.rx_valid;
    assign RAMif.din             = DUT.rx_data;
    assign RAMif.tx_valid        = DUT.tx_valid;
    assign RAMif.dout            = DUT.tx_data;

endmodule