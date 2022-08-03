# structs and struct methods
using JuMP

mutable struct Swap
    existing::Union{VariableRef, Nothing}
    new::Union{VariableRef, Nothing}
    obj_value::Real
    success::Union{Bool, Nothing}
    all_fixed::Union{Array{VariableRef}, Nothing}
    termination_status::Union{String, TerminationStatusCode, Nothing}
    solve_time::Union{Real, Nothing}
    Swap(existing::Union{VariableRef, Nothing}, new::Union{VariableRef, Nothing}) = new(existing, new, NaN, nothing, nothing, nothing,nothing)
end

function Base.:(==)(a::Swap, b::Swap)
    return a.existing == b.existing && a.new == b.new
end

mutable struct Swappable
    to_swap::Array{Swap}
    consider_swapping::Array{VariableRef}
    completed_swaps::Union{Array{Array{Swap}}, Nothing}
    sense::OptimizationSense
    Swappable(to_swap, to_swap_with, model) = new(to_swap, to_swap_with, [], objective_sense(model))
end

