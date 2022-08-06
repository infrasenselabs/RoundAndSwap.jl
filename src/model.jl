
using JuMP

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
