require("/D8Weaponry/activeitem/JPBAI/module/specialised/d8Weap/localRenderUtil.lua")

function tooltip(config, parameters, configParameter)
    --[[configParameter = function(keyName, defaultValue)
        if parameters[keyName] ~= nil then
            return parameters[keyName]
        elseif config[keyName] ~= nil then
            return config[keyName]
        else
            return defaultValue
        end
    end]]
    if string.lower(configParameter("rarity", "common")) == "uncommon" then
        config.tooltipFields.rarityLabel = "^green;Uncommon^reset;"
    elseif string.lower(configParameter("rarity", "common")) == "rare" then
        config.tooltipFields.rarityLabel = "^Cyan;Rare^reset;"
    elseif  string.lower(configParameter("rarity", "common")) == "legendary" then
        config.tooltipFields.rarityLabel = "^magenta;Legendary^reset;"
    elseif  string.lower(configParameter("rarity", "common")) == "essential" then
        config.tooltipFields.rarityLabel = "^orange;Essential^reset;"
    end
    
    config.tooltipFields.damagePerShotTitleLabel = "Damage Per Magazine:"
    config.tooltipFields.damagePerShotLabel = "0" -- Handled by item Scripts
    local behaviors = configParameter("behaviors")
    sb.logInfo("[buildscript] behaviors = %s, %s", config.behaviors, parameters.behaviors)
    if behaviors then
        sb.logInfo("behaviors %s", behaviors)
        sb.logInfo("behaviors[\"reload\"] %s", behaviors["reload"])
        if behaviors["reload"] then
            local reloadTime = stanceDuration(behaviors["reload"]["stance"])
            config.tooltipFields.energyPerShotTitleLabel = "Reload:"
            config.tooltipFields.energyPerShotLabel = string.format("~%s", reloadTime)
        end
        if behaviors["fire"] then
            local fireTime = stanceDuration(behaviors["fire"]["stance"])
            config.tooltipFields.speedLabel = tostring(fireTime)
        end
    end
    
    -- config.tooltipFields.magazineImage -- Handled by item script
end

function stanceDuration(stanceName)
    local time = 0
    local stanceName = stanceName
    local stances = configParameter("stances", {})
    if not stanceName then return time end
    time = time + stances[stanceName]["duration"]
    while stances[stanceName]["transition"] do
        stanceName = stances[stanceName]["transition"]
        if stances[stanceName]["transition"] then time = time + stances[stanceName]["duration"] end
    end
    return time
end