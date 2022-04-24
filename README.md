# TL;DR
This repo slices the official HPCC code into its composing benchmarks such that they can be run individually.

# How to build and run
Simply invoke `make` to build the standalone binaries (hpl, lat\_bw, mpi\_fft, etc.) in the top-level directory.
To build a single binary, you can `make <binary_name>`.
To run a single binary, you can `make run-<binary_name>`.

# Motivation
According to its [website](https://icl.utk.edu/hpcc/), the HPC Challenge (HPCC) suite measures a range memory access patterns and consists of seven benchmarks: HPL, DGEMM, STREAM, PTRANS, RandomAccess, FFT, and Communication bandwidth and latency. Strangely, the suite links all these benchmarks into a single, monolithic executable that runs them one by one: see [this question](https://icl.utk.edu/hpcc/faq/index.html#323) from the HPCC FAQ:

> How do I run individual tests in HPCC?
> 
> HPCC has not been designed for running invidual tests. Quite the opposite. It's a harness that ties multiple tests together. Having said that, it is possible to comment out calls to individual tests in src/hpcc.c

Commenting out/in code is inconvenient, so we use the HPCC library to build multiple executables, one per benchmark. This repo borrows most of its code from src/hpcc.c in the official HPCC repo.

