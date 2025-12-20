`timescale 1ns/1ps

module top_parking_system_4slot(
    input  wire        clk,
    input  wire        rst,
    input  wire        entry_pulse,
    input  wire        exit_pulse_for_system,
    input  wire        payment_received,     
    input  wire [1:0]  exit_car_select,
    output wire        entry_gate,
    output wire        exit_gate,
    output wire        full_led,
    output wire        fee_ready,            
    output wire [3:0]  occupancy,
    output wire [2:0]  free_count,
    output wire [31:0] e0,
    output wire [31:0] e1,
    output wire [31:0] e2,
    output wire [31:0] e3,
    output wire [31:0] fee
);

wire alloc_req, free_req;
wire slot_available;
wire [1:0] allocated_slot;
wire [1:0] exit_slot;

// BILLING TRIGGER WAITS FOR PAYMENT
reg exit_event_for_billing;

always @(posedge clk or posedge rst) begin
    if (rst)
        exit_event_for_billing <= 0;
    else
        exit_event_for_billing <= payment_received; 
end

// FSM
fsm_parking FSM(
    .clk(clk),
    .rst(rst),
    .entry_pulse(entry_pulse),
    .exit_pulse_in(exit_pulse_for_system),
    .payment_received(payment_received), 
    .slot_available(slot_available),
    .occupancy(occupancy),
    .alloc_req(alloc_req),
    .free_req(free_req),
    .entry_gate(entry_gate),
    .exit_gate(exit_gate),
    .full_led(full_led),
    .fee_ready(fee_ready)             
);

// SLOT MANAGER 
slot_manager_4slot SM(
    .clk(clk),
    .rst(rst),
    .alloc_req(alloc_req),
    .free_req(free_req),
    .slot_available(slot_available),
    .allocated_slot(allocated_slot),
    .occupancy(occupancy),
    .free_count(free_count),
    .exit_slot(exit_slot),
    .exit_car_select(exit_car_select)
);

// BILLING 
time_billing_4slot TM(
    .clk(clk),
    .rst(rst),
    .occupancy(occupancy),
    .exit_pulse(exit_event_for_billing),
    .exit_slot(exit_slot),
    .elapsed0(e0),
    .elapsed1(e1),
    .elapsed2(e2),
    .elapsed3(e3),
    .fee(fee)
);

endmodule