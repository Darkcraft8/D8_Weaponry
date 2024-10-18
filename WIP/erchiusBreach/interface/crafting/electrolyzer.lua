local container_init = init
local container_update = update
local container_uninit = uninit
local container_swapSlot = swapSlot

function init()
    if container_init then container_init() end
    sb.logInfo("Container Custom Script init")
    sourceEntity = pane.containerEntityId()
    --sb.logInfo("dt %s", sb.printJson(objectParameters, 1))
end

function update(dt)
    if container_update then container_update(dt) end
    --sb.logInfo("dt %s", dt)
    objectParameters = world.getObjectParameter(sourceEntity, '')
    local oxygenAmount = 0
    if objectParameters.ressources then
        oxygenAmount = objectParameters.ressources.oxygen or 0
    end
    if oxygenAmount > 50 then
        oxygenAmount = 50
    end
    local oxygenImage = "/assetmissing.png:?replace;ffffff00=6f6fffff?crop;0;0;5;1?scalenearest=1;"

    --sb.logInfo("%s", oxygenImage .. math.ceil(oxygenAmount))
    widget.setImage("ressourceOxygen", oxygenImage .. oxygenAmount)
end

function uninit()
    if container_uninit then container_uninit() end

end

function clear()
    local itemGridItems = widget.itemGridItems("itemGrid2")
    for i, v in pairs(itemGridItems) do
        if i ~= 1 and i ~= 2 then
            --sb.logInfo("%s, %s", i, v)
            local itemDescriptor = itemGridItems[i]
            world.containerTakeAt(sourceEntity, i - 1)
            player.giveItem(itemDescriptor)
        end
    end
end