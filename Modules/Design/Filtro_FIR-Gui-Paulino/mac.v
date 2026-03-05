/*****************************************************
MULT → calcula A × B
ADDER → soma produto + acumulador
soma (acumular)
ACCUMULATOR → registrador

*******************************************************/

module mac #(
    parameter DW = 8,
    parameter CW = 8,
    parameter AW = DW + CW + 4
)(
    input  wire clk,
    input  wire rst,

    input  wire signed [DW-1:0] data_in,
    input  wire signed [CW-1:0] coeff_in,

    input  wire ps,
    input  wire l_acc,
    input  wire signed [AW-1:0] load_value,

    output reg  signed [AW-1:0] acc_out
);

    // Produto
    wire signed [DW+CW-1:0] product;
    assign product = data_in * coeff_in;

    // Extensão explícita de sinal
    wire signed [AW-1:0] product_ext;
    assign product_ext = {{(AW-(DW+CW)){product[DW+CW-1]}}, product};

    // Soma
    wire signed [AW-1:0] sum;
    assign sum = acc_out + product_ext;

    always @(posedge clk or posedge rst) begin
        if (rst)
            acc_out <= 0;

        else if (l_acc)
            acc_out <= 0;

        else if (ps)
            acc_out <= sum;

    end

endmodule