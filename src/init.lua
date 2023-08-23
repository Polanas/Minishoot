local engine = require("engine")

local keys = engine.keys

local game_layer = nil
local ui_layer = nil

local Vec2 = engine.Vec2
local Color = engine.Color

local started_at = os.time()
local frequency = 60
local delta_time = 1 / frequency

local screen_width
local screen_height
local screen_size

local floor = math.floor
local ceiling = math.ceil
local min = math.min
local random = math.random
local sin = math.sin

local function set_random_seed(offset)
    math.randomseed(started_at + engine.get_time() + offset)
end

local function mod(a, b)
    return (a % b + b) % b
end

function math.sign(x)
    if x < 0 then return -1
    elseif x > 0 then return 1
    else return 0
    end
 end

local time = 0
local font
local player = { }
local player_bullets = { }
local enemies = { }
local enemy_bullets = { }
local player_bullet_sprite
local enemy_sprite
local enemy_bullet_sprite
local enemy_tail_sprite
local PLAYER_BASE_SPEED = 120
local DASH_BASE_SPEED = 400
local bullet_particles
local bullet_count = 0
local BULLET_SPEED = 300
local TAIL_PARTS_COUNT = 15
local ENEMY_TAIL_PARTS_COUNT = 7
local bullet_timer = 0
local mouse_position
local enemy_spawn_timer = 0
local displacement_sprite
local in_main_menu = true
local selected_button = "PLAY"

function math.rad_to_deg(angle)
    return angle / math.pi * 180
end

function math.deg_to_rad(angle)
    return angle * math.pi / 180
end
--public static float AngleBetweenPoints(Vector2 point1, Vector2 point2) =>
  --  MathHelper.RadiansToDegrees(MathF.Atan2(point1.Y - point2.Y, point2.X - point1.X));
function math.angle_between_points(posA, posB)
    return math.rad_to_deg(math.atan2(posA.y - posB.y, posA.x - posB.x))
end

local function bool_to_number(condition)
    if condition then
        return 1
    else
        return -1
    end
end
-- позаимствовано (спизжено) со StackOverflow
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local function on_start()
    game_layer = engine.Layer({
        width = 320,
        height = 180,
        depth = 0
    })

    ui_layer = engine.Layer({
        width = 320,
        height = 180,
        depth = 1
    })

    displacement_layer = engine.Layer({
        width = 320,
        height = 180,
        depth = 2
    })

    screen_width = 320
    screen_height = 180
    screen_size = Vec2(screen_width, screen_height)

    player.tail_positions = { }
    player.speed = Vec2.zero()
    player.tail_positions[1] = screen_size / 2
    for i = 2, TAIL_PARTS_COUNT do
        player.tail_positions[i] = Vec2.zero()
    end
    player.last_direction = Vec2.zero()
    player.can_shoot = true
    player.linear_speed = 0
    player.stared_dashing = false
    player.locked_direction_saved = false
    player.is_dashing = false
    player.bullet_direction = Vec2.zero()
    player.sprite = engine.Sprite(0, 0, 8, 8)
    player.dash_copies = { }
    player.hp = 1
    player_bullet_sprite = engine.Sprite(8, 0, 4,4)
    enemy_sprite = engine.Sprite(15,0, 10, 9)
    enemy_tail_sprite = engine.Sprite(25, 0, 6, 6)
    enemy_bullet_sprite = engine.Sprite(31, 0, 4, 4)
    menu_current_button_sprite = engine.Sprite(509, 0, 41, 13)
end

local function collision_circle(posA, radA, posB, radB)
    return (posA - posB):length() <= radA + radB
end

local function collision_rectangle(posA, sizeA, posB, sizeB)
    if math.abs(posA.x - posB.x) > sizeA.x / 2 + sizeB.x / 2 then
        return false
    end
    if math.abs(posA.y - posB.y) > sizeA.y / 2 + sizeB.y / 2 then
        return false
    end

    return true
end

local function draw_player()
    if player.is_dead then
        if player.death_timer ~= nil and player.death_timer > 10 then
            return
        end
        
        if player.death_timer == nil or player.death_timer == 0 then
            player.death_timer = 0
            player.death_particles = { }

            for i = 1, 8 do
                angle = (i-1) * (360 / 8)
                speed = Vec2(100 * delta_time, 0):rotate(Vec2.zero(), math.deg_to_rad(angle))

                particle = {
                    position = player.tail_positions[1],
                    speed = speed
                }

                table.insert(player.death_particles, particle)
            end
        end

        player.death_timer = player.death_timer + 1

        for i, particle in pairs(player.death_particles) do
            particle.position = particle.position + particle.speed
            particle.speed = particle.speed * .9
            player_bullet_sprite.color.r = player.hp * 255
            player_bullet_sprite.color.g = player.hp * 255
            player_bullet_sprite.color.b = player.hp * 255
            player_bullet_sprite.scale = Vec2(1 - player.death_timer/10.)
            engine.draw_sprite(particle.position.x, particle.position.y, player_bullet_sprite)
        end
    end

    for i = 1, TAIL_PARTS_COUNT do
        local currentPos = player.tail_positions[i]
        local size = 1 - (i / TAIL_PARTS_COUNT)
        if player.death_timer ~= nil and player.death_timer > 0 then
            size = size * (1.-player.death_timer/10)
        end
        player.sprite.scale = Vec2(size)
        player.sprite.color.r = player.hp * 255.0
        player.sprite.color.g = player.hp * 255.0
        player.sprite.color.b = player.hp * 255.0

        if player.death_timer ~= nil and player.death_timer > 0 then
            currentPos = Vec2.clone(currentPos):lerp(player.tail_positions[1], player.death_timer/10)
        end
        engine.draw_sprite(currentPos.x, currentPos.y, player.sprite)
    end
end

local function draw_player_bullets()
    for i, bullet in pairs(player_bullets) do
        local bullet_pos = bullet.position
        local connected_bullet = bullet.connected_bullet
        player_bullet_sprite.color.r = player.hp * 255.
        player_bullet_sprite.color.g = player.hp * 255.
        player_bullet_sprite.color.b = player.hp * 255.
        player_bullet_sprite.scale = Vec2(1)
        -- if connected_bullet ~= nil then
        --     local connected_bullet_pos = connected_bullet.position
        --     local color = Color(255)

        --     if connected_bullet.removed then
        --         if bullet.connection_timer == nil then
        --             bullet.connection_timer = 0
        --         end

        --         bullet.connection_timer = bullet.connection_timer + 1

        --         color = Color(255 - bullet.connection_timer * 12)
        --     end
        --     engine.draw_line(bullet_pos.x, bullet_pos.y, connected_bullet_pos.x, connected_bullet_pos.y, color) 
        -- end

        engine.draw_sprite(bullet_pos.x, bullet_pos.y, player_bullet_sprite)
    end
end

local function draw_enemies()    
    for i, enemy in pairs(enemies) do
        local pos = enemy.position
        local sprite = enemy.sprite
        local offset = enemy.offset
        local tail_positions = enemy.tail_positions
        local scale = 1
        local dir = bool_to_number(enemy.position.x > player.tail_positions[1].x)

         engine.draw_sprite(pos.x - offset.x, pos.y - offset.y, sprite)

        if enemy.killed then
            if enemy.death_timer == nil then
                enemy.death_timer = 1
            end
            scale = 1.-(enemy.death_timer / 10)

            if enemy.death_particles == nil then
                enemy.death_particles = { }

                for i = 1, 5 do
                    local angle = math.random() * 360
                    local speed = Vec2(1,0):rotate(Vec2.zero(), angle) * 80 * delta_time
                    local particle = {
                        sprite = deepcopy(enemy_tail_sprite),
                        speed = speed,
                        position = enemy.position + enemy.offset
                    }

                    particle.sprite.scale = Vec2(1)

                    table.insert(enemy.death_particles, particle)
                end
            end

            for i, particle in pairs(enemy.death_particles) do
                particle.position = particle.position + particle.speed
                particle.speed = particle.speed * .91
                local pos = particle.position
                particle.sprite.scale = Vec2((1.- (enemy.death_timer / 10)))
                engine.draw_sprite(pos.x, pos.y, particle.sprite)
            end
        end
        
        sprite.scale = Vec2(scale)

        tail_positions[1] = enemy.position + Vec2(2 * dir,2)
        tail_positions[1] = tail_positions[1]:lerp(enemy.position, 1.-scale)
        for i = 2, ENEMY_TAIL_PARTS_COUNT do
            local diff = Vec2.normalize(tail_positions[i] - tail_positions[i - 1])

            local fixed_pos = tail_positions[1] + (Vec2(i - 1, 0) * dir)
            local dynamic_pos = tail_positions[i - 1] + (diff * scale) 
            tail_positions[i] = fixed_pos:lerp(dynamic_pos, i / ENEMY_TAIL_PARTS_COUNT)
        end

        for i = 2, ENEMY_TAIL_PARTS_COUNT do
            local tail_pos = tail_positions[i]
            enemy_tail_sprite.scale = Vec2(.1)
            engine.draw_sprite(tail_pos.x, tail_pos.y, enemy_tail_sprite)
        end
    end
end

local function get_player_dir()
    if (engine.key_down(keys.right)) then
        if (engine.key_down(keys.down)) then
            return Vec2(1,1):normalize()
        elseif (engine.key_down(keys.up)) then
            return Vec2(1,-1):normalize()
        else return Vec2(1,0)
        end
    elseif (engine.key_down(keys.left)) then
        if (engine.key_down(keys.down)) then
            return Vec2(-1,1):normalize()
        elseif (engine.key_down(keys.up)) then
            return Vec2(-1,-1):normalize()
        else return Vec2(-1,0)
        end
    elseif (engine.key_down(keys.down)) then
        if (engine.key_down(keys.left)) then
            return Vec2(-1,-1):normalize()
        elseif (engine.key_down(keys.right)) then
            return Vec2(1,-1):normalize()
        else return Vec2(0,1)
        end
    elseif (engine.key_down(keys.up)) then
        if (engine.key_down(keys.left)) then
            return Vec2(-1,-1):normalize()
        elseif (engine.key_down(keys.right)) then
            return Vec2(-1,1):normalize()
        else return Vec2(0,-1)
        end
    else return Vec2.zero()
    end
end

local function add_enemy(position)
    local enemy = {
        position = position,
        sprite = deepcopy(enemy_sprite),
        offset = Vec2(0,1),
        tail_positions = { },
        shoot_timer = 0,
        speed = Vec2.zero(),
        radius = 4,
        angle_offset = math.random() * 40 - 20
    }

    for i = 0, ENEMY_TAIL_PARTS_COUNT do
        enemy.tail_positions[i] = Vec2.zero()
    end

    table.insert(enemies,enemy)
end

local function add_bullet(position, speed, sprite, bulletList)
    local bullet = {
        position = position,
        speed = speed,
        sprite = deepcopy(sprite),
        removed = false
    }

    table.insert(bulletList, bullet)
    return bullet
end

local function remove_bullet(index, bulletList)
    local bullet = bulletList[index]
    table.remove(bulletList, index)
end

local function remove_enemy(index)
    table.remove(enemies, index)
end

local function update_enemy_bullets(index)
    for i, bullet in pairs(enemy_bullets) do
        bullet.position = bullet.position + bullet.speed
        local sprite = bullet.sprite
        local bullet_radius = sprite.width / 2
        local player_radius = player.sprite.width / 2

        if not collision_rectangle(bullet.position, Vec2(sprite.width, sprite.height), screen_size / 2, screen_size) then
            remove_bullet(i, enemy_bullets)
        end

        if collision_circle(bullet.position, bullet_radius, player.tail_positions[1], player_radius) then
            player.is_dead = true
        end
    end
end

local function update_player_bullets()
    for i, bullet in pairs(player_bullets) do
        bullet.position = bullet.position + bullet.speed
        local sprite = bullet.sprite

        if not collision_rectangle(bullet.position, Vec2(sprite.width, sprite.height), screen_size / 2, screen_size) then
           bullet.removed = true
        end
        if not collision_rectangle(bullet.position, Vec2(sprite.width * 2, sprite.height * 2), screen_size / 2, screen_size) then
            remove_bullet(i, player_bullets)
         end

        for k, enemy in pairs(enemies) do
            local sprite = enemy.sprite
            if collision_circle(
                enemy.position,
                enemy.sprite.width / 2,
                bullet.position,
                bullet.sprite.width / 2) then
                    enemy.killed = true
                    remove_bullet(i, player_bullets)
            end
        end
    end
end

local function get_random_vec2_box(x, y, sizeX, sizeY)
    local randX = math.random() * sizeX + x
    local randY = math.random() * sizeY + y

    return Vec2(randX, randY)
end

local function update_enemies()
    enemy_spawn_timer = enemy_spawn_timer + delta_time

    if enemy_spawn_timer >= 1 then
        enemy_spawn_timer = 0

        local rand_pos
        local spawn_point = math.floor((math.random()) * 4)
        
        if spawn_point == 0 then
            rand_pos = get_random_vec2_box(-15, -10, 10, screen_height + 20)
        elseif spawn_point == 1 then
            rand_pos = get_random_vec2_box(screen_width + 5, -10, 10, screen_height + 20)
        elseif spawn_point == 2 then
            rand_pos = get_random_vec2_box(-15, -10, screen_width + 30, 10)
        elseif spawn_point == 3 then
            rand_pos = get_random_vec2_box(-15, screen_height + 5, screen_width + 30, 10)
        end

        add_enemy(rand_pos)
    end

    for i, enemy in pairs(enemies) do
        local tail_positions = enemy.tail_positions
        
        local distance_to_player = (enemy.position - player.tail_positions[1]):length()
        local angle_offset = enemy.angle_offset * (math.min(180, distance_to_player) / 180)
        
        local angle = math.angle_between_points(player.tail_positions[1], enemy.position) + angle_offset
        local speed = Vec2(1, 0):rotate(Vec2(0), math.deg_to_rad(angle)) * Vec2(BULLET_SPEED * delta_time / 4)
        enemy.position = enemy.position + speed

        if  not enemy.killed and 
            collision_circle(
                enemy.position + enemy.offset,
                enemy.radius,
                player.tail_positions[1],
                player.sprite.width / 2) then
            player.is_dead = true
        end

        enemy.shoot_timer = enemy.shoot_timer + delta_time

        if enemy.killed then
            if enemy.death_timer == nil then 
                enemy.death_timer = 0
                player.hp = player.hp + .1
                player.hp = math.max(player.hp, 1)
            end

            enemy.death_timer = enemy.death_timer + 1

            if enemy.death_timer >= 10 then
                remove_enemy(i, enemies)
            end
        end
        -- if enemy.shoot_timer > .8 then
        --     enemy.shoot_timer = 0

        --     local angle = math.angle_between_points(player.tail_positions[1], enemy.position)
        --     local random_angle_offset = math.random() * 20 - 10
        --     angle = angle - random_angle_offset

        --     local speed = Vec2(BULLET_SPEED * delta_time / 2, 0):rotate(Vec2(0), math.deg_to_rad(angle))

        --     add_bullet(enemy.position, speed, enemy_bullet_sprite, enemy_bullets)
        -- end
    end
end

local function adjust_player_position()
    local player_pos = player.tail_positions[1]
    local playerRadius = player.sprite.width / 2

    if (player_pos.x + playerRadius > screen_width) then
        player_pos.x = screen_width - playerRadius
    end
    if (player_pos.x - playerRadius < 0) then
        player_pos.x = playerRadius
    end
    if (player_pos.y - playerRadius < 0) then
        player_pos.y = playerRadius
    end
    if (player_pos.y + playerRadius > screen_height) then
        player_pos.y = screen_height - playerRadius
    end
end

local function update_player()
    if player.is_dead then
        return
    end

    player.hp = player.hp - delta_time * .1
    
    local tail_positions = player.tail_positions
    local player_pos = tail_positions[1]
    local dir = get_player_dir()

    if engine.key_pressed(keys.x) then
        player.is_dashing = true

        if not player.stared_dashing then
            player.linear_speed = DASH_BASE_SPEED
            player.stared_dashing = true
        end
    end

    if player.is_dashing and player.linear_speed <= PLAYER_BASE_SPEED then
        player.is_dashing = false
        player.stared_dashing = false
    end

    if dir:length() > 0 and not player.is_dashing then
        player.linear_speed = PLAYER_BASE_SPEED
    end

    player.direction = dir
    if dir:length() > 0 then
        player.last_direction = dir
    end

    tail_positions[1] = tail_positions[1] + player.speed * delta_time

    if (dir:length() == 0) then
        player.linear_speed = math.max(0, player.linear_speed - 16)
    end

    if player.is_dashing then
        player.linear_speed = math.max(0, player.linear_speed - 32)
        player.linear_speed = math.max(player.linear_speed, PLAYER_BASE_SPEED)
    end

    player.speed = player.last_direction * player.linear_speed
    adjust_player_position()

    if engine.key_down(keys.z) then
        if not player.locked_direction_saved then
            player.locked_direction_saved = true
            player.locked_direction = player.last_direction
        end
    else
        player.locked_direction_saved = false
    end

    for i = 2, TAIL_PARTS_COUNT do
        local diff = Vec2.normalize(tail_positions[i] - tail_positions[i - 1])

         if engine.key_down(keys.z) then
            local locked_dir = player.locked_direction       
            local fixed_pos = tail_positions[1] - locked_dir * ( i - 1)
            local dynamic_pos = tail_positions[i - 1] + diff
            tail_positions[i] = fixed_pos:lerp(dynamic_pos, i / TAIL_PARTS_COUNT)
        else
            tail_positions[i] = tail_positions[i - 1] + diff
        end
    end

    player.last_position = tail_positions[1]

    bullet_timer = bullet_timer + delta_time

    if engine.key_down(keys.c) and bullet_timer > .1 then

        bullet_timer = 0
        local dir = player.direction
        if dir:length() == 0 then
            dir = player.last_direction
        end

        local bullet_direction = Vec2.zero()
        if engine.key_down(keys.z) then
            bullet_direction = player.locked_direction
        else
            bullet_direction = dir
        end

        local new_bullet = add_bullet(
            player.tail_positions[1],
            bullet_direction * BULLET_SPEED * delta_time,
            player_bullet_sprite,
            player_bullets)

        local index = nil
        local min_distance = 999999
        for i, bullet in pairs(player_bullets) do
            if bullet ~= new_bullet and not bullet.removed then            
                local distance = (bullet.position - new_bullet.position):length()
                if min_distance > distance then
                    index = i
                    min_distance = distance
                end
            end
        end

        local connected_bullet = player_bullets[index]
        if connected_bullet ~= nil and min_distance <= 90 then
            new_bullet.connected_bullet = connected_bullet
        end
    end
end

local function draw_enemy_bullets()
    for i, bullet in pairs(enemy_bullets) do
        local bulletPos = bullet.position
        engine.draw_sprite(bulletPos.x, bulletPos.y, bullet.sprite)
    end
end

local function try_append_0_to_time(time)
    if string.len(time) < 2 then
        time = "0" .. time
    end

    return time
end

local function draw_time()
    local time_minutes = try_append_0_to_time(tostring(math.floor(time / 60)))
    local time_seconds = try_append_0_to_time(tostring(math.mod(math.floor(time), 60)))
    local time_milliseconds = ""
    if time > 0 then 
        time_milliseconds = string.sub(tostring(time - math.floor(time)), 3, 4)
    else 
        time_milliseconds = "00"
    end

   -- engine.fill_rectangle(-1, -1, 80, 17, Color(0))
    engine.draw_text(
        5, 4, font,
        time_minutes .. ":" .. time_seconds .. ":" .. time_milliseconds, Color(255))
    engine.draw_rectangle(-1, -1, 80, 17, Color(255))
end

local function draw_main_menu()
    if not in_main_menu then
        return
    end

    local play_button_pos = Vec2(180 - 34, 80)
    local exit_button_pos = Vec2(180 - 34, 100)
    local current_button = menu_current_button_sprite

    engine.draw_text(play_button_pos.x, play_button_pos.y, font, "PLAY", Color(255))
    engine.draw_text(exit_button_pos.x, exit_button_pos.y, font, "EXIT", Color(255))

    if selected_button == "PLAY" then
        engine.draw_sprite(
            play_button_pos.x + current_button.width / 2 - 3,
            play_button_pos.y + current_button.height / 2 - 2,
            current_button)
    else 
        engine.draw_sprite(
            exit_button_pos.x + current_button.width / 2 - 3,
            exit_button_pos.y + current_button.height / 2 - 2,
            current_button)
    end
end

local function on_draw()
    if not in_main_menu then
        engine.begin_layer(game_layer)
        draw_player_bullets()
        draw_enemies()
        draw_enemy_bullets()
        draw_player()
        engine.end_current_layer()
    end
    engine.begin_layer(ui_layer)
    draw_time()
    if in_main_menu then
        draw_main_menu()
    end
    --engine.draw_text(mouse_position.x, mouse_position.y, font, tostring(math.floor(time)), Color(255))
    engine.end_current_layer()
end

local function start_game()
    in_main_menu = false
    player.death_timer = 0
    player.is_dead = false
    player.tail_positions[1] = screen_size / 2
    enemies = { }
    enemy_bullets = {}
end

local function update_main_menu()
    if not in_main_menu then
        return
    end

    if engine.key_pressed(keys.down) and selected_button ~= "EXIT" then
        selected_button = "EXIT"
    elseif engine.key_pressed(keys.up) and selected_button ~= "PLAY" then
        selected_button = "PLAY"
    end

    if engine.key_pressed(keys.c) then
        if selected_button == "EXIT" then
            engine.terminate()
        else
            start_game()
        end
    end
end

local function reset_game()
    time = 0
    in_main_menu = true
    player.hp = 1
    player.can_shoot = false
end

local function on_update()
    mouse_position = engine.get_mouse_position(game_layer)
    
    if not in_main_menu then
        time = time + delta_time
        update_player()
        update_player_bullets()
        update_enemies()
        update_enemy_bullets()

        if player.is_dead and player.death_timer ~= nil and player.death_timer > 10 then
            reset_game()
        end
        if player.hp <= 0 then
            reset_game()
        end
    else
        update_main_menu()
    end
end

engine.on_start(on_start)
engine.on_update(on_update)
engine.on_draw(on_draw)

engine.enable_fps_counter()

engine.initialize({
    name = "Tetris",
    width = 320 * 4,
    height = 180 * 4,
    frequency = frequency
})

math.randomseed(os.time())
font = engine.Font(0, 10, "font.xml")

engine.run()