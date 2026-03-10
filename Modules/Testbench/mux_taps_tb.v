/*
TODO

- [x] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
- [ ] Importar configurações e arquivos

*/

/*
Descrição dos testes:

Inicializo a variavel de memória que alimentará a entrada do mux com valores gerados aleatóriamente

Teste 1: pego o valor na primeira entrada do mux e comparo para verificar se é o mesmo na saída
Teset 2: pego o valor na ultima entrada do mux e comparo para verificar se é o mesmo na saída
Teste 3: rodo um for para comparar todos os valores do mux com suas respectivas saídas

*/

`timescale 1 ns / 1 ps

module mux_taps_tb;

    localparam	DATA_WIDTH = 8,
    			      NUM_TAPS   = 8,
                DELAY      = 5;

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

    initial begin

        // inicializa o mux_taps
        for (i = 0; i < NUM_TAPS; i = i + 1) begin
            tap_mem[i] = $random;
        end

		// Specify the VCD file name
		$dumpfile("CIDI-SD192-mux_taps.vcd"); 
		$dumpvars(0, mux_taps_tb); 

		// Terminal view
		$display("|TIME |TAP-INDEX |TAPS-IN |TAPS-OUT |");
		$monitor("|%0t  |%b        |%b      |%b       |", 
			  $time, tap_index, taps_in[tap_index*DATA_WIDTH +: DATA_WIDTH], data_out
		); 
	end

    initial begin

        taps_in = 0;
        
        for (i = 0; i < NUM_TAPS; i = i + 1) begin
            taps_in[i*DATA_WIDTH +: DATA_WIDTH] = tap_mem[i];
        end

        $display("<< Starting mux_taps Self-Checking Testbench >>");

        errors = 0;

        $display("\n--- Teste 1 — Seleção do primeiro tap. ---");
        tap_index = 0;
        #DELAY;

        if (data_out !== tap_mem[tap_index]) begin
            $display("ERROR: Na primeira entrada, esperado=%0b obtido=%0b", tap_mem[tap_index], data_out);
            errors = errors + 1;
        end
        else begin
            $display("OK: Na primeira entrada, esperado=%0b obtido=%0b", tap_mem[0], data_out);
        end

        $display("\n--- Teste 2 — Seleção do último tap. ---");
        tap_index = NUM_TAPS-1;
        #DELAY;

        if (data_out !== tap_mem[NUM_TAPS-1]) begin
            $display("ERROR: Na ultima entrada, esperado=%0b obtido=%0b", tap_mem[tap_index], data_out);
            errors = errors + 1;
        end
        else begin
            $display("OK: Na ultima entrada, esperado=%0b obtido=%0b", tap_mem[tap_index], data_out);
        end


        $display("\n--- Teste 3: Varredura completa do MUX. ---");
  
        // Testa todos os índices
        for (i = 0; i < NUM_TAPS; i = i + 1) begin
            tap_index = i;
            #DELAY;  // deixa o mux atualizar

            if (data_out !== tap_mem[i]) begin
                $display("ERROR: Na entrada=%0d, esperado=%0b obtido=%0b", i, tap_mem[i], data_out);
                errors = errors + 1;
            end
            else begin
                $display("OK: Na entrada=%0d, esperado=%0b obtido=%0b", i, tap_mem[i], data_out);
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
