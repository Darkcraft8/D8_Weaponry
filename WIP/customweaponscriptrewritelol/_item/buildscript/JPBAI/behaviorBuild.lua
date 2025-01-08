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

    local elementalType = configParameter("elementalType", "physical")
    replacePatternInData(config, nil, "<elementalType>", elementalType)

    if configParameter("tooltipKind", "base") ~= "base" then
        config.tooltipFields = config.tooltipFields or {}
        -- Yup this mean you can add func to build tooltip simply by adding one to the tooltip folder next to this script
        require("/WIP/customweaponscriptrewritelol/_item/buildscript/JPBAI/tooltip/" .. config.tooltipKind .. ".lua")
        if _ENV.tooltip then tooltip(config, parameters) end
    end

    config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

    return config, parameters
end