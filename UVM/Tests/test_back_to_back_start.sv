`ifndef TEST_BACK_TO_BACK_START_SV
`define TEST_BACK_TO_BACK_START_SV 

// Inside Vivado: settings -> simmulation -> simulation add:
// -testplusarg UVM_TESTNAME=test_back_to_back_start -testplusarg UVM_VERBOSITY=UVM_LOW -sv_seed 2013

class test_back_to_back_start extends uvm_test;

    `uvm_component_utils(test_back_to_back_start)
	
	sobel_env env;
	memory_model shared_mem;
	axi_full_config axi_cfg;
	
	function new(string name = "test_back_to_back_start", uvm_component parent = null);
		super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("TEST_BACK_TO_BACK_START", "build_phase running", UVM_LOW)
		
		// ------ Create AXI-Full config in latency stress mode ------
        axi_cfg = axi_full_config::type_id::create("axi_cfg");
        //axi_cfg.set_mode(AXI_FULL_MODE_LATENCY);
        axi_cfg.set_mode(AXI_FULL_MODE_FAST);
        //axi_cfg.set_mode(AXI_FULL_MODE_BACKPRESSURE);
        //axi_cfg.set_mode(AXI_FULL_MODE_COMBINED);
		uvm_config_db#(axi_full_config)::set(this, "env.full_master_agent", "axi_cfg", axi_cfg);
		
		shared_mem = memory_model::type_id::create("shared_mem");
        uvm_config_db#(memory_model)::set(this, "env.*", "shared_mem", shared_mem);
		env = sobel_env::type_id::create("env", this);  
    endfunction
    
    task run_phase(uvm_phase phase);
		program_base_addr_seq pba_seq;
        start_pulse_seq    start_seq;
        wait_for_ready_seq wait_seq;
        longint unsigned   base_addr;
        longint unsigned   offset;
    
        phase.raise_objection(this);
        `uvm_info("TEST_BACK_TO_BACK_START", "run_phase running", UVM_LOW)
        `uvm_info("TEST_BACK_TO_BACK_START", $sformatf("%s", axi_cfg.print_mode()), UVM_LOW)
    
        base_addr = 32'h1000_0000;
        // Memory needed for the input image + 2 output images + 2 zero zones = 270000 + 2*540000 + 2*544 = 1351088
		offset = 32'h0014_9DB0;
        
        // ------ Preload input images from file ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Loading input images", UVM_LOW)
        // Put the golden file inside the root of Vivado generated project file 
        shared_mem.load_file(base_addr, "../../../../golden/IMG-01/input.txt");
		shared_mem.load_file(base_addr + offset, "../../../../golden/IMG-02/input.txt");
		shared_mem.load_file(base_addr + 2*offset, "../../../../golden/IMG-05/input.txt");
		
		// IMG-01 processing
		// ------ Program the base_address register ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Programming base_address register", UVM_LOW)
        pba_seq = program_base_addr_seq::type_id::create("pba_seq");
        pba_seq.base_address_value = base_addr[31:0];
        pba_seq.start(env.lite_slave_agent.seqr);
    
        // ------ Start pulse ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Issuing start pulse", UVM_LOW)
        start_seq = start_pulse_seq::type_id::create("start_seq");
        start_seq.start(env.lite_slave_agent.seqr);
    
        // ------ Wait for ready ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Waiting for DUT ready (timeout: 200 ms)", UVM_LOW)
        wait_seq = wait_for_ready_seq::type_id::create("wait_seq");
    
        fork
            begin
                wait_seq.start(env.lite_slave_agent.seqr);
            end
            begin
                #200ms;
                `uvm_warning("TEST_BACK_TO_BACK_START", "Timeout expired waiting for ready")
            end
        join_any
        disable fork;
    
        if (wait_seq.ready_observed) begin
            `uvm_info("TEST_BACK_TO_BACK_START", $sformatf("DUT ready after %0d polls.",
                      wait_seq.reads_done), UVM_LOW)
        end else begin
            `uvm_error("TEST_BACK_TO_BACK_START", "DUT did not assert ready within timeout")
        end
		
		// IMG-02 processsing
		// ------ Program the base_address register ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Programming base_address register", UVM_LOW)
        pba_seq = program_base_addr_seq::type_id::create("pba_seq");
        pba_seq.base_address_value = base_addr + offset;
        pba_seq.start(env.lite_slave_agent.seqr);
    
        // ------ Start pulse ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Issuing start pulse", UVM_LOW)
        start_seq = start_pulse_seq::type_id::create("start_seq");
        start_seq.start(env.lite_slave_agent.seqr);
    
        // ------ Wait for ready ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Waiting for DUT ready (timeout: 200 ms)", UVM_LOW)
        wait_seq = wait_for_ready_seq::type_id::create("wait_seq");
    
        fork
            begin
                wait_seq.start(env.lite_slave_agent.seqr);
            end
            begin
                #200ms;
                `uvm_warning("TEST_BACK_TO_BACK_START", "Timeout expired waiting for ready")
            end
        join_any
        disable fork;
    
        if (wait_seq.ready_observed) begin
            `uvm_info("TEST_BACK_TO_BACK_START", $sformatf("DUT ready after %0d polls.",
                      wait_seq.reads_done), UVM_LOW)
        end else begin
            `uvm_error("TEST_BACK_TO_BACK_START", "DUT did not assert ready within timeout")
        end
		
		// IMG-05 processsing
		// ------ Program the base_address register ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Programming base_address register", UVM_LOW)
        pba_seq = program_base_addr_seq::type_id::create("pba_seq");
        pba_seq.base_address_value = base_addr + 2*offset;
        pba_seq.start(env.lite_slave_agent.seqr);
    
        // ------ Start pulse ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Issuing start pulse", UVM_LOW)
        start_seq = start_pulse_seq::type_id::create("start_seq");
        start_seq.start(env.lite_slave_agent.seqr);
    
        // ------ Wait for ready ------
        `uvm_info("TEST_BACK_TO_BACK_START", "Waiting for DUT ready (timeout: 200 ms)", UVM_LOW)
        wait_seq = wait_for_ready_seq::type_id::create("wait_seq");
    
        fork
            begin
                wait_seq.start(env.lite_slave_agent.seqr);
            end
            begin
                #200ms;
                `uvm_warning("TEST_BACK_TO_BACK_START", "Timeout expired waiting for ready")
            end
        join_any
        disable fork;
    
        if (wait_seq.ready_observed) begin
            `uvm_info("TEST_BACK_TO_BACK_START", $sformatf("DUT ready after %0d polls.",
                      wait_seq.reads_done), UVM_LOW)
        end else begin
            `uvm_error("TEST_BACK_TO_BACK_START", "DUT did not assert ready within timeout")
        end		
		
		
		// Running scoreboard 3 times
		
		// ------ Tell scoreboard what to expect ------
        env.scoreboard.base_address   = base_addr;
        // Put the golden file inside the root of Vivado generated project file
        env.scoreboard.golden_gx_path = "../../../../golden/IMG-01/output_1.txt";
        env.scoreboard.golden_gy_path = "../../../../golden/IMG-01/output_2.txt";
		env.scoreboard.check_mem();
		
		// ------ Tell scoreboard what to expect ------
        env.scoreboard.base_address   = base_addr + offset;
        // Put the golden file inside the root of Vivado generated project file
        env.scoreboard.golden_gx_path = "../../../../golden/IMG-02/output_1.txt";
        env.scoreboard.golden_gy_path = "../../../../golden/IMG-02/output_2.txt";
		env.scoreboard.check_mem();		
		
		// ------ Tell scoreboard what to expect ------
        env.scoreboard.base_address   = base_addr + 2*offset;
        // Put the golden file inside the root of Vivado generated project file
        env.scoreboard.golden_gx_path = "../../../../golden/IMG-05/output_1.txt";
        env.scoreboard.golden_gy_path = "../../../../golden/IMG-05/output_2.txt";
		env.scoreboard.check_mem();
		
    
        // Check that input pixels from input.txt and output pixels from DUT are inside the shared_mem
        `uvm_info("MEM",$sformatf("Memory usage at the end of the test: %d bytes.", shared_mem.size()),UVM_LOW)
        #100ns;
        phase.drop_objection(this);
    endtask
    
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
    
endclass
  
`endif