module ram #(
   parameter MEM_DEPTH = 256 ,
   parameter ADDR_SIZE = 8 
)(

    input [9:0] din , 
    input clk ,rst_n , rx_valid ,
    output reg tx_valid ,
    output reg [7:0] dout 
    );

    reg [7:0] mem [MEM_DEPTH -1 :0] ;

    //address
    reg [ADDR_SIZE-1:0] addr ;


    always @(posedge clk  )begin 
        if ( !rst_n ) begin 
          tx_valid <= 1'b0 ; 
          dout <=  8'b0 ;
        end 
        else if (rx_valid) begin 
              tx_valid <= 1'b0  ; 

            if ( din[9:8] == 2'b00   || din[9:8] == 2'b10 )
              addr <= din [7:0] ;

            else if (din[9:8] == 2'b01) 
              mem [addr] <= din[7:0] ;

            else if (din[9:8] == 2'b11) begin 
              tx_valid <= 1 ;
              dout <= mem [addr] ;
            end
        end 
    end 
endmodule  
