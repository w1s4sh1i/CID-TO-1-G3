module shift_register_tb;

    // Parâmetros
    parameter DATA_WIDTH = 8;
    parameter NUM_TAPS = 8;

    // Sinais do Testbench
    reg clk;
    reg rst;
    reg shift_en;
    reg signed [DATA_WIDTH-1:0] data_in;
    wire signed [NUM_TAPS*DATA_WIDTH-1:0] taps_out;

    shift_register #(.DATA_WIDTH(DATA_WIDTH),.NUM_TAPS(NUM_TAPS)) uut (.*);

    // Geração do Clock (100MHz)
    always #5 clk = ~clk;

    // Procedimento de Teste
    initial begin
      // Inicialização
      clk = 0; rst = 1; shift_en = 0; data_in = 0;
      // Reset do sistema
      #20 rst = 0;        #10;

      $display("-----------------------------------------------------------------------------------------------");
      $display(" Time | shift_en | data_in |                             taps_out");
      $display("----------------------------------------------------------------------------------------------");
      $monitor("%5t |     %1b    |    %1d    | %b  ", $time, shift_en, data_in, taps_out);

      // Teste de Impulso Unitário
      #10 shift_en = 1; data_in = 1; 
        
      // Inserindo dados sequenciais
      repeat (NUM_TAPS + 2) begin
        @(posedge clk);
        shift_en = 1;
        data_in = 0; 
      end
      
      $finish;
    end
endmodule
