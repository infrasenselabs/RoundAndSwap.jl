using Test

using JuMP
using HiGHS
using RoundAndSwap

model = Model(HiGHS.Optimizer)
@variable(model, 0 ≤  a ≤ 1)
@variable(model, 0 ≤  b ≤ 1)
@variable(model, 0 ≤  c ≤ 1)
@variable(model, 0 ≤  d ≤ 1)

@objective(model, Max, (a+b)+(2*(b+c))+(3*(c-d))+(4*(d+a)))

@constraint(model, a+b+c+d == 2)

fix(model[:b], 1, force=true)
fix(model[:d], 1, force=true)


optimize!(model)

consider_swapping = [a,b,c,d]
_best_swap, swapper = round_and_swap(model, consider_swapping)

@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.new == a
@test _best_swap.existing == b
@test _best_swap.all_fixed == [a,c]
@test _best_swap.obj_value == 10
@test _best_swap.success == true
@test _best_swap.termination_status == OPTIMAL
@test length(swapper.to_swap) == 0
@test length(swapper.completed_swaps) == 5
@test length(flatten(swapper.completed_swaps)) == 16


@objective(model, Min, (a+b)+(2*(b+c))+(3*(c-d))+(4*(d+a)))

@constraint(model, a+b+c+d == 2)

_best_swap, swapper = round_and_swap(model, consider_swapping)

@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.new == d
@test _best_swap.existing == a
@test _best_swap.all_fixed[1] in [b,d]
@test _best_swap.all_fixed[2] in [b,d]
@test length(_best_swap.all_fixed) ==2
@test _best_swap.obj_value == 4
@test _best_swap.success == true
@test _best_swap.termination_status == OPTIMAL
@test length(swapper.to_swap) == 0
@test length(swapper.completed_swaps) == 3
@test length(flatten(swapper.completed_swaps)) == 10
