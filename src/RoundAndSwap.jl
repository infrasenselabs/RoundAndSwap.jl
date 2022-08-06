module RoundAndSwap

include("structs.jl")
include("swapping.jl")
include("misc.jl")
include("model.jl")
include("printing.jl")

# misc
export flatten
# model
export successful, fixed_variables, unfix!, make_models, fix!
# printing

# structs
export Swap, Swappable, successful_swaps, unsuccessful_swaps, total_optimisation_time, num_swaps
# swapping
export best_swap, previously_tried, best_objective, try_swapping!, initial_swaps, create_swaps, evalute_sweep, round_and_swap

end # module RoundAndSwap
