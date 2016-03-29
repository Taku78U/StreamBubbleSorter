`default_nettype none
module StreamBubbleSorter #(parameter STAGES = `ELEMS_PER_UNIT-1)
                           (input  wire              CLK,
                            input  wire              RST,
                            input  wire [`SORTW-1:0] DIN_T,
                            input  wire              ENQ_T,
                            output wire [`DRAMW-1:0] DOUT,
                            output wire              dvalid);

  // Define Flag Wires
  wire [STAGES:0] enq0, enq1, enq_s, emp0, emp1, full0, full1, deq0, deq1;
  wire [STAGES-1:0] full_t;
  wire [`SORTW-1:0] din0_s [0:STAGES];
  wire [`SORTW-1:0] din1_s [0:STAGES];
  wire [`SORTW-1:0] dot [0:STAGES];
  wire [1:0] cnt0 [0:STAGES];
  wire [1:0] cnt1 [0:STAGES];
  
  // Define Flag Regs
  reg [STAGES:0] icnt;
  assign enq_s[0] = ENQ_T;
  assign dot[0]   = DIN_T;

  reg icnt_fin;
  always @(posedge CLK) icnt_fin <= (RST) ? 0 : (enq_s[STAGES]) ? icnt_fin + 1 : icnt_fin;

  assign enq0[STAGES] = !icnt_fin & enq_s[STAGES];
  assign enq1[STAGES] =  icnt_fin & enq_s[STAGES];

  genvar i;
  generate
    for (i=0;i<=STAGES;i=i+1) begin : ICNTS
      MREG im0(CLK, RST, enq0[i], deq0[i], dot[i], din0_s[i], emp0[i], full0[i]);
      MREG im1(CLK, RST, enq1[i], deq1[i], dot[i], din1_s[i], emp1[i], full1[i]);
      if(i<STAGES) assign enq0[i] = enq_s[i] & (deq0[i] | !deq1[i] &  emp0[i]); 
      if(i<STAGES) assign enq1[i] = enq_s[i] & (deq1[i] | !deq0[i] & !emp0[i]);
    end
  endgenerate

  genvar j;
  generate
    for (j=0;j<STAGES;j=j+1) begin : SCELLAlts
      SCELL_Alter #(`ELEMS_PER_UNIT) s(!emp0[j], !emp1[j], CLK, RST, deq0[j], deq1[j], din0_s[j], din1_s[j], full_t[j], dot[j+1], enq_s[j+1]);
      assign full_t[j] = 0;
    end
  endgenerate

  // Input data
  assign deq0[STAGES] = !emp0[STAGES] && !emp1[STAGES];
  assign deq1[STAGES] = deq0[STAGES];

  assign DOUT = {din1_s[STAGES], din0_s[STAGES]};
  assign dvalid = deq1[STAGES] && deq0[STAGES];

endmodule
`default_nettype wire
