local D8Machinery = {
    type = "Producer",
    recipeList = {},
    recipeProgress = {
    },
    uninitTime = nil,
    hurryUp = 0
}
local initTimer = 2
function D8Machinery:init()
    self.scriptConfig = config.getParameter("scriptConfig")
    self.timer = 0
    --sb.logInfo("D8Machinery Init")
    --sb.logInfo("%s", self.scriptConfig)
    if config.getParameter("scriptStorage") then
        storage = config.getParameter("scriptStorage")
        object.setConfigParameter("scriptStorage", nil)
    end
    if storage.scriptConfig then
        if storage.scriptConfig.ressources then
            self.scriptConfig.ressources = storage.scriptConfig.ressources
        end
    end
    self:recipesPopulate()
    --sb.logInfo("recipeList %s", self.recipeList)
    --self.hurryUp = 10000000000 -- For Testing the time boost
end

function D8Machinery:hurryUpBoostMath() --Give a Massive Speed Boost to the logics to catch up after uninit
    local prevTime = config.getParameter("uninitTime")
    local newTime = world.time()
    local test1, test2 = world.time()
    if (self.hurryUp or 0) < 0 then
        self.hurryUp = 0
    end
    if (newTime - prevTime) > 0 then
        self.hurryUp = (self.hurryUp or 0) + newTime - prevTime
    else
        self.hurryUp = (self.hurryUp or 0)
    end
    --sb.logInfo("%s - %s = %s = hurryUp",  newTime, prevTime, self.hurryUp)
end

function D8Machinery:update(dt)
    if initTimer > 0 then
        initTimer = initTimer - 1
    elseif initTimer ~= -404 then -- PostInit because init is sometime weird
        if config.getParameter("uninitTime") then
            self:hurryUpBoostMath()
        end
        initTimer = -404
        --sb.logInfo("containerItems %s", sb.printJson(world.containerItems(entity.id()), 1))
        --sb.logInfo("Post Init")
    else
        object.setConfigParameter("ressources", self.scriptConfig.ressources)
        if self.timer > 0 and not self.recipeProgress.inProgress then
            self.timer = self.timer - dt
        elseif not self.recipeProgress.inProgress then
            self.timer = 2.5
            
            local foundRecipe = self:checkAvailableRecipes()
            if foundRecipe then return end
            self.hurryUp = 0
        elseif self.recipeProgress.inProgress then
            if (self.hurryUp or 0) > 0 then
                self.hurryUp = self.hurryUp - self.recipeProgress.duration
                self.recipeProgress.duration = -1
                --sb.logInfo("updateDt %s, inProgress %s, hurryUp %s", script.updateDt(), self.recipeProgress.inProgress or false, self.hurryUp)
            end
            self:recipesUpdate(dt)
    
        end
        --sb.logInfo("timer = %s", self.timer)
        --sb.logInfo("hurryUp = %s", (self.hurryUp or 0))
        --sb.logInfo("updateDt %s, inProgress %s, hurryUp %s", script.updateDt(), self.recipeProgress.inProgress or false, self.hurryUp)
    end
end

function D8Machinery:checkAvailableRecipes()
    local currentItems = world.containerItems(entity.id())
    local currentRessoures = self.scriptConfig.ressources

    --sb.logInfo("\ncurrentItems %s\ncurrentRessoures %s", sb.printJson(currentItems, 1), sb.printJson(currentRessoures, 1))
    
    local nextRecipe = self:hasRequirement(currentItems, currentRessoures, true)
    if nextRecipe then
        local hasSpace = self:hasSpace(nextRecipe)
        if hasSpace then
            --sb.logInfo("nextRecipe = %s", nextRecipe)
            self.recipeProgress.nextRecipe = nextRecipe
            self.recipeProgress.duration = nextRecipe.duration or 1

            self.recipeProgress.inProgress = true
            self.timer = self.recipeProgress.duration
            script.setUpdateDelta(1)
            return true
        else
            script.setUpdateDelta(10)
        end
    else
        script.setUpdateDelta(10)
    return end
end
function D8Machinery:recipesUpdate(dt)
    --Input Check--
    local currentItems = world.containerItems(entity.id())
    local currentRessoures = self.scriptConfig.ressources
    local hasAllRequirement = self:hasRequirement(currentItems, currentRessoures)
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
        script.setUpdateDelta(10)
    end
end

function D8Machinery:craftItem()
    local hasSpace = self:hasSpace()
    if hasSpace then
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
            end
        end
        if consumedItem then
            if self.recipeProgress.nextRecipe.fill then
                sb.logInfo("%s", self.recipeProgress.nextRecipe.fill)
            else
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
            end
            
            local currentItems = world.containerItems(entity.id())
            local currentRessoures = self.scriptConfig.ressources
            local hasAllRequirement = self:hasRequirement(currentItems, currentRessoures)
            if hasAllRequirement then
                self.recipeProgress.duration = self.recipeProgress.nextRecipe.duration or 1
            else
                self.recipeProgress = {}
                self.timer = 2.5
                script.setUpdateDelta(10)
            end
        end
    else
        self.recipeProgress = {}
        self.timer = 2.5
        script.setUpdateDelta(10)
    return end
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
            for index, input in ipairs(v.inputs) do 
                local hasItem = 0
                if input.item then
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
                elseif input.ressource then

                end

                if hasItem == 0 then
                    hasAllRequirement = false
                end
            end
            if hasAllRequirement then
                return v
            end
        end

        return nil
    else
        for index, input in ipairs(self.recipeProgress.nextRecipe.inputs) do 
            local hasItem = 0
            if input.item then
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
            elseif input.ressource then
            end

            if hasItem == 0 then
                return false
            end
        end

        return true
    end
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

function D8Machinery:uninit()
    if not storage.scriptConfig then storage.scriptConfig = {} end
    storage.scriptConfig.ressources = self.scriptConfig.ressources
    object.setConfigParameter("uninitTime", world.time())
    --sb.logInfo("uninit world Time %s", config.getParameter("uninitTime"))
end

function D8Machinery:die()
    if not storage.scriptConfig then storage.scriptConfig = {} end
    storage.scriptConfig.ressources = self.scriptConfig.ressources

    object.setConfigParameter("scriptStorage", storage)
    --sb.logInfo("scriptStorage = %s", config.getParameter("scriptStorage"))
end

function init()
    D8Machinery:init()
end

function update(dt)
    D8Machinery:update(dt)
end

function uninit()
    D8Machinery:uninit()
end

function die()
    D8Machinery:die()
end
