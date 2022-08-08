import Base.show

show(io::IO, s::Swap) = print(io, 
"""
Swap 
    existing:           $(s.existing)
    new:                $(s.new)
    obj_value:          $(s.obj_value)          
    success:            $(s.success)            
    all_fixed:          $(s.all_fixed)          
    termination_status: $(s.termination_status) 
    solve_time:         $(s.solve_time)
""")
show(io::IO, s::Swapper) = print(io, 
"""
Swapper
    $(length(s.to_swap)) left to swap
    Sense $(s.sense)
    Best Objective: $(best_objective(s))
    Completed $(s.number_of_swaps) swaps
    $(length(successful_swaps(s))) were successful
    $(length(unsuccessful_swaps(s))) were unsuccessful
    The rest were be skipped
""")
