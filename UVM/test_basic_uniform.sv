`ifndef TEST_BASIC_UNIFORM_SV
`define TEST_BASIC_UNIFORM_SV 

// Inside Vivado: settings -> simmulation -> simulation add:
// -testplusarg UVM_TESTNAME=test_basic_uniform -testplusarg UVM_VERBOSITY=UVM_LOW -sv_seed 2013

class test_basic_uniform extends uvm_test;

    `uvm_component_utils(test_basic_uniform)
	
	sobel_env env;
	memory_model shared_mem;
	
	function new(string name = "test_basic_uniform", uvm_component parent = null);
		super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("TEST_BASIC_UNIFORM", "build_phase running", UVM_LOW)
		
		shared_mem = memory_model::type_id::create("shared_mem");
        uvm_config_db#(memory_model)::set(this, "env.*", "shared_mem", shared_mem);
		env = sobel_env::type_id::create("env", this);  
    endfunction
    
    task run_phase(uvm_phase phase);
        start_pulse_seq    start_seq;
        wait_for_ready_seq wait_seq;
        longint unsigned   base_addr;
    
        phase.raise_objection(this);
        `uvm_info("TEST_BASIC_UNIFORM", "run_phase running", UVM_LOW)
    
        base_addr = 32'h0000_0000;
        
        // ------ Preload input image from file ------
        `uvm_info("TEST_BASIC_UNIFORM", "Loading input image from file", UVM_LOW)
        // Put the golden file inside the root of Vivado generated project file 
        shared_mem.load_file(base_addr, "../../../../golden/IMG-02/input.txt");
    
        // ------ Tell scoreboard what to expect ------
        env.scoreboard.base_address   = base_addr;
        // Put the golden file inside the root of Vivado generated project file
        env.scoreboard.golden_gx_path = "../../../../golden/IMG-02/output_1.txt";
        env.scoreboard.golden_gy_path = "../../../../golden/IMG-02/output_2.txt";
    
        // ------ Start pulse ------
        `uvm_info("TEST_BASIC_UNIFORM", "Issuing start pulse", UVM_LOW)
        start_seq = start_pulse_seq::type_id::create("start_seq");
        start_seq.start(env.lite_slave_agent.seqr);
    
        // ------ Wait for ready ------
        `uvm_info("TEST_BASIC_UNIFORM", "Waiting for DUT ready (timeout: 200 ms)", UVM_LOW)
        wait_seq = wait_for_ready_seq::type_id::create("wait_seq");
    
        fork
            begin
                wait_seq.start(env.lite_slave_agent.seqr);
            end
            begin
                #200ms;
                `uvm_warning("TEST_BASIC_UNIFORM", "Timeout expired waiting for ready")
            end
        join_any
        disable fork;
    
        if (wait_seq.ready_observed) begin
            `uvm_info("TEST_BASIC_UNIFORM", $sformatf("DUT ready after %0d polls. Running scoreboard.",
                      wait_seq.reads_done), UVM_LOW)
            env.scoreboard.check_mem();
        end else begin
            `uvm_error("TEST_BASIC_UNIFORM", "DUT did not assert ready within watchdog timeout")
        end
    
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