local COLOR_COMPONENTS_COUNT = 4

local RESOURCES_FOLDER = "Resources"
local SHADERS_FOLDER = "Shaders"

local CONTENT_FOLDER = "Content"
local FONTS_FOLDER = "Fonts"
local ATLAS_NAME = "atlas.png"

local png = require("png")
local imgui_enabled, imgui = pcall(require, "imgui/imgui")

local glfw = require("engine/glfw")

local KEY_PRESSED = glfw.PRESS
local KEY_RELEASED = glfw.RELEASE
local KEY_REPEATED = glfw.REPEAT

local batch = require("engine/rendering/batch")
local utils = require("engine/utils")
local keys = require("engine/keys")

local Emitter = require("engine/Emitter")
local Layer = require("engine/Layer")
local Sprite = require("engine/Sprite")
local Color = require("engine/Color")
local Vec2 = require("engine/Vec2")
local Font = require("engine/Font")
local FontFamily = require("engine/FontFamily")

local engine = {
    Color = Color,
    Vec2 = Vec2,
    keys = keys
}

local window = nil

local width = nil
local height = nil
local name  = nil

local current_layer = nil
local current_buffer = nil
local layer_width = nil
local layer_height = nil

local cursor_x_buffer = glfw.double(1)
local cursor_y_buffer = glfw.double(1)  

local emitter = Emitter()

local layers = {}
local sprites = {}

local pressed_keys = {}
local held_keys = {}
local released_keys = {}
local repeated_keys = {}
local entered_text = nil

local atlas_buffer = {}
local atlas_width = 0
local atlas_height = 0

local font_families = {}

local time_seconds = 0
local time = 0
local show_fps = false

local imgui_implementation = nil

local temp_color = Color()

local min = math.min
local max = math.max
local sqrt = math.sqrt
local floor = math.floor
local abs = math.abs
local sin = math.sin
local cos = math.cos
local clamp = utils.clamp
local sub = string.sub

local white = Color.white()

local one = Vec2.one()

local function call(name, arguments)
    emitter.emit(emitter, name, arguments)
    
   
end

local function on_resize(_, new_width, new_height)
    width = new_width
    height = new_height
    
    batch.on_resize(width, height)

    call("resize", {
        width,
        height
    })
end

local function register_input_acion(key, action)
    if action == KEY_PRESSED then
        pressed_keys[key] = true
        held_keys[key] = true
    elseif action == KEY_REPEATED then
        repeated_keys[key] = true
    elseif action == KEY_RELEASED then
        released_keys[key] = true
        held_keys[key] = false
    end
end

local function on_key_action(window, key, scancode, action, mods)
    register_input_acion(key, action)
end

local function on_mouse_button_action(window, button, action, mods)
    register_input_acion(button, action)
end

local function special_key_entered(key)
    return engine.key_pressed(key) or repeated_keys[key]
end

local function get_color_index(x, y)
    local index = (layer_width * y + x) * COLOR_COMPONENTS_COUNT

    return index
end

local function get_atlas_index(x, y)
    if x < 0 or y < 0 or x >= atlas_width or y >= atlas_height then
        return nil
    end

    local index = atlas_width * y + x + 1

    return index
end

local function get_atlas_color(x, y)
    local index = get_atlas_index(x, y)

    if index == nil then
        return nil
    end

    return atlas_buffer[index]
end

local function in_layer_bounds(x, y)
    if x < 0 or x > layer_width - 1 or y < 0 or y > layer_height - 1 then
        return false
    end

    return true
end

local function draw_shallow_line(x1, y1, x2, delta_x, delta_y, color)
    local y_increment = 1

    if delta_y < 0 then
        y_increment = y_increment * -1
        delta_y = delta_y * -1
    end

    local d = 2 * delta_y - delta_x
    local d_increment = 2 * (delta_y - delta_x)
    local d_no_increment = 2 * delta_y

    local y = y1

    for x = x1, x2 do
        engine.put_pixel(x, y, color)

        if d > 0 then
            y = y + y_increment
            d = d + d_increment
        else
            d = d + d_no_increment
        end
    end
end

local function draw_steep_line(x1, y1, y2, delta_x, delta_y, color)
    local x_increment = 1

    if delta_x < 0 then
        x_increment = x_increment * -1
        delta_x = delta_x * -1
    end

    local d = 2 * delta_x - delta_y
    local d_increment = 2 * (delta_x - delta_y)
    local d_no_increment = 2 * delta_x

    local x = x1

    for y = y1, y2 do
        engine.put_pixel(x, y, color)

        if d > 0 then
            x = x + x_increment
            d = d + d_increment
        else
            d = d + d_no_increment
        end
    end
end

local function draw_horizontal_line(x1, x2, y, color)
    local start_x = min(x1, x2)
    local end_x = max(x1, x2)

    for x = start_x, end_x do
        engine.put_pixel(x, y, color)
    end
end

local function draw_vertical_line(x, y1, y2, color)
    local start_y = min(y1, y2)
    local end_y = max(y1, y2)

    for y = start_y, end_y do
        engine.put_pixel(x, y, color)
    end
end

local function draw_sprite(x, y, sprite)
    local atlas_left = sprite:get_current_x()
    local atlas_top = sprite:get_current_y()

    local sprite_width = sprite:get_frame_width()
    local sprite_height = sprite:get_frame_height()
    local atlas_origin_x = atlas_left + floor(sprite_width / 2)
    local atlas_origin_y = atlas_top + floor(sprite_height / 2)

    local atlas_right = atlas_left + sprite_width
    local atlas_bottom = atlas_top + sprite_height

    local scale = sprite.scale
    local scale_x = scale.x
    local scale_y = scale.y

    local opacity = sprite.opacity

    local angle = sprite.angle
    local sin = sin(angle)
    local cos = cos(angle)

    local side = max(sprite_width * scale_x, sprite_height * scale_y) / 2
    local radius = floor(sqrt(side ^ 2 * 2))

    for relative_x = -radius, radius do
        for relative_y = -radius, radius do
            local rotated_x = floor(relative_x * cos - relative_y * sin)
            local rotated_y = floor(relative_x * sin + relative_y * cos)

            local color_x = floor(rotated_x / scale_x) + atlas_origin_x
            local color_y = floor(rotated_y / scale_y) + atlas_origin_y

            if color_x >= atlas_left and color_x < atlas_right and color_y >= atlas_top and color_y < atlas_bottom then
                local color = get_atlas_color(color_x, color_y)
                color = Color.clone(color):multiply(opacity)

                color = color:multiply_color_raw(Color.clone(sprite.color):divide_raw(255));
                engine.put_pixel(x + relative_x, y + relative_y, color)
            end
        end
    end
end

local function draw_sprite_cheap(x, y, sprite)
    local atlas_x = sprite:get_current_x()
    local atlas_y = sprite:get_current_y()

    local width = sprite:get_frame_width()
    local height = sprite:get_frame_height()

    x = x - floor(width / 2)
    y = y - floor(height / 2)

    engine.draw_atlas_segment(x, y, atlas_x, atlas_y, width, height, sprite.color)
end

local function set_name_internal(name)
    glfw.SetWindowTitle(window, name)
end

local function on_new_scanline(index, scanline, width, height)
    local y = index - 1
    local pixels = scanline.pixels

    for x = 1, width do
        local pixel = pixels[x]
        local color_index = y * width + x
        local color = Color(pixel.R, pixel.G, pixel.B, pixel.A)

        atlas_buffer[color_index] = color
    end
end

local function run()
    local period = 1 / engine.frequency
    local last_time = glfw.GetTime()
    local delta = 0
    local frames = 0

    while not glfw.WindowShouldClose(window) do
        time = glfw.GetTime()
        delta = delta + time - last_time
        last_time = time

        while delta >= period do
            delta = 0
            
            utils.clear_table(pressed_keys)
            utils.clear_table(released_keys)
            utils.clear_table(repeated_keys)
            entered_text = ""

            glfw.PollEvents()

            for _, sprite in ipairs(sprites) do
                if sprite.auto_update then
                    sprite:update_frame()
                end
            end

            call("update")
            call("draw")

            frames = frames + 1

            if time - time_seconds >= 1 then
                time_seconds = time_seconds + 1

                if show_fps then
                    set_name_internal(name .. " FPS: " .. frames)
                end

                frames = 0
            end
            
            local color = engine.clear_color
            color:clamp()

            batch.begin(color, true)
            
            for _, layer in ipairs(layers) do
                local texture = layer.get_texture()
                local layer_width = layer:get_width()
                local layer_height = layer:get_height()
                local buffer = layer:get_buffer()
                
                texture:bind()
                texture:set_data(buffer)
                
                local x_scale = width / layer_width
                local y_scale = height / layer_height
                
                local depth = layer:get_depth()
                
                batch.submit(0, 0, texture, x_scale, y_scale, depth)
            end
            
            batch.finish(time, engine.get_mouse_position())

            if imgui_enabled then
                imgui_implementation:NewFrame()
                
                call("imgui")
                
                imgui_implementation:Render()
            end

            glfw.SwapBuffers(window)
        end
    end

    print("App was closed")
end

function engine.initialize(props)
    local atlas_path = utils.concat_paths(CONTENT_FOLDER, ATLAS_NAME)

    local atlas_exists, atlas = pcall(png.Image, atlas_path, on_new_scanline)
    
    if atlas_exists then
        atlas_width = atlas.width
        atlas_height = atlas.height
    else
        utils.log(atlas)
    end

    local fonts_directory = utils.concat_paths(CONTENT_FOLDER, FONTS_FOLDER)
    local font_files_paths = utils.get_directory_files(fonts_directory)

    if font_files_paths ~= nil then
        local font_file = font_files_paths()

        while font_file ~= nil do
            local font_path = utils.concat_paths(fonts_directory, font_file)
            font_families[font_file] = FontFamily(font_path)

            font_file = font_files_paths()
        end
    end
    
    glfw.Init()

    width = props.width
    height = props.height
    name = props.name

    local clear_color = props.clear_color 
    local frequency = props.frequency

    if clear_color == nil then
        clear_color = Color(0, 0, 0, 0)
    end

    if frequency == nil then
        frequency = 60
    end

    engine.clear_color = clear_color
    engine.frequency = frequency

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    engine.disable_resizing()
end

function engine.run()
    window = glfw.CreateWindow(width, height, name, nil, nil)
    glfw.MakeContextCurrent(window) 

    if imgui_enabled then
        imgui_implementation = imgui.Imgui_Impl_glfw_opengl3()
        imgui_implementation:Init(window, true)
    end
    
    glfw.SetWindowSizeCallback(window, on_resize)
    glfw.SetKeyCallback(window, on_key_action)
    glfw.SetMouseButtonCallback(window, on_mouse_button_action)

    local shaders_directory = utils.concat_paths(RESOURCES_FOLDER, SHADERS_FOLDER)
    batch.initialize(shaders_directory)
    on_resize(nil, width, height)

    call("start")
    call("resize")

    run()

    glfw.DestroyWindow(window)
end

function engine.on_start(listener)
    emitter:on("start", listener)
end

function engine.on_update(listener)
    emitter:on("update", listener)
end

function engine.on_draw(listener)
    emitter:on("draw", listener)
end

function engine.on_imgui_render(listener)
    emitter:on("imgui", listener)
end

function engine.on_resize(listener)
    emitter:on("resize", listener)
end

function engine.show_cursor()
    glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_NORMAL)
end

function engine.hide_cursor()
    glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_HIDDEN)
end

function engine.resize(width, height)
    glfw.SetWindowSize(window, width, height)
end

function engine.set_name(new_name)
    name = new_name
    set_name_internal(name)
end

function engine.disable_resizing()
    glfw.WindowHint(glfw.RESIZABLE, false)
end

function engine.enable_resizing()
    glfw.WindowHint(glfw.RESIZABLE, true)
end

function engine.enable_fps_counter()
    show_fps = true
end

function engine.disable_fps_counter()
    show_fps = false
    set_name_internal(name)
end

function engine.get_mouse_position(layer)
    glfw.GetCursorPos(window, cursor_x_buffer, cursor_y_buffer)

    local x = cursor_x_buffer[0]
    local y = cursor_y_buffer[0]

    local max_width = width
    local max_height = height

    if layer ~= nil then
        max_width = layer:get_width()
        max_height = layer:get_height()

        x = x * max_width / width
        y = y * max_height / height
    end

    x = clamp(x, 0, max_width)
    y = clamp(y, 0, max_height)

    return Vec2(x, y):floor()
end

function engine.get_time()
    return time
end

-- !
function engine.terminate()
    glfw.SetWindowShouldClose(window, true)
end

function engine.Layer(props)
    local layer = Layer(props)
    table.insert(layers, layer)

    return layer
end

function engine.Sprite(x, y, width, height, frame_width, frame_height)
    x = max(x, 0)
    y = max(y, 0)

    width = min(width, atlas_width - x)
    height = min(height, atlas_height - y)

    if frame_width == nil then
        frame_width = width
    else
        frame_width = min(frame_width, width)
    end

    if frame_height == nil then
        frame_height = height
    else 
        frame_height = min(frame_height, height)
    end

    local sprite = Sprite(x, y, width, height, frame_width, frame_height)
    table.insert(sprites, sprite)

    return sprite
end

function engine.Font(x, y, name)
    local font_family = font_families[name]
    
    if font_family == nil then
        return nil
    end

    return Font(x, y, font_family)
end

function engine.free_sprite(sprite)
    utils.remove(sprites, sprite)
end

function engine.begin_layer(layer)
    assert(current_layer == nil, "You can only begin a new layer after the current one is ended.")

    if not utils.table_contains(layers, layer) then
        return
    end

    if layer.auto_clear then
        layer:clear()
    end

    current_layer = layer
    current_buffer = layer:get_buffer()

    layer_width = layer:get_width()
    layer_height = layer:get_height()
end

function engine.end_current_layer()
    assert(current_layer ~= nil, "You need to begin drawing on a layer before ending it.")

    current_layer = nil
end

function engine.key_pressed(key)
    return pressed_keys[key] == true
end

function engine.key_down(key)    
    return held_keys[key] == true
end

function engine.key_released(key)
    return released_keys[key] == true
end

function engine.update_text_input_string(input, position)
    local length = #input

    if position == nil then
        position = length
    end
    
    position = clamp(position, 0, length)

    if length > 0 then
        if special_key_entered(keys.backspace) and position >= 1 then
            input = sub(input, 1, position - 1) .. sub(input, position + 1, -1)

            position = position - 1
            length = length - 1
        end

        if special_key_entered(keys.delete) and position <= length then
            input = sub(input, 1, position) .. sub(input, position + 2, -1)
        end
    end

    input = sub(input, 1, position) .. entered_text .. sub(input, position + 1, -1)
    position = position + #entered_text

    return input, position
end

function engine.set_pixel(x, y, color)
    assert(current_layer ~= nil, "You can only draw after begin is called.")
    
    if not in_layer_bounds(x, y) or color.a == 0 then
        return
    end

    x = floor(x)
    y = floor(y)

    local index = get_color_index(x, y)

    current_buffer[index] = color.r
    current_buffer[index + 1] = color.g
    current_buffer[index + 2] = color.b
    current_buffer[index + 3] = color.a
end

function engine.set_pixel_vec(vec, color)
    engine.set_pixel(vec.x, vec.y, color)
end

function engine.put_pixel(x, y, color)
    if not current_layer.blending then
        engine.set_pixel(x, y, color)
    end

    local destination_r, destination_g, destination_b, destination_a = engine.get_pixel(x, y)

    if destination_r == nil then
        return
    end

    temp_color.r = destination_r
    temp_color.g = destination_g
    temp_color.b = destination_b
    temp_color.a = destination_a

    local alpha_normalized = color:a_normalized()
    temp_color:multiply(1 - alpha_normalized)
    temp_color:add(color)

    engine.set_pixel(x, y, temp_color)
end

function engine.put_pixel_vec(vec, color)
    engine.put_pixel(vec.x, vec.y, color) 
end

function engine.get_pixel(x, y)
    assert(current_layer ~= nil, "You need to begin drawing on a layer.")

    x = floor(x)
    y = floor(y)

    if not in_layer_bounds(x, y) then
        return nil
    end

    local index = get_color_index(x, y)

    local r = current_buffer[index]
    local g = current_buffer[index + 1]
    local b = current_buffer[index + 2]
    local a = current_buffer[index + 3]

    return r, g, b, a
end

function engine.get_pixel_vec(vec)
    return engine.get_pixel(vec.x, vec.y)
end

function engine.get_atlas_color(x, y)
    local color = get_atlas_color(x, y)

    if color == nil then
        return nil
    end

    return Color.clone(color)
end

function engine.set_atlas_color(x, y, color)
    local index = get_atlas_index(x, y)

    if index == nil then
        return
    end

    atlas_buffer[index] = color
end

function engine.draw_line(x1, y1, x2, y2, color)
    x1 = floor(x1)
    x2 = floor(x2)
    y1 = floor(y1)
    y2 = floor(y2)

    if y1 == y2 then
        draw_horizontal_line(x1, x2, y1, color)
        return
    elseif x1 == x2 then
        draw_vertical_line(x1, y1, y2, color)
        return
    end

    local delta_x = x2 - x1
    local delta_y = y2 - y1

    if abs(delta_x) > abs(delta_y) then
        if x2 < x1 then
            local temporary_x = x1
            local temporary_y = y1

            x1 = x2
            x2 = temporary_x
            y1 = y2
            y2 = temporary_y

            delta_x = delta_x * -1
            delta_y = delta_y * -1
        end

        draw_shallow_line(x1, y1, x2, delta_x, delta_y, color)

        return
    end

    if y2 < y1 then
        local temporary_x = x1
        local temporary_y = y1

        x1 = x2
        x2 = temporary_x
        y1 = y2
        y2 = temporary_y

        delta_x = delta_x * -1
        delta_y = delta_y * -1
    end

    draw_steep_line(x1, y1, y2, delta_x, delta_y, color)
end

function engine.draw_line_vec(vec1, vec2, color)
    engine.draw_line(vec1.x, vec1.y, vec2.x, vec2.y, color) 
end

function engine.draw_rectangle(left, top, right, bottom, color)
    if left > right then
        local temporary = left
        left = right
        right = temporary
    end

    if top > bottom then
        local temporary = top
        top = bottom
        bottom = temporary
    end

    local shifted_top = top + 1
    local shifted_bottom = bottom - 1

    draw_horizontal_line(left, right, top, color)
    draw_vertical_line(right, shifted_top, shifted_bottom, color)
    draw_horizontal_line(right, left, bottom, color)
    draw_vertical_line(left, shifted_bottom, shifted_top, color)
end 

function engine.draw_rectangle_vec(top_left, bottom_right, color)
    engine.draw_rectangle(top_left.x, top_left.y, bottom_right.x, bottom_right.y, color) 
end

function engine.fill_rectangle(left, top, right, bottom, color)
    if left > right then
        local temporary = left
        left = right
        right = temporary
    end

    if top > bottom then
        local temporary = top
        top = bottom
        bottom = temporary
    end

    local put_pixel = engine.put_pixel

    for x = left, right do
        for y = top, bottom do
            put_pixel(x, y, color)
        end
    end
end

function engine.fill_rectangle_vec(top_left, bottom_right, color)
    engine.fill_rectangle(top_left.x, top_left.y, bottom_right.x, bottom_right.y, color) 
end

function engine.draw_triangle(x1, y1, x2, y2, x3, y3, color)
    engine.draw_line(x1, y1, x2, y2, color)
    engine.draw_line(x2, y2, x3, y3, color)
    engine.draw_line(x3, y3, x1, y1, color)
end

function engine.draw_triangle_vec(vec1, vec2, vec3, color) 
    engine.draw_triangle(vec1.x, vec1.y, vec2.x, vec2.y, vec3.x, vec3.y, color) 
end

function engine.fill_triangle(x1, y1, x2, y2, x3, y3, color)
    local delta_c_y = y3 - y1
    local delta_c_x = x3 - x1
    local delta_b_y = y2 - y1
    
    local min_x = min(x1, x2, x3)
    local min_y = min(y1, y2, y3)
    local max_x = max(x1, x2, x3)
    local max_y = max(y1, y2, y3)

    local put_pixel = engine.put_pixel
    for x = min_x, max_x do
        for y = min_y, max_y do
            local w1 = x1 * delta_c_y + (y - y1) * delta_c_x - x * delta_c_y
            w1 = w1 / (delta_b_y * delta_c_x - (x2 - x1) * delta_c_y)

            if w1 >= 0 then
                local w2 = y - y1 - w1 * delta_b_y
                w2 = w2 / delta_c_y

                if w2 >= 0 and w1 + w2 <= 1 then
                    put_pixel(x, y, color)
                end
            end
        end
    end
end

function engine.fill_triangle_vec(vec1, vec2, vec3, color) 
    engine.fill_triangle(vec1.x, vec1.y, vec2.x, vec2.y, vec3.x, vec3.y, color) 
end

function engine.draw_circle(center_x, center_y, raduis, color)
    if raduis <= 0 then
        return
    end 

    local diamerer = raduis * 2
    local left = center_x - raduis
    local top = center_y - raduis

    for x = left, left + diamerer do
        for y = top, top + diamerer do
            local distance = utils.distance(center_x, center_y, x, y) 

            if floor(distance) == raduis then
                engine.put_pixel(x, y, color)
            end
        end
    end
end

function engine.draw_circle_vec(vec, radius, color)
    engine.draw_circle(vec.x, vec.y, radius, color)
end

function engine.fill_circle(center_x, center_y, raduis, color)
    if raduis <= 0 then
        return
    end

    local diamerer = raduis * 2
    local left = center_x - raduis
    local top = center_y - raduis

    for x = left, left + diamerer do
        for y = top, top + diamerer do
            local distance = utils.distance(center_x, center_y, x, y) 

            if floor(distance) <= raduis then
                engine.put_pixel(x, y, color)
            end
        end
    end
end

function engine.fill_circle_vec(vec, radius, color)
    engine.fill_circle(vec.x, vec.y, radius, color)
end

function engine.draw_atlas_segment(x, y, atlas_x, atlas_y, width, height, sprite_color)
    for relative_x = 0, width - 1 do
        for relative_y = 0, height - 1 do
            local color_x = atlas_x + relative_x
            local color_y = atlas_y + relative_y

            local color = Color.clone(get_atlas_color(color_x, color_y))
            color = color:multiply_color_raw(Color.clone(sprite_color):divide_raw(255));

            if color ~= nil then
                engine.put_pixel(x + relative_x, y + relative_y, color)
            end
        end
    end
end

function engine.draw_sprite(x, y, sprite)
    if sprite.scale:equals(one) and sprite.angle == 0 and sprite.opacity == 1 then
        draw_sprite_cheap(x, y, sprite)
        return
    end
    
    draw_sprite(x, y, sprite)
end

function engine.draw_sprite_vec(vec, sprite)
    engine.draw_sprite(vec.x, vec.y, sprite) 
end

function engine.draw_text(x, y, font, text, color)
    local font_x = font:get_x()
    local font_y = font:get_y()

    local current_x = x

    for symbol in string.gmatch(text, ".") do
        local character = font:get_character(symbol)

        if character ~= nil then
            local char_x = current_x + character.bearing_x
            local char_y = y + character.bearing_y

            local atlas_x = font_x + character.x
            local atlas_y = font_y + character.y
            local width = character.width
            local height = character.height

            for relative_x = 0, width - 1 do
                for relative_y = 0, height - 1 do
                    local color_x = atlas_x + relative_x
                    local color_y = atlas_y + relative_y

                    local atlas_color = get_atlas_color(color_x, color_y)

                    if atlas_color ~= nil then
                        if atlas_color:equals(white) then
                            atlas_color = color
                        end

                        engine.put_pixel(char_x + relative_x, char_y + relative_y, atlas_color)
                    end
                end
            end

            current_x = current_x + character.x_advance + 1
        end
    end
end

function engine.draw_text_vec(vec, font, text, color)
    engine.draw_text(vec.x, vec.y, font, text, color)
end

if imgui_enabled then
    engine.imgui = imgui
else
    utils.log("Imgui not found")
end

jit.off(run)

-- do the same with other functions
engine.get_atlas_color = get_atlas_color

return engine