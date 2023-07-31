# ARM_NFP_Calculator
Addition and Multiplication of New-Floating Point numbers (not in IEEE754) using Assembly-ARM-SIM

## Problem Statement and Solution
Let us define our customized floating point number system (called **NFP** => New Floating-Point number) in **32 bits** as follows:

**Sign bit**: most significant bit (0 => the number is positive, 1=> the number is negative)

**2’compliment exponent**: next 12 bits

**Mantissa**: rest 19 bits

All these floating-point numbers are in a normalized format.

The file `Final_SP_NP.s` contains modular code which can leverage the arithmetic operations of Sum and Product to these unique kinds of NFP (New-Floating Point) numbers.

These NFP numbers are NOT in IEEE-754 standardized format.

The code contains two functions namely nfpAdd and nfpMultiply to bring the utility to life.

Also, the data is taken from the memory itself, and the results are also stored in the memory.

Registers are only being used to perform intermediate computations.

## Authors:
[Aashray Gupta](https://github.com/AashrayGupta2003)
