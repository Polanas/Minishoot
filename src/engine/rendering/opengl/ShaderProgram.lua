local ffi = require("ffi")

local gl = require("engine/rendering/gl")

local NAME_STRING_LENGTH = 64

local function create_shader(source, type, program_handle)
    local shader = gl.CreateShader(type)
    
    local source_buffer = gl.GLchar(#source, source)
    local source_buffer_pointer = gl.GLcharptr(1, source_buffer)
    
    gl.ShaderSource(shader, 1, source_buffer_pointer, nil)

    gl.CompileShader(shader)

    gl.AttachShader(program_handle, shader)

    return shader
end

local function ShaderProgram(vertex_source, fragment_source)
    local program = {}
    local locations = {}

    local handle = gl.CreateProgram()
    
    local vertex_shader = create_shader(vertex_source, gl.VERTEX_SHADER, handle)
    local fragment_shader = create_shader(fragment_source, gl.FRAGMENT_SHADER, handle)
    gl.LinkProgram(handle)
    
    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(fragment_shader)
    
    local uniforms_count_buffer = gl.GLint(1)
    gl.GetProgramiv(handle, gl.ACTIVE_UNIFORMS, uniforms_count_buffer)

    local uniforms_count = uniforms_count_buffer[0] 
    
    local name_buffer = gl.GLchar(NAME_STRING_LENGTH)
    local length_buffer = gl.GLsizei(1)
    
    local dummy = gl.GLint(1)

    for i = 0, uniforms_count - 1 do
        gl.GetActiveUniform(handle, i, NAME_STRING_LENGTH, length_buffer, dummy, dummy, name_buffer)
        local name = ffi.string(name_buffer, length_buffer[0])
        local location = gl.GetUniformLocation(handle, name)

        local bracket_index = string.find(name, "%[")

        if bracket_index ~= nil then 
            name = string.sub(name, 1, bracket_index - 1)
        end

        locations[name] = location
    end

    function program:bind()
        gl.UseProgram(handle)
    end

    function program:set_uniform_f1(name, count, value)
        local location = locations[name]

        if location == nil then 
            return 
        end

        gl.Uniform1fv(location, count, value)
    end

    function program:set_uniform_f2(name, count, value)
        local location = locations[name]

        if location == nil then 
            return 
        end
        gl.Uniform2fv(location, count, value)
    end

    function program:set_uniform(name, count, value)
        local location = locations[name]

        if location == nil then 
            return 
        end
        gl.Uniform1iv(location, count, value)
    end

    function program:set_uniform_matrix(name, matrix)
        local location = locations[name]
        
        if location == nil then 
            return 
        end
        
        gl.UniformMatrix4fv(location, 1, false, matrix)
    end

    return program
end

return ShaderProgram