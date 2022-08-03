using PrettyPrinting: best_fit, indent, list_layout, literal, pair_layout, pprint

function _all_but_swapped(s::Swappable)
    ret_val = literal("Swappable:") * literal("\n") *
    indent(4) * literal("To swap      -> ") * list_layout(tile.(s.to_swap)) * literal("\n") *
    indent(4) * literal("Current best -> ") * list_layout(tile.(s.current_best)) *  literal("\n") *
    indent(4) * literal("To swap with -> ") * list_layout(tile.(s.to_swap_with)) * literal("\n");
    return ret_val;
end

tile(s::Swappable) = 
    if isempty(s.swapped)
        _all_but_swapped(s);
    else
        _all_but_swapped(s) * indent(4) * literal("Swapped      -> ") * list_layout(tile.(s.swapped)) 
    end

Base.show(io::IO,::MIME"text/plain", s::Swappable) = pprint(s)

