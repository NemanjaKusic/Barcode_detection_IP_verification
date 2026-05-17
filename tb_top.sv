`ifndef TB_TOP_SV
`define TB_TOP_SV

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import test_pkg::*;

module tb_top;

	logic aclk;
	logic aresetn;

	// Clock 10ns
	initial begin
		aclk = 0;
		forever #5 aclk = ~aclk;
	end

	// Reset: 0 in first 100ns
	initial begin
		aresetn = 0;
		#100 aresetn = 1;
	end

	// Instantiate the two interfaces
	axi_lite_if  s_axi_lite (.aclk(aclk), .aresetn(aresetn));
	axi_full_if  m_axi_full (.aclk(aclk), .aresetn(aresetn));

	// Internal signals between the two IPs (start / base_address / ready)
	logic        start_s;
	logic [31:0] base_addr_s;
	logic        ready_s;


	// DUT — AXI4_Lite_slave_cntrl instance
	AXI4_lite_slave_cntrl lite_inst (
		.start_axi_o         (start_s),
		.base_address_axi_o  (base_addr_s),
		.ready_axi_i         (ready_s),

		.S_AXI_ACLK          (aclk),
		.S_AXI_ARESETN       (aresetn),
		.S_AXI_AWADDR        (s_axi_lite.awaddr),
		.S_AXI_AWPROT        (s_axi_lite.awprot),
		.S_AXI_AWVALID       (s_axi_lite.awvalid),
		.S_AXI_AWREADY       (s_axi_lite.awready),
		.S_AXI_WDATA         (s_axi_lite.wdata),
		.S_AXI_WSTRB         (s_axi_lite.wstrb),
		.S_AXI_WVALID        (s_axi_lite.wvalid),
		.S_AXI_WREADY        (s_axi_lite.wready),
		.S_AXI_BRESP         (s_axi_lite.bresp),
		.S_AXI_BVALID        (s_axi_lite.bvalid),
		.S_AXI_BREADY        (s_axi_lite.bready),
		.S_AXI_ARADDR        (s_axi_lite.araddr),
		.S_AXI_ARPROT        (s_axi_lite.arprot),
		.S_AXI_ARVALID       (s_axi_lite.arvalid),
		.S_AXI_ARREADY       (s_axi_lite.arready),
		.S_AXI_RDATA         (s_axi_lite.rdata),
		.S_AXI_RRESP         (s_axi_lite.rresp),
		.S_AXI_RVALID        (s_axi_lite.rvalid),
		.S_AXI_RREADY        (s_axi_lite.rready)
	);

	// DUT — AXI4_full_top (sobel_fn + BRAMs + controllers)
	AXI4_full_top full_inst (
		.start         (start_s),
		.ready         (ready_s),
		.base_address  (base_addr_s),

		.M_AXI_ACLK    (aclk),
		.M_AXI_ARESETN (aresetn),
		.M_AXI_AWID    (m_axi_full.awid),
		.M_AXI_AWADDR  (m_axi_full.awaddr),
		.M_AXI_AWLEN   (m_axi_full.awlen),
		.M_AXI_AWSIZE  (m_axi_full.awsize),
		.M_AXI_AWBURST (m_axi_full.awburst),
		.M_AXI_AWLOCK  (m_axi_full.awlock),
		.M_AXI_AWCACHE (m_axi_full.awcache),
		.M_AXI_AWPROT  (m_axi_full.awprot),
		.M_AXI_AWQOS   (m_axi_full.awqos),
		.M_AXI_AWUSER  (),                    // in entity port list: (-1 downto 0) = null
		.M_AXI_AWVALID (m_axi_full.awvalid),
		.M_AXI_AWREADY (m_axi_full.awready),
		.M_AXI_WDATA   (m_axi_full.wdata),
		.M_AXI_WSTRB   (m_axi_full.wstrb),
		.M_AXI_WLAST   (m_axi_full.wlast),
		.M_AXI_WUSER   (),                    // same
		.M_AXI_WVALID  (m_axi_full.wvalid),
		.M_AXI_WREADY  (m_axi_full.wready),
		.M_AXI_BID     (m_axi_full.bid),
		.M_AXI_BRESP   (m_axi_full.bresp),
		.M_AXI_BUSER   (),                    // same
		.M_AXI_BVALID  (m_axi_full.bvalid),
		.M_AXI_BREADY  (m_axi_full.bready),
		.M_AXI_ARID    (m_axi_full.arid),
		.M_AXI_ARADDR  (m_axi_full.araddr),
		.M_AXI_ARLEN   (m_axi_full.arlen),
		.M_AXI_ARSIZE  (m_axi_full.arsize),
		.M_AXI_ARBURST (m_axi_full.arburst),
		.M_AXI_ARLOCK  (m_axi_full.arlock),
		.M_AXI_ARCACHE (m_axi_full.arcache),
		.M_AXI_ARPROT  (m_axi_full.arprot),
		.M_AXI_ARQOS   (m_axi_full.arqos),
		.M_AXI_ARUSER  (),                    // same
		.M_AXI_ARVALID (m_axi_full.arvalid),
		.M_AXI_ARREADY (m_axi_full.arready),
		.M_AXI_RID     (m_axi_full.rid),
		.M_AXI_RDATA   (m_axi_full.rdata),
		.M_AXI_RRESP   (m_axi_full.rresp),
		.M_AXI_RLAST   (m_axi_full.rlast),
		.M_AXI_RUSER   (),                    // same
		.M_AXI_RVALID  (m_axi_full.rvalid),
		.M_AXI_RREADY  (m_axi_full.rready)
	);

	// For now all singlas that teh 2 drivers should drive to 0
	initial begin
		s_axi_lite.awvalid = 0;
		s_axi_lite.wvalid  = 0;
		s_axi_lite.bready  = 0;
		s_axi_lite.arvalid = 0;
		s_axi_lite.rready  = 0;
		s_axi_lite.awprot  = 0;
		s_axi_lite.arprot  = 0;
		s_axi_lite.awaddr  = 0;
		s_axi_lite.araddr  = 0;
		s_axi_lite.wdata   = 0;
		s_axi_lite.wstrb   = 0;

		m_axi_full.awready = 0;
		m_axi_full.wready  = 0;
		m_axi_full.bvalid  = 0;
		m_axi_full.bid     = 0;
		m_axi_full.bresp   = 0;
		m_axi_full.arready = 0;
		m_axi_full.rvalid  = 0;
		m_axi_full.rid     = 0;
		m_axi_full.rdata   = 0;
		m_axi_full.rresp   = 0;
		m_axi_full.rlast   = 0;
	end

	// sent the interfaces to components via config_db
	initial begin
		uvm_config_db#(virtual axi_lite_if)::set(null, "*", "axi_lite_vif", s_axi_lite);
		uvm_config_db#(virtual axi_full_if)::set(null, "*", "axi_full_vif", m_axi_full);
	end

	// Run test
	initial begin
		$display("[%0t] tb_top: starting", $time);
		run_test();
	end

endmodule

`endif