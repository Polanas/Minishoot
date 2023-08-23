local function Emitter()
    local emitter = {}
    local events = {}

    function emitter:on(name, listener)
        local listeners = events[name]

        if not listeners then
            listeners = {
                listener
            }

            events[name] = listeners

            return
        end

        table.insert(listeners, listener)
    end

    function emitter:off(name, listener)
        local listeners = events[name]

        if listeners == nil then
            return
        end

        for i, item in ipairs(listeners) do
            if listener == item then
                table.remove(listeners, i)
                break
            end
        end
    end

    function emitter:get_listeners(name)
        local result = {}
        local listeners = events[name]

        if listeners ~= nil then
            for _, listener in ipairs(listeners) do
                table.insert(result, listener)
            end
        end

        return result
    end

    function emitter:emit(name, arguments)
        local listeners = events[name]

        if listeners == nil then
            return
        end

        if arguments == nil then
            arguments = {}
        end

        for _, listener in ipairs(listeners) do
            listener(unpack(arguments))
        end
    end

    return emitter
end

return Emitter