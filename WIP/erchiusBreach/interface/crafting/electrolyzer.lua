require "/scripts/util.lua"

local container_init = init
local container_update = update
local container_uninit = uninit
local container_swapSlot = swapSlot

function init()
    if container_init then container_init() end
    sourceEntity = pane.containerEntityId()
    self.progressBarTexture = config.getParameter("gui.progressBar.file")
    --sb.logInfo("message %s", message)
end

function update(dt)
    if container_update then container_update(dt) end
    objectParameters = world.getObjectParameter(sourceEntity, '')
    if objectParameters.D8Machinery_paneParam then
        drawRessource(objectParameters)
        drawProgressBar(objectParameters.D8Machinery_paneParam.globalInit, objectParameters.D8Machinery_paneParam.globalDuration)
    end
end

function uninit()
    if container_uninit then container_uninit() end

end

function takeOutputBtn()
    local itemGridItems = widget.itemGridItems("itemGrid2")
    for _, i in ipairs(objectParameters.scriptConfig.slotConfig.output) do
        local itemDescriptor = itemGridItems[i + 1]
        world.containerTakeAt(sourceEntity, i)
        player.giveItem(itemDescriptor)
    end
end

function clear()
    local itemGridItems = widget.itemGridItems("itemGrid2")
    for _, i in ipairs(objectParameters.scriptConfig.slotConfig.input) do
        local itemDescriptor = itemGridItems[i + 1]
        world.containerTakeAt(sourceEntity, i)
        player.giveItem(itemDescriptor)
    end
    for _, i in ipairs(objectParameters.scriptConfig.slotConfig.output) do
        local itemDescriptor = itemGridItems[i + 1]
        world.containerTakeAt(sourceEntity, i)
        player.giveItem(itemDescriptor)
    end
end

function drawRessource(objectParameters)
    local oxygenAmount = 0
    local hydrogenAmount = 0

    if objectParameters.D8Machinery_paneParam.resources then
        oxygenAmount = objectParameters.D8Machinery_paneParam.resources.oxygen or 0
        hydrogenAmount = objectParameters.D8Machinery_paneParam.resources.hydrogen or 0
    end

    if objectParameters.D8Machinery_paneParam.maxResources then
        if hydrogenAmount > objectParameters.D8Machinery_paneParam.maxResources.hydrogen then
            hydrogenAmount = objectParameters.D8Machinery_paneParam.maxResources.hydrogen
        end
        if oxygenAmount > objectParameters.D8Machinery_paneParam.maxResources.oxygen then
            oxygenAmount = objectParameters.D8Machinery_paneParam.maxResources.oxygen
        end
    end

    if oxygenAmount < 0 then
        oxygenAmount = 0
    end
    if hydrogenAmount < 0 then
        hydrogenAmount = 0
    end

    local oxygenImage = "/assetmissing.png:?replace;ffffff00=6f6fffff?crop;0;0;3;1?scalenearest=1;"
    local hydrogenImage = "/assetmissing.png:?replace;ffffff00=6fff6fff?crop;0;0;3;1?scalenearest=1;"

    local oxygenPercent = oxygenAmount / 100
    local hydrogenPercent = hydrogenAmount / 100
    if objectParameters.D8Machinery_paneParam.maxResources then
        oxygenPercent = (oxygenAmount / objectParameters.D8Machinery_paneParam.maxResources.oxygen)
        hydrogenPercent = (hydrogenAmount / objectParameters.D8Machinery_paneParam.maxResources.hydrogen)
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

function drawProgressBar(initDuration, currentRecipeProgress)
    if currentRecipeProgress and initDuration then
        local percent = currentRecipeProgress / (initDuration or 1)
        local imageSize = root.imageSize(self.progressBarTexture)
        local newImage = copy(self.progressBarTexture)
        
        if imageSize[1]*percent < 0 or imageSize[1]*percent > imageSize[1] then
            newImage = newImage.."?crop;0;0;"..imageSize[1]..";"..imageSize[2]
        else
            newImage = newImage.."?crop;0;0;"..math.ceil(imageSize[1]*percent)..";"..imageSize[2]
        end
        
        widget.setImage("progressBar", newImage)
        widget.setVisible("progressBar", true)
    else
        widget.setVisible("progressBar", false)
    end
end