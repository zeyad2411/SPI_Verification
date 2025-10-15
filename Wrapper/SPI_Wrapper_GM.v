module SPI_Wrapper_GM (

    input MOSI , clk , rst_n , SS_n ,
    output MISO 
);

wire [9:0] rx_data ; 
wire [7:0] tx_data ;
wire rx_valid ;
wire tx_valid ;

RAM_GM  u1(
        .din(rx_data),
        .clk(clk),
        .rst_n(rst_n),
        .rx_valid(rx_valid),
        .dout(tx_data),
        .tx_valid(tx_valid)
    );

SLAVE_GM u2(
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

endmodule 
