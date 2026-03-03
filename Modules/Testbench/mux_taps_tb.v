`timescale 1ns / 1ps

module mux_taps_tb;

    parameter DATA_WIDTH = 8;
    parameter NUM_TAPS   = 8;

    reg  [NUM_TAPS*DATA_WIDTH-1:0] taps_in;
    reg  [$clog2(NUM_TAPS)-1:0]    tap_index;

    wire signed [DATA_WIDTH-1:0]   data_out;

    mux_taps #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_TAPS(NUM_TAPS)
    ) UUT (
        .taps_in(taps_in),
        .tap_index(tap_index),
        .data_out(data_out)
    );

    integer i;
    integer errors;

    reg signed [DATA_WIDTH-1:0] tap_mem [0:NUM_TAPS-1];
    
    // Adicionar $monitor and dump; 

    initial begin

        $display("<< Starting mux_taps Self-Checking Testbench >>");

        errors = 0;

        $readmemb("../dataset-tests/test_mux_taps.txt", tap_mem);

        taps_in = 0;
        for (i = 0; i < NUM_TAPS; i = i + 1) begin
            taps_in[i*DATA_WIDTH +: DATA_WIDTH] = tap_mem[i];
        end

        // Testa todos os índices
        for (i = 0; i < NUM_TAPS; i = i + 1) begin
            tap_index = i;
            #5; // sleep para estabilizar

            // compara a saida do mux com o resultado esperado que foi lido do txt
            if (data_out !== tap_mem[i]) begin
                $display("ERROR: index=%0d expected=%0d got=%0d", i, tap_mem[i], data_out);
                errors = errors + 1;
            end
            else begin
                $display("OK: index=%0d value=%0d", i, data_out);
            end
        end

        // ----------------------------------------
        // Resultado final
        // ----------------------------------------
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED with %0d errors", errors);

        $stop;
    end

endmodule
