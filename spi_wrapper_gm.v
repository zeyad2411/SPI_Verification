module spi_wrapper (

    input MOSI , clk , rst_n , SS_n ,
    output MISO 
);

wire [9:0] rx_data ; 
wire [7:0] tx_data ;
wire rx_valid ;
wire tx_valid ;

ram  u1(

     rx_data , 
     clk ,rst_n , rx_valid ,
     tx_valid ,
     tx_data
    );

spi u2(
    MOSI, SS_n, clk, rst_n,
     tx_valid,
     tx_data,
     rx_valid,
     rx_data,
     MISO

);

endmodule 
