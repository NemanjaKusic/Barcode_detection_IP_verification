`ifndef AXI_FULL_CONFIG_SV
`define AXI_FULL_CONFIG_SV

// Modes for grouping common configurations
typedef enum {
    AXI_FULL_MODE_FAST,
    AXI_FULL_MODE_LATENCY,
    AXI_FULL_MODE_BACKPRESSURE,
    AXI_FULL_MODE_COMBINED
} axi_full_mode_e;

class axi_full_config extends uvm_object;

    `uvm_object_utils(axi_full_config)

    function new(string name = "axi_full_config");
        super.new(name);
    endfunction
    
    // Min and Max VALID signal latencies (that driver drives)
    rand int min_ar_to_r_latency = 1;        // min cycles from AR accepted to first R transaction of a burst
    rand int max_ar_to_r_latency = 1;        // max cycles from AR accepted to first R transaction of a burst
    rand int min_inside_burst_latency = 0;    // min idle cycles between R transactions of a burst
    rand int max_inside_burst_latency = 0;    // min idle cycles between R transactions of a burst
    rand int min_wlast_to_b_latency = 1;     // min cycles from WLAST to BVALID
    rand int max_wlast_to_b_latency = 1;     // max cycles from WLAST to BVALID

    // Changes (in percentages) of droping READY signals (that driver drives)
    rand int awready_backpressure_pct = 0;   // 0-100
    rand int wready_backpressure_pct  = 0;
    rand int arready_backpressure_pct = 0;
    // max cycles READY stays low
    rand int backpressure_max_duration = 0; 

    // Constraints
    constraint c_latency_ranges {
        min_ar_to_r_latency >= 0;      min_ar_to_r_latency <= max_ar_to_r_latency;           max_ar_to_r_latency <= 100;
        min_inside_burst_latency >= 0; min_inside_burst_latency <= max_inside_burst_latency; max_inside_burst_latency <= 20;
        min_wlast_to_b_latency >= 0;   min_wlast_to_b_latency <= max_wlast_to_b_latency;     max_wlast_to_b_latency <= 100;
    }

    constraint c_backpressure_ranges {
        awready_backpressure_pct  inside {[0:100]};
        wready_backpressure_pct   inside {[0:100]};
        arready_backpressure_pct  inside {[0:100]};
        backpressure_max_duration inside {[0:20]};
    }


    // Driver/memory modes - tests can call set_mode(MODE) instead of setting fields
    function void set_mode(axi_full_mode_e mode);
        case (mode)
            AXI_FULL_MODE_FAST: begin
                min_ar_to_r_latency       = 0;
                max_ar_to_r_latency       = 0;
                min_inside_burst_latency  = 0;
                max_inside_burst_latency  = 0;
                min_wlast_to_b_latency    = 0;
                max_wlast_to_b_latency    = 0;
                awready_backpressure_pct  = 0;
                wready_backpressure_pct   = 0;
                arready_backpressure_pct  = 0;
                backpressure_max_duration = 0;
            end
            AXI_FULL_MODE_LATENCY: begin
                min_ar_to_r_latency       = 5;
                max_ar_to_r_latency       = 50;
                min_inside_burst_latency  = 0;
                max_inside_burst_latency  = 3;
                min_wlast_to_b_latency    = 5;
                max_wlast_to_b_latency    = 50;
                awready_backpressure_pct  = 0;
                wready_backpressure_pct   = 0;
                arready_backpressure_pct  = 0;
                backpressure_max_duration = 0;
            end
            AXI_FULL_MODE_BACKPRESSURE: begin
                min_ar_to_r_latency       = 0;
                max_ar_to_r_latency       = 0;
                min_inside_burst_latency  = 0;
                max_inside_burst_latency  = 0;
                min_wlast_to_b_latency    = 0;
                max_wlast_to_b_latency    = 0;
                awready_backpressure_pct  = 40;
                wready_backpressure_pct   = 40;
                arready_backpressure_pct  = 40;
                backpressure_max_duration = 5;
            end
            AXI_FULL_MODE_COMBINED: begin
                min_ar_to_r_latency       = 5;
                max_ar_to_r_latency       = 50;
                min_inside_burst_latency  = 0;
                max_inside_burst_latency  = 3;
                min_wlast_to_b_latency    = 5;
                max_wlast_to_b_latency    = 50;
                awready_backpressure_pct  = 30;
                wready_backpressure_pct   = 30;
                arready_backpressure_pct  = 30;
                backpressure_max_duration = 5;
            end
        endcase
    endfunction

    // Print the values of latencies and backpressures
    function string print_mode();
        return $sformatf(
            "AR-to-R latency: [%0d - %0d], Inside burst gap: [%0d - %0d], AW-to-B latency: [%0d - %0d], Backpressure: AW=%0d%% W=%0d%% AR=%0d%% (max %0d cycles)",
            min_ar_to_r_latency, max_ar_to_r_latency,
            min_inside_burst_latency, max_inside_burst_latency,
            min_wlast_to_b_latency, max_wlast_to_b_latency,
            awready_backpressure_pct, wready_backpressure_pct,
            arready_backpressure_pct, backpressure_max_duration);
    endfunction
	
endclass 

`endif