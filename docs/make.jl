using Documenter
using RoundAndSwap

makedocs(
    sitename = "RoundAndSwap",
    format = Documenter.HTML(),
    modules = [RoundAndSwap]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
