`ifndef MEMORY_MODEL_SV
`define MEMORY_MODEL_SV

class memory_model extends uvm_object;

    `uvm_object_utils(memory_model)

    // Associative array, longint = 8 bytes
    protected byte unsigned mem [longint unsigned];

    // Default value returned for addresses that are not initialised
    byte unsigned default_value = 8'h00;

    function new(string name = "memory_model");
        super.new(name);
    endfunction

    // One byte read
    function byte unsigned read_byte(longint unsigned addr);
        if (mem.exists(addr))
            return mem[addr];
        else
            return default_value;
    endfunction

    // One byte write
    function void write_byte(longint unsigned addr, byte unsigned data);
        mem[addr] = data;
    endfunction

    // 4-byte read (little-endian)
    function bit [31:0] read_word(longint unsigned addr);
        bit [31:0] result;
        result[ 7: 0] = read_byte(addr + 0);
        result[15: 8] = read_byte(addr + 1);
        result[23:16] = read_byte(addr + 2);
        result[31:24] = read_byte(addr + 3);
        return result;
    endfunction

    // 32-bit word write
    function void write_word(longint unsigned addr, bit [31:0] data);
        write_byte(addr + 0, data[ 7: 0]);
        write_byte(addr + 1, data[15: 8]);
        write_byte(addr + 2, data[23:16]);
        write_byte(addr + 3, data[31:24]);
    endfunction

    // Block read - reads N bytes starting at addr
    function void read_block(longint unsigned addr, int length, ref byte unsigned data []);
        data = new[length];
        for (int i = 0; i < length; i++)
            data[i] = read_byte(addr + i);
    endfunction

    // Block write - writes N bytes starting at addr
    function void write_block(longint unsigned addr, input byte unsigned data []);
        foreach (data[i])
            write_byte(addr + i, data[i]);
    endfunction

    // Check to see how many addresses were written to
    function int unsigned size();
        return mem.num();
    endfunction

endclass : memory_model

`endif