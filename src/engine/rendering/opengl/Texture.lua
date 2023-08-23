local gl = require("engine/rendering/gl")

local function Texture(width, height)
    local texture = {}

    local texture_2d = gl.TEXTURE_2D

    local handle_buffer = gl.GLuint(1)
    gl.CreateTextures(texture_2d, 1, handle_buffer)

    local handle = handle_buffer[0]

    function texture:bind(unit)
        if unit == nil then
            unit = gl.TEXTURE0
        end

        gl.ActiveTexture(unit)
        gl.BindTexture(texture_2d, handle)
    end

    texture:bind()

    local texture_repeat = gl.REPEAT
    local texture_nearest = gl.NEAREST

    gl.TexParameteri(texture_2d, gl.TEXTURE_WRAP_S, texture_repeat)
    gl.TexParameteri(texture_2d, gl.TEXTURE_WRAP_S, texture_repeat)
    gl.TexParameteri(texture_2d, gl.TEXTURE_MIN_FILTER, texture_nearest)
    gl.TexParameteri(texture_2d, gl.TEXTURE_MAG_FILTER, texture_nearest)

    local rgba = gl.RGBA
    local ubyte = gl.UNSIGNED_BYTE

    gl.TexImage2D(texture_2d, 0, rgba, width, height, 0, rgba, ubyte, nil)
    gl.GenerateMipmap(texture_2d)

    function texture:set_data(data)
        gl.TexSubImage2D(texture_2d, 0, 0, 0, width, height, rgba, ubyte, data)
    end

    function texture:get_width()
        return width
    end

    function texture:get_height()
        return height
    end

    return texture
end

return Texture