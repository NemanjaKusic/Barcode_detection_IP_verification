`ifndef AXI_LITE_MONITOR_SV
`define AXI_LITE_MONITOR_SV

class axi_lite_monitor extends uvm_monitor;

    `uvm_component_utils(axi_lite_monitor)

    virtual axi_lite_if vif;
    uvm_analysis_port #(axi_lite_seq_item) ap;
	
    // Internal queues inside axi lite channel tasks for communication between them
    axi_lite_seq_item aw_queue [$];   // captured AW info, used in monitor_b_channel
    axi_lite_seq_item w_queue  [$];   // captured W info, used in monitor_b_channel
    axi_lite_seq_item ar_queue [$];   // captured AR info, used in monitor_r_channel

    function new(string name = "axi_lite_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AXI_LITE_MON", "build_phase running", UVM_LOW)
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "axi_lite_vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set: ", get_full_name(), ".vif"})
    endfunction


    task run_phase(uvm_phase phase);
		//every channel runs in parallel
        fork
            monitor_aw_channel();
            monitor_w_channel();
            monitor_b_channel();
            monitor_ar_channel();
            monitor_r_channel();
        join_none
    endtask

    // AW channel task — captures every write address signal 
    task monitor_aw_channel();
        axi_lite_seq_item txn;
        forever begin
            @(vif.cb iff (vif.cb.awvalid && vif.cb.awready));
            txn = axi_lite_seq_item::type_id::create("aw_txn");
            txn.dir   = AXI_LITE_WRITE;
            //txn.dir   = 1;
            txn.addr  = vif.cb.awaddr;
            txn.prot  = vif.cb.awprot;
            aw_queue.push_back(txn);
            `uvm_info("AXI_LITE_MON", $sformatf("AW captured: addr=0x%01h prot=%b", txn.addr, txn.prot), UVM_HIGH)
        end
    endtask

    // W channel task — captures every write data signal
    task monitor_w_channel();
        axi_lite_seq_item txn;
        forever begin
            @(vif.cb iff (vif.cb.wvalid && vif.cb.wready));
            txn = axi_lite_seq_item::type_id::create("w_txn");
            txn.data  = vif.cb.wdata;
            txn.wstrb = vif.cb.wstrb;
            w_queue.push_back(txn);
            `uvm_info("AXI_LITE_MON", $sformatf("W captured: data=0x%08h wstrb=%b", txn.data, txn.wstrb), UVM_HIGH)
        end
    endtask
	
    // B channel task — reads response and combines into one transaction
    task monitor_b_channel();
        axi_lite_seq_item write_txn;
        axi_lite_seq_item aw_part;
        axi_lite_seq_item w_part;

        forever begin
            @(vif.cb iff (vif.cb.bvalid && vif.cb.bready));

			//checks if the previous two channel tasks did their job
            wait (aw_queue.size() > 0 && w_queue.size() > 0);

			//no creation because they are created and then stored inside the queues
            aw_part = aw_queue.pop_front();
            w_part  = w_queue.pop_front();

            write_txn = axi_lite_seq_item::type_id::create("write_txn");
            write_txn.dir   = AXI_LITE_WRITE;
            //write_txn.dir   = 1;
            write_txn.addr  = aw_part.addr;
            write_txn.prot  = aw_part.prot;
            write_txn.data  = w_part.data;
            write_txn.wstrb = w_part.wstrb;
            write_txn.resp  = axi_lite_resp_e'(vif.cb.bresp);
            //write_txn.resp  = vif.cb.bresp;

            `uvm_info("AXI_LITE_MON",
						$sformatf("Write txn complete: %s", write_txn.sprint()),
						UVM_LOW)

            ap.write(write_txn);
        end
    endtask

    // AR channel task — captures every read address signal
    task monitor_ar_channel();
        axi_lite_seq_item txn;
        forever begin
            @(vif.cb iff (vif.cb.arvalid && vif.cb.arready));
            txn = axi_lite_seq_item::type_id::create("ar_txn");
            txn.dir  = AXI_LITE_READ;
            //txn.dir  = 0;
            txn.addr = vif.cb.araddr;
            txn.prot = vif.cb.arprot;
            ar_queue.push_back(txn);
            `uvm_info("AXI_LITE_MON", $sformatf("AR captured: addr=0x%01h prot=%b", txn.addr, txn.prot), UVM_HIGH)
        end
    endtask

    // R channel task — reads response and combines it with the transaction from the previous task into one transaction
    task monitor_r_channel();
        axi_lite_seq_item read_txn;
        axi_lite_seq_item ar_part;

        forever begin
            @(vif.cb iff (vif.cb.rvalid && vif.cb.rready));

            wait (ar_queue.size() > 0);
            ar_part = ar_queue.pop_front();

            read_txn = axi_lite_seq_item::type_id::create("read_txn");
            read_txn.dir  = AXI_LITE_READ;
            //read_txn.dir  = 0;
            read_txn.addr = ar_part.addr;
            read_txn.prot = ar_part.prot;
            read_txn.data = vif.cb.rdata;
            read_txn.resp = axi_lite_resp_e'(vif.cb.rresp);
            //read_txn.resp = vif.cb.rresp;
            
            `uvm_info("AXI_LITE_MON",
                      $sformatf("Read txn complete: %s", read_txn.sprint()),
                      UVM_MEDIUM)
//read_txn.convert2string()
            ap.write(read_txn);
        end
    endtask

endclass : axi_lite_monitor

`endif