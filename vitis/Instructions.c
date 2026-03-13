#include "Instructions.h"

/*======================================*/
/*           Base Encoders              */
/*======================================*/

static uint32_t r_type(uint8_t rd, uint8_t rs1, uint8_t rs2, uint8_t alu_op)
{
    return (0b00 << 18) |
           ((alu_op & 0x7) << 15) |
           ((rs2 & 0x7) << 12) |
           (0b0000 << 8) |
           ((rs1 & 0x7) << 5) |
           ((rd & 0x7) << 2) |
           OP_R_TYPE;
}

static uint32_t news_type(uint8_t rd, uint8_t rs1, uint8_t rs2, uint8_t dir, uint8_t alu_op)
{
    return (0b00 << 18) |
           ((alu_op & 0x7) << 15) |
           ((rs2 & 0x7) << 12) |
           ((dir & 0x3) << 10) |
           (0b00 << 8) |
           ((rs1 & 0x7) << 5) |
           ((rd & 0x7) << 2) |
           OP_NEWS_TYPE;
}

/*======================================*/
/*          LOAD / STORE                */
/*======================================*/

uint32_t vload(uint16_t address, uint8_t rd)
{
    return (0b00 << 18) |
           ((address & 0x3FF) << 8) |
           (0b000 << 5) |
           ((rd & 0x7) << 2) |
           OP_LOAD;
}

uint32_t vstore(uint16_t address, uint8_t rs1)
{
    return (0b00 << 18) |
           ((address & 0x3FF) << 8) |
           ((rs1 & 0x7) << 5) |
           (0b000 << 2) |
           OP_STORE;
}

/*======================================*/
/*          R-Type Instructions         */
/*======================================*/

uint32_t vadd(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return r_type(rd, rs1, rs2, ADD);
}

uint32_t vsub(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return r_type(rd, rs1, rs2, SUB);
}

uint32_t vxor(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return r_type(rd, rs1, rs2, XORR);
}

uint32_t vorr(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return r_type(rd, rs1, rs2, ORR);
}

uint32_t vandd(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return r_type(rd, rs1, rs2, ANDD);
}

/*======================================*/
/*        Special R-Type Operations     */
/*======================================*/

/* Extract MSB (used for absolute value trick) */
uint32_t getmsb(uint8_t rd, uint8_t rs)
{
    return r_type(rd, 0, rs, MSBTST);
}

/* Arithmetic Shift Right */
uint32_t vsra(uint8_t rd, uint8_t rs1, uint8_t shamt)
{
    return r_type(rd, rs1, shamt, SRA);
}

/*======================================*/
/*          NEWS ADD                    */
/*======================================*/

uint32_t mvnorthadd(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return news_type(rd, rs1, rs2, NEWS_NORTH, ADD);
}

uint32_t mveastadd(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return news_type(rd, rs1, rs2, NEWS_EAST, ADD);
}

uint32_t mvwestadd(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return news_type(rd, rs1, rs2, NEWS_WEST, ADD);
}

uint32_t mvsouthadd(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return news_type(rd, rs1, rs2, NEWS_SOUTH, ADD);
}

/*======================================*/
/*          NEWS SUB                    */
/*======================================*/

uint32_t mvnorthsub(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return news_type(rd, rs1, rs2, NEWS_NORTH, SUB);
}

uint32_t mveastsub(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return news_type(rd, rs1, rs2, NEWS_EAST, SUB);
}

uint32_t mvwestsub(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return news_type(rd, rs1, rs2, NEWS_WEST, SUB);
}

uint32_t mvsouthsub(uint8_t rd, uint8_t rs1, uint8_t rs2)
{
    return news_type(rd, rs1, rs2, NEWS_SOUTH, SUB);
}