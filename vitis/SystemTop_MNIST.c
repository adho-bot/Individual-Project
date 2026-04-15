#include <stdio.h>
#include <xil_types.h>
#include <xstatus.h>
#include "platform.h"
#include "xil_printf.h"
#include "xbram.h"
#include "xparameters.h"
#include "Instructions.h"
#include "imagedata.h"

/*======================================*/
/*              DEFINES                 */
/*======================================*/

#define ROW_LENGTH 16
#define COL_LENGTH 16
#define NUM_PES    (ROW_LENGTH * COL_LENGTH)  // 256

// Memory map in BRAM (word addresses)
// BRAM byte address = base + wordAddr*4
//
// The array processor address field is 10 bits [17:8] = 0-1023
// Load/Store use this field to select which PE to talk to
// For a 16x16 array, PE addresses 0-255 are valid
// We REUSE addresses 0-255 for different stages since the
// data lives in PE registers between operations
#define IMG_BASE         0       // 0-255:   input image (16x16)
#define POOL_CH0_BASE    256     // 256-304: pooled channel 0 (7x7=49)
#define POOL_CH1_BASE    320     // 320-368: pooled channel 1 (7x7=49)
#define SCRATCH_ADDR     400     // scratch location for constants

#define IP_BASEADDR  XPAR_AXI_ARRAYPROC_0_BASEADDR
#define INSTR_OFFSET 0x00
#define VALID_OFFSET 0x04
#define READY_OFFSET 0x08

XBram Bram;

/*======================================*/
/*     FC Weights                       */
/*======================================*/
static const int8_t fc_bias[10] = {
    7, 80, -22, -127, 60, 45, 9, 77, -47, -33
};

static const int8_t fc_weights[10][98] = {
    { // class 0
          12,  -11,  -22,   -7,  -12,  -64,  -36,  -15,  -21,    1,   -2,   -6,  -13,   -4,
         -27,   11,  -26,   11,  -10,    0,  -32,  -43,  -14,   -6,  -30,  -58,    7,   -6,
         -19,  -23,    8,  -56,  -19,   12,   -2,  -21,   -3,    6,    7,   10,    1,   -2,
           9,   -4,    2,   26,   12,   -7,   -5,  -25,   -8,    5,  -11,   -2,    6,   -7,
          -3,    9,   -6,   15,   23,   -2,    7,   -5,  -10,   20,    7,   23,   23,   12,
          18,   30,   16,  -29,  -18,   18,   29,   23,   21,   11,  -66,  -11,   -4,   25,
           4,   -3,   37,  -13,   -5,   -7,   -8,   -4,   -8,   -6,   -9,  -27,  -15,  -25
    },
    { // class 1
          25,  -61,  -83,   35,   21,  -12,  -34,   46,  -21,  -74,  -40,  -37,   -4,  -13,
         -34,   -2,  -24,  -31,   15,  -52,  -35,  -10,   35,  -47,   15,   19,  -57,   11,
           4,  -30,   -7,   -4,    3,  -70,   10,  -61,    9,    6,   19,  -32,   43,    3,
          35,   22,    0,  -27,   31,   21,   -2,   33,   -1,   25,   25,  -13,   30,   -3,
          -9,  -13,   22,   -9,    6,   11,    5,  -43,  -21,  -36,   53,   -1,   11,  -23,
         -17,    5,  -32,   21,  -13,  -13,  -40,  -94,  -11,  -19,   59,  -40,   -1,   -1,
          13,   -5,    3,   13,    9,    5,   15,   31,   -2,    0,  -24,   15,  -12,  -13
    },
    { // class 2
         -33,   61,   67,   22,   -4,  -45,  -59,   32,   24,    7,   12,  -18,  -31,  -29,
          71,   49,   18,    8,  -15,  -28,  -23,   42,   36,   13,   -6,  -35,    2,   19,
          26,   13,   12,    6,    8,    1,   57,   13,  -11,    6,    5,    6,   43,   53,
          -1,   12,    0,  -19,   16,   43,   61,  -16,  -19,   -2,   14,   33,   22,  -17,
         -23,  -14,   20,    6,   -2,    2,   -7,  -70,  -55,  -48,  -24,   15,   12,  -18,
         -39,  -20,  -19,  -17,  -16,  -12,  -11,   24,    9,   33,   20,  -20,  -43,  -18,
          16,   28,   25,   -6,    2,  -18,  -24,   -6,  -19,   -1,   -2,   -7,  -17,    5
    },
    { // class 3
         -14,    9,   27,   36,  -11,  -35,  -78,   45,   20,   24,    7,  -14,  -24,  -34,
          31,   40,   29,   25,    3,   -3,  -11,   25,   22,   16,   24,   17,   16,  -52,
          29,   17,    6,    7,    3,    0,  -20,   20,   30,    9,    6,    9,   -3,  -14,
          -2,   11,   23,   -1,    1,   -9,  -29,   15,  -13,    4,    4,   18,   10,  -15,
          -5,  -10,   -2,   10,   11,   10,    4,  -28,  -36,  -51,   -5,   -2,    6,  -26,
         -40,  -33,    3,   28,  -17,  -12,  -26,   12,  -38,  -17,  -18,   -1,   11,   10,
           3,  -10,  -42,  -22,   29,    5,   -7,   18,    6,   17,   10,   -1,    8,   -5
    },
    { // class 4
         -28,  -26,  -86,  -80,  -33,   -6,   -1,  -45,   16,  -15,  -40,  -19,   17,   42,
         -42,  -38,  -36,  -84,  -54,  -11,  -16,  -25,    4,   14,  -16,  -21,    7,    0,
           8,   29,    2,   26,   37,    9,   14,  -13,  -14,  -27,  -14,   -2,  -25,    7,
           4,  -24,  -24,    1,    8,   14,   18,    0,  -32,  -61,   -7,  -22,  -31,   -6,
          22,    6,   16,    6,   11,   19,   39,   -6,    7,   33,  -23,   21,   -6,   -4,
           7,   21,   10,  -38,   30,   -4,  -42,   -7,   15,   -2,   29,   14,  -23,  -37,
         -14,   -2,   -4,   22,   -2,   17,  -35,  -28,   -6,  -17,  -35,  -16,  -24,    1
    },
    { // class 5
          12,  -39,  -70,  -12,   40,   42,   29,  -61,  -52,  -15,   12,   27,   42,   18,
         -78,  -47,   -8,   18,   16,   44,   93,   55,  -16,    7,   19,   10,   -1,   10,
          58,   35,    5,    4,  -15,  -14,  -25,   83,   42,   21,    5,    0,   -4,  -12,
         -22,   26,   20,    1,    2,  -18,    0,    1,    6,    0,  -12,    3,  -38,  -15,
          39,   38,   23,  -17,  -22,  -17,   11,   16,   22,   15,   -5,  -32,  -62,  -11,
         -64,  -27,   12,   -8,  -20,    1,  -16,  -42,  -39,  -23,  -23,    0,   12,   20,
         -14,  -11,  -22,    5,   14,   -1,   26,    7,  -19,   12,   12,    8,   24,   20
    },
    { // class 6
          11,  -16,   17,   27,   31,   66,   52,  -39,  -32,  -44,   -3,    7,   18,    9,
         -92,  -31,  -34,   -7,    5,    0,   -9,  -87,  -66,  -12,  -15,   16,   -3,    5,
          -7,  -49,   -4,    6,  -12,   14,  -12,  -13,  -22,    5,   13,   17,   10,   -7,
         -20,  -26,   12,   24,   21,    8,  -13,   15,   34,   22,    8,   24,   35,   52,
           4,    0,  -25,  -14,  -35,  -30,  -34,    7,   20,   13,  -26,  -48,   -8,   -8,
          35,   41,   16,    6,   -6,    9,   38,   -9,   14,   27,  -10,   -1,   11,    8,
         -29,    1,   41,   13,    9,  -13,   -6,  -55,  -21,  -42,  -30,  -21,    5,  -55
    },
    { // class 7
          17,  -11,  -39,  -61,  -53,  -27,   -5,   25,   37,   35,  -11,    6,   -9,    4,
          36,    0,   41,   38,   11,   22,  -10,  -10,   30,   11,   -4,   -7,   -4,   -1,
          -8,   43,  -33,  -37,   11,   19,   11,  -17,  -18,  -17,  -20,  -10,   -7,  -27,
          20,  -14,  -37,  -42,  -34,  -46,  -82,  -17,  -39,  -11,   -1,  -24,  -50, -117,
          11,   -2,   14,  -29,   -6,   -1,    4,    6,    1,  -16,   34,   48,    0,  -28,
          15,  -21,  -16,  -19,   29,    0,  -35,  -22,    2,   -2,    3,    6,    7,  -23,
          -6,  -20,   -9,   15,  -27,   -8,  -57,   25,   44,   12,   13,   27,   -4,  -58
    },
    { // class 8
         -28,  -24,   -4,  -22,   -9,    5,   28,  -26,   -3,   -4,   12,   -2,    1,    5,
         -10,  -19,  -14,   -9,   -5,    9,   -6,   46,   10,  -27,   -3,   13,   34,   17,
         -55,  -12,  -30,   18,  -13,   -1,  -39,   -9,  -18,  -16,  -18,   -8,  -20,    5,
          15,  -21,   -3,   30,   22,   -7,   -9,  -20,   -1,  -16,   10,   11,   -3,  -31,
         -16,    4,   12,   -1,    2,   -6,    0,    2,   30,   30,  -18,  -14,   13,   22,
         -12,   -7,  -10,   37,  -17,  -15,   -6,    0,    6,   32,    7,    3,   -7,   -7,
          27,   28,    4,  -26,    0,   10,   26,  -48,  -15,  -16,   -3,  -11,    8,  -15
    },
    { // class 9
           2,  -19,  -70, -100,  -79,  -78,  -56, -127,  -26,    6,   20,   33,   -6,  -29,
         -50,  -12,    1,   11,    5,  -19,  -27,  -26,  -18,    3,   -7,   19,   -2,  -21,
         -27,  -20,   31,   14,   -6,  -31,  -35,  -50,    7,   13,    7,   -2,  -50,  -29,
         -19,    1,  -19,  -29,  -38,  -18,    9, -121,   19,   18,  -60,  -39,    8,  -46,
         -15,  -32,  -16,   21,   14,   -1,  -26,   26,   24,   31,   -8,    4,    6,    0,
          27,   30,   -9,   24,   46,   20,   -3,    0,   -8,  -32,  -25,   14,    5,  -29,
         -13,  -34,  -26,   -6,   -8,  -17,  -12,    9,   32,   32,   29,   18,   21,   21
    }
};

/*======================================*/
/*                BRAM                  */
/*======================================*/

int BRAMinit(int baseAddr){
    int Status;
    XBram_Config *ConfigPtr;
    ConfigPtr = XBram_LookupConfig(baseAddr);
    if (ConfigPtr == NULL) return XST_FAILURE;
    Status = XBram_CfgInitialize(&Bram, ConfigPtr, ConfigPtr->CtrlBaseAddress);
    if (Status != XST_SUCCESS) return XST_FAILURE;
    return XST_SUCCESS;
}

void BRAMwrite(int baseAddr, int wordAddr, u16 val){
    XBram_WriteReg(baseAddr, wordAddr * 4, (u32)val);
}

u16 BRAMread(int baseAddr, int wordAddr){
    return (u16)(XBram_ReadReg(baseAddr, wordAddr * 4) & 0xFFFF);
}

void BRAMimgLoad(int baseAddr){
    for(int i = 0; i < IMG_WIDTH * IMG_HEIGHT; i++){
        BRAMwrite(baseAddr, IMG_BASE + i, image_data[i]);
    }
}

/*======================================*/
/*          AXI Instruction Issue       */
/*======================================*/

void wait_ready() {
    while (!(Xil_In32(IP_BASEADDR + READY_OFFSET) & 0x1));
}

void issue(u32 instr) {
    wait_ready();
    Xil_Out32(IP_BASEADDR + INSTR_OFFSET, instr);
    Xil_Out32(IP_BASEADDR + VALID_OFFSET, 0x1);
    Xil_Out32(IP_BASEADDR + VALID_OFFSET, 0x0);
    wait_ready();
}

/*======================================*/
/*       DEBUG: store reg and dump      */
/*======================================*/

// Store register 'reg' from all PEs to BRAM addr 0-255, then print a few
void debug_dump_reg(int reg, const char* label){
    // Store the register from every PE
    for(int i = 0; i < ROW_LENGTH; i++){
        for(int j = 0; j < COL_LENGTH; j++){
            issue(vstore(i*ROW_LENGTH + j, reg));
        }
    }

    xil_printf("\r\n--- DEBUG %s (reg r%d) ---\r\n", label, reg);

    // Print a 4x4 corner sample
    xil_printf("  Top-left 4x4:\r\n");
    for(int i = 0; i < 4; i++){
        xil_printf("    ");
        for(int j = 0; j < 4; j++){
            u16 raw = BRAMread(XPAR_XBRAM_0_BASEADDR, i*ROW_LENGTH + j);
            int16_t val = (int16_t)raw;
            xil_printf("%6d ", val);
        }
        xil_printf("\r\n");
    }

    // Print centre 4x4
    xil_printf("  Centre (6-9, 6-9):\r\n");
    for(int i = 6; i < 10; i++){
        xil_printf("    ");
        for(int j = 6; j < 10; j++){
            u16 raw = BRAMread(XPAR_XBRAM_0_BASEADDR, i*ROW_LENGTH + j);
            int16_t val = (int16_t)raw;
            xil_printf("%6d ", val);
        }
        xil_printf("\r\n");
    }

    // Check: are ALL values zero?
    int all_zero = 1;
    int nonzero_count = 0;
    for(int i = 0; i < 256; i++){
        u16 raw = BRAMread(XPAR_XBRAM_0_BASEADDR, i);
        if(raw != 0){ all_zero = 0; nonzero_count++; }
    }
    xil_printf("  Nonzero PEs: %d / 256\r\n", nonzero_count);
    if(all_zero) xil_printf("  *** WARNING: ALL ZEROS ***\r\n");
    xil_printf("---\r\n");
}

/*======================================*/
/*       Load 0xFFFF into r7            */
/*======================================*/

void load_constant_r7(void){
    // For each PE: write 0xFFFF to that PE's address, then load it
    for(int i = 0; i < ROW_LENGTH; i++){
        for(int j = 0; j < COL_LENGTH; j++){
            int addr = i * ROW_LENGTH + j;
            BRAMwrite(XPAR_XBRAM_0_BASEADDR, addr, 0xFFFF);
            issue(vload(addr, 7));
        }
    }
    // Restore image data in BRAM (we just overwrote it)
    BRAMimgLoad(XPAR_XBRAM_0_BASEADDR);
}

/*======================================*/
/*       Load image into r1             */
/*======================================*/

void load_image_to_r1(void){
    BRAMimgLoad(XPAR_XBRAM_0_BASEADDR);  
    for(int i = 0; i < ROW_LENGTH; i++){
        for(int j = 0; j < COL_LENGTH; j++){
            issue(vload(IMG_BASE + i*ROW_LENGTH + j, 1));
        }
    }
}

/*======================================*/
/*       CONV1 FILTER 0                 */
/*======================================*/

void conv1_filter0(void){
    xil_printf("=== Conv1 Filter 0 ===\r\n");

    // Clear accumulator r2
    issue(vxor(2, 2, 2));

    // pos(0,0) NW w=89
    issue(mvsouthadd(3, 0, 1));  // r3 = north(r1) + r0 = move
    issue(mveastadd(3, 0, 3));   // r3 = west(r3) = NW
    issue(vsra(4, 3, 7)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 4)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vadd(2, 2, 4));

    // pos(0,1) N w=52
    issue(mvsouthadd(3, 0, 1));
    issue(vsra(4, 3, 5)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 2)); issue(vadd(2, 2, 4));

    // pos(0,2) NE w=119
    issue(mvsouthadd(3, 0, 1));
    issue(mvwestadd(3, 0, 3));
    issue(vsra(4, 3, 7)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 6)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 2)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vadd(2, 2, 4));

    // pos(1,0) W w=63
    issue(mveastadd(3, 0, 1));
    issue(vsra(4, 3, 7)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 6)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 4)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 2)); issue(vadd(2, 2, 4));

    // pos(1,1) SELF w=64
    issue(vsra(4, 1, 1)); issue(vadd(2, 2, 4));

    // pos(1,2) E w=30
    issue(mvwestadd(3, 0, 1));
    issue(vsra(4, 3, 6)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 4)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vadd(2, 2, 4));

    // pos(2,0) SW w=-127
    issue(mvnorthadd(3, 0, 1));
    issue(mveastadd(3, 0, 3));
    issue(vsra(4, 3, 7)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 6)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 4)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 2)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vsub(2, 2, 4));

    // pos(2,1) S w=-90
    issue(mvnorthadd(3, 0, 1));
    issue(vsra(4, 3, 6)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 4)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vsub(2, 2, 4));

    // pos(2,2) SE w=-109
    issue(mvnorthadd(3, 0, 1));
    issue(mvwestadd(3, 0, 3));
    issue(vsra(4, 3, 7)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 4)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 2)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vsub(2, 2, 4));

    xil_printf("  Conv0 pre-ReLU:\r\n");
    //debug_dump_reg(2, "conv0_pre_relu");

    // ReLU
    issue(getmsb(3, 2));
    issue(vxor(3, 3, 7));
    issue(vandd(2, 2, 3));

    xil_printf("  Conv0 post-ReLU:\r\n");
    //debug_dump_reg(2, "conv0_post_relu");

    // Rescale
    issue(vsra(2, 2, 3));

    // Copy result to r6 so it survives the image reload
    issue(vadd(6, 2, 0));

    //debug_dump_reg(6, "conv0_final_in_r6");
    xil_printf("Conv1 filter 0 done\r\n");
}

/*======================================*/
/*       CONV1 FILTER 1                 */
/*======================================*/

void conv1_filter1(void){
    xil_printf("=== Conv1 Filter 1 ===\r\n");

    issue(vxor(2, 2, 2));

    // pos(0,0) NW w=-18
    issue(mvsouthadd(3, 0, 1));
    issue(mveastadd(3, 0, 3));
    issue(vsra(4, 3, 6)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vsub(2, 2, 4));

    // pos(0,1) N w=116
    issue(mvsouthadd(3, 0, 1));
    issue(vsra(4, 3, 5)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 2)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vadd(2, 2, 4));

    // pos(0,2) NE w=71
    issue(mvsouthadd(3, 0, 1));
    issue(mvwestadd(3, 0, 3));
    issue(vsra(4, 3, 7)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 6)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vadd(2, 2, 4));

    // pos(1,0) W w=-25
    issue(mveastadd(3, 0, 1));
    issue(vsra(4, 3, 7)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 4)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 3)); issue(vsub(2, 2, 4));

    // pos(1,1) SELF w=118
    issue(vsra(4, 1, 6)); issue(vadd(2, 2, 4));
    issue(vsra(4, 1, 5)); issue(vadd(2, 2, 4));
    issue(vsra(4, 1, 3)); issue(vadd(2, 2, 4));
    issue(vsra(4, 1, 2)); issue(vadd(2, 2, 4));
    issue(vsra(4, 1, 1)); issue(vadd(2, 2, 4));

    // pos(1,2) E w=-6
    issue(mvwestadd(3, 0, 1));
    issue(vsra(4, 3, 6)); issue(vsub(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vsub(2, 2, 4));

    // pos(2,0) SW w=7
    issue(mvnorthadd(3, 0, 1));
    issue(mveastadd(3, 0, 3));
    issue(vsra(4, 3, 7)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 6)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vadd(2, 2, 4));

    // pos(2,1) S w=66
    issue(mvnorthadd(3, 0, 1));
    issue(vsra(4, 3, 6)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vadd(2, 2, 4));

    // pos(2,2) SE w=103
    issue(mvnorthadd(3, 0, 1));
    issue(mvwestadd(3, 0, 3));
    issue(vsra(4, 3, 7)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 6)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 5)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 2)); issue(vadd(2, 2, 4));
    issue(vsra(4, 3, 1)); issue(vadd(2, 2, 4));

    //debug_dump_reg(2, "conv1_pre_relu");

    // ReLU
    issue(getmsb(3, 2));
    issue(vxor(3, 3, 7));
    issue(vandd(2, 2, 3));

    // Rescale -> store in r5 (not r1, r1 needed for pooling ch0)
    issue(vsra(5, 2, 3));

    //debug_dump_reg(5, "conv1_final_in_r5");
    xil_printf("Conv1 filter 1 done\r\n");
}

/*======================================*/
/*          MAX POOL                    */
/*======================================*/

void maxpool(int store_base, int src_reg, const char* label){
    xil_printf("=== MaxPool %s (from r%d) ===\r\n", label, src_reg);

    // Copy src_reg into r1 for the pooling logic
    issue(vadd(1, src_reg, 0));

    //debug_dump_reg(1, "pool_input_r1");

    // Round 1: max(self, east)
    issue(mvwestadd(2, 0, 1));    // r2 = east of r1
    issue(vsub(3, 1, 2));         // r3 = self - east
    issue(getmsb(4, 3));          // r4 = sign(self-east)
    issue(vxor(5, 4, 7));         // r5 = ~sign
    issue(vandd(3, 1, 5));        // r3 = self where self >= east
    issue(vandd(5, 2, 4));        // r5 = east where east > self
    issue(vorr(1, 3, 5));         // r1 = max(self, east)

    // Round 2: max(result, south)
    issue(mvnorthadd(2, 0, 1));   // r2 = south of r1
    issue(vsub(3, 1, 2));
    issue(getmsb(4, 3));
    issue(vxor(5, 4, 7));
    issue(vandd(3, 1, 5));
    issue(vandd(5, 2, 4));
    issue(vorr(1, 3, 5));         // r1 = max(2x2)

    //debug_dump_reg(1, "pool_max_result");

    // Store all PEs to BRAM first
    for(int i = 0; i < ROW_LENGTH; i++){
        for(int j = 0; j < COL_LENGTH; j++){
            issue(vstore(i*ROW_LENGTH + j, 1));
        }
    }

    // Now copy stride-2 values to pooled storage
    // Conv output valid at rows 1-14, cols 1-14 (borders are garbage)
    // Pool stride-2: pick rows 1,3,5,7,9,11,13 and cols 1,3,5,7,9,11,13
    xil_printf("  Pooled %s values:\r\n", label);
    for(int i = 0; i < 7; i++){
        xil_printf("    ");
        for(int j = 0; j < 7; j++){
            int pe_row = 1 + i*2;
            int pe_col = 1 + j*2;
            int pe_addr = pe_row * ROW_LENGTH + pe_col;
            u16 val = BRAMread(XPAR_XBRAM_0_BASEADDR, pe_addr);
            BRAMwrite(XPAR_XBRAM_0_BASEADDR, store_base + i*7 + j, val);
            int16_t sval = (int16_t)val;
            xil_printf("%5d ", sval);
        }
        xil_printf("\r\n");
    }
}

/*======================================*/
/*     FULLY CONNECTED LAYER            */
/*======================================*/

int fc_layer(void){
    int16_t pooled[98];

    xil_printf("\r\n=== FC Layer ===\r\n");

    // Read 49 pooled values from channel 0
    xil_printf("  Pooled CH0: ");
    for(int i = 0; i < 49; i++){
        u16 raw = BRAMread(XPAR_XBRAM_0_BASEADDR, POOL_CH0_BASE + i);
        pooled[i] = (int16_t)raw;
        if(i < 7) xil_printf("%d ", pooled[i]);
    }
    xil_printf("...\r\n");

    // Read 49 pooled values from channel 1
    xil_printf("  Pooled CH1: ");
    for(int i = 0; i < 49; i++){
        u16 raw = BRAMread(XPAR_XBRAM_0_BASEADDR, POOL_CH1_BASE + i);
        pooled[49 + i] = (int16_t)raw;
        if(i < 7) xil_printf("%d ", pooled[49+i]);
    }
    xil_printf("...\r\n");

    // Check if all pooled values are zero
    int all_zero = 1;
    for(int i = 0; i < 98; i++){
        if(pooled[i] != 0){ all_zero = 0; break; }
    }
    if(all_zero) xil_printf("  *** WARNING: ALL POOLED VALUES ARE ZERO ***\r\n");

    // Compute 10 class scores
    int32_t scores[10];
    int predicted = 0;

    for(int cls = 0; cls < 10; cls++){
        scores[cls] = (int32_t)fc_bias[cls];
        for(int i = 0; i < 98; i++){
            scores[cls] += (int32_t)pooled[i] * (int32_t)fc_weights[cls][i];
        }
        xil_printf("  Class %d: score = %d\r\n", cls, (int)scores[cls]);

        if(scores[cls] > scores[predicted]){
            predicted = cls;
        }
    }

    return predicted;
}

/*======================================*/
/*                 Main                 */
/*======================================*/

int main(){
    init_platform();

    if(BRAMinit(XPAR_XBRAM_0_BASEADDR) != XST_SUCCESS){
        xil_printf("BRAM Init Failed\r\n");
        return XST_FAILURE;
    }

    // Load image
    BRAMimgLoad(XPAR_XBRAM_0_BASEADDR);

    // Verify BRAM has image data
    xil_printf("BRAM image check: [0]=%04x [1]=%04x [127]=%04x [255]=%04x\r\n",
        BRAMread(XPAR_XBRAM_0_BASEADDR, 0),
        BRAMread(XPAR_XBRAM_0_BASEADDR, 1),
        BRAMread(XPAR_XBRAM_0_BASEADDR, 127),
        BRAMread(XPAR_XBRAM_0_BASEADDR, 255));

    u32 ready = Xil_In32(IP_BASEADDR + READY_OFFSET);
    xil_printf("FSM ready: %d\r\n", ready & 0x1);

/*====================================================*/
/*           LOAD IMAGE + CONSTANT                    */
/*====================================================*/

    xil_printf("\r\n=== Loading image into r1 ===\r\n");
    load_image_to_r1();
    //debug_dump_reg(1, "image_in_r1");

    xil_printf("=== Loading 0xFFFF into r7 ===\r\n");
    load_constant_r7();

    // Verify r7 loaded correctly
    //debug_dump_reg(7, "r7_constant");

    // Reload image (load_constant_r7 overwrote BRAM then restored,
    // but r1 in PEs was NOT touched - verify)
    // Actually r1 is fine, load_constant_r7 only loaded into r7
    // But BRAM was temporarily overwritten - we restored it
    // Let's verify r1 is still good:
    //debug_dump_reg(1, "r1_after_r7_load");

/*====================================================*/
/*           CONV1                                    */
/*====================================================*/

    conv1_filter0();    // result in r6

    // Reload image into r1 (NEWS moves during conv corrupted neighbours)
    xil_printf("\r\n=== Reloading image into r1 ===\r\n");
    load_image_to_r1();

    conv1_filter1();    // result in r5

/*====================================================*/
/*           MAX POOL                                 */
/*====================================================*/

    // Pool channel 1 FIRST (r5) because pooling clobbers r1
    maxpool(POOL_CH1_BASE, 5, "CH1");

    // Pool channel 0 (r6)
    maxpool(POOL_CH0_BASE, 6, "CH0");

/*====================================================*/
/*           FC LAYER                                 */
/*====================================================*/

    int predicted = fc_layer();

    xil_printf("\r\n=============================\r\n");
    xil_printf("  PREDICTED DIGIT: %d\r\n", predicted);
    xil_printf("=============================\r\n");

    cleanup_platform();
    return 0;
}