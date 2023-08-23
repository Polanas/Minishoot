-- batch.terminate

local MAX_VERTICES = 1000
local ELEMENTS_PER_ITEM = 6
local MAX_ELEMENT = 4
local VERTICES_PER_ITEM = 4
local MAX_ELEMENTS = MAX_VERTICES / VERTICES_PER_ITEM * ELEMENTS_PER_ITEM
local VALUES_PER_VERTEX = 5
local VALUES_PER_ITEM = VALUES_PER_VERTEX * VERTICES_PER_ITEM
local MAX_VERTEX_VALUES = MAX_VERTICES * VALUES_PER_VERTEX
local MAX_TEXTURES = 32

local MATRIX_4X4_SIZE = 16

local VERTEX_SHADER_NAME = "default.vert"
local FRAGMENT_SHADER_NAME = "default.frag"

local gl = require("engine/rendering/gl")

local utils = require("engine/utils")

local VertexArray = require("engine/rendering/opengl/VertexArray")
local VertexBuffer = require("engine/rendering/opengl/VertexBuffer")
local ElementBuffer = require("engine/rendering/opengl/ElementBuffer")
local ShaderProgram = require("engine/rendering/opengl/ShaderProgram")

local batch = {}

local quad_elements = {
    0, 
    1, 
    3,
    1, 
    2, 
    3
}

local projection = nil

local items = {}

local vertex_values = gl.GLfloat(MAX_VERTEX_VALUES)
local vertex_values_count = 0
local gl_time = gl.GLfloat(1)
local gl_mouse_pos = gl.GLfloat(2)

local textures_count = 0
local items_count = 0

local shader_program = nil
local vertex_buffer = nil
local element_buffer = nil
local vertex_array = nil

local blending_enabled = false

local began = false

local function compare_items(first, second)
    return first.depth < second.depth
end

local function add_vertex(x, y, texture_x, texture_y, texture_index)
    vertex_values[vertex_values_count] = x
    vertex_values[vertex_values_count + 1] = y
    vertex_values[vertex_values_count + 2] = texture_x
    vertex_values[vertex_values_count + 3] = texture_y
    vertex_values[vertex_values_count + 4] = texture_index

    vertex_values_count = vertex_values_count + VALUES_PER_VERTEX
end

local function flush(time, mouse_pos)
    gl_time[0] = time
    shader_program:set_uniform_f1("time", 1, gl_time)

    gl_mouse_pos[0] = mouse_pos.x
    gl_mouse_pos[1] = mouse_pos.y
    shader_program:set_uniform_f2("mousePos", 1, gl_mouse_pos)

    vertex_buffer:set_data(vertex_values_count, vertex_values)
    element_buffer:draw(gl.TRIANGLES, items_count * ELEMENTS_PER_ITEM)

    vertex_values_count = 0
    textures_count = 0
    items_count = 0
end

function batch.initialize(shaders_folder)
    gl.load_modern_functions()
    
    gl.BlendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA)

    local vertex_path = utils.concat_paths(shaders_folder, VERTEX_SHADER_NAME)
    local fragment_path = utils.concat_paths(shaders_folder, FRAGMENT_SHADER_NAME)

    local vertex_source = utils.read_file(vertex_path)
    local fragment_source = utils.read_file(fragment_path)
    
    shader_program = ShaderProgram(vertex_source, fragment_source)
    shader_program:bind()

    local float = gl.FLOAT
    local float_size = gl.float_size

    vertex_buffer = VertexBuffer(float, float_size, MAX_VERTEX_VALUES)
    element_buffer = ElementBuffer(gl.UNSIGNED_INT, gl.uint_size, MAX_ELEMENTS)

    vertex_array = VertexArray(vertex_buffer, element_buffer)
    
    vertex_array:bind()
    
    vertex_array:push_attribute(float, float_size, 2)
    vertex_array:push_attribute(float, float_size, 2)
    vertex_array:push_attribute(float, float_size, 1)
    
    vertex_array:initialize()

    local elements = gl.GLuint(MAX_ELEMENTS)
    local index = 0

    for i = 1, MAX_ELEMENTS / #quad_elements do
        local quad_elements_length = #quad_elements

        for j = 1, quad_elements_length do
            local local_element = quad_elements[j]
            local offset = MAX_ELEMENT * (i - 1)

            elements[index + j  - 1] = local_element + offset
        end

        index = index + quad_elements_length
    end
    
    element_buffer:set_data(MAX_ELEMENTS, elements)
    
    local texture_units = gl.GLint(MAX_TEXTURES)
    
    for i = 0, MAX_TEXTURES - 1 do
        texture_units[i] = i
    end
    
    shader_program:set_uniform("u_Textures", MAX_TEXTURES, texture_units)
    
    local matrix_size = MATRIX_4X4_SIZE
    projection = gl.GLfloat(matrix_size)
    projection[3] = -1
    projection[7] = 1
    projection[10] = -2
    projection[11] = 1
    projection[15] = 1
end

function batch.begin(clear_color, blending)
    assert(not began, "Finish must be called before begin is called.")

    local blend = gl.BLEND

    if not blending and blending_enabled then
        gl.Disable(blend)
        blending_enabled = false
    elseif blending and not blending_enabled then
        gl.Enable(blend)
        blending_enabled = true
    end

    local r = clear_color:r_normalized()
    local g = clear_color:g_normalized()
    local b = clear_color:b_normalized()
    local a = clear_color:a_normalized()

    gl.ClearColor(r, g, b, a)

    began = true
end

function batch.submit(x, y, texture, scale_x, scale_y, depth)
    assert(began, "Begin must be called before submitting items.")

    local texture_width = texture:get_width()
    local texture_height = texture:get_height()

    local right = x + texture_width * scale_x
    local bottom = y + texture_height * scale_y

    local item = {
        left = x,
        top = y,
        right = right,
        bottom = bottom,
        texture = texture,
        depth = depth
    }

    table.insert(items, item)
end

function batch.finish(time, mouse_pos)
    assert(began, "Begin must be calle before finish is called.")

    gl.Clear(gl.COLOR_BUFFER_BIT)

    table.sort(items, compare_items)

    local last_texture = nil

    for _, item in ipairs(items) do
        local current_texture = item.texture

        if last_texture ~= current_texture and textures_count + 1 > MAX_TEXTURES or vertex_values_count + VALUES_PER_ITEM > MAX_VERTICES then
            flush(time, mouse_pos)

            last_texture = nil
        end

        if current_texture ~= last_texture then
            current_texture:bind(gl.TEXTURE0 + textures_count)

            last_texture = current_texture
            textures_count = textures_count + 1
        end

        local left = item.left
        local top = item.top
        local right = item.right
        local bottom = item.bottom

        local texture_index = textures_count - 1

        add_vertex(right, top, 1, 0, texture_index)
        add_vertex(right, bottom, 1, 1, texture_index)
        add_vertex(left, bottom, 0, 1, texture_index)
        add_vertex(left, top, 0, 0, texture_index)

        items_count = items_count + 1
    end

    if vertex_values_count > 0 then
        flush(time, mouse_pos)
    end

    utils.clear_table(items)
    began = false
end

function batch.on_resize(width, height)
    gl.Viewport(0, 0, width, height)
    
    projection[0] = 2 / width
    projection[5] = -2 / height
    
    shader_program:set_uniform_matrix("u_Transform", projection)
end
    
return batch