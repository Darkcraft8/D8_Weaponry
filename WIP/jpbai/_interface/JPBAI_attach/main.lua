
swapSlotItem = nil
function init()
    getCurrentItem()
end

function uninit()
    giveCurrentItemBack()
end

function updateItemIcon()
    widget.setItemSlotItem("itemIcon", swapSlotItem)
end

function getCurrentItem()
    swapSlotItem = player.swapSlotItem()
    player.setSwapSlotItem(nil)
    updateItemIcon()
end

function giveCurrentItemBack()
    if not player.swapSlotItem() then
        player.setSwapSlotItem(swapSlotItem)
    else
        player.giveItem(swapSlotItem)
    end
end

function getParameter(variable, defaultValue) -- return the value of the variable in "parameters" or nil otherwise
    return swapSlotItem["parameters"][variable] or defaultValue
end

function getConfig(variable, defaultValue) -- return the value of the variable in "config" or nil otherwise
    return root.itemConfig(swapSlotItem)["config"][variable] or defaultValue
end