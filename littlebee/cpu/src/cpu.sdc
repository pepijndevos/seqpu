//Copyright (C)2014-2019 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.1.01 Beta
//Created Time: 2019-09-22 15:36:47
create_clock -name pinclock -period 10 -waveform {0 5} [get_ports {clk_100}]
create_generated_clock -name pll -source [get_ports {clk_100}] -master_clock pinclock -divide_by 4 -duty_cycle 50 
