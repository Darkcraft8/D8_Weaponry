require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"
-- yes it a fork of buildunrandweapon
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
  config.d8Weaponry_resetTooltipOnUpgrade = configParameter("d8Weaponry_resetTooltipOnUpgrade", true)

  setupAbility(config, parameters, "primary")
  setupAbility(config, parameters, "alt")
  local primaryAbility = sb.jsonMerge(config.primaryAbility or {}, parameters.primaryAbility or {})
  local altAbility = sb.jsonMerge(config.altAbility or {}, parameters.altAbility or {})

  -- elemental type and config (for alt ability)
  local elementalType = configParameter("elementalType", "physical")
  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if altAbility and altAbility.elementalConfig then
    util.mergeTable(altAbility, altAbility.elementalConfig[elementalType])
  end

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  -- palette swaps
  config.paletteSwaps = config.paletteSwaps or ""
  if config.palette then
    local palette = root.assetJson(util.absolutePath(directory, config.palette))
    local selectedSwaps = palette.swaps[configParameter("colorIndex", 1)]
    config.paletteSwaps = ""
    for k, v in pairs(selectedSwaps) do
      config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
    end
  end
  if type(config.inventoryIcon) == "string" then
    config.inventoryIcon = config.inventoryIcon .. config.paletteSwaps
  else
    for i, drawable in ipairs(config.inventoryIcon) do
      if drawable.image then drawable.image = drawable.image .. config.paletteSwaps end
    end
  end

  -- gun offsets
  if config.baseOffset then
    construct(config, "animationCustom", "animatedParts", "parts", "middle", "properties")
    config.animationCustom.animatedParts.parts.middle.properties.offset = config.baseOffset
    if config.muzzleOffset then
      config.muzzleOffset = vec2.add(config.muzzleOffset, config.baseOffset)
    end
  end

  -- populate tooltip fields

  if config.tooltipKind ~= "base" then
    config.tooltipFields = config.tooltipFields or {}
    config.tooltipFields.levelLabel = string.format("Level: %s", math.floor(util.round(configParameter("level", 1), 1)))

    local ammoCost = ((config[primaryAbility.ammoMaxName] or 2) - (primaryAbility.stances.ammoCost or 1))
    if ammoCost < 1 then ammoCost = 1 end
  
    config.tooltipFields.speedLabel = util.round(1 / (primaryAbility.fireTime or 1.0), 1)
    local reloadTime = 0
    for stancesName, value in pairs(primaryAbility.stances) do 
      if string.find(stancesName, "reload") and value.duration then
        reloadTime = reloadTime + value.duration
      end
    end
    config.tooltipFields.reloadLabel = string.format("Reload: ~%s", reloadTime)
    config.tooltipFields.damagePerShotLabel = util.round((primaryAbility.baseDamage or (primaryAbility.baseDps / (ammoCost / (ammoCost*(8/ammoCost) ) ) ) ) * (primaryAbility.baseDamageMultiplier or 1.0) * (primaryAbility.damageLevelMultiplier or 1.0) / (primaryAbility.projectileCount or 1), 1) * math.floor(util.round(configParameter("level", 1), 1))
    config.tooltipFields.energyPerShotLabel = util.round((primaryAbility.energyUsage or 0) * (primaryAbility.fireTime or 1.0), 1)
    
    if string.lower(configParameter("rarity")) == "uncommon" then
      config.tooltipFields.rarityLabel = "^green;Uncommon^reset;"
    elseif string.lower(configParameter("rarity")) == "rare" then
      config.tooltipFields.rarityLabel = "^Cyan;Rare^reset;"
    elseif  string.lower(configParameter("rarity")) == "legendary" then
      config.tooltipFields.rarityLabel = "^magenta;Legendary^reset;"
    elseif  string.lower(configParameter("rarity")) == "essential" then
      config.tooltipFields.rarityLabel = "^orange;Essential^reset;"
    end

    if elementalType ~= "physical" then
      config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
    end

    if config.primaryAbility or parameters.primaryAbility then
      config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
      config.tooltipFields.primaryAbilityLabel = primaryAbility.name or "unknown"
      
      config.tooltipFields.ammo1NameLabel = primaryAbility.ammoName or primaryAbility.ammoType
      if type(primaryAbility.ammoType) ~= "string" then
        config.tooltipFields.ammo1NameLabel = primaryAbility.ammoType.name
      end
      config.tooltipFields.ammo1CapacityTitleLabel = "Primary Capacity:"
      config.tooltipFields.ammo1TitleLabel = "Primary Amount:"
      config.tooltipFields.ammo1CapacityLabel = config[primaryAbility.ammoMaxName] or "unknown"
      config.tooltipFields.ammo1Label = config[primaryAbility.ammoCountName] or "unknown"
    end

    if config.altAbility or parameters.altAbility then
      config.tooltipFields.altAbilityTitleLabel = "Special:"
      config.tooltipFields.altAbilityLabel = altAbility.name or "unknown"
      
      if   primaryAbility.ammoCountName ~= altAbility.ammoCountName
      and primaryAbility.ammoMaxName ~= altAbility.ammoMaxName
      and altAbility.ammoMaxName
      and altAbility.ammoCountName then
   
        config.tooltipFields.ammo2NameLabel = altAbility.ammoName or altAbility.ammoType
        if type(altAbility.ammoType) ~= "string" then
          config.tooltipFields.ammo2NameLabel = altAbility.ammoType.name
        end
        config.tooltipFields.ammo2CapacityTitleLabel = "Alt Capacity:"
        config.tooltipFields.ammo2TitleLabel = "Alt Amount:"
        config.tooltipFields.ammo2CapacityLabel = config[altAbility.ammoMaxName] or "unknown"
        config.tooltipFields.ammo2Label = config[altAbility.ammoCountName] or "unknown"
      end
     
    end
  end
  -- populate parameters d8Weaponry 
  if configParameter("d8Weaponry") then
    parameters.d8Weaponry = configParameter("d8Weaponry")
  end

  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end