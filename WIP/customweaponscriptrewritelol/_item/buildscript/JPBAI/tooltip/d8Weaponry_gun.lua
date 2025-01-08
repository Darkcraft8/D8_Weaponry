function tooltip(config, parameters)
    configParameter = function(keyName, defaultValue)
        if parameters[keyName] ~= nil then
            return parameters[keyName]
        elseif config[keyName] ~= nil then
            return config[keyName]
        else
            return defaultValue
        end
    end

    if string.lower(configParameter("rarity", "common")) == "uncommon" then
        config.tooltipFields.rarityLabel = "^green;Uncommon^reset;"
    elseif string.lower(configParameter("rarity", "common")) == "rare" then
        config.tooltipFields.rarityLabel = "^Cyan;Rare^reset;"
    elseif  string.lower(configParameter("rarity", "common")) == "legendary" then
        config.tooltipFields.rarityLabel = "^magenta;Legendary^reset;"
    elseif  string.lower(configParameter("rarity", "common")) == "essential" then
        config.tooltipFields.rarityLabel = "^orange;Essential^reset;"
    end
    local damageTable = {}
    local damageValue = 0
    for _, munition in ipairs(configParameter("magazine", {})) do
        local munition = root.itemConfig(munition)
        local configParam = function(parameter)
            if munition.parameters[parameter] then return munition.parameters[parameter] end
            if munition.config[parameter] then return munition.config[parameter] end
            return default
        end
        local args = {}
        args.type = configParam("projectileType")
        args.count = configParam("projectileCount", 1)
        args.parameter = configParam("projectileParameter", {})

        table.insert(damageTable, damageScaling(args))
    end
    for _, damage in ipairs(damageTable) do 
        local diff = damage - damageValue
        damageValue = damageValue + diff
    end
    config.tooltipFields.damagePerShotLabel = "~"..util.round(damageValue)

    local reloadTime = stanceDuration(configParameter("behaviors", {})["reload"]["stance"])
    config.tooltipFields.energyPerShotTitleLabel = string.format("Reload: ~%s", reloadTime)
    local fireTime = stanceDuration(configParameter("behaviors", {})["fire"]["stance"])
    config.tooltipFields.speedLabel = tostring(fireTime)
end

function stanceDuration(stanceName)
    local reloadTime = 0
    local stanceName = stanceName
    local stances = configParameter("stances", {})
    if not stanceName then return reloadTime end
    reloadTime = reloadTime + stances[stanceName]["duration"]
    while stances[stanceName]["transition"] do
        stanceName = stances[stanceName]["transition"]
        if stances[stanceName]["transition"] then reloadTime = reloadTime + stances[stanceName]["duration"] end
    end
    return reloadTime
end

function damageScaling(args)
    local projectileCfg = sb.jsonMerge(root.projectileConfig(args.type), args.parameters or {})
    local args = args
    args.baseDamage = (projectileCfg.power * 0.25) * (projectileCfg.speed * 0.065)
    args.knockback = (projectileCfg.speed * 0.1) + (args.baseDamage * 0.25)

    local damageLevelMultiplier = configParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1)))
    local mathResult = args.baseDamage or 1
    mathResult = mathResult * (damageLevelMultiplier or 1.0)
    mathResult = mathResult * (damageLevelMultiplier / (args.count or 1))
    
    return mathResult
end