--Function for container slots
D8Machinery_slotUtil = {}
function D8Machinery_slotUtil:findItem(item, slotTable, exactMatch)
    local currentRessoures = D8Machinery.scriptConfig.ressources
    local item = copy(item)
    if item then
        if item.item and not item.name then item.name = item.item item.item = nil end
        if not item.parameters then item.parameters = {} end

        for _, i in ipairs(slotTable or {}) do
            local slotItem = world.containerItemAt(entity.id(), i)
            if root.itemDescriptorsMatch(slotItem, item, exactMatch or false) then
                return i, slotItem
            end
        end
    end
end

function D8Machinery_slotUtil:findSpace(itemTable, slotTable)
    local spacesTable
    for i, v in ipairs(itemTable) do
        if v.item or v.name then
            local possibleSlot = self:ItemsFitWhere(v)
            for _, slot in ipairs(slotTable) do
                if possibleSlot["slots"][slot] > 0 then
                    if not spacesTable then spacesTable = {} end
                    spacesTable[slot] = possibleSlot["slots"][slot]
                end
            end
        end
    end
    
    return spacesTable
end

function D8Machinery_slotUtil:ItemsFitWhere(itemCfg)
    local item = copy(itemCfg)
    local slotCount = world.getObjectParameter(entity.id(), "slotCount", 0)
    local currentSlot = 0
    local result = {
        slots = {}
    }
    local previousCount = copy(itemCfg)["count"]
    while currentSlot < slotCount do 
        local slotItem = world.containerItemAt(entity.id(), currentSlot)
        local applyResult = world.containerItemApply(entity.id(), item, currentSlot)

        if root.itemDescriptorsMatch(item, slotItem, true) then
            item = applyResult
        end

        if not applyResult then --All item where placed :D
            result.slots[currentSlot] = previousCount
            self:setSlotItem(slotItem, currentSlot) -- remove test and give back previous amount test
        else -- Either some or no item where placed D:
            if root.itemDescriptorsMatch(item, slotItem, true) then --item overflow slot
                local itemCountDiff = previousCount - item.count
                result.slots[currentSlot] = itemCountDiff
            else --different items
                result.slots[currentSlot] = 0
            end
            self:setSlotItem(slotItem, currentSlot) -- remove test and give back previous amount test
        end
        currentSlot = currentSlot + 1
    end
    return result
end

function D8Machinery_slotUtil:addItem(itemCfg, slot)
    if type(slot) ~= "table" then
        slot = {slot}
    end

    for slotI, slotV in ipairs(slot) do
        if itemCfg.name or itemCfg.item then
            itemCfg = world.containerPutItemsAt(entity.id(), itemCfg, slotV)
            if not itemCfg then break end
            if slotI == #slot then
                return itemCfg
            end
        end
    end
end

function D8Machinery_slotUtil:addItems(itemTable, slotTable)
    local resultTable = {}
    if not itemTable and not slotTable then 
        if type(itemTable) ~= "table" and type(slotTable) ~= "table" then return end end
        
    for itemI, itemV in ipairs(itemTable) do
        local itemV = copy(itemV)
        local result = self:addItem(itemV, slotTable)
        if result then table.insert(resultTable, result) end
    end

    if resultTable[1] then return resultTable end
end

function D8Machinery_slotUtil:setSlotItem(item, slot) --Allow to easily set the item in a slot
    if slot then
        world.containerTakeAt(entity.id(), slot)
        if item then
            world.containerPutItemsAt(entity.id(), item, slot)
        end
    end
end

function D8Machinery_slotUtil:removeItemsIn(itemTable, slotTable, exactMatch)
    local removedAllItems = true
    for _, item in ipairs(itemTable) do
        if item.item then
            local atSlot, foundItem = self:findItem(item, slotTable, exactMatch)
            if atSlot then
                removedAllItems = world.containerConsumeAt(entity.id(), atSlot, item.count)
            else
                removedAllItems = false
            end
        end
    end
    return removedAllItems
end