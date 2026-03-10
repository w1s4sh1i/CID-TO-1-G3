/*
TODO

- [X] Adicionar um dump e reconfigurar 
- [x] Change $stop by $finish;
- [ ] Especificar quais testes estão sendo realizados; 
- [ ] Adicionar clock por instância;  
- [ ] Importar configurações e arquivos

Descrição dos testes:
teste 1: ativo o RESET para verificar se a maquina de estado inicializa as saidas com 0, ou seja está parada
teste 2: ativo a maquina de estado com o sinal 0, para verificar se ela continua parada como deveria
teste 3: ativo a maquina de estado com o pulso de start, (mudo de 0 para 1 e para 0 de novo) e verifico os sinais de enable
         para validar se a maquina de estado está alternando corretamente entre os estados
teste 4: inicializo a maquina de estado com um pulso de start e espero ela chegar no estado de process, dentro dele
         disparo outro pulso de start e verifico se ativou o sinal de enable do primeiro estado durante um tempo de de
         10 clocks
*/

`timescale 1 ns / 1 ps

module fir_control_tb;

    localparam  INDICE_TAP = 2, 
                K = 8, 
                DELAY = 5;

    reg clk, rst, start;
    wire shift_en, acc_clear, mac_en, data_valid;
    wire [$clog2(K)-1:0] tap_index;

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
			  $time, rst, start, shift_en, acc_clear, mac_en, data_valid, tap_index
		); 
	end

    initial begin
    	
    	clk = 1'b0; 
 
    	// [ ] Especificar quais testes estão sendo realizados; 
        errors = 1'b0;
        rst = 1'b1;
        start = 1'b0;

        $display("Starting FIR_control Self-Checking Testbench");

        @(posedge clk);
        rst = 1'b0;

        $display("\n--- Teste 1: inicialização com RESET ---");
        @(posedge clk);
        if (shift_en || mac_en || acc_clear || data_valid) begin
            $display("ERROR: Saídas incorretas após reset");
            errors = errors + 1;
        end
        else
            $display("OK: reset funcionando");

        $display("\n--- Teste 2: IDDLE sem start ---");
        @(posedge clk);
        start = 1'b0;
        repeat(DELAY) @(posedge clk);
        @(posedge clk);
        if (shift_en || mac_en || acc_clear || data_valid) begin
            $display("ERROR: Saídas incorretas após START = 0");
            errors = errors + 1;
        end
        else
            $display("OK: sem start a FSM não gera comandos");

        $display("\n--- Teste 3: Inicia a máquina de estados com pulso de start ---");
        // muda duas vezes para gerar um pulso e inicializar a maquina de estado uma vez apenas
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        while (acc_clear != 1'b1)
            @(posedge clk);
        $display("OK: CAPTURE detectado");

        while (shift_en != 1'b1)
            @(posedge clk);
        $display("OK: SHIFT detectado");

        while (mac_en != 1'b1)
            @(posedge clk);

        i = 0;

        while (mac_en == 1'b1) begin

            if (tap_index !== i) begin
                $display("ERROR: tap_index esperado %0d obtido %0d", i, tap_index);
                errors = errors + 1;
            end

            @(posedge clk);

            i = i + 1;
        end

        if (i != K) begin
            $display("ERROR: PROCESS executou número errado de ciclos, esperado %0d obtido %0d", K, i);
            errors = errors + 1;
        end else
            $display("OK: PROCESS completo");

        while (data_valid != 1'b1)
            @(posedge clk);
        $display("OK: DONE detectado");

        $display("\n--- Teste 4: START durante o PROCESS ---");
        
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // esperar o PROCESS
        while (mac_en != 1'b1) begin
            @(posedge clk);
        end

        // outro start
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // trecho para verificar se ativou o acc_clear e aguardar alguns ciclos de clock
        i = 0;
        while (acc_clear != 1'b1 && i<DELAY*2) begin
            @(posedge clk);
            i = i + 1;
        end

        if (acc_clear==0)
            $display("OK: FSM não recomeçou");
        else
            $display("ERROR: FSM recomeçou com pulso de START durante o PROCESS");


        if (errors == 0)
            $display("\n==== TEST PASSED ====\n");
        else
            $display("\n==== TEST FAILED (%0d errors) ====\n", errors);

        $finish;
    end

endmodule