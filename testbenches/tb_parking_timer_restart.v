`timescale 1ns/1ps
module tb_parking_timer_restart;

reg clk = 0;
reg rst = 0;

reg entry_sensor = 0;
reg exit_sensor  = 0;
reg payment_received = 0;
reg [1:0] exit_car_select = 0;

wire entry_gate, exit_gate, full_led, fee_ready;
wire [3:0] occupancy;
wire [2:0] free_count;
wire [31:0] e0, e1, e2, e3, fee;

// Clock
always #5 clk = ~clk;

// Edge detection logic
reg entry_d, exit_d;
always @(posedge clk) begin
    entry_d <= entry_sensor;
    exit_d  <= exit_sensor;
end

wire entry_pulse = entry_sensor & ~entry_d;
wire exit_pulse  = exit_sensor  & ~exit_d;

// DUT
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
// ------------------- DASHBOARD MONITOR -------------------
initial begin
    $display("\n================ SMART PARKING SYSTEM MONITOR ================");
    $display(" Time | State | Entry | Exit | Occ | Free | Fee | Gate(Entry/Exit) ");  
    $display("--------------------------------------------------------------");
end

always @(posedge clk) begin
    if(entry_pulse || exit_pulse || payment_received) begin
        $display("%4t | %b |   %b   |  %b  | %b |  %0d   | %0d |   %b / %b",
            $time,
            DUT.FSM.state,         // FSM state display
            entry_pulse,
            exit_pulse,
            occupancy,
            free_count,
            fee,
            entry_gate,
            exit_gate
        );
    end
end




// MAIN TEST SEQUENCE
initial begin
   $dumpfile("timer_restart.vcd");
    $dumpvars(0, tb_parking_timer_restart);

    rst = 1; #40; rst = 0;
    $display("\n==== TESTCASE: Timer Restarts After Car Re-Entry ====\n");


    // -------------------------------------------------------------
    // STEP 1: First Entry
    // -------------------------------------------------------------
    $display(">> Car entering first time...");
    entry_sensor = 1; #20;
    entry_sensor = 0; #200;   // let timer run

    $display("Timer after first entry: e0=%0d", e0);


    // -------------------------------------------------------------
    // STEP 2: Exit and Pay
    // -------------------------------------------------------------
    $display(">> Car exiting...");
    exit_car_select = 0;
    exit_sensor = 1; #20; exit_sensor = 0;
    #80;

    // car must pay
    payment_received = 1; #20; payment_received = 0;
    #200;

    $display("Timer value when exiting first time: %0d, Fee=%0d", e0, fee);


    // -------------------------------------------------------------
    // STEP 3: Re-enter the same slot
    // -------------------------------------------------------------
    $display(">> Car re-entering (slot should reset timer)...");
    entry_sensor = 1; #20;
    entry_sensor = 0; #200;

    $display("Timer after second entry should restart from 0: e0=%0d", e0);


    // let timer run again to verify restart
    #300;
    $display("Updated timer value: e0=%0d", e0);

    // ------------------------------------------------------------
    $display("\n==== END OF TESTCASE ====\n");
    #200;
 
    $finish;
end

endmodule