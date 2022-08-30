using OnlineStats

"""
    flatten(to_flatten::Array{Array{Swap}})

Flatten nested arrays of swaps
"""
function flatten(to_flatten::Array{Array{Swap}})
    return collect(Iterators.flatten(to_flatten))
end


function init_mean(vals)
    m =Mean()
    m.μ = vals[:mean]
    m.n = vals[:n]
    return m
end

