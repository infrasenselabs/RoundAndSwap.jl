using Test
using JuMP
using HiGHS
using RoundAndSwap

function make_model()
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    @variable(model, 0 ≤ a[1:3] ≤ 1)
    @variable(model, 0 ≤ b ≤ 1)
    @variable(model, 0 ≤ c ≤ 1)
    @variable(model, 0 ≤ d ≤ 1)

    @objective(model, Max, (a[1] + b) + (2 * (b + c)) + (3 * (c - d)) + (4 * (d + a[1])))

    @constraint(model, a[1] + b + c + d == 2)

    return model
end
model = make_model()
optimize!(model)
fix(model[:b], 1; force=true)
fix(model[:d], 1; force=true)
a, b, c, d = [model[:a][1]], model[:b], model[:c], model[:d]

consider_swapping = [a[1], b, c, d]
_best_swap, swapper = swap(model, consider_swapping; save_path="swapper_in_loop")

# Test basic run
@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.new == Symbol("a[1]")
@test _best_swap.existing == :b
@test _best_swap.all_fixed == [Symbol("a[1]"), :c]
@test _best_swap.obj_value == 10
@test _best_swap.success == true
@test _best_swap.termination_status == OPTIMAL
@test length(swapper.to_swap) == 0
@test length(swapper.completed_swaps) == 5
@test num_swaps(swapper) == 6

@test_throws OptimizeNotCalled objective_value(model)
reproduce_best!(_best_swap, swapper, model)
@test objective_value(model) == 10

# Test restarting
_, _short_swapper = swap(model, consider_swapping; max_swaps=3)
models = make_models(model, HiGHS.Optimizer)
_short_swapper.max_swaps = Inf
_b, _s = swap(models, _short_swapper)
@test _s == swapper
@test _b[1] == _best_swap

# Sest IO
for f in ("swapper_in_loop.json", "test_swapper.json")
    save(f, swapper)
    _swapper = load_swapper(f)
    @test swapper == _swapper
end

# Test Min
@objective(model, Min, (a[1] + b) + (2 * (b + c)) + (3 * (c - d)) + (4 * (d + a[1])))

@constraint(model, a[1] + b + c + d == 2)

_best_swap, swapper = swap(model, consider_swapping)

@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.new === nothing
@test _best_swap.existing === nothing
@test _best_swap.all_fixed[1] in [:b, :d]
@test _best_swap.all_fixed[2] in [:b, :d]
@test length(_best_swap.all_fixed) == 2
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

# Test max swaps
_best_swap, swapper = swap(model, consider_swapping; max_swaps=2)

# First "swap" is with the initial values
@test num_swaps(swapper) == 3

@constraint(model, a[1] + b + c + d == 1)
_best_swap, swapper = swap(model, consider_swapping)
@test _best_swap === NaN
@test status_codes(swapper) == [INFEASIBLE, INFEASIBLE, INFEASIBLE, INFEASIBLE, INFEASIBLE]

@test model[[:c, :b]] == [c, b]

model = make_model()
@constraint(model, model[:a][1] ≤ 0.9)
optimize!(model)
consider_swapping = [model[:a][1], model[:b], model[:c], model[:d]]
@test reduce_to_consider(consider_swapping,3) == [model[:a][1], model[:b], model[:c]]

@test value(model[:a][1]) == 0.9
@test value(model[:b]) ≈ 0.1

round!(consider_swapping, 2)
optimize!(model)
objective_value(model)

@test fix_value(model[:a][1]) == 1
@test fix_value(model[:c]) == 1

model = make_model()
@constraint(model, model[:a][1] ≤ 0.9)
@constraint(model, model[:c] ≤ 0.9)
optimize!(model)

consider_swapping = [model[:a][1], model[:b], model[:c], model[:d]]
@test_throws ErrorException round!(consider_swapping, 1)
