require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"
-- Json Powered Behavioral Active Item >:D
-- or JPBAI for short
-- a bunch of list for frequent func type
initFunc = {
    "activeItemCfg",
    "initStances",
    "initBehavior",
    "configInit"
}
updateFunc = { -- just so that incase a script need to 
    "behaviorUpdate",
    "updateStance"
}
uninitFunc = {
    "uninitBehavior",
    "uninitStance"
}

require "/WIP/customweaponscriptrewritelol/JPBAI Module/behavior.lua"
require "/WIP/customweaponscriptrewritelol/JPBAI Module/behaviorEX.lua"
require "/WIP/customweaponscriptrewritelol/JPBAI Module/animation.lua"
require "/WIP/customweaponscriptrewritelol/JPBAI Module/inventory.lua"
require "/WIP/customweaponscriptrewritelol/JPBAI Module/stance.lua"

function init()
    for _, func in ipairs(initFunc) do
        if type(func) == "function" then
            func()
        else
            local callback = findCallback(func)
            callback()
        end
    end
    for _, func in ipairs(config.getParameter("initFunction", {})) do 
        if type(func) == "function" then
            func()
        else
            local callback = findCallback(func)
            callback()
        end
    end
end

function update(dt, fireMode, isShiftHeld, currentMove)
    for _, func in ipairs(updateFunc) do 
        if type(func) == "function" then
            func(dt, fireMode, isShiftHeld, currentMove)
        else
            local callback = findCallback(func)
            callback(dt, fireMode, isShiftHeld, currentMove)
        end
    end
end

function uninit()
    for _, func in ipairs(uninitFunc, {}) do 
        if type(func) == "function" then
            func()
        else
            local callback = findCallback(func)
            callback()
        end
    end
    for _, func in ipairs(config.getParameter("uninitFunction", {})) do
        if type(func) == "function" then
            func()
        else
            local callback = findCallback(func)
            callback()
        end
    end
end

function activeItemCfg()
    self.coroutine = {} -- here just so that i don't have to make a new func just for it
end

-- getParameters Replacement, modified a bit from Encyclopedia
function configInit()
    customConfig = {}
    customConfig.rootParameter = config.getParameter
    customConfig.getParameter = function(path, defaultValue)
        if path == "" then return util.mergeTable(config.param, config.rootParameter('')) end -- lua asked for all the parameters data
        local pathSegment = segmentPath(path)
        local currentResult = nil
        for _, string in ipairs(pathSegment) do
            if not currentResult then 
                if config.rootParameter(string) then
                    currentResult = config.rootParameter(string)
                else
                    return defaultValue
                end
            else
                if currentResult[string] then
                    currentResult = currentResult[string]
                else
                    return defaultValue
                end
            end
        end
        if currentResult ~= nil then
            return currentResult
        else
            return defaultValue
        end
    end
    config = customConfig
    --sb.logInfo("Config Override Initialisation Done\nconfig.rootParameter | Vanilla getParameter\nconfig.getParameter  | getParameter from a list that can get updated using setParameter")
end

function segmentPath(path)
    local pathSegment = {}
    if string.find(path, "[.]") then
    while string.find(path, "[.]") do
        local dotNumber = string.find(path, "[.]")
        if dotNumber then
        table.insert(pathSegment, string.sub(path, 1, dotNumber - 1))
        path = string.sub(path, dotNumber + 1, string.len(path))
        end
    end
    end
    table.insert(pathSegment, path)
    return pathSegment
end

function call(eventCfg) -- because whe can't directly do _ENV[funcGroup.Func]()
    if type(eventCfg) == "string" then
        callback = findCallback(tostring(eventCfg))
        if callback then return callback() end
    else
        callback = findCallback(tostring(eventCfg.callback))
        if callback then return callback(eventCfg.args) end
    end
end

function findCallback(functionPath)
    local findCallback = function(path)
        local pathSegment = {}
        if string.find(path, "[.:]") then
          while string.find(path, "[.:]") do
            local dotNumber = string.find(path, "[.:]")
            if dotNumber then
              table.insert(pathSegment, string.sub(path, 1, dotNumber - 1))
              path = string.sub(path, dotNumber + 1, string.len(path))
            end
          end
        end
        table.insert(pathSegment, path)
        local currentResult = nil
        for _, string in ipairs(pathSegment) do
          if not currentResult then 
            currentResult = _ENV[string]
          else
            currentResult = currentResult[string]
          end
        end
        if currentResult ~= nil then
          return currentResult
        else
          return defaultValue
        end
    end
    local callback = findCallback(functionPath)
    return callback
end