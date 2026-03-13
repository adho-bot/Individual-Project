/*==========================================================================================*/
/*                            ALU Operation Encoding (3-bit)                                */
/*==========================================================================================*/
`define ADD       3'b000   // Addition
`define SUB       3'b001   // Subtraction
`define XORR      3'b010   // Xor
`define ORR       3'b011   // Or
`define ANDD      3'b100   // And
`define MSBTST    3'b101   // MSB Test
`define SRA       3'b110   // Arithmetic Shift Right
// 3'b111 reserved

/*==========================================================================================*/
/*                          Instruction Type Encoding (2-bit)                               */
/*==========================================================================================*/
`define OP_LOAD        2'b00
`define OP_R_TYPE      2'b01
`define OP_STORE       2'b10
`define OP_NEWS_TYPE   2'b11

/*==========================================================================================*/
/*                                   FSM STATES                                             */
/*==========================================================================================*/
`define IDLE           4'b0001
`define DATA_LOAD      4'b0010
`define R_EXECUTE      4'b0011
`define NEWS_EXECUTE   4'b0100
`define STORE_DATA     4'b0101
`define DATA_TO_MEM    4'b0110
`define MEM_TO_DATA    4'b0111
`define DATA_FETCH     4'b1000
