# structs and struct methods
using JuMP

"""
    Swap

An objecct to keep track of a swap

# Arguments:
- `existing::Union{Symbol, Nothing}`: The existing variable
- `new::Union{Symbol, Nothing}`: The variable to replace the existing
- `obj_value::Real`: The objective value for this swap
- `success::Union{Bool, Nothing}`: Whether the swap was successful
- `all_fixed::Union{Array{Symbol}, Nothing}`: All the variable in swapper.to_consider which were fixed
- `termination_status::Union{String, TerminationStatusCode, Nothing}`: TerminationStatusCode
- `solve_time::Union{Real, Nothing}`: Time to solve
- `Swap(existing, new)`: A constructor for a Swap object
"""
mutable struct Swap
    existing::Union{Symbol, Nothing}
    new::Union{Symbol, Nothing}
    obj_value::Real
    success::Union{Bool, Nothing}
    all_fixed::Union{Array{Symbol}, Nothing}
    termination_status::Union{String, TerminationStatusCode, Nothing}
    solve_time::Union{Real, Nothing}
    Swap(existing::Union{Symbol, Nothing}, new::Union{Symbol, Nothing}) = new(existing, new, NaN, nothing, nothing, nothing,nothing)
end

"""
    Base.:(==)(a::Swap, b::Swap)

Check whther two swaps have the same existing and new values
"""
function Base.:(==)(a::Swap, b::Swap)
    return a.existing == b.existing && a.new == b.new
end

"""
    Swapper

An object to keep track of all the swaps

# Arguments:
- `to_swap::Array{Swap}`: A list of swaps yet to be done
- `consider_swapping::Array{Symbol}`: The variables to consider swapping
- `completed_swaps::Union{Array{Array{Swap}}, Nothing}`: The completed swaps
- `sense::OptimizationSense`: The optimisation sense, MAX or MIN
- `max_swaps::Real`: The maximum number of swaps to complete
- `number_of_swaps::Int`: The number of swaps completed
- `Swapper(to_swap, to_swap_with, model; max_swaps)`: A constructor
"""
mutable struct Swapper
    to_swap::Array{Swap}
    consider_swapping::Array{Symbol}
    completed_swaps::Union{Array{Array{Swap}}, Nothing}
    sense::OptimizationSense
    max_swaps::Real # Real to allow Inf
    number_of_swaps::Int
    Swapper(to_swap, to_swap_with, model; max_swaps) = new(to_swap, to_swap_with, [], objective_sense(model), max_swaps, 0)
end

"""
    _completed_swaps(swapper::Swapper)

Get a list of swaps which actually ran
"""
function _completed_swaps(swapper::Swapper)
    return [s for s in flatten(swapper.completed_swaps) if !isnothing(s.success)]
end

"""
    successful_swaps(swapper::Swapper)

Get a list of swaps which succeeded
"""
function successful_swaps(swapper::Swapper)
    return [s for s in _completed_swaps(swapper) if s.success]
end
"""
    unsuccessful_swaps(swapper::Swapper)

Get a list of swaps which failed
"""
function unsuccessful_swaps(swapper::Swapper)
    return [s for s in _completed_swaps(swapper) if !s.success]
end

"""
    status_codes(swapper::Swapper)

Get all the status codes which have occured for this Swapper
"""
function status_codes(swapper::Swapper)
    return [s.termination_status for s in _completed_swaps(swapper)]
end

"""
    num_swaps(swapper::Swapper)

Get how many swaps have been completed
"""
function num_swaps(swapper::Swapper)
    return length(_completed_swaps(swapper))
end

"""
    total_optimisation_time(swapper::Swapper)

Get the total time spent in optimizers
"""
function total_optimisation_time(swapper::Swapper)
    return print("Optimisations ran for: " * string(round(sum([s.solve_time for s in _completed_swaps(swapper)]),digits=2)) * " seconds")
end