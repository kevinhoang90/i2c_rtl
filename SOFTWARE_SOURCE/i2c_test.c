/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

//after implement RTL code into FPGA, I'll use i2c slave ADXL345 to test i2c master's function 

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "unistd.h"
#include "driver.h"
#include "stdlib.h"
int main()
{
	u32* data;
	data = (u32*) malloc (6 * 4);
    init_platform();
    usleep(10);
    i2c_master_init();
    i2c_slave_config();
    i2c_read_data(data);
    printf("X_AXIS_DATA_1: %lu", (unsigned long) data[0]);
    printf("X_AXIS_DATA_2: %lu", (unsigned long) data[1]);
    printf("Y_AXIS_DATA_1: %lu", (unsigned long) data[2]);
    printf("Y_AXIS_DATA_2: %lu", (unsigned long) data[3]);
    printf("Z_AXIS_DATA_1: %lu", (unsigned long) data[4]);
    printf("Z_AXIS_DATA_2: %lu", (unsigned long) data[5]);
    cleanup_platform();
    return 0;
}
