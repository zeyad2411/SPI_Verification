module SLAVE (MOSI, MISO, SS_n, clk, rst_n, rx_data, rx_valid, tx_data, tx_valid,cs_sva);

localparam IDLE      = 3'b000;
localparam WRITE     = 3'b001;
localparam CHK_CMD   = 3'b010;
localparam READ_ADD  = 3'b011;
localparam READ_DATA = 3'b100;

input            MOSI, clk, rst_n, SS_n, tx_valid;
input      [7:0] tx_data;
output reg [9:0] rx_data;
output reg       rx_valid, MISO;
output wire [2:0] cs_sva;
// BUG FIX #3: Split single counter into two separate counters
// ORIGINAL BUG: Used single 'counter' for both RX and TX, causing conflicts
// FIX: Use counter_in for receiving data and counter_out for transmitting
reg [3:0] counter_in;      // Counter for input (receiving 10 bits)
reg [3:0] counter_out;     // Counter for output (transmitting 8 bits)

// Renamed 'received_address' to 'add_exist' for clarity (same functionality)
reg       add_exist;       // Flag to track if address has been received

// BUG FIX #4: Added registers to properly handle MISO transmission
// ORIGINAL BUG: Directly used tx_data without latching, causing timing issues
// FIX: Latch tx_data into tx_reg and use start_out flag to control transmission
reg [7:0] tx_reg;          // Register to latch and hold tx_data during transmission
reg       start_out;       // Flag to indicate MISO transmission is active

reg [2:0] cs, ns;

// State memory - No changes needed
always @(posedge clk) begin
    if (~rst_n) begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end

// Next state logic - No changes needed
always @(*) begin
    case (cs)
        IDLE : begin
            if (SS_n)
                ns = IDLE;
            else
                ns = CHK_CMD;
        end
        CHK_CMD : begin
            if (SS_n)
                ns = IDLE;
            else begin
                if (~MOSI)
                    ns = WRITE;
                else begin
                    if (add_exist) 
                        ns = READ_DATA; 
                    else
                        ns = READ_ADD;
                end
            end
        end
        WRITE : begin
            if (SS_n)
                ns = IDLE;
            else
                ns = WRITE;
        end
        READ_ADD : begin
            if (SS_n)
                ns = IDLE;
            else
                ns = READ_ADD;
        end
        READ_DATA : begin
            if (SS_n)
                ns = IDLE;
            else
                ns = READ_DATA;
        end
        default : ns = IDLE;
    endcase
end

// Output logic
always @(posedge clk) begin
    if (~rst_n) begin 
        rx_data <= 0;
        rx_valid <= 0;
        add_exist <= 0;
        MISO <= 0;
        
        // BUG FIX #2: Initialize new registers during reset
        counter_in <= 0;
        counter_out <= 0;
        tx_reg <= 0;
        start_out <= 0;
    end
    else begin
        // BUG FIX #6: Clear rx_valid every cycle by default
        // ORIGINAL BUG: rx_valid was only cleared in IDLE state
        // FIX: Set rx_valid <= 0 at the start, then set to 1 only when data is ready
        // This ensures proper handshaking - rx_valid pulses high for one cycle
        rx_valid <= 0;
        
        // BUG FIX #7: Handle SS_n deassertion to reset counters and data
        // ORIGINAL BUG: No handling when slave is deselected (SS_n goes high)
        // FIX: Reset all counters and data registers when SS_n is high
        // This ensures clean state for next transaction
        if (SS_n) begin
            counter_in <= 4'b0;
            counter_out <= 3'b0;
            start_out <= 0;
            rx_data <= 10'b0;
        end
        else begin
            case (cs)
                IDLE : begin
                    // BUG FIX #2: Reset counters in IDLE state
                    // ORIGINAL BUG: Counters were never reset, causing incorrect counts
                    counter_in <= 0;
                    counter_out <= 0;
                end
                
                
                WRITE : begin
                    // BUG FIX #1: Use increment counter with shift register
                    // ORIGINAL BUG: Used decrement counter with direct indexing rx_data[counter-1]
                    //               This caused 11 cycles to complete (counter: 10->9->...->0)
                    // FIX: Increment from 0 to 9 (10 cycles) and use shift register
                    //      Shift register: {rx_data[8:0], MOSI} shifts left and adds new bit at LSB
                    if (counter_in < 10) begin
                        rx_data <= {rx_data[8:0], MOSI};  // Shift left, add MOSI at bit[0]
                        counter_in <= counter_in + 1;
                    end
                    
                    // BUG FIX #6: Set rx_valid on same cycle as last bit received
                    // ORIGINAL BUG: rx_valid set one cycle late (when counter = 0)
                    // FIX: Check if counter_in == 9, meaning we just received 10th bit
                    if (counter_in == 9) begin
                        rx_valid <= 1;
                    end
                end
                
                READ_ADD : begin
                    // Same fixes as WRITE state
                    // BUG FIX #1: Shift register approach instead of direct indexing
                    if (counter_in < 10) begin
                        rx_data <= {rx_data[8:0], MOSI};
                        counter_in <= counter_in + 1;
                    end
                    
                    // BUG FIX #6: Immediate rx_valid on 10th bit
                    if (counter_in == 9) begin
                        rx_valid <= 1;
                        add_exist <= 1;  // Mark that address has been received
                    end
                end
                
                READ_DATA : begin
                    // BUG FIX #1: Same shift register approach for receiving
                    if (counter_in < 10) begin
                        rx_data <= {rx_data[8:0], MOSI};
                        counter_in <= counter_in + 1;
                    end
                    
                    // BUG FIX #6: Immediate rx_valid
                    if (counter_in == 9) begin
                        rx_valid <= 1;
                    end
                    
                    // BUG FIX #5: Use blocking assignment for add_exist flag
                    // ORIGINAL BUG: Used non-blocking (<=) which delays update by one cycle
                    // FIX: Use blocking (=) for immediate effect within same cycle
                    // This ensures add_exist is cleared immediately for next transaction
                    add_exist = 0;
                    
                    // BUG FIX #4: Latch tx_data when valid, don't use directly
                    // ORIGINAL BUG: Used tx_data[counter-1] directly with same counter as RX
                    //               Counter management was chaotic (set to 8 mid-operation)
                    // FIX: When tx_valid is high:
                    //      1. Latch tx_data into tx_reg for stable transmission
                    //      2. Set start_out flag to begin MISO transmission
                    if (tx_valid) begin
                        tx_reg <= tx_data;    // Save data to transmit
                        start_out <= 1;       // Signal to start MISO output
                    end
                end
            endcase
            
            // BUG FIX #4: Separate, independent MISO transmission logic
            // ORIGINAL BUG: MISO logic was inside READ_DATA state with shared counter
            //               Used: if(counter > 0) MISO <= tx_data[counter-1]
            //               Then set counter <= 8, causing conflicts with RX operations
            // FIX: Place MISO logic outside case statement so it runs independently
            //      Use dedicated counter_out for transmission (0 to 7 for 8 bits)
            //      This allows simultaneous RX (via MOSI) and TX (via MISO)
            if (start_out && (counter_out < 8)) begin
                // Transmit MSB first: tx_reg[7], tx_reg[6], ..., tx_reg[0]
                MISO <= tx_reg[7 - counter_out];
                counter_out <= counter_out + 1;
            end
            else if (counter_out >= 8) begin
                // After transmitting all 8 bits, stop transmission
                start_out <= 0;
                // Note: counter_out stays at 8, will reset on next transaction
            end
        end
    end
end
assign cs_sva = cs; // assign current state to output for SVA monitoring
endmodule