create_clock -period 200.000 -name i2c_core_clock_i -waveform {0.000 100.000} -add [get_ports i2c_core_clock_i]
create_clock -period 10.000 -name pclk_i -waveform {0.000 5.000} -add [get_ports pclk_i]