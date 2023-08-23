local gl = require("engine/rendering/gl")
local utils = require("engine/utils")

local Buffer = require("engine/rendering/opengl/Buffer")

local function VertexBuffer(type, size, count)
    local buffer = Buffer(gl.ARRAY_BUFFER, type, size, count)
    local vertex_buffer = utils.inherit(buffer)

    return vertex_buffer
end

return VertexBuffer