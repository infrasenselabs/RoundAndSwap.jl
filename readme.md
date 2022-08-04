# RoundAndSwap

[![Run tests](https://github.com/this-josh/RoundAndSwap.jl/actions/workflows/runtests.yml/badge.svg)](https://github.com/this-josh/RoundAndSwap.jl/actions/workflows/runtests.yml)

`RoundAndSwap` is a library for implementing the Round and Swap algorithm to try and find an intial solution.

### caveats

* Only choosing 0 and 1 as integer values is supported.

## Quickstart

1.  Create your JuMP model
2.  Solve a linear relaxation of your problem
3.  Fix the desired number of variables to 1
4.  Create an array of variables to consider in the swap - `consider_swapping`
5.  `round_and_swap(model, consider_swapping)`


See the `tests/runtests.jl` for an example of how to use this library.