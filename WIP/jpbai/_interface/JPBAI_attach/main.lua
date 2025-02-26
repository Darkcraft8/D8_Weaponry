require '/shared/darkcraft8/util/item.lua'

swapSlotItem = nil
function init()
    D8Shared_BuildItemFunction()
    getCurrentItem()
end

function uninit()
    giveCurrentItemBack()
end

function updateItemIcon()
    widget.setItemSlotItem("itemIcon", swapSlotItem)
end

function getCurrentItem()
    swapSlotItem = swapSlotItem 
    if not swapSlotItem then
        swapSlotItem = player.swapSlotItem()
        player.setSwapSlotItem(nil)
    end
    updateItemIcon()
end

function giveCurrentItemBack()
    if not player.swapSlotItem() then
        player.giveItem(swapSlotItem)--player.setSwapSlotItem(swapSlotItem)
    else
        player.giveItem(swapSlotItem)
    end
end