local _config, _parameters
function configBehavior(behaviorName)
    local list = root.assetJson("/WIP/customweaponscriptrewritelol/_item/buildscript/JPBAI/behaviorList.config")
    local behaviorConfigPath = list[behaviorName]
    if behaviorConfigPath then return root.assetJson(behaviorConfigPath) end
end

function setupBehavior(config, parameters, behaviorName, fireType)
    _config, _parameters = config, parameters
    local configParameter = function(keyName, defaultValue)
        if _parameters[keyName] ~= nil then
            return _parameters[keyName]
        elseif _config[keyName] ~= nil then
            return _config[keyName]
        else
            return defaultValue
        end
    end
    local cfg = configBehavior(behaviorName)
    
    if not cfg then return end
    if _config.buildConfig.override then
        for var, val in pairs(_config.buildConfig.override or {}) do
            replaceInData(cfg, nil, "<"..var..">", val)
        end
    end
    local newConfig = util.mergeTable(cfg, config)
    return newConfig
end