using JuMP
using HiGHS
using DataFrames
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


swapper= Swapper(initial_swaps(fixed_variables(consider_swapping), consider_swapping),  [a,b,c,d])


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
        create_swaps!(swapper, to_swap)
        try_swapping!(model, swapper)
        better=  [better;evalute_sweep(swapper)...]
    end
end

best_swap(swapper)

# end


# 5 a + 3 b + 5 c + d
