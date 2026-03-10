#include <stdio.h>
#include <xil_types.h>
#include <xstatus.h>
#include "platform.h"
#include "xil_printf.h"
#include "xbram.h"
#include "xparameters.h"
#include "Instructions.h"

//NOTE: if ld not working, go to code /home/gary/Individual_Project_System/hello_world/src/UserConfig.cmake
//Add Instructions.c into 
//set(USER_COMPILE_SOURCES
//    helloworld.c
//    platform.c
//    Instructions.c    # add this
//)

//right now, if rd = rs1 or rs2, the system fails as there are repeated instruction executions.

/*======================================*/
/*              DEFINES                 */
/*======================================*/

#define ROW_LENGTH 2
#define COL_LENGTH 2

#define IP_BASEADDR  XPAR_AXI_ARRAYPROC_0_BASEADDR
#define INSTR_OFFSET 0x00
#define VALID_OFFSET 0x04
#define READY_OFFSET 0x08

XBram Bram;

/*======================================*/
/*                BRAM                  */
/*======================================*/

int BRAMinit(int baseAddr){
    int Status;
    XBram_Config *ConfigPtr;

    ConfigPtr = XBram_LookupConfig(baseAddr);
    if (ConfigPtr == (XBram_Config *) NULL)
        return XST_FAILURE;

    Status = XBram_CfgInitialize(&Bram, ConfigPtr,
                                 ConfigPtr->CtrlBaseAddress);
    if (Status != XST_SUCCESS)
        return XST_FAILURE;

    return XST_SUCCESS;
}

void BRAMimgInt(int baseAddr){
    XBram_WriteReg(baseAddr, 0x00, 0x00);
    XBram_WriteReg(baseAddr, 0x04, 0x50);
    XBram_WriteReg(baseAddr, 0x08, 0x00);
    XBram_WriteReg(baseAddr, 0x0C, 0x50);
}

void BRAMimgRead(int baseAddr){
    int tempVar;
    for(int i = 0; i < 16; i += 4){
        tempVar = XBram_ReadReg(baseAddr, i);
        xil_printf("%d: %x\n", i, tempVar);
    }
}

/*======================================*/
/*         Printing Binary Function     */
/*======================================*/

void print_binary32(uint32_t val) {
    for (int i = 31; i >= 0; i--) {
        xil_printf("%d", (val >> i) & 1);
        if (i % 4 == 0 && i != 0) xil_printf("_");
    }
    xil_printf("\r\n");
}

/*======================================*/
/*          AXI Instruction Issue       */
/*======================================*/

void wait_ready() {
    while (!(Xil_In32(IP_BASEADDR + READY_OFFSET) & 0x1));
}

void issue_instruction(u32 instr) {
    wait_ready();
    Xil_Out32(IP_BASEADDR + INSTR_OFFSET, instr);    
    Xil_Out32(IP_BASEADDR + VALID_OFFSET, 0x1);    
    Xil_Out32(IP_BASEADDR + VALID_OFFSET, 0x0); 
    wait_ready();
}

/*======================================*/
/*                 Main                 */
/*======================================*/

int main(){

    init_platform();

    // BRAM Init
    if (BRAMinit(XPAR_XBRAM_0_BASEADDR) != XST_SUCCESS){
        xil_printf("Bram Init Failed\r\n");
        return XST_FAILURE;
    }

    // BRAM Write
    BRAMimgInt(XPAR_XBRAM_0_BASEADDR);

    // BRAM Read
    BRAMimgRead(XPAR_XBRAM_0_BASEADDR);

    // Sanity check
    u32 ready = Xil_In32(IP_BASEADDR + READY_OFFSET);
    xil_printf("FSM ready at startup: %d\r\n", ready & 0x1);

    /*================ LOAD A -> r1 ================*/
    for (int i = 0; i < ROW_LENGTH; i++) {
        for (int j = 0; j < COL_LENGTH; j++) {
            xil_printf("LOAD (%d,%d)\r\n", i, j);
            issue_instruction(vload((i*ROW_LENGTH + j), 1));
        }
    }

    /*================ Gx Calculation ================*/

    xil_printf("B = A + A North\r\n");
    issue_instruction(mvnorthadd(2, 1, 1));

    xil_printf("C = B + B South\r\n");
    issue_instruction(mvsouthadd(2, 2, 2));

    xil_printf("C East -> r3\r\n");
    issue_instruction(mveastadd(3, 0, 2));

    xil_printf("C West -> r4\r\n");
    issue_instruction(mvwestadd(4, 0, 2));

    xil_printf("D = C West - C East -> r5\r\n");
    issue_instruction(vsub(5, 3, 4));

    /*================ Gy Calculation ================*/

    xil_printf("B = A + A East\r\n");
    issue_instruction(mveastadd(2, 1, 1));

    xil_printf("C = B + B West\r\n");
    issue_instruction(mvwestadd(2, 2, 2));

    xil_printf("C North -> r3\r\n");
    issue_instruction(mvnorthadd(3, 0, 2));

    xil_printf("C South -> r4\r\n");
    issue_instruction(mvsouthadd(4, 0, 2));

    xil_printf("E = C North - C South -> r6\r\n");
    issue_instruction(vsub(6, 3, 4));

    /*================ Magnitude ================*/

    xil_printf("|Gx| = |r5|\r\n");
    issue_instruction(vabs(5, 5));

    xil_printf("|Gy| = |r6|\r\n");
    issue_instruction(vabs(6, 6));

    xil_printf("|Gx| + |Gy| -> r6\r\n");
    issue_instruction(vadd(6, 5, 6));


    /*================ STORE ================*/
    for (int i = 0; i < ROW_LENGTH; i++) {
        for (int j = 0; j < COL_LENGTH; j++) {
            xil_printf("STORE (%d,%d)\r\n", i, j);
            issue_instruction(vstore((i*ROW_LENGTH + j), 6));
            BRAMimgRead(XPAR_XBRAM_0_BASEADDR);
        }
    }

    xil_printf("Sobel Done\r\n");


    // BRAM Read after processing
    BRAMimgRead(XPAR_XBRAM_0_BASEADDR);

    cleanup_platform();
    return 0;
}