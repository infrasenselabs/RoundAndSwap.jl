var documenterSearchIndex = {"docs":
[{"location":"nomenclature/#Nomenclature","page":"Nomenclature","title":"Nomenclature","text":"","category":"section"},{"location":"nomenclature/","page":"Nomenclature","title":"Nomenclature","text":"sweep: A complete round of swaps, finishing all in swapper.to_swap","category":"page"},{"location":"#RoundAndSwap.jl","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"","category":"section"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"(Image: Run tests)(Image: codecov)","category":"page"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"RoundAndSwap is a library for implementing the Round and Swap algorithm to try and find an intial solution.","category":"page"},{"location":"#caveats","page":"RoundAndSwap.jl","title":"caveats","text":"","category":"section"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"Only choosing 0 and 1 as integer values is supported.","category":"page"},{"location":"#Quickstart","page":"RoundAndSwap.jl","title":"Quickstart","text":"","category":"section"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"Create your JuMP model\nSolve a linear relaxation of your problem\nFix the desired number of variables to 1\nCreate an array of variables to consider in the swap - consider_swapping\nround_and_swap(model, consider_swapping)","category":"page"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"See the tests/runtests.jl for an example of how to use this library.","category":"page"},{"location":"#Performance","page":"RoundAndSwap.jl","title":"Performance","text":"","category":"section"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"In testing I've done 536 swaps with round_and_swap taking 174.1 seconds with 172.8 seconds of that being in the optimizer, giving RoundAndSwap.jl an overhead of 0.75%.  ","category":"page"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"Pages = [\"nomenclature.md\"]","category":"page"},{"location":"#Index","page":"RoundAndSwap.jl","title":"Index","text":"","category":"section"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"","category":"page"},{"location":"#Functions","page":"RoundAndSwap.jl","title":"Functions","text":"","category":"section"},{"location":"","page":"RoundAndSwap.jl","title":"RoundAndSwap.jl","text":"Modules = [RoundAndSwap]","category":"page"},{"location":"#RoundAndSwap.Swap","page":"RoundAndSwap.jl","title":"RoundAndSwap.Swap","text":"Swap\n\nAn objecct to keep track of a swap\n\nArguments:\n\nexisting::Union{Symbol, Nothing}: The existing variable\nnew::Union{Symbol, Nothing}: The variable to replace the existing\nobj_value::Real: The objective value for this swap\nsuccess::Union{Bool, Nothing}: Whether the swap was successful\nall_fixed::Union{Array{Symbol}, Nothing}: All the variable in swapper.to_consider which were fixed\ntermination_status::Union{String, TerminationStatusCode, Nothing}: TerminationStatusCode\nsolve_time::Union{Real, Nothing}: Time to solve\nSwap(existing, new): A constructor for a Swap object\n\n\n\n\n\n","category":"type"},{"location":"#RoundAndSwap.Swapper","page":"RoundAndSwap.jl","title":"RoundAndSwap.Swapper","text":"Swapper\n\nAn object to keep track of all the swaps\n\nArguments:\n\nto_swap::Array{Swap}: A list of swaps yet to be done\nconsider_swapping::Array{Symbol}: The variables to consider swapping\ncompleted_swaps::Union{Array{Array{Swap}}, Nothing}: The completed swaps\nsense::OptimizationSense: The optimisation sense, MAX or MIN\nmax_swaps::Real: The maximum number of swaps to complete\nnumber_of_swaps::Int: The number of swaps completed\nSwapper(to_swap, to_swap_with, model; max_swaps): A constructor\n\n\n\n\n\n","category":"type"},{"location":"#Base.:==-Tuple{Swap, Swap}","page":"RoundAndSwap.jl","title":"Base.:==","text":"Base.:(==)(a::Swap, b::Swap)\n\nCheck whther two swaps have the same existing and new values\n\n\n\n\n\n","category":"method"},{"location":"#Base.getindex-Tuple{JuMP.AbstractModel, Array{Symbol, N} where N}","page":"RoundAndSwap.jl","title":"Base.getindex","text":"Base.getindex(m::JuMP.AbstractModel, names::Array{Symbol})\n\nAllow the getting of multiple variables\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap._completed_swaps-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap._completed_swaps","text":"_completed_swaps(swapper::Swapper)\n\nGet a list of swaps which actually ran\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.best_objective-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.best_objective","text":"best_objective(swapper::Swapper)\n\nGet the best objective value in swapper.completed_swaps\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.best_swap-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.best_swap","text":"best_swap(swapper::Swapper)\n\nReturn the best swap in the swapper\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.create_swaps!-Tuple{Swapper, Symbol}","page":"RoundAndSwap.jl","title":"RoundAndSwap.create_swaps!","text":"create_swaps!(swapper::Swapper, to_swap::Symbol)\n\nGiven the previously completed swaps, create a list of new swaps\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.evalute_sweep-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.evalute_sweep","text":"evalute_sweep(swapper::Swapper)\n\nAfter complete a sweep, find which swaps improved the existing best objective and use this to create new swaps\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.fix!","page":"RoundAndSwap.jl","title":"RoundAndSwap.fix!","text":"fix!(models::Array{Model}, to_fix::Array{Symbol}, value = 1)\n\nFor each model, fix all variables in to_fix to 1 \n\nArguments:\n\nmodels: Models to fix values\nto_fix: Variables to fix\nvalue: Value to fix to, by default 1\n\n\n\n\n\n","category":"function"},{"location":"#RoundAndSwap.fixed_variables-Tuple{JuMP.Model, Array{Symbol, N} where N}","page":"RoundAndSwap.jl","title":"RoundAndSwap.fixed_variables","text":"fixed_variables(model::Model, consider_swapping::Array{Symbol})\n\nFind which variables in consider swapping are fixed\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.fixed_variables-Tuple{JuMP.Model, Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.fixed_variables","text":"fixed_variables(model::Model, swapper::Swapper)\n\nFind which variables in consider swapping are fixed\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.flatten-Tuple{Array{Array{Swap, N} where N, N} where N}","page":"RoundAndSwap.jl","title":"RoundAndSwap.flatten","text":"flatten(to_flatten::Array{Array{Swap}})\n\nFlatten nested arrays of swaps\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.get_var-Tuple{JuMP.AbstractModel, Symbol}","page":"RoundAndSwap.jl","title":"RoundAndSwap.get_var","text":"get_var(m::JuMP.AbstractModel, name::Symbol)\n\nGet a variable, if the symbol fails try getting it from an array of variables\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.initial_swaps-Tuple{Array{Symbol, N} where N, Array{Symbol, N} where N}","page":"RoundAndSwap.jl","title":"RoundAndSwap.initial_swaps","text":"initial_swaps(to_swap::Array{Symbol}, to_swap_with::Array{Symbol})\n\nGiven the initial state, create a list of initial swaps\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.make_models","page":"RoundAndSwap.jl","title":"RoundAndSwap.make_models","text":"make_models(model::Model, optimizer::Union{Nothing, DataType} = nothing)\n\nGiven a single model, make enough models to have one for each thread\n\nArguments:\n\noptimizer: Optimizer to use, if nothing, will use the same as the one in the provided model, proving it is one of [Gurobi, Ipopt, HiGHS]\n\n\n\n\n\n","category":"function"},{"location":"#RoundAndSwap.num_swaps-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.num_swaps","text":"num_swaps(swapper::Swapper)\n\nGet how many swaps have been completed\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.previously_tried-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.previously_tried","text":"previously_tried(swapper::Swapper)\n\nGet a list of all previously stried fixed variables in swapper.consider_swapping\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.round_and_swap-Tuple{Array{JuMP.Model, N} where N, Array{JuMP.VariableRef, N} where N}","page":"RoundAndSwap.jl","title":"RoundAndSwap.round_and_swap","text":"round_and_swap(models::Array{Model}, consider_swapping::Array{VariableRef}; max_swaps = Inf, optimizer = nothing)\n\nGiven a model and a list of variables swap the integer values to improve the objective function\n\nArguments:\n\nmodels: An array of models, one for each thread\nconsider_swapping: An array of variables to consider swapping\nmax_swaps: The maximum number of swaps, default is Inf\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.round_and_swap-Tuple{JuMP.Model, Array{JuMP.VariableRef, N} where N}","page":"RoundAndSwap.jl","title":"RoundAndSwap.round_and_swap","text":"round_and_swap(model::Model, consider_swapping::Array{VariableRef}; optimizer = nothing, max_swaps = Inf)\n\nGiven a model and a list of variables swap the integer values to improve the objective function\n\nArguments:\n\nmodels: An array of models, one for each thread\nconsider_swapping: An array of variables to consider swapping\noptimizer: A specific optimizer to use, if the desired is not in [Gurobi, Ipopt, HiGHS]\nmax_swaps: The maximum number of swaps, default is Inf\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.solve!-Tuple{Any, Any, Any}","page":"RoundAndSwap.jl","title":"RoundAndSwap.solve!","text":"solve!(model, swapper, swap)\n\nSolve this swap\n\nArguments:\n\nmodel: A model object\nswapper: The swapper being used\nswap: Which swap to solve\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.status_codes-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.status_codes","text":"status_codes(swapper::Swapper)\n\nGet all the status codes which have occured for this Swapper\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.successful-Tuple{JuMP.Model}","page":"RoundAndSwap.jl","title":"RoundAndSwap.successful","text":"successful(model::Model)\n\nDetermine if a model was succesful\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.successful-Tuple{MathOptInterface.TerminationStatusCode}","page":"RoundAndSwap.jl","title":"RoundAndSwap.successful","text":"successful(t_stat::TerminationStatusCode)\n\nDetermine if a model was succesful\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.successful_swaps-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.successful_swaps","text":"successful_swaps(swapper::Swapper)\n\nGet a list of swaps which succeeded\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.total_optimisation_time-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.total_optimisation_time","text":"total_optimisation_time(swapper::Swapper)\n\nGet the total time spent in optimizers\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.try_swapping!-Tuple{Array{JuMP.Model, N} where N, Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.try_swapping!","text":"try_swapping!(models::Array{Model}, swapper::Swapper)\n\nGiven a model and the swapper, try all swaps in swapper.to_swap\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.unfix!-Tuple{Array{JuMP.Model, N} where N, Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.unfix!","text":"unfix!(models::Array{Model}, swapper::Swapper)\n\nUnfix all variables in consider swapping\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.unfix!-Tuple{JuMP.VariableRef}","page":"RoundAndSwap.jl","title":"RoundAndSwap.unfix!","text":"unfix!(variable::VariableRef)\n\nunfix! a variable are reset 0 and 1 as lower and upper bounds\n\n\n\n\n\n","category":"method"},{"location":"#RoundAndSwap.unsuccessful_swaps-Tuple{Swapper}","page":"RoundAndSwap.jl","title":"RoundAndSwap.unsuccessful_swaps","text":"unsuccessful_swaps(swapper::Swapper)\n\nGet a list of swaps which failed\n\n\n\n\n\n","category":"method"}]
}
