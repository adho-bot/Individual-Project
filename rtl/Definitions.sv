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
//temp, will change once i decide on the instruction encodings
`define OP_R_TYPE       7'b1010111 // R
`define OP_MV_TYPE      7'b1111110 // MOVE
`define OP_LOAD         7'b1111101 // LOAD
`define OP_STORE        7'b1111100 // STORE
`define OP_NEWS_TYPE    7'b1111011 // Another R type implementation

/*------------------------------------------------------------------------------------------*/
/*                                      FSM STATES                                          */
/*------------------------------------------------------------------------------------------*/

`define IDLE       3'b001 // R
`define DATA_LOAD  3'b010 // JAL
`define R_EXECUTE  3'b011 // implement as R type
`define NEWS_EXECUTE 3'b100 //implement as  I type
`define MV_EXECUTE 3'b101 // LOAD
`define STORE_DATA 3'b110 // STORE






