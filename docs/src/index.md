# RoundAndSwap.jl

[![Run tests](https://github.com/this-josh/RoundAndSwap.jl/actions/workflows/runtests.yml/badge.svg)](https://github.com/this-josh/RoundAndSwap.jl/actions/workflows/runtests.yml)[![codecov](https://codecov.io/gh/this-josh/RoundAndSwap.jl/branch/main/graph/badge.svg?token=hfQGPZjl2y)](https://codecov.io/gh/this-josh/RoundAndSwap.jl)



`RoundAndSwap.jl` is a library for implementing the Round and Swap algorithm to try and find an intial solution.


## Getting started

1.  Create your JuMP model, and optimize
```julia
# Define how many variables you want fixed
num_to_fix = 2

using JuMP, HiGHS
model = Model(HiGHS.Optimizer)
@variable(model, 0 ≤ a ≤ 1)
@variable(model, 0 ≤ b ≤ 1)
@variable(model, 0 ≤ c ≤ 1)
@variable(model, 0 ≤ d ≤ 1)
@constraint(model, a + b + c + d == num_to_fix)
@objective(model, Max, (a + b) + (2 * (b + c)) + (3 * (c - d)) + (4 * (d + a)))

# To demonstate functionality we will fix b and d
fix(b, 0.8; force=true)
fix(d, 0.8; force=true)

optimize!(model)
```
2. Identify which variable we are considering making `1`
```julia
consider_swapping = [a,b,c,d]
```

3. Round variables closest to `1`, this will be b and d as we fixed them at `0.8`.
```julia
using RoundAndSwap
round!(consider_swapping, num_to_fix)
```
4. Begin swapping
```julia
best_swap, swapper = swap(model, consider_swapping)
```
5. Review your best swap
```julia
julia> best_swap
1-element Vector{Swap}:
 Swap 
    existing:           b
    new:                a
    obj_value:          10.0          
    success:            true            
    all_fixed:          [:a, :c]          
    termination_status: OPTIMAL 
    solve_time:         0.0004438320000872409
    swap_number:        7
```
As you can see in this case we found the globally optimal solution of 10.
 *Note:* Round and Swap does not provide guarantees of global optimility.

### caveats

* Currently can only set variables to `0` or `1`.

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
