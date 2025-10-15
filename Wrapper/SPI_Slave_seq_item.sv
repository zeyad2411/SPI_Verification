package SPI_Slave_seq_item_pkg;
  import uvm_pkg::*;
  import shared_pkg::*;
  `include "uvm_macros.svh"

  class SPI_Slave_seq_item extends uvm_sequence_item;
    `uvm_object_utils(SPI_Slave_seq_item)

    // ============================================
    // GM signals
    // ============================================
     logic [9:0] rx_data_gm;
     logic rx_valid_gm, MISO_gm;
     logic [2:0] cs_sva_gm;




    // ============================================
    // DUT signals
    // ============================================
    logic MOSI = 0;
    rand logic       rst_n;
    rand logic   SS_n, tx_valid;
    logic [7:0] tx_data;
    

    // DUT outputs (for monitor use)
    logic [9:0] rx_data;
    logic       rx_valid;
    logic       MISO;
    logic [2:0] cs_sva;

    // ============================================
    // Internal randomization control
    // ============================================
    rand logic [10:0] mosi_bits;  // full serial frame (11 bits)

    // Global (shared) variables for frame control
    
    static int bit_counter = 0;
    static logic [10:0] current_mosi_bits; // current active command frame
    static int frame_counter = 0;
    static int frame_period  = 13;

    // ============================================
    // Constructor
    // ============================================
    function new(string name = "SPI_Slave_seq_item");
      super.new(name);
    endfunction

    // ============================================
    // Constraints
    // ============================================

    // (1) Reset mostly deasserted
    constraint rst_n_c {
      rst_n dist {1 := 95, 0 := 5};
    }

    // (2) Valid MOSI command combinations (first 3 bits)
    // Commands: 000=WRITE_ADD, 001=reserved, 110=READ_ADD, 111=READ_DATA
    constraint valid_cmd_c {
      !(mosi_bits[10:8] inside {3'b100 ,3'b010 ,3'b011 ,3'b101 }) ;
      mosi_bits[10:8] inside {3'b000, 3'b001, 3'b110, 3'b111};
    }

    

    // (4) tx_valid high only during READ_DATA operations
    constraint tx_valid_c {
      if (mosi_bits[10:8] == 3'b111)
        tx_valid == 1;
      else
        tx_valid == 0;
    }

    // ============================================
    // post_randomize() : handle SS_n + MOSI timing
    // ============================================
    function void post_randomize();

      if (!rst_n) begin
        // During reset, force outputs low and idle inputs
        MOSI     = 0;
        SS_n     = 1;  // inactive
        tx_valid = 0;
        tx_data  = 0;
        bit_counter = 0;
        frame_counter = 0;
        current_mosi_bits = 0;
        frame_period = 13;
        return;
      end

      // Latch new frame properties only at frame start
      if (frame_counter == 0) begin
       // Latch frame properties only once per frame
           current_mosi_bits    = mosi_bits;
           frame_period         = (mosi_bits [10:8] == 3'b111) ? 24 : 14;
           bit_counter = 0;
           SS_n = 1;   // high for 1 cycle at start of new frame
         end
       else begin
      
        SS_n = 0;   
        end

        if ( (13 > frame_counter)  && (frame_counter > 1) ) begin   // first transient to chk_cmd not get values from mosi_bits
             MOSI = current_mosi_bits[10 - bit_counter];
             bit_counter = (bit_counter + 1) % 11; 
        end else begin 
           MOSI = 0; // idle value
           bit_counter = 0;
         end


      // (4) tx_valid logic (reinforced for safety)
      if (current_mosi_bits[10:8] == 3'b111 && SS_n == 0 && frame_counter == 13) begin 
            tx_valid = 1;    // pulse for 1 cycle at bit 13 of READ_DATA frame
            tx_data = $random; // random data to send
          end
          else  begin
            tx_valid = 0;
            tx_data  = 0;    // idle value
          end

      // --- Increment counters ---
       frame_counter = (frame_counter + 1) % frame_period; // controls SS_n timing  zero at frame counter = 12

       // debug 
       //$display("post_randomize: %s time = %0t frame_counter=%0d bit_counter=%0d current_mosi_bits=%b ",convert2string(), $time, frame_counter, bit_counter , current_mosi_bits);
      


    endfunction


    function string convert2string();
      return $sformatf( " MSIO = %0b SS_n=%0b rst_n=%0b tx_valid=%0b tx_data=0x%0h mosi_bits=%b (cycle=%0d bit=%0d) | rx_data=0x%0h rx_valid=%0b MISO=%0b | GM: rx_data_gm=0x%0h rx_valid_gm=%0b MISO_gm=%0b | cs_sva=%0b cs_sva_gm=%0b |",
        MOSI, SS_n, rst_n, tx_valid, tx_data, mosi_bits, frame_counter, bit_counter,
        rx_data, rx_valid, MISO,
        rx_data_gm, rx_valid_gm, MISO_gm, cs_sva , cs_sva_gm );
    endfunction

    function string convert2string_stimulus();
      return $sformatf("Stimulus: CMD=%3b MOSI=%0b SS_n=%0b tx_valid=%0b rst_n=%0b tx_data=0x%0h",
        mosi_bits[10:8], MOSI, SS_n, tx_valid, rst_n, tx_data);
    endfunction

  endclass
endpackage    