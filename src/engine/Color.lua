local MAX_VALUE = 255
local MIN_VALUE = 0

local utils = require("engine/utils")

local function clamp(value)
    return utils.clamp(value, MIN_VALUE, MAX_VALUE)
end

local function normalize(value)
    return value / MAX_VALUE
end

local function multiply(value, by)
    local result = math.floor(value * by)
    return clamp(result)
end

local function lerp(value, towards, amount)
    value = utils.lerp(value, towards, amount)
    return clamp(value)
end

local function new_color(r, g, b, a)
    if a == nil then
        a = MAX_VALUE
    end

    if g == nil then
        g = r
    end
    if b == nil then
        b = r
    end

    local color = {
        r = r,
        g = g,
        b = b,
        a = a
    }

    function color:add(value)
        self.r = clamp(self.r + value.r)
        self.g = clamp(self.g + value.g)
        self.b = clamp(self.b + value.b)
        self.a = clamp(self.a + value.a)

        return self
    end

    function color:subtract(value)
        self.r = clamp(self.r - value.r)
        self.g = clamp(self.g - value.g)
        self.b = clamp(self.b - value.b)
        self.a = clamp(self.a - value.a)

        return self
    end

    function color:multiply(value)
        self.r = multiply(self.r, value)
        self.g = multiply(self.g, value)
        self.b = multiply(self.b, value)
        self.a = multiply(self.a, value)

        return self
    end

    function color:divide_raw(value)
        self.r = self.r / value
        self.g = self.g / value
        self.b = self.b / value
        self.a = self.a / value

        return self
    end

    function color:multiply_raw(value)
        self.r = self.r * value
        self.g = self.g * value
        self.b = self.b * value
        self.a = self.a * value

        return self
    end

    function color:multiply_color(color)
        self.r = multiply(self.r, color.r)
        self.g = multiply(self.g, color.g)
        self.b = multiply(self.b, color.b)
        self.a = multiply(self.a, color.a)

        return self
    end

    function color:multiply_color_raw(color)
        self.r = self.r * color.r
        self.g = self.g * color.g
        self.b = self.b * color.b
        self.a = self.a * color.a

        return self
    end

    function color:lerp(towards, value)
        self.r = lerp(self.r, towards.r, value)
        self.g = lerp(self.g, towards.g, value)
        self.b = lerp(self.b, towards.b, value)
        self.a = lerp(self.a, towards.a, value)

        return self
    end

    function color:clamp()
        self.r = clamp(self.r)
        self.g = clamp(self.g)
        self.b = clamp(self.b)
        self.a = clamp(self.a)

        return self
    end

    function color:equals(color)
        return self.r == color.a and self.g == color.g and self.b == color.b and self.a == color.a
    end

    function color:r_normalized()
        return normalize(self.r)
    end

    function color:g_normalized()
        return normalize(self.g)
    end

    function color:b_normalized()
        return normalize(self.b)
    end

    function color:a_normalized()
        return normalize(self.a)
    end

    return color
end

local Color = {}

function Color.white()
    return new_color(255, 255, 255)
end

function Color.black()
    return new_color(0, 0, 0)
end

function Color.transparent()
    return new_color(0, 0, 0, 0)
end

function Color.red()
    return new_color(255, 0, 0)
end

function Color.green()
    return new_color(0, 255, 0)
end

function Color.blue()
    return new_color(0, 0, 255)
end

function Color.clone(color)
    return new_color(color.r, color.g, color.b, color.a)
end

setmetatable(Color, {
    __call = function(instance, r, g, b, a)
        return new_color(r, g, b, a)
    end
})

return Color