/*
TODO

- [X] Adicionar um dump e reconfigurar 
- [x] Change $stop by $finish;
- [ ] Adicionar clock por instância;  
- [ ] Importar configurações e arquivos
*/

`timescale 1 ns / 1 ps

module fir_control_tb;

    localparam K = 3, DELAY = 5;

    reg clk, rst, start;
    wire shift_en, acc_clear, mac_en, data_valid;
    wire [2:0] tap_index;

    integer i, errors;

    fir_control #(
        .K(K) 
    ) UUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .shift_en(shift_en),
        .acc_clear(acc_clear),
        .mac_en(mac_en),
        .data_valid(data_valid),
        .tap_index(tap_index)
    );

	always #DELAY clk = ~clk;
    
    // - [X] Adicionar um dump e reconfigurar exibição de informação 
	initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-control.vcd"); 
		$dumpvars(0, fir_control_tb); 

		// Terminal view
		$display("|TIME |RESET |START |SHIFT-EN |ACC CLEAR |MAC-EN |DATA-VALID |TAP-INDEX |"); // formatar saída vísível no terminal
		$monitor("|%0t |%b |%b |%b |%b |%b |%b |%b |", 
			  $time, rst, start, shift_en, acc_clear, mac_en, data_valid, tap_index;
		); 
	end

    initial begin
    	
    	clk = 1'b0; 
 
    	// [ ] Especificar quais testes estão sendo realizados; 
        errors = 1'b0;
        rst = 1'b1;
        start = 1'b0;

        $display("Starting FIR_control Self-Checking Testbench");

        @(negedge clk);
        rst = 1'b0;

        @(negedge clk);
        if (shift_en || mac_en || acc_clear || data_valid) begin
            $display("ERROR: Saídas incorretas após reset");
            errors = errors + 1;
        end
        else
            $display("OK: reset funcionando");

        // muda duas vezes para gerar um pulso e inicializar a maquina de estado uma vez apenas
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        while (acc_clear != 1'b1)
            @(negedge clk);
        $display("OK: CAPTURE detectado");

        while (shift_en != 1'b1)
            @(negedge clk);
        $display("OK: SHIFT detectado");

		//
        i = 1;
        while (mac_en == 1'b1) begin

            @(negedge clk);
            if (tap_index !== i[2:0]) begin
                $display("ERROR: tap_index esperado %0d obtido %0d", i, tap_index);
                errors = errors + 1;
            end
            i = i + 1;
        end

        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        $display("TESTE: Start durante o process");
        repeat(5) @(posedge clk);
        if (acc_clear == 1'b1) begin
            $display("ERROR: O start inicializou a maquina de estado durante o process");
        end else begin
            $display("OK: O start não inicializou a maquina de estado durante o process");
        end

        if (i != K+1) begin
            $display("ERROR: PROCESS executou número errado de ciclos, esperado %0d obtido %0d", K+1, i);
            errors = errors + 1;
        end else
            $display("OK: PROCESS completo");

        while (data_valid != 1'b1)
            @(negedge clk);
        $display("OK: DONE detectado");

        if (errors == 0)
            $display("\n==== TEST PASSED ====\n");
        else
            $display("\n==== TEST FAILED (%0d errors) ====\n", errors);

        $finish;
    end

endmodule
