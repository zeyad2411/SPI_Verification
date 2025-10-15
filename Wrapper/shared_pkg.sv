package shared_pkg;
// items for the RAM
typedef enum bit [2:0] { WA  = 3'b000 , WD = 3'b001 , RA = 3'b110 , RD = 3'b111  } rw_e;

// for handling the Wrapper assertions
typedef enum bit [2:0] {
    IDLE      = 3'b000,
    WRITE     = 3'b001,
    CHK_CMD   = 3'b010,
    READ_ADD  = 3'b011,
    READ_DATA = 3'b100
} cs_e;


// items for the Wrapper


endpackage