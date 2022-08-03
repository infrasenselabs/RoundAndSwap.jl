using JuMP
using HiGHS
using DataFrames

using PrettyPrinting: best_fit, indent, list_layout, literal, pair_layout, pprint
model = Model(HiGHS.Optimizer)
@variable(model, 0 ≤  a ≤ 1)
@variable(model, 0 ≤  b ≤ 1)
@variable(model, 0 ≤  c ≤ 1)
@variable(model, 0 ≤  d ≤ 1)

@objective(model, Max, (a+b)+(2*(b+c))+(3*(c-d))+(4*(d+a)))

@constraint(model, a+b+c+d ≤ 2)

fix(model[:b], 1, force=true)
fix(model[:d], 1, force=true)

struct ReplaceExisting
    existing::VariableRef
    new::VariableRef
end

function flatten(to_flatten)
    return collect(Iterators.flatten(to_flatten))
end

mutable struct Swap
    existing::VariableRef
    new::VariableRef
    obj_value::Real
    success::Union{Bool, Nothing}
    all_fixed::Union{Array{VariableRef}, Nothing}
    termination_status
    solve_time
    Swap(existing::VariableRef, new::VariableRef) = new(existing, new, NaN, nothing, nothing, nothing,nothing)
end

function Base.:(==)(a::Swap, b::Swap)
return a.existing == b.existing && a.new == b.new
end


struct BestResult
    obj_val
    fixed_vars
end

mutable struct Swappable
    to_swap::Array{Swap}
    current_best::Array{BestResult}
    consider_swapping
    completed_swaps
    Swappable(to_swap, current_best::BestResult,to_swap_with) = new(to_swap, [current_best], to_swap_with, [])
    Swappable(to_swap, current_best::Array{BestResult},to_swap_with) = new(to_swap, current_best, to_swap_with, [])
end

function _all_but_swapped(s::Swappable)
    ret_val = literal("Swappable:") * literal("\n") *
    indent(4) * literal("To swap      -> ") * list_layout(tile.(s.to_swap)) * literal("\n") *
    indent(4) * literal("Current best -> ") * list_layout(tile.(s.current_best)) *  literal("\n") *
    indent(4) * literal("To swap with -> ") * list_layout(tile.(s.to_swap_with)) * literal("\n");
    return ret_val;
end

tile(s::Swappable) = 
    if isempty(s.swapped)
        _all_but_swapped(s);
    else
        _all_but_swapped(s) * indent(4) * literal("Swapped      -> ") * list_layout(tile.(s.swapped)) 
    end

Base.show(io::IO,::MIME"text/plain", s::Swappable) = pprint(s)


function best_objective(swapper::Swappable)
    objectives = [obj.obj_value for obj in flatten(swapper.completed_swaps) if !isnan(obj.obj_value)]
    # All objectives should be equally best
    # @assert all(objectives .== objectives[1])
    return maximum(objectives)
end

function best_swap(swapper::Swappable)
    filter(x-> x.obj_value == best_objective(swapper), flatten(swapper.completed_swaps))
end

function next!(swapper::Swappable)
    if !isempty(swapper.to_swap)
        next_val = pop!(swapper.to_swap)
        push!(swapper.swapped, next_val)
        return next_val
    else
        @info "done"
    end
end

function successful(model::Model)
    acceptable_status = [OPTIMAL, LOCALLY_SOLVED, ALMOST_OPTIMAL, ALMOST_LOCALLY_SOLVED]
    return (termination_status(model) in acceptable_status) ? true : false
end

function fixed_variables(model::Model)
    return [var for var in values(model.obj_dict) if is_fixed(var)]
end

function unfix!(variable)
    try
        unfix(variable)
    catch e
        if !is_fixed(variable)
            @info  "$variable is not fixed"
        else
            throw(error(e))
        end
    end
	set_lower_bound(variable, 0)
	set_upper_bound(variable, 1)
end

function unfix!(swapper::Swappable)
    for var in swapper.consider_swapping
        unfix!(var)
    end
end

function try_swapping!(model::Model,swapper::Swappable, to_unfix::ReplaceExisting, results::DataFrame)
    unfix!(to_unfix.existing)
    fix(to_unfix.new, 1, force=true)
	try_swapping!(model, swapper,to_unfix.new,results)
    unfix!(to_unfix.new)
    fix(to_unfix.existing, 1, force=true)
end

function previously_tried(swapper::Swappable)
    [fixed.all_fixed for fixed in flatten(swapper.completed_swaps)]
end


function try_swapping!(model::Model,swapper::Swappable)
    push!(swapper.completed_swaps,[])
    for swap in swapper.to_swap
        @info "Trying swap: $(swap.existing) -> $(swap.new)" 
        if is_fixed(swap.new)
            @info "$(swap.new) already fixed"
            swap.termination_status = "fixed"
            continue
        end
        unfix!(swap.existing)
        fix(swap.new, 1, force=true)
        if fixed_variables(model) in previously_tried(swapper)
            @info "swap $swap already done"
            swap.termination_status = "already_done"
        else
            optimize!(model)
            swap.termination_status = termination_status(model)
            swap.solve_time = MOI.get(model, MOI.SolveTimeSec())
            swap.success = successful(model)
            swap.obj_value = swap.success ? objective_value(model) : NaN 
            swap.all_fixed = fixed_variables(model)
        end
        unfix!(swap.new)
        fix(swap.existing, 1, force=true)
    end
    swapper.completed_swaps[end] = swapper.to_swap
    swapper.to_swap = []
end

function remove_worse_best!(swapper::Swappable)
    swapper.current_best = [best for best in swapper.current_best if best.obj_val ≥ best_objective(swapper)]
end

function anything_better!(results, swapper, to_unfix::ReplaceExisting)
    anything_better!(results, swapper, to_unfix.new)
end

function anything_better!(results, swapper::Swappable, to_unfix::VariableRef)
    these_results = filter(x-> x.unfixed == to_unfix, results)
    #! sign needs to change based on model sense
	better_results = filter(x-> x.obj_val ≥ best_objective(swapper), these_results)
    if !isempty(better_results)
        swapper.current_best = [swapper.current_best; [BestResult(x.obj_val, x.fixed_vars) for x in eachrow(better_results)]]
        remove_worse_best!(swapper)
        to_add = [ReplaceExisting(to_unfix,new) for new in better_results.new_fix]
        swapper.to_swap = [swapper.to_swap; to_add]
    else
        @info "Nothing better"
    end
end

function Base.isequal(a::Swap, b::Swap)
    return a.existing == b.existing && a.new == b.new
end

function initial_swaps(to_swap::Array{VariableRef}, to_swap_with::Array{VariableRef})
    initial_swaps = []
    # can be one loop
    for existing in to_swap
        for new in to_swap_with
            if existing == new
                continue
            end
            push!(initial_swaps, Swap(existing, new))
        end
    end
    return initial_swaps
end

function create_swaps(swapper, to_swap)
    for to_consider in swapper.consider_swapping
        if to_consider == to_swap
            continue
        end
        _new_swap = Swap(to_swap, to_consider)
        if _new_swap in swapper.completed_swaps
            continue
        end
        push!(swapper.to_swap, _new_swap)
    end

end

function evalute_sweep(swapper)
    current_best = best_objective(swapper)
    to_swap = []
    for swap in swapper.completed_swaps[end]
        if swap.obj_value ≥ current_best
            push!(to_swap, swap)
        end
    end
    return to_swap
end



optimize!(model)
current= BestResult(objective_value(model), [b,d])
consider_swapping = [a,b,c,d]


swapper= Swappable(initial_swaps(current.fixed_vars, consider_swapping), current, [a,b,c,d])


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

    swapper

# end


# 5 a + 3 b + 5 c + d
