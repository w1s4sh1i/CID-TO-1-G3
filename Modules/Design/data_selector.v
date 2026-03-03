// =======================================================
//  DATA SELECTOR (MUX DAS AMOSTRAS)
//  Seleciona x[n-k] a partir da linha de atraso
// =======================================================

module data_selector #(
    parameter DATA_WIDTH = 16,      // Largura de cada amostra (ponto fixo em complemento de dois)
    parameter K = 8                // Número de taps do filtro FIR (ordem parametrizável)
)(   
    input  wire signed [K*DATA_WIDTH-1:0] shift_bus, // Barramento único contendo todas as amostras armazenadas, tamanho total = K amostras * largura de cada amostra
    input  wire [$clog2(K)-1:0] tap_index,          // Índice do tap atual (vem do contador de taps), determina qual amostra será selecionada
    output reg  signed [DATA_WIDTH-1:0] sample_out // Saída, esta amostra irá para o multiplicador da arquitetura MAC
);

integer i;
// Bloco combinacional, sempre que shift_bus ou tap_index mudarem, a saída será recalculada imediatamente
always @(*) begin
    sample_out = 0;
    for (i = 0; i < K; i = i + 1)
        if (tap_index == i)
            sample_out = shift_bus[i*DATA_WIDTH +: DATA_WIDTH];
end

endmodule



/***********TESTBENCH***********************/ 

`timescale 1ns/1ps

module tb_data_selector;

    parameter DATA_WIDTH = 16;
    parameter K = 8;

    reg  signed [K*DATA_WIDTH-1:0] shift_bus;
    reg  [$clog2(K)-1:0] tap_index;
    wire signed [DATA_WIDTH-1:0] sample_out;

    data_selector #(
        .DATA_WIDTH(DATA_WIDTH),
        .K(K)
    ) dut (
        .shift_bus(shift_bus),
        .tap_index(tap_index),
        .sample_out(sample_out)
    );

    initial begin
        shift_bus[0*DATA_WIDTH +: DATA_WIDTH] = 16'sd10;
        shift_bus[1*DATA_WIDTH +: DATA_WIDTH] = 16'sd20;
        shift_bus[2*DATA_WIDTH +: DATA_WIDTH] = 16'sd30;
        shift_bus[3*DATA_WIDTH +: DATA_WIDTH] = 16'sd40;
        shift_bus[4*DATA_WIDTH +: DATA_WIDTH] = 16'sd50;
        shift_bus[5*DATA_WIDTH +: DATA_WIDTH] = 16'sd60;
        shift_bus[6*DATA_WIDTH +: DATA_WIDTH] = 16'sd70;
        shift_bus[7*DATA_WIDTH +: DATA_WIDTH] = 16'sd80;

        for (tap_index = 0; tap_index < K; tap_index = tap_index + 1)
            #10;

        #20 $finish;
    end

endmodule
