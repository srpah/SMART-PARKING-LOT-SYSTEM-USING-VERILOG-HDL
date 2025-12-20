`timescale 1ns/1ps

module tb_fallback_exit();

reg clk = 0;
reg rst = 0;

reg entry_sensor = 0;
reg exit_sensor  = 0;
reg payment_received = 0;
reg [1:0] exit_car_select = 0;

wire entry_gate, exit_gate, full_led, fee_ready;
wire [3:0] occupancy;
wire [2:0] free_count;
wire [31:0] fee, e0, e1, e2, e3;

// Clock 10ns period
always #5 clk = ~clk;

// Edge detect
reg entry_d, exit_d;
always @(posedge clk) begin
    entry_d <= entry_sensor;
    exit_d  <= exit_sensor;
end

wire entry_pulse = entry_sensor & ~entry_d;
wire exit_pulse  = exit_sensor  & ~exit_d;

// DUT Instance
top_parking_system_4slot DUT(
    .clk(clk),
    .rst(rst),
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

initial begin
    #1;
    $display("\n=============== FALLBACK EXIT TEST MONITOR ===============");
    $display(" Time | Event                       | Occ | Free | FeeReady | Gate(E/X)");
    $display("-----------------------------------------------------------------------");
end

always @(posedge clk) begin

    if(entry_pulse)
        $display("%4t | Entry detected              | %b |  %0d  |     %b    |  %b/%b",
                  $time, occupancy, free_count, fee_ready, entry_gate, exit_gate);

    if(exit_pulse)
        $display("%4t | Exit request (Slot=%0d)     | %b |  %0d  |     %b    |  %b/%b",
                  $time, exit_car_select, occupancy, free_count, fee_ready, entry_gate, exit_gate);

    if(payment_received)
        $display("%4t | Payment received            | %b |  %0d  |     %b    |  %b/%b",
                  $time, occupancy, free_count, fee_ready, entry_gate, exit_gate);

    if(exit_gate)
        $display("%4t | Exit completed              | %b |  %0d  |     %b    |  %b/%b",
                  $time, occupancy, free_count, fee_ready, entry_gate, exit_gate);
end

// Stimulus
initial begin
    $dumpfile("fallback_exit.vcd");
    $dumpvars(0, tb_fallback_exit);

    rst = 1; 
    #40 rst = 0;

    // Enter 3 Cars (Slot0 → Slot1 → Slot2)
    repeat(3) begin
        entry_sensor = 1; #20;
        entry_sensor = 0; #100;
    end

    // Allow timers to run
    #300;

    // Wrong exit: user selects empty slot (slot 3)
    exit_car_select = 2'd3;
    exit_sensor = 1; #20;
    exit_sensor = 0;

    // System should wait for payment
    #100;

    // Payment after wrong exit attempt
    payment_received = 1; #20;
    payment_received = 0;

    #200;

    $display("\n===== TEST COMPLETE =====");
    $display("Final Occupancy = %b | Free Count = %0d\n", occupancy, free_count);

    $finish;
end

endmodule