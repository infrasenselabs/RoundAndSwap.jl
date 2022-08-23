using JuMP

function round!(to_consider::Vector{VariableRef}, num_to_fix::Int)
    thresh = minimum(sort(value.(to_consider))[(end - num_to_fix + 1):end])
    idx_to_fix = findall(x -> thresh ≤ x, value.(to_consider))
    variables_to_fix = to_consider[idx_to_fix]

    if length(variables_to_fix) != num_to_fix
        error("It seems like there are multiple values at the rounding threshold.")
    end
    @info "Fixing: " variables_to_fix
    return fix.(variables_to_fix, 1; force=true)
end
