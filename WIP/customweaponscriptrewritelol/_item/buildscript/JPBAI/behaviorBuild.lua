require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua" -- it here for it replacePatternInData function
require "/WIP/customweaponscriptrewritelol/_item/buildscript/JPBAI/behavior.lua"
function build(directory, config, parameters, level, seed)
    local configParameter = function(keyName, defaultValue)
        if parameters[keyName] ~= nil then
            return parameters[keyName]
        elseif config[keyName] ~= nil then
            return config[keyName]
        else
            return defaultValue
        end
    end
      
    if (level or parameters["level"]) and not configParameter("fixedLevel", false) then
        parameters.level = (level or configParameter("level", 1))
    end

    if configParameter("buildConfig") then 
        for behaviorName, fireType in pairs(configParameter("buildConfig")["behavior"]) do 
            setupBehavior(config, parameters, behaviorName, fireType)
        end
    end

    local elementalType = configParameter("elementalType", "physical")
    replacePatternInData(config, nil, "<elementalType>", elementalType)
    local tooltipList = root.assetJson("/WIP/customweaponscriptrewritelol/_item/buildscript/JPBAI/tooltip/tooltipList.config")
    if tooltipList[configParameter("tooltipKind", "base")] then
        config.tooltipFields = config.tooltipFields or {}
        -- Yup this mean you can add func to build tooltip simply by adding it name and path to the toolTipList
        local tooltipLib = tooltipList[configParameter("tooltipKind", "base")]
        require(tooltipLib)
        if _ENV.tooltip then tooltip(config, parameters) end
    end

    config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

    return config, parameters
end