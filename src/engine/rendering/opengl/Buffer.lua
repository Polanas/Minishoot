local gl = require("engine/rendering/gl")

local function Buffer(target, type, size, count)
    local buffer = {}

    local handle_buffer = gl.GLuint(1)
    gl.GenBuffers(1, handle_buffer)
    
    local handle = handle_buffer[0]
    local length = 0
    
    function buffer:bind()
        gl.BindBuffer(target, handle)
    end
    
    buffer:bind()          
    gl.BufferData(target, size * count, nil, gl.STATIC_DRAW)

    function buffer:set_data(count, data)
        gl.BufferSubData(target, 0, count * size, data)
    end

    function buffer:get_length()
        return length
    end

    function buffer:get_type()
        return type
    end

    return buffer
end

return Buffer