local ffi = require("ffi")

local gl = require("engine/rendering/gl")

local function VertexArray(vertex_buffer, element_buffer)
    local array = {}

    local handle_buffer = gl.GLuint(1)
    gl.CreateVertexArrays(1, handle_buffer)

    local handle = handle_buffer[0]

    local attributes = {}
    local stride = 0

    function array:bind()
        gl.BindVertexArray(handle)
    end 

    function array:push_attribute(type, size, count)
        local size = size * count
        stride = stride + size

        local attribute = {
            type = type,
            count = count, 
            size = size
        }

        table.insert(attributes, attribute)
    end

    function array:initialize()
        vertex_buffer:bind()
        element_buffer:bind()
        
        local offset = 0
        
        for i, attribute in ipairs(attributes) do
            local index = i - 1
            
            local pointer = ffi.cast("void*", offset)
            
            gl.VertexAttribPointer(index, attribute.count, attribute.type, false, stride, pointer)
            gl.EnableVertexAttribArray(index)
            
            offset = offset + attribute.size
        end
    end

    return array
end

return VertexArray