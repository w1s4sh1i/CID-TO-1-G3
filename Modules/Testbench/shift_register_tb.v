/*
TODO

- [ ] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
*/
`timescale 1 ns / 1 ps

// [ ] Importar configurações e arquivos
// [x] Change $stop by $finish;

module shift_register_tb;

    // Parâmetros
    localparam	DATA_WIDTH = 8,
    			NUM_TAPS = 8;

    // Sinais do Testbench
    reg clk;
    reg rst;
    reg shift_en;
    reg signed [DATA_WIDTH-1:0] data_in;
    wire signed [NUM_TAPS*DATA_WIDTH-1:0] taps_out;

// Implementação do $readmemh
reg [DATA_WIDTH-1:0] memoria  [0:7];
integer i=0;

integer k=0;

    shift_register #(.DATA_WIDTH(DATA_WIDTH),.NUM_TAPS(NUM_TAPS)) uut (.*); // Boas práticas: efetuar declarações (conexões)

    // Geração do Clock (100MHz)
    always #5 clk = ~clk;

 	// - [X] Adicionar um dump e reconfigurar 
	initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-controll.vcd"); 
		$dumpvars(0, shift_register_tb); 

		// Editar
		$display("|TIME | |"); // formatar saída vísível no terminal
		$monitor("|%0t | |", 
			  $time, 
		); 
	end
    
  // Procedimento de Teste
  initial begin
      
      // Inicialização
      clk = 1'b0; 
      rst = 1'b1; 
      shift_en = 1'b0; 
      data_in = 0;
      
      // Reset do sistema
      #20 
      rst = 1'b0;        
      
      // Carrega o arquivo na memória
      $display("------------------------------------");
      $display(" Leitura de coeffs.mem com $readmeh");
      $display("------------------------------------");
      $readmemh("coeffs.mem", memoria);
      for (i = 0; i < 8; i = i + 1) begin
          $display("%1d: %h", i, memoria[i]);
      end


      $display("----------------------------------");
      $display("   Programacao dos Coeficientes ");
      $display("----------------------------------");

    for (i=0; i<8; i=i+1) begin
      @(posedge clk); // sinal de clock passa de baixo (0) para alto (1)
      uut.reg_mem[i] <= memoria[i]; // Atribuição direta para simular a configuração dos coeficientes
    end


    for (i=0; i<8; i=i+1) begin
        $display("%1d: %h", i, uut.reg_mem[i] );
    end

      #10;
      
      // [ ] Reconfigurar no monitor; 
      $display("-----------------------------------------------------------------------------------------------");
      $display(" Time | shift | in |                             taps_out                             | k");
      $display("-----------------------------------------------------------------------------------------------");

      // Teste de Impulso Unitário
      #10 
      shift_en = 1'b1; 
      data_in = 1; 
      for (k= 0; k < 8; k = k + 1) begin

        $display("%6t |   %1b  |  %1d | %b | %1d | %h",
                  $time, shift_en, data_in, taps_out, k, taps_out[k  * DATA_WIDTH +: DATA_WIDTH]);

      end
      $display("-----------------------------------------------------------------------------------------------");


      shift_en = 1'b1;
      data_in = 0; 

      // Inserindo dados sequenciais
      repeat (NUM_TAPS + 2) begin
        @(posedge clk);

       for (k= 0; k < 8; k = k + 1) begin
        $display("%6t |   %1b  |  %1d | %b | %1d | %h",
                  $time, shift_en, data_in, taps_out, k, taps_out[k  * DATA_WIDTH +: DATA_WIDTH]);

        end
        $display("-----------------------------------------------------------------------------------------------");
      end
      
      $finish;
    end
endmodule
