
using JuMP

using Ipopt, Gurobi, HiGHS

solver_dict = Dict("Ipopt"=> Ipopt.Optimizer, "Gurobi"=> Gurobi.Optimizer, "HiGHS"=> HiGHS.Optimizer)

"""
    Base.getindex(m::JuMP.AbstractModel, names::Array{Symbol})

Allow the getting of multiple variables
"""
function Base.getindex(m::JuMP.AbstractModel, names::Array{Symbol})
    return [m[n] for n in names]
end

"""
    get_var(m::JuMP.AbstractModel, name::Symbol)

Get a variable, if the symbol fails try getting it from an array of variables
"""
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
"""
    successful(model::Model)

Determine if a model was succesful
"""
function successful(model::Model)
    return successful(termination_status(model))
end

"""
    successful(t_stat::TerminationStatusCode)

Determine if a model was succesful
"""
function successful(t_stat:: TerminationStatusCode)
    acceptable_status = [OPTIMAL, LOCALLY_SOLVED, ALMOST_OPTIMAL, ALMOST_LOCALLY_SOLVED]
    return (t_stat in acceptable_status) ? true : false
end

"""
    fixed_variables(model::Model, swapper::Swapper)

Find which variables in consider swapping are fixed
"""
function fixed_variables(model::Model, swapper::Swapper)
    return fixed_variables(model, swapper.consider_swapping)
end

"""
    fixed_variables(model::Model, consider_swapping::Array{Symbol})

Find which variables in consider swapping are fixed
"""
function fixed_variables(model::Model, consider_swapping::Array{Symbol})
    return [var for var in consider_swapping if is_fixed(get_var(model,var))]
end

"""
    unfix!(variable::VariableRef)

unfix! a variable are reset 0 and 1 as lower and upper bounds
"""
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

"""
    unfix!(models::Array{Model}, swapper::Swapper)

Unfix all variables in consider swapping
"""
function unfix!(models::Array{Model}, swapper::Swapper)
    for model in models for var in swapper.consider_swapping
        unfix!(get_var(model,var))
    end
end
end
    
"""
    fix!(models::Array{Model}, to_fix::Array{Symbol}, value = 1)

For each model, fix all variables in to_fix to 1 

# Arguments:
- `models`: Models to fix values
- `to_fix`: Variables to fix
- `value`: Value to fix to, by default 1
"""
function fix!(models::Array{Model}, to_fix::Array{Symbol}, value =1 )
    for model in models for var in to_fix
        fix(get_var(model, var), value, force=true)
    end
end
end

"""
    make_models(model::Model, optimizer::Union{Nothing, DataType} = nothing)

Given a single model, make enough models to have one for each thread

# Arguments:
- `optimizer`: Optimizer to use, if nothing, will use the same as the one in the provided model, proving it is one of [Gurobi, Ipopt, HiGHS]
"""
function make_models(model::Model, optimizer::Union{Nothing, DataType}=nothing)
    optimizer = !isnothing(optimizer) ? optimizer : solver_dict[solver_name(model)]
    _models = [copy(model) for _ in 1:Threads.nthreads()]
    [MOI.set(_models[ii], MOI.Name(), "Model for thread: $ii") for ii in 1:Threads.nthreads()]
    set_optimizer.(_models, optimizer)
    return _models
end