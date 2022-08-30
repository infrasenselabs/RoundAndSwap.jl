using JSON
using DataStructures
import OnlineStats.Mean

function JSON.lower(s::Swap)
    return Dict(
        "existing" => s.existing,
        "new" => s.new,
        "obj_value" => s.obj_value,
        "success" => s.success,
        "all_fixed" => s.all_fixed,
        "termination_status_code" => Int(s.termination_status),
        "termination_status_string" => s.termination_status,
        "solve_time" => s.solve_time,
    )
end

function JSON.lower(μ::Mean)
    return Dict("mean" => μ.μ, "n" => μ.n)
end

function save(file_name::String, s::Swapper)
    if splitext(file_name)[end] !== ".json"
        @info "Adding .json extension to file name"
        file_name = file_name * ".json"
    end
    open(file_name, "w") do f
        JSON.print(f, s)
    end
end


function load_swapper(file_name::String)
    read_s = JSON.parsefile(file_name; dicttype=() -> DefaultDict{Symbol,Any}(Missing))

    read_s[:consider_swapping] = Symbol.(read_s[:consider_swapping])

    for (idx, sweep) in enumerate(read_s[:completed_swaps])
        _sweep = []
        for swap in sweep
            swap[:all_fixed] =
                isnothing(swap[:all_fixed]) ? swap[:all_fixed] : Symbol.(swap[:all_fixed])
            swap[:new] = isnothing(swap[:new]) ? swap[:new] : Symbol.(swap[:new])
            swap[:existing] =
                isnothing(swap[:existing]) ? swap[:existing] : Symbol.(swap[:existing])
            swap[:obj_value] = isnothing(swap[:obj_value]) ? NaN : swap[:obj_value]
            swap[:termination_status] = if swap[:termination_status_code] < 100
                MOI.TerminationStatusCode(swap[:termination_status_code])
            else
                RSStatusCodes(swap[:termination_status_code])
            end
            delete!(swap, :termination_status_code)
            delete!(swap, :termination_status_string)
            push!(_sweep, Swap(; NamedTuple(swap)...))
        end
        read_s[:completed_swaps][idx] = _sweep
    end

    read_s[:sense] =
        read_s[:sense] == "MAX_SENSE" ? MOI.OptimizationSense(1) : MOI.OptimizationSense(0)
    read_s[:max_swaps] = isnothing(read_s[:max_swaps]) ? Inf : read_s[:max_swaps]

    read_s[:_successful_run_time] = init_mean(read_s[:_successful_run_time])
    read_s[:_unsuccessful_run_time] = init_mean(read_s[:_unsuccessful_run_time])

    return Swapper(; NamedTuple(read_s)...)
end
