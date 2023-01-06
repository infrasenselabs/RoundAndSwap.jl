import OnlineStats.Mean
using JuMP

"""
    flatten(to_flatten::Array{Array{Swap}})

Flatten nested arrays of swaps
"""
function flatten(to_flatten::Array{Array{Swap}})
    return collect(Iterators.flatten(to_flatten))
end

function init_mean(vals)
    m = Mean()
    m.μ = vals[:mean]
    m.n = vals[:n]
    return m
end

function _derive_cpu_limit(swapper::Swapper, required_swaps::Int=20)
    if swapper._successful_run_time.n > required_swaps &&
        swapper._unsuccessful_run_time.n > required_swaps &&
        swapper._successful_run_time.μ * 1.5 < swapper._unsuccessful_run_time.μ
        return swapper._successful_run_time.μ * 1.5
    else
        return Inf
    end
end

function set_cpu_limit(swapper::Swapper, model::Model)
    if swapper.auto_cpu_limit
        l = _derive_cpu_limit(swapper)
        @debug "Setting cpu limit to $l seconds"
        set_time_limit_sec(model, l)
    end
end
