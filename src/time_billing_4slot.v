module time_billing_4slot(
input  wire        clk,
input  wire        rst,
input  wire [3:0]  occupancy,
input  wire        exit_pulse,
input  wire [1:0]  exit_slot,
output reg [31:0]  elapsed0,
output reg [31:0]  elapsed1,
output reg [31:0]  elapsed2,
output reg [31:0]  elapsed3,
output reg [31:0]  fee
);

parameter RATE = 10;

reg run0, run1, run2, run3;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        run0<=0; run1<=0; run2<=0; run3<=0;
        elapsed0<=0; elapsed1<=0; elapsed2<=0; elapsed3<=0;
        fee <= 0;
    end else begin

        if (exit_pulse) begin
            case(exit_slot)
                0: fee <= elapsed0 * RATE;
                1: fee <= elapsed1 * RATE;
                2: fee <= elapsed2 * RATE;
                3: fee <= elapsed3 * RATE;
            endcase
        end

        if (occupancy[0]) begin if(!run0) elapsed0<=0; run0<=1; end else run0<=0;
        if (occupancy[1]) begin if(!run1) elapsed1<=0; run1<=1; end else run1<=0;
        if (occupancy[2]) begin if(!run2) elapsed2<=0; run2<=1; end else run2<=0;
        if (occupancy[3]) begin if(!run3) elapsed3<=0; run3<=1; end else run3<=0;

        if (run0) elapsed0 <= elapsed0 + 1;
        if (run1) elapsed1 <= elapsed1 + 1;
        if (run2) elapsed2 <= elapsed2 + 1;
        if (run3) elapsed3 <= elapsed3 + 1;
    end
end
endmodule