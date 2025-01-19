--Base for machine pane

function init()
end

function update()
    objectParameters = world.getObjectParameter(pane.containerEntityId(), '', {})
    if objectParameters.D8Machinery_paneParam then
        drawRessource(objectParameters)
        --drawProgressBar(objectParameters.D8Machinery_paneParam.globalInit, objectParameters.D8Machinery_paneParam.globalDuration)
    end
end

function uninit()
end

--A few usefull function
function callFunction(path, args1, args2, args3, args4, args5) --Call the function after checking for any dot as to not get the jankiness of table.func
    local func, error = getFunction(path)
    if not error then
        if string.find(path, "[.:]") then
            func(nil, args1, args2, args3, args4, args5) --puting nil as first args because function in table LOVE to eat them up
        else
            func(args1, args2, args3, args4, args5)
        end
    end
end

function getFunction(path) --Search and and send back the last found function
    local pathSegment = segmentatePath(path)
    local currentResult = nil
    for _, string in ipairs(pathSegment) do
      if not currentResult then 
        currentResult = _ENV[string]
      else
        currentResult = currentResult[string]
      end
    end
    if currentResult ~= nil then
      return currentResult
    else
      return nil, "Error: Function Not Found"
    end
end

function getParameter(path, defaultValue) --Basicaly call config.getParameter for the first segment of the path and then search up
    local pathSegment = segmentatePath(path)
    local currentResult = nil
    for _, string in ipairs(pathSegment) do
      if not currentResult then 
        currentResult = config.getParameter(string, {})
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

function segmentatePath(path) --Segmentate the path from [.:]
    local pathSegment = {}
    if string.find(path, "[.:]") then
      while string.find(path, "[.:]") do
        local dotNumber = string.find(path, "[.:]")
        if dotNumber then
          table.insert(pathSegment, string.sub(path, 1, dotNumber - 1))
          path = string.sub(path, dotNumber + 1, string.len(path))
        end
      end
    end
    table.insert(pathSegment, path)

    return pathSegment
end

--D8Machinery focused Function
function getMachineParam()
    return world.getObjectParameter(pane.containerEntityId(), "D8Machinery_paneParam", {})
end

function machineResources()

end

--Test

function drawRessource(objectParameters)
    local resources = config.getParameter("D8Machinery.resources")
    local oxygenAmount = 0
    local hydrogenAmount = 0

    if objectParameters.D8Machinery_paneParam.resources then
        oxygenAmount = objectParameters.D8Machinery_paneParam.resources[resources[1]] or 0
        hydrogenAmount = objectParameters.D8Machinery_paneParam.resources[resources[2]] or 0
    end

    if objectParameters.D8Machinery_paneParam.maxResources then
        if oxygenAmount > objectParameters.D8Machinery_paneParam.maxResources[resources[1]] then
            oxygenAmount = objectParameters.D8Machinery_paneParam.maxResources[resources[1]]
        end
        if hydrogenAmount > objectParameters.D8Machinery_paneParam.maxResources[resources[2]] then
            hydrogenAmount = objectParameters.D8Machinery_paneParam.maxResources[resources[2]]
        end
    end

    if oxygenAmount < 0 then
        oxygenAmount = 0
    end
    if hydrogenAmount < 0 then
        hydrogenAmount = 0
    end

    local oxygenImage = "/assetmissing.png:?replace;ffffff00=ff7800ff?crop;0;0;3;1?scalenearest=1;"
    local hydrogenImage = "/assetmissing.png:?replace;ffffff00=10ff10ff?crop;0;0;3;1?scalenearest=1;"

    local oxygenPercent = oxygenAmount / 100
    local hydrogenPercent = hydrogenAmount / 100
    if objectParameters.D8Machinery_paneParam.maxResources then
        oxygenPercent = (oxygenAmount / objectParameters.D8Machinery_paneParam.maxResources[resources[1]])
        hydrogenPercent = (hydrogenAmount / objectParameters.D8Machinery_paneParam.maxResources[resources[2]])
        if oxygenPercent <= 0 then 
            oxygenPercent = 0.001
        end
        if hydrogenPercent <= 0 then 
            hydrogenPercent = 0.001
        end
    end

    widget.setImage("ressourceOxygen", oxygenImage .. (27 * oxygenPercent))
    widget.setImage("ressourceHydrogen", hydrogenImage .. (27 * hydrogenPercent))
end