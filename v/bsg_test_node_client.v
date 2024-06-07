/**
 * BSG Test Node Client
 */
module  bsg_test_node_client #(parameter ring_width_p="inv"
                              ,parameter master_p="inv"
                              ,parameter master_id_p="inv"
                              ,parameter client_id_p="inv")
  (input  clk_i
  ,input  reset_i
  ,input  en_i

  ,input                     v_i
  ,input  [ring_width_p-1:0] data_i
  ,output                    ready_o
  
  ,output                    v_o
  ,output [ring_width_p-1:0] data_o
  ,input                     yumi_i
  );


  logic [74:0] data_lo, data_li;

  assign data_li = data_i[74:0];
  assign data_o  = { 4'(client_id_p), data_lo };

  logic [224:0] data_sipo_o;
  logic yumi_sipo_i, v_node_o, ready_node_o, v_sipo_o;
  assign yumi_sipo_i = ready_node_o & v_sipo_o;

  logic [177:0] data_node_o;
  logic ready_piso_o, yumi_node_i;
  assign yumi_node_i = ready_piso_o & v_node_o;
  
  /** INSTANTIATE NODE 0 **/
  if ( client_id_p == 0 ) begin
    bsg_serial_in_parallel_out_full #(
      .width_p(75),
      .els_p(3)
    ) serial_parallel (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .v_i(v_i),
      .ready_o(ready_o),
      .data_i(data_li),
      .data_o(data_sipo_o),
      .v_o(v_sipo_o),
      .yumi_i(yumi_sipo_i)
    );

    trade_decision node (
    .message_i(data_sipo_o[177:0]),
    .average_i(64'b10011100010000),
    .clk_i(clk_i), 
    .reset_i(reset_i), 
    .v_i(v_sipo_o), 
    .yumi_i(yumi_node_i),
    .ready_o(ready_node_o), 
    .v_o(v_node_o),
    .trade_o(data_node_o)
    );

    bsg_parallel_in_serial_out #(
      .width_p(75),
      .els_p(3)
    ) parallel_serial (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .valid_i(v_node_o),
      .data_i({47'b0, data_node_o}),
      .ready_and_o(ready_piso_o),
      .valid_o(v_o),
      .data_o(data_lo),
      .yumi_i(yumi_i)
    );
  end

endmodule

