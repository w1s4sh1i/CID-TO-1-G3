/*
TODO

- [ ] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
*/
`timescale 1 ns / 1 ps

// [ ] Importar configurações 
// [x] Change $stop by $finish;


module FIR_datapath_tb;

    parameter K  = 8;
    parameter DW = 8;
    parameter CW = 8;

    localparam AW = DW + CW + $clog2(K) + 1;

    reg clk, rst;
    reg shift_en, mac_en, acc_clear, start, tap_en;
    reg signed [DW-1:0] x_in;
    wire signed [DW+CW+$clog2(K):0] y_out;

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

    // Modelo referÃªncia para o scoreboard
    reg signed [DW-1:0] samples [0:K-1];
    reg signed [CW-1:0] coeffs  [0:K-1];
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
        clk = 0;
        rst = 1;

        shift_en = 0;
        mac_en = 0;
        acc_clear = 0;
        start = 0;
        tap_en = 0;
        x_in = 0;

        #20 rst = 0;

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
