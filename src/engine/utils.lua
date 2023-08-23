local LOG_PREFIX = "[ENGINE] "

local utils = {}

function utils.inherit(parent, instance)
    if instance == nil then
        instance = {}
    end

    setmetatable(instance, {
        __index = parent
    })

    return instance
end

function utils.set_c_lib_metatable(instance, lib, prefix)
    local function find_function(table, key)
        local func_name = prefix .. key
        return lib[func_name]
    end

    setmetatable(instance, {
        __index = find_function
    })
end

function utils.clear_table(table)
    for i, _ in pairs(table) do
        table[i] = nil
    end
end

function utils.table_contains(table, value)
    for _, item in ipairs(table) do
        if item == value then
            return true
        end
    end

    return false
end

function utils.remove(array, value)
    for index, item in ipairs(array) do
        if item == value then
            table.remove(array, index)

            break
        end
    end
end

function utils.read_file(path)
    local file = io.open(path)

    if file == nil then
        return
    end

    local data = file:read("*all")
    file:close()
    
    return data
end

function utils.clamp(value, min, max)
    value = math.max(value, min)
    value = math.min(value, max)

    return value
end

function utils.lerp(from, to, amount)
    amount = utils.clamp(amount, 0, 1)

    return from + (to - from) * amount
end

function utils.sign(value)
    if value > 0 then
        return 1
    elseif value == 0 then
        return 0
    end

    return -1
end

function utils.distance(x1, y1, x2, y2)
    local delta_x = x2 - x1
    local delta_y = y2 - y1

    local distance = math.sqrt(delta_x ^ 2 + delta_y ^ 2)

    return distance
end

function utils.log(text)
    print(LOG_PREFIX .. text)
end

function utils.get_directory_files(directory)
    local result = io.popen("dir" .. [[ "]] .. directory .. [[" ]] .. "/b")

    if result == nil then
        return nil
    end

    return result:lines()
end

function utils.to_char_array(text)
    return string.gmatch(text, ".")
end

function utils.concat_paths(path1, path2)
    return path1 .. "/" .. path2
end

return utils