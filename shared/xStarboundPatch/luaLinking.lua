require("/scripts/xSB-param-util.lua")
function xCallbackCheckRequest(keyName) -- adding :Return will give the result given by a callback if any
    local currentCallbackRequest = world.getGlobal(keyName)
    local result = nil
    if currentCallbackRequest then
        for index, request in ipairs(currentCallbackRequest) do
            if not result then result = {} end
            if _ENV["xCallback"] then
                result = xCallback(request) -- To be Set in the respective lua scripts
            end
        end
        world.setGlobal(keyName, nil)
        world.setGlobal(keyName .. ":Return", result or "nihil")
    end
end

function xCallbackSendRequest(keyName, request)
    world.setGlobal(keyName, jsonPack(request))
    while not world.getGlobal(keyName .. ":Return", result) do end
    return world.getGlobal(keyName .. ":Return")
end