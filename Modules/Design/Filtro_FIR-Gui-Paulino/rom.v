//a ROM lê automaticamente o arquivo na simulação

module rom #(
    parameter NUM_TAPS   = 8,
    parameter COEFF_WIDTH = 8,
    parameter FILE_NAME  = "coeffs/fir_coeffs.mem"
)(
    input  wire [$clog2(NUM_TAPS)-1:0] addr,
    output reg  signed [COEFF_WIDTH-1:0] coeff
);

    // Memória interna
    reg signed [COEFF_WIDTH-1:0] memory [0:NUM_TAPS-1];

    // Leitura do arquivo externo
    initial begin
        $readmemh(FILE_NAME, memory);
    end

    // Leitura combinacional
    always @(*) begin
        coeff = memory[addr];
    end

endmodule