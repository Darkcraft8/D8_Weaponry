D8Machinery = {
    type = "Null",
    recipeList = {},
    recipeProgress = {
    },
    uninitTime = nil,
    hurryUp = 0
}

function D8Machinery:init()
    --sb.logInfo("D8Machinery Init")
    self.modeDatabase = root.assetJson("/WIP/shared/darkcraft8/object/machinery/modeDatabase.config") --Get the different mode
    if self.modeDatabase[string.lower(self.type)] then require(self.modeDatabase[string.lower(self.type)]) end -- load the required lib for the current mode

    self.scriptConfig = config.getParameter("scriptConfig")
    self.timer = 0
    if config.getParameter("scriptStorage") then
        storage = config.getParameter("scriptStorage")
        object.setConfigParameter("scriptStorage", nil)
    end
    if storage.scriptConfig then self.scriptConfig = storage.scriptConfig end
    self:recipesPopulate()
    self.owner = world.getObjectParameter(entity.id(), "owner") -- In case it needed
    self.initTimer = initTimer or 2
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
    if self.initTimer > 0 then
        self.initTimer = self.initTimer - 1
    elseif self.initTimer ~= -404 then -- PostInit because init is sometime weird
        if config.getParameter("uninitTime") then
            self:hurryUpBoostMath()
        end
        if storage.itemBag then -- Machine stock their ressources so why not do the same with items
            for i, v in pairs(storage.itemBag) do
                world.containerPutItemsAt(entity.id(), v, i - 1)
            end
            storage.itemBag = nil
        end
        self.initTimer = -404
    else
        if self.modeDatabase[string.lower(self.type)] then self[string.lower(self.type).."Logic"](nil, dt, self) end -- I might have over Engineered a way to separate the functions instead of using require()...
    end
end

function D8Machinery:uninit()
    if not storage.scriptConfig then storage.scriptConfig = {} end
    storage.scriptConfig = self.scriptConfig
    object.setConfigParameter("uninitTime", world.time())
end

function D8Machinery:die()
    if not storage.scriptConfig then storage.scriptConfig = {} end
    storage.scriptConfig = self.scriptConfig
    storage.itemBag = world.containerItems(entity.id())

    object.setConfigParameter("scriptStorage", storage)
    world.containerTakeAll(entity.id())
end