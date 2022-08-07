import Base.show

show(io::IO, s::Swap) = print(io, 
"""
Swap 
    new: $(s.new)
    obj_value: $(s.obj_value)          
    success: $(s.success)            
    all_fixed: $(s.all_fixed)          
    termination_status: $(s.termination_status) 
    solve_time: $(s.solve_time)
""")
show(io::IO, s::Swapper) = print(io, 
"""
Swapper
    $(length(s.to_swap)) left to swap
    Completed $(length(s.completed_swaps)) swaps
    Sense $(s.sense)
    Number of swaps: $(s.number_of_swaps)
    Best Objective: $(best_objective(swapper))
""")
