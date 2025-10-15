package RAM_seq_item_pkg;
  import uvm_pkg::*;
  import shared_pkg::*;
  `include "uvm_macros.svh"

  class RAM_seq_item extends uvm_sequence_item;
    `uvm_object_utils(RAM_seq_item)

     static rw_e old_rw;
      rand rw_e operation;  // 2-bit random operation
     rand logic      [9:0] din;
    rand logic          rst_n, rx_valid;

     rand logic  [7:0] dout;
     rand logic       tx_valid;

 

   
    function new(string name = "RAM_seq_item");
      super.new(name);
    endfunction


   
    constraint rst_c {
      rst_n dist {1 := 95, 0 := 5};
    }

    constraint rx_c {
      rx_valid dist {1 := 95, 0 := 5};
    }

    // Write-only sequence constraint
    constraint w_c {
      (old_rw == WA) -> (operation inside {WA, WD});
      (old_rw == WD) -> (operation == WA);
      !(operation inside {RA, RD});
    }

    // Read-only sequence constraint
    constraint r_c {
      (old_rw == RA) -> (operation == RD);
      (old_rw == RD) -> (operation == RA);
      !(operation inside {WA, WD});
    }

    // Randomized read/write sequence constraint
    constraint w_r_c {
      (old_rw == WA) -> (operation inside {WA, WD });
      (old_rw == RA) -> (operation == RD);  // Hard constraint: RA must always go to RD
      (old_rw == WD) -> (operation dist {WA := 40, RA := 60});
      (old_rw == RD) -> (operation dist {WA := 60, RA := 40});
    }

  


function void post_randomize();
      din[9:8] = operation;  // Assign randomized operation to din[9:8]
      old_rw = operation;  // Update old_rw to the current operation
      
   endfunction
    

    function string convert2string();
  return $sformatf("Stimulus: din=%10b rst_n=%0b rx_valid=%0b ",
                   din, rst_n, rx_valid);
endfunction

    function string convert2string_stimulus();
  return $sformatf("Stimulus: din=%10b rst_n=%0b rx_valid=%0b tx_valid=%0b dout=0x%0h",
                   din, rst_n, rx_valid, tx_valid, dout);
endfunction

  endclass
endpackage