`include "Defines.vh"

module Fixed_Point_Unit 
#(
    parameter WIDTH = 32,
    parameter FBITS = 10
)
(
    input wire clk,
    input wire reset,
    
    input wire [WIDTH - 1 : 0] operand_1,
    input wire [WIDTH - 1 : 0] operand_2,
    
    input wire [ 1 : 0] operation,

    output reg [WIDTH - 1 : 0] result,
    output reg ready
);

    always @(*)
    begin
        case (operation)
            `FPU_ADD    : begin result <= operand_1 + operand_2; ready <= 1; end
            `FPU_SUB    : begin result <= operand_1 - operand_2; ready <= 1; end
            `FPU_MUL    : begin result <= product[WIDTH + FBITS - 1 : FBITS]; ready <= product_ready; end
            `FPU_SQRT   : begin result <= root; ready <= root_ready; end
            default     : begin result <= 'bz; ready <= 0; end
        endcase
    end

    always @(posedge reset)
    begin
        if (reset)  ready = 0;
        else        ready = 'bz;
    end
    // ------------------- //
    // Square Root Circuit //
    // ------------------- //
    reg [WIDTH - 1 : 0] root;
    reg root_ready;

 // Registers for square root calculation
reg [WIDTH-1:0] current_operand;
reg [WIDTH-1:0] approx_root;
reg [WIDTH-1:0] intermediate_result;
reg [WIDTH-1:0] accumulated_root;
reg [WIDTH-1:0] iteration_count;
reg [WIDTH-1:0] operand_copy;

// State machine states
localparam IDLE_STATE = 2'b00;
localparam CALC_STATE = 2'b01;
reg [1:0] current_state;
reg [1:0] next_bits;

always @(posedge clk) begin
    if (reset) begin
        current_state <= IDLE_STATE;
        root <= 0;
        root_ready <= 0;
        operand_copy <= operand_1;
    end else begin
        case (current_state)
            IDLE_STATE: begin
                if (operation == `FPU_SQRT) begin
                    // Setup initial values for computation
                    current_operand <= operand_1[WIDTH-1:WIDTH-2];
                    approx_root <= 2'b01;
                    iteration_count <= (WIDTH + FBITS) >> 1; // Determine number of iterations
                    current_state <= CALC_STATE;
                    accumulated_root <= 0;
                end
            end
            CALC_STATE: begin
                if (iteration_count > 0) begin
                    // Calculate the next digit of the square root
                    intermediate_result <= current_operand - approx_root;
                    if (intermediate_result < 0) begin
                        // If result is negative, shift left by 1
                        accumulated_root <= accumulated_root << 1;
                    end else begin
                        // If result is positive, shift left and add 1
                        accumulated_root <= (accumulated_root << 1) + 1;
                    end

                    // Prepare for next iteration by shifting operand
                    operand_copy <= operand_copy << 2;
                    // Extract the next two bits for the next iteration
                    next_bits <= operand_copy[WIDTH-1:WIDTH-2];
                    // Update the current operand
                    current_operand <= (current_operand << 2) + next_bits;
                    // Update the approximation of the root
                    approx_root <= (accumulated_root << 2) + 1;
                    
                    iteration_count <= iteration_count - 1;
                end else begin
                    root <= accumulated_root;
                    root_ready <= 1;
                    current_state <= IDLE_STATE;
                end
            end
        endcase
    end
end
    // ------------------ //
    // Multiplier Circuit //
    // ------------------ // 
    // Internal registers to hold intermediate states and partial products  
    reg [64 - 1 : 0] product;
    reg product_ready;
    reg [2:0] caseNum;
    reg [15 : 0] A, B;
    wire [31 : 0] multiplyResult;
    reg [31 : 0] partialPordact1, partialPordact2, partialPordact3, partialPordact4;

    // Multiplier instance to multiply 16-bit segments
    Multiplier multiplier(
        .operand_1(A),
        .operand_2(B),
        .product(multiplyResult)
    );

    // Sequential logic to handle reset and multiplication state machine
    always @(posedge clk or posedge reset)
    begin
        if (reset) begin
            // Reset all registers to their initial values
            caseNum <= 0;
            product_ready <= 0;
            product <= 0;
            {partialPordact1, partialPordact2, partialPordact3, partialPordact4} <= 0;
            {A, B} <= 0;
        end
        else if (operation == `FPU_MUL) begin
            case (caseNum)
                0: begin 
                    // Stage 1: Multiply lower 16 bits of both operands
                    A <= operand_1[15:0];
                    B <= operand_2[15:0];
                    caseNum <= 1;
                end
                1: begin 
                    // Store partial result and prepare next multiplication (upper 16 bits of operand_1 and lower 16 bits of operand_2)
                    partialPordact1 <= multiplyResult;
                    A <= operand_1[31:16];
                    B <= operand_2[15:0];
                    caseNum <= 2;
                end
                2: begin 
                    // Shift and store partial result, prepare next multiplication (lower 16 bits of operand_1 and upper 16 bits of operand_2)
                    partialPordact2 <= multiplyResult << 16;
                    A <= operand_1[15:0];
                    B <= operand_2[31:16];
                    caseNum <= 3;
                end
                3: begin 
                    // Shift and store partial result, prepare next multiplication (upper 16 bits of both operands)
                    partialPordact3 <= multiplyResult << 16;
                    A <= operand_1[31:16];
                    B <= operand_2[31:16];
                    caseNum <= 4;
                end
                4: begin
                    // Shift and store the final partial result
                    partialPordact4 <= multiplyResult << 32;
                    caseNum <= 5;
                end
                5: begin
                    // Combine all partial products to form the final 64-bit product
                    product <= partialPordact1 + partialPordact2 + partialPordact3 + partialPordact4;
                    product_ready <= 1;
                    caseNum <= 0;
                end
                // Default case to handle unexpected states
                default: caseNum <= 0;
            endcase
        end
    end
endmodule

module Multiplier
(
    input wire [15 : 0] operand_1,
    input wire [15 : 0] operand_2,

    output reg [31 : 0] product
);

    always @(*)
    begin
        product <= operand_1 * operand_2;
    end
endmodule