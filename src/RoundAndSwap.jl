module RoundAndSwap

include("structs.jl")
include("swapping.jl")
include("misc.jl")
include("model.jl")
include("printing.jl")
include("inout.jl")
include("round.jl")

const SHOW_PROGRESS_BARS = parse(Bool, get(ENV, "PROGRESS_BARS", "true"))

# misc
export flatten
# model
export successful, fixed_variables, unfix!, make_models, fix!, get_var
# printing

# structs
export Swap,
    Swapper,
    successful_swaps,
    unsuccessful_swaps,
    total_optimisation_time,
    num_swaps,
    status_codes,
    RSStatusCodes

# round
export round!

# swapping
export best_swap,
    previously_tried,
    best_objective,
    try_swapping!,
    initial_swaps,
    create_swaps!,
    evalute_sweep,
    swap
# inout
export save, load_swapper

end # module RoundAndSwap
