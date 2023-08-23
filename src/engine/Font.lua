local function Font(x, y, font_family)
    local font = {}

    function font:get_character(symbol)
        return font_family:get_character(symbol)
    end

    function font:get_x()
        return x
    end

    function font:get_y()
        return y
    end

    return font
end

return Font