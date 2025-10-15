interface SPI_Wrapper_if (clk);
input bit clk;

//inputs:
logic            MOSI, rst_n, SS_n;

//outputs:
logic MISO;

    

endinterface : SPI_Wrapper_if