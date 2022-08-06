# structs and struct methods
using JuMP

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

function Base.:(==)(a::Swap, b::Swap)
    return a.existing == b.existing && a.new == b.new
end

mutable struct Swappable
    to_swap::Array{Swap}
    consider_swapping::Array{Symbol}
    completed_swaps::Union{Array{Array{Swap}}, Nothing}
    sense::OptimizationSense
    max_swaps::Real # Real to allow Inf
    number_of_swaps::Int
    Swappable(to_swap, to_swap_with, model; max_swaps) = new(to_swap, to_swap_with, [], objective_sense(model), max_swaps, 0)
end

""" Get a list of swaps which actually ran"""
function _completed_swaps(swapper::Swappable)
    return [s for s in flatten(swapper.completed_swaps) if !isnothing(s.success)]
end

function successful_swaps(swapper::Swappable)
    return [s for s in _completed_swaps(swapper) if s.success]
end
function unsuccessful_swaps(swapper::Swappable)
    return [s for s in _completed_swaps(swapper) if !s.success]
end

function num_swaps(swapper::Swappable)
    return length(_completed_swaps(swapper))
end

function total_optimisation_time(swapper::Swappable)
    return print("Optimisations ran for: " * string(round(sum([s.solve_time for s in _completed_swaps(swapper)]),digits=2)) * " seconds")
end