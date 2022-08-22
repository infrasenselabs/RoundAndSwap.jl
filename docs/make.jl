using Documenter
using RoundAndSwap

makedocs(
    sitename = "RoundAndSwap",
    format = Documenter.HTML(),
    modules = [RoundAndSwap]
)


deploydocs(
    repo = "github.com/this-josh/RoundAndSwap.jl.git",
    push_preview = true,
    forcepush = true,
    versions = ["stable" => "v^", "v#.#", devurl => "dev"]
)