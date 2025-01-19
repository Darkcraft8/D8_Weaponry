require("/shared/darkcraft8/machinery/V0_0_1/object/machinery/utils/slot.lua")
require("/shared/darkcraft8/machinery/V0_0_1/object/machinery/utils/resource.lua")

-- the most important util for processor and crafter... the recipe util

D8Machinery_recipe = {}

function D8Machinery_recipe:resetRecipes(group)
    D8Machinery_recipe.recipeList = {}
    storage.recipe = storage.recipe or {}
    for _, group in ipairs(groups or D8Machinery.scriptConfig.recipeGroups or {"primary"}) do
        storage.recipe[group] = {}
    end
    D8Machinery_recipe:addRecipes(D8Machinery.scriptConfig["recipes"])
end
function D8Machinery_recipe:buildRecipes(group)
    D8Machinery_recipe.recipeList = {}
    storage.recipe = storage.recipe or {}
    for _, group in ipairs(groups or D8Machinery.scriptConfig.recipeGroups or {"primary"}) do
        storage.recipe[group] = storage.recipe[group] or {}
    end
    D8Machinery_recipe:addRecipes(D8Machinery.scriptConfig["recipes"])
end
-- maybe i should remake the recipes populate functions ?...
function D8Machinery_recipe:addRecipe(recipe)
    D8Machinery_recipe:addRecipes({recipeList})
end

function D8Machinery_recipe:addRecipes(recipeList) -- if string then root if table then if string root if table then add to list
    local recipes = recipeList or D8Machinery.scriptConfig["recipes"]
    if type(recipes) == "string" then
        local root = root.assetJson(recipes)
        for i, v in ipairs(root) do
            if type(v) == "string" then self:addRecipes(v)
            elseif type(v) == "table" then
                if v["inputs"] then --It a recipe
                    table.insert(D8Machinery_recipe.recipeList, v)
                else--It a table of recipe
                    self:addRecipes(v)
                end
            end
        end
    elseif type(recipes) == "table" then
        for i, v in ipairs(recipes) do
            if type(v) == "string" then self:addRecipes(v)
            elseif type(v) == "table" then
                if v["inputs"] then --It a recipe
                    table.insert(D8Machinery_recipe.recipeList, v)
                else--It a table of recipe
                    self:addRecipes(v)
                end
            end
        end
    end

    table.sort(D8Machinery_recipe.recipeList, prioritySort)
end

function prioritySort(a, b) --table.sort act weird when the sort func is in a table... like all func called through an _ENV... Hmm
    return (a.priority or 0) < (b.priority or 0)
end

function D8Machinery_recipe:recipesUpdate(dt, groups)
    for _, group in ipairs(groups or D8Machinery.scriptConfig.recipeGroups or {"primary"}) do
        if storage.recipe[group].current then
            local hasRequirement = D8Machinery_recipe:recipeRequirement(storage.recipe[group].current, group)
            if not hasRequirement then
                D8Machinery_recipe:clearCurrentRecipe(group)
            return end
            if storage.recipe[group].duration > 0 then storage.recipe[group].duration = storage.recipe[group].duration - dt return end
            D8Machinery_recipe:craft(group)
        end
    end
    if not D8Machinery_recipe:hasRecipesRunning() then D8Machinery_recipe:resetRecipesProgress() end
end

-- Crafting Functions
function D8Machinery_recipe:craft(group)
    local outCurrency, outItem, outResource, outTreasure = D8Machinery_recipe:analyseRecipesTable(storage.recipe[group].current.outputs)
    local inCurrency, inItem, inResource = D8Machinery_recipe:analyseRecipesTable(storage.recipe[group].current.inputs)
    local hasSpaceForItemss = D8Machinery_slotUtil:findSpace(outItem, D8Machinery.scriptConfig.slotConfig.input)
    local hasSpaceForResources = D8Machinery_resourceUtil:hasSpaceForResources(outResource)
    local hasResources = D8Machinery_resourceUtil:hasResources(inResource)
    local exactMatch = storage.recipe[group].current.matchInputParameters or false
    local bool, error = D8Machinery_recipe:recipeRequirement(storage.recipe[group].current, group)
    --sb.logInfo("bool %s, error %s", bool, error)

    if storage.recipe[group].current.fill and hasResources then
        for i, v in ipairs(outItem) do
            D8Machinery_recipe:fillItem(v, outCurrency, outItem, outResource, inCurrency, inItem, inResource, exactMatch, group)
        end
    elseif D8Machinery_recipe:recipeRequirement(storage.recipe[group].current, group) then
        D8Machinery_recipe:normalRecipe(outCurrency, outItem, outResource, inCurrency, inItem, inResource, exactMatch, group, outTreasure)
    end

end

function D8Machinery_recipe:normalRecipe(outCurrency, outItem, outResource, inCurrency, inItem, inResource, exactMatch, group, outTreasure)
    local consumedAllItems = D8Machinery_slotUtil:removeItemsIn(inItem, D8Machinery.scriptConfig.slotConfig.input, exactMatch)
    local consumedAllResources = D8Machinery_resourceUtil:removeResources(inResource)

    if consumedAllItems and consumedAllResources then
        for _, cfg in ipairs(outTreasure) do 
            if cfg.treasure then
                self:generateTreasurePool(cfg, outItem)
            end
        end
        D8Machinery_slotUtil:addItems(outItem, D8Machinery.scriptConfig.slotConfig.output)
        D8Machinery_resourceUtil:addResources(outResource)

            
        storage.recipe[group].amount = storage.recipe[group].amount - 1
        if storage.recipe[group].amount <= 0 then
            D8Machinery_recipe:clearCurrentRecipe(group)
        end
    end
end
function D8Machinery_recipe:generateTreasurePool(treasurePool, outItem)
    local count = (treasurePool.count or 1)
    if root.isTreasurePool(treasurePool.treasure) then
        while count > 0 do
            local treasure = root.createTreasure(treasurePool.treasure, treasurePool.level or 1, treasurePool.seed)
            for _, itemCfg in pairs(treasure) do 
                table.insert(outItem, itemCfg)
            end
            count = count - 1
        end
    end
end
function D8Machinery_recipe:fillItem(item, outCurrency, outItem, outResource, inCurrency, inItem, inResource, exactMatch, group)
    local foundSlot, foundItem = D8Machinery_recipe:fillItemFindOutput(item, D8Machinery.scriptConfig.slotConfig.output)

    if not foundSlot and not foundItem then
        if not D8Machinery_slotUtil:findSpace(outItem, D8Machinery.scriptConfig.slotConfig.output) then return end
        
        local inSlot, inItem = D8Machinery_slotUtil:findItem(item, D8Machinery.scriptConfig.slotConfig.input)
        if inSlot and inItem then
            if inItem.count > 1 then
                inItem.count = 1
                world.containerConsumeAt(entity.id(), inSlot, 1)
                D8Machinery_slotUtil:addItem(inItem, D8Machinery.scriptConfig.slotConfig.output)
            else
                world.containerTakeAt(entity.id(), inSlot)
                D8Machinery_slotUtil:addItem(inItem, D8Machinery.scriptConfig.slotConfig.output)
            end
        end
    else
        if not D8Machinery_resourceUtil:hasResources(inResource) then return end
        local stack = nil
        if foundItem.count > 1 then
            stack = copy(foundItem)
            stack.count = stack.count - 1
            foundItem.count = 1

            local slotTable = D8Machinery_slotUtil:findSpace({stack}, D8Machinery.scriptConfig.slotConfig.input)
            if not slotTable then D8Machinery_slotUtil:findSpace({stack}, D8Machinery.scriptConfig.slotConfig.output) end
            if slotTable then
                for currentslot, _ in pairs(slotTable) do
                    if not selectedStackSlot then selectedStackSlot = currentslot end
                    if selectedStackSlot > currentslot then 
                        selectedStackSlot = currentslot
                    end
                end
            else return end
            D8Machinery_slotUtil:setSlotItem(foundItem, foundSlot)
            D8Machinery_slotUtil:setSlotItem(stack, selectedStackSlot)
        end

        D8Machinery_resourceUtil:removeResources(inResource)
        local filled = true
        for param, value in pairs(item.parameters) do 
            if foundItem["parameters"][param] and type(foundItem["parameters"][param]) == "number" then
                if not foundItem["parameters"][param] then foundItem["parameters"][param] = 0 end
                if (foundItem["parameters"][param] + (storage.recipe[group].current.amount[param] or 1)) < value then filled = false end
            else
                if not foundItem["parameters"][param] then foundItem["parameters"][param] = value end
            end
        end

        if not filled then
            for param, value in pairs(item.parameters) do 
                if foundItem["parameters"][param] and type(foundItem["parameters"][param]) == "number" then
                    foundItem["parameters"][param] = foundItem["parameters"][param] + (storage.recipe[group].current.amount[param] or 1)
                    if foundItem["parameters"][param] > value then
                        foundItem["parameters"][param] = value
                    end
                else
                    if not foundItem["parameters"][param] then foundItem["parameters"][param] = value end
                end
            end
            D8Machinery_slotUtil:setSlotItem(foundItem, foundSlot)
        else
            for param, value in pairs(item.parameters) do 
                if foundItem["parameters"][param] and type(foundItem["parameters"][param]) == "number" then
                    foundItem["parameters"][param] = foundItem["parameters"][param] + (storage.recipe[group].current.amount[param] or 1)
                    if foundItem["parameters"][param] > value then
                        foundItem["parameters"][param] = value
                    end
                else
                    if not foundItem["parameters"][param] then foundItem["parameters"][param] = value end
                end
            end
            
            world.containerConsumeAt(entity.id(), foundSlot, 1)
            D8Machinery_slotUtil:addItem(foundItem, D8Machinery.scriptConfig.slotConfig.output)

            local _, nextRecipe = D8Machinery_recipe:checkAvailableRecipes()
            if not nextRecipe then
                storage.recipe[group].amount = storage.recipe[group].amount - 1
                if storage.recipe[group].amount <= 0 then
                    D8Machinery_recipe:clearCurrentRecipe(group)
                end
            else
                D8Machinery_recipe:setRecipe(nextRecipe, 1, group)
            end
        end
    end
end

function D8Machinery_recipe:fillItemFindOutput(item, slots)
    for _, slot in ipairs(slots) do
        local index, foundItem = D8Machinery_slotUtil:findItem(item, {slot})

        if index and foundItem then
            local full = true
            for param, value in pairs(item.parameters) do
                if foundItem["parameters"][param] and type(foundItem["parameters"][param]) == "number" then
                    if not foundItem["parameters"][param] then foundItem["parameters"][param] = 0 end
                    if foundItem["parameters"][param] < value then full = false end
                else
                    if not foundItem["parameters"][param] then foundItem["parameters"][param] = value end
                end
            end
            if not full then
                return index, foundItem
            end
        end
    end
end
--
--
function D8Machinery_recipe:findFirstAvailableRecipe(group)
    local nextRecipe = nil
    for index, recipe in ipairs(D8Machinery_recipe.recipeList or {}) do
        if not nextRecipe then
            local result, error = D8Machinery_recipe:recipeRequirement(recipe, group)
            --sb.logInfo("result %s, error %s", result, error)
            if result then 
                nextRecipe = recipe 
            end
        end
    end
    if nextRecipe then return true, nextRecipe end
end

function D8Machinery_recipe:checkAvailableRecipes(group)
    local availableRecipes = {}
    for _, recipe in ipairs(D8Machinery_recipe.recipeList or {}) do
        local result, error = D8Machinery_recipe:recipeRequirement(recipe, group)
        --sb.logInfo("result %s, error %s", result, error)
        if result then
            table.insert(availableRecipes, recipe)
        end
    end

    return availableRecipes
end

function D8Machinery_recipe:recipeRequirement(recipe, group)
    if not recipe then return false, "Error:No recipe given" end
    if recipe.decay then return true end -- if the recipe has decay that mean that it meant to work without regard for requirements
    local inputsTable = recipe.inputs or {}
    local outputsTable = recipe.outputs or {}
    local duration = recipe.duration or 1
    local fill = recipe.fill or false
    local exactMatch = recipe.matchInputParameters or false
    local hasResourceSpaceForAll = true
    local group = group or "primary"
    if recipe.hasResourceSpaceForAll == false then hasResourceSpaceForAll = false end

    local amount = recipe.amount or {}
    local outCurrency, outItem, outResource, outTreasure = D8Machinery_recipe:analyseRecipesTable(outputsTable)
    local inCurrency, inItem, inResource = D8Machinery_recipe:analyseRecipesTable(inputsTable)
    for _, cfg in ipairs(outTreasure) do 
        if cfg.treasure then
            self:generateTreasurePool(cfg, outItem)
        end
    end
    if (recipe.group or "primary") ~= group then return false end
    if outItem[1] then if not D8Machinery_slotUtil:findSpace(outItem, D8Machinery.scriptConfig.slotConfig.output) then return false, "Error:Doesn't have space for items" end end
    if hasResourceSpaceForAll then if not D8Machinery_resourceUtil:hasSpaceForResources(outResource) then return false, "Error:Doesn't have space for resources" end end
    if not hasResourceSpaceForAll then
        local hasSpaceForOne = false
        for _, resourceCfg in ipairs(outResource) do
            if D8Machinery_resourceUtil:hasSpaceForResource(resourceCfg) then
                hasSpaceForOne = true
            end
        end
        if not hasSpaceForOne then return false, "Error:Doesn't have space for one resource" end
    end
    if not D8Machinery_resourceUtil:hasResources(inResource) then return false, "Error:Doesn't have resources" end
    if not D8Machinery_resourceUtil:hasResources(inCurrency) then return false, "Error:Doesn't have currency" end

    for i, v in ipairs(inItem) do
        local slot, currentItem = D8Machinery_slotUtil:findItem(v, D8Machinery.scriptConfig.slotConfig.input, exactMatch)
        if not currentItem then return false, "Error:Doesn't have item" end
    end
    if fill then
        local result = true
        for i, v in ipairs(outItem) do
            local slot, currentItem = D8Machinery_slotUtil:findItem(v, D8Machinery.scriptConfig.slotConfig.input, exactMatch)
            if not currentItem then
                slot, currentItem = D8Machinery_slotUtil:findItem(v, D8Machinery.scriptConfig.slotConfig.output, exactMatch)
            end
            if not currentItem then result = false end
        end
        if not result then return false end
    end

    return true
end

function D8Machinery_recipe:analyseRecipesTable(recipeTable)
    local resource = {}
    local item = {}
    local currency = {}
    local treasure = {}
    for i, v in ipairs(recipeTable) do 
        if v.resource then
            table.insert(resource, v)
        end
        if v.item then
            table.insert(item, v)
        end
        if v.treasure then
            table.insert(treasure, v)
        end
        if v.currency then
            v.resource = v.currency
            v.currency = nil 
            table.insert(currency, v)
        end
    end

    return currency, item, resource, treasure
end
--

--A few calls
function D8Machinery_recipe:getOutput(group) -- return the current recipe outputs if any
    if storage.recipe[group].current then return storage.recipe[group].current.outputs end
end

function D8Machinery_recipe:getInput(group) -- same has output but inputs instead
    if storage.recipe[group].current then return storage.recipe[group].current.inputs end
end

function D8Machinery_recipe:setRecipe(recipe, amount, group)
    if recipe then
        storage.recipe[group or "primary"] = {}
        storage.recipe[group or "primary"].current = recipe
        storage.recipe[group or "primary"].duration = recipe.duration or 1
        storage.recipe[group or "primary"].inProgress = true
        storage.recipe[group or "primary"].amount = amount or 1
    end
end

function D8Machinery_recipe:clearCurrentRecipe(group)
    storage.recipe[group or "primary"] = {}
end

function D8Machinery_recipe:resetRecipesProgress()
    for _, group in ipairs(groups or D8Machinery.scriptConfig.recipeGroups or {"primary"}) do
        D8Machinery_recipe:clearCurrentRecipe(group)
    end
    if D8Machinery.startPaused and D8Machinery.setPause then D8Machinery:setPause(true) end
end

function D8Machinery_recipe:hasRecipeRunning(group)
    if not storage.recipe[group or "primary"] then return false end
    if storage.recipe[group or "primary"]["inProgress"] then return true else return false end
end

function D8Machinery_recipe:hasRecipesRunning(groups)
    local groupTable = groups or D8Machinery.scriptConfig.recipeGroups or {"primary"}
    local hasOneRecipeGroupRunning = false
    for _, group in ipairs(groupTable) do
        if D8Machinery_recipe:hasRecipeRunning(group) then hasOneRecipeGroupRunning = true end
    end
    return hasOneRecipeGroupRunning
end