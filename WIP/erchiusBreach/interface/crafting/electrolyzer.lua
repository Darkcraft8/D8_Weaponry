local container_init = init
local container_update = update
local container_uninit = uninit
local container_swapSlot = swapSlot

function init()
    if container_init then container_init() end
    --sb.logInfo("Container Custom Script init")
    sourceEntity = pane.containerEntityId()
    --sb.logInfo("dt %s", sb.printJson(objectParameters, 1))
end

function update(dt)
    if container_update then container_update(dt) end
    --sb.logInfo("dt %s", dt)
    objectParameters = world.getObjectParameter(sourceEntity, '')
    drawRessource(objectParameters)
end

function uninit()
    if container_uninit then container_uninit() end

end

function clear()
    local itemGridItems = widget.itemGridItems("itemGrid2")
    for _, i in ipairs(objectParameters.scriptConfig.slotConfig.output) do
        local itemDescriptor = itemGridItems[i]
        world.containerTakeAt(sourceEntity, i - 1)
        player.giveItem(itemDescriptor)
    end
    --for i, v in pairs(itemGridItems) do
    --    if i ~= 1 and i ~= 2 then
    --        sb.logInfo("%s, %s", i, v)
    --        sb.logInfo("%s", itemGridItems[i])
    --        local itemDescriptor = itemGridItems[i]
    --        world.containerTakeAt(sourceEntity, i - 1)
    --        player.giveItem(itemDescriptor)
    --    end
    --end
end

function drawRessource(objectParameters)
    local oxygenAmount = 0
    if objectParameters.ressources then
        oxygenAmount = objectParameters.ressources.oxygen or 0
    end
    if oxygenAmount > 27 then
        oxygenAmount = 27
    elseif oxygenAmount < 0 then
        oxygenAmount = 0
    end
    local oxygenImage = "/assetmissing.png:?replace;ffffff00=6f6fffff?crop;0;0;3;1?scalenearest=1;"

    local hydrogenAmount = 0
    if objectParameters.ressources then
        hydrogenAmount = objectParameters.ressources.hydrogen or 0
    end
    if hydrogenAmount > 27 then
        hydrogenAmount = 27
    elseif hydrogenAmount < 0 then
        hydrogenAmount = 0
    end
    local hydrogenImage = "/assetmissing.png:?replace;ffffff00=6fff6fff?crop;0;0;3;1?scalenearest=1;"
    widget.setImage("ressourceOxygen", oxygenImage .. oxygenAmount)
    widget.setImage("ressourceHydrogen", hydrogenImage .. hydrogenAmount)
end