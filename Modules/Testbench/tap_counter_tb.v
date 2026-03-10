/*
TODO
- [x] Change $stop by $finish;
- [ ] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
- [ ] Importar configurações e arquivos
*/
`timescale 1 ns / 1 ps

module tap_counter_tb;

  // Parâmetros
  localparam	K = 8,
  				CLK_PERIOD = 10; // 100MHz

  // Sinais do Testbench
  reg clk, rst, start, enable;
  wire [$clog2(K)-1:0] tap_index;
  wire last_cycle;

  // Instância da Unidade Sob Teste (UUT)
  tap_counter #( .K(K) ) uut (.*); // Evitar declaração -> interligar

  // Geração do Clock
  always #(CLK_PERIOD/2) clk = ~clk;
  
   // - [X] Adicionar um dump e reconfigurar 
	initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-tap_counter.vcd"); 
		$dumpvars(0, tap_counter_tb); 

		// Editar
		$display("|TIME |RESET |START |ENABLE |TAP-INDEX |LAST-CYCLE |"); // formatar saída vísível no terminal
		$monitor("|%0t | |", 
			  $time, rst, start, enable, tap_index, last_cycle
		); 
	end 

	// Procedimento de Teste
	initial begin
		
		// Inicialização
		clk = 1'b0;
		rst = 1'b1;
		start = 1'b0;
		enable = 1'b0;

		// 1. Reset do Sistema
		#(CLK_PERIOD * 2);
		rst = 0;

		// 2. Iniciar Processamento
		@(posedge clk);
		start = 1;
		#(CLK_PERIOD);
		start = 0;
		enable = 1; // Habilita a contagem

		@(posedge clk);
			repeat (8) @(posedge clk);

		$finish;
	end

endmodule
