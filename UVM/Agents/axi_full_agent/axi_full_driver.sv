`ifndef AXI_FULL_DRIVER_SV
`define AXI_FULL_DRIVER_SV

class axi_full_driver extends uvm_driver;   // no #(seq_item) - data from memory_model

    `uvm_component_utils(axi_full_driver)

    virtual axi_full_if vif;
    memory_model mem;

    // Internal queues - for communication betwwen channel tasks
    // Holds AR channel info.
    typedef struct {
        bit [31:0] addr;
        bit [7:0]  len;
        bit [0:0]  id;
    } ar_req_t;
    ar_req_t ar_queue [$];

    // Holds AW channel info
    typedef struct {
        bit [31:0] addr;
        bit [7:0]  len;
        bit [0:0]  id;
    } aw_req_t;
    aw_req_t aw_queue [$];


    function new(string name = "axi_full_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AXI_FULL_DRV", "build_phase running", UVM_LOW)

        if (!uvm_config_db#(virtual axi_full_if)::get(this, "", "axi_full_vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set: ", get_full_name(), ".vif"})

        if (!uvm_config_db#(memory_model)::get(this, "", "shared_mem", mem))
            `uvm_fatal("NOMEM", {"shared memory model must be set: ", get_full_name(), ".mem"})
    endfunction

    task run_phase(uvm_phase phase);
        reset_signals();
        fork
            ar_channel();
            r_channel();
            aw_channel();
            w_channel();
            b_channel();
        join_none
    endtask

    // Reset all slave-driven signals 
    task reset_signals();
        @(vif.cb);
        vif.cb.awready <= 1'b0;
        vif.cb.wready  <= 1'b0;
        vif.cb.bvalid  <= 1'b0;
        vif.cb.bid     <= '0;
        vif.cb.bresp   <= 2'b00;
        vif.cb.arready <= 1'b0;
        vif.cb.rvalid  <= 1'b0;
        vif.cb.rid     <= '0;
        vif.cb.rdata   <= '0;
        vif.cb.rresp   <= 2'b00;
        vif.cb.rlast   <= 1'b0;
    endtask

    // READ SIDE
	
    // AR channel - accept incoming read requests
    task ar_channel();
        ar_req_t req;
        forever begin
            @(vif.cb);
            vif.cb.arready <= 1'b1;
            @(vif.cb iff vif.cb.arvalid);	// ARREADY and ARVALID both high
            req.addr = vif.cb.araddr;
            req.len  = vif.cb.arlen;
            req.id   = vif.cb.arid;
            ar_queue.push_back(req);

            `uvm_info("AXI_FULL_DRV", $sformatf("AR accepted: addr=0x%08h len=%0d", req.addr, req.len), UVM_HIGH)

            @(vif.cb);
            vif.cb.arready <= 1'b0;		// Indication that the transaction is complete
        end
    endtask

    // R channel - produce read response beats (beat - one transaction of a burst)
    task r_channel();
        ar_req_t req;
        bit [31:0] beat_data;
        int total_beats;

        forever begin
            // Wait until an AR is in the queue
            wait (ar_queue.size() > 0);
            req = ar_queue.pop_front();
            total_beats = req.len + 1;

            // Drive each beat
            for (int beat = 0; beat < total_beats; beat++) begin
                beat_data = mem.read_word(req.addr + beat * 4);

                @(vif.cb);
                vif.cb.rvalid <= 1'b1;
                vif.cb.rid    <= req.id;
                vif.cb.rdata  <= beat_data;
                vif.cb.rresp  <= 2'b00;   // OKAY
                vif.cb.rlast  <= (beat == total_beats - 1);

                @(vif.cb iff vif.cb.rready);	// Handshake completed on this clock
            end

            // Reset R signals after burst
            @(vif.cb);
            vif.cb.rvalid <= 1'b0;
            vif.cb.rlast  <= 1'b0;
            vif.cb.rdata  <= '0;
            vif.cb.rid    <= '0;

            `uvm_info("AXI_FULL_DRV", $sformatf("Read burst complete: addr=0x%08h beats=%0d", req.addr, total_beats), UVM_LOW)
        end
    endtask

    // WRITE SIDE

    // AW channel - accept incoming write address, length, id
    task aw_channel();
        aw_req_t req;
        forever begin
            @(vif.cb);
            vif.cb.awready <= 1'b1;
            @(vif.cb iff vif.cb.awvalid);
            req.addr = vif.cb.awaddr;
            req.len  = vif.cb.awlen;
            req.id   = vif.cb.awid;
            aw_queue.push_back(req);

            `uvm_info("AXI_FULL_DRV", $sformatf("AW accepted: addr=0x%08h len=%0d", req.addr, req.len), UVM_HIGH)

            @(vif.cb);
            vif.cb.awready <= 1'b0;		// Indication that the transaction is complete
        end
    endtask

    // W channel - accept write data beats and store into memory
    task w_channel();
        aw_req_t current;
        int beat_idx;
        int total_beats;

        forever begin
            // Wait for an AW in the queue
            wait (aw_queue.size() > 0);
            current = aw_queue[0];   // dont pop in this channel
            total_beats = current.len + 1;
            beat_idx = 0;

            while (beat_idx < total_beats) begin
                @(vif.cb);
                vif.cb.wready <= 1'b1;
                @(vif.cb iff vif.cb.wvalid);	// Handshake - then write beat into memory
                mem.write_word(current.addr + beat_idx * 4, vif.cb.wdata);

                `uvm_info("AXI_FULL_DRV", $sformatf("W beat %0d/%0d: addr=0x%08h data=0x%08h",
						beat_idx + 1, total_beats, current.addr + beat_idx * 4, vif.cb.wdata), UVM_HIGH)

                beat_idx++;
            end

            @(vif.cb);
            vif.cb.wready <= 1'b0;

        end
    endtask

    // B channel - send write response after burst is complete
    task b_channel();
        aw_req_t req;
        forever begin
            wait (aw_queue.size() > 0);		// Wait for AW channel to complete

            @(vif.cb iff (vif.cb.wlast && vif.cb.wvalid && vif.cb.wready));		// Wait for W channel to complete

            req = aw_queue.pop_front();

            // Drive B response singals
            @(vif.cb);
            vif.cb.bvalid <= 1'b1;
            vif.cb.bid    <= req.id;
            vif.cb.bresp  <= 2'b00;   // OKAY
            @(vif.cb iff vif.cb.bready);

			// Reset the B channel signals
            @(vif.cb);
            vif.cb.bvalid <= 1'b0;
            vif.cb.bid    <= '0;
            vif.cb.bresp  <= 2'b00;

            `uvm_info("AXI_FULL_DRV", $sformatf("Write response sent for addr=0x%08h", req.addr), UVM_LOW)
        end
    endtask

endclass : axi_full_driver

`endif