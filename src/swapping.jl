using JuMP
using ProgressMeter
using Dates
using OnlineStats: Mean, fit!
using Statistics
using Random

"""
    best_swap(swapper::Swapper)

Return the best swap in the swapper
"""
function best_swap(swapper::Swapper)
    return filter(
        x -> x.obj_value == best_objective(swapper), flatten(swapper.completed_swaps)
    )
end

"""
    previously_tried(swapper::Swapper)

Get a list of all previously stried fixed variables in swapper.consider_swapping
"""
function previously_tried(swapper::Swapper)
    return [
        Set(fixed.all_fixed) for
        fixed in flatten(swapper.completed_swaps) if fixed.all_fixed !== nothing
    ]
end

"""
    best_objective(swapper::Swapper)

Get the best objective value in swapper.completed_swaps
"""
function best_objective(swapper::Swapper; ignore_end=false)
    swapper.number_of_swaps == 0 && return NaN
    swaps = ignore_end ? swapper.completed_swaps[1:(end-1)] : swapper.completed_swaps
    objectives = [obj.obj_value for obj in flatten(swaps) if !isnan(obj.obj_value)]
    isempty(objectives) && return NaN
    
    if swapper.sense == MAX_SENSE
        return maximum(objectives)
    else
        return minimum(objectives)
    end
end

"""
    solve!(model, swapper, swap)

Solve this swap

# Arguments:
- `model`: A model object
- `swapper`: The swapper being used
- `swap`: Which swap to solve
"""
function solve!(model, swapper, swap)
    set_cpu_limit(swapper, model)
    optimize!(model)
    swap.termination_status = termination_status(model)
    swap.solve_time = MOI.get(model, MOI.SolveTimeSec())
    swap.success = successful(model)
    swap.obj_value = swap.success ? objective_value(model) : NaN
    return swap.all_fixed = fixed_variables(model, swapper)
end

function swapping_loop!(models, swapper, num_success, num_failed, swaps_complete; shuffle=false)
    p = Progress(length(swapper.to_swap); enabled=SHOW_PROGRESS_BARS)
    shuffle && Random.shuffle!(swapper.to_swap)
    for swap in swapper.to_swap
        model = models[Threads.threadid()]
        swapper.number_of_swaps += 1
        swap.swap_number = swapper.number_of_swaps

        if swapper.number_of_swaps > swapper.max_swaps
            @info "max swaps reached"
            swapper._stop = true
            break
        end
        push!(swaps_complete, swap)
        @debug "Trying swap: $(swap.existing) -> $(swap.new)"
        if is_fixed(get_var(model, swap.new))
            @debug "$(swap.new) already fixed"
            swap.termination_status = Fixed
            continue
        end
        unfix!(get_var(model, swap.existing))
        fix(get_var(model, swap.new), 1; force=true)
        if Set(fixed_variables(model, swapper)) in previously_tried(swapper)
            @debug "swap $swap already done"
            swap.all_fixed = fixed_variables(model, swapper)
            swap.termination_status = AlreadyDone
        else
            solve!(model, swapper, swap)
        end
        if swap.success isa Bool && swap.success
            num_success += 1
            fit!(swapper._successful_run_time, swap.solve_time)
        else
            num_failed += 1
            !isnothing(swap.solve_time) ? fit!(swapper._unsuccessful_run_time, swap.solve_time) : nothing
        end
        unfix!(get_var(model, swap.new))
        fix(get_var(model, swap.existing), 1; force=true)
        ProgressMeter.next!(
            p; showvalues=[(:num_success, num_success), (:num_failed, num_failed)]
        )
    end
end

"""
    try_swapping!(models::Array{Model}, swapper::Swapper)

Given a model and the swapper, try all swaps in swapper.to_swap
"""
function try_swapping!(models::Array{Model}, swapper::Swapper; kwargs...)
    if swapper._stop
        return 
    end
    push!(swapper.completed_swaps, [])
    num_success = 0
    num_failed = 0
    swaps_complete = []
    try
        swapping_loop!(models, swapper, num_success, num_failed, swaps_complete; kwargs...)
    catch err 
        if isa(err, InterruptException)
            swapper._stop = true
            @error "InterruptException, will terminate swaps"
        else
            rethrow(err)
        end
    end 

    swapper.completed_swaps[end] = swaps_complete
    return swapper.to_swap = setdiff(swapper.to_swap, swaps_complete)
end


"""
    initial_swaps(fixed_variables::Array{Symbol}, consider_swapping::Array{Symbol})

Given the initial state, create a list of initial swaps
For all currently fixed, consider_swapping with all variables to consider
wFixed = a
consider = a,b,c,d
Swaps([
    a -> b,
    a -> c,
    a -> d
])

"""
function initial_swaps(fixed_variables::Array{Symbol}, consider_swapping::Array{Symbol})
    # would easily refactor into create swaps
    initial_swaps = []
    # can be one loop
    for currently_fixed in fixed_variables
        for consider in consider_swapping
            if currently_fixed == consider
                continue
            end
            push!(initial_swaps, Swap(; existing=currently_fixed, new=consider))
        end
    end
    return initial_swaps
end

"""
    create_swaps!(swapper::Swapper, to_swap::Array{Symbol})

Given the previously completed swaps, create a list of new swaps
"""
function create_swaps!(swapper::Swapper, to_swap::Array{Symbol})
    for _to_swap in to_swap
        create_swaps!(swapper, _to_swap)
    end
end

"""
    create_swaps!(swapper::Swapper, to_swap::Symbol)

Given the previously completed swaps, create a list of new swaps
"""
function create_swaps!(swapper::Swapper, to_swap::Symbol)
    for to_consider in swapper.consider_swapping
        if to_consider == to_swap
            continue
        end
        _new_swap = Swap(; existing=to_swap, new=to_consider)
        if _new_swap in swapper.completed_swaps
            continue
        end
        push!(swapper.to_swap, _new_swap)
    end
end

"""
    evalute_sweep(swapper::Swapper)

After complete a sweep, find which swaps improved the existing best objective and use this to create new swaps
"""
function evalute_sweep(swapper::Swapper)
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

"""
    swap(model::Model, consider_swapping::Array{VariableRef}; optimizer = nothing, max_swaps = Inf,save_path::Union{Nothing, String}=nothing)

Given a model and a list of variables swap the integer values to improve the objective function

# Arguments:
- `models`: An array of models, one for each thread
- `consider_swapping`: An array of variables to consider swapping
- `optimizer`: A specific optimizer to use, if the desired is not in [Gurobi, Ipopt, HiGHS]
- `max_swaps`: The maximum number of swaps, default is Inf
- `save_path`: A path to save the swapper to after each swap, isnothing(save_path) ?  don't save : save, default is nothing
"""
function swap(
    model::Model,
    consider_swapping::Array{VariableRef};
    optimizer=nothing,
    max_swaps=Inf,
    save_path::Union{Nothing,String}=nothing,
    kwargs...
)
    models = make_models(model, optimizer)
    return swap(models, consider_swapping; max_swaps=max_swaps, save_path=save_path, kwargs...)
end

"""
    swap(models::Vector{Model}, consider_swapping::Vector{VariableRef}; max_swaps = Inf, optimizer = nothing)

Given a model and a list of variables swap the integer values to improve the objective function

# Arguments:
- `models`: An Vector of models, one for each thread
- `consider_swapping`: An Vector of variables to consider swapping
- `max_swaps`: The maximum number of swaps, default is Inf
- `save_path`: A path to save the swapper to after each swap, isnothing(save_path) ?  don't save : save, default is nothing
-  `auto_cpu_limit`: Whether to set a cpu time limie. Once enough feasible and infeasible solutions have been determined if there is sufficient gap in the solve time between the two this will be used to set the cpu time limit.
"""
function swap(
    models::Vector{Model},
    consider_swapping::Vector{VariableRef};
    max_swaps::Real=Inf,
    save_path::Union{Nothing,String}=nothing,
    auto_cpu_limit::Bool=false,
    shuffle::Bool = false,
    kwargs...
)
    if auto_cpu_limit
        @warn "auto_cpu_limit sets a cpu time limit based on completed swaps. It may stop potentially feasible solutions from being found"
    end
    consider_swapping = [Symbol(v) for v in consider_swapping]
    initial_fixed = fixed_variables(models[1], consider_swapping)
    if isempty(initial_fixed)
        error("Some variables in consider_swapping must be fixed initially")
    end
    swapper = Swapper(;
        to_swap=initial_swaps(initial_fixed, consider_swapping),
        consider_swapping=consider_swapping,
        sense=objective_sense(models[1]),
        max_swaps=max_swaps,
        auto_cpu_limit=auto_cpu_limit
    )
    init_swap = Swap(; existing=nothing, new=nothing)

    solve!(models[1], swapper, init_swap)
    push!(swapper.completed_swaps, [])
    swapper.completed_swaps[end] = [init_swap]
    # Try swapping based on initially fixed
    try_swapping!(models, swapper, shuffle = shuffle)
    if length(unsuccessful_swaps(swapper)) == num_swaps(swapper)
        @warn "All initial swaps have failed with the following termination status $(unique(status_codes(swapper))). \n The problem may be infeasible, try to provide a feasible model"
        return NaN, swapper
    end
    return swap(models, swapper; save_path=save_path)
end

"""
    swap(models::Array{Model}, swapper::Swapper)

# Arguments:
- `models`: An array of models, one for each thread
- `swapper`: An already initialised swapper, this can either be clean or it can be partially complete
"""
function swap(
    models::Array{Model}, swapper::Swapper; save_path::Union{Nothing,String}=nothing, kwargs...
)   
    start_time = now()
    # Given swaps which improved initial, try to swap them
    # Only applicable if we are swapping more than one var
    if swapper.max_swaps == num_swaps(swapper)
        @warn (
            "Swapper already at max swaps, if this swapper has previously hit its max swaps this must be reset before resuming. `swapper.max_swaps=Inf`"
        )
    end
    if length(swapper.completed_swaps[1][1].all_fixed) == 1
        @info "only one variable is to consider, have tried all applicable swaps"
    else
        if !isempty(swapper.to_swap)
            @info "Swapper has existing swaps to complete, will do this. Ensure max_swap has been increased"
            try_swapping!(models, swapper)
        end
        sweep_number = 1
        better = evalute_sweep(swapper)
        while !isempty(better) && !swapper._stop
            sweep_number += 1
            @debug "Running sweep $sweep_number"
            bet = pop!(better)
            # set to better scenario
            unfix!(models, swapper)
            fix!(models, bet.all_fixed)
            to_swap =
                bet.all_fixed == [bet.new] ? [bet.new] : setdiff(bet.all_fixed, [bet.new])
            create_swaps!(swapper, to_swap)
            try_swapping!(models, swapper)
            !isnothing(save_path) && save(save_path, swapper)
            better = [better; evalute_sweep(swapper)...]
        end
    end
    run_time = now() - start_time
    @info ("
    Ran for        : $(round(run_time, Dates.Second))
    Optimised for  : $(total_optimisation_time(swapper)) seconds
    Best objective : $(best_objective(swapper))")
    return best_swap(swapper), swapper
end

"""
    reduce_to_consider(to_consider::Array{VariableRef}; num_desired_to_consider::Int)

Only consider the num_desired_to_consider largest values in to consider. Note that to_consider shouldn't be rounded yet.
"""
function reduce_to_consider_number(to_consider::Array{VariableRef}; num_to_consider::Int)
    consider_vals = value.(to_consider)
    thresh = threshold(consider_vals, num_to_consider)
    @assert thresh != 0 "Thresh is zero, you cannot consider this many values"
    idx_to_consider = findall(x -> thresh ≤ x, consider_vals)
    reduced_to_consider = to_consider[idx_to_consider]
	@info "Gone from considering $(length(to_consider)) to $(length(reduced_to_consider)) variables"
    return reduced_to_consider
end

function _values_above_percentile(values::Vector{Float64}, percentile::Real)
    thresh = quantile(values, percentile/100)
    thresh == 0 && @warn "Threshold is zero, consider a higher percentile"
    return findall(x -> thresh ≤ x, values)
end

"""
    reduce_to_consider(to_consider::Array{VariableRef}; percentile::Int)

Only consider the percentile largest values in to consider. Note that to_consider shouldn't be rounded yet.
"""
function reduce_to_consider_percentile(to_consider::Array{VariableRef}; percentile::Real, min_to_consider::Int=0)
    num_variables = length(to_consider)
    consider_vals = value.(to_consider)
    non_zero_idx = consider_vals .> 0
    to_consider = to_consider[non_zero_idx]
    consider_vals = consider_vals[non_zero_idx]
    @show all(consider_vals .== consider_vals[1]) 
    @info "All values are the same, cannot reduce using percentile"
    if all(consider_vals .== consider_vals[1])
         @info "All values are the same, cannot reduce using percentile"
         return to_consider
    end
    while length(_values_above_percentile(consider_vals, percentile))<min_to_consider
        @info "Too few values above percentile $percentile, reducing percentile by 10"
        percentile -= 10
        if percentile < 0
            @warn "Percentile is < 0, you cannot consider this many values you should reduce min_to_consider, for now will return all non-zeros"
            percentile = 0
            break
        end
    end
    idx_to_consider = _values_above_percentile(consider_vals, percentile)
    reduced_to_consider = to_consider[idx_to_consider]
	@info "Gone from considering $(num_variables) to $(length(reduced_to_consider)) variables, note: $(num_variables - length(non_zero_idx)) were removed as they were zero"
    return reduced_to_consider
end