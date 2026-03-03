/*
TODO

- [ ] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
*/
`timescale 1 ns / 1 ps

// [ ] Importar configurações e arquivos
// [x] Change $stop by $finish;

module tap_counter_tb;

  // Parâmetros
  parameter K = 8;
  parameter CLK_PERIOD = 10; // 100MHz

  // Sinais do Testbench
  reg clk;
  reg rst;
  reg start;
  reg enable;
  wire [$clog2(K)-1:0] tap_index;
  wire last_cycle;

  // Instância da Unidade Sob Teste (UUT)
  tap_counter #( .K(K) ) uut (.*);

  // Geração do Clock
  always #(CLK_PERIOD/2) clk = ~clk;

  // Procedimento de Teste
  initial begin
    // Inicialização
    clk = 0;
    rst = 1;
    start = 0;
    enable = 0;


    $display("------------------------------------------------");
    $display(" Time | start | enable | tap_index | last_cycle");
    $display("------------------------------------------------");
    $monitor(" %4t |   %b   |    %b   |     %d     |     %b", 
                $time,  start,   enable, tap_index, last_cycle);

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
