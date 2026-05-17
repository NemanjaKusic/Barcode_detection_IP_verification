`ifndef AXI_LITE_IF_SV
`define AXI_LITE_IF_SV

interface axi_lite_if (input logic aclk, input logic aresetn);

	parameter int ADDR_WIDTH = 4;
	parameter int DATA_WIDTH = 32;
	parameter int STRB_WIDTH = DATA_WIDTH/8;

	// Write address channel
	logic [ADDR_WIDTH-1:0] awaddr;
	logic [2:0]            awprot;
	logic                  awvalid;
	logic                  awready;

	// Write data channel
	logic [DATA_WIDTH-1:0] wdata;
	logic [STRB_WIDTH-1:0] wstrb;
	logic                  wvalid;
	logic                  wready;

	// Write response channel
	logic [1:0]            bresp;
	logic                  bvalid;
	logic                  bready;

	// Read address channel
	logic [ADDR_WIDTH-1:0] araddr;
	logic [2:0]            arprot;
	logic                  arvalid;
	logic                  arready;

	// Read data channel
	logic [DATA_WIDTH-1:0] rdata;
	logic [1:0]            rresp;
	logic                  rvalid;
	logic                  rready;

	//clocking block - used for:
	//when driving - simulator drives signals 1ns after the clock signal rising edge
	//when sampling - simulator samples signals a step before the clock signal rising edge
	clocking cb @(posedge aclk);
		default input #1step output #1ns;
		inout awaddr, awprot, awvalid, awready;
		inout wdata, wstrb, wvalid, wready;
		inout bresp, bvalid, bready;
		inout araddr, arprot, arvalid, arready;
		inout rdata, rresp, rvalid, rready;
	endclocking

endinterface

`endif