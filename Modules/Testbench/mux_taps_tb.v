/*
TODO

- [x] Change $stop by $finish;
- [ ] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
- [ ] Importar configurações e arquivos

*/
`timescale 1 ns / 1 ps

module mux_taps_tb;

    localparam	DATA_WIDTH	= 8,
    			NUM_TAPS	= 8,
    			DELAY		= 5;

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

    integer i, errors;

    reg signed [DATA_WIDTH-1:0] tap_mem [0:NUM_TAPS-1];
	
	// - [X] Adicionar um dump e reconfigurar 
	initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-mux_taps.vcd"); 
		$dumpvars(0, fir_top_tb); 

		// Editar
		$display("|TIME |RESET |START |X-IN |DATA-VALID |TAP-INDEX |Y-OUT |"); // formatar saída vísível no terminal
		$monitor("|%0t |%b |%b |%b |%b |%b |%b |", 
			$time, rst, start, x_in, data_valid, tap_index, y_out;
		); 
	end
		
	
    initial begin
		
		
		// [ ] Especificar quais testes estão sendo realizados; 
        $display("<< Starting mux_taps Self-Checking Testbench >>");

        errors = 0;

        $readmemb("../dataset-tests/test_mux_taps.txt", tap_mem); // Analisar funcionamento

        taps_in = 0;
        
        for (i = 0; i < NUM_TAPS; i = i + 1) begin
            taps_in[i*DATA_WIDTH +: DATA_WIDTH] = tap_mem[i];
        end

        // Testa todos os índices
        for (i = 0; i < NUM_TAPS; i = i + 1) begin
            tap_index = i;
            #DELAY; // sleep para estabilizar

            // compara a saida do mux com o resultado esperado que foi lido do txt
            if (data_out !== tap_mem[i]) begin
                $display("ERROR: index=%0d expected=%0d got=%0d", i, tap_mem[i], data_out);
                errors = errors + 1;
            end
            else begin
                $display("OK: index=%0d value=%0d", i, data_out);
            end
        end

        // Resultado final
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED with %0d errors", errors);

        $finish;
    end

endmodule
