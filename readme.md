<p align="center">
  <img src="./docs/src/assets/logo.png" width=20% height=20%>
</p>

# RoundAndSwap


| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][GHA-img]][GHA-url] [![][codecov-img]][codecov-url] |


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://this-josh.github.io/RoundAndSwap.jl/dev/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://this-josh.github.io/RoundAndSwap.jl/dev/

[GHA-img]: https://github.com/this-josh/RoundAndSwap.jl/actions/workflows/runtests.yml/badge.svg
[GHA-url]: https://github.com/this-josh/RoundAndSwap.jl/actions/workflows/runtests.yml

[codecov-img]: https://codecov.io/gh/this-josh/RoundAndSwap.jl/branch/main/graph/badge.svg?token=hfQGPZjl2y
[codecov-url]: https://codecov.io/gh/this-josh/RoundAndSwap.jl


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
