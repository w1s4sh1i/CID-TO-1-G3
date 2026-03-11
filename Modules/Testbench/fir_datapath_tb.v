`timescale 1ns/1ps

module FIR_datapath_tb;

    parameter K  = 8;
    parameter DW = 8;
    parameter CW = 8;

    localparam AW = DW + CW + $clog2(K) + 1;

    reg clk, rst;
    reg shift_en, mac_en, acc_clear, start, tap_en;
    reg signed [DW-1:0] x_in;
    wire signed [DW+CW+$clog2(K):0] y_out;
    integer pass_count = 0;
    integer fail_count = 0;

    FIR_datapath #(
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

    reg signed [DW-1:0] samples [0:K-1];
    reg signed [CW-1:0] coeffs  [0:K-1];
    reg signed [AW-1:0] expected;

    integer i;

    initial begin
        $readmemh("coeffs.mem", coeffs);
        for (i = 0; i < K; i = i + 1)
            samples[i] = 0;
    end

    // Dump e monitor geral
    initial begin
        $dumpfile("CIDI-SD192-fir-datapath.vcd"); 
        $dumpvars(0, FIR_datapath_tb); 

        $display("| TIME(ns) | x_in | y_out | expected |");
        $monitor("| %0t      | %0d   | %0d   | %0d  |", 
                  $time, x_in, y_out, expected);
    end

    reg legenda_impressa = 0;

    // Scoreboard 
    task automatic scoreboard_calc;
        integer j;
        reg signed [AW-1:0] partial;
        reg signed [DW+CW-1:0] product;
        begin
        expected = 0;

        if (!legenda_impressa) begin
            $display("TAP -> posição no shift register)");
            $display("SAMPLE -> valor da amostra");
            $display("COEFF -> coeficiente do filtro");
            $display("MULT -> SAMPLE * COEFF");
            $display("SOMA -> soma acumulada");
            legenda_impressa = 1;
        end
            $display(" TAP | SAMPLE | COEFF |   MULT   | SOMA PARCIAL ");
            $display("-------------------------------------------------------------");
            for (j = 0; j < K; j = j + 1) begin
                product = samples[j] * coeffs[j];
                partial = expected + product;
                $display(" %3d | %6d | %5d | %7d | %12d ",
                         j, samples[j], coeffs[j], product, partial);
                expected = partial;
            end
            $display("-------------------------------------------------------------");
            $display("Resultado esperado = %0d", expected);
        end
    endtask

// Driver
task automatic driver(input signed [DW-1:0] sample);
    begin
        
        for (i = K-1; i > 0; i = i - 1)
        samples[i] = samples[i-1];
        samples[0] = sample;

        
        scoreboard_calc();
        
        @(posedge clk);
        shift_en  = 1;        
        acc_clear = 1;        
        start     = 1;        
        x_in      = sample;

        
        @(posedge clk);
        shift_en  = 0;
        acc_clear = 0;
        start     = 0;
        
        for (i = 0; i < K; i = i + 1) begin
            @(posedge clk);
            mac_en = 1;
            tap_en = 1;
        end
        
        @(posedge clk);
        mac_en = 0;
        tap_en = 0;
    end
endtask

    task automatic monitor;
        begin
            @(posedge clk);
            if (y_out !== expected) begin
                $display("Erro -> esperado=%0d obtido=%0d", expected, y_out);
                fail_count = fail_count + 1;
            end 
            else begin
                $display("Resultado ok");
                pass_count = pass_count + 1;
            end
        end
    endtask


// Send: aplica uma amostra completa ao DUT - chama o driver para inserir a amostra - chama o monitor para verificar o resultado
    task automatic send(input signed [DW-1:0] sample);
        begin
            driver(sample);

            monitor();
        end
    endtask

    // Casos de testes
    initial begin
        clk = 0;
        rst = 1;
        shift_en = 0;
        mac_en = 0;
        acc_clear = 0;
        start = 0;
        tap_en = 0;
        x_in = 0;

        #20 rst = 0;

        $display("--- Teste com impulsos unitarios ---");
        send(1);
        repeat(K) send(0);

        $display("--- Teste com uma sequencia crescente ---");
        send(1);
        send(2);
        send(3);
        send(4);

        $display("--- Teste com números negativos ---");
        send(-1);
        send(-2);
        send(-3);
        send(-4);

        $display("--- Teste sem habilitar shift ---");
        @(posedge clk);
        shift_en = 0;
        x_in = 5;   @(posedge clk);
        x_in = 10;  @(posedge clk);
        x_in = -7;  @(posedge clk);

        @(posedge clk);
        monitor();


        $display("--- Teste com valores grandes ---");
        send(127);   
        send(-128);  

        $display("--- Teste para overflow ---");
        repeat(10) send(100);

        $display("--- Teste com valores aleatorios ---");
        repeat(20) begin
        send($random);
        end

        #100;

        $display("Resumo final dos testes: ");
        $display("Passou: %0d", pass_count);
        $display("Falhou: %0d", fail_count);
        $finish;
    end

endmodule
