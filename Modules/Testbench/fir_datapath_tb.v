/*
TODO
- [ ] Adicionar clock por instância;  
*/
`timescale 1 ns / 1 ps

// [ ] Importar configurações e arquivos
// [x] Change $stop by $finish;


module fir_datapath_tb;

	localparam	K  = 8,
				DW = 8,
				CW = 8;

	localparam AW = DW + CW + $clog2(K) + 1;

	reg clk, rst;
	reg shift_en, mac_en, acc_clear, start, tap_en;
	reg signed [DW-1:0] x_in;
	wire signed [DW+CW+$clog2(K):0] y_out;

	fir_datapath #(
		.K(K),
		.DW(DW),
		.CW(CW)
	) dut (
		.clk(clk),
		.rst(rst),
		.shift_en(shift_en),
		.mac_en(mac_en),
		.acc_clear(acc_clear),
		.start(start),
		.tap_en(tap_en),
		.x_in(x_in),
		.y_out(y_out)
	);

	always #5 clk = ~clk;
	
	// - [X] Adicionar um dump e reconfigurar 
	initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-fir-datapath.vcd"); 
		$dumpvars(0, fir_datapath_tb); 

		// Editar
		$display("|TIME | |"); // formatar saída vísível no terminal
		$monitor("|%0t | |", 
			  $time, 
		); 
	end


	// Modelo referência para o scoreboard
	reg signed [DW-1:0] samples [0 : K-1];
	reg signed [CW-1:0] coeffs  [0 : K-1];
	reg signed [AW-1:0] expected;

	integer i;

	initial begin
		$readmemh("coeffs.mem", coeffs); // ???
		for (i = 0; i < K; i = i + 1)
		    samples[i] = 0;
	end

	// Scoreboard
	task automatic scoreboard_calc;

		integer j;
		reg signed [AW-1:0] partial;
		reg signed [DW+CW-1:0] product;

		begin
		expected = 0;

		$display("Valores encontrados:");

		for (j = 0; j < K; j = j + 1) begin
		    product = samples[j] * coeffs[j];
		    partial = expected + product;

		    $display("tap=%0d | sample=%0d | coeff=%0d | prod=%0d | soma_parcial=%0d",
		             j, samples[j], coeffs[j], product, partial);

		    expected = partial;
		end

		$display("Resultado esperado = %0d", expected);
	end

	endtask

	// Driver
	task automatic driver(input signed [DW-1:0] sample);
		begin
		    // shift modelo
		    for (i = K-1; i > 0; i = i - 1)
		        samples[i] = samples[i-1];

		    samples[0] = sample;

		    scoreboard_calc();

		    // inicia DUT
		    @(posedge clk);
		    shift_en  = 1'b1;
		    acc_clear = 1'b1;
		    start     = 1'b1;
		    x_in      = sample;

		    @(posedge clk);
		    shift_en  = 1'b0;
		    acc_clear = 1'b0;
		    start     = 1'b0;

		    for (i = 0; i < K; i = i + 1) begin
		        @(posedge clk);
		        mac_en = 1'b1;
		        tap_en = 1'b1;
		    end

		    @(posedge clk);
		    mac_en = 1'b0;
		    tap_en = 1'b0;
		end
	endtask

	// Monitor
	task automatic monitor;
		begin
		    @(posedge clk);

		    if (y_out !== expected)
		       $display("Erro -> %0d  foi obtido=%0d", expected, y_out);
		    else
		       $display("Resultado OK");
		end
	endtask

	// Sequence
	task automatic send(input signed [DW-1:0] sample);
		begin
		    driver(sample);
		    monitor();
		end
	endtask

	// Testes
	initial begin
	
		// [ ] Especificar quais testes estão sendo realizados; 
		clk = 1'b0;
		rst = 1'b1;

		shift_en = 1'b0;
		mac_en = 1'b0;
		acc_clear = 1'b0;
		start = 1'b0;
		tap_en = 1'b0;
		x_in = 1'b0;

		#20 rst = 1'b0;

		// impulso
		send(1);
		repeat(K) send(0);

		// crescente
		send(1);
		send(2);
		send(3);
		send(4);

		// negativos
		send(-1);
		send(-2);
		send(3);
		send(-4);

		#100;
		$finish;
	end

endmodule
