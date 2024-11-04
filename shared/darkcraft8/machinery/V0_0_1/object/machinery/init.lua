require "/shared/darkcraft8/machinery/V0_0_1/object/machinery/compact.lua"
require "/scripts/util.lua"
D8Machinery = {
    startPaused = true,
    autoRecipeSearch = false,
    uninitTime = nil,
    hurryUp = 0
}

function D8Machinery:init()
    if compactInit then compactInit() end
    self:scriptConfigInit()
    self:currentMode()
    self.timer = 0
    self.owner = world.getObjectParameter(entity.id(), "owner") -- In case it needed
    self.initTimer = initTimer or 2
    --self.hurryUp = 10000000000 -- For Testing the time boost
end

function D8Machinery:update(dt)
    if (self.initTimer or 2) > 0 then
        self.initTimer = self.initTimer - 1
    elseif self.initTimer ~= -404 then -- PostInit because init is sometime weird
        if config.getParameter("uninitTime") then
            self:hurryUpBoostMath()
        end
        if storage.itemBag then -- Machine stock their resources so why not do the same with items
            for i, v in pairs(storage.itemBag) do
                world.containerPutItemsAt(entity.id(), v, i - 1)
            end
            storage.itemBag = nil
        end
        self.initTimer = -404
    else
        if self.modeLogic then self:modeLogic(dt) end
    end
end

function D8Machinery:uninit()
    if not storage.scriptConfig then storage.scriptConfig = {} end
    storage.scriptConfig = self.scriptConfig
    object.setConfigParameter("uninitTime", world.time())
end

function D8Machinery:die()
    if not storage.scriptConfig then storage.scriptConfig = {} end
    storage.currentRecipe = nil
    storage.scriptConfig = self.scriptConfig
    if self.keepInventory then
        storage.itemBag = world.containerItems(entity.id())
        world.containerTakeAll(entity.id())
    end
    if self.scriptConfig.clearedResource then
        for _, name in ipairs(self.scriptConfig.clearedResource) do 
            self.scriptConfig.resources[name] = 0
        end
    end
    object.setConfigParameter("scriptStorage", storage)
    self:cleanParam()
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
end

function D8Machinery:currentMode()
    self.modeDatabase = root.assetJson("/shared/darkcraft8/machinery/V0_0_1/object/machinery/modeDatabase.config") --Get the different mode
    if self.modeDatabase[string.lower(self.type)] then -- load the required lib for the current mode
        require(self.modeDatabase[string.lower(self.type)])
        if self.modeInit then self:modeInit() end
    end

    return string.lower(self.type)
end

function D8Machinery:scriptConfigInit()
    local scriptConfig = config.getParameter("scriptConfig")
    self.scriptConfig = config.getParameter("scriptConfig")
    if config.getParameter("scriptStorage") then
        storage = config.getParameter("scriptStorage")
        object.setConfigParameter("scriptStorage", nil)
    end
    if storage.scriptConfig then self.scriptConfig = storage.scriptConfig end

    self.type = self.type or scriptConfig.type or "Null"
    if scriptConfig.startPaused ~= nil then 
        self.startPaused = scriptConfig.startPaused
    end
    if scriptConfig.autoRecipeSearch ~= nil then 
        self.autoRecipeSearch = scriptConfig.autoRecipeSearch
    end

    self.scriptConfig.maxResources = scriptConfig["maxResources"]
    self.scriptConfig.recipes = scriptConfig["recipes"]
    self.scriptConfig.recipeGroups = scriptConfig["recipeGroups"]
    self.scriptConfig.transferTable = scriptConfig["transferTable"] or {}
    self.scriptConfig.clearedResource = scriptConfig["clearedResource"] or {}
    self.keepInventory = scriptConfig.keepInventory
    
end

function D8Machinery:useD8Machinery() return true end

function D8Machinery:updatePaneParam() --Yea
    local paneParam = {}
    if self.scriptConfig.resources then
        paneParam.resources = self.scriptConfig.resources
        paneParam.maxResources = self.scriptConfig.maxResources
    end
    if self.globalInit then
        if self.globalInit ~= 0 and self.globalDuration > 0 then
            paneParam.globalInit = self.globalInit
            paneParam.globalDuration = self.globalDuration
        end
    end
    object.setConfigParameter("D8Machinery_paneParam", paneParam)
end

function D8Machinery:cleanParam()
    object.setConfigParameter("D8Machinery_paneParam", nil)
    object.setConfigParameter("uninitTime", nil)
end

function D8Machinery:isAFK()
    local isAFK = true
    if D8Machinery_recipe then if D8Machinery_recipe:hasRecipesRunning() then isAFK = false end end
    if D8Machinery.shouldTransfer then if D8Machinery:shouldTransfer() then isAFK = false end end

    if isAFK then
        script.setUpdateDelta(10) --Setting update delta to a higher number so that it doesn't update frequently when afk
        self.hurryUp = 0 --reset hurryUp when AFK
        self.globalInit = nil
        self.globalDuration = nil
    else
        script.setUpdateDelta(1)
    end

    return isAFK
end

-- just the vanilla function
local objectInit = init
local objectUpdate = update
local objectUninit = uninit
local objectDie = die

function init()
    if objectInit then objectInit() end
    D8Machinery:init()
end
    
function update(dt)
    if objectUpdate then objectUpdate(dt) end
    D8Machinery:update(dt)
end
    
function uninit()
    if objectUninit then objectUninit() end
    D8Machinery:uninit()
end
    
function die()
    if objectDie then objectDie() end
    D8Machinery:die()
end