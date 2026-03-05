/*
  ACCUMULATOR MUX (MUX DO ACUMULADOR)
  Controla o valor carregado no acumulador do MAC
  Permite limpar ou acumular durante o processamento
*/

module acc_mux #(  
    parameter ACC_WIDTH = 19 // Largura do acumulador, deve incluir bits de guarda para evitar overflow (exigência do projeto)
)(
	input  sel_acc,                       	// Sinal de controle vindo da FSM, 0 → limpar acumulador, 1 → acumular normalmente
    input  signed [ACC_WIDTH-1 : 0] sum_in, // Entrada do somador (ACC + produto), representa o novo valor acumulado
    output signed [ACC_WIDTH-1 : 0] acc_in  // Valor que será carregado no registrador do acumulador
);
    // Operação combinacional simples, Se sel_acc for 1 → passa a soma / Se sel_acc for 0 → força zero (limpeza)
    assign acc_in = (sel_acc) ? sum_in : {ACC_WIDTH{1'b0}};

endmodule

// [ ] Enviar código para o testbench;

/*

// TESTBENCH

	`timescale 1 ns / 1 ps

	module acc_mux_tb;

	localparam  ACC_WIDTH = 19, DELAY = 10; 
	
	reg  sel_acc;
	reg  signed [ACC_WIDTH-1:0] sum_in;
	wire signed [ACC_WIDTH-1:0] acc_in;

	acc_mux #(.ACC_WIDTH(ACC_WIDTH)) dut (
		.sum_in(sum_in),
		.sel_acc(sel_acc),
		.acc_in(acc_in)
	);

	initial begin
		// Descrever os testes realizados
		sum_in  = 19'sd123;
		sel_acc = 1'b0;
		#DELAY;

		sel_acc = 1'b1;
		#DELAY;

		sum_in = 19'sd456;
		#DELAY;

		sel_acc = 1'b0;
		#DELAY;

		$finish;
	end

endmodule
*/
