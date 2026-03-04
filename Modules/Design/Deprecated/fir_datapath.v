module FIR_datapath #(
    parameter K  = 8,
    parameter DW = 8,
    parameter CW = 8
)(
    input  wire clk,
    input  wire rst,

    // Controle da FSM
    input  wire shift_en,
    input  wire mac_en,
    input  wire acc_clear,
    input  wire start,
    input  wire tap_en,

    // Dados
    input  wire signed [DW-1:0] x_in,

    // Sa�da
    output reg signed [DW+CW+$clog2(K):0] y_out
);

    localparam PW = DW + CW;
    localparam AW = PW + $clog2(K) + 1;

    // ======================================================
    // Shift Register
    // ======================================================

    wire signed [K*DW-1:0] taps_bus;

    shift_register #(
        .DATA_WIDTH(DW),
        .NUM_TAPS  (K)
    ) u_shift_register (
        .clk      (clk),
        .rst      (rst),
        .shift_en (shift_en),
        .data_in  (x_in),
        .taps_out (taps_bus)
    );

    // ======================================================
    // Tap Counter
    // ======================================================

    wire [$clog2(K)-1:0] tap_index;
    wire last_cycle;

    tap_counter #(
        .K(K)
    ) u_tap_counter (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .enable    (tap_en),
        .tap_index (tap_index),
        .last_cycle(last_cycle)
    );

    // ======================================================
    // Data Selector (MUX de taps)
    // ======================================================

    wire signed [DW-1:0] sample;

    mux_taps #(
        .DATA_WIDTH(DW),
        .NUM_TAPS  (K)
    ) u_mux_taps (
        .taps_in  (taps_bus),
        .tap_index(tap_index),
        .data_out (sample)
    );

    // ======================================================
    // ROM de coeficientes
    // ======================================================

    wire signed [CW-1:0] coeff; 
    rom #( .NUM_TAPS(K), .COEFF_WIDTH(CW) ) u_rom ( .addr(tap_index), .coeff(coeff) );

    // ======================================================
    // Multiplicador
    // ======================================================

    wire signed [PW-1:0] product;
    assign product = sample * coeff;

    // ======================================================
    // Acumulador + ACC_MUX
    // ======================================================

    reg signed [AW-1:0] acc_reg;
    wire signed [AW-1:0] acc_sum;
    wire signed [AW-1:0] acc_next;

    assign acc_sum = acc_reg + product;

    acc_mux #(
        .ACC_WIDTH(AW)
    ) u_acc_mux (
        .sum_in (acc_sum),
        .acc_reg(acc_reg),   // <<< NOVO: passa o valor atual do acumulador
        .sel_acc(mac_en),    // 1 = acumula | 0 = mant�m
        .acc_in (acc_next)
    );

    always @(posedge clk or posedge rst) begin
        if (rst)
            acc_reg <= '0;
        else if (acc_clear)
            acc_reg <= '0;    // limpeza expl�cita s� aqui
        else
            acc_reg <= acc_next;
    end

    // ======================================================
    // Latch da sa�da
    // ======================================================

    always @(posedge clk or posedge rst) begin
        if (rst)
            y_out <= '0;
        else if (last_cycle)   // s� no �ltimo tap
            y_out <= acc_sum;
    end

    // ======================================================
    // Bloco de debug interno
    // ======================================================

    //always @(posedge clk) begin
      //  $display("tap=%0d | sample=%h | coeff=%h | product=%h | acc_reg=%h | acc_sum=%h | y_out=%h | last_cycle=%b",
      //           tap_index, sample, coeff, product, acc_reg, acc_sum, y_out, last_cycle);
    //end

endmodule

