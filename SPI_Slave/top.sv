import uvm_pkg::*;
`include "uvm_macros.svh"
import SPI_Slave_test_pkg::*; // bn7ot el test gwa el top
import shared_pkg::*;
module top();
 bit clk;
  // Clock generation
  initial begin
  clk=0;
  forever 
  #5 clk = ~clk;
end
  // Instantiate the interface and DUT
  SPI_Slave_if SPI_Slave_if (clk);
  SPI_gm_if SPI_gm_if (clk);
  SLAVE_GM GM (
    .clk(SPI_Slave_if.clk),
    .rst_n(SPI_Slave_if.rst_n),
    .MOSI(SPI_Slave_if.MOSI),
    .SS_n(SPI_Slave_if.SS_n),
    .tx_valid(SPI_Slave_if.tx_valid),
    .tx_data(SPI_Slave_if.tx_data),

    .rx_data(SPI_gm_if.rx_data_gm),
    .rx_valid(SPI_gm_if.rx_valid_gm),
    .MISO(SPI_gm_if.MISO_gm),
    .cs_sva(SPI_gm_if.cs_sva_gm)
  );

  SLAVE DUT (
    .clk(SPI_Slave_if.clk),
    .rst_n(SPI_Slave_if.rst_n),
    .MOSI(SPI_Slave_if.MOSI),
    .SS_n(SPI_Slave_if.SS_n),
    .tx_valid(SPI_Slave_if.tx_valid),
    .tx_data(SPI_Slave_if.tx_data),
    .rx_data(SPI_Slave_if.rx_data),
    .rx_valid(SPI_Slave_if.rx_valid),
    .MISO(SPI_Slave_if.MISO),
    .cs_sva(SPI_Slave_if.cs_sva)
  );


  bind SLAVE SPI_Slave_SVA SVA (    
    .clk(SPI_Slave_if.clk),
    .rst_n(SPI_Slave_if.rst_n),
    .MOSI(SPI_Slave_if.MOSI),
    .SS_n(SPI_Slave_if.SS_n),
    .tx_valid(SPI_Slave_if.tx_valid),
    .tx_data(SPI_Slave_if.tx_data),
    .rx_data(SPI_Slave_if.rx_data),
    .rx_valid(SPI_Slave_if.rx_valid),
    .MISO(SPI_Slave_if.MISO),
    .cs_sva(SPI_Slave_if.cs_sva) // connect the DUT state signal to the SVA
    );
  // run test using run_test task
  initial begin
  uvm_config_db#(virtual SPI_Slave_if)::set(null , "uvm_test_top" , "SPI_Slave_IF" , SPI_Slave_if);
  uvm_config_db#(virtual SPI_gm_if)::set(null , "uvm_test_top" , "SPI_gm_IF" , SPI_gm_if);
  run_test("SPI_Slave_test");
  end

endmodule