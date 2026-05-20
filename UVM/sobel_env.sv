`ifndef SOBEL_ENV_SV
`define SOBEL_ENV_SV

class sobel_env extends uvm_env;

	`uvm_component_utils (sobel_env)

	axi_lite_agent lite_slave_agent;
	//axi_full_agent full_master_agent;

	virtual axi_lite_if lite_vif;
	virtual axi_full_if full_vif;

	function new(string name = "sobel_env", uvm_component parent = null);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("SOBEL_ENV", "build_phase running", UVM_LOW)

		/************Geting from configuration database*******************/
		if(!uvm_config_db#(virtual axi_lite_if)::get(this, "", "axi_lite_vif", lite_vif))
			`uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".lite_vif"});
		if(!uvm_config_db#(virtual axi_full_if)::get(this, "", "axi_full_vif", full_vif))	
			`uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".full_vif"});
		/*****************************************************************/
		
		/************Setting to configuration database********************/
		uvm_config_db#(virtual axi_lite_if)::set(this, "lite_slave_agent", "axi_lite_vif", lite_vif);
		//uvm_config_db#(virtual axi_full_if)::set(this, "full_master_agent", "axi_full_vif", full_vif);
		/*****************************************************************/
		
		lite_slave_agent = axi_lite_agent::type_id::create("lite_slave_agent", this);
		//full_master_agent = axi_full_agent::type_id::create("full_master_agent", this);
			
	endfunction : build_phase
   
endclass : sobel_env

`endif