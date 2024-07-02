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
            `FPU_ADD    : begin result = operand_1 + operand_2; ready = 1; end
            `FPU_SUB    : begin result = operand_1 - operand_2; ready = 1; end
            `FPU_MUL    : begin result = product[WIDTH + FBITS - 1 : FBITS]; ready = product_ready; end
            `FPU_SQRT   : begin result = root; ready = root_ready; end
            default     : begin result = 'bz; ready = 0; end
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

    reg [WIDTH - 1 : 0] root;           // Register to store the final square root result
    reg root_ready;                     // Flag to indicate when the square root computation is complete

    reg [1 : 0] sqrt_stage;             // Current stage of the square root computation
    reg [1 : 0] next_sqrt_stage;        // Next stage of the square root computation

    always @(posedge clk) 
    begin
        if (operation == `FPU_SQRT) sqrt_stage <= next_sqrt_stage;  // Update the stage if the operation is square root
        else                        
        begin
            sqrt_stage <= 2'b00;       // Reset stage to initial value if operation is not square root
            root_ready <= 0;           // Reset root ready flag
        end
    end 

    always @(*) 
    begin
        next_sqrt_stage <= 'bz;        // Default high-impedance value for next stage
        case (sqrt_stage)
            2'b00 : begin 
                sqrt_init <= 0;        // Initialize sqrt_init to 0
                next_sqrt_stage <= 2'b01;  // Move to the next stage
            end
            2'b01 : begin 
                sqrt_init <= 1;        // Set sqrt_init to 1 to start the computation
                next_sqrt_stage <= 2'b10;  // Move to the next stage
            end
            2'b10 : begin 
                sqrt_init <= 0;        // Set sqrt_init to 0 as computation is in progress
                next_sqrt_stage <= 2'b10;  // Stay in the current stage
            end
        endcase    
    end
    
    reg sqrt_init;                      // Flag to indicate the initialization of square root computation
    reg sqrt_active;                    // Flag to indicate if square root computation is active

    reg [WIDTH - 1 : 0] dividend, dividend_next;  // Registers to hold current and next values of the dividend
    reg [WIDTH - 1 : 0] quotient, quotient_next;  // Registers to hold current and next values of the quotient
    reg [WIDTH + 1 : 0] accumulator, accumulator_next;  // Registers to hold current and next values of the accumulator
    reg [WIDTH + 1 : 0] test_result;    // Register to hold the test result

    localparam TOTAL_ITER = (WIDTH + FBITS) >> 1; // Total number of iterations needed for computation
    reg [4 : 0] iteration = 0;                    // Iteration counter

    always @(*)
    begin
        test_result = accumulator - {quotient, 2'b01}; // Compute the test result

        if (test_result[WIDTH + 1] == 0) 
        begin
            {accumulator_next, dividend_next} = {test_result[WIDTH - 1 : 0], dividend, 2'b0}; // Update accumulator and dividend if test result is non-negative
            quotient_next = {quotient[WIDTH - 2 : 0], 1'b1};  // Update quotient
        end 
        else 
        begin
            {accumulator_next, dividend_next} = {accumulator[WIDTH - 1 : 0], dividend, 2'b0}; // Maintain current accumulator and dividend if test result is negative
            quotient_next = quotient << 1;  // Shift quotient to the left
        end
    end

    always @(posedge clk) 
    begin
        if (sqrt_init)
        begin
            sqrt_active <= 1;          // Activate the square root computation
            root_ready <= 0;           // Reset root ready flag
            iteration <= 0;            // Reset iteration counter
            quotient <= 0;             // Reset quotient
            {accumulator, dividend} <= {{WIDTH{1'b0}}, operand_1, 2'b0}; // Initialize accumulator and dividend
        end
        else if (sqrt_active)
        begin
            if (iteration == TOTAL_ITER-1) 
            begin  // Check if computation is complete
                sqrt_active <= 0;      // Deactivate square root computation
                root_ready <= 1;       // Set root ready flag
                root <= quotient_next; // Store the final square root result
            end
            else 
            begin  // Proceed to next iteration
                iteration <= iteration + 1; // Increment iteration counter
                dividend <= dividend_next; // Update dividend
                accumulator <= accumulator_next; // Update accumulator
                quotient <= quotient_next; // Update quotient
                root_ready <= 0;       // Reset root ready flag
            end
        end
    end
    // ------------------ //
    // Multiplier Circuit //
    // ------------------ //   
    reg [64 - 1 : 0] product;
    reg product_ready;

    // Registers for 16-bit inputs to the multiplier circuit
    reg [15:0] mul_input_1;
    reg [15:0] mul_input_2;
    // Wire to hold the 32-bit result from the multiplier circuit
    wire [31:0] mul_output;

    // Instantiation of the multiplier module
    Multiplier mul_unit (
        .operand_1(mul_input_1),
        .operand_2(mul_input_2),
        .product(mul_output)
    );

    // Registers to hold the partial products of the multiplication
    reg [31:0] part_prod1;
    reg [31:0] part_prod2;
    reg [31:0] part_prod3;
    reg [31:0] part_prod4;

    // Registers to keep track of the current and next stages of the multiplication process
    reg [2:0] mul_stage;
    reg [2:0] next_mul_stage;

    // Sequential block to update the multiplication stage on each clock cycle
    always @(posedge clk) 
    begin
        if (operation == `FPU_MUL) 
            mul_stage <= next_mul_stage; // Update stage if operation is multiplication
        else                        
            mul_stage <= 3'b000; // Reset stage to initial if operation is not multiplication
    end

    // Combinational block to determine the next multiplication stage and handle partial products
    always @(*) 
    begin
        next_mul_stage <= 3'bzzz; // Default high-impedance value for next stage
        case (mul_stage)
            3'b000: 
            begin
                product_ready <= 0; // Clear product ready flag

                // High-impedance values for inputs and partial products
                mul_input_1 <= 16'bz;
                mul_input_2 <= 16'bz;

                part_prod1 <= 32'bz;
                part_prod2 <= 32'bz;
                part_prod3 <= 32'bz;
                part_prod4 <= 32'bz;

                next_mul_stage <= 3'b001; // Move to the next stage
            end
            3'b001: 
            begin
                // Perform first partial multiplication
                mul_input_1 <= operand_1[15:0];
                mul_input_2 <= operand_2[15:0];
                part_prod1 <= mul_output;
                next_mul_stage <= 3'b010; // Move to the next stage
            end
            3'b010: 
            begin
                // Perform second partial multiplication
                mul_input_1 <= operand_1[31:16];
                mul_input_2 <= operand_2[15:0];
                part_prod2 <= mul_output;
                next_mul_stage <= 3'b011; // Move to the next stage
            end
            3'b011: 
            begin
                // Perform third partial multiplication
                mul_input_1 <= operand_1[15:0];
                mul_input_2 <= operand_2[31:16];
                part_prod3 <= mul_output;
                next_mul_stage <= 3'b100; // Move to the next stage
            end
            3'b100: 
            begin
                // Perform fourth partial multiplication
                mul_input_1 <= operand_1[31:16];
                mul_input_2 <= operand_2[31:16];
                part_prod4 <= mul_output;
                next_mul_stage <= 3'b101; // Move to the next stage
            end
            3'b101: 
            begin
                // Combine partial products to get the final product
                product <= part_prod1 + (part_prod2 << 16) + (part_prod3 << 16) + (part_prod4 << 32);
                next_mul_stage <= 3'b000; // Reset to initial stage
                product_ready <= 1; // Set product ready flag
            end

            default: 
                next_mul_stage <= 3'b000; // Default case to reset stage
        endcase    
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