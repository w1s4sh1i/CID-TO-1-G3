`timescale 1ns/1ps

module FIR_datapath_tb;

    // =====================================================
    // Parâmetros
    // =====================================================

    parameter K  = 8;
    parameter DW = 8;
    parameter CW = 8;

    localparam AW = DW + CW + $clog2(K) + 1;

    // =====================================================
    // Sinais
    // =====================================================

    reg clk;
    reg rst;

    reg shift_en;
    reg mac_en;
    reg acc_clear;
    reg start;
    reg tap_en;

    reg  signed [DW-1:0] x_in;
    wire signed [DW+CW+$clog2(K):0] y_out;

    // =====================================================
    // DUT
    // =====================================================

    FIR_datapath #(
        .K(K),
        .DW(DW),
        .CW(CW)
    ) uut (
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

    // =====================================================
    // Clock 100 MHz
    // =====================================================

    always #5 clk = ~clk;

    // =====================================================
    // Modelo de Referência (Scoreboard)
    // =====================================================

    reg signed [DW-1:0] samples [0:K-1];
    reg signed [CW-1:0] coeffs  [0:K-1];

    integer i;
    reg signed [AW-1:0] expected;

    // Lê os mesmos coeficientes usados na ROM
    initial begin
        $readmemh("coeffs.mem", coeffs);
    end

    // Inicializa shift model
    initial begin
        for (i = 0; i < K; i = i + 1)
            samples[i] = 0;
    end

    // Calcula saída esperada
    task compute_expected;
        begin
            expected = 0;
            for (i = 0; i < K; i = i + 1)
                expected = expected + samples[i] * coeffs[i];
        end
    endtask

    // =====================================================
    // Driver (envia amostra)
    // =====================================================

    task send_sample;
        input signed [DW-1:0] sample;
        begin

            // Atualiza modelo de referência
            for (i = K-1; i > 0; i = i - 1)
                samples[i] = samples[i-1];

            samples[0] = sample;

            compute_expected;

            // Fase SHIFT
            @(posedge clk);
            shift_en  = 1;
            acc_clear = 1;
            start     = 1;
            x_in      = sample;

            @(posedge clk);
            shift_en  = 0;
            acc_clear = 0;
            start     = 0;

            // Fase MAC (K ciclos)
            for (i = 0; i < K; i = i + 1) begin
                @(posedge clk);
                mac_en = 1;
                tap_en = 1;
            end

            @(posedge clk);
            mac_en = 0;
            tap_en = 0;

            // Espera y_out ser atualizado
            @(posedge clk);

            // Scoreboard
            if (y_out !== expected)
                $display("❌ ERRO: esperado=%0d obtido=%0d", expected, y_out);
            else
                $display("✅ OK: %0d", y_out);

        end
    endtask

    // =====================================================
    // Testes
    // =====================================================

    initial begin

        // Inicialização
        clk = 0;
        rst = 1;
        shift_en = 0;
        mac_en = 0;
        acc_clear = 0;
        start = 0;
        tap_en = 0;
        x_in = 0;

        #20 rst = 0;

        $display("\n==============================");
        $display(" TESTE 1 - IMPULSO UNITÁRIO ");
        $display("==============================\n");

        send_sample(1);
        repeat(K) send_sample(0);

        $display("\n==============================");
        $display(" TESTE 2 - SEQUÊNCIA CRESCENTE ");
        $display("==============================\n");

        send_sample(1);
        send_sample(2);
        send_sample(3);
        send_sample(4);

        $display("\n==============================");
        $display(" TESTE 3 - VALORES NEGATIVOS ");
        $display("==============================\n");

        send_sample(-1);
        send_sample(-2);
        send_sample(3);
        send_sample(-4);

        #100;
        $finish;
    end

endmodule
