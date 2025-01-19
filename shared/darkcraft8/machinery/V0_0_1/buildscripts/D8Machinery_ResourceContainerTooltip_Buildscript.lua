require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
--BuildScript for object/item containing Resources
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
  local pathSearch = function(path, defaultValue)
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
      local currentResult = nil
      for _, string in ipairs(pathSegment) do
        if not currentResult then 
          currentResult = configParameter(string, "failed")
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

  if (level or configParameter("level", 1)) and not configParameter("fixedLevel", true) then
    if configParameter("level") then parameters.level = (level or configParameter("level", 1)) end
    if configParameter("resourceMax") then parameters.resourceMax = configParameter("resourceMax", 5) * parameters.level end
  end

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

  -- populate tooltip fields
  if config.tooltipKind ~= "base" then
    config.tooltipFields = config.tooltipFields or {}

    if not config.tooltipFields.rarityLabel then --Rarity Colors
      if string.lower(config.rarity) == "uncommon" then
        config.tooltipFields.rarityLabel = "^green;Uncommon^reset;"
      elseif string.lower(config.rarity) == "rare" then
        config.tooltipFields.rarityLabel = "^Cyan;Rare^reset;"
      elseif  string.lower(config.rarity) == "legendary" then
        config.tooltipFields.rarityLabel = "^magenta;Legendary^reset;"
      elseif  string.lower(config.rarity) == "essential" then
        config.tooltipFields.rarityLabel = "^orange;Essential^reset;"
      end
    end

    --Resources Config
    if configParameter("buildConfig") then
      local buildConfig = configParameter("buildConfig", {})
      config.description = string.gsub(config.description, "<resource1Label>", buildConfig.resource1Label or "Unknown")
      config.description = string.gsub(config.description, "<resource2Label>", buildConfig.resource1Label or "Unknown")
      config.description = string.gsub(config.description, "<resource3Label>", buildConfig.resource1Label or "Unknown")
      config.description = string.gsub(config.description, "<resource4Label>", buildConfig.resource1Label or "Unknown")
      config.description = string.gsub(config.description, "<resource5Label>", buildConfig.resource1Label or "Unknown")
      config.description = string.gsub(config.description, "<resource6Label>", buildConfig.resource1Label or "Unknown")

      if buildConfig.resource1Label then config.tooltipFields.resource1NameLabel = buildConfig.resource1Label end
      if buildConfig.resource2Label then config.tooltipFields.resource2NameLabel = buildConfig.resource2Label end
      if buildConfig.resource3Label then config.tooltipFields.resource3NameLabel = buildConfig.resource3Label end
      if buildConfig.resource4Label then config.tooltipFields.resource4NameLabel = buildConfig.resource4Label end
      if buildConfig.resource5Label then config.tooltipFields.resource5NameLabel = buildConfig.resource5Label end
      if buildConfig.resource6Label then config.tooltipFields.resource6NameLabel = buildConfig.resource6Label end

      if buildConfig.resourcePath then
        
        if buildConfig.resourcePath.resource1Amount then config.tooltipFields.resource1AmountLabel = "" .. pathSearch(buildConfig.resourcePath.resource1Amount, 0) .. "/" .. pathSearch(buildConfig.resourcePath.resource1MaxAmount, "'Inf'") end
        if buildConfig.resourcePath.resource2Amount then config.tooltipFields.resource2AmountLabel = "" .. pathSearch(buildConfig.resourcePath.resource2Amount, 0) .. "/" .. pathSearch(buildConfig.resourcePath.resource2MaxAmount, "'Inf'") end
        if buildConfig.resourcePath.resource3Amount then config.tooltipFields.resource3AmountLabel = "" .. pathSearch(buildConfig.resourcePath.resource3Amount, 0) .. "/" .. pathSearch(buildConfig.resourcePath.resource3MaxAmount, "'Inf'") end
        if buildConfig.resourcePath.resource4Amount then config.tooltipFields.resource4AmountLabel = "" .. pathSearch(buildConfig.resourcePath.resource4Amount, 0) .. "/" .. pathSearch(buildConfig.resourcePath.resource4MaxAmount, "'Inf'") end
        if buildConfig.resourcePath.resource5Amount then config.tooltipFields.resource5AmountLabel = "" .. pathSearch(buildConfig.resourcePath.resource5Amount, 0) .. "/" .. pathSearch(buildConfig.resourcePath.resource5MaxAmount, "'Inf'") end
        if buildConfig.resourcePath.resource6Amount then config.tooltipFields.resource6AmountLabel = "" .. pathSearch(buildConfig.resourcePath.resource6Amount, 0) .. "/" .. pathSearch(buildConfig.resourcePath.resource6MaxAmount, "'Inf'") end

        if buildConfig.resourcePath.resource1MaxAmount then config.description = string.gsub(config.description, "<resource1.maxAmount>", pathSearch(buildConfig.resourcePath.resource1MaxAmount, "'Inf'")) end
        if buildConfig.resourcePath.resource2MaxAmount then config.description = string.gsub(config.description, "<resource2.maxAmount>", pathSearch(buildConfig.resourcePath.resource2MaxAmount, "'Inf'")) end
        if buildConfig.resourcePath.resource3MaxAmount then config.description = string.gsub(config.description, "<resource3.maxAmount>", pathSearch(buildConfig.resourcePath.resource3MaxAmount, "'Inf'")) end
        if buildConfig.resourcePath.resource4MaxAmount then config.description = string.gsub(config.description, "<resource4.maxAmount>", pathSearch(buildConfig.resourcePath.resource4MaxAmount, "'Inf'")) end
        if buildConfig.resourcePath.resource5MaxAmount then config.description = string.gsub(config.description, "<resource5.maxAmount>", pathSearch(buildConfig.resourcePath.resource5MaxAmount, "'Inf'")) end
        if buildConfig.resourcePath.resource6MaxAmount then config.description = string.gsub(config.description, "<resource6.maxAmount>", pathSearch(buildConfig.resourcePath.resource6MaxAmount, "'Inf'")) end
      end
      
      --parameters.description = config.description
    end

  end

  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0)
  return config, parameters
end