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

@constraint(model, a+b+c+d ≤ 2)

fix(model[:b], 1, force=true)
fix(model[:d], 1, force=true)



optimize!(model)
consider_swapping = [a,b,c,d]


swapper= Swappable(initial_swaps(fixed_variables(model), consider_swapping),  [a,b,c,d])


for _ in 1:1
    try_swapping!(model, swapper)
    better = evalute_sweep(swapper)
    while !isempty(better)
        bet = pop!(better)
        # set to better scenario
        unfix!(swapper)
        fix.(bet.all_fixed, 1, force=true)
        to_swap = setdiff(bet.all_fixed, [bet.new])
        to_swap = to_swap[1]
        #* for var in to_swap
        create_swaps(swapper, to_swap)
        try_swapping!(model, swapper)
        better=  [better;evalute_sweep(swapper)...]
    end
end

_best_swap = best_swap(swapper)
@test length(_best_swap) == 1
_best_swap = _best_swap[1]
@test _best_swap.new == a
@test _best_swap.existing == b
@test _best_swap.obj_value == 10
@test _best_swap.success == true
@test _best_swap.termination_status == OPTIMAL
@test length(swapper.to_swap) == 0
@test length(swapper.completed_swaps) == 4
@test length(flatten(swapper.completed_swaps)) == 15


