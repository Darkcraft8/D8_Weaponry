function configBehavior(behaviorName)
    local list = root.assetJson("/WIP/customweaponscriptrewritelol/_item/buildscript/JPBAI/behaviorList.config")
    local behaviorConfigPath = list[behaviorName]
    if behaviorConfigPath then return root.assetJson(behaviorConfigPath) end
end

function setupBehavior(config, parameters, behaviorName, fireType)
    local configParameter = function(keyName, defaultValue)
        if parameters[keyName] ~= nil then
            return parameters[keyName]
        elseif config[keyName] ~= nil then
            return config[keyName]
        else
            return defaultValue
        end
    end
    local cfg = configBehavior(behaviorName)
    
    if not cfg then return end
    if cfg.overrideRule then
        for path, override in pairs(cfg.overrideRule) do 
            local param = fetchCfg(cfg, path)
            local overrideValue = configParameter("buildConfig")[override]

            if param then
                setCfg(cfg, path, overrideValue)
            end
        end
    end
    local newConfig = util.mergeTable(cfg, config)
end

function addBehavior()

end

function setCfg(config, path, newValue)
    local pathSegment = segmentPath(path)
    local newConfig = {}
    local search
    local currentStage = {}
    --sb.logInfo("path %s", path)
    for index, string in ipairs(pathSegment) do
        search = (tonumber(string) or string)
        --sb.logInfo("%s ~= %s = %s\n[Search] %s\n[CurrentStage] %s", index, #pathSegment, index ~= #pathSegment, search, (currentStage[search] or config[search]))
        currentStage = (currentStage[search] or config[search])
        if newConfig then
            if currentStage then
                if index ~= #pathSegment then
                    newConfig[search] = currentStage
                else
                    newConfig[search] = newValue
                    break
                end
            else
                if index ~= #pathSegment then return end
                break
            end
        else
            sb.logError("Function [setCfg] Errored")
        end
    end
    --sb.logInfo("config %s", sb.printJson(newConfig, 1))
    --sb.logInfo("currentResult %s", sb.printJson(config, 1))
end

function fetchCfg(config, path, defaultValue)
    local pathSegment = segmentPath(path)
    local currentResult = nil
    for _, string in ipairs(pathSegment) do
      if not currentResult then 
        if config[string] then
            currentResult = config[string]
        elseif tonumber(string) then
            if config[tonumber(string)] then
                currentResult = config[tonumber(string)]
            end
        else return
        end
      else
        if currentResult[string] then
            currentResult = currentResult[string]
        elseif tonumber(string) then
            if currentResult[tonumber(string)] then
                currentResult = currentResult[tonumber(string)]
            end
        else return
        end
      end
    end

    if currentResult ~= nil then
        return currentResult
    else
        return defaultValue
    end
end

function fetchConfigParam(config, parameters, path, defaultValue)
    local configParameter = function(keyName, defaultValue)
        if parameters[keyName] ~= nil then
            return parameters[keyName]
        elseif config[keyName] ~= nil then
            return config[keyName]
        else
            return defaultValue
        end
    end

    local pathSegment = segmentPath(path)
    local currentResult = nil
    for _, string in ipairs(pathSegment) do
      if not currentResult then 
        if configParameter(string) then
            currentResult = configParameter(string)
        end
      else
        if currentResult[string] then
            currentResult = currentResult[string]
        end
      end
      sb.logInfo("currentResult %s", currentResult)
    end

    if currentResult ~= nil then
        return currentResult
    else
        return defaultValue
    end
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