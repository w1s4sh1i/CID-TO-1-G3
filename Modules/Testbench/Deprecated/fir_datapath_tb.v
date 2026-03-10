/*
TODO

- [ ] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
*/
`timescale 1 ns / 1 ps

// [ ] Importar configurações e arquivos
// [x] Change $stop by $finish;

module fir_datapath_tb;

    // ==========================
    // Parâmetros
    // ==========================
    parameter K  = 4;
    parameter DW = 8;
    parameter CW = 8;

    localparam PW = DW + CW;
    localparam AW = PW + $clog2(K) + 1;

    // ==========================
    // Sinais
    // ==========================
    reg clk;
    reg rst;

    reg shift_en;
    reg mac_en;
    reg acc_clear;

    reg signed [DW-1:0] x_in;
    reg [$clog2(K)-1:0] tap_index;

    wire signed [AW-1:0] y_out;

    // ==========================
    // Instância do DUT
    // ==========================
    fir_datapath #(K, DW, CW) DUT (
        .clk(clk),
        .rst(rst),
        .shift_en(shift_en),
        .mac_en(mac_en),
        .acc_clear(acc_clear),
        .x_in(x_in),
        .tap_index(tap_index),
        .y_out(y_out)
    );

    // ==========================
    // Clock
    // ==========================
    always #5 clk = ~clk;

	 // - [X] Adicionar um dump e reconfigurar 
	initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-controll.vcd"); 
		$dumpvars(0, fir_control_tb); 

		// Editar
		$display("|TIME | |"); // formatar saída vísível no terminal
		$monitor("|%0t | |", 
			  $time, 
		); 
	end
	
	
    // ==========================
    // Modelo de referência
    // ==========================
    reg signed [DW-1:0] x_ref [0:K-1];
    reg signed [CW-1:0] coeff_ref [0:K-1];

    integer i, n;
    reg signed [AW-1:0] y_expected;

    initial begin
        $readmemh("coeffs.mem", coeff_ref); /// ???
    end

    // ==========================
    // Teste automático
    // ==========================
    initial begin

        clk = 0;
        rst = 1;
        shift_en = 0;
        mac_en = 0;
        acc_clear = 0;
        x_in = 0;
        tap_index = 0;

        // Reset
        #20;
        rst = 0;

        // Inicializa modelo referência
        for (i = 0; i < K; i = i + 1)
            x_ref[i] = 0;

        // ==========================
        // Loop de testes
        // ==========================
        for (n = 0; n < 10; n = n + 1) begin

            // Gera amostra aleatória
            x_in = $random % 20;

            // Shift no modelo referência
            for (i = K-1; i > 0; i = i - 1)
                x_ref[i] = x_ref[i-1];
            x_ref[0] = x_in;

            // Envia para DUT
            shift_en = 1;
            #10;
            shift_en = 0;

            // Limpa acumulador
            acc_clear = 1;
            #10;
            acc_clear = 0;

            // Executa MAC sequencial
            for (i = 0; i < K; i = i + 1) begin
                tap_index = i;
                mac_en = 1;
                #10;
            end

            mac_en = 0;

            // Calcula resultado esperado
            y_expected = 0;
            for (i = 0; i < K; i = i + 1)
                y_expected = y_expected + x_ref[i] * coeff_ref[i];

            #10;

            // Comparação automática
            if (y_out !== y_expected) begin
                $display("❌ ERRO na amostra %0d", n);
                $display("Esperado = %0d | Obtido = %0d", y_expected, y_out);
                $fatal;
            end
            else begin
                $display("✅ OK amostra %0d | Resultado = %0d", n, y_out);
            end

        end

        $display("=================================");
        $display("🎉 TESTE FINALIZADO COM SUCESSO");
        $display("=================================");

        $finish;
    end

endmodule

/*******************************************************
Testbench valida:
* Shift register
* Seleção do tap
* Multiplicador
* Acumulador
* Lógica de limpeza
* Soma completa do FIR
********************************************************/
