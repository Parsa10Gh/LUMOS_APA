
# Computer Organization Project Spring_2024

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

#  Multiplier and Square Root Circuit

This Verilog module implements both an enhanced multiplier circuit and a square root circuit designed for a floating point unit (FPU). It performs 32-bit floating point multiplication and square root operations using a pipelined approach.

## Module Overview

### Inputs
- **clk**: Clock signal
- **operand_1**: First operand (32-bit)
- **operand_2**: Second operand (32-bit)
- **operation**: Control signal to determine the operation (e.g., multiplication or square root)

### Outputs
- **product**: Output product from the multiplication circuit (64-bit)
- **product_ready**: Flag to indicate the completion of the multiplication
- **root**: Output result from the square root circuit (32-bit)
- **root_ready**: Flag to indicate the completion of the square root computation

## Multiplier Circuit

The multiplier circuit performs 32-bit multiplication using partial products. It breaks down the multiplication into four stages, each producing a partial product. The final product is computed by combining these partial products.

### Stages of Multiplication
1. **Stage 1**: Multiply the lower 16 bits of both operands.
2. **Stage 2**: Multiply the upper 16 bits of `operand_1` and the lower 16 bits of `operand_2`.
3. **Stage 3**: Multiply the lower 16 bits of `operand_1` and the upper 16 bits of `operand_2`.
4. **Stage 4**: Multiply the upper 16 bits of both operands.
5. **Stage 5**: Combine all partial products to form the final 64-bit product.

### Key Registers and Signals
- **mul_input_1, mul_input_2**: 16-bit registers to hold the partial inputs for the multiplier.
- **mul_output**: 32-bit wire to hold the result of the partial multiplication.
- **part_prod1, part_prod2, part_prod3, part_prod4**: 32-bit registers to hold the partial products.
- **mul_stage, next_mul_stage**: 3-bit registers to keep track of the current and next stages of multiplication.

## Square Root Circuit

The square root circuit computes the square root of a 32-bit operand using an iterative approach. The algorithm is based on the non-restoring division method.

### Stages of Square Root Computation
1. **Stage 1**: Initialize the square root computation.
2. **Stage 2**: Start the square root computation.
3. **Stage 3**: Continue the square root computation until completion.

### Key Registers and Signals
- **sqrt_stage, next_sqrt_stage**: 2-bit registers to keep track of the current and next stages of the square root computation.
- **sqrt_init**: Flag to indicate the initialization of the square root computation.
- **sqrt_active**: Flag to indicate if the square root computation is active.
- **dividend, dividend_next**: Registers to hold the current and next values of the dividend.
- **quotient, quotient_next**: Registers to hold the current and next values of the quotient.
- **accumulator, accumulator_next**: Registers to hold the current and next values of the accumulator.
- **test_result**: Register to hold the test result during the computation.
- **iteration**: Counter to track the number of iterations.

This module provides a robust and efficient solution for performing 32-bit multiplication and square root operations in hardware, making it suitable for integration into larger floating point units and other digital signal processing systems.


This module provides a robust and efficient solution for performin
## Result and Waveforms
![Waveform1](https://raw.githubusercontent.com/Parsa10Gh/LUMOS_APA/main/Images/Waveform1.png)
![Waveform2](https://raw.githubusercontent.com/Parsa10Gh/LUMOS_APA/main/Images/Waveform2.png)
![Waveform3](https://raw.githubusercontent.com/Parsa10Gh/LUMOS_APA/main/Images/Waveform3.png)
![Waveform4](https://raw.githubusercontent.com/Parsa10Gh/LUMOS_APA/main/Images/Waveform4.png)