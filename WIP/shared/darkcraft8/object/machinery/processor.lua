-- Machinery that produce ressource/item logic is here
function D8Machinery:processorLogic(dt, self)
    --sb.logInfo("producerLogic, dt = %s, timer = %s", dt, self.timer)
    object.setConfigParameter("ressources", self.scriptConfig.ressources)
    if self.timer > 0 and not self.recipeProgress.inProgress then
        self.timer = self.timer - dt
    elseif not self.recipeProgress.inProgress then
        self.timer = 2.5
        
        local foundRecipe = self:checkAvailableRecipes() -- to be redone
        --sb.logInfo("foundRecipe %s", foundRecipe)
        if foundRecipe then return end
        self.hurryUp = 0
    elseif self.recipeProgress.inProgress then
        if (self.hurryUp or 0) > 0 then
            self.hurryUp = self.hurryUp - self.recipeProgress.duration
            self.recipeProgress.duration = -1
        end
        self:recipesUpdate(dt)
    end
end

function D8Machinery:craftItem()
    local hasSpace = self:hasSpace()
    
    if hasSpace or self.recipeProgress.nextRecipe.fill then
        if self.recipeProgress.nextRecipe.fill then
            local consumedItem = true
            for _, itemInput in ipairs(self.recipeProgress.nextRecipe.inputs) do
                if itemInput.item then
                    local itemAlreadyConsumed = false
                    if not itemInput.slot then
                        for _, slot in ipairs(self.scriptConfig.slotConfig.input) do 
                            local slotitem = world.containerItemAt(entity.id(), slot - 1)
                            --sb.logInfo("itemInput %s", itemInput)
                            --sb.logInfo("slot %s", slot)
                            --sb.logInfo("slotitem %s", slotitem)
                            if slotitem then
                                if slotitem.name == itemInput.item then
                                    if not itemAlreadyConsumed then
                                        local consumed = world.containerConsumeAt(entity.id(), slot-1, itemInput.count)
                                        if consumed == false then
                                            consumedItem = consumed
                                        elseif consumed == true then
                                            itemAlreadyConsumed = true
                                        end
                                    end
                                end
                            end
                        end
                    else
                        if not itemAlreadyConsumed then
                            local consumed = world.containerConsumeAt(entity.id(), itemInput.slot-1, itemInput.count)
                            if consumed == false then
                                consumedItem = consumed
                            elseif consumed == true then
                                itemAlreadyConsumed = true
                            end
                        end
                    end
                elseif itemInput.ressource then
                    local prev = self.scriptConfig.ressources[itemInput.ressource]
                    local after = self.scriptConfig.ressources[itemInput.ressource] - itemInput.count
                    if prev ~= after then
                        self.scriptConfig.ressources[itemInput.ressource] = self.scriptConfig.ressources[itemInput.ressource] - itemInput.count
                    else
                        consumedItem = false
                    end
                end
            end
            if consumedItem then
                --sb.logInfo("consumedItem %s", consumedItem)
                --sb.logInfo("self.scriptConfig.ressources %s", self.scriptConfig.ressources)
                sb.logInfo("itemsFitWhere %s, %s", self:itemsFitWhere(true))
            end
        else
            local consumedItem = true
            for _, itemInput in ipairs(self.recipeProgress.nextRecipe.inputs) do
                if itemInput.item then
                    local itemAlreadyConsumed = false
                    if not itemInput.slot then
                        for _, slot in ipairs(self.scriptConfig.slotConfig.input) do 
                            local slotitem = world.containerItemAt(entity.id(), slot - 1)
                            --sb.logInfo("itemInput %s", itemInput)
                            --sb.logInfo("slot %s", slot)
                            --sb.logInfo("slotitem %s", slotitem)
                            if slotitem then
                                if slotitem.name == itemInput.item then
                                    if not itemAlreadyConsumed then
                                        local consumed = world.containerConsumeAt(entity.id(), slot-1, itemInput.count)
                                        if consumed == false then
                                            consumedItem = consumed
                                        elseif consumed == true then
                                            itemAlreadyConsumed = true
                                        end
                                    end
                                end
                            end
                        end
                    else
                        if not itemAlreadyConsumed then
                            local consumed = world.containerConsumeAt(entity.id(), itemInput.slot-1, itemInput.count)
                            if consumed == false then
                                consumedItem = consumed
                            elseif consumed == true then
                                itemAlreadyConsumed = true
                            end
                        end
                    end
                elseif itemInput.ressource then
                    local prev = self.scriptConfig.ressources[itemInput.ressource]
                    local after = self.scriptConfig.ressources[itemInput.ressource] - itemInput.count

                    if prev ~= after then
                        self.scriptConfig.ressources[itemInput.ressource] = self.scriptConfig.ressources[itemInput.ressource] - itemInput.count
                    else
                        consumedItem = false
                    end
                end
            end
            if consumedItem then
                for index, item in ipairs(self.recipeProgress.nextRecipe.outputs) do
                        local addedItem = nil
                        local finished = nil
                        local slotOffset = 0
                        if item.item then
                            for _, _ in ipairs(self.scriptConfig.slotConfig.input) do 
                                slotOffset = slotOffset + 1
                            end
                            while not finished do
                                local prevItemSlot = world.containerItemAt(entity.id(), slotOffset)
                                world.containerPutItemsAt(entity.id(), item, slotOffset)
                                if input.slot then
                                    addedItem = world.containerItemAt(entity.id(), input.slot - 1)
                                    --sb.logInfo("%s", addedItem)
                                else
                                    addedItem = world.containerItemAt(entity.id(), slotOffset)
                                end
                                slotOffset = slotOffset + 1
                                if sb.printJson(prevItemSlot) ~= sb.printJson(addedItem) then
                                    if addedItem or slotOffset > self.scriptConfig.slotConfig.output[#self.scriptConfig.slotConfig.output] then
                                        --sb.logInfo("%s, %s", slotOffset + 1, addedItem)
                                        finished = true
                                    end
                                end
                            end
                        elseif item.ressource then
                            self.scriptConfig.ressources[item.ressource] = (self.scriptConfig.ressources[item.ressource] or 0) + item.count
                        end
                end
                
                local currentItems = world.containerItems(entity.id())
                local currentRessoures = self.scriptConfig.ressources
                local hasAllRequirement = self:hasRequirement(currentItems, currentRessoures)
                if hasAllRequirement then
                    self.recipeProgress.duration = self.recipeProgress.nextRecipe.duration or 1
                else
                    self.recipeProgress = {}
                    self.timer = 2.5
                    script.setUpdateDelta(5)
                end
            end
        end
    else
        self.recipeProgress = {}
        self.timer = 2.5
        script.setUpdateDelta(5)
    return end
end


function D8Machinery:recipesPopulate() -- if string then root if table then if string root if table then add to list
    if type(self.scriptConfig["recipes"]) == "string" then
        local root = root.assetJson(self.scriptConfig["recipes"])
        for i, v in ipairs(root) do
            table.insert(self.recipeList, v)
        end
    elseif type(self.scriptConfig["recipes"]) == "table" then
        for i, v in ipairs(self.scriptConfig["recipes"]) do
            if type(v) == "string" then
                local root = root.assetJson(v)
                for i2, v2 in ipairs(root) do
                    table.insert(self.recipeList, v2)
                end
            elseif type(v) == "table" then
                table.insert(self.recipeList, v)
            end
        end
    end
end

function D8Machinery:checkAvailableRecipes()
    local currentItems = world.containerItems(entity.id())
    local currentRessoures = self.scriptConfig.ressources

    --sb.logInfo("\ncurrentItems %s\ncurrentRessoures %s", sb.printJson(currentItems, 1), sb.printJson(currentRessoures, 1))
    
    local nextRecipe = self:hasRequirement(currentItems, currentRessoures, true)
    if nextRecipe then
        local hasSpace = self:hasSpace(nextRecipe)
        if hasSpace or nextRecipe.fill then
            if nextRecipe.fill then
                for i, v in ipairs(nextRecipe.outputs) do
                    local hasItem = world.containerAvailable(entity.id(), v)
                    
                    if hasItem == 0 then
                        script.setUpdateDelta(5)
                    return else
                        hasItem = false
                        for i2, v2 in pairs(world.containerItems(entity.id())) do
                            for i3, v3 in pairs(v.parameters) do
                                if v2["parameters"][i3] < v3 then
                                    hasItem = true
                                end
                            end
                        end
                        if not hasItem then
                            script.setUpdateDelta(5)
                        return end
                    end
                end
            end
            
            self.recipeProgress.nextRecipe = nextRecipe
            self.recipeProgress.duration = nextRecipe.duration or 1

            self.recipeProgress.inProgress = true
            self.timer = self.recipeProgress.duration
            script.setUpdateDelta(1)
            return true
        else
            script.setUpdateDelta(5)
        end
    else
        script.setUpdateDelta(5)
    return end
end
function D8Machinery:recipesUpdate(dt)
    --Input Check--
    local currentItems = world.containerItems(entity.id())
    local currentRessoures = self.scriptConfig.ressources
    local hasAllRequirement = self:hasRequirement(currentItems, currentRessoures)
    
    if self.recipeProgress.nextRecipe.fill then
        for i, v in ipairs(self.recipeProgress.nextRecipe.outputs) do
            local hasItem = world.containerAvailable(entity.id(), v)
            if hasItem == 0 then
                self.recipeProgress = {}
                script.setUpdateDelta(5)
            return else
                hasItem = false
                for i2, v2 in pairs(world.containerItems(entity.id())) do
                    for i3, v3 in pairs(v.parameters) do
                        if v2["parameters"][i3] < v3 then
                            hasItem = true
                        end
                    end
                end
                if not hasItem then
                    self.recipeProgress = {}
                    script.setUpdateDelta(5)
                return end
            end
        end
    end
    if hasAllRequirement then
        if self.recipeProgress.duration > 0 then
            self.recipeProgress.duration = self.recipeProgress.duration - (dt)
            if self.recipeProgress.duration <= 0 then
                self.recipeProgress.duration = 0
            end
            --sb.logInfo("recipeProgress.duration = %s", self.recipeProgress.duration)
        else
            self:craftItem()
        end
    else
        self.recipeProgress = {}
        script.setUpdateDelta(5)
    end
end

function D8Machinery:hasSpace(nextRecipe)
    local currentItems = world.containerItems(entity.id())
    local hasSpace = true
    local recipeCfg = nextRecipe
    if not recipeCfg then
        recipeCfg = self.recipeProgress.nextRecipe
    end
    for index, item in ipairs(recipeCfg.outputs) do
        if item.item then
            local canFit = world.containerItemsFitWhere(entity.id(), item)-- world.containerItemsCanFit(entity.id(), item)
            --sb.logInfo("%s", canFit)
            for _, slotIndex in ipairs(self.scriptConfig.slotConfig.input) do 
                if canFit["slots"][1] == slotIndex - 1 then
                    hasSpace = false
                end
            end
        end
    end

    return hasSpace
end

function D8Machinery:hasRequirement(currentItems, currentRessoures, recipeList)
    if recipeList then
        for i, v in ipairs(self.recipeList) do
            local hasAllRequirement = true
            --sb.logInfo("%s, %s", i,hasAllRequirement)
            for index, input in ipairs(v.inputs) do 
                if input.item then
                    local hasItem = 0
                    hasItem = world.containerAvailable(entity.id(), input)
                    if hasItem > 0 then
                        if input.slot then
                            if currentItems[input.slot] then
                                if currentItems[input.slot]["count"] < input.count then
                                    hasItem = 0
                                end
                            end
                        else
                            for _, index2 in ipairs(self.scriptConfig.slotConfig.input) do 
                                if currentItems[index2 - 1] then
                                    if currentItems[index2 - 1]["count"] < input.count then
                                        hasItem = 0
                                    else
                                        hasItem = 1
                                    end
                                end
                            end
                        end
                    end
                    if hasItem == 0 then
                        hasAllRequirement = false
                    end
                elseif input.ressource then
                    if currentRessoures[input.ressource] < input.count then
                        hasAllRequirement = false
                    end
                    --sb.logInfo("%s = %s, %s", input.ressource, currentRessoures[input.ressource], hasAllRequirement)
                end

            end
            --sb.logInfo("%s, %s", i,hasAllRequirement)
            if hasAllRequirement then
                return v
            end
        end

        return nil
    else
        for index, input in ipairs(self.recipeProgress.nextRecipe.inputs) do 
            if input.item then
                local hasItem = 0
                hasItem = world.containerAvailable(entity.id(), input)
                if hasItem > 0 then
                    if input.slot then
                        if currentItems[input.slot] then
                            if currentItems[input.slot]["count"] < input.count then
                                hasItem = 0
                            end
                        end
                    else
                        for index2, _ in ipairs(self.scriptConfig.slotConfig.input) do 
                            if currentItems[index2] then
                                if currentItems[index2]["count"] < input.count then
                                    hasItem = 0
                                else
                                    hasItem = 1
                                end
                            end
                        end
                    end
                end
                if hasItem == 0 then
                    return false
                end
            elseif input.ressource then
                if currentRessoures[input.ressource] < input.count then
                    hasAllRequirement = false
                end
            end
        end

        return true
    end
end

function D8Machinery:itemsFitWhere(debug)
    local currentItems = world.containerItems(entity.id())
    local currentRessoures = self.scriptConfig.ressources
    local result1, result2 = false, nil

    for _, i in ipairs(self.scriptConfig.slotConfig.output) do
        local fit = false
        if debug then
            sb.logInfo("currentItem n'%s, %s", i, currentItems[i])
        end
        if currentItems[i] then
            for _, outputCfg in ipairs(self.recipeProgress.nextRecipe.outputs) do
                sb.logInfo("outputCfg %s", v)
                for i2, v2 in pairs(outputCfg.parameters) do
                    sb.logInfo("i2 %s, v2 %s", i2, v2 )
                end
            end
        end
        if fit then
            result1, result2 = i, currentItems[i]
        end
    end

    return result1, result2
end