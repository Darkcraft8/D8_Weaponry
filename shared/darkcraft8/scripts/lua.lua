-- a few function change for my convenience --
local _type = type
preciseType = function(...)
    local typeReturn = _type(...)
    if typeReturn == "table" then
        local arg = ...
        if arg["op"] and arg["path"] then return "jsonPatch" end
        if #arg == 0 then return "array" end
    end
    return typeReturn
end