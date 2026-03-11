`timescale 1ns/1ps
module mac_tb;
 
    localparam  DW = 8,
                CW = 8,
                AW = DW + CW + 4,
                DELAY = 5;

    reg clk, rst;
    reg signed [DW-1:0] data_in;
    reg signed [CW-1:0] coeff_in;
    reg ps, l_acc;
    reg signed [AW-1:0] load_value;
    wire signed [AW-1:0] acc_out;

    integer i, errors, n;

    //DUT
    mac #(
        .DW(DW),
        .CW(CW),
        .AW(AW)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .coeff_in(coeff_in),
        .ps(ps),
        .l_acc(l_acc),
        .load_value(load_value),
        .acc_out(acc_out)
    );

  //Clock
  always #DELAY clk = ~clk;

  initial begin
		
		// Specify the VCD file name
		$dumpfile("CIDI-SD192-mac-tb.vcd"); 
		$dumpvars(0, mac_tb); 

		// Terminal view
		$display("|TIME |CLOCK  |RESET  | DATA_IN   |COEFF_IN   |PS |L_ACC  |LOAD_VALUE |ACC_OUT    |");
		$monitor("|%0t  |%b     |%b |%b |%b |%b |%b |%b |", 
			    $time, clk, rst, data_in, coeff_in, ps, l_acc, load_value, acc_out
		); 
	end

    initial begin
        clk = 1'b0;
        rst = 1;
        ps = 0;
        l_acc = 0;
        data_in = 0;
        coeff_in = 0;
        load_value = 0;

        repeat(2) @(posedge clk);
        $display("Starting FIR_control Self-Checking Testbench");
        @(posedge clk);

        $display("\n--- Teste 1: inicialização com RESET ---");

        if (acc_out!=0) begin
            $display("ERROR: Saída acc_out incorreta após o RESET");
            errors = errors + 1;
        end
        else
            $display("OK: RESET funcionando");
        
        @(posedge clk);
        rst = 0;

        // cabe uma validação de ps = 0 passando valores
        ps =1;

        @(posedge clk);

        $display("\n--- Teste 2: Teste deterministico ---");
        // data_in, coeff_in, ps, l_acc
        @(posedge clk);
        data_in = 0;
        coeff_in = 0; 
        ps = 0;
        l_acc = 1;

        @(posedge clk);
        data_in = 10;
        coeff_in = 3; 
        ps = 1;
        l_acc = 0;

        @(posedge clk);
        data_in = 5;
        coeff_in = -2; 
        ps = 1;
        l_acc = 0;

        @(posedge clk);
        data_in = 7;
        coeff_in = 1; 
        ps = 1;
        l_acc = 0;
    
        @(posedge clk);
        data_in = 0;
        coeff_in = 0; 
        ps = 0;
        l_acc = 1;

        $display("\n--- Teste 2: Teste borda ---");
        $display("\n--- Teste 2.1: Máximo positivo ---");
        @(posedge clk);
        data_in = 127;
        coeff_in = 127; 
        ps = 1;
        l_acc = 0;
        
        $display("\n--- Teste 2.2: Mínimo negativo ---");
        @(posedge clk);
        data_in = -128;
        coeff_in = -128; 
        ps = 1;
        l_acc = 0;

        $display("\n--- Teste 2.3: Zero multiplicado ---");
        @(posedge clk);
        data_in = 0;
        coeff_in = 50; 
        ps = 1;
        l_acc = 0;

        //Random test
        $display("\n--- Teste 3: Teste com valores aleatórios ---");
        for (i = 0; i < 20; i = i+1) begin
            if (i % 5 == 0) begin
                @(posedge clk);
                data_in = 0;
                coeff_in = 0; 
                ps = 0;
                l_acc = 1;
            end

            @(posedge clk);
            data_in = $random % 128;
            coeff_in = $random % 64; 
            ps = 1;
            l_acc = 0;
        end

        $finish;

    end



   /* 

  //Sequencer
  task automatic apply_mac(input signed [DW-1:0] data_in,
                           input signed [CW-1:0] coeff_in,
                           input ps,
                           input l_acc);
    begin
      data_in = data_in;
      coeff_in = coeff_in;
      ps = ps;
      l_acc = l_acc;
      @(posedge clk);
    end
  endtask

  //Scoreboard
  reg signed [AW-1:0] golden_acc;
  always @(posedge clk or posedge rst) begin
    if (rst) golden_acc <= 0;
    else if (l_acc) golden_acc <= 0;
    else if (ps) golden_acc <= golden_acc + data_in * coeff_in;
  end

  //Monitor
  always @(posedge clk) begin
    if (!rst) begin
      if (acc_out !== golden_acc) begin
        $display("ERRO: Esperado=%d, Obtido=%d, Tempo=%t",
                 golden_acc, acc_out, $time);
      end else begin
        $display("OK: acc_out=%d, Tempo=%t", acc_out, $time);
      end
    end
  end

  //Cobertura
  integer ps_count, lacc_count;
  always @(posedge clk) begin
    if (ps) ps_count = ps_count + 1;
    if (l_acc) lacc_count = lacc_count + 1;
  end

  //Sequence
  integer i;
  initial begin
    clk = 0;
    rst = 1;
    ps = 0;
    l_acc = 0;
    data_in = 0;
    coeff_in = 0;
    load_value = 0;
    ps_count = 0;
    lacc_count = 0;

    repeat(2) @(posedge clk);
    rst = 0;

    //Teste deterministico
    apply_mac(0, 0, 0, 1); 
    apply_mac(10, 3, 1, 0); 
    apply_mac(5, -2, 1, 0); 
    apply_mac(7, 1, 1, 0);  
    apply_mac(0, 0, 0, 1);  

    //Teste de borda
    apply_mac(127, 127, 1, 0);                   // maximo positivo
    apply_mac(-128, -128, 1, 0);                // minimo negativo
    apply_mac(0, 50, 1, 0);                    // zero multiplicado

    //Random test
    for (i = 0; i < 20; i = i+1) begin
      if (i % 5 == 0) apply_mac(0, 0, 0, 1); 
      apply_mac($random % 128, $random % 64, 1, 0);
    end

    //Relatorio de cobertura
    $display("Cobertura: ps=%0d vezes, l_acc=%0d vezes", ps_count, lacc_count);

    repeat(5) @(posedge clk);
    $finish;
  end
    */

endmodule