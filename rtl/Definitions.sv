/*------------------------------------------------------------------------------------------*/
/*                                ALU Operation States                                      */
/*------------------------------------------------------------------------------------------*/
//Normal ALU
`define ADD		    10'b0000000_000 // Addition
`define SUB     	10'b0100000_000 // Subtraction
`define SLL    	  	10'b0000000_001 // Shift left logical
`define XORR     	10'b0000000_100 // Xor
`define SRL     	10'b0000000_101 // Shift right logical
`define SRA     	10'b0100000_101 // Shift right arithmetic
`define ORR     	10'b0000000_110 // Or
`define ANDD    	10'b0000000_111 // And
    
    
//Branch
`define BEQ     	10'b1111111_000  //sketchy way of doing this. Qno funct7 for B instructions. I just made it 7 1s
`define BNE     	10'b1111111_001
`define BLT     	10'b1111111_100
`define BGE     	10'b1111111_101

/*------------------------------------------------------------------------------------------*/
/*                                Instruction Opcodes                                      */
/*------------------------------------------------------------------------------------------*/

`define OP_R_TYPE       7'b0110011 // R
`define OP_I_TYPE       7'b0010011 // I
`define OP_JAL          7'b1101111 // JAL
`define OP_B_TYPE     	7'b1100011 // B
`define OP_LOAD         7'b0000011 // LOAD
`define OP_STORE        7'b0100011 // STORE


/*------------------------------------------------------------------------------------------*/
/*                                      FSM STATES                                          */
/*------------------------------------------------------------------------------------------*/

`define IDLE       7'b0110011 // R
`define DECODE       7'b0010011 // I
`define DATA_LOAD          7'b1101111 // JAL
`define R_EXECUTE     	7'b1100011 // B
`define MV_EXEC         7'b0000011 // LOAD
`define STORE_DATA        7'b0100011 // STORE






