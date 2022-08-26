using JuMP

threshold(values, num_above) =  minimum(sort(values)[(end-num_above+1):end])


function round!(to_consider::Vector{VariableRef}, num_to_fix::Int)
    thresh = threshold(value.(to_consider), num_to_fix)
    idx_to_fix = findall(x -> thresh ≤ x, value.(to_consider))
    variables_to_fix = to_consider[idx_to_fix]

    if length(variables_to_fix) != num_to_fix
        error("It seems like there are multiple values at the rounding threshold.")
    end
    @info "Fixing: " variables_to_fix
    return fix.(variables_to_fix, 1; force=true)
end


