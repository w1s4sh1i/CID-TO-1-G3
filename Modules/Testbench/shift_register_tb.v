/*
TODO
- [x] Change $stop by $finish;
- [ ] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
- [ ] Importar configurações e arquivos
*/
`timescale 1 ns / 1 ps


module shift_register_tb;

    // Parâmetros
    localparam	DATA_WIDTH 	= 8,
    			NUM_TAPS 	= 8,
    			DELAY 		= 10;

    // Sinais do Testbench
    reg clk, rst, shift_en;
    reg signed [DATA_WIDTH-1:0] data_in;
    wire signed [NUM_TAPS*DATA_WIDTH-1:0] taps_out;

    shift_register #(
    	.DATA_WIDTH(DATA_WIDTH),
    	.NUM_TAPS(NUM_TAPS)
    ) uut (.*);  // Boas práticas: efetuar declarações (conexões)

    // Geração do Clock (100MHz)
    always #(DELAY/2) clk = ~clk;

 	// - [X] Adicionar um dump e reconfigurar 
	initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-shift_register.vcd"); 
		$dumpvars(0, shift_register_tb); 

		// Editar
		$display("|TIME |RESET |SHIFT-EN |DATA-IN |TAP-OUT |"); // formatar saída vísível no terminal
		$monitor("|%0t |%b |%b |%b |%b |", 
			  $time, rst, shift_en, data_in, taps_out;
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
      #(DELAY*2); 
      rst = 1'b0;         

      // Teste de Impulso Unitário
      #DELAY;
      shift_en = 1'b1; 
      data_in = 1; 
        
      // Inserindo dados sequenciais
      repeat (NUM_TAPS + 2) begin
        @(posedge clk);
        shift_en = 1'b1;
        data_in = 0; 
      end
      
      $finish;
    end
endmodule
