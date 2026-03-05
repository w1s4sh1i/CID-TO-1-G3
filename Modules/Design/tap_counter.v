/*
	TAP COUNTER (CONTADOR DE TAPS)
	Responsável por sequenciar o processamento do FIR
	Garante exatamente K ciclos por amostra de saída
*/

module tap_counter #(
    parameter K = 8
)(
    input	clk,
    input	rst,
    input 	start,
    input	enable,
    output reg  [$clog2(K)-1:0] tap_index, // Índice do tap atual (0 até K-1), Utilizado para endereçar a ROM e o Data Selector
    output last_cycle
);

    // Bloco sequencial sensível à borda de subida do clock ou ao reset
    always @(posedge clk or posedge rst) begin
        if (rst)             // Se o reset estiver ativo, o contador é zerado
            tap_index <= 0;
        else if (start)      // Se a FSM indicar início de um novo processamento, o contador também é reiniciado
            tap_index <= 0;
        else if (enable)     // Durante o estado de processamento, o contador avança a cada ciclo de clock
            tap_index <= tap_index + 1'b1;
    end

    assign last_cycle = (tap_index == K-1); // Indica à FSM que o último tap foi alcançado

endmodule

/*

TESTBENCH

 `timescale 1ns/1ps

 module tap_counter_tb;
	
     parameter K = 8;

     reg clk, rst, start, enable;
     wire [$clog2(K)-1:0] tap_index;
     wire last_cycle;

     always #5 clk = ~clk;

     tap_counter #(.K(K)) dut (
         .clk(clk),
         .rst(rst),
         .start(start),
         .enable(enable),
         .tap_index(tap_index),
         .last_cycle(last_cycle)
     );

     initial begin
     
     	// [ ] Definir características dos testes
         clk = 1'b0;
         rst = 1'b1;
         start = 1'b0;
         enable = 1'b0;

         #20 rst = 1'b0;

         @(posedge clk);
         start = 1'b1;
         enable = 1'b1;

         @(posedge clk);
         start = 1'b0;

         repeat (10) @(posedge clk);

         enable = 1'b0;
         #20 $finish;
     end

 endmodule
*/
