module slot_manager_4slot(
input  wire       clk,
input  wire       rst,
input  wire       alloc_req,
input  wire       free_req,
input  wire [1:0] exit_car_select,
output reg        slot_available,
output reg [1:0]  allocated_slot,
output reg [3:0]  occupancy,
output reg [2:0]  free_count,
output reg [1:0]  exit_slot
);

integer i;
reg found;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        occupancy      <= 0;
        free_count     <= 4;
        slot_available <= 1;
        allocated_slot <= 0;
        exit_slot      <= 0;
    end else begin

        found = 0;

        if (free_req) begin
            if (occupancy[exit_car_select]) begin
                occupancy[exit_car_select] <= 0;
                exit_slot <= exit_car_select;
                free_count <= free_count + 1;
            end else begin
                for (i=0;i<4;i=i+1)
                    if (occupancy[i] && !found) begin
                        occupancy[i] <= 0;
                        exit_slot <= i;
                        free_count <= free_count + 1;
                        found = 1;
                    end
            end
        end

        found = 0;

        if (alloc_req && free_count > 0) begin
            for (i=0;i<4;i=i+1)
                if (!occupancy[i] && !found) begin
                    occupancy[i] <= 1;
                    allocated_slot <= i;
                    free_count <= free_count - 1;
                    found = 1;
                end
        end

        slot_available <= (free_count > 0);
    end
end

endmodule