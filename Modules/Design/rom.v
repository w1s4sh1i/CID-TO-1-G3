module rom #(
    parameter NUM_TAPS = 8;
    parameter COEFF_WIDTH = 8;
)(
    input [$clog2(NUM_TAPS)-1:0] addr,
    output reg [CW-1:0] coeff
);
    
    always @(addr) begin
        case (addr)
            3'b000: coeff = {CW-1{1'b0}, {1'b1}};
            3'b001: coeff = {CW-1{1'b0}, {1'b1}};
            3'b010: coeff = {CW-1{1'b0}, {1'b1}};
            3'b011: coeff = {CW-1{1'b0}, {1'b1}};
            3'b100: coeff = {CW-1{1'b0}, {1'b1}};
            3'b101: coeff = {CW-1{1'b0}, {1'b1}};
            3'b110: coeff = {CW-1{1'b0}, {1'b1}};
            3'b111: coeff = {CW-1{1'b0}, {1'b1}};
            default: coeff = 0;
        endcase
    end

endmodule