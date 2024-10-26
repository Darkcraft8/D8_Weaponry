function D8Machinery:findItem(item, slotTable)
    local currentItems = world.containerItems(entity.id())
    local currentRessoures = self.scriptConfig.ressources
    for _, i in ipairs(slotTable) do
        local slotItem = currentItems[i]
        if slotItem.name == item.item then
            return i, currentItems[i]
        end
    end
end

function D8Machinery:findSpace()

end

function D8Machinery:canMerge()

end