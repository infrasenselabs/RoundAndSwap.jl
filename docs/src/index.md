# RoundAndSwap.jl

[![Run tests](https://github.com/this-josh/RoundAndSwap.jl/actions/workflows/runtests.yml/badge.svg)](https://github.com/this-josh/RoundAndSwap.jl/actions/workflows/runtests.yml)[![codecov](https://codecov.io/gh/this-josh/RoundAndSwap.jl/branch/main/graph/badge.svg?token=hfQGPZjl2y)](https://codecov.io/gh/this-josh/RoundAndSwap.jl)



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


## Performance

In testing I've done 536 swaps with `round_and_swap` taking 174.1 seconds with 172.8 seconds of that being in the optimizer, giving `RoundAndSwap.jl` an overhead of 0.75%.  


```@contents
Pages = ["nomenclature.md"]
```
## Index
```@index
```
## Functions

```@autodocs
Modules = [RoundAndSwap]
```
