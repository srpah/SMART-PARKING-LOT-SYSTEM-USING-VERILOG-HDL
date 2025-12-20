`timescale 1ns/1ps
module tb_entry_when_full;

reg clk = 0, rst = 0;
reg entry_sensor = 0, exit_sensor = 0, payment_received = 0;
reg [1:0] exit_car_select = 0;

wire entry_gate, exit_gate, full_led, fee_ready;
wire [3:0] occupancy;
wire [2:0] free_count;
wire [31:0] fee, e0, e1, e2, e3;

always #5 clk = ~clk;

// Edge detect signals
reg entry_d, exit_d;
always @(posedge clk) begin
    entry_d <= entry_sensor;
    exit_d  <= exit_sensor;
end

wire entry_pulse = entry_sensor & ~entry_d;
wire exit_pulse  = exit_sensor  & ~exit_d;


// DUT
top_parking_system_4slot DUT(
    .clk(clk), .rst(rst),
    .entry_pulse(entry_pulse),
    .exit_pulse_for_system(exit_pulse),
    .payment_received(payment_received),
    .exit_car_select(exit_car_select),
    .entry_gate(entry_gate),
    .exit_gate(exit_gate),
    .full_led(full_led),
    .fee_ready(fee_ready),
    .occupancy(occupancy),
    .free_count(free_count),
    .e0(e0), .e1(e1), .e2(e2), .e3(e3),
    .fee(fee)
);


// ================= DASHBOARD PRINT =================

initial begin
    #1;
    $display("\n================ ENTRY-BLOCK WHEN FULL TEST ================");
    $display("Time | Event              | Occ  | Free | FullLED | Gate(E)");
    $display("-----------------------------------------------------------");
end

always @(posedge clk) begin
    if(entry_pulse)
        $display("%4t | ENTRY Attempt      | %b |   %0d  |    %b     |   %b",
                  $time, occupancy, free_count, full_led, entry_gate);
end


// ================= TEST STIMULUS =================

initial begin
    $dumpfile("entry_when_full.vcd");
    $dumpvars(1, tb_entry_when_full);

    rst = 1; #30; rst = 0;

    // Fill lot completely
    repeat(4) begin
        entry_sensor = 1; #20;
        entry_sensor = 0; #80;
    end

    #120;
    $display("\nLot Full Detected -> FULL_LED=%b | FREE_SLOTS=%0d\n", full_led, free_count);

    // Attempt entry when full
    entry_sensor = 1; #20; entry_sensor = 0;

    #120;

    $display("\nENTRY BLOCKED — SYSTEM RESPONSE SUMMARY:");
    $display("Entry Gate      = %b (Expected: 0)", entry_gate);
    $display("Occupancy       = %b", occupancy);
    $display("Free Slot Count = %0d (Expected: 0)", free_count);
    $display("Full Indicator  = %b (Expected: 1)", full_led);

    $display("\n================ TEST COMPLETE =================\n");

    #100;
    $finish;
end

endmodule