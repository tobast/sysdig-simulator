# sysdig-simulator
Simulator of a digital system using net-list for the L3 class project &lt;http://www.di.ens.fr/~bourke/sysdig.html&gt;

Goals
===

This project aims to provide a net-list to C++ compiler, in order to be as optimized as possible, allowing the user to compile their net-list files with any C++ compiler (eg. g++) to achieve high performance.

The input files should be formatted as described in http://www.di.ens.fr/~bourke/minijazz.pdf. This compiler uses the OCaml interface provided by http://www.di.ens.fr/~bourke/minijazz.zip.

The generated program should read through stdin (to allow easy piping) a number of cycles to run, and its input states at each cycle. It should output on stdout at the end of *each* cycle its output pins states, to allow piping to a frontend in real time.


Detailed I/O format of the compiled output
===

*WARNING!* The input format *might* still change while this compiler is being developped.

Stdin
---

Stdin should consist of N+1 lines of plain text, where

* The first line contains a single integer N > 0, the number of cycles to run,
* The N following lines consists of K characters '0' or '1' to denote a LOW or HIGH input pin, in the order the input pins were declared in the net-list. K denotes the number of input pins. If some inputs are bit arrays, those are handled as if each wire of the bit array was a distinct input, starting from a[0] to a[size-1].

Yet, if there is no input pin at all, *only the first line is expected* to avoid passing a lot of useless \n. Passing those \n is still accepted.

Stdout
---

Stdout will consist of N lines of plain text, each one generated just after a cycle was executed.

Each line consists of K' characters '0' or '1' to denote a LOW or HIGH output pin, in the order the output pins were declared in the net-list. K' denotes the number of output pins. If some outputs are bit arrays, those are outputted bit by bit, starting from a[0] to a[size-1].
