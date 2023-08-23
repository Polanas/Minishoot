local xml = require("xmlSimple")

local utils = require("engine/utils")

local function read_int_attribute(data, name)
    local value = data[name]
    return tonumber(value)
end

local function FontFamily(xmlPath)
    local font_family = {}
    local characters = {}

    local parser = xml.newParser()
    local text = utils.read_file(xmlPath)

    local data = parser:ParseXmlText(text)
    local font_data = data.font

    local chars_data = font_data.chars
    local chars = chars_data:children()
    local count = tonumber(chars_data["@count"])

    for i = 1, count do
        local char = chars[i]
        local id = read_int_attribute(char, "@id")
        local symbol = string.char(id)

        local x = read_int_attribute(char, "@x")
        local y = read_int_attribute(char, "@y")
        local width = read_int_attribute(char, "@width")
        local height = read_int_attribute(char, "@height")

        local bearing_x = read_int_attribute(char, "@xoffset")
        local bearing_y = read_int_attribute(char, "@yoffset")

        local x_advance = read_int_attribute(char, "@xadvance")
        
        local character = {
            x = x,
            y = y,
            width = width,
            height = height,
            bearing_x = bearing_x,
            bearing_y = bearing_y,
            x_advance = x_advance
        }

        characters[symbol] = character
    end

    function font_family:get_character(symbol)
        return characters[symbol]
    end

    return font_family
end

return FontFamily