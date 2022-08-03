function flatten(to_flatten::Array{Array{Swap}})
    return collect(Iterators.flatten(to_flatten))
end
