/*

teste 1: testa o comportamento do fir com o reset ativado
teset 2: gera entradas de valores aleatórios para testar o calculo completo do fir, 
as entradas são valores gerados de forma aleatória, o coeff é carregado do mesmo arquivo usado
na ROM pq ambos precisam ser os mesmos valores para calcular o expected. Calculado a saída esperada,
envio o valor de entrada para o fir e comparo o valor na saída com o esperado.

TODO
- [x] Change $stop by $finish;
- [x] Adicionar um dump e reconfigurar exibição de informação 
- [ ] Adicionar clock por instância;  
- [ ] Importar configurações e arquivos
- [ ] Especificar quais testes estão sendo realizados; 

*/
`timescale 1 ns / 1 ps

module fir_top_tb;

    localparam 	K = 8,
                DW = 8,
                CW = 8,
                PW = DW + CW,
                AW = PW + $clog2(K) + 1,
                DELAY = 5,
                FILE_NAME  = "fir_coeffs.mem";
    
    reg clk, rst, start;
    reg signed [DW-1:0] x_in;
    wire data_valid;
    wire signed [DW+CW+$clog2(K):0] y_out;

    integer i, errors, n;

    reg signed [DW-1:0] x_ref [0:K-1];
    reg signed [CW-1:0] coeff_ref [0:K-1];

    reg signed [DW+CW+$clog2(K):0] y_expected;
    reg signed [DW+CW+$clog2(K):0] y_expected_d;

    fir_top #(
        .K(K),
        .DW(DW),
        .CW(CW)
    ) UUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .x_in(x_in),
        .y_out(y_out),
        .data_valid(data_valid)
    );    

	initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Inicializa modelo referência igual ao do fir
        $readmemh(FILE_NAME, coeff_ref);

        // apagar
        for (i=0; i<K; i=i+1)
            $display("coeff[%0d] = %0d", i, coeff_ref[i]);
    end
 
	initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-top.vcd"); 
		$dumpvars(0, fir_top_tb); 

		// Editar
		$display("|TIME |RESET  |START  |X-IN   |DATA-VALID |Y-OUT  |");
		$monitor("|%0t  |%b     |%b     |%b     |%b         |%b     |", 
			    $time, rst, start, x_in, data_valid, y_out
		); 
	end

    initial begin
        errors = 0;
        rst = 1'b1;
        start = 1'b0;

        $display("Starting fir_top Self-Checking Testbench");

        // teste de reset, ao mudar de 0 para 1, não deve ter resultado na saida y_out
        $display("\n--- Teste 1: inicialização com RESET ---");

        repeat(2) @(posedge clk);
        rst = 0;

        repeat(2) @(posedge clk);
        rst = 1;

        if (y_out || data_valid) begin
            $display("ERROR: Saídas incorretas após o RESET");
            errors = errors + 1;
        end
        else
            $display("OK: RESET funcionando");

        $display("\n--- Teste 2: Teste de cálculo com entradas aleatórias ---");
        rst = 1'b0;
        repeat(3) @(posedge clk);

        // Inicializa modelo referência
        for (i = 0; i < K; i = i + 1)
            x_ref[i] = 0;
        
        // preciso dessa variavel pq para o testbench teve uma latencia, fazendo o obtido ficar um passo para tras do esperado
         y_expected_d = 0;

        // Loop de testes
        for (n = 0; n < 10; n = n + 1) begin

            // gera amostra aleatória
            x_in = $random % 20;

            // inicializa referência
            for (i = K-1; i > 0; i = i - 1)
                x_ref[i] = x_ref[i-1];

            x_ref[0] = x_in;
            
            // calcula saída esperada
            y_expected = 0;
            for (i = 0; i < K; i = i + 1)
                y_expected = y_expected + x_ref[i] * coeff_ref[i];

            // pulso de start
            @(posedge clk);
            start = 1;

            // pulso para incializar a maquina de estado na descida do clock para evitar conflito com com a maquina de estado
            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            // aguarda a maquina de estado sinalizar o processamento
            while (data_valid != 1'b1) begin
                @(posedge clk);
            end
            
            // debugger
            $display("Entrada = %0d | Esperado = %0d | Obtido = %0d", x_in, y_expected, y_out);
            if (^y_out === 1'bx)
                $display("y_out contém X no tempo %0t", $time);

            if (y_out !== y_expected_d) begin
                $display("ERRO na amostra %0d", n);
                $display("Esperado = %0d | Obtido = %0d", y_expected_d, y_out);
                errors = errors + 1;
            end
            else begin
                $display("OK amostra %0d | Resultado = %0d", n, y_out);
            end

            // passo extra para tratar a latencia
            y_expected_d = y_expected;

        end

        if (errors == 0)
            $display("\n==== TEST PASSED ====\n");
        else
            $display("\n==== TEST FAILED (%0d errors) ====\n", errors);

        $finish;
    end


endmodule