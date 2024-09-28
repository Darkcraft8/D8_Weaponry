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
  
  if (level or configParameter("level", 1)) and not configParameter("fixedLevel", false) then
    parameters.level = (level or configParameter("level", 1))
  end
  parameters.d8Weaponry_resetTooltipOnUpgrade = configParameter("d8Weaponry_resetTooltipOnUpgrade", true)

  setupAbility(config, parameters, "primary")
  setupAbility(config, parameters, "alt")

  -- elemental type and config (for alt ability)
  local elementalType = configParameter("elementalType", "physical")
  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if config.altAbility and config.altAbility.elementalConfig then
    util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType])
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
    local ammoCost = ((config[config.primaryAbility.ammoMaxName] or 2) - (config.primaryAbility.stances.ammoCost or 1))
    config.tooltipFields.dpsLabel = util.round((config.primaryAbility.baseDps or 0) * config.damageLevelMultiplier, 1)
    config.tooltipFields.speedLabel = util.round(1 / (config.primaryAbility.fireTime or 1.0), 1)
    local reloadTime = 0
    for stancesName, value in pairs(config.primaryAbility.stances) do 
      if string.find(stancesName, "reload") and value.duration then
        reloadTime = reloadTime + value.duration
      end
    end
    config.tooltipFields.reloadLabel = string.format("Reload: ~%s", reloadTime)
    config.tooltipFields.damagePerShotLabel = util.round((config.primaryAbility.baseDamage or (config.primaryAbility.baseDps / (ammoCost / (ammoCost*(8/ammoCost) ) ) ) ) * (config.primaryAbility.baseDamageMultiplier or 1.0) * (config.primaryAbility.damageLevelMultiplier or 1.0) / (config.primaryAbility.projectileCount or 1), 1)
    config.tooltipFields.energyPerShotLabel = util.round((config.primaryAbility.energyUsage or 0) * (config.primaryAbility.fireTime or 1.0), 1)
    
    if string.lower(config.rarity) == "uncommon" then
      config.tooltipFields.rarityLabel = "^green;Uncommon^reset;"
    elseif string.lower(config.rarity) == "rare" then
      config.tooltipFields.rarityLabel = "^Cyan;Rare^reset;"
    elseif  string.lower(config.rarity) == "legendary" then
      config.tooltipFields.rarityLabel = "^magenta;Legendary^reset;"
    elseif  string.lower(config.rarity) == "essential" then
      config.tooltipFields.rarityLabel = "^orange;Essential^reset;"
    end

    if elementalType ~= "physical" then
      config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
    end
    if config.primaryAbility then
      config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
      config.tooltipFields.primaryAbilityLabel = config.primaryAbility.name or "unknown"
      
      config.tooltipFields.ammo1NameLabel = config.primaryAbility.ammoName or config.primaryAbility.ammoType
      if type(config.primaryAbility.ammoType) ~= "string" then
        config.tooltipFields.ammo1NameLabel = config.primaryAbility.ammoType.name
      end
      config.tooltipFields.ammo1CapacityTitleLabel = "Primary Capacity:"
      config.tooltipFields.ammo1TitleLabel = "Primary Amount:"
      config.tooltipFields.ammo1CapacityLabel = config[config.primaryAbility.ammoMaxName] or "unknown"
      config.tooltipFields.ammo1Label = config[config.primaryAbility.ammoCountName] or "unknown"
    end

    if config.altAbility then
      config.tooltipFields.altAbilityTitleLabel = "Special:"
      config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
      
      if   config.primaryAbility.ammoCountName ~= config.altAbility.ammoCountName
      and config.primaryAbility.ammoMaxName ~= config.altAbility.ammoMaxName
      and config.altAbility.ammoMaxName
      and config.altAbility.ammoCountName then
   
        config.tooltipFields.ammo2NameLabel = config.altAbility.ammoName or config.altAbility.ammoType
        if type(config.altAbility.ammoType) ~= "string" then
          config.tooltipFields.ammo2NameLabel = config.altAbility.ammoType.name
        end
        config.tooltipFields.ammo2CapacityTitleLabel = "Alt Capacity:"
        config.tooltipFields.ammo2TitleLabel = "Alt Amount:"
        config.tooltipFields.ammo2CapacityLabel = config[config.altAbility.ammoMaxName] or "unknown"
        config.tooltipFields.ammo2Label = config[config.altAbility.ammoCountName] or "unknown"
      end
     
    end
  end
  -- populate parameters d8Weaponry 
  if config.d8Weaponry then
    parameters.d8Weaponry = config.d8Weaponry
  end

  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end