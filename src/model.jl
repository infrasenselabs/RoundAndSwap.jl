
using JuMP

using Ipopt, Gurobi, HiGHS

solver_dict = Dict("Ipopt"=> Ipopt.Optimizer, "Gurobi"=> Gurobi.Optimizer, "HiGHS"=> HiGHS.Optimizer)

"""Allow the getting of multiple variables"""
function Base.getindex(m::JuMP.AbstractModel, names::Array{Symbol})
    return [m[n] for n in names]
end

function successful(model::Model)
    return successful(termination_status(model))
end

function successful(t_stat:: TerminationStatusCode)
    acceptable_status = [OPTIMAL, LOCALLY_SOLVED, ALMOST_OPTIMAL, ALMOST_LOCALLY_SOLVED]
    return (t_stat in acceptable_status) ? true : false
end

function fixed_variables(model::Model, swapper::Swappable)
    return fixed_variables(model, swapper.consider_swapping)
end

function fixed_variables(model::Model, consider_swapping::Array{Symbol})
    return [var for var in consider_swapping if is_fixed(model[var])]
end

function unfix!(variable::VariableRef)
    try
        unfix(variable)
    catch e
        if !is_fixed(variable)
            @debug  "$variable is not fixed"
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

function unfix!(models::Array{Model}, swapper::Swappable)
    for model in models for var in swapper.consider_swapping
        unfix!(model[var])
    end
end
end
    
function fix!(models::Array{Model}, to_fix::Array{Symbol}, value =1 )
    for model in models for var in to_fix
        fix(model[var], value, force=true)
    end
end
end

function make_models(model::Model, multi_thread::Bool, optimizer::Union{Nothing, DataType}=nothing)
    if !multi_thread
        return [model]
    end

    optimizer = !isnothing(optimizer) ? optimizer : solver_dict[solver_name(model)]
    _models = [copy(model) for _ in 1:Threads.nthreads()]
    [MOI.set(_models[ii], MOI.Name(), "Model for thread: $ii") for ii in 1:Threads.nthreads()]
    set_optimizer.(_models, optimizer)
    return _models
end