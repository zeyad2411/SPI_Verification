module SLAVE_GM #(
    parameter IDLE = 3'b000, 
    parameter CHK_CMD = 3'b010, 
    parameter WRITE = 3'b001, 
    parameter READ_ADD = 3'b011, 
    parameter READ_DATA = 3'b100
)(
    input MOSI, SS_n, clk, rst_n,
    input tx_valid,
    input [7:0] tx_data,
    output reg rx_valid,
    output reg [9:0] rx_data,
    output reg MISO ,
    output wire [2:0] cs_sva  // for SVA to monitor the current state
    

);

reg [2:0] cs, ns;
reg add_exist;
reg [3:0] counter_in;
reg [3:0] counter_out;
reg [7:0] tx_reg;
reg start_out;

// State memory
always @(posedge clk ) begin
    if(!rst_n)  
       cs <= IDLE;
    else 
        cs <= ns;
end

// Next state logic
always @(*) begin 
    case (cs)
        IDLE: ns = (SS_n == 0) ? CHK_CMD : IDLE;
        
        CHK_CMD: begin
            if (SS_n == 1) 
                ns = IDLE;
            else if (MOSI == 0)
                ns = WRITE;
            else
                ns = (add_exist) ? READ_DATA : READ_ADD;
        end

        WRITE: ns = (SS_n == 1) ? IDLE : WRITE;
        READ_ADD: ns = (SS_n == 1) ? IDLE : READ_ADD;
        READ_DATA: ns = (SS_n == 1) ? IDLE : READ_DATA;
        default: ns = IDLE;
    endcase 
end 

// Output logic and counters
always @(posedge clk ) begin 
    if (!rst_n) begin
        add_exist <= 0;
        counter_in <= 4'b0;
        counter_out <= 3'b0;
        rx_valid <= 0;
        rx_data <= 10'b0;
        MISO <= 0;
       
        start_out <= 0;
        tx_reg <= 8'b0;
    end
    else begin
        // Default assignments
        rx_valid <= 0;   // to set rx_valid to zero every clk cycle even it was high previous to sample data correctly and dosnt coreept with another mosi
       
        
        if (SS_n) begin
            counter_in <= 4'b0;
            counter_out <= 3'b0;
            start_out <= 0;
            rx_data <= 10'b0;
        end
        else begin
                
            case (cs)
                IDLE: begin
                    counter_in <= 0;
                    counter_out <= 0;
                end
                
                
                WRITE :begin 
                 if (counter_in < 10) begin
                   rx_data <= {rx_data[8:0], MOSI};
                  counter_in <= counter_in + 1;
                    end
                        
                 if (counter_in == 9)
                            rx_valid <= 1;
                end
                READ_ADD: begin
                   if (counter_in < 10) begin // excute 10 time 
                   rx_data <= {rx_data[8:0], MOSI};
                  counter_in <= counter_in + 1;
                    end
                        
                 if (counter_in == 9)   // at 10th time 
                            rx_valid <= 1;
                 add_exist <= 1 ;
                    
                end
                 READ_DATA : begin
                 if (counter_in < 10) begin
                   rx_data <= {rx_data[8:0], MOSI};
                  counter_in <= counter_in + 1;
                    end
                        
                 if (counter_in == 9)
                            rx_valid <= 1;
                 add_exist = 0 ;
                      
                 if ( tx_valid  ) begin
                        tx_reg <= tx_data;    // save inside spi 
                        start_out <= 1;
                    end
                 end
                
            endcase
            
            
            // MISO handling
            if (start_out && (counter_out < 8)) begin
                MISO <= tx_reg[7-counter_out];
                counter_out <= counter_out + 1;
            end
            else if (counter_out >= 8 ) begin
                start_out <= 0;
            end
        end
        

    end
end
assign cs_sva = cs; // assign current state to output for SVA monitoring

endmodule