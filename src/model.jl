
using JuMP

using Ipopt, Gurobi, HiGHS

solver_dict = Dict("Ipopt"=> Ipopt.Optimizer, "Gurobi"=> Gurobi.Optimizer, "HiGHS"=> HiGHS.Optimizer)

"""Allow the getting of multiple variables"""
function Base.getindex(m::JuMP.AbstractModel, names::Array{Symbol})
    return [m[n] for n in names]
end

function get_var(m::JuMP.AbstractModel, name::Symbol)
    try
        return JuMP.getindex(m,name)
    catch e
        var_name=Symbol(match(r"^\w+", String(name)).match)
        var = JuMP.getindex(m,var_name)
        var_num=parse(Int,(match(r"\d+", String(name)).match))
        return var[var_num]
    end
end
function successful(model::Model)
    return successful(termination_status(model))
end

function successful(t_stat:: TerminationStatusCode)
    acceptable_status = [OPTIMAL, LOCALLY_SOLVED, ALMOST_OPTIMAL, ALMOST_LOCALLY_SOLVED]
    return (t_stat in acceptable_status) ? true : false
end

function fixed_variables(model::Model, swapper::Swapper)
    return fixed_variables(model, swapper.consider_swapping)
end

function fixed_variables(model::Model, consider_swapping::Array{Symbol})
    return [var for var in consider_swapping if is_fixed(get_var(model,var))]
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

function unfix!(models::Array{Model}, swapper::Swapper)
    for model in models for var in swapper.consider_swapping
        unfix!(get_var(model,var))
    end
end
end
    
function fix!(models::Array{Model}, to_fix::Array{Symbol}, value =1 )
    for model in models for var in to_fix
        fix(get_var(model, var), value, force=true)
    end
end
end

function make_models(model::Model, optimizer::Union{Nothing, DataType}=nothing)
    optimizer = !isnothing(optimizer) ? optimizer : solver_dict[solver_name(model)]
    _models = [copy(model) for _ in 1:Threads.nthreads()]
    [MOI.set(_models[ii], MOI.Name(), "Model for thread: $ii") for ii in 1:Threads.nthreads()]
    set_optimizer.(_models, optimizer)
    return _models
end