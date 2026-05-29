`ifndef SOBEL_SCOREBOARD_SV
`define SOBEL_SCOREBOARD_SV

class sobel_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(sobel_scoreboard)

    // Configuration set by the test
    memory_model     mem;
    longint unsigned base_address;
    string           golden_gx_path;
    string           golden_gy_path;

    // Image dimensions - constants
    int IMG_WIDTH     = 600;
    int IMG_HEIGHT    = 450;
    int IMG_PIXELS    = IMG_WIDTH * IMG_HEIGHT;     // 270,000
    int IMG_BYTES_IN  = IMG_PIXELS;                 // 270,000 (8bit)
    int IMG_BYTES_OUT = IMG_PIXELS * 2;             // 540,000 (16bit)
    int ZERO_BYTES    = 544;
    int GX_OFFSET     = IMG_BYTES_IN;               // 270,000
    int ZERO_OFFSET   = GX_OFFSET + IMG_BYTES_OUT;  // 810,000
    int GY_OFFSET     = ZERO_OFFSET + ZERO_BYTES;   // 810,544

    // Only first 20 mismatches are reported, no need for 270000
    int MAX_REPORTED_MISMATCHES = 20;

    // Mismatches count
    int gx_mismatches   = 0;
    int gy_mismatches   = 0;
    int zero_violations = 0;

    function new(string name = "sobel_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase - get the shared memory model
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("SCOREBOARD", "build_phase running", UVM_LOW)
        if (!uvm_config_db#(memory_model)::get(this, "", "shared_mem", mem))
            `uvm_fatal("NOMEM", {"shared memory model must be set: ", get_full_name()})
    endfunction

    // Main check function - called by the test after ready=1
    function void check_mem();
        `uvm_info("SCOREBOARD", "===== Starting end-of-test check =====", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("base_address = 0x%0h, golden_gx = %s, golden_gy = %s",
                  base_address, golden_gx_path, golden_gy_path), UVM_LOW)

        check_gx();
        check_zero_region();
        check_gy();

        report_summary();
    endfunction

    // Compare Gx region with golden file
    function void check_gx();
        int fh;
        string line;
        int line_no;
        int golden_value;
        shortint observed_value;
        longint unsigned addr;
        int reported;

        `uvm_info("SCOREBOARD", "Checking Gx region...", UVM_LOW)

        fh = $fopen(golden_gx_path, "r");
        if (fh == 0) begin
            `uvm_error("SCOREBOARD", $sformatf("Could not open golden file: %s", golden_gx_path))
            return;
        end

        line_no  = 0;
        reported = 0;

        while ((line_no < IMG_PIXELS) && !$feof(fh)) begin
            $fgets(line, fh);
            
            // Skip empty lines
			if (line.len() == 0) continue;

            // Parse line to decimal value
            if ($sscanf(line, "%d", golden_value) != 1) begin
                `uvm_warning("SCOREBOARD", $sformatf("Could not parse Gx golden line %0d: %s", line_no+1, line))
                continue;
            end

            // Read 16-bit pixel from memory (little-endian)
            addr = base_address + GX_OFFSET + line_no * 2;
            observed_value = {mem.read_byte(addr+1), mem.read_byte(addr)};

            // Compare values
            if (observed_value !== shortint'(golden_value)) begin
                gx_mismatches++;
                if (reported < MAX_REPORTED_MISMATCHES) begin
                    int row, col;
                    row = line_no / IMG_WIDTH;
                    col = line_no % IMG_WIDTH;
                    `uvm_error("SCOREBOARD", $sformatf("Gx mismatch at pixel %0d (row %0d, col %0d): expected %0d, got %0d",
                               line_no, row, col, golden_value, observed_value))
                    reported++;
                end
            end

            line_no++;
        end

        $fclose(fh);

        if (line_no != IMG_PIXELS) begin
            `uvm_error("SCOREBOARD", $sformatf("Gx golden file had only %0d pixels, expected %0d",
                       line_no, IMG_PIXELS))
        end

        `uvm_info("SCOREBOARD", $sformatf("Gx check done: %0d mismatches", gx_mismatches), UVM_LOW)
    endfunction

    // Compare Gy region with golden file
    function void check_gy();
        int fh;
        string line;
        int line_no;
        int golden_value;
        shortint observed_value;
        longint unsigned addr;
        int reported;

        `uvm_info("SCOREBOARD", "Checking Gy region...", UVM_LOW)

        fh = $fopen(golden_gy_path, "r");
        if (fh == 0) begin
            `uvm_error("SCOREBOARD", $sformatf("Could not open golden file: %s", golden_gy_path))
            return;
        end

        line_no  = 0;
        reported = 0;

        while ((line_no < IMG_PIXELS) && !$feof(fh)) begin
            $fgets(line, fh);
            
            if (line.len() == 0) continue;

            if ($sscanf(line, "%d", golden_value) != 1) begin
                `uvm_warning("SCOREBOARD", $sformatf("Could not parse Gy golden line %0d: %s", line_no+1, line))
                continue;
            end

            addr = base_address + GY_OFFSET + line_no * 2;
            observed_value = {mem.read_byte(addr+1), mem.read_byte(addr)};

            if (observed_value !== shortint'(golden_value)) begin
                gy_mismatches++;
                if (reported < MAX_REPORTED_MISMATCHES) begin
                    int row, col;
                    row = line_no / IMG_WIDTH;
                    col = line_no % IMG_WIDTH;
                    `uvm_error("SCOREBOARD", $sformatf("Gy mismatch at pixel %0d (row %0d, col %0d): expected %0d, got %0d",
                               line_no, row, col, golden_value, observed_value))
                    reported++;
                end
            end

            line_no++;
        end

        $fclose(fh);

        `uvm_info("SCOREBOARD", $sformatf("Gy check done: %0d mismatches", gy_mismatches), UVM_LOW)
    endfunction

    // Check that zero region is all zeros
    function void check_zero_region();
        int reported;
        `uvm_info("SCOREBOARD", "Checking zero region...", UVM_LOW)

        reported = 0;
        for (int i = 0; i < ZERO_BYTES; i++) begin
            byte unsigned b = mem.read_byte(base_address + ZERO_OFFSET + i);
            if (b !== 8'h00) begin
                zero_violations++;
                if (reported < MAX_REPORTED_MISMATCHES) begin
                    `uvm_error("SCOREBOARD", $sformatf("Zero region violation at offset %0d (addr 0x%0h): expected 0, got 0x%02h",
                               i, base_address + ZERO_OFFSET + i, b))
                    reported++;
                end
            end
        end

        `uvm_info("SCOREBOARD", $sformatf("Zero region check done: %0d violations", zero_violations), UVM_LOW)
    endfunction

    // Print final summary
    function void report_summary();
        int total_errors;
        total_errors = gx_mismatches + gy_mismatches + zero_violations;

        `uvm_info("SCOREBOARD", "===== Scoreboard Summary =====", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Gx mismatches:          %0d / %0d pixels", gx_mismatches, IMG_PIXELS), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Gy mismatches:          %0d / %0d pixels", gy_mismatches, IMG_PIXELS), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Zero region violations: %0d / %0d bytes", zero_violations, ZERO_BYTES), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total errors: %0d", total_errors), UVM_LOW)

        if (total_errors == 0)
            `uvm_info("SCOREBOARD", "----- TEST PASSED -----", UVM_LOW)
        else
            `uvm_info("SCOREBOARD", "----- TEST FAILED -----", UVM_LOW)
    endfunction

endclass

`endif