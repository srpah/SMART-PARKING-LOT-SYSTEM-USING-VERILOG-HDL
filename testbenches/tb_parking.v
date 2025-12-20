`timescale 1ns/1ps
module tb_parking;

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

// Clock
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
top_parking_system_4slot DUT (
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


// ------------------- CONSOLE DASHBOARD OUTPUT -------------------

initial begin
    #1;
    $display("\n================= PARKING SYSTEM MONITOR =================");
    $display("Time | Event                  | Occ | Free | FeeReady | Fee | Gate(E/X)");
    $display("-----------------------------------------------------------------------");
end

always @(posedge clk) begin

    if(entry_pulse)
        $display("%4t | ENTRY                 | %b |  %0d  |   %b     | %0d |  %b/%b",
                  $time, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);

    if(exit_pulse)
        $display("%4t | EXIT REQUEST (Slot=%0d) | %b |  %0d  |   %b     | %0d |  %b/%b",
                  $time, exit_car_select, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);

    if(payment_received)
        $display("%4t | PAYMENT RECEIVED      | %b |  %0d  |   %b     | %0d |  %b/%b",
                  $time, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);

    if(exit_gate)
        $display("%4t | EXIT COMPLETED        | %b |  %0d  |   %b     | %0d |  %b/%b",
                  $time, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);

end


// ------------------- TEST SCENARIO -------------------

initial begin
    $dumpfile("parking_payment.vcd");
    $dumpvars(1, tb_parking);

    rst = 1; #40; rst = 0;

    $display("\n==== 4 VEHICLES ENTER ====\n");

    repeat(4) begin
        entry_sensor = 1; #30;
        entry_sensor = 0; #120;
    end

    #200;

    $display("\n==== TEST: EXIT WITHOUT PAYMENT (Slot 3) ====\n");

    exit_car_select = 3;
    exit_sensor = 1; #20; exit_sensor = 0;

    #150;
    $display("Gate remains closed. Waiting for payment.");
    $display("Timer continues running. Current time for slot 3 = %0d", e3);

    #200;

    $display("\nProcessing payment...");
    payment_received = 1; #20; payment_received = 0;

    #150;

    $display("\n==== Remaining Vehicles Exit With Payment ====\n");

    exit_car_select = 1;
    exit_sensor=1; #30; exit_sensor=0;
    #50; payment_received=1; #20; payment_received=0; #150;

    exit_car_select = 2;
    exit_sensor=1; #30; exit_sensor=0;
    #50; payment_received=1; #20; payment_received=0; #150;

    exit_car_select = 0;
    exit_sensor=1; #30; exit_sensor=0;
    #50; payment_received=1; #20; payment_received=0; #200;

    $display("\n===== TEST COMPLETE =====");
    $display("Final State: Occupancy=%b | Free Count=%0d\n", occupancy, free_count);

    $finish;
end

endmodule