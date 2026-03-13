#ifndef INSTRUCTIONS_H
#define INSTRUCTIONS_H

#include <stdint.h>

/*======================================*/
/*          Instruction Width           */
/*======================================*/
#define INSTR_WIDTH 20

/*======================================*/
/*            Opcodes (2-bit)           */
/*======================================*/
#define OP_LOAD        0b00
#define OP_R_TYPE      0b01
#define OP_STORE       0b10
#define OP_NEWS_TYPE   0b11

/*======================================*/
/*              ALU OPS                 */
/*======================================*/
#define ADD     0b000
#define SUB     0b001
#define XORR    0b010
#define ORR     0b011
#define ANDD    0b100
#define MSBTST  0b101
#define SRA     0b110

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

uint32_t vload (uint16_t address, uint8_t rd);
uint32_t vstore(uint16_t address, uint8_t rs1);

/*======================================*/
/*          R-Type Instructions         */
/*======================================*/

uint32_t vadd (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t vsub (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t vxor (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t vorr (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t vandd(uint8_t rd, uint8_t rs1, uint8_t rs2);

/*======================================*/
/*        Special R-Type Operations     */
/*======================================*/

/* Extract MSB (used in absolute value trick) */
uint32_t getmsb(uint8_t rd, uint8_t rs);

/* Arithmetic Shift Right */
uint32_t vsra(uint8_t rd, uint8_t rs1, uint8_t shamt);

/*======================================*/
/*        NEWS Instructions (ADD)       */
/*======================================*/

uint32_t mvnorthadd(uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mveastadd (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mvwestadd (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mvsouthadd(uint8_t rd, uint8_t rs1, uint8_t rs2);

/*======================================*/
/*        NEWS Instructions (SUB)       */
/*======================================*/

uint32_t mvnorthsub(uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mveastsub (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mvwestsub (uint8_t rd, uint8_t rs1, uint8_t rs2);
uint32_t mvsouthsub(uint8_t rd, uint8_t rs1, uint8_t rs2);

#endif