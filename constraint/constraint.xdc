create_clock -period 50.000 -name i2c_core_clock_i -waveform {0.000 25.000} -add [get_ports i2c_core_clock_i]
create_clock -period 20.000 -name pclk_i -waveform {0.000 10.000} -add [get_ports pclk_i]