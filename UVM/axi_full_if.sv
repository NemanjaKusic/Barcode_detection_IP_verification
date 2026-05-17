`ifndef AXI_FULL_IF_SV
`define AXI_FULL_IF_SV

interface axi_full_if (input logic aclk, input logic aresetn);

	parameter int ID_WIDTH    = 1;
	parameter int ADDR_WIDTH  = 32;
	parameter int DATA_WIDTH  = 32;
	parameter int STRB_WIDTH  = DATA_WIDTH/8;
	parameter int LEN_WIDTH   = 8;
	parameter int SIZE_WIDTH  = 3;
	parameter int BURST_WIDTH = 2;
	parameter int RESP_WIDTH  = 2;
	parameter int CACHE_WIDTH = 4;
	parameter int PROT_WIDTH  = 3;
	parameter int QOS_WIDTH   = 4;

	// Write address channel
	logic [ID_WIDTH-1:0]    awid;
	logic [ADDR_WIDTH-1:0]  awaddr;
	logic [LEN_WIDTH-1:0]   awlen;
	logic [SIZE_WIDTH-1:0]  awsize;
	logic [BURST_WIDTH-1:0] awburst;
	logic                   awlock;
	logic [CACHE_WIDTH-1:0] awcache;
	logic [PROT_WIDTH-1:0]  awprot;
	logic [QOS_WIDTH-1:0]   awqos;
	logic                   awvalid;
	logic                   awready;

	// Write data channel
	logic [DATA_WIDTH-1:0]  wdata;
	logic [STRB_WIDTH-1:0]  wstrb;
	logic                   wlast;
	logic                   wvalid;
	logic                   wready;

	// Write response channel
	logic [ID_WIDTH-1:0]    bid;
	logic [RESP_WIDTH-1:0]  bresp;
	logic                   bvalid;
	logic                   bready;

	// Read address channel
	logic [ID_WIDTH-1:0]    arid;
	logic [ADDR_WIDTH-1:0]  araddr;
	logic [LEN_WIDTH-1:0]   arlen;
	logic [SIZE_WIDTH-1:0]  arsize;
	logic [BURST_WIDTH-1:0] arburst;
	logic                   arlock;
	logic [CACHE_WIDTH-1:0] arcache;
	logic [PROT_WIDTH-1:0]  arprot;
	logic [QOS_WIDTH-1:0]   arqos;
	logic                   arvalid;
	logic                   arready;

	// Read data channel
	logic [ID_WIDTH-1:0]    rid;
	logic [DATA_WIDTH-1:0]  rdata;
	logic [RESP_WIDTH-1:0]  rresp;
	logic                   rlast;
	logic                   rvalid;
	logic                   rready;

	//clocking block - used for:
	//when driving - simulator drives signals 1ns after the clock signal rising edge
	//when sampling - simulator samples signals a step before the clock signal rising edge
	clocking cb @(posedge aclk);
		default input #1step output #1ns;
		inout awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awvalid, awready;
		inout wdata, wstrb, wlast, wvalid, wready;
		inout bid, bresp, bvalid, bready;
		inout arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arvalid, arready;
		inout rid, rdata, rresp, rlast, rvalid, rready;
	endclocking

endinterface

`endif