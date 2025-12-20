`timescale 1ns/1ps
module tb_parking_full_cycle;

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

// Edge detect logic
reg entry_d, exit_d;
always @(posedge clk) begin
    entry_d <= entry_sensor;
    exit_d  <= exit_sensor;
end

wire entry_pulse = entry_sensor & ~entry_d;
wire exit_pulse  = exit_sensor  & ~exit_d;


// DUT instance
top_parking_system_4slot DUT(
    .clk(clk), .rst(rst), .entry_pulse(entry_pulse), .exit_pulse_for_system(exit_pulse),
    .payment_received(payment_received), .exit_car_select(exit_car_select),
    .entry_gate(entry_gate), .exit_gate(exit_gate), .full_led(full_led), .fee_ready(fee_ready),
    .occupancy(occupancy), .free_count(free_count),
    .e0(e0), .e1(e1), .e2(e2), .e3(e3), .fee(fee)
);


// =================== DASHBOARD OUTPUT ===================

integer printed_header = 0;

initial begin
    #1;
    $display("\n=================== PARKING SYSTEM CONSOLE ===================");
    $display("Time | Event Description        | Occupancy | Free | FeeReady | Fee | Gate(E/X)");
    $display("--------------------------------------------------------------------------");
end

reg [31:0] prev_fee = 0;

always @(posedge clk) begin

    // Print fee calculation immediately when updated
    if (fee_ready && fee !== prev_fee) begin
        $display("%0t | Fee Calculated             | %b |  %0d   |    %b     | %0d |   %b/%b",
                 $time, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);
        prev_fee <= fee;
    end

    else if(entry_pulse)
        $display("%0t | Entry Detected             | %b |  %0d   |    %b     | %0d |   %b/%b",
                 $time, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);

    else if(exit_pulse)
        $display("%0t | Exit Requested (Slot %0d)  | %b |  %0d   |    %b     | %0d |   %b/%b",
                 $time, exit_car_select, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);

    else if(payment_received)
        $display("%0t | Payment Received           | %b |  %0d   |    %b     | %0d |   %b/%b",
                 $time, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);

    else if(exit_gate)
        $display("%0t | Exit Completed             | %b |  %0d   |    %b     | %0d |   %b/%b",
                 $time, occupancy, free_count, fee_ready, fee, entry_gate, exit_gate);
end



// ====================== TEST SCENARIO ======================

initial begin
    $dumpfile("parking_full_cycle.vcd");
    $dumpvars(0, tb_parking_full_cycle);

    rst = 1; #40; rst = 0;


    // ----------- Car Entry Phase -----------
    $display("\n===== CAR ENTRY PHASE =====");

    repeat(4) begin
        entry_sensor = 1; #20;
        entry_sensor = 0; #150;
    end

    #200;
    $display("\nParking lot full. No further entry allowed.\n");


    // ----------- Exit Phase (All Cars) -----------
    $display("\n===== EXIT PHASE =====");

    exit_car_select = 3; exit_sensor = 1; #20; exit_sensor = 0; #80;
    payment_received = 1; #20; payment_received = 0; #200;

    exit_car_select = 1; exit_sensor = 1; #20; exit_sensor = 0; #80;
    payment_received = 1; #20; payment_received = 0; #200;

    exit_car_select = 2; exit_sensor = 1; #20; exit_sensor = 0; #80;
    payment_received = 1; #20; payment_received = 0; #200;

    exit_car_select = 0; exit_sensor = 1; #20; exit_sensor = 0; #80;
    payment_received = 1; #20; payment_received = 0; #200;


    // ----------- Summary -----------
    $display("\n===== ALL CARS EXITED. PARKING EMPTY =====");
    $display("Final Status: Occupancy=%b | Free Slots=%0d\n", occupancy, free_count);

    #200;
    $finish;
end

endmodule