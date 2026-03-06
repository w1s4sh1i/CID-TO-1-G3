/*
TODO
- [ ] Adicionar clock por instância
*/

`timescale 1 ns / 1 ps

module fir_datapath_tb;

    localparam K  = 8,
               DW = 8,
               CW = 8;

    localparam AW = DW + CW + $clog2(K) + 1;

    reg clk, rst;
    reg shift_en, mac_en, acc_clear;
    reg signed [DW-1:0] x_in;
    reg [$clog2(K)-1:0] tap_index;

    wire signed [DW+CW+$clog2(K):0] y_out;

    // =====================================================
    // DUT
    // =====================================================

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
        .tap_index(tap_index),
        .x_in(x_in),
        .y_out(y_out)
    );

    // =====================================================
    // CLOCK
    // =====================================================

    always #5 clk = ~clk;

    // =====================================================
    // VCD / Monitor
    // =====================================================

    initial begin
        
        $dumpfile("CIDI-SD192-fir-datapath.vcd");
        $dumpvars(0, fir_datapath_tb);

        $display("|TIME | y_out | expected |");
        $monitor("|%0t | %0d | %0d |", 
            $time, y_out, expected);
    end

    // =====================================================
    // Modelo referência (scoreboard)
    // =====================================================

    reg signed [DW-1:0] samples [0:K-1];
    reg signed [CW-1:0] coeffs  [0:K-1];
    reg signed [AW-1:0] expected;

    integer i;

    initial begin
        $readmemh("coeffs.mem", coeffs);

        for (i = 0; i < K; i = i + 1)
            samples[i] = 0;
    end

    // =====================================================
    // SCOREBOARD
    // =====================================================

    task automatic scoreboard_calc;

        integer j;
        reg signed [AW-1:0] partial;
        reg signed [DW+CW-1:0] product;

        begin

            expected = 0;

            $display("\n--- SCOREBOARD ---");

            for (j = 0; j < K; j = j + 1) begin

                product = samples[j] * coeffs[j];
                partial = expected + product;

                $display("tap=%0d | sample=%0d | coeff=%0d | prod=%0d | soma=%0d",
                    j, samples[j], coeffs[j], product, partial);

                expected = partial;

            end

            $display("Resultado esperado = %0d\n", expected);

        end

    endtask


    // =====================================================
    // DRIVER
    // =====================================================

    task automatic driver(input signed [DW-1:0] sample);
    begin

        // modelo de shift
        for (i = K-1; i > 0; i = i - 1)
            samples[i] = samples[i-1];

        samples[0] = sample;

        scoreboard_calc();

        // CAPTURE
        @(posedge clk);
        shift_en  = 1'b1;
        acc_clear = 1'b1;
        x_in      = sample;

        @(posedge clk);
        shift_en  = 1'b0;
        acc_clear = 1'b0;

        // PROCESS (itera pelos taps)
        for (i = 0; i < K; i = i + 1) begin
            @(posedge clk);
            mac_en    = 1'b1;
            tap_index = i;
        end

        @(posedge clk);
        mac_en    = 1'b0;
        tap_index = 0;

    end
    endtask


    // =====================================================
    // MONITOR
    // =====================================================

    task automatic monitor;
    begin

        @(posedge clk);

        if (y_out !== expected)
            $display("ERRO -> esperado=%0d obtido=%0d", expected, y_out);
        else
            $display("RESULTADO OK -> %0d", y_out);

    end
    endtask


    // =====================================================
    // SEQUENCE
    // =====================================================

    task automatic send(input signed [DW-1:0] sample);
    begin
        driver(sample);
        monitor();
    end
    endtask


    // =====================================================
    // TESTES
    // =====================================================

    initial begin

        clk = 0;
        rst = 1;

        shift_en  = 0;
        mac_en    = 0;
        acc_clear = 0;
        tap_index = 0;
        x_in      = 0;

        #20 rst = 0;

        // impulso
        send(1);
        // repeat(K) send(0);

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

        // mistura
        send(0);
        send(2);
        send(3);

        #100;
        $finish;

    end

endmodule