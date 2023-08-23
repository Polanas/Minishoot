-- layer:terminate

-- put this in constants.lua??
local COLOR_COMPONENTS_COUNT = 4

local gl = require("engine/rendering/gl")

local Texture = require("engine/rendering/opengl/Texture")
local Color = require("engine/Color")

local function Layer(props)
    local auto_clear = props.auto_clear

    if auto_clear == nil then
        auto_clear = true
    end

    local layer = {
        auto_clear = auto_clear,
        blending = props.blending
    }
    
    local width = props.width
    local height = props.height
    local buffer_length = width * height * COLOR_COMPONENTS_COUNT

    local texture = Texture(width, height)
    local buffer = gl.GLubyte(buffer_length)
    local depth = props.depth

    local clear_color = props.clear_color

    if clear_color == nil then
        clear_color = Color(0, 0, 0, 0)
    end

    function layer:clear()
        for i = 0, buffer_length / COLOR_COMPONENTS_COUNT - 1 do
            local index = COLOR_COMPONENTS_COUNT * i
    
            buffer[index] = clear_color.r
            buffer[index + 1] = clear_color.g
            buffer[index + 2] = clear_color.b
            buffer[index + 3] = clear_color.a
        end
    end

    layer:clear()

    function layer:get_texture()
        return texture
    end

    function layer:get_buffer()
        return buffer
    end

    function layer:get_width()
        return width
    end

    function layer:get_height()
        return height
    end

    function layer:get_depth()
        return depth
    end

    return layer
end

return Layer