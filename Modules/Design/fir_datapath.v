/*
Datapath é o bloco responsável por:
	Fazer todas as operações matemáticas do filtro FIR
Contém:

└── fir_datapath
	├──	Shift register (linha de atraso)
	├──	ROM coeficientes
	├──	MUX seleção tap
	├──	Multiplicador
	├──	Somador
	├──	Acumulador
	└──	Registrador de saída
*/

module fir_datapath #(
    parameter	K  = 8,
				DW = 8,
				CW = 8
)(
    input  clk,
    input  rst,

    // Controle da FSM
    input  shift_en,
    input  mac_en,
    input  acc_clear,
    input  start,
    input  tap_en,

    // Dados
    input  signed [DW-1:0] x_in,

    // Saída
    output reg signed [DW+CW+$clog2(K):0] y_out
);

    localparam	PW = DW + CW,
    			AW = PW + $clog2(K) + 1;

    // Shift Register

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

    // Tap Counter

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

    // Data Selector (MUX de taps)

    wire signed [DW-1:0] sample;

    mux_taps #(
        .DATA_WIDTH(DW),
        .NUM_TAPS  (K)
    ) u_mux_taps (
        .taps_in  (taps_bus),
        .tap_index(tap_index),
        .data_out (sample)
    );

	// ROM de coeficientes

    wire signed [CW-1:0] coeff_rom;

    rom #(
        .NUM_TAPS(K),
        .COEFF_WIDTH(CW)
    ) u_rom (
        .addr(tap_index),
        .coeff(coeff_rom)
    );

    // Multiplicador

    wire signed [PW-1:0] product;
    assign product = sample * coeff_rom;

    // Acumulador + ACC_MUX

    reg signed [AW-1:0] acc_reg;
    wire signed [AW-1:0] acc_sum;
    wire signed [AW-1:0] acc_next;

    assign acc_sum = acc_reg + product;

    acc_mux #(
        .ACC_WIDTH(AW)
    ) u_acc_mux (
        .sum_in (acc_sum),
        .sel_acc(mac_en),   // 1 = acumula | 0 = limpa
        .acc_in (acc_next)
    );

    always @(posedge clk or posedge rst) begin
        if (rst)
            acc_reg <= 1'b0;
        else if (acc_clear)
            acc_reg <= 1'b0;
        else
            acc_reg <= acc_next;
    end

   // Latch da saída

    always @(posedge clk) begin
        if (mac_en && last_cycle)
            y_out <= acc_sum;
    end

endmodule
