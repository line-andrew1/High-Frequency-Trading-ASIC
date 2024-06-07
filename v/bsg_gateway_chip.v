module bsg_gateway_chip
  `include "bsg_pinout_inverted.v"

  localparam nodes_lp = `NUM_MASTER_NODES;
  localparam core_0_period_lp      = `CORE_0_PERIOD;
  localparam core_1_period_lp      = `CORE_1_PERIOD;
  localparam io_master_0_period_lp = `IO_MASTER_0_PERIOD;
  localparam io_master_1_period_lp = `IO_MASTER_1_PERIOD;

  initial begin
    $fsdbDumpfile("waveform.fsdb");
    $fsdbDumpvars();
  end

  initial begin
    $display("%m gateway creating clocks",core_0_period_lp, core_1_period_lp, io_master_0_period_lp, io_master_1_period_lp);
  end

   wire asic_core_clk, asic_io_master_clk;

   bsg_nonsynth_clock_gen #(.cycle_time_p(core_1_period_lp  ))    asic_core_gen_clk   (.o(asic_core_clk  ));
   bsg_nonsynth_clock_gen #(.cycle_time_p(io_master_1_period_lp)) asic_master_gen_clk (.o(asic_io_master_clk));

   assign p_misc_L_4_o = asic_core_clk;
   assign p_PLL_CLK_o  = asic_io_master_clk;

   wire gateway_core_clk, gateway_io_master_clk;

   bsg_nonsynth_clock_gen #(.cycle_time_p(core_0_period_lp  ))      gateway_core_gen_clk  (.o(gateway_core_clk  ));
   bsg_nonsynth_clock_gen #(.cycle_time_p(io_master_0_period_lp  )) gateway_master_gen_clk(.o(gateway_io_master_clk));

   logic       async_reset_lo;

   localparam core_reset_cycles_hi_lp = 128;
   localparam core_reset_cycles_lo_lp = 16;

   // reset generator for local module
   bsg_nonsynth_reset_gen
     #(.num_clocks_p(4)
       ,.reset_cycles_lo_p(core_reset_cycles_lo_lp)
       ,.reset_cycles_hi_p(core_reset_cycles_hi_lp)
       ) reset_gen
       (.clk_i({ gateway_core_clk, gateway_io_master_clk, asic_core_clk, asic_io_master_clk })
        ,.async_reset_o(async_reset_lo)
        );


   wire [7:0] sdo_data_i_int_packed [0:0];
   wire [7:0] sdi_data_o_int_packed [0:0];

   bsg_make_2D_array #(.width_p(8),.items_p(1)) m2da
     (.i({p_sdo_A_data_i})
      ,.o(sdo_data_i_int_packed)
      );

   // we swap B input and C input on both ASIC and Gateway to make physical design easier
   bsg_flatten_2D_array #(.width_p(8),.items_p(1)) f2da
     (.i(sdi_data_o_int_packed)
      ,.o({p_sdi_A_data_o})
      );

   wire       core_calib_reset;

`define BSG_SWIZZLE_3120(a) { a[3],a[1],a[2],a[0] }


   bsg_guts #(.num_channels_p(1)
              ,.master_p(1)
              ,.master_to_client_speedup_p(100)
              ,.master_bypass_test_p(5'b11111)
              ,.enabled_at_start_vec_p({ (nodes_lp) {1'b1} })
              ,.nodes_p(nodes_lp)
              ) guts
     (.core_clk_i               ( gateway_core_clk      )  // locally generated
      ,.async_reset_i           ( async_reset_lo        )
      ,.io_master_clk_i         ( gateway_io_master_clk    )  // locally generated
      ,.io_clk_tline_i          ( p_sdo_sclk_i[0]       )
      ,.io_valid_tline_i        ( p_sdo_ncmd_i[0]       )
      ,.io_data_tline_i         ( sdo_data_i_int_packed )
      ,.io_token_clk_tline_o    ( p_sdo_token_o[0]      )
      ,.im_clk_tline_o          ( p_sdi_sclk_o[0]  )
      ,.im_valid_tline_o        ( p_sdi_ncmd_o[0]  )
      ,.im_data_tline_o         ( sdi_data_o_int_packed            )
      ,.token_clk_tline_i       ( p_sdi_token_i[0] )
      ,.im_slave_reset_tline_r_o( p_reset_o )
      ,.core_reset_o            (core_calib_reset)
      );


   localparam cycle_counter_width_lp=32;

   wire [cycle_counter_width_lp-1:0] core_ctr[1:0];
   wire [cycle_counter_width_lp-1:0] io_ctr  [1:0];

   wire [nodes_lp-1:0]               done_signals;

   bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
   gw_core_ctr (.clk_i(gateway_core_clk), .reset_i(core_calib_reset), .ctr_r_o(core_ctr[0]));

   bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
   gw_io_ctr   (.clk_i(gateway_io_master_clk), .reset_i(core_calib_reset), .ctr_r_o(io_ctr[0]));

   bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
   asic_core_ctr (.clk_i(asic_core_clk), .reset_i(core_calib_reset), .ctr_r_o(core_ctr[1]));

   bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
   asic_io_ctr   (.clk_i(asic_io_master_clk), .reset_i(core_calib_reset), .ctr_r_o(io_ctr[1]));


   localparam channel_width_lp = 8;
   localparam num_channels_lp  = 1;
   localparam verbose_lp       = 0;
   localparam iterations_lp    = 16;
   localparam ring_bytes_lp    = 10;
   
   //always @(negedge gateway_core_clk)
   //  if ((& done_signals) == 1'b1)
   //    $finish("##");

   // assign unuseds, so it's clear they're here
   // and to clean up X's in simulation

   assign p_misc_T_0_o = 1'b0;
   assign p_misc_T_1_o = 1'b0;
   assign p_misc_T_2_o = 1'b0;

   assign p_misc_L_0_o = 1'b0;
   assign p_misc_L_1_o = 1'b0;
   assign p_misc_L_2_o = 1'b0;

   assign p_misc_R_0_o = 1'b0;
   assign p_misc_R_1_o = 1'b0;
   assign p_misc_R_2_o = 1'b0;

   assign p_JTAG_TMS_o = 1'b0;
   assign p_JTAG_TDI_o = 1'b0;
   assign p_JTAG_TCK_o = 1'b0;
   assign p_JTAG_TST_o = 1'b0;

   wire _unused1 = p_JTAG_TDO_i;
   wire _unused2 = p_misc_L_3_i;
   wire _unused3 = p_misc_R_3_i;

   assign p_misc_R_4_o = 1'b0;
   assign p_misc_R_5_o = 1'b0;
   assign p_misc_R_6_o = 1'b0;
   assign p_misc_R_7_o = 1'b0;

   // assign p_misc_L_4_o = 1'b0;  used as clock input for ASIC
   assign p_misc_L_5_o = 1'b0;
   assign p_misc_L_6_o = 1'b0;
   assign p_misc_L_7_o = 1'b0;

   assign                p_sdo_tkn_ex_o = 4'b0;
   wire [3:0] _unused4 = p_sdi_tkn_ex_i;

   assign p_sdi_sclk_ex_o = 4'b0;
   wire [3:0] _unused5    = p_sdo_sclk_ex_i;

   assign p_clk_0_p_o = 1'b0;
   assign p_clk_0_n_o = 1'b1;

   assign p_clk_1_p_o = 1'b0;
   assign p_clk_1_n_o = 1'b1;


    genvar i;
    logic [nodes_lp-1:0] done_n;
    for (i = 0; i < nodes_lp; i++) begin
        assign done_n[i] = guts.n[i].mstr.mstr.done_lo;
    end
    wire all_done = &done_n;
    always @(posedge all_done)
        $finish();


endmodule
