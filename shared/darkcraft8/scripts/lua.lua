-- a few function for convenience --
local _type = type
preciseType = function(...) -- has a few extra if statement to find what specificaly it is
    local typeReturn = _type(...)
    if typeReturn == "table" then
        local arg = ...
        if arg["op"] and arg["path"] then return "jsonPatch" end
        --if #arg == 2 and type(arg[1]) == "number" and type(arg[2]) == "number" then return "vec2" end
        if #arg == 0 then return "array" end
    end
    return typeReturn
end