`ifndef AXI_LITE_AGENT_SV
`define AXI_LITE_AGENT_SV


class axi_lite_agent extends uvm_agent;

	`uvm_component_utils (axi_lite_agent)
	
	// components
	axi_lite_driver drv;
	axi_lite_sequencer seqr;
	axi_lite_monitor mon;

	virtual axi_lite_if lite_vif;
	
	function new(string name = "axi_lite_agent", uvm_component parent = null);
        super.new(name,parent);
    endfunction
   
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AXI_LITE_AGENT", "build_phase running", UVM_LOW)
	   
        /************Geting from configuration database*******************/
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "axi_lite_vif", lite_vif))
			`uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".lite_vif"})
			
		/************Setting to configuration database********************/
		uvm_config_db#(virtual axi_lite_if)::set(this, "*", "axi_lite_vif", lite_vif);
		/*****************************************************************/
			
		mon = axi_lite_monitor::type_id::create("mon", this);	
	    drv = axi_lite_driver::type_id::create("drv", this);
		seqr = axi_lite_sequencer::type_id::create("seqr", this);
		
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		drv.seq_item_port.connect(seqr.seq_item_export);
		
	endfunction : connect_phase		

endclass : axi_lite_agent

`endif