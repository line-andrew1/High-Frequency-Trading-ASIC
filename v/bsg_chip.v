
/**
 * BSG Chip
 *
 * Toplevel module. The bsg_pinout.v file defines all of the input
 * and output ports for this module. The port will be defined in
 * the ee477-packaging directory.
 */
module bsg_chip
    `include "bsg_pinout.v"
    `bsg_pinout_macro

    // Pack the input data
    //
    wire [7:0] sdi_data_i_int_packed [0:0];
    bsg_make_2D_array #(.width_p(8)
                       ,.items_p(1))
      m2da
        (.i( {sdi_A_data_i_int} )
        ,.o( sdi_data_i_int_packed )
        );

    // Unpack the output data
    //
    wire [7:0] sdo_data_o_int_packed [0:0];
    bsg_flatten_2D_array #(.width_p(8)
                          ,.items_p(1))
      f2da
        (.i( sdo_data_o_int_packed )
        ,.o( {sdo_A_data_o_int} )
        );

    //  ____ ____   ____    ____       _
    // | __ ) ___| / ___|  / ___|_   _| |_ ___
    // |  _ \___ \| |  _  | |  _| | | | __/ __|
    // | |_) |__) | |_| | | |_| | |_| | |_\__ \
    // |____/____/ \____|  \____|\__,_|\__|___/

    bsg_guts #(.num_channels_p  ( 1 )
              ,.channel_width_p ( 8 )
              ,.nodes_p         ( 1 )
              )
      guts
        (.core_clk_i               ( misc_L_4_i_int        )
        ,.async_reset_i            ( reset_i_int           )
        ,.io_master_clk_i          ( PLL_CLK_i_int         )
        ,.io_clk_tline_i           ( sdi_sclk_i_int[0]     )
        ,.io_valid_tline_i         ( sdi_ncmd_i_int[0]     )
        ,.io_data_tline_i          ( sdi_data_i_int_packed )
        ,.io_token_clk_tline_o     ( sdi_token_o_int[0]    )
        ,.im_clk_tline_o           ( sdo_sclk_o_int[0]     )
        ,.im_valid_tline_o         ( sdo_ncmd_o_int[0]     )
        ,.im_data_tline_o          ( sdo_data_o_int_packed )
        ,.token_clk_tline_i        ( sdo_token_i_int[0]    )
        ,.im_slave_reset_tline_r_o ()   // unused by ASIC
        ,.core_reset_o             ()   // post calibration reset
        );

    // `include "bsg_pinout_end.v"
endmodule
