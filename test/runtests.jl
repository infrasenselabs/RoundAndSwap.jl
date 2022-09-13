using Test
using JuMP
using HiGHS
using RoundAndSwap
using Random
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


# Test restarting
_, _short_swapper = swap(model, consider_swapping; max_swaps=3)
models = make_models(model, HiGHS.Optimizer)
_short_swapper.max_swaps = Inf
_short_swapper._stop = false
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

@test_throws OptimizeNotCalled objective_value(model)
reproduce_best!(_best_swap, swapper, model)
@test objective_value(model) == 4

# Test max swaps
_best_swap, swapper = swap(model, consider_swapping; max_swaps=2)

# First "swap" is with the initial values
@test num_swaps(swapper) == 3

@constraint(model, a[1] + b + c + d == 1)
_best_swap, swapper = swap(model, consider_swapping)
@test _best_swap === NaN
@test status_codes(swapper) == [INFEASIBLE, INFEASIBLE, INFEASIBLE, INFEASIBLE, INFEASIBLE]

@test model[[:c, :b]] == [c, b]

if VERSION >= v"1.7"
    Random.seed!(42)
    _best_swap, swapper = swap(model, consider_swapping; max_swaps=6, shuffle=true)
    expected_swaps =  [[Symbol("a[1]"), :d],nothing,
    [:b, :c],
    [Symbol("a[1]"), :b],
    [:c, :d],
    nothing]
    for (idx,s) in enumerate(swapper.completed_swaps[2])
        @test s.all_fixed == expected_swaps[idx]
    end
end

model = make_model()
@constraint(model, model[:a][1] ≤ 0.9)
optimize!(model)
consider_swapping = [model[:a][1], model[:b], model[:c], model[:d]]
to_consider= consider_swapping
@test reduce_to_consider_number(consider_swapping; num_to_consider=3) == [model[:a][1], model[:b], model[:c]]

@test reduce_to_consider_percentile(consider_swapping; percentile = 90) == [model[:c]]
@test reduce_to_consider_percentile(consider_swapping; percentile = 90, min_to_consider=2) == [model[:a][1], model[:c]]
@test reduce_to_consider_percentile(consider_swapping; percentile = 90, min_to_consider=20) == [model[:a][1], model[:b], model[:c]]


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


function make_model_3()
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    @variable(model, 0 ≤ a[1:3] ≤ 1)
    @variable(model, 0 ≤ b ≤ 1)
    @variable(model, 0 ≤ c ≤ 1)
    @variable(model, 0 ≤ d ≤ 1)
    @variable(model, 0 ≤ e ≤ 1)
    @variable(model, 0 ≤ f ≤ 1)

    @objective(model, Max, 
    (a[1] + b) + (2 * (b + c)) + (3 * (c - d)) + (4 * (d + e))+ (5 * (e + a[1]))
    )

    @constraint(model, a[1] + b + c + d + e == 3)

    return model
end

model = make_model_3()
optimize!(model)
fix(model[:b], 1; force=true)
fix(model[:c], 1; force=true)
fix(model[:d], 1; force=true)
a, b, c, d,e = [model[:a][1]], model[:b], model[:c], model[:d], model[:e]

consider_swapping = [a[1], b, c, d, e]
_best_swap, swapper = swap(model, consider_swapping)

@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.obj_value == 20
@test _best_swap.all_fixed[1] in [Symbol("a[1]"),:c,:e]
@test _best_swap.all_fixed[2] in [Symbol("a[1]"),:c,:e]
@test _best_swap.all_fixed[3] in [Symbol("a[1]"),:c,:e]

function make_model_4()
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    @variable(model, 0 ≤ a[1:3] ≤ 1)
    @variable(model, 0 ≤ b ≤ 1)
    @variable(model, 0 ≤ c ≤ 1)
    @variable(model, 0 ≤ d ≤ 1)
    @variable(model, 0 ≤ e ≤ 1)
    @variable(model, 0 ≤ f ≤ 1)

    @objective(model, Max, 
    (a[1] + b) + (2 * (b + c)) + (3 * (c - d)) + (4 * (d + e))+ (5 * (e + f)+(6 * (f + a[1])))
    )

    @constraint(model, a[1] + b + c + d + e + f == 4)

    return model
end
model = make_model_4()
optimize!(model)
fix(model[:b], 1; force=true)
fix(model[:c], 1; force=true)
fix(model[:d], 1; force=true)
fix(model[:e], 1; force=true)
a, b, c, d,e, f = [model[:a][1]], model[:b], model[:c], model[:d], model[:e], model[:f]

consider_swapping = [a[1], b, c, d, e, f]
_best_swap, swapper = swap(model, consider_swapping)

@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.obj_value == 32
@test _best_swap.all_fixed[1] in [Symbol("a[1]"),:c,:e,:f]
@test _best_swap.all_fixed[2] in [Symbol("a[1]"),:c,:e,:f]
@test _best_swap.all_fixed[3] in [Symbol("a[1]"),:c,:e,:f]
@test _best_swap.all_fixed[4] in [Symbol("a[1]"),:c,:e,:f]
