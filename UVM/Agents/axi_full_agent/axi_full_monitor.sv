`ifndef AXI_FULL_MONITOR_SV
`define AXI_FULL_MONITOR_SV

class axi_full_monitor extends uvm_monitor;

    `uvm_component_utils(axi_full_monitor)

    virtual axi_full_if vif;
    axi_full_config     cfg;
    uvm_analysis_port #(axi_full_seq_item) ap;
    
    // Burst progress tracking for A6, A7, A9
    int unsigned aw_expected_beats = 0;
    int unsigned w_beats_received = 0;
    int unsigned ar_expected_beats = 0;
    int unsigned r_beats_received = 0;
    
    // Outstanding-transaction tracking for A14
    int unsigned outstanding_reads  = 0;
    int unsigned outstanding_writes = 0;

    // Internal queues for communication between channel tasks
    axi_full_seq_item aw_queue [$];
    axi_full_seq_item ar_queue [$];

    // arrays used for storing data from write channel
    bit [31:0] w_data_collected [];
    bit [3:0]  w_strb_collected [];
    int        w_transaction_count;
    int        w_expected_transactions;

    function new(string name = "axi_full_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AXI_FULL_MON", "build_phase running", UVM_LOW)
        if (!uvm_config_db#(virtual axi_full_if)::get(this, "", "axi_full_vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set: ", get_full_name(), ".vif"})
            
        // Get config for assertion enables (use defaults if not provided)
        if (!uvm_config_db#(axi_full_config)::get(this, "", "axi_cfg", cfg)) begin
            `uvm_info("AXI_FULL_MON", "No config from agent, creating default", UVM_LOW)
        end
    endfunction

    // Run phase - parallel channels
    task run_phase(uvm_phase phase);
        fork
            monitor_aw_channel();
            monitor_w_channel();
            monitor_b_channel();
            monitor_ar_channel();
            monitor_r_channel();
            
            // Stability monitors
            awvalid_stable();       // A1
            wvalid_stable();        // A2
            arvalid_stable();       // A3
            aw_signal_stable();     // A4
            ar_signal_stable();     // A5
            bvalid_after_wlast();   // A8
        join_none
    endtask

    // AW channel - captures write address
    task monitor_aw_channel();
        axi_full_seq_item txn;
        
        // For A10
        int beats;
        int bytes_per_beat;
        longint burst_end_addr;
        
        forever begin
            @(vif.cb iff (vif.cb.awvalid && vif.cb.awready));
            txn = axi_full_seq_item::type_id::create("aw_txn");
            txn.dir   = AXI_FULL_WRITE;
            txn.id    = vif.cb.awid;
            txn.addr  = vif.cb.awaddr;
            txn.len   = vif.cb.awlen;
            txn.size  = vif.cb.awsize;
            txn.burst = axi_full_burst_e'(vif.cb.awburst);
            txn.lock  = vif.cb.awlock;
            txn.cache = vif.cb.awcache;
            txn.prot  = vif.cb.awprot;
            txn.qos   = vif.cb.awqos;

            // Initialize the data/wstrb arrays for incoming W channel transactions
            w_expected_transactions = vif.cb.awlen + 1;
            w_transaction_count = 0;
            w_data_collected = new[w_expected_transactions];
            w_strb_collected = new[w_expected_transactions];

            aw_queue.push_back(txn);
            
            // ----- A10: AW burst does not cross 4KB boundary -----
            beats          = vif.cb.awlen + 1;
            bytes_per_beat = 1 << vif.cb.awsize;
            burst_end_addr = vif.cb.awaddr + beats * bytes_per_beat - 1;
            
            if (cfg.enable_4kb_checks) begin
                assert ((vif.cb.awaddr[31:12]) == (burst_end_addr[31:12]))
                else `uvm_warning("AXI_A10", $sformatf("AW burst crosses 4KB boundary: start=0x%08h end=0x%0h",
                                  vif.cb.awaddr, burst_end_addr))
            end
            // -----------------------------------------------------
            
            // ----- A12: AWSIZE always = 2 (4 bytes) -----
            assert (vif.cb.awsize == 3'b010)
            else 
                `uvm_error("AXI_A12", $sformatf("AWSIZE = 0x%h, expected 0x2 (4 bytes per beat)", vif.cb.awsize))
            // --------------------------------------------
            
            // ----- A14 (writes): outstanding writes must be 0 before this AW -----
            assert (outstanding_writes == 0)
            else 
                `uvm_error("AXI_A14", $sformatf("Outstanding write count = %0d at AW accept (expected 0)",
                           outstanding_writes))
            // ---------------------------------------------------------------------
            
            // ----- A15 (AW): AWID = 0 -----
            assert (vif.cb.awid == 1'b0)
            else 
                `uvm_error("AXI_A15", $sformatf("AWID = 0x%h, expected 0x0", vif.cb.awid))
            // ------------------------------
            
            // ----- A17: AWADDR 4-byte aligned -----
            if (cfg.enable_alignment_checks) begin
                assert ((vif.cb.awaddr & 32'h0000_0003) == 32'h0)
                else 
                    `uvm_error("AXI_A17", $sformatf("AWADDR = 0x%08h not 4-byte aligned", vif.cb.awaddr))
            end
            // --------------------------------------  
            
            // ----- A18: AWLEN always = 255 -----
            assert (vif.cb.awlen == 8'hFF)
            else 
                `uvm_error("AXI_A18", $sformatf("AWLEN = 0x%h, expected 0xFF (256-beat burst)", vif.cb.awlen)) 
            // -----------------------------------    
            
            // ----- A20: AWPROT = 0 (Data, Secure, Unprivileged) -----
            assert (vif.cb.awprot == 3'b000)
            else 
                `uvm_error("AXI_A20", $sformatf("AWPROT = 0x%h, expected 0x0", vif.cb.awprot))  
            // --------------------------------------------------------
            
            // ----- A22: AWCACHE = 4'b0010 (Modifiable) -----
            assert (vif.cb.awcache == 4'b0010)
            else 
                `uvm_error("AXI_A22", $sformatf("AWCACHE = 0x%h, expected 0x2 (Modifiable)", vif.cb.awcache))
            // -----------------------------------------------
            
            // ----- A24: AWLOCK = 0 (normal access) -----
            assert (vif.cb.awlock == 1'b0)
            else 
                `uvm_error("AXI_A24", $sformatf("AWLOCK = 0x%h, expected 0x0", vif.cb.awlock))
            // -------------------------------------------

            // ----- A26: AWQOS = 0 (no priority) -----
            assert (vif.cb.awqos == 4'b0000)
            else 
                `uvm_error("AXI_A26", $sformatf("AWQOS = 0x%h, expected 0x0", vif.cb.awqos))
            // ----------------------------------------
            
            // Track outstanding + burst progress
            outstanding_writes++;
            aw_expected_beats = w_expected_transactions;    //its the same thing: burst = transaction
            w_beats_received = 0;

            `uvm_info("AXI_FULL_MON", $sformatf("AW captured: addr=0x%08h len=%0d", txn.addr, txn.len), UVM_HIGH)
        end
    endtask

    // W channel - captures each transaction of write data
    task monitor_w_channel();
        forever begin
            @(vif.cb iff (vif.cb.wvalid && vif.cb.wready));
            
            // ----- A6: WLAST must be high exactly on the last beat -----
            w_beats_received++;          
            if (vif.cb.wlast == 1'b1) begin
                assert (w_beats_received == aw_expected_beats)
                else 
                    `uvm_error("AXI_A6", $sformatf("WLAST asserted at W beat %0d/%0d (should be only at last beat)",
                               w_beats_received, aw_expected_beats))
            end
            // -----------------------------------------------------------

            if (w_transaction_count < w_expected_transactions) begin
                w_data_collected[w_transaction_count] = vif.cb.wdata;
                w_strb_collected[w_transaction_count] = vif.cb.wstrb;
                w_transaction_count++;
            end

            `uvm_info("AXI_FULL_MON",
                      $sformatf("W beat %0d/%0d captured: data=0x%08h wlast=%0b",
                                w_transaction_count, w_expected_transactions, vif.cb.wdata, vif.cb.wlast), UVM_HIGH)
        end
    endtask

    // B channel - finalizes the write burst
    task monitor_b_channel();
        axi_full_seq_item write_txn;

        forever begin
            @(vif.cb iff (vif.cb.bvalid && vif.cb.bready));
            
            // ----- A7: number of W beats compared to AW transactoins should be AWLEN+1 -----
            // In the ver plan its on average, so (255 beats + 257 beats)/2 which would still give the average 256 (even though it should not happen)
            // So thats why this is better
            assert (w_beats_received == aw_expected_beats)
            else 
                `uvm_error("AXI_A7", $sformatf("B response with only %0d/%0d W beats received",
                           w_beats_received, aw_expected_beats))
            // -------------------------------------------------------------------------------
            

            wait (aw_queue.size() > 0);
            write_txn = aw_queue.pop_front();
            write_txn.data  = w_data_collected;
            write_txn.wstrb = w_strb_collected;
            write_txn.bresp = axi_full_resp_e'(vif.cb.bresp);

            `uvm_info("AXI_FULL_MON",
                      $sformatf("Write txn complete: %s", write_txn.to_string()),
                      UVM_LOW)

            ap.write(write_txn);
            
            // Clear outstanding/burst state
            outstanding_writes--;
            aw_expected_beats = 0;
            w_beats_received = 0;
        end
    endtask

    // AR channel - captures read address 
    task monitor_ar_channel();
        axi_full_seq_item txn;
        
        // For A11
        int beats;
        int bytes_per_beat;
        longint burst_end_addr;
        
        forever begin
            @(vif.cb iff (vif.cb.arvalid && vif.cb.arready));
            txn = axi_full_seq_item::type_id::create("ar_txn");
            txn.dir   = AXI_FULL_READ;
            txn.id    = vif.cb.arid;
            txn.addr  = vif.cb.araddr;
            txn.len   = vif.cb.arlen;
            txn.size  = vif.cb.arsize;
            txn.burst = axi_full_burst_e'(vif.cb.arburst);
            txn.lock  = vif.cb.arlock;
            txn.cache = vif.cb.arcache;
            txn.prot  = vif.cb.arprot;
            txn.qos   = vif.cb.arqos;

            // create data/rresp arrays for upcoming transactions
            txn.data  = new[txn.len + 1];
            txn.rresp = new[txn.len + 1];

            ar_queue.push_back(txn);
            
            // ----- A11: AR burst does not cross 4KB boundary -----
            beats          = vif.cb.arlen + 1;
            bytes_per_beat = 1 << vif.cb.arsize;
            burst_end_addr = vif.cb.araddr + beats * bytes_per_beat - 1;
            
            if (cfg.enable_4kb_checks) begin
                assert ((vif.cb.araddr[31:12]) == (burst_end_addr[31:12]))
                else 
                    `uvm_warning("AXI_A11", $sformatf("AR burst crosses 4KB boundary: start=0x%08h end=0x%0h",
                                 vif.cb.araddr, burst_end_addr))
            end
            // -----------------------------------------------------------
            
            // ----- A13: ARSIZE always = 2 (4 bytes) -----
            assert (vif.cb.arsize == 3'b010)
            else 
                `uvm_error("AXI_A13", $sformatf("ARSIZE = 0x%h, expected 0x2 (4 bytes per beat)", vif.cb.arsize))
            // --------------------------------------------
            
            // ----- A14 (reads): outstanding reads must be 0 before this AR -----
            assert (outstanding_reads == 0)
            else 
                `uvm_error("AXI_A14", $sformatf("Outstanding read count = %0d at AR accept (expected 0)",
                           outstanding_reads))
            // -------------------------------------------------------------------
            
            // ----- A15 (AR): ARID = 0 -----
            assert (vif.cb.arid == 1'b0)
            else 
                `uvm_error("AXI_A15", $sformatf("ARID = 0x%h, expected 0x0", vif.cb.arid))
            // ------------------------------
                     
            // ----- A16: ARADDR 4-byte aligned -----
            if (cfg.enable_alignment_checks) begin
                assert ((vif.cb.araddr & 32'h0000_0003) == 32'h0)
                else 
                    `uvm_error("AXI_A16", $sformatf("ARADDR = 0x%08h not 4-byte aligned", vif.cb.araddr))
            end
            // --------------------------------------        
            
            // ----- A19: ARLEN always = 255 -----
            assert (vif.cb.arlen == 8'hFF)
            else 
                `uvm_error("AXI_A19", $sformatf("ARLEN = 0x%h, expected 0xFF (256-beat burst)", vif.cb.arlen))
            // -----------------------------------
            
            // ----- A21: ARPROT = 0 (Data, Secure, Unprivileged) -----
            assert (vif.cb.arprot == 3'b000)
            else 
                `uvm_error("AXI_A21", $sformatf("ARPROT = 0x%h, expected 0x0", vif.cb.arprot))
            // --------------------------------------------------------
            
            // ----- A23: ARCACHE = 4'b0010 (Modifiable) -----
            assert (vif.cb.arcache == 4'b0010)
            else 
                `uvm_error("AXI_A23", $sformatf("ARCACHE = 0x%h, expected 0x2 (Modifiable)", vif.cb.arcache))
            // -----------------------------------------------
            
            // ----- A25: ARLOCK = 0 -----
            assert (vif.cb.arlock == 1'b0)
            else 
                `uvm_error("AXI_A25", $sformatf("ARLOCK = 0x%h, expected 0x0", vif.cb.arlock))
            // ---------------------------

            // ----- A27: ARQOS = 0 -----
            assert (vif.cb.arqos == 4'b0000)
            else 
                `uvm_error("AXI_A27", $sformatf("ARQOS = 0x%h, expected 0x0", vif.cb.arqos))
            // --------------------------
            
            // Track outstanding + burst progress
            outstanding_reads++;
            ar_expected_beats = vif.cb.arlen + 1;
            r_beats_received = 0;

            `uvm_info("AXI_FULL_MON", $sformatf("AR captured: addr=0x%08h len=%0d", txn.addr, txn.len), UVM_HIGH)
        end
    endtask

    // R channel - accumulates beats, closes burst on RLAST
    task monitor_r_channel();
        axi_full_seq_item read_txn;
        int transaction_idx;

        transaction_idx = 0;
        forever begin
            @(vif.cb iff (vif.cb.rvalid && vif.cb.rready));
            
            r_beats_received++;

            wait (ar_queue.size() > 0);
            read_txn = ar_queue[0];   // dont pop until RLAST

            if (transaction_idx < read_txn.data.size()) begin
                read_txn.data[transaction_idx]  = vif.cb.rdata;
                read_txn.rresp[transaction_idx] = axi_full_resp_e'(vif.cb.rresp);
            end

            `uvm_info("AXI_FULL_MON",
                      $sformatf("R beat %0d captured: data=0x%08h rlast=%0b",
                                transaction_idx, vif.cb.rdata, vif.cb.rlast), UVM_HIGH)

            transaction_idx++;
			
			// last transaction of a burst - finalize the burst and write 
            if (vif.cb.rlast) begin
                // ----- A9: total R beats received must equal ARLEN+1 -----
                assert (r_beats_received == ar_expected_beats)
                else 
                    `uvm_error("AXI_A9", $sformatf("Received %0d R beats but expected %0d (RLAST at wrong position)",
                               r_beats_received, ar_expected_beats))
                // ---------------------------------------------------------
            
                ar_queue.pop_front();   // burst finished - wait for the next one

                `uvm_info("AXI_FULL_MON", $sformatf("Read txn complete: %s", read_txn.to_string()), UVM_LOW)

                ap.write(read_txn);
                transaction_idx = 0;   // reset for next burst
                
                // Clear outstanding/burst state
                outstanding_reads--;
                ar_expected_beats = 0;
                r_beats_received = 0;
            end
        end
    endtask
    
    
    // A1: AWVALID stable until AWREADY is observed highx
    task awvalid_stable();
        forever begin
            @(vif.cb iff vif.cb.awvalid);
            // If AWREADY isnt already high, watch that AWVALID stays high
            while (vif.cb.awready == 1'b0) begin
                assert (vif.cb.awvalid == 1'b1)
                else 
                    `uvm_error("AXI_A1", "AWVALID dropped before AWREADY was observed high")
                @(vif.cb);
            end
        end
    endtask

    // A2: WVALID stable until WREADY is observed high
    task wvalid_stable();
        forever begin
            @(vif.cb iff vif.cb.wvalid);
            while (vif.cb.wready == 1'b0) begin
                assert (vif.cb.wvalid == 1'b1)
                else 
                    `uvm_error("AXI_A2", "WVALID dropped before WREADY was observed high")
                @(vif.cb);
            end
        end
    endtask

    // A3: ARVALID stable until ARREADY is observed high
    task arvalid_stable();
        forever begin
            @(vif.cb iff vif.cb.arvalid);
            while (vif.cb.arready == 1'b0) begin
                assert (vif.cb.arvalid == 1'b1)
                else 
                    `uvm_error("AXI_A3", "ARVALID dropped before ARREADY was observed high")
                @(vif.cb);
            end
        end
    endtask

    // A4: AWADDR/AWLEN/AWSIZE/AWBURST stable while AWVALID && !AWREADY
    task aw_signal_stable();
        bit [31:0] awaddr_at_valid;
        bit [7:0]  awlen_at_valid;
        bit [2:0]  awsize_at_valid;
        bit [1:0]  awburst_at_valid;
        
        forever begin
            @(vif.cb iff (vif.cb.awvalid && !vif.cb.awready));
            awaddr_at_valid  = vif.cb.awaddr;
            awlen_at_valid   = vif.cb.awlen;
            awsize_at_valid  = vif.cb.awsize;
            awburst_at_valid = vif.cb.awburst;

            while (vif.cb.awvalid && !vif.cb.awready) begin
                assert (vif.cb.awaddr == awaddr_at_valid)
                else 
                    `uvm_error("AXI_A4", $sformatf("AWADDR changed from 0x%08h to 0x%08h while AWVALID && !AWREADY",
                               awaddr_at_valid, vif.cb.awaddr))
                assert (vif.cb.awlen == awlen_at_valid)
                else 
                    `uvm_error("AXI_A4", $sformatf("AWLEN changed from 0x%h to 0x%h while AWVALID && !AWREADY",
                               awlen_at_valid, vif.cb.awlen))
                assert (vif.cb.awsize == awsize_at_valid)
                else 
                    `uvm_error("AXI_A4", $sformatf("AWSIZE changed from 0x%h to 0x%h while AWVALID && !AWREADY",
                               awsize_at_valid, vif.cb.awsize))
                assert (vif.cb.awburst == awburst_at_valid)
                else 
                    `uvm_error("AXI_A4", $sformatf("AWBURST changed from 0x%h to 0x%h while AWVALID && !AWREADY",
                               awburst_at_valid, vif.cb.awburst))
                @(vif.cb);
            end
        end
    endtask

    // A5: ARADDR/ARLEN/ARSIZE/ARBURST stable while ARVALID && !ARREADY
    task ar_signal_stable();
        bit [31:0] araddr_at_valid;
        bit [7:0]  arlen_at_valid;
        bit [2:0]  arsize_at_valid;
        bit [1:0]  arburst_at_valid;
        
        forever begin
            @(vif.cb iff (vif.cb.arvalid && !vif.cb.arready));
            araddr_at_valid  = vif.cb.araddr;
            arlen_at_valid   = vif.cb.arlen;
            arsize_at_valid  = vif.cb.arsize;
            arburst_at_valid = vif.cb.arburst;

            while (vif.cb.arvalid && !vif.cb.arready) begin
                assert (vif.cb.araddr == araddr_at_valid)
                else 
                    `uvm_error("AXI_A5", $sformatf("ARADDR changed from 0x%08h to 0x%08h while ARVALID && !ARREADY",
                               araddr_at_valid, vif.cb.araddr))
                assert (vif.cb.arlen == arlen_at_valid)
                else 
                    `uvm_error("AXI_A5", $sformatf("ARLEN changed from 0x%h to 0x%h while ARVALID && !ARREADY",
                               arlen_at_valid, vif.cb.arlen))
                assert (vif.cb.arsize == arsize_at_valid)
                else 
                    `uvm_error("AXI_A5", $sformatf("ARSIZE changed from 0x%h to 0x%h while ARVALID && !ARREADY",
                               arsize_at_valid, vif.cb.arsize))
                assert (vif.cb.arburst == arburst_at_valid)
                else 
                    `uvm_error("AXI_A5", $sformatf("ARBURST changed from 0x%h to 0x%h while ARVALID && !ARREADY",
                               arburst_at_valid, vif.cb.arburst))
                @(vif.cb);
            end
        end
    endtask
    
    // ----- A8: BVALID only legal after WLAST handshake -----
    task bvalid_after_wlast();
        bit wlast_seen = 0;
        
        fork
            forever begin
                @(vif.cb iff (vif.cb.wvalid && vif.cb.wready && vif.cb.wlast));
                wlast_seen = 1;
            end
            forever begin
                @(vif.cb iff (vif.cb.bvalid && vif.cb.bready));
                assert (wlast_seen == 1)
                else 
                    `uvm_error("AXI_A8", "BVALID asserted before WLAST")
                wlast_seen = 0;   // reset for next burst
            end
        join_none
    endtask

endclass : axi_full_monitor

`endif