using JuMP

threshold(values, num_above) = minimum(sort(values)[(end - num_above + 1):end])

function variables_over_thresh(to_consider::Vector{VariableRef}, num_to_fix::Int)
    if num_to_fix == 0
        return []
    end
    thresh = threshold(value.(to_consider), num_to_fix)
    idx_to_fix = findall(x -> thresh ≤ x, value.(to_consider))
    return to_consider[idx_to_fix]
end

function round!(to_consider::Vector{VariableRef}, num_to_fix::Int)
    variables_to_fix = variables_over_thresh(to_consider, num_to_fix)

    if length(variables_to_fix) != num_to_fix
        error("It seems like there are multiple values at the rounding threshold.")
    end
    @info "Fixing: " variables_to_fix
    return fix.(variables_to_fix, 1; force=true)
end

function round!(model::Model, to_consider::Vector{String}, num_to_fix::Int)
    to_consider = variable_by_name.(model, to_consider)
    return round!(to_consider, num_to_fix)
end
