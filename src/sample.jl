using JuMP
using HiGHS
using DataFrames

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

struct BestResult
    obj_val
    fixed_vars
end


using PrettyPrinting: best_fit, indent, list_layout, literal, pair_layout

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

mutable struct Swappable
    to_swap
    current_best::Array{BestResult}
    to_swap_with
    swapped
    Swappable(to_swap, current_best::BestResult,to_swap_with) = new(to_swap, [current_best], to_swap_with, [])
    Swappable(to_swap, current_best::Array{BestResult},to_swap_with) = new(to_swap, current_best, to_swap_with, [])
end

function best_objective(swapper::Swappable)
    objectives = [obj.obj_val for obj in swapper.current_best]
    # All objectives should be equally best
    # @assert all(objectives .== objectives[1])
    return maximum(objectives)
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

function create_results_df()
	return DataFrame(t_stat=[], obj_val=[], unfixed=[], new_fix = [], solve_time = [], success=[], fixed_vars = [])
end

function try_swapping!(model::Model,swapper::Swappable, to_unfix::ReplaceExisting, results::DataFrame)
    unfix!(to_unfix.existing)
    fix(to_unfix.new, 1, force=true)
	try_swapping!(model, swapper,to_unfix.new,results)
    unfix!(to_unfix.new)
    fix(to_unfix.existing, 1, force=true)
end


function try_swapping!(model::Model,swapper::Swappable, to_unfix::VariableRef, results::DataFrame)
    unfix!(to_unfix)
    for new_fix in swapper.to_swap_with
        @info "Trying $new_fix"
        if new_fix == to_unfix || is_fixed(new_fix)
            @info "Skipping $new_fix"
            continue
        end
        fix(new_fix, 1, force=true)
        optimize!(model)
        t_stat = termination_status(model)
        solve_time = MOI.get(model, MOI.SolveTimeSec())
        success = successful(model)
        obj_val = success ? objective_value(model) : NaN 
        push!(results,[t_stat, obj_val, to_unfix, new_fix, solve_time, success, fixed_variables(model)])
        unfix!(new_fix)
    end
    fix(to_unfix, 1, force=true)
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

results = create_results_df()
optimize!(model)
current= BestResult(objective_value(model), [b,d])

swapper= Swappable(current.fixed_vars, current, [a,b,c,d])

# for _ in 1:5
    next_val = next!(swapper)
    to_unfix= next_val
    try_swapping!(model, swapper, next_val, results)
    anything_better!(results, swapper, to_unfix)
    swapper

# end


# 5 a + 3 b + 5 c + d
