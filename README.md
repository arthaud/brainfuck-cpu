# Brainfuck CPU

This is an experiment where I suppose we are in a world where we only have:
* a **CPU** able to run **Brainfuck code**
* a **text editor**

For information, Brainfuck is a [minimalism esoteric programming language](https://en.wikipedia.org/wiki/Brainfuck), but still [Turing-complete](https://en.wikipedia.org/wiki/Turing-complete).

## Brainfuck interpreter and compiler

`bf.py` is the Brainfuck interpreter and compiler available.

You can execute a Brainfuck source code by running `./bf.py code.bf`
Using the compiler (option `-c`) is a way to make the code faster (it uses gcc or clang with flag `-O3`).

Notes: cells are 8-bit and the special character EOF is 0xff (255).
You can use any Brainfuck compiler meeting these criteria.

For more details, run `./bf.py -h`

## Plan

For now, my goal is to be able to run C code on that CPU, because C is the most commonly used programming language.

I think the best idea is to start by creating a virtual machine able to run a higher level language,
such as a [RISC](https://en.wikipedia.org/wiki/Reduced_instruction_set_computing) Assembly
language. Indeed, Brainfuck is way to low level: I want to be able to handle pointers, but there is no easy way in Brainfuck to get the byte at a specific address.
That's why I'm building a virtual machine with an infinite table acting as a Random-access memory,
based on the idea of INSHAME: [Memory efficient Brainfuck tables](http://www.inshame.com/2008/02/efficient-brainfuck-tables.html).
The virtual machine will use the [Von Neumann architecture](https://en.wikipedia.org/wiki/Von_Neumann_architecture), putting the program and data in the same memory.

### Brainfuck virtual machine

I am currently working on a virtual machine written in Brainfuck and able to run
a simple assembly language.
