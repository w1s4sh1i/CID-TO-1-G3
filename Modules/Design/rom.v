module rom #(
    parameter NUM_TAPS    = 8,
    parameter COEFF_WIDTH = 8
)(
    input  wire [$clog2(NUM_TAPS)-1:0] addr,
    output reg  signed [COEFF_WIDTH-1:0] coeff
);

    // Memória de coeficientes
    reg signed [COEFF_WIDTH-1:0] mem [0:NUM_TAPS-1];

    // Inicializa a ROM a partir de arquivo externo
    initial begin
        $readmemh("coeffs.mem", mem);
    end

    // Leitura combinacional
    always @(*) begin
        coeff = mem[addr];
    end

endmodule
