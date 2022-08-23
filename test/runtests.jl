using Test
using JuMP
using HiGHS
using RoundAndSwap

model = Model(HiGHS.Optimizer)
set_silent(model)
@variable(model, 0 ≤  a[1:3] ≤ 1)
@variable(model, 0 ≤  b ≤ 1)
@variable(model, 0 ≤  c ≤ 1)
@variable(model, 0 ≤  d ≤ 1)

@objective(model, Max, (a[1]+b)+(2*(b+c))+(3*(c-d))+(4*(d+a[1])))

@constraint(model, a[1]+b+c+d == 2)

fix(model[:b], 1, force=true)
fix(model[:d], 1, force=true)


optimize!(model)

consider_swapping = [a[1],b,c,d]
_best_swap, swapper = round_and_swap(model, consider_swapping)

@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.new == Symbol("a[1]")
@test _best_swap.existing == :b
@test _best_swap.all_fixed == [Symbol("a[1]"),:c]
@test _best_swap.obj_value == 10
@test _best_swap.success == true
@test _best_swap.termination_status == OPTIMAL
@test length(swapper.to_swap) == 0
@test length(swapper.completed_swaps) == 5
@test num_swaps(swapper) == 6

# Test restarting
_, _short_swapper = round_and_swap(model, consider_swapping, max_swaps=3)
models = make_models(model, HiGHS.Optimizer)
_short_swapper.max_swaps = Inf
_b, _s = round_and_swap(models, _short_swapper)
@test _s == swapper
@test _b[1] == _best_swap

save("test_swapper.json", swapper)
_swapper = load_swapper("test_swapper.json")
@test swapper == _swapper


@objective(model, Min, (a[1]+b)+(2*(b+c))+(3*(c-d))+(4*(d+a[1])))

@constraint(model, a[1]+b+c+d == 2)

_best_swap, swapper = round_and_swap(model, consider_swapping)

@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.new === nothing
@test _best_swap.existing === nothing
@test _best_swap.all_fixed[1] in [:b,:d]
@test _best_swap.all_fixed[2] in [:b,:d]
@test length(_best_swap.all_fixed) ==2
@test _best_swap.obj_value == 4
@test _best_swap.success == true
@test _best_swap.termination_status == OPTIMAL
@test length(swapper.to_swap) == 0
@test length(swapper.completed_swaps) == 2
@test num_swaps(swapper) == 5
@test swapper.completed_swaps[1] == swapper.completed_swaps[1]
@test length(successful_swaps(swapper)) == 5
@test length(unsuccessful_swaps(swapper)) == 0
# Print functions, check they don't error
@test total_optimisation_time(swapper) < 0.1


_best_swap, swapper = round_and_swap(model, consider_swapping, max_swaps = 2)

# First "swap" is with the initial values
@test num_swaps(swapper) == 3

@constraint(model, a[1]+b+c+d == 1)
_best_swap, swapper = round_and_swap(model, consider_swapping)
@test _best_swap === NaN
@test status_codes(swapper) == [INFEASIBLE, INFEASIBLE, INFEASIBLE, INFEASIBLE, INFEASIBLE]


@test model[[:c,:b]] == [c, b]