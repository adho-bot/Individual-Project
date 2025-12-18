/*------------------------------------------------------------------------------------------*/
/*                                ALU Operation States                                      */
/*------------------------------------------------------------------------------------------*/
//Normal ALU
`define ADD		       10'b0000000_000 // Addition
`define SUB     	   10'b0100000_000 // Subtraction
`define SLL    	  	   10'b0000000_001 // Shift left logical
`define XORR     	   10'b0000000_100 // Xor
`define SRL     	   10'b0000000_101 // Shift right logical
`define SRA     	   10'b0100000_101 // Shift right arithmetic
`define ORR     	   10'b0000000_110 // Or
`define ANDD    	   10'b0000000_111 // And
    
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

`define IDLE            4'b0001 // R
`define DATA_LOAD       4'b0010 // load data into array
`define R_EXECUTE       4'b0011 // implement as R type
`define NEWS_EXECUTE    4'b0100 //implement as  I type
`define STORE_DATA      4'b0101 // STORE
`define DATA_TO_MEM     4'b0110 //send data to sipo
`define MEM_TO_DATA     4'b0111 //send data from memory to piso
`define DATA_FETCH      4'b1000 //1 cycle to fetch the data






