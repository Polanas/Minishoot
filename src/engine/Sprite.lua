local Vec2 = require("engine/Vec2")
local Color = require("engine/Color")

local function Sprite(x, y, width, height, frame_width, frame_heigth)
    if frame_width == nil then
        frame_width = width
    end
    if frame_height == nil then
        frame_height = height
    end

    local sprite = {
        angle = 0,
        auto_update = true,
        opacity = 1,
        width = width,
        height = height,
        frame_width = frame_width,
        frame_height = frame_height,
        color = Color(255,255,255,255)
    }
    local animations = {}
    local current_animation
    local animation_finished = false

    local time_passed = 0
    local current_segment_index = 1

    local current_atlas_x
    local current_atlas_y

    local frames_per_row = math.floor(width / frame_width)
    local max_y = y + height

    sprite.scale = Vec2.one()

    local function set_current_segment_frame()
        local segment = current_animation.segments[current_segment_index]

        sprite:set_frame(segment.frame)
    end

    function sprite:update_frame()
        if current_animation == nil or animation_finished then
            return
        end

        time_passed = time_passed + 1
        local segments = current_animation.segments
        local current_segment = segments[current_segment_index]

        if time_passed >= current_segment.duration then
            time_passed = 0

            if current_segment_index < #segments then
                current_segment_index = current_segment_index + 1
                
                set_current_segment_frame()
            else
                if current_animation.looped then
                    current_segment_index = 1

                    set_current_segment_frame()
                else
                    animation_finished = true
                end
            end
        end
    end

    function sprite:add_animation(name, animation)
        animations[name] = animation
    end

    function sprite:set_animation(name)
        if name == nil then
            current_animation = nil
            return
        end

        current_animation = animations[name]

        animation_finished = false
        time_passed = 0
        current_segment_index = 1
    end

    function sprite:set_frame(frame)
        frame = frame - 1

        current_atlas_x = x + frame % frames_per_row * frame_width
        current_atlas_y = y + math.floor(frame / frames_per_row) * frame_heigth

        current_atlas_y = math.min(current_atlas_y, max_y)
    end

    function sprite:get_current_x()
        return current_atlas_x
    end

    function sprite:get_current_y()
        return current_atlas_y
    end

    function sprite:get_frame_width()
        return frame_width
    end

    function sprite:get_frame_height()
        return frame_heigth
    end

    sprite:set_frame(1)

    return sprite
end

return Sprite