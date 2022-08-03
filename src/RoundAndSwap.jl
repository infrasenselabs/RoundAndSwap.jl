module RoundAndSwap

include("structs.jl")
include("swapping.jl")
include("misc.jl")
include("model.jl")
include("printing.jl")

# misc
export flatten
# model
export successful, fixed_variables, unfix!
# printing

# structs
export Swap, Swappable
# swapping
export best_swap, previously_tried, best_objective, try_swapping!, initial_swaps, create_swaps, evalute_sweep

end # module RoundAndSwap
