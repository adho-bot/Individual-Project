/******************************************************************************
 * instructions.c
 * Instruction encoding functions for custom vector processor
 ******************************************************************************/

#include "Instructions.h"
#include <xil_types.h>

/*======================================*/
/*  Helper macros to extract funct7/3   */
/*======================================*/
#define F7(f)  (((f) >> 3) & 0x7F)
#define F3(f)  ((f) & 0x07)

/*======================================*/
/*        Internal Base Encoders        */
/*======================================*/

static uint32_t r_type(uint8_t rd, uint8_t rs1, uint8_t rs2, uint16_t funct) {
    return ((F7(funct))      << 25) |
           ((rs2  & 0x1F)    << 20) |
           ((rs1  & 0x1F)    << 15) |
           ((F3(funct))      << 12) |
           ((rd   & 0x1F)    <<  7) |
           (OP_R_TYPE & 0x7F);
}

static uint32_t news_type(uint8_t rd, uint8_t rs1, uint8_t news_sel, uint8_t rs2, uint16_t funct) {
    return ((F7(funct))          << 25) |
           ((news_sel & 0x03)    << 23) |
           ((rs2      & 0x07)    << 20) |
           ((rs1      & 0x1F)    << 15) |
           ((F3(funct))          << 12) |
           ((rd       & 0x1F)    <<  7) |
           (OP_NEWS_TYPE & 0x7F);
}

/*======================================*/
/*        Core Instruction Encoders     */
/*======================================*/

uint32_t vstore(uint32_t address, uint8_t rs1) {
    uint32_t addr_hi = (address >> 8) & 0xFFF;
    uint32_t addr_lo = (address)      & 0xFF;
    return (addr_hi << 20) | ((rs1 & 0x1F) << 15) | (addr_lo << 7) | (OP_STORE & 0x7F);
}

uint32_t vload(uint32_t address, uint8_t rd) {
    return ((address & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | (OP_LOAD & 0x7F);
}

uint32_t vabs(uint8_t rd, uint8_t rs1) {
    return ((F7(FUNCT_ABS_OP)) << 25) |
           (0x00               << 20) |
           ((rs1  & 0x1F)      << 15) |
           ((F3(FUNCT_ABS_OP)) << 12) |
           ((rd   & 0x1F)      <<  7) |
           (OP_ABS & 0x7F);
}

/*======================================*/
/*          R-Type Instructions         */
/*======================================*/
uint32_t vadd (uint8_t rd, uint8_t rs1, uint8_t rs2) { return r_type(rd, rs1, rs2, FUNCT_ADD);  }
uint32_t vsub (uint8_t rd, uint8_t rs1, uint8_t rs2) { return r_type(rd, rs1, rs2, FUNCT_SUB);  }
uint32_t vxor (uint8_t rd, uint8_t rs1, uint8_t rs2) { return r_type(rd, rs1, rs2, FUNCT_XORR); }
uint32_t vorr (uint8_t rd, uint8_t rs1, uint8_t rs2) { return r_type(rd, rs1, rs2, FUNCT_ORR);  }
uint32_t vandd(uint8_t rd, uint8_t rs1, uint8_t rs2) { return r_type(rd, rs1, rs2, FUNCT_ANDD); }

/*======================================*/
/*          NEWS NORTH Variants         */
/*======================================*/
uint32_t mvnorthadd(uint8_t rd, uint8_t rs1, uint8_t rs2) { return news_type(rd, rs1, NEWS_NORTH, rs2, FUNCT_ADD); }
uint32_t mvnorthsub(uint8_t rd, uint8_t rs1, uint8_t rs2) { return news_type(rd, rs1, NEWS_NORTH, rs2, FUNCT_SUB); }

/*======================================*/
/*          NEWS EAST Variants          */
/*======================================*/
uint32_t mveastadd(uint8_t rd, uint8_t rs1, uint8_t rs2) { return news_type(rd, rs1, NEWS_EAST, rs2, FUNCT_ADD); }
uint32_t mveastsub(uint8_t rd, uint8_t rs1, uint8_t rs2) { return news_type(rd, rs1, NEWS_EAST, rs2, FUNCT_SUB); }

/*======================================*/
/*          NEWS WEST Variants          */
/*======================================*/
uint32_t mvwestadd(uint8_t rd, uint8_t rs1, uint8_t rs2) { return news_type(rd, rs1, NEWS_WEST, rs2, FUNCT_ADD); }
uint32_t mvwestsub(uint8_t rd, uint8_t rs1, uint8_t rs2) { return news_type(rd, rs1, NEWS_WEST, rs2, FUNCT_SUB); }

/*======================================*/
/*          NEWS SOUTH Variants         */
/*======================================*/
uint32_t mvsouthadd(uint8_t rd, uint8_t rs1, uint8_t rs2) { return news_type(rd, rs1, NEWS_SOUTH, rs2, FUNCT_ADD); }
uint32_t mvsouthsub(uint8_t rd, uint8_t rs1, uint8_t rs2) { return news_type(rd, rs1, NEWS_SOUTH, rs2, FUNCT_SUB); }
