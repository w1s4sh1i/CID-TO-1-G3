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
    // initial begin
    //     $readmemh("coeffs.mem", mem);
    // end

    // Leitura combinacional
    // always @(*) begin
    //     coeff = mem[addr];
    // end

    always @(*) begin
        case (addr)
         3'b000: coeff = 3;
         3'b001: coeff = 1;
         3'b010: coeff = 1;
         3'b011: coeff = 1;
         3'b100: coeff = 1;
         3'b101: coeff = 1;
         3'b110: coeff = 1;
         3'b111: coeff = 5;
        endcase
    end

endmodule
