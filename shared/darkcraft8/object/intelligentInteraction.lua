require "/scripts/util.lua"
require "/objects/crafting/upgradeablecraftingobjects/upgradeablecraftingobject.lua"

local upgradeInit = init
local upgradeUninit = uninit

local intelligentInteraction = {}
function init()
    upgradeInit()
end

function onInteraction(args)
    local interactedEntity = args.sourceId
    intelligentInteraction:init(storage.currentStage)
    intelligentInteraction:analyseIntData(interactedEntity, storage.currentStage)
    if config.getParameter("interactOverride") then
        local Override = config.getParameter("interactOverride")
        local config = root.assetJson(Override.interactData)
        config.PaneScriptConfiguration = {}
        config.PaneScriptConfiguration.interactAction = intelligentInteraction.interactAction
        config.PaneScriptConfiguration.compiledInteractData = intelligentInteraction.compiledInteractData
        config.PaneScriptConfiguration.UpgradeRecipe = intelligentInteraction.UpgradeRecipe

        config.PaneScriptConfiguration.objectPos = entity.position()

        return {Override.interactAction, config}
    else
        --sb.logInfo("%s\n%s\n%s", intelligentInteraction.interactAction, sb.printJson(intelligentInteraction.compiledInteractData, 1), entity.id())
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
    if config.getParameter("interactAction") then 
        self.interactAction = config.getParameter("interactAction")
    end
    if currentStage then
        self.interactData = config.getParameter("interactData")[currentStage]
    else
        self.interactData = config.getParameter("interactData")
    end
end

function intelligentInteraction:analyseIntData(interactedEntity, currentStage)
    if config.getParameter("interactOverride") then
        self:complexAnalyseIntData(interactedEntity, currentStage)
    else
        self:basicAnalyseIntData(interactedEntity, currentStage)
    end
end

function intelligentInteraction:complexAnalyseIntData(interactedEntity, currentStage)
    self.compiledInteractData = {}
    if config.getParameter("interactOverride")["upgradeMaterials"] then
        if config.getParameter("interactOverride")["upgradeMaterials"][currentStage] then
            self.UpgradeRecipe = config.getParameter("interactOverride")["upgradeMaterials"][currentStage]
        end
    end

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
        
        if currentPaneConfig["upgradeMaterials"] then
            self.UpgradeRecipe = currentPaneConfig["upgradeMaterials"]
            currentPaneConfig["upgradeMaterials"] = nil
        end

        if currentPaneConfig["interactData"]["convertionList"] then
            for _, convertionList in ipairs(root.assetJson(currentPaneConfig["interactData"]["convertionList"])) do
                local list = convertionList["item"]
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
        end
        table.insert(self.compiledInteractData, currentPaneConfig)
    end
end

function intelligentInteraction:basicAnalyseIntData(interactedEntity, currentStage)
    if self.interactData["config"] then
        self.compiledInteractData = copy(self.interactData)
        self.compiledInteractData["config"] = root.assetJson(self.interactData["config"])
    else
        sb.logInfo("[intelligentInteraction] : interactData Config Missing")
        return
    end
    if self.compiledInteractData["convertionList"] then
        for _, convertionList in ipairs(root.assetJson(self.compiledInteractData["convertionList"])) do
            local list = convertionList["item"]
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
                    if not self.compiledInteractData["filter"] then
                        self.compiledInteractData["filter"] = {}
                    end
                    
                    if itemConv then
                        for _, filter in ipairs(itemConv[item]) do
                            local craftFilter = string.format("d8Conversion_%s", filter)
                            table.insert(self.compiledInteractData["filter"], string.format("%s_%s", convertionList["prefix"], craftFilter))
                        end
                    else
                        table.insert(self.compiledInteractData["filter"], string.format("%s_%s", convertionList["prefix"], item))
                    end
                end
            end
        end
    end
    
    --sb.logInfo("[intelligentInteraction] :\nfilter = %s", self.compiledInteractData["filter"])
end

function uninit()
    upgradeUninit()
end