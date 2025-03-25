local initTimer = 0.2

function postInit()
    load()
    initTimer = nil
end

function update(dt)
    if initTimer then
        if initTimer > 0 then
            initTimer = initTimer - dt
        else
            postInit()
        end
    end
end

function load()
    widget.setText("opacityMax", property("opacityMax")) 
    widget.setText("positionX", property("posOffset")[1]) 
    widget.setText("positionY", property("posOffset")[2])
    widget.setChecked("numberOnly", property("numberOnly"))
    widget.setChecked("mousePos", property("mousePos"))
end

function confirm_box()
    if widget.hasFocus("opacityMax") then
        widget.blur("opacityMax")
        setProperty("opacityMax", tonumber(widget.getText("opacityMax")))
    end

    if widget.hasFocus("positionX") then
        widget.blur("positionX")
        local vector = {
            tonumber(widget.getText("positionX")),
            tonumber(widget.getText("positionY"))
        }
        setProperty("posOffset", vector)
    end

    if widget.hasFocus("positionY") then
        widget.blur("positionY")
        local vector = {
            tonumber(widget.getText("positionX")),
            tonumber(widget.getText("positionY"))
        }
        setProperty("posOffset", vector)
    end
end

function button(buttonName)
    if buttonName == "numberOnly" then
        setProperty("numberOnly", widget.getChecked(buttonName))
    end
    if buttonName == "mousePos" then
        setProperty("mousePos", widget.getChecked(buttonName))
    end
end

-- Property Function

function setProperty(propertyName, propertyValue)
    local cfg = player.getProperty("d8Weap")
    cfg["renderCfg"][propertyName] = propertyValue
    player.setProperty("d8Weap", cfg)
end

function property(propertyName)
    local cfg = player.getProperty("d8Weap")
    return cfg["renderCfg"][propertyName]
end

function pathSearch(path, defaultValue, table)
    local pathSegment = {}
    local table = table or {}

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
        currentResult = table[string] or config.getParameter(string, "failed")
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