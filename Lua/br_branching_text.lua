branching_text_names = {
    is = true,
    has = true,
    near = true,
    make = true,
    follow = true,
    mimic = true,
    play = true,
    eat = true,
    fear = true,
    on = true,
    without = true,
    facing = true,
    above = true,
    below = true,
    feeling = true
}

br_prefix = "branching_"
br_prefix_len = string.len(br_prefix)

function is_branching_text_defined(name)
    return branching_text_names[name] or name == "and"
end

function name_is_branching_text(name)
    return string.len(name) > br_prefix_len and string.sub(name, 1, br_prefix_len) == br_prefix and is_branching_text_defined(string.sub(name, br_prefix_len + 1))
end

function name_is_branching_and(name)
    return name == br_prefix.."and"
end


function parse_branching_text(name)
    if string.len(name) > br_prefix_len and string.sub(name, 1, br_prefix_len) == br_prefix then 
        local main_text = string.sub(name, br_prefix_len + 1)
        if is_branching_text_defined(main_text) then
            return main_text
        else
            return name
        end
    else
        return name
    end
end