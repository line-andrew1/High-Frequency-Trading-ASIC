// double_trouble_pcb.v
//
// simulates connectivity of the double trouble PCB
//
// this is intended as the canonical simulation file
// but currently it may only implement a subset of
// all of the wires and functionality -- please
// extend rather than cloning the file and modifying it
//

`timescale 1ps/1ps

module bsg_double_trouble_pcb
  (
   // this is the FMC connector
   inout  [33:00] LAxx_N,   inout [33:00] LAxx_P     //  e.g. LA14_N
   ,inout     CLK0_C2M_N,   inout     CLK0_C2M_P
   ,inout     CLK0_M2C_N,   inout     CLK0_M2C_P

   // SMA connectors (for simulation)
   ,input   ASIC_SMA_IN_N, input   ASIC_SMA_IN_P     // terminated on ASIC side
   ,inout  ASIC_SMA_OUT_N, inout  ASIC_SMA_OUT_P     // unterminated

   ,inout   FPGA_SMA_IN_N, inout   FPGA_SMA_IN_P     // unterminated
   ,inout  FPGA_SMA_OUT_N, inout  FPGA_SMA_OUT_P     // unterminated

   // LEDs (for simulation)
   ,output [3:0] FPGA_LED  // from GW   FPGA
   ,output [1:0] ASIC_LED  // from ASIC FPGA

   ,input  UART_RX
   ,output UART_TX

   // low-true reset signal for GW FPGA (normal driven by reset controller)
   ,input PWR_RSTN

   );

   localparam osc_time_p = 6667ps;

   // ******************************************************************
   // *
   // * GW only signals
   // *

   logic CLK_OSC_P, CLK_OSC_N;

  // on board oscillator chip

   bsg_nonsynth_clock_gen #(.cycle_time_p(osc_time_p)) cg (.o(CLK_OSC_P));
   assign CLK_OSC_N = ~CLK_OSC_P;

   // ******************************************************************
   // *
   // *  BETWEEN GW and ASIC FPGA traces (e.g. AOD00, AID00, CIC0 etc.)
   //

   // ** begin terminated on ASIC FPGA side
   wire [1:0]  AICx,  BICx,  CICx,  DICx;       // clock capable
   wire [10:0] AIDxx, BIDxx, CIDxx, DIDxx;
   wire [1:0]  AOTx,  BOTx,  COTx,  DOTx;

   wire        AIC1_X, BIC1_X, CIC1_X, DIC1_X;  // more clocks for various experiments

   wire        CLK0_P, CLK0_N;
   wire        CLK1_P, CLK1_N;
   wire        MSTR_SDO_CLK;
   wire        PLL_CLK_I;
   wire        CLK0, CLK90;

   // ** begin terminated on GW FPGA side
   wire [10:0] AODxx, BODxx, CODxx, DODxx;
   wire [1:0]  AOCx,  BOCx,  COCx,  DOCx;
   wire [1:0]  AITx,  BITx,  CITx,  DITx;

   wire        AOC1_X, BOC1_X, COC1_X, DOC1_X;  // more clocks for various experiments

   // ** begin unterminated, 3.3V
   // note in RealTrouble, these will be replaced with the "Q" pins
   // as they will be the correct voltage for the real ASIC.
   //

   wire [9:0]  XGx;

   // ******************************************************************
   // *
   // *  BEGIN GW FPGA SIMULATION
   // *
   // *
   // *
   // *  this interfaces to bsg_fpga/ip/bsg_gateway/bsg_gateway/
   // *                                                         v/bsg_gateway.v
   // *                                                         fdc/bsg_gateway_ml605.fdc
   // *  technically it would be a little more correct
   // *  to use the PIN names of the BGA rather than the trace names
   // *  of the PCB for the interface, but the pin names are not very meaningful
   // *

  bsg_gateway_socket gateway
    ( .CLK_OSC_P(CLK_OSC_P)           ,.CLK_OSC_N(CLK_OSC_N)
      ,.FPGA_LED0(FPGA_LED[0])        ,.FPGA_LED1(FPGA_LED[1])
      ,.FPGA_LED2(FPGA_LED[2])        ,.FPGA_LED3(FPGA_LED[3])
      ,.FPGA_SMA_IN_N (FPGA_SMA_IN_N) ,.FPGA_SMA_IN_P (FPGA_SMA_IN_P)
      ,.FPGA_SMA_OUT_N(FPGA_SMA_OUT_N),.FPGA_SMA_OUT_P(FPGA_SMA_OUT_P)

      // --------------------- FMC ------------------------
      ,.FCLK0_M2C_N(CLK0_M2C_N),.FCLK0_M2C_P(CLK0_M2C_P)
      ,.FCLK1_M2C_N(CLK0_C2M_N),.FCLK1_M2C_P(CLK0_C2M_P)

      // on these signals, N/P are flipped on the board hence the swap
      ,.F0_P (LAxx_N[ 0]) ,.F0_N (LAxx_P[ 0])
      ,.F1_P (LAxx_N[ 1]) ,.F1_N (LAxx_P[ 1])
      ,.F2_P (LAxx_N[ 2]) ,.F2_N (LAxx_P[ 2])
      ,.F3_P (LAxx_N[ 3]) ,.F3_N (LAxx_P[ 3])
      ,.F4_P (LAxx_N[ 4]) ,.F4_N (LAxx_P[ 4])
      ,.F5_P (LAxx_N[ 5]) ,.F5_N (LAxx_P[ 5])
      ,.F6_P (LAxx_N[ 6]) ,.F6_N (LAxx_P[ 6])
      ,.F7_P (LAxx_N[ 7]) ,.F7_N (LAxx_P[ 7])
      ,.F8_P (LAxx_N[ 8]) ,.F8_N (LAxx_P[ 8])
      ,.F9_P (LAxx_N[ 9]) ,.F9_N (LAxx_P[ 9])
      ,.F10_P(LAxx_N[10]) ,.F10_N(LAxx_P[10])
      ,.F11_P(LAxx_N[11]) ,.F11_N(LAxx_P[11])
      ,.F12_P(LAxx_N[12]) ,.F12_N(LAxx_P[12])
      ,.F13_P(LAxx_N[13]) ,.F13_N(LAxx_P[13])
      ,.F14_P(LAxx_N[14]) ,.F14_N(LAxx_P[14])
      ,.F15_P(LAxx_N[15]) ,.F15_N(LAxx_P[15])
      ,.F16_P(LAxx_N[16]) ,.F16_N(LAxx_P[16])
      ,.F17_P(LAxx_N[17]) ,.F17_N(LAxx_P[17])
      ,.F18_P(LAxx_N[18]) ,.F18_N(LAxx_P[18])
      ,.F19_P(LAxx_N[19]) ,.F19_N(LAxx_P[19])
      ,.F20_P(LAxx_N[20]) ,.F20_N(LAxx_P[20])
      ,.F21_P(LAxx_N[21]) ,.F21_N(LAxx_P[21])
      ,.F22_P(LAxx_N[22]) ,.F22_N(LAxx_P[22])
      ,.F23_P(LAxx_N[23]) ,.F23_N(LAxx_P[23])
      ,.F24_P(LAxx_N[24]) ,.F24_N(LAxx_P[24])
      ,.F25_P(LAxx_N[25]) ,.F25_N(LAxx_P[25])
      ,.F26_P(LAxx_N[26]) ,.F26_N(LAxx_P[26])
      ,.F27_P(LAxx_N[27]) ,.F27_N(LAxx_P[27])
      ,.F28_P(LAxx_N[28]) ,.F28_N(LAxx_P[28])
      ,.F29_P(LAxx_N[29]) ,.F29_N(LAxx_P[29])
      ,.F30_P(LAxx_N[30]) ,.F30_N(LAxx_P[30])
      ,.F31_P(LAxx_N[31]) ,.F31_N(LAxx_P[31])
      ,.F32_P(LAxx_N[32]) ,.F32_N(LAxx_P[32])
      ,.F33_P(LAxx_N[33]) ,.F33_N(LAxx_P[33])

      // --------------------- ASIC ------------------------
`define GW_ASIC_IO                                                                \
      ,.CLK0        (CLK0)                                                        \
      ,.CLK90       (CLK90)                                                       \
      ,.MSTR_SDO_CLK(MSTR_SDO_CLK)                                                \
      ,.PLL_CLK_I   (PLL_CLK_I)                                                   \
      ,.CLK0_N      (CLK0_N) ,.CLK0_P(CLK0_P)                                     \
      ,.CLK1_N      (CLK1_N) ,.CLK1_P(CLK1_P)                                     \
                                                                                  \
      /* ** terminated on GW FPGA side (i.e. inputs to GW FPGA) */                \
      ,.AOC0  (AOCx[0])   ,.BOC0  (BOCx[0]) ,.COC0  (COCx[0])   ,.DOC0 (DOCx[0])  \
      ,.AOC1  (AOCx[1])   ,.BOC1  (BOCx[1]) ,.COC1  (COCx[1])   ,.DOC1 (DOCx[1])  \
      ,.AOC1_X(AOC1_X)    ,.BOC1_X(BOC1_X)  ,.COC1_X(COC1_X)    ,.DOC1_X(DOC1_X)   \
                                                                                  \
      ,.AOD0 (AODxx[0])  ,.BOD0 (BODxx[0]) ,.COD0 (CODxx[0])   ,.DOD0 (DODxx[0])  \
      ,.AOD1 (AODxx[1])  ,.BOD1 (BODxx[1]) ,.COD1 (CODxx[1])   ,.DOD1 (DODxx[1])  \
      ,.AOD2 (AODxx[2])  ,.BOD2 (BODxx[2]) ,.COD2 (CODxx[2])   ,.DOD2 (DODxx[2])  \
      ,.AOD3 (AODxx[3])  ,.BOD3 (BODxx[3]) ,.COD3 (CODxx[3])   ,.DOD3 (DODxx[3])  \
      ,.AOD4 (AODxx[4])  ,.BOD4 (BODxx[4]) ,.COD4 (CODxx[4])   ,.DOD4 (DODxx[4])  \
      ,.AOD5 (AODxx[5])  ,.BOD5 (BODxx[5]) ,.COD5 (CODxx[5])   ,.DOD5 (DODxx[5])  \
      ,.AOD6 (AODxx[6])  ,.BOD6 (BODxx[6]) ,.COD6 (CODxx[6])   ,.DOD6 (DODxx[6])  \
      ,.AOD7 (AODxx[7])  ,.BOD7 (BODxx[7]) ,.COD7 (CODxx[7])   ,.DOD7 (DODxx[7])  \
      ,.AOD8 (AODxx[8])  ,.BOD8 (BODxx[8]) ,.COD8 (CODxx[8])   ,.DOD8 (DODxx[8])  \
      ,.AOD9 (AODxx[9])  ,.BOD9 (BODxx[9]) ,.COD9 (CODxx[9])   ,.DOD9 (DODxx[9])  \
      ,.AOD10(AODxx[10]) ,.BOD10(BODxx[10]),.COD10(CODxx[10])  ,.DOD10(DODxx[10]) \
                                                                                  \
      ,.AIT0(AITx[0]) ,.BIT0(BITx[0]) ,.CIT0(CITx[0]) ,.DIT0(DITx[0])             \
      ,.AIT1(AITx[1]) ,.BIT1(BITx[1]) ,.CIT1(CITx[1]) ,.DIT1(DITx[1])             \
                                                                                  \
      /* ** terminated on ASIC FPGA side (i.e. inputs to ASIC FPGA)        */     \
      ,.AIC0  (AICx [0]) ,.BIC0  (BICx[0])   ,.CIC0(CICx[0])    ,.DIC0  (DICx[0] ) \
      ,.AIC1  (AICx [1]) ,.BIC1  (BICx[1])   ,.CIC1(CICx[1])    ,.DIC1  (DICx[1] ) \
      ,.AIC1_X(AIC1_X  ) ,.BIC1_X(BIC1_X )   ,.CIC1_X(CIC1_X )  ,.DIC1_X(DIC1_X  ) \
                                                                                  \
      ,.AID0 (AIDxx[0])  ,.BID0 (BIDxx[0])  ,.CID0 (CIDxx[0])   ,.DID0 (DIDxx[0]) \
      ,.AID1 (AIDxx[1])  ,.BID1 (BIDxx[1])  ,.CID1 (CIDxx[1])   ,.DID1 (DIDxx[1]) \
      ,.AID2 (AIDxx[2])  ,.BID2 (BIDxx[2])  ,.CID2 (CIDxx[2])   ,.DID2 (DIDxx[2]) \
      ,.AID3 (AIDxx[3])  ,.BID3 (BIDxx[3])  ,.CID3 (CIDxx[3])   ,.DID3 (DIDxx[3]) \
      ,.AID4 (AIDxx[4])  ,.BID4 (BIDxx[4])  ,.CID4 (CIDxx[4])   ,.DID4 (DIDxx[4]) \
      ,.AID5 (AIDxx[5])  ,.BID5 (BIDxx[5])  ,.CID5 (CIDxx[5])   ,.DID5 (DIDxx[5]) \
      ,.AID6 (AIDxx[6])  ,.BID6 (BIDxx[6])  ,.CID6 (CIDxx[6])   ,.DID6 (DIDxx[6]) \
      ,.AID7 (AIDxx[7])  ,.BID7 (BIDxx[7])  ,.CID7 (CIDxx[7])   ,.DID7 (DIDxx[7]) \
      ,.AID8 (AIDxx[8])  ,.BID8 (BIDxx[8])  ,.CID8 (CIDxx[8])   ,.DID8 (DIDxx[8]) \
      ,.AID9 (AIDxx[9])  ,.BID9 (BIDxx[9])  ,.CID9 (CIDxx[9])   ,.DID9 (DIDxx[9]) \
      ,.AID10(AIDxx[10]) ,.BID10(BIDxx[10]) ,.CID10(CIDxx[10])  ,.DID10(DIDxx[10])\
                                                                                  \
      ,.AOT0(AOTx[0]) ,.BOT0(BOTx[0]) ,.COT0(COTx[0]) ,.DOT0(DOTx[0])             \
      ,.AOT1(AOTx[1]) ,.BOT1(BOTx[1]) ,.COT1(COTx[1]) ,.DOT1(DOTx[1])             \
                                                                                  \
      ,.XG0(XGx[0]) ,.XG1(XGx[1]), .XG2(XGx[2]), .XG3(XGx[3]), .XG4(XGx[4])       \
      ,.XG5(XGx[5]) ,.XG6(XGx[6]), .XG7(XGx[7]), .XG8(XGx[8]), .XG9(XGx[9])

     `GW_ASIC_IO

      ,.PWR_RSTN(PWR_RSTN) // input reset; normally comes from on-board chip

      // board-level lifesupport; unused for digital simulation
      ,.ASIC_CORE_EN () // output
      ,.ASIC_IO_EN   () // output
      ,.CUR_MON_ADDR0() // output
      ,.CUR_MON_ADDR1() // output
      ,.CUR_MON_SCL  () // inout
      ,.CUR_MON_SDA  () // inout
      ,.DIG_POT_ADDR0() // output
      ,.DIG_POT_ADDR1() // output
      ,.DIG_POT_INDEP()
      ,.DIG_POT_NRST ()
      ,.DIG_POT_SCL  () // inout
      ,.DIG_POT_SDA  () // inout
      ,.UART_RX(UART_RX)// input
      ,.UART_TX(UART_TX)// output

    // --------------------- MISC BOARD WIRES ------------------------

     // TODO: add remaining misc signals here (FG_SWITCH etc)
    );

   // ******************************************************************
   // *
   // *  BEGIN ASIC FPGA SIMULATION
   // *
   // *  this interfaces to bsg_fpga/ip/bsg_asic/common/
   // *                                                 v/bsg_asic.v
   // *                                                 fdc/bas_asic.fdc

  bsg_asic_socket asic
    (
      .ASIC_LED0     (ASIC_LED[0])
     ,.ASIC_LED1     (ASIC_LED[1])
     ,.ASIC_SMA_IN_N (ASIC_SMA_IN_N) ,.ASIC_SMA_IN_P (ASIC_SMA_IN_P)
     ,.ASIC_SMA_OUT_N(ASIC_SMA_OUT_N),.ASIC_SMA_OUT_P(ASIC_SMA_OUT_P)

     `GW_ASIC_IO

     );

endmodule
