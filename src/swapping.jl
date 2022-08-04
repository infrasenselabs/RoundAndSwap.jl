using JuMP
using ProgressMeter

function best_swap(swapper::Swappable)
    filter(x-> x.obj_value == best_objective(swapper), flatten(swapper.completed_swaps))
end

function previously_tried(swapper::Swappable)
    [fixed.all_fixed for fixed in flatten(swapper.completed_swaps)]
end

function best_objective(swapper::Swappable)
    objectives = [obj.obj_value for obj in flatten(swapper.completed_swaps) if !isnan(obj.obj_value)]
    if swapper.sense == MAX_SENSE
        return maximum(objectives)
    else
        return minimum(objectives)
    end
end
function solve!(model, swapper, swap)
    optimize!(model)
    swap.termination_status = termination_status(model)
    swap.solve_time = MOI.get(model, MOI.SolveTimeSec())
    swap.success = successful(model)
    swap.obj_value = swap.success ? objective_value(model) : NaN 
    swap.all_fixed = fixed_variables(swapper)
end


function try_swapping!(model::Model,swapper::Swappable)
    push!(swapper.completed_swaps,[])
    p = Progress(length(swapper.to_swap))
    num_success = 0
    num_failed = 0
    for swap in swapper.to_swap
        @debug "Trying swap: $(swap.existing) -> $(swap.new)" 
        if is_fixed(swap.new)
            @debug "$(swap.new) already fixed"
            swap.termination_status = "fixed"
            continue
        end
        unfix!(swap.existing)
        fix(swap.new, 1, force=true)
        if fixed_variables(swapper) in previously_tried(swapper)
            @debug "swap $swap already done"
            swap.termination_status = "already_done"
        else
            solve!(model, swapper, swap)
        end
        if swap.success isa Bool && swap.success
            num_success += 1
        else
            num_failed += 1
        end
        unfix!(swap.new)
        fix(swap.existing, 1, force=true)
        ProgressMeter.next!(p; showvalues = [(:num_success,num_success),(:num_failed,num_failed)])
    end
    swapper.completed_swaps[end] = swapper.to_swap
    swapper.to_swap = []
end



function initial_swaps(to_swap::Array{VariableRef}, to_swap_with::Array{VariableRef})
    # would easily refactor into create swaps
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

function create_swaps(swapper::Swappable, to_swap::VariableRef)
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

function evalute_sweep(swapper::Swappable)
    current_best = best_objective(swapper)
    to_swap = []
    for swap in swapper.completed_swaps[end]
        if swapper.sense == MAX_SENSE && swap.obj_value ≥ current_best
            push!(to_swap, swap)
        elseif swapper.sense == MIN_SENSE && swap.obj_value ≤ current_best
            push!(to_swap, swap)
        end
    end
    return to_swap
end

function round_and_swap(model::Model, consider_swapping::Array{VariableRef})
    swapper= Swappable(initial_swaps(fixed_variables(consider_swapping), consider_swapping),  consider_swapping, model)
    init_swap = Swap(nothing, nothing)
    solve!(model, swapper, init_swap)
    push!(swapper.completed_swaps,[])
    swapper.completed_swaps[end] = [init_swap]
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

    return best_swap(swapper), swapper
end
