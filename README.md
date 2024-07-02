
# Computer Organization Project Spring_2024
==============================================================
# Iran Univeristy of Science and Technology

- Team Members: Parsa Ghorbani & AmirMohammad Chamanzari & AmirReza Bakhtaki
- Date: 2 July 2024

## Assembly.s Code Description

This RISC-V assembly program computes the Euclidean norm of pairs of floating-point numbers in a loop and accumulates the results. Below is a detailed breakdown of the code:

#### Code Breakdown

```assembly
main:
    li          sp,     0x3C00        # Initialize stack pointer
    addi        gp,     sp,     392    # Set global pointer to stack pointer + 392

loop:
    flw         f1,     0(sp)         # Load floating-point number from memory (sp)
    flw         f2,     4(sp)         # Load next floating-point number from memory (sp + 4)
   
    fmul.s      f10,    f1,     f1     # f10 = f1 * f1
    fmul.s      f20,    f2,     f2     # f20 = f2 * f2
    fadd.s      f30,    f10,    f20    # f30 = f10 + f20
    fsqrt.s     f3,     f30            # f3 = sqrt(f30)
    fadd.s      f0,     f0,     f3     # Accumulate result in f0

    addi        sp,     sp,     8      # Increment stack pointer by 8
    blt         sp,     gp,     loop   # Loop until sp < gp
    ebreak                         # End of program
```

#### Functionality

1. **Initialization:**
    - Set the stack pointer (`sp`) to `0x3C00`.
    - Set the global pointer (`gp`) to `sp + 392` (to define the end of the loop).

2. **Loop:**
    - Load two consecutive floating-point numbers from memory.
    - Compute the square of each number and sum them.
    - Compute the square root of the sum (Euclidean norm).
    - Accumulate this result in the floating-point register `f0`.
    - Increment the stack pointer to process the next pair of numbers.
    - Repeat the loop until the stack pointer reaches the global pointer.

3. **Termination:**
    - The program ends with the `ebreak` instruction, causing a breakpoint exception.

#### Notes
- The `fsqrt.s` instruction places the result in the floating-point register `f3`.

This program iterates through a set of floating-point numbers stored in memory, computes their Euclidean norm, and accumulates the results in `f0`.

---
## Square Root Calculation Module

This Verilog module implements a fixed-point square root calculation using a state machine. The design employs an iterative approach to compute the square root of a given operand. Below is a detailed description of the code:

#### Registers and Signals
- **current_operand**: Holds the current value of the operand being processed.
- **approx_root**: Holds the approximate value of the square root being computed.
- **intermediate_result**: Temporary register to store intermediate results during computation.
- **accumulated_root**: Stores the accumulated value of the square root.
- **iteration_count**: Counter to keep track of the number of iterations required for the calculation.
- **operand_copy**: A copy of the input operand used for shifting and extracting bits.
- **next_bits**: Holds the next two most significant bits (MSB) to be processed in each iteration.

#### State Machine States
- **IDLE_STATE**: Initial state where the module waits for the square root operation command.
- **CALC_STATE**: Active state where the module performs the square root calculation.

#### Description of Operation

1. **Reset Condition**
    - When the `reset` signal is high, the state machine is reset to the `IDLE_STATE`. The `root` and `root_ready` signals are also reset, and the input operand is copied to `operand_copy`.

2. **IDLE_STATE**
    - In this state, the module checks if the `operation` signal indicates a square root operation (`FPU_SQRT`). If so, it initializes the values for computation:
        - `current_operand` is initialized with the two MSBs of `operand_1`.
        - `approx_root` is set to `2'b01`.
        - `iteration_count` is set to half of the total width of the operand plus the fractional bits (`(WIDTH + FBITS) >> 1`).
        - The state machine transitions to the `CALC_STATE`.
        - `accumulated_root` is reset to 0.

3. **CALC_STATE**
    - In this state, the module performs the square root calculation iteratively:
        - **Iteration Loop**:
            - **Subtraction Check**: `intermediate_result` is calculated by subtracting `approx_root` from `current_operand`.
            - **Shift and Accumulate**:
                - If `intermediate_result` is negative, `accumulated_root` is shifted left by 1 bit.
                - If `intermediate_result` is non-negative, `accumulated_root` is shifted left and incremented by 1.
            - **Operand Update**:
                - `operand_copy` is shifted left by 2 bits.
                - The next two MSBs are extracted and stored in `next_bits`.
                - `current_operand` is updated by shifting left by 2 bits and adding `next_bits`.
                - `approx_root` is updated by shifting `accumulated_root` left by 2 bits and adding 1.
            - **Iteration Count**:
                - The iteration count is decremented by 1.
                - The loop continues until the iteration count reaches 0.
        - **Final Result**:
            - Once the iterations are complete, the final square root value is stored in `root`.
            - The `root_ready` signal is set to 1, indicating that the result is ready.
            - The state machine transitions back to the `IDLE_STATE`.

#### Conclusion

This module efficiently computes the square root of a fixed-point number using an iterative method and a state machine. It is designed to handle reset conditions and ensures that the result is accurate and ready for use once the calculation is complete.

Certainly! Here's a description for the Verilog modules provided, suitable for inclusion in a readme file:

---

## Multiplier Circuit 
This Verilog module implements a multiplier controller that multiplies two 32-bit operands by breaking them down into smaller 16-bit segments and using a smaller multiplier module. The module handles the multiplication in stages, storing partial products and combining them to produce the final 64-bit product.

#### Inputs
- `clk`: Clock signal for synchronous operations.
- `reset`: Reset signal to initialize all registers.
- `operand_1`: The first 32-bit operand.
- `operand_2`: The second 32-bit operand.
- `operation`: Control signal indicating a multiplication operation.

#### Outputs
- `product`: The 64-bit result of the multiplication.
- `product_ready`: Signal indicating that the product is ready.

#### Internal Registers and Wires
- `product`: Register to hold the final 64-bit product.
- `product_ready`: Register to indicate when the product is ready.
- `caseNum`: Register to keep track of the current state in the state machine.
- `A`, `B`: Registers to hold 16-bit segments of the operands for multiplication.
- `multiplyResult`: Wire to hold the result of the 16-bit multiplication.
- `partialPordact1`, `partialPordact2`, `partialPordact3`, `partialPordact4`: Registers to hold intermediate partial products.

#### State Machine
The state machine controls the steps of the multiplication:
1. **State 0**: Multiply lower 16 bits of both operands.
2. **State 1**: Store partial result and prepare for the next multiplication (upper 16 bits of `operand_1` and lower 16 bits of `operand_2`).
3. **State 2**: Shift and store partial result, prepare for the next multiplication (lower 16 bits of `operand_1` and upper 16 bits of `operand_2`).
4. **State 3**: Shift and store partial result, prepare for the next multiplication (upper 16 bits of both operands).
5. **State 4**: Shift and store the final partial result.
6. **State 5**: Combine all partial products to form the final 64-bit product and set `product_ready` flag.

### Multiplier

The `Multiplier` module is a simple combinational logic module that multiplies two 16-bit numbers.

#### Inputs
- `operand_1`: The first 16-bit operand.
- `operand_2`: The second 16-bit operand.

#### Output
- `product`: The 32-bit result of the multiplication.

### Conclusion

The `MultiplierController` module provides an efficient way to multiply two 32-bit operands by breaking them into smaller segments and combining partial results. This approach is useful for designs where a smaller multiplier unit is available or where resource optimization is needed.

## Result and Waveforms
