

// Corrected: Use a standard module definition with simple ports.
module SPI_Wrapper (
    input   clk,
    input   rst_n,
    input   MOSI,
    input   SS_n,
    output MISO
    // Add an output port for the FSM state for assertions
);

    wire [2:0] cs_sva;
    // Internal wires to connect the SPI and RAM modules
    wire [9:0] rx_data;
    wire [7:0] tx_data;
    wire       rx_valid;
    wire       tx_valid;

    // Instance of the SPI Slave module
    SLAVE SPI (
        .clk(clk),
        .rst_n(rst_n),
        .MOSI(MOSI),
        .SS_n(SS_n),
        .tx_valid(tx_valid), // from RAM
        .tx_data(tx_data),   // from RAM
        .rx_data(rx_data),   // to RAM
        .rx_valid(rx_valid), // to RAM
        .MISO(MISO),
        .cs_sva(cs_sva)     // Drive the output port
    );

    // Instance of the RAM module
    RAM RAM (
        .din(rx_data),
        .clk(clk),
        .rst_n(rst_n),
        .rx_valid(rx_valid),
        .dout(tx_data),
        .tx_valid(tx_valid)
    );

    // *** SOLUTION: BIND DIRECTLY TO THE INSTANCES ***
    // The bind statements now connect to the internal signals of the
    // SPI and RAM instances, which is the correct approach.

    bind RAM RAM_SVA RAM_assertions (
        .din(din),
        .clk(clk),
        .rst_n(rst_n),
        .rx_valid(rx_valid),
        .dout(dout),
        .tx_valid(tx_valid)
    );

    bind SLAVE SPI_Slave_SVA SPI_Slave_assertions (
        .clk(clk),
        .rst_n(rst_n),
        .MOSI(MOSI),
        .SS_n(SS_n),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .MISO(MISO),
        // Connect the SVA module to the FSM state signal inside the SPI instance
        .cs_sva(cs_sva)
    );

endmodule

