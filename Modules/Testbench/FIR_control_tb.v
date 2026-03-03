/*
TODO

- [ ] Adicionar um dump e reconfigurar 
- [ ] Adicionar clock por instância;  
*/
`timescale 1 ns / 1 ps

// [ ] Importar configurações 
// [x] Change $stop by $finish;

module fir_control_tb;

    parameter K = 3;

    reg clk, rst, start;
    wire shift_en, acc_clear, mac_en, data_valid;
    wire [2:0] tap_index;

    integer i;
    integer errors;

    fir_control #(
        .K(K) 
    ) UUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .shift_en(shift_en),
        .acc_clear(acc_clear),
        .mac_en(mac_en),
        .data_valid(data_valid),
        .tap_index(tap_index)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        errors = 0;
        rst = 1;
        start = 0;

        $display("Starting FIR_control Self-Checking Testbench");

        @(negedge clk);
        rst = 0;

        @(negedge clk);
        if (shift_en || mac_en || acc_clear || data_valid) begin
            $display("ERROR: Saídas incorretas após reset");
            errors = errors + 1;
        end
        else
            $display("OK: reset funcionando");

        // muda duas vezes para gerar um pulso e inicializar a maquina de estado uma vez apenas
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        while (acc_clear != 1'b1)
            @(negedge clk);
        $display("OK: CAPTURE detectado");

        while (shift_en != 1'b1)
            @(negedge clk);
        $display("OK: SHIFT detectado");

        i = 1;
        while (mac_en == 1'b1) begin

            @(negedge clk);
            if (tap_index !== i[2:0]) begin
                $display("ERROR: tap_index esperado %0d obtido %0d", i, tap_index);
                errors = errors + 1;
            end
            i = i + 1;
        end

        if (i != K+1) begin
            $display("ERROR: PROCESS executou número errado de ciclos, esperado %0d obtido %0d", K+1, i);
            errors = errors + 1;
        end else
            $display("OK: PROCESS completo");

        while (data_valid != 1'b1)
            @(negedge clk);
        $display("OK: DONE detectado");

        if (errors == 0)
            $display("\n==== TEST PASSED ====\n");
        else
            $display("\n==== TEST FAILED (%0d errors) ====\n", errors);

        $finish;
    end

endmodule
