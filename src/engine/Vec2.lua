local utils = require("engine/utils")

local function new_vec_2(x, y)
    if y == nil then
        y = x
    end

    local vec2 = {
        x = x,
        y = y
    }

    setmetatable(vec2, {
        __add = function(a, b)
            if type(b) == "number" then
                return new_vec_2(a.x + b, a.y + b)
            end
            return new_vec_2(a.x + b.x, a.y + b.y)
        end,
        __sub = function(a, b)
            if type(b) == "number" then
                return new_vec_2(a.x - b, a.y - b)
            end
            return new_vec_2(a.x - b.x, a.y - b.y)
        end,
        __mul = function(a, b)
            if type(b) == "number" then
                return new_vec_2(a.x * b, a.y * b)
            end
            return new_vec_2(a.x * b.x, a.y * b.y)
        end,
        __div = function(a, b)
            if type(b) == "number" then
                return new_vec_2(a.x / b, a.y / b)
            end
            return new_vec_2(a.x / b.x, a.y / b.y)
        end,
        __unm = function(vec)
            return new_vec_2(-vec.x, -vec.y) 
        end,
    })

    function vec2:add(vec)
        self.x = self.x + vec.x
        self.y = self.y + vec.y

        return self
    end

    function vec2:subtract(vec)
        self.x = self.x - vec.x
        self.y = self.y - vec.y

        return self
    end

    function vec2:multiply_vec2(vec)
        self.x = self.x * vec.x
        self.y = self.y * vec.y

        return self
    end

    function vec2:multiply(number)
        self.x = self.x * number
        self.y = self.y * number

        return self
    end

    function vec2:divide_vec2(vec)
        self.x = self.x / vec.x
        self.y = self.y / vec.y

        return self
    end

    function vec2:divide(number)
        self.x = self.x / number
        self.y = self.y / number

        return self
    end

    function vec2:equals(vec)
        return self.x == vec.x and self.y == vec.y
    end

    function vec2:copy(vec)
        vec.x = self.x
        vec.y = self.y
    end

    function vec2:negate()
        self.x = -self.x
        self.y = -self.y

        return self
    end

    function vec2:get_magnitude()
        local magnitude_squared = self.x ^ 2 + self.y ^ 2
        if magnitude_squared == 0 then
            return 0
        end 
        return math.sqrt(magnitude_squared)
    end

    function vec2:length()
        return self:get_magnitude()
    end

    function vec2:normalize()
        local magnitude = self:get_magnitude()
        if magnitude ~= 0 then
            self:divide(magnitude)
        else
             return new_vec_2(0,0)
        end

        return self
    end

    function vec2:lerp(vec, amount)
        self.x = utils.lerp(self.x, vec.x, amount)
        self.y = utils.lerp(self.y, vec.y, amount)

        return self
    end

    function vec2:floor()
        self.x = math.floor(self.x)
        self.y = math.floor(self.y)

        return self
    end

    function vec2:ceiling()
        self.x = math.ceil(self.x)
        self.y = math.ceil(self.y)

        return self
    end

    function vec2:rotate(pivot, angle)
        local sin = math.sin(angle)
        local cos = math.cos(angle)

        local pivot_x = pivot.x
        local pivot_y = pivot.y

        local delta_x = self.x - pivot_x 
        local delta_y = self.y - pivot_y 

        self.x = delta_x * cos - delta_y * sin + pivot_x
        self.y = delta_x * sin + delta_y * cos + pivot_y

        return self
    end

    function vec2:perpendicular_clockwise()
        return new_vec_2(self.y, -self.x)
    end

    function vec2:perpendicular_couter_clockwise()
        return new_vec_2(-self.y, self.x)
    end

    function vec2:distance(vec)
        return utils.distance(self.x, self.y, vec.x, vec.y)
    end

    function vec2:to_string()
        return "{" .. self.x .. ", " .. self.y .. "}"
    end

    function vec2:clone()
        return new_vec_2(self.x, self.y)
    end

    return vec2
end

local Vec2 = {}

function Vec2.clone(vec)
    return new_vec_2(vec.x, vec.y)
end

function Vec2.normalize(vec)
    return vec:normalize():clone()
end

function Vec2.zero()
    return new_vec_2(0)
end

function Vec2.one()
    return new_vec_2(1)
end

local metatable = {
    __call = function(instance, x, y)
        return new_vec_2(x, y)
    end
}

setmetatable(Vec2, metatable)

return Vec2