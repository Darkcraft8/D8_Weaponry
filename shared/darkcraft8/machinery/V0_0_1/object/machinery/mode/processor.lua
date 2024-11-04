require("/shared/darkcraft8/machinery/V0_0_1/object/machinery/utils/node.lua")
require("/shared/darkcraft8/machinery/V0_0_1/object/machinery/utils/recipe.lua")

-- Machinery that produce resource/item logic is here

function D8Machinery:modeInit()
    self.itemDefaultCfg = root.assetJson("/items/defaultparameters.config")
    D8Machinery_recipe:buildRecipes()
    if not D8Machinery_recipe:hasRecipesRunning() then 
        D8Machinery:setPause(D8Machinery.startPaused)
    end
    self:buildTransferDuration()
    self:buildProcessorMessage()
end

--A bunch of message handler meant to be used for Pane... ok so pane "can't" use message...
function D8Machinery:buildProcessorMessage()
    message.setHandler("setPaused", function(_,_, boolean)
        if type(boolean) == "boolean" then if D8Machinery.setPause then D8Machinery:setPause(boolean) end end
    end)
    
    message.setHandler("setRecipe", function(_,_, recipe, number, group)
        D8Machinery_recipe:setRecipe(foundRecipe, number, group)
    end)

    message.setHandler("getRecipes", function(_,_, paneId)
        world.sendEntityMessage("getRecipes", paneId, "result", D8Machinery_recipe.recipeList)
    end)

    message.setHandler("getAvailableRecipes", function(_,_, paneId)
        world.sendEntityMessage("getAvailableRecipes", paneId, "result", D8Machinery_recipe.recipeList)
    end)

    message.setHandler("resetRecipes", function(_,_)
        D8Machinery_recipe:resetRecipes()
    end)
end

function D8Machinery:modeLogic(dt)
    self:isAFK()
    self:recipeLogic(dt)
    self:resourceTransferLogic(dt)
    self:updatePaneParam(dt)
    if not D8Machinery_recipe:hasRecipesRunning() and not D8Machinery_resourceUtil:hasResources(self.scriptConfig.transferTable or {}) and not D8Machinery_node:hasConnectedObjectToOutputNode() then 
        self.hurryUp = 0 --sb.logInfo("Reseting Hurry Up so that player's don't stock boosted speed")
    end
end

function D8Machinery:hurryUpRecipeLogic()
    if (self.hurryUp or 0) > 0 then
        for _, group in ipairs(groups or D8Machinery.scriptConfig.recipeGroups or {"primary"}) do
            if storage.recipe[group].duration then 
                self.hurryUp = self.hurryUp - storage.recipe[group].duration
                storage.recipe[group].duration = -1
            end
        end
    end
end
--A few calls
function D8Machinery:setPause(boolean) -- in case it needed
    self.pause = boolean
end

function D8Machinery:recipeLogic(dt)
    if (self.recipeSearchTimer or 0) > 0 then self.recipeSearchTimer = (self.recipeSearchTimer or 0) - dt end
    if not self.pause then
        --sb.logInfo("hasRecipesRunning %s", D8Machinery_recipe:hasRecipesRunning())
        --sb.logInfo("storage.recipe    %s", storage.recipe)
        if D8Machinery_recipe:hasRecipesRunning() then
            self:durationCalcul()
            if self.hurryUp > 0 then self:hurryUpRecipeLogic() end
            D8Machinery_recipe:recipesUpdate(dt)
        end
        if not self:hasInventoryChanged() and self.autoRecipeSearch and (self.recipeSearchTimer or 0) > 0 then return end -- a simple check so that processor don't check multiple time their inventory for valid recipes if their inv din't change
        self.recipeSearchTimer = 2
        for _, group in ipairs(groups or D8Machinery.scriptConfig.recipeGroups or {"primary"}) do
            self:recipeGroupCheck(dt, group)
        end
    end
end

function D8Machinery:durationCalcul()
    self.globalDuration = 0
    self.globalInit = 0
    for _, group in ipairs(groups or D8Machinery.scriptConfig.recipeGroups or {"primary"}) do
        if storage.recipe[group].duration then
            self.globalDuration = self.globalDuration + (storage.recipe[group].duration or 0)
            self.globalInit = self.globalInit + (storage.recipe[group].current.duration or 0)
        end
    end
end

function D8Machinery:recipeGroupCheck(dt, group)
    local doSearchRecipe = false
    if not D8Machinery_recipe:hasRecipeRunning(group) then doSearchRecipe = true end
    if doSearchRecipe then
        local _, foundRecipe = D8Machinery_recipe:findFirstAvailableRecipe(group)

        if foundRecipe then
            if foundRecipe then D8Machinery_recipe:setRecipe(foundRecipe, 1, group) return end
        end
    end
end

function D8Machinery:buildTransferDuration()
    storage.transferDuration = {}
    for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
        storage.transferDuration[resourceCfg.resource] = resourceCfg.speed
    end
end

function D8Machinery:resourceTransferLogic(dt)
    local transferTableIsntEmpty = false
    for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
        transferTableIsntEmpty = true
        if storage.transferDuration[resourceCfg.resource] > 0 then storage.transferDuration[resourceCfg.resource] = storage.transferDuration[resourceCfg.resource] - dt end
        --sb.logInfo("%s", D8Machinery_resourceUtil:getResource(resourceCfg.resource))
    end
    if not transferTableIsntEmpty then return end
    if self:shouldTransfer() then
        if self.hurryUp > 0 then self:hurryUpResourceLogic() end
        for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
            if storage.transferDuration[resourceCfg.resource] <= 0 and D8Machinery_resourceUtil:hasResources({resourceCfg}) then
                if D8Machinery_node:findValidResourceTarget(resourceCfg) then D8Machinery_node:sendResource(resourceCfg) end
                storage.transferDuration[resourceCfg.resource] = resourceCfg.speed
            end
        end
    end
end

function D8Machinery:hurryUpResourceLogic()
    if (self.hurryUp or 0) > 0 then
        for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
            self.hurryUp = self.hurryUp - resourceCfg.speed
            storage.transferDuration[resourceCfg.resource] = 0
        end
    end
end

function D8Machinery:shouldTransfer()
    local hasResourcesForOneType = false 
    local hasValidTargetForOneResource = false
    for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
        if D8Machinery_resourceUtil:hasResources({resourceCfg}) then hasResourcesForOneType = true end
        if D8Machinery_node:findValidResourceTarget(resourceCfg) then hasValidTargetForOneResource = true end
    end

    if hasResourcesForOneType and hasValidTargetForOneResource then
        return true
    else
        return false
    end
end

function D8Machinery:hasInventoryChanged()
    local changed = false
    if self.prevInv then
        if sb.printJson(self.prevInv) ~= sb.printJson(world.containerItems(entity.id())) then
            self.prevInv = world.containerItems(entity.id())
            changed = true
        end
    else
        self.prevInv = world.containerItems(entity.id())
        changed =  true
    end
    if self.prevResources then
        if sb.printJson(self.prevResources) ~= sb.printJson(D8Machinery_resourceUtil:getResources(self.scriptConfig.transferTable)) then
            self.prevResources = D8Machinery_resourceUtil:getResources(self.scriptConfig.transferTable)
            changed = true
        end
    else
        self.prevResources = D8Machinery_resourceUtil:getResources(self.scriptConfig.transferTable)
        changed =  true
    end

    return changed
end