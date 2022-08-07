if Int === Int32
    error("As Gurobi.jl does not support 32-bit Julia, RoundAndSwap cannot either. Please install a 64-bit Julia.")
end