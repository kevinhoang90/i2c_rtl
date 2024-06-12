
/*
 * driver.h
 *
 *  Created on: Jun 12, 2024
 *      Author: PC
 */
#include "platform_config.h"
#include "xil_io.h"
#include "unistd.h"

#ifndef SRC_DRIVER_H_
#define SRC_DRIVER_H_

#define ADDR_DONE 1 << 4
#define BUS_FREE 1 << 5
#define ADDR_SLAVE_READ 0xA6
#define ADDR_SLAVE_WRITE 0xA7
#define SLAVE_CONFIG_REG 0x2D

void i2c_master_init();
u32 i2c_read();
void i2c_write();
void i2c_slave_config();
void i2c_read_data(u32* data);

#endif /* SRC_DRIVER_H_ */
