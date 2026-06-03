`ifndef AXI_LITE_DRIVER_SV
`define AXI_LITE_DRIVER_SV

class axi_lite_driver extends uvm_driver #(axi_lite_seq_item);

    `uvm_component_utils(axi_lite_driver)

    virtual axi_lite_if vif;

    function new(string name = "axi_lite_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AXI_LITE_DRV", "build_phase running", UVM_LOW)
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "axi_lite_vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set: ", get_full_name(), ".vif"})
    endfunction

    task run_phase(uvm_phase phase);

        reset_signals();

        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("AXI_LITE_DRV",
                      $sformatf("Driving: %s", req.sprint()),
                      UVM_MEDIUM)
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    // Initialize bus to idle before any transactions
    task reset_signals();
        @(vif.cb);
        vif.cb.awvalid <= 1'b0;
        vif.cb.awaddr  <= '0;
        vif.cb.awprot  <= '0;
        vif.cb.wvalid  <= 1'b0;
        vif.cb.wdata   <= '0;
        vif.cb.wstrb   <= '0;
        vif.cb.bready  <= 1'b0;
        vif.cb.arvalid <= 1'b0;
        vif.cb.araddr  <= '0;
        vif.cb.arprot  <= '0;
        vif.cb.rready  <= 1'b0;
    endtask

    // Drive one transaction — based on direction
    task drive_transaction(axi_lite_seq_item req);
        if (req.dir == AXI_LITE_WRITE)
            drive_write(req);
        else
            drive_read(req);
    endtask

    // Drive a write transaction
    // AW and W channels are driven in parallel(axi lite protocol says they can), then we wait for B.
    task drive_write(axi_lite_seq_item req);
        fork
            drive_aw_channel(req);
            drive_w_channel(req);
        join
        wait_for_b_response(req);
    endtask

    // AW channel: assert AWVALID with rest of signals, wait for AWREADY
    task drive_aw_channel(axi_lite_seq_item req);
        @(vif.cb);
        vif.cb.awvalid <= 1'b1;
        vif.cb.awaddr  <= req.addr;
        vif.cb.awprot  <= req.prot;
        @(vif.cb iff vif.cb.awready);    // wait until slave accepts
        vif.cb.awvalid <= 1'b0;
        vif.cb.awaddr  <= '0;
        vif.cb.awprot  <= '0;
    endtask

    // W channel: assert WVALID with rest of signals, wait for WREADY
    task drive_w_channel(axi_lite_seq_item req);
        @(vif.cb);
        vif.cb.wvalid <= 1'b1;
        vif.cb.wdata  <= req.data;
        vif.cb.wstrb  <= req.wstrb;
        @(vif.cb iff vif.cb.wready);
        vif.cb.wvalid <= 1'b0;
        vif.cb.wdata  <= '0;
        vif.cb.wstrb  <= '0;
    endtask

    // B channel: assert BREADY and wait for BVALID, read response
    task wait_for_b_response(axi_lite_seq_item req);
        @(vif.cb);
        vif.cb.bready <= 1'b1;
        @(vif.cb iff vif.cb.bvalid);
        req.resp = axi_lite_resp_e'(vif.cb.bresp);
        @(vif.cb);
        vif.cb.bready <= 1'b0;
    endtask

    // Drive a read transaction
    task drive_read(axi_lite_seq_item req);
        drive_ar_channel(req);
        wait_for_r_response(req);
    endtask

    // AR channel: assert ARVALID, wait for ARREADY
    task drive_ar_channel(axi_lite_seq_item req);
        @(vif.cb);
        vif.cb.arvalid <= 1'b1;
        vif.cb.araddr  <= req.addr;
        vif.cb.arprot  <= req.prot;
        @(vif.cb iff vif.cb.arready);
        vif.cb.arvalid <= 1'b0;
        vif.cb.araddr  <= '0;
        vif.cb.arprot  <= '0;
    endtask

    // R channel: assert RREADY and wait for RVALID, read data and response
    task wait_for_r_response(axi_lite_seq_item req);
        @(vif.cb);
        vif.cb.rready <= 1'b1;
        @(vif.cb iff vif.cb.rvalid);
        req.data = vif.cb.rdata;
        req.resp = axi_lite_resp_e'(vif.cb.rresp);
        @(vif.cb);
        vif.cb.rready <= 1'b0;
    endtask

endclass : axi_lite_driver

`endif