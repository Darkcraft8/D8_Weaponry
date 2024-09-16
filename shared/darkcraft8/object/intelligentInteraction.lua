require "/scripts/util.lua"
require "/objects/crafting/upgradeablecraftingobjects/upgradeablecraftingobject.lua"

local upgradeInit = init
local upgradeUninit = uninit

local intelligentInteraction = {}
function init()
    upgradeInit()
    intelligentInteraction:init(storage.currentStage)
end

function onInteraction(args)
    local interactedEntity = args.sourceId
    intelligentInteraction:analyseIntData(interactedEntity, storage.currentStage)
    if config.getParameter("interactOverride") then
        local Override = config.getParameter("interactOverride")
        local config = root.assetJson(Override.interactData)
        config.PaneScriptConfiguration = {}
        config.PaneScriptConfiguration.interactAction = intelligentInteraction.interactAction
        config.PaneScriptConfiguration.compiledInteractData = intelligentInteraction.compiledInteractData

        config.PaneScriptConfiguration.objectPos = entity.position()

        return {Override.interactAction, config}
    else
        return {intelligentInteraction.interactAction, intelligentInteraction.compiledInteractData, entity.id()}
    end
end

function intelligentInteraction:init(currentStage)
    if config.getParameter("interactOverride") then
        self:complexInit(currentStage)
    else
        self:basicInit(currentStage)
    end
end

function intelligentInteraction:complexInit(currentStage)
    local overrideConfig = config.getParameter("interactOverride")
    self.paneList = overrideConfig.panes
    if type(self.paneList) == "string" then
        self.paneList = root.assetJson(self.paneList)
    end
end

function intelligentInteraction:basicInit(currentStage)
    if config.getParameter("interactOverride") then 
        self.interactAction = config.getParameter("interactOverride")
    end
    if currentStage then
        self.interactData = config.getParameter("interactData")[currentStage]
    else
        self.interactData = config.getParameter("interactData")
    end
end

function intelligentInteraction:analyseIntData(interactedEntity, currentStage)
    if config.getParameter("interactData") then
        self:complexAnalyseIntData(interactedEntity, currentStage)
    else
        self:basicAnalyseIntData(interactedEntity)
    end
end

function intelligentInteraction:complexAnalyseIntData(interactedEntity, currentStage)
    self.compiledInteractData = {}

    for index, paneConfig in pairs(self.paneList) do
        --sb.logInfo("index = %s", index)
        --sb.logInfo("paneConfig = %s", sb.printJson(paneConfig, 1))
        local currentPaneConfig = copy(paneConfig)
        local configPath = paneConfig["interactData"]["config"]

        if paneConfig["interactData"][currentStage] then
            currentPaneConfig.interactData = copy(paneConfig["interactData"][currentStage])
            configPath = paneConfig["interactData"][currentStage]["config"]
        end

        currentPaneConfig.interactData.config = root.assetJson(configPath)

        if currentPaneConfig["interactData"]["convertionList"] then
            local list = root.assetJson(currentPaneConfig["interactData"]["convertionList"])
            for index, item in ipairs(list) do 
                local itemConv
                if type(item) ~= "string" then
                    itemConv = item
                    for itemDescriptor, _ in pairs(item) do
                        item = itemDescriptor
                    end
                end

                local hasItem = world.entityHasCountOfItem(interactedEntity, item)
                if hasItem > 0 then
                    --sb.logInfo("[intelligentInteraction] :\nitem : %s\nhasItem : %s", item, hasItem)
                    if not currentPaneConfig["interactData"]["filter"] then
                        currentPaneConfig["interactData"]["filter"] = {}
                    end
                    if itemConv then
                        for _, filter in ipairs(itemConv[item]) do
                            local craftFilter = string.format("d8Conversion_%s", filter)
                            table.insert(currentPaneConfig["interactData"]["filter"], craftFilter)
                        end
                    else
                        table.insert(currentPaneConfig["interactData"]["filter"], string.format("d8Conversion_%s", item))
                    end
                end
            end
        end
        table.insert(self.compiledInteractData, currentPaneConfig)
    end
end

function intelligentInteraction:basicAnalyseIntData(interactedEntity)
    if self.interactData["config"] then
        self.compiledInteractData = copy(self.interactData)
        self.compiledInteractData["config"] = root.assetJson(self.interactData["config"])
    else
        sb.logInfo("[intelligentInteraction] : interactData Config Missing")
        return
    end
    if self.compiledInteractData["convertionList"] then
        local list = root.assetJson(self.compiledInteractData["convertionList"])
        for index, item in ipairs(list) do 
            local hasItem = world.entityHasCountOfItem(interactedEntity, item, true)
            if hasItem > 0 then
                sb.logInfo("[intelligentInteraction] :\nitem : %s\nhasItem : %s", item, hasItem)
                if not self.compiledInteractData["filter"] then
                    self.compiledInteractData["filter"] = {}
                end
                table.insert(self.compiledInteractData["filter"], string.format("d8Conversion_%s", item))
            end
        end
    end
    --sb.logInfo("[intelligentInteraction] :\nfilter = %s", self.compiledInteractData["filter"])
end

function uninit()
    upgradeUninit()
end