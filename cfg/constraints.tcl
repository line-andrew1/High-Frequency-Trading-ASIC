# constraints.tcl
#
# This file is where design timing constraints are defined for Genus and Innovus.
# Many constraints can be written directly into the Hammer config files. However, 
# you may manually define constraints here as well.
#

set CORE_CLOCK_PERIOD 5.2     
set IO_MASTER_CLOCK_PERIOD 15

# << arguments >>
# bsg_chip_timing_constraint
#     [package
#     [reset_port]
#     [core_clk_port]
#     [core_clk_name]
#     [core_clk_period]
#     [master_io_clk_port]
#     [master_io_clk_name]
#     [master_io_clk_period]
#     [create_core_clk]
#     [create_master_clk]
#     [input_cell_rise_fall_difference]
#     [output_cell_rise_fall_difference_A]
#     [output_cell_rise_fall_difference_B]
#     [output_cell_rise_fall_difference_C]
#     [output_cell_rise_fall_difference_D]

bsg_chip_timing_constraint    \
    ucsd_bsg_332              \
    [get_ports p_reset_i]     \
    [get_ports p_misc_L_4_i]  \
    core_clk                  \
    ${CORE_CLOCK_PERIOD}      \
    [get_ports p_PLL_CLK_i]   \
    master_io_clk             \
    ${IO_MASTER_CLOCK_PERIOD} \
    1                         \
    1                         \
    0                         \
    0                         \
    0                         \
    0                         \
    0 

