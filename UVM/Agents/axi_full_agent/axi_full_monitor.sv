`ifndef AXI_FULL_MONITOR_SV
`define AXI_FULL_MONITOR_SV

class axi_full_monitor extends uvm_monitor;

    `uvm_component_utils(axi_full_monitor)

    virtual axi_full_if vif;
    uvm_analysis_port #(axi_full_seq_item) ap;

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
    endfunction

    // Run phase - parallel channels
    task run_phase(uvm_phase phase);
        fork
            monitor_aw_channel();
            monitor_w_channel();
            monitor_b_channel();
            monitor_ar_channel();
            monitor_r_channel();
        join_none
    endtask

    // AW channel - captures write address
    task monitor_aw_channel();
        axi_full_seq_item txn;
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

            `uvm_info("AXI_FULL_MON", $sformatf("AW captured: addr=0x%08h len=%0d", txn.addr, txn.len), UVM_HIGH)
        end
    endtask

    // W channel - captures each transaction of write data
    task monitor_w_channel();
        forever begin
            @(vif.cb iff (vif.cb.wvalid && vif.cb.wready));

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

            wait (aw_queue.size() > 0);
            write_txn = aw_queue.pop_front();
            write_txn.data  = w_data_collected;
            write_txn.wstrb = w_strb_collected;
            write_txn.bresp = axi_full_resp_e'(vif.cb.bresp);

            `uvm_info("AXI_FULL_MON",
                      $sformatf("Write txn complete: %s", write_txn.to_string()),
                      UVM_LOW)

            ap.write(write_txn);
        end
    endtask

    // AR channel - captures read address 
    task monitor_ar_channel();
        axi_full_seq_item txn;
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
                ar_queue.pop_front();   // burst finished - wait for the next one

                `uvm_info("AXI_FULL_MON", $sformatf("Read txn complete: %s", read_txn.to_string()), UVM_LOW)

                ap.write(read_txn);
                transaction_idx = 0;   // reset for next burst
            end
        end
    endtask

endclass : axi_full_monitor

`endif