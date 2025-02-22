-- because sometime config.getParameter is drunk --
function getParameter(variable, defaultValue) -- return the value of the variable in "parameters" or nil otherwise
    local itemCfg = item.descriptor()
    return itemCfg["parameters"][variable] or defaultValue
end

function getConfig(variable, defaultValue) -- return the value of the variable in "config" or nil otherwise
    local itemCfg = root.itemConfig(item.descriptor())
    return itemCfg["config"][variable] or defaultValue
end