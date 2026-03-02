#ifndef INSTRUCTIONS_H
#define INSTRUCTIONS_H

#include <stdint.h>

/*======================================*/
/*          Instruction Width           */
/*======================================*/
#define INSTR_WIDTH 32

/*======================================*/
/*            Opcodes (7-bit)           */
/*======================================*/
#define OP_R_TYPE       0b1011100
#define OP_LOAD         0b1111000
#define OP_STORE        0b1110100
#define OP_NEWS_TYPE    0b1111010
#define OP_ABS          0b1010100

/*======================================*/
/*        ALU funct7 + funct3           */
/*        [9:3] = funct7                */
/*        [2:0] = funct3                */
/*======================================*/

#define FUNCT_ADD       0b0000000000   // funct7=0000000 funct3=000
#define FUNCT_SUB       0b0100000000   // funct7=0100000 funct3=000
#define FUNCT_XORR      0b0000000100   // funct7=0000000 funct3=100
#define FUNCT_ORR       0b0000000110   // funct7=0000000 funct3=110
#define FUNCT_ANDD      0b0000000111   // funct7=0000000 funct3=111

// ABS → funct7 = 0100000, funct3 = 001
#define FUNCT_ABS_OP    0b0100000001

/*======================================*/
/*        NEWS Direction Select         */
/*======================================*/
#define NEWS_NORTH      0b00
#define NEWS_EAST       0b01
#define NEWS_WEST       0b10
#define NEWS_SOUTH      0b11

/*======================================*/
/*        Core Instruction Encoders     */
/*======================================*/

uint32_t vstore(uint32_t address, uint8_t rs1);
uint32_t vload(uint32_t address, uint8_t rd);
uint32_t vabs(uint8_t rd, uint8_t rs1);

/*======================================*/
/*          R-Type Instructions         */
/*======================================*/
uint32_t vadd (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t vsub (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t vxor (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t vorr (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t vandd(uint8_t rd, uint8_t rs1, uint8_t rs2);

/*======================================*/
/*     NEWS Variants (ADD and SUB only) */
/*======================================*/

uint32_t mvnorthadd(uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mvnorthsub(uint8_t rd, uint8_t rs1, uint8_t rs2);

uint32_t mveastadd(uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mveastsub(uint8_t rd, uint8_t rs1, uint8_t rs2);

uint32_t mvwestadd(uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mvwestsub(uint8_t rd, uint8_t rs1, uint8_t rs2);

uint32_t mvsouthadd(uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mvsouthsub(uint8_t rd, uint8_t rs1, uint8_t rs2);

#endif