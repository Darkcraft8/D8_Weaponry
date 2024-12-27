invUtil = {}
function invUtil:FindValidItem(itemDescriptor, softRequiredParameters) -- Extracted from my fork of gunfire
    local result = copy(itemDescriptor)
    local valueCheck = nil
    for name, value in pairs(softRequiredParameters or {}) do
      result.parameters[name] = itemDescriptor.parameters[name]
      if type(value) == "number" and not valueCheck then
        valueCheck = name
      end
    end
    
    repeat
      local hasItem = player.hasItem(result, true)
      --sb.logInfo("hasItem %s, item %s", hasItem, result)
      if hasItem then return result end
      for name, value in pairs(softRequiredParameters) do
        if type(value) == "number" then
          result.parameters[name] = result.parameters[name] - 1
        end
      end
    until result.parameters[valueCheck] < softRequiredParameters[valueCheck]
  
    return result
end