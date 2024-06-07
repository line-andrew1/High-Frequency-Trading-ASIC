
`include "bsg_noc_links.vh"

module bsg_guts 

  import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (local node)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south
  
  // wormhole routing matrix
  import bsg_wormhole_router_pkg::StrictX;
  import bsg_fsb_pkg::*;

 #(parameter num_channels_p=4
  ,parameter channel_width_p=8
  ,parameter enabled_at_start_vec_p=0
  ,parameter master_p=0
  ,parameter master_to_client_speedup_p=100
  ,parameter master_bypass_test_p=5'b00000
  ,parameter nodes_p=1
  ,parameter uniqueness_p=0
  ,localparam max_val_lp = 32
  
  ,parameter wh_cord_offset_p = 4
  ,parameter flit_width_p = 32
  ,parameter dims_p = 1
  ,parameter int cord_markers_pos_p[dims_p:0] = '{4, 0}
  ,parameter dirs_p = dims_p*2+1
  ,parameter bit [1:0][dirs_p-1:0][dirs_p-1:0] routing_matrix_p = StrictX
  ,parameter len_width_p = 4
  ,localparam cord_width_lp = cord_markers_pos_p[dims_p]
  )
   (
    input core_clk_i
    , input async_reset_i
    , input io_master_clk_i

    // input from i/o
    , input  [num_channels_p-1:0] io_clk_tline_i       // clk
    , input  [num_channels_p-1:0] io_valid_tline_i
    , input  [channel_width_p-1:0] io_data_tline_i [num_channels_p-1:0]
    , output [num_channels_p-1:0] io_token_clk_tline_o // clk

    // out to i/o
    , output [num_channels_p-1:0] im_clk_tline_o       // clk
    , output [num_channels_p-1:0] im_valid_tline_o
    , output [channel_width_p-1:0] im_data_tline_o [num_channels_p-1:0]
    , input  [num_channels_p-1:0] token_clk_tline_i    // clk

    // note: generate by the master (FPGA) and sent to the slave (ASIC)
    // not used by slave (ASIC).
    , output                  im_slave_reset_tline_r_o

    // this signal is the post-calibration reset signal
    // synchronous to the core clock
    , output                       core_reset_o
    );

   localparam ring_bytes_lp = 10;
   localparam ring_width_lp = ring_bytes_lp*channel_width_p;

   // into nodes (fsb interface)
   wire [nodes_p-1:0]       core_node_v_A;
   wire [ring_width_lp-1:0] core_node_data_A [nodes_p-1:0];
   wire [nodes_p-1:0]       core_node_ready_A;

    // into nodes (control)
   wire [nodes_p-1:0] core_node_en_r_lo;
   wire [nodes_p-1:0] core_node_reset_r_lo;

    // out of nodes (fsb interface)
   wire [nodes_p-1:0]       core_node_v_B;
   wire [ring_width_lp-1:0] core_node_data_B [nodes_p-1:0];
   wire [nodes_p-1:0]       core_node_yumi_B;

   // state definition for bsg_link reset sequence
   typedef enum {S1, S2, S3, S4, S5, S6, S7, S8} reset_state_e;
   reset_state_e reset_state_n, reset_state_r;
   
   // resets used for bsg_link
   logic async_token_reset;
   logic core_io_upstream_link_reset_n, core_io_upstream_link_reset_r;
   logic core_clk_link_reset_n, core_clk_link_reset_r;
   logic core_io_downstream_link_reset_n, core_io_downstream_link_reset_r;
   
   // used for bsg_counter_up
   logic [`BSG_SAFE_CLOG2(max_val_lp+1)-1:0] counter_r, counter_n;
   
   
   // reset synchronizer
   logic sync_reset_lo;
   
  bsg_sync_sync 
 #(.width_p(1)
  ) bss_reset
  (.oclk_i(core_clk_i)
  ,.iclk_data_i(async_reset_i)
  ,.oclk_data_o(sync_reset_lo)
  );
   
   
   always_ff @(posedge core_clk_i)
    if (sync_reset_lo)
        counter_r <= 0;
    else
        counter_r <= counter_n;

   // reset used for bsg_fsb
   logic core_calib_done_r_lo;
   
   // instantiate murn nodes here

   genvar                           i;

   for (i = 0; i < nodes_p; i=i+1)
     begin : n
        if (master_p)
          begin: mstr
             bsg_test_node_master
               #(.ring_width_p(ring_width_lp)
                 ,.master_id_p(i)
                 ,.client_id_p(i)
                 ) mstr
                 (.clk_i   (core_clk_i                )
                  ,.reset_i(core_node_reset_r_lo [i])

                  ,.v_i    (core_node_v_A      [i])
                  ,.data_i (core_node_data_A   [i])
                  ,.ready_o(core_node_ready_A  [i])

                  ,.v_o    (core_node_v_B      [i])
                  ,.data_o (core_node_data_B   [i])
                  ,.yumi_i (core_node_yumi_B   [i])

                  ,.en_i   (core_node_en_r_lo  [i])
                  );
          end
        else
          begin: clnt
             bsg_test_node_client
               #(.ring_width_p(ring_width_lp)
                 ,.master_id_p(i)
                 ,.client_id_p(i)
                 ) clnt
                 (.clk_i   (core_clk_i                )
                  ,.reset_i(core_node_reset_r_lo [i])

                  ,.v_i    (core_node_v_A      [i])
                  ,.data_i (core_node_data_A   [i])
                  ,.ready_o(core_node_ready_A  [i])

                  ,.v_o    (core_node_v_B      [i])
                  ,.data_o (core_node_data_B   [i])
                  ,.yumi_i (core_node_yumi_B   [i])

                  ,.en_i   (core_node_en_r_lo  [i])
                  );
          end
     end

   // should not need to modify

   always_comb begin
    //reset states
    reset_state_n = reset_state_r;
    
    //link reset initialization
    async_token_reset = 0;
    core_clk_link_reset_n = core_clk_link_reset_r;
    core_io_upstream_link_reset_n = core_io_upstream_link_reset_r;
    core_io_downstream_link_reset_n = core_io_downstream_link_reset_r;
    
    //counter_set 
    counter_n = counter_r + 1;
    
    //fsb reset
    core_calib_done_r_lo = 0;
    
    case (reset_state_r)
      S1: begin
            if (counter_r == max_val_lp) begin
              reset_state_n = S2;
              counter_n = 0;
            end
          end
          
      S2: begin
            async_token_reset = 1;
            if (counter_r == max_val_lp) begin
              reset_state_n = S3;
              counter_n = 0;
            end
          end
   
      S3: begin
            async_token_reset = 0;
            if (counter_r == max_val_lp) begin
              reset_state_n = S4;
              counter_n = 0;
            end
          end
          
      S4: begin
            core_io_upstream_link_reset_n = 0;
            if (counter_r == max_val_lp) begin
              reset_state_n = S5;
              counter_n = 0;
            end
          end
          
      S5: begin
            core_io_downstream_link_reset_n = 1;
            if (counter_r == max_val_lp) begin
              reset_state_n = S6;
              counter_n = 0;
            end
          end
          
      S6: begin
            core_io_downstream_link_reset_n = 0;
            if (counter_r == max_val_lp) begin
              reset_state_n = S7;
              counter_n = 0;
            end
          end
   
      S7: begin
            core_clk_link_reset_n = 0;
            if (counter_r == max_val_lp) begin
              reset_state_n = S8;
              counter_n = 0;
            end
          end
          
      S8: begin
            core_calib_done_r_lo = 1;
          end
    endcase
   end
   
   // for reset state machine
   always_ff @(posedge core_clk_i) begin
      if (sync_reset_lo)
        reset_state_r <= S1;
      else
        reset_state_r <= reset_state_n;
   end
   
   // for core_clk_link_reset
   always_ff @(posedge core_clk_i) begin
      if (sync_reset_lo)
        core_clk_link_reset_r <= 1;
      else
        core_clk_link_reset_r <= core_clk_link_reset_n;
   end
   
   // for io_upstream_link_reset
   always_ff @(posedge core_clk_i) begin
      if (sync_reset_lo)
        core_io_upstream_link_reset_r <= 1;
      else
        core_io_upstream_link_reset_r <= core_io_upstream_link_reset_n;
   end
   
   // for io_downstream_link_reset
   always_ff @(posedge core_clk_i) begin
      if (sync_reset_lo)
        core_io_downstream_link_reset_r <= 0;
      else
        core_io_downstream_link_reset_r <= core_io_downstream_link_reset_n;
   end 
   
   logic io_upstream_link_reset, io_downstream_link_reset;
   
   // synchronizer for upstream/downstream link reset
   bsg_launch_sync_sync #(.width_p(1)) link_upstream_reset_sync_sync
   (.iclk_i         (core_clk_i)
   ,.iclk_reset_i   (1'b0)
   ,.oclk_i         (io_master_clk_i)
   ,.iclk_data_i    (core_io_upstream_link_reset_r)
   
   ,.iclk_data_o    ()
   ,.oclk_data_o    (io_upstream_link_reset)
   );
  
   bsg_launch_sync_sync #(.width_p(1)) link_downstream_reset_sync_sync
   (.iclk_i         (core_clk_i)
   ,.iclk_reset_i   (1'b0)
   ,.oclk_i         (io_clk_tline_i[0])
   ,.iclk_data_i    (core_io_downstream_link_reset_r)
   
   ,.iclk_data_o    ()
   ,.oclk_data_o    (io_downstream_link_reset)
   ); 

   wire core_clk_link_reset = core_clk_link_reset_r;
   assign im_slave_reset_tline_r_o = sync_reset_lo;
   assign core_reset_o = ~core_calib_done_r_lo;
   
   // fsb in
   wire                     core_cl_valid_lo;
   wire [flit_width_p-1:0] core_cl_data_lo;
   wire                     core_fsb_yumi_lo;

   // fsb out
   wire                     core_fsb_valid_lo;
   wire [flit_width_p-1:0] core_fsb_data_lo;
   wire                     core_cl_ready_lo;
   
   
   logic [num_channels_p-1:0] io_token_clk_tline_lo;
   logic [num_channels_p-1:0] im_clk_tline_lo;
   logic [num_channels_p-1:0] im_valid_tline_lo;
   logic [num_channels_p-1:0][channel_width_p-1:0] im_data_tline_lo;
   
   assign io_token_clk_tline_o = io_token_clk_tline_lo;
   assign im_clk_tline_o = im_clk_tline_lo;
   assign im_valid_tline_o = im_valid_tline_lo;
   for (genvar j = 0; j < num_channels_p; j++)
    assign im_data_tline_o[j] = im_data_tline_lo[j];
    
   logic [num_channels_p-1:0][channel_width_p-1:0] io_data_tline_li;
   for (genvar j = 0; j < num_channels_p; j++)
    assign io_data_tline_li[j] = io_data_tline_i[j];
   
   // link upstream (on one side)
   bsg_link_ddr_upstream #(.width_p (flit_width_p)
                          ,.channel_width_p (channel_width_p)
                          ,.num_channels_p  (num_channels_p)
                          //,.lg_fifo_depth_p () use default
                          //,.lg_credit_to_token_decimation_p () use default
                          //,.lg_credit_to_token_decimation_p () use default
                          //,.use_extra_data_bit_p () use default
                          ) link_upstream
                  
   (.core_clk_i         (core_clk_i)            //clk
   
   // reset signals: generate this reset based on sync_reset_lo
   ,.core_link_reset_i   (core_clk_link_reset) 
   ,.io_link_reset_i     (io_upstream_link_reset) 
   ,.async_token_reset_i (async_token_reset)   
   
   // out of nodes (fsb interface) 
   ,.core_data_i        (core_fsb_data_lo)         
   ,.core_valid_i       (core_fsb_valid_lo)
   ,.core_ready_o       (core_cl_ready_lo)
   
   // in from i/o
  ,.io_clk_i            (io_master_clk_i) // clk
  ,.token_clk_i         (token_clk_tline_i)  // clk
  
   // out to i/o
  ,.io_clk_r_o          (im_clk_tline_lo)  // clk
  ,.io_data_r_o         (im_data_tline_lo)
  ,.io_valid_r_o        (im_valid_tline_lo)
  );
  
   // link downstream (on the same side as upstream)
   bsg_link_ddr_downstream #(.width_p (flit_width_p)
                          ,.channel_width_p (channel_width_p)
                          ,.num_channels_p  (num_channels_p)
                          //,.lg_fifo_depth_p () use default
                          //,.lg_credit_to_token_decimation_p () use default
                          //,.lg_credit_to_token_decimation_p () use default
                          //,.use_extra_data_bit_p () use default
                          ) link_downstream
                          
   (.core_clk_i         (core_clk_i)             //clk
   
   // reset signals: generate this reset based on sync_reset_lo
   ,.core_link_reset_i  (core_clk_link_reset) 
   ,.io_link_reset_i    (io_downstream_link_reset)       
   
   // into nodes (fsb interface)
   ,.core_data_o        (core_cl_data_lo)
   ,.core_valid_o       (core_cl_valid_lo)
   ,.core_yumi_i        (core_fsb_yumi_lo)
   
   // in from i/o
   ,.io_clk_i           (io_clk_tline_i) // clk from upstream's io_clk_r_o
   ,.io_data_i          (io_data_tline_li) 
   ,.io_valid_i         (io_valid_tline_i)
   
   ,.core_token_r_o     (io_token_clk_tline_lo) 
   );
   
   
  // ral link declaration
  `declare_bsg_ready_and_link_sif_s(flit_width_p,bsg_ready_and_link_sif_s);
  `declare_bsg_ready_and_link_sif_s(ring_width_lp,bsg_fsb_link_sif_s);
   
  bsg_ready_and_link_sif_s [nodes_p-1:0][dirs_p-1:0] router_link_li;
  bsg_ready_and_link_sif_s [nodes_p-1:0][dirs_p-1:0] router_link_lo;
  
  bsg_fsb_link_sif_s [nodes_p-1:0] adapter_link_li;
  bsg_fsb_link_sif_s [nodes_p-1:0] adapter_link_lo;
  
  bsg_fsb_pkt_s [nodes_p-1:0] core_node_B_pkt_lo;
  logic [nodes_p-1:0][cord_width_lp-1:0] adapter_dest_cord_lo;
  
  // Wormhole routers and ral adapters
  for (genvar j = 0; j < nodes_p; j++) 
  begin: loop
  
    localparam my_cord_lp = (master_p == 0)? j + wh_cord_offset_p : j;
  
    bsg_wormhole_router
   #(.flit_width_p      (flit_width_p)
    ,.dims_p            (dims_p)
    ,.cord_markers_pos_p(cord_markers_pos_p)
    ,.routing_matrix_p  (routing_matrix_p)
    ,.len_width_p       (len_width_p)
    ) router
    (.clk_i    (core_clk_i)
  ,.reset_i  (~core_calib_done_r_lo)
  ,.my_cord_i(cord_width_lp'(my_cord_lp))
  ,.link_i   (router_link_li[j])
  ,.link_o   (router_link_lo[j])
  );
    
    // router chain stitching
    if (j > 0)
      begin
        assign router_link_li[j-1][E] = router_link_lo[j][W];
        assign router_link_li[j][W] = router_link_lo[j-1][E];
      end
      
    // bsg ral adapter
    bsg_ready_and_link_async_to_wormhole
   #(.ral_link_width_p(ring_width_lp)
    ,.flit_width_p(flit_width_p)
    ,.dims_p(dims_p)
    ,.cord_markers_pos_p(cord_markers_pos_p)
    ,.len_width_p(len_width_p)
    ) adapter
    (// ral (ready_and_link) side
     .ral_clk_i(core_clk_i)
    ,.ral_reset_i(~core_calib_done_r_lo)
    
    ,.ral_link_i(adapter_link_li[j])
    ,.ral_link_o(adapter_link_lo[j])
    ,.ral_dest_cord_i(adapter_dest_cord_lo[j])
    
    // Wormhole side
    ,.wh_clk_i(core_clk_i)
    ,.wh_reset_i(~core_calib_done_r_lo)
    
    ,.wh_link_i(router_link_lo[j][P])
    ,.wh_link_o(router_link_li[j][P])
    );
    
    assign adapter_link_li[j].v = core_node_v_B[j];
    assign adapter_link_li[j].data = core_node_data_B[j];
    assign core_node_yumi_B[j] = core_node_v_B[j] & adapter_link_lo[j].ready_and_rev;
    
    assign core_node_v_A[j] = adapter_link_lo[j].v;
    assign core_node_data_A[j] = adapter_link_lo[j].data;
    assign adapter_link_li[j].ready_and_rev = core_node_ready_A[j];
    
    // routing destination settings
    assign core_node_B_pkt_lo[j] = core_node_data_B[j];
    
    if (master_p == 0)
        assign adapter_dest_cord_lo[j] = core_node_B_pkt_lo[j].destid;
    else
        assign adapter_dest_cord_lo[j] = core_node_B_pkt_lo[j].destid + wh_cord_offset_p;
    
    assign core_node_reset_r_lo[j] = ~core_calib_done_r_lo;
    assign core_node_en_r_lo[j] = core_calib_done_r_lo;
    
  end
  
  // if client, tie off east and exit to west
  if (master_p == 0)
  begin
    assign router_link_li[0][E] = '0;
    
    assign router_link_li[nodes_p-1][W].v = core_cl_valid_lo;
    assign router_link_li[nodes_p-1][W].data = core_cl_data_lo;
    assign core_fsb_yumi_lo = core_cl_valid_lo & router_link_lo[nodes_p-1][W].ready_and_rev;
    
    assign core_fsb_valid_lo = router_link_lo[nodes_p-1][W].v;
    assign core_fsb_data_lo = router_link_lo[nodes_p-1][W].data;
    assign router_link_li[nodes_p-1][W].ready_and_rev = core_cl_ready_lo;
  end
  // if master, tie off west and exit to east
  else
  begin
    assign router_link_li[0][W] = '0;
    
    assign router_link_li[nodes_p-1][E].v = core_cl_valid_lo;
    assign router_link_li[nodes_p-1][E].data = core_cl_data_lo;
    assign core_fsb_yumi_lo = core_cl_valid_lo & router_link_lo[nodes_p-1][E].ready_and_rev;
    
    assign core_fsb_valid_lo = router_link_lo[nodes_p-1][E].v;
    assign core_fsb_data_lo = router_link_lo[nodes_p-1][E].data;
    assign router_link_li[nodes_p-1][E].ready_and_rev = core_cl_ready_lo;
  end

  

endmodule
