/*
Testbench para fir_control
Verifica a sequência de estados e sinais de controle
*/

`timescale 1 ns / 1 ps

module fir_control_tb;

    localparam K = 8;

    reg clk, rst;
    reg start;

    wire shift_en;
    wire acc_clear;
    wire mac_en;
    wire data_valid;
    wire [$clog2(K)-1:0] tap_index;

    fir_control #(
        .K(K)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .shift_en(shift_en),
        .acc_clear(acc_clear),
        .mac_en(mac_en),
        .data_valid(data_valid),
        .tap_index(tap_index)
    );

    // Clock
    always #5 clk = ~clk;

    // Dump e monitor
    initial begin
        
        $dumpfile("CIDI-SD192-fir-control.vcd");
        $dumpvars(0, fir_control_tb);

        $display("TIME | start shift_en mac_en acc_clear data_valid tap_index");
        $monitor("%0t |  %b      %b        %b      %b        %b        %0d",
            $time,
            start,
            shift_en,
            mac_en,
            acc_clear,
            data_valid,
            tap_index
        );
    end


    // Driver
    task automatic driver_start;
        begin
            @(posedge clk);
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;
        end
    endtask


    // Monitor simples de término
    task automatic wait_done;
        begin
            wait(data_valid == 1'b1);
            @(posedge clk);
            $display("Saída válida detectada");
        end
    endtask


    // Sequência de testes
    task automatic send;
        begin
            driver_start();
            wait_done();
        end
    endtask


    // Testes
    initial begin

        clk = 0;
        rst = 1;
        start = 0;

        #20 rst = 0;

        // Teste 1
        send();

        // Teste 2
        send();

        // Teste 3
        send();

        #100;
        $finish;
    end

endmodule