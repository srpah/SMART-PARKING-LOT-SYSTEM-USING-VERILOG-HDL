module fsm_parking(
input  wire       clk,
input  wire       rst,
input  wire       entry_pulse,
input  wire       exit_pulse_in,
input  wire       payment_received,     
input  wire       slot_available,
input  wire [3:0] occupancy,
output reg        alloc_req,
output reg        free_req,
output reg        entry_gate,
output reg        exit_gate,
output reg        full_led,
output reg        fee_ready          
);

localparam S_IDLE          = 3'd0;
localparam S_ALLOC         = 3'd1;
localparam S_GATEOPEN      = 3'd2;
localparam S_EXIT_REQUEST  = 3'd3;
localparam S_WAIT_PAYMENT  = 3'd4;
localparam S_EXITOPEN      = 3'd5;

reg [2:0] state, next;

always @(posedge clk or posedge rst)
    if (rst) state <= S_IDLE;
    else     state <= next;

always @(*) begin
    alloc_req=0; free_req=0; entry_gate=0; exit_gate=0;
    fee_ready=0;
    full_led = ~slot_available;
    next = state;

    case(state)

        S_IDLE:
            if(entry_pulse && slot_available)
                next = S_ALLOC;
            else if(exit_pulse_in && occupancy!=0)
                next = S_EXIT_REQUEST;

        S_ALLOC: begin
            alloc_req = 1;
            next = S_GATEOPEN;
        end

        S_GATEOPEN: begin
            entry_gate = 1;
            next = S_IDLE;
        end

        S_EXIT_REQUEST: begin
            fee_ready = 1;
            next = S_WAIT_PAYMENT;
        end

        S_WAIT_PAYMENT: begin
            fee_ready = 1;
            if(payment_received) begin
                free_req = 1;
                next = S_EXITOPEN;
            end
        end

        S_EXITOPEN: begin
            exit_gate = 1;
            next = S_IDLE;
        end

    endcase
end

endmodule