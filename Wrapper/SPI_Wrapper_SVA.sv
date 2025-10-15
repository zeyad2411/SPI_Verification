import shared_pkg::*;

module SPI_Wrapper_SVA (
    // Interface signals from the SPI Slave DUT
    input bit        clk,
    input logic      MOSI,
    input logic      rst_n,
    input logic      SS_n,
    input logic      MISO,
    // FSM current state from the DUT for checking transitions
    input wire [2:0] cs
);

AP1_reset_outputs_low_assert: assert property (
    @(posedge clk)
    !rst_n |=> (MISO == 1'b0)
) else $error("Reset Assertion Failed: Outputs were not low during reset.");

CP1_reset_outputs_low_cover: cover property (
    @(posedge clk)
    !rst_n |=> (MISO == 1'b0)
);


AP2_MISO_stable_when_NOT_read: assert property (
    @(posedge clk) disable iff (!rst_n)
    // When SS_n is high (slave is idle), the rx_data bus should not change
    ((cs != READ_DATA) && $past(cs != READ_DATA)) |=> $stable(MISO)
) else $error("rx_data Signal Integrity Failed: Data changed while slave was idle (SS_n high).");

CP2_MISO_stable_when_NOT_read: cover property (
    @(posedge clk) disable iff (!rst_n)
    ((cs != READ_DATA) && $past(cs != READ_DATA)) |=> $stable(MISO)
);

endmodule;
