/*
 * driver.c
 *
 *  Created on: Jun 12, 2024
 *      Author: PC
 */
#include "driver.h"

void i2c_master_init() {
	Xil_Out32(CMD_REG, 0x20); 					//reset i2c master
	Xil_Out32(PRESCALE_REG, 0x0a);				//configure prescaler reg
}
u32 i2c_read(u32 reg_addr) {
	Xil_Out32(ADDR_REG, ADDR_SLAVE_WRITE); 		//write slave's addr and write op
	Xil_Out32(TRANSMIT_REG, reg_addr);     		//write register's addr
	Xil_Out32(CMD_REG, 0x20);					//enable i2c master
	while (!(Xil_In32(STATUS_REG) & ADDR_DONE));
	Xil_Out32(ADDR_REG, ADDR_SLAVE_WRITE);      //update read op
	while (!(Xil_In32(STATUS_REG) & BUS_FREE)); //when stop
	Xil_Out32(CMD_REG, 0x70);					//read 1 byte from register(reg_addr)
	while (!(Xil_In32(STATUS_REG) & BUS_FREE)); //when stop, finish read data

	return Xil_In32(RECEIVE_REG);
}
void i2c_write(u32 reg_addr, u32 data) {
	Xil_Out32(ADDR_REG, ADDR_SLAVE_WRITE);		//write slave's addr and write op
	Xil_Out32(TRANSMIT_REG, reg_addr);			//write register's addr
	Xil_Out32(TRANSMIT_REG, data);				//write data
	Xil_Out32(CMD_REG, 0x20);					//enable i2c master
}
void i2c_slave_config() {
	i2c_write(SLAVE_CONFIG_REG, 0x08);		 	//enable measure mode
	while (!(Xil_In32(STATUS_REG) & BUS_FREE)); //wait until stop condition
}
void i2c_read_data(u32* data) {
	data[0] = i2c_read(X_AXIS_REG_1);
	data[1] = i2c_read(X_AXIS_REG_2);
	data[2] = i2c_read(Y_AXIS_REG_1);
	data[3] = i2c_read(Y_AXIS_REG_2);
	data[4] = i2c_read(Z_AXIS_REG_1);
	data[5] = i2c_read(Z_AXIS_REG_2);
}
