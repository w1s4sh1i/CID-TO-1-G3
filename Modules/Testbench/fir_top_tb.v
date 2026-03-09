/*

testbench incompleta ainda, mas criei ela para ter um primeiro teste de todo o projeto,
usei o testbench q está no deprecated como base para passar pelo datapath

no momento ela está recebendo X no y_out,
preciso verificar se o erro está na no fir_top com alguém do design, porém só de
achar esse possivel problema já vale a testbench

mas para o primeiro teste, está inicializando a máquina de estado e o datapath

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
    			DELAY = 5;
    
    reg clk, rst, start;
    reg signed [DW-1:0] x_in;
    wire data_valid;
    wire [2:0] tap_index;
    wire signed [DW+CW+$clog2(K):0] y_out;

    integer i, errors, n;

    reg signed [DW-1:0] x_ref [0:K-1];
    reg signed [CW-1:0] coeff_ref [0:K-1];

    reg signed [AW-1:0] y_expected;

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
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-top.vcd"); 
		$dumpvars(0, fir_top_tb); 

		// Editar
		$display("|TIME |RESET |START |X-IN |DATA-VALID |TAP-INDEX |Y-OUT |"); // formatar saída vísível no terminal
		$monitor("|%0t |%b |%b |%b |%b |%b |%b |", 
			$time, rst, start, x_in, data_valid, tap_index, y_out
		); 
	end

    initial begin
    	
    	clk = 1'b0;
        errors = 0;
        rst = 1'b1;
        start = 1'b0;

        $display("Starting fir_top Self-Checking Testbench");

        // teste de reset, ao mudar de 0 para 1, não deve ter resultado na saida y_out
        $display("\n--- Teste 1: inicialização com RESET ---");

        #(DELAY*2); 
        rst = 1'b0;

        #(DELAY*2);
        rst = 1'b1;

        if (y_out || data_valid) begin
            $display("ERROR: Saídas incorretas após o RESET");
            errors = errors + 1;
        end
        else
            $display("OK: RESET funcionando");


        // teste de funcionamento genérico, entro com valores e comparo com a saída esperada do datapath
        $display("\n--- Teste 2: Teste de cálculo com entradas aleatórias ---");
        #(DELAY*4);
        rst = 1'b0;

        // Inicializa modelo referência
        for (i = 0; i < K; i = i + 1)
            x_ref[i] = 0;

        // Inicializa coeff para teste
        for (i = 0; i < K; i = i + 1)
            coeff_ref[i] = 1;

        // Loop de testes
        for (n = 0; n < 10; n = n + 1) begin

            // Gera amostra aleatória
            x_in = $random % 20;

            // Shift no modelo referência
            for (i = K-1; i > 0; i = i - 1)
                x_ref[i] = x_ref[i-1];
            x_ref[0] = x_in;

            // Calcula resultado esperado
            y_expected = 0;
            for (i = 0; i < K; i = i + 1)
                y_expected = y_expected + x_ref[i] * coeff_ref[i];

            #(DELAY*2);

            // pulso para incializar a maquina de estado na descida do clock para evitar conflito com com a maquina de estado
            @(posedge  clk);
            start = 1'b1;
            @(posedge  clk);
            start = 1'b0;

            // aguarda a maquina de estado sinalizar o processamento
            while (data_valid != 1'b1) begin
                @(posedge  clk);
            end

            // Comparação automática
            if (y_out !== y_expected) begin
                $display("ERRO na amostra %0d", n);
                $display("Esperado = %0d | Obtido = %0d", y_expected, y_out);
                errors = errors + 1;
            end
            else begin
                $display("OK amostra %0d | Resultado = %0d", n, y_out);
            end

        end

        if (errors == 0)
            $display("\n==== TEST PASSED ====\n");
        else
            $display("\n==== TEST FAILED (%0d errors) ====\n", errors);

        $finish;
    end


endmodule