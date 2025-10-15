package SPI_Wrapper_seq_item_pkg;
  import uvm_pkg::*;
  import shared_pkg::*;
  `include "uvm_macros.svh"

  class SPI_Wrapper_seq_item extends uvm_sequence_item;
    `uvm_object_utils(SPI_Wrapper_seq_item)
    
   
    logic MISO_gm;


   
    logic MOSI = 0;
    rand logic rst_n;
    rand logic SS_n;
    
    logic MISO;

    
    rand logic [10:0] mosi_bits;  
    
    // Global (shared) variables for frame control
    static int bit_counter = 0;
    static logic [10:0] current_mosi_bits;
    static int frame_counter = 0;
    static int frame_period = 13;
    
    // Track previous command for sequence ordering
    static rw_e previous_cmd = WA;

    
    function new(string name = "SPI_Wrapper_seq_item");
      super.new(name);
    endfunction

   
    constraint rst_n_c {
      rst_n dist {1 := 99, 0 := 1};
    }

    

    
    constraint valid_cmd_c {
      mosi_bits[10:8] inside {3'b000, 3'b001, 3'b110, 3'b111};
    }

    
    constraint write_only_seq_c {
      (previous_cmd == WA) -> (mosi_bits[10:8] inside {3'b000, 3'b001});
      !( mosi_bits[10:8] inside {3'b110, 3'b111} ); // no read commands allowed
    }

    
    constraint read_only_seq_c {
      (previous_cmd == RA) -> (mosi_bits[10:8] == 3'b111);
      (previous_cmd == RD) -> (mosi_bits[10:8] == 3'b110);
        !( mosi_bits[10:8] inside {3'b000, 3'b001} ); // no write commands allowed
    }

    
    constraint mixed_rw_seq_c {
      
      (previous_cmd == WA) -> (mosi_bits[10:8] inside {3'b000, 3'b001});
      
      
      (previous_cmd == WD) -> (mosi_bits[10:8] dist {3'b110 := 60, 3'b000 := 40});
      
      
      (previous_cmd == RA) -> (mosi_bits[10:8] == 3'b111);
      
      
      (previous_cmd == RD) -> (mosi_bits[10:8] dist {3'b000 := 60, 3'b110 := 40});
    }

    
    function void post_randomize();

      if (!rst_n) begin
        // During reset, force idle state
        MOSI = 0;
        SS_n = 1;
        bit_counter = 0;
        frame_counter = 0;
        current_mosi_bits = 0;
        frame_period = 13;
        return;
      end

      // Latch new frame properties only at frame start (frame_counter == 0)
      if (frame_counter == 0) begin
        current_mosi_bits = mosi_bits;
        // Track the current command as previous for next iteration
         previous_cmd = rw_e'(mosi_bits[10:8]);
        // Set frame period: 23 cycles for READ_DATA (3'b111), 13 for others
        frame_period = (mosi_bits[10:8] == 3'b111) ? 24 : 14;
        bit_counter = 0;
        SS_n = 1;   // high for 1 cycle at start of new frame
      end
      else begin
        SS_n = 0;   // low during transmission
      end

      // MOSI bit transmission (cycles 2-12 for normal, 2-22 for READ_DATA)
      // Skip cycle 0 (SS_n high) and cycle 1 (setup)
      if ((frame_counter > 1) && (frame_counter < 13)) begin
        MOSI = current_mosi_bits[10 - bit_counter];
        bit_counter = (bit_counter + 1) % 11;
      end
      else begin
        MOSI = 0;   // idle value
        bit_counter = 0;
      end

      // Increment frame counter (wraps at frame_period)
      frame_counter = (frame_counter + 1) % frame_period;


      

    endfunction

    

    // ============================================
    // Convert to string for debugging
    // ============================================
    function string convert2string();
      return $sformatf("MOSI=%0b SS_n=%0b rst_n=%0b mosi_bits=%b cmd=%3b (frame_cycle=%0d bit=%0d frame_period=%0d) | prev_cmd=%s | MISO=%0b | MISO_gm=%0b",
        MOSI, SS_n, rst_n, current_mosi_bits, current_mosi_bits[10:8], frame_counter, bit_counter, frame_period, previous_cmd.name(), MISO , MISO_gm);
    endfunction

    function string convert2string_stimulus();
      return $sformatf("MOSI=%0b SS_n=%0b rst_n=%0b mosi_bits=%b cmd=%3b (frame_cycle=%0d bit=%0d frame_period=%0d) | prev_cmd=%s",
        MOSI, SS_n, rst_n, current_mosi_bits, current_mosi_bits[10:8], frame_counter, bit_counter, frame_period, previous_cmd.name());
    endfunction

  endclass
endpackage