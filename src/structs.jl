# structs and struct methods
using JuMP

mutable struct Swap
    existing::VariableRef
    new::VariableRef
    obj_value::Real
    success::Union{Bool, Nothing}
    all_fixed::Union{Array{VariableRef}, Nothing}
    termination_status
    solve_time
    Swap(existing::VariableRef, new::VariableRef) = new(existing, new, NaN, nothing, nothing, nothing,nothing)
end

function Base.:(==)(a::Swap, b::Swap)
    return a.existing == b.existing && a.new == b.new
end

mutable struct Swappable
    to_swap::Array{Swap}
    consider_swapping
    completed_swaps
    Swappable(to_swap, to_swap_with) = new(to_swap, to_swap_with, [])
end
