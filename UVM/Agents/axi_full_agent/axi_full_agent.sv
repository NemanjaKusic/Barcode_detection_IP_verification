`ifndef AXI_FULL_AGENT_SV
`define AXI_FULL_AGENT_SV


class axi_full_agent extends uvm_agent;

	`uvm_component_utils (axi_full_agent)
	
	// components
	axi_full_driver drv;
	axi_full_sequencer seqr;
	axi_full_monitor mon;
	axi_full_config cfg;

	virtual axi_full_if full_vif;
	
	function new(string name = "axi_full_agent", uvm_component parent = null);
        super.new(name,parent);
    endfunction
   
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AXI_FULL_AGENT", "build_phase running", UVM_LOW)
	   
        /************Geting from configuration database*******************/
        if (!uvm_config_db#(virtual axi_full_if)::get(this, "", "axi_full_vif", full_vif))
			`uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".full_vif"})
			
		/************Setting to configuration database********************/
		uvm_config_db#(virtual axi_full_if)::set(this, "*", "axi_full_vif", full_vif);
		/*****************************************************************/
		
		// ------ Get config from test (if test didn't set one, create a default) ------
        if (!uvm_config_db#(axi_full_config)::get(this, "", "axi_cfg", cfg)) begin
            `uvm_info("AXI_FULL_AGENT", "No config provided, using default (fast mode)", UVM_LOW)
            cfg = axi_full_config::type_id::create("axi_cfg");
        end
        // Pass config down to the driver
        uvm_config_db#(axi_full_config)::set(this, "drv", "axi_cfg", cfg);
			
		mon = axi_full_monitor::type_id::create("mon", this);	
	    drv = axi_full_driver::type_id::create("drv", this);
		seqr = axi_full_sequencer::type_id::create("seqr", this);
		
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		// No driver-sequencer connection for the AXI-Full agent
		// Driver does not pull sequence items from the sequencer. It pulls data from the memory model
		
		//drv.seq_item_port.connect(seqr.seq_item_export);    // uncommented - would be error because driver is not parametrized with (same) seq item
		
	endfunction : connect_phase		

endclass : axi_full_agent

`endif