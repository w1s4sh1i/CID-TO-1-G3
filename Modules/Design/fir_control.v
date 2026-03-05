/*
fir_control é a Unidade de Controle (FSM – Finite State Machine) do filtro FIR.
Controla quando cada operação deve acontecer.
*/

module fir_control #(
    parameter K = 8
)(
	// [ ] Remoção do wire (redundância) 
    input  clk,
    input  rst,
    input  start, // nova amostra disponível
    
    // [ ] Analisar por que precisam ser reg 
    output reg  shift_en,
    output reg  acc_clear,
    output reg  mac_en,
    output reg  data_valid,
    output reg  [$clog2(K)-1:0] tap_index // Usar valor para parametrizar
);

    localparam	IDLE    = 3'd0,
    			CAPTURE = 3'd1,
				SHIFT   = 3'd2,
				PROCESS = 3'd3,
				DONE    = 3'd4;

    reg [2:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case(state)
            IDLE:    if (start) next_state = CAPTURE;
            CAPTURE: next_state = SHIFT;
            SHIFT:   next_state = PROCESS;
            PROCESS: if (tap_index == K-1) next_state = DONE;
            DONE:    next_state = IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tap_index <= 0;
            shift_en  <= 1'b0;
            mac_en    <= 1'b0;
            acc_clear <= 1'b0;
            data_valid<= 1'b0;
        end else begin
            shift_en   <= 1'b0;
            mac_en     <= 1'b0;
            acc_clear  <= 1'b0;
            data_valid <= 1'b0;

            case(state)
                CAPTURE: begin
                    acc_clear <= 1'b1;
                    tap_index <= 0;
                end
                SHIFT: begin
                    shift_en <= 1'b1;
                end
                PROCESS: begin
                    mac_en <= 1'b1;
                    tap_index <= tap_index + 1;
                end
                DONE: begin
                    data_valid <= 1'b1;
                end
            endcase
        end
    end

endmodule
