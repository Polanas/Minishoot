local gl = require("engine/rendering/gl")

local utils = require("engine/utils")

local Buffer = require("engine/rendering/opengl/Buffer")

local function ElementBuffer(type, size, count)
    local buffer = Buffer(gl.ELEMENT_ARRAY_BUFFER, type, size, count)
    local element_buffer = utils.inherit(buffer)

    function element_buffer:draw(primitive_type, count)
        gl.DrawElements(primitive_type, count, type, nil)
    end 

    return element_buffer
end

return ElementBuffer