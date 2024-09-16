local PaneScriptConfiguration
local sourceEntity
local playerEntityId
local paneConfig = {}
local initTimer = 2
local objectPos = {0, 0}
local aPaneIsOpen = false
local spawnedEntity
local paneButton = {
}
local listContent = {}
local checkInteractRadiusTimer = 0.5

function init()
    interactRadius = root.assetJson("/player.config")["interactRadius"] -0.4
    PaneScriptConfiguration = config.getParameter("PaneScriptConfiguration")

    if not PaneScriptConfiguration then
        local backpackedCrafting = {}
        if not player.getProperty("d8backpackedCrafting") then
            backpackedCrafting = {}
            --player.setProperty("d8backpackedCrafting", backpackedCrafting)
        end
        backpackedCrafting = player.getProperty("d8backpackedCrafting") or {}
        local defaultBackpackedCrafting = root.assetJson("/shared/darkcraft8/interfaces/craftingpaneselector/backpackCrafting.config")["default"]
        for index, value in ipairs(defaultBackpackedCrafting) do 
            table.insert(backpackedCrafting, value)
        end

        PaneScriptConfiguration = {
            compiledInteractData = backpackedCrafting
        }
    end
    paneButton = PaneScriptConfiguration.compiledInteractData
    objectPos = PaneScriptConfiguration.objectPos
    sourceEntity = pane.sourceEntity()
    playerEntityId = player.id()
    self.playerTilesPosition = objectPos
    if not world.entityExists(sourceEntity) then
        local objectParam = {
            smashOnBreak = true,
            color = "?replace;ffffff00=ffffffff?setcolor=ffffff?blendmult=/items/armors/decorative/costumes/hiker/back.png;42;10?crop;13;1;21;17?flipx",
            interactAction = "OpenSongbookInterface"
        }
        self.playerTilesPosition = world.entityPosition(playerEntityId)
        self.playerTilesPosition[1] = roundPos(self.playerTilesPosition[1])
        self.playerTilesPosition[2] = roundPos(self.playerTilesPosition[2], true)
        local objectAtPlayer = world.objectAt(self.playerTilesPosition)
        if objectAtPlayer then
            if not world.getObjectParameter(objectAtPlayer, "interactAction") then
                spawnedEntity = world.placeObject("protectorateroofdetail01", self.playerTilesPosition, 1, objectParam)
                if spawnedEntity then
                    pane.playSound("/sfx/blocks/footstep_snow.ogg")
                end
            else
                hostExist = true
            end
        else
            spawnedEntity = world.placeObject("protectorateroofdetail01", self.playerTilesPosition, 1, objectParam)
            if spawnedEntity then
                pane.playSound("/sfx/blocks/footstep_snow.ogg")
            end
        end
    end

end

function roundPos(value, vertical)
    local result
    if vertical then
        if value > 0.5 then
            result = math.ceil(value) - 3
        else
            result = math.floor(value) - 2
        end 
    else
        if value > 0.5 then
            result = math.ceil(value)
        else
            result = math.floor(value)
        end 
    end
    return result
end

function postInit()
    if initTimer > 0 then
        initTimer = initTimer - 1
    elseif initTimer ~= -10 then
        if not world.entityExists(sourceEntity) then
            if spawnedEntity or hostExist then
                sourceEntity = world.objectAt(self.playerTilesPosition) or 0
            else
                pane.dismiss()
            end
            if not world.entityExists(sourceEntity) then
                pane.dismiss()
            end
        end

        if sourceEntity then
            if world.entityExists(sourceEntity) and paneButton then
                populateList()
            end
        end
        initTimer = -10
    end
end

function update(dt)
    postInit()
    if initTimer == -10 then
        if checkInteractRadiusTimer > 0 then
            checkInteractRadiusTimer = checkInteractRadiusTimer - (1*dt)
        else
            checkInteractRadiusTimer = 0.5
            if hostExist or spawnedEntity then
                checkInteractRadius()
            end
            if not world.entityExists(sourceEntity) and spawnedEntity then
                uninit()
            end
        end
    end
end

function checkInteractRadius()
    local distance = {
        self.playerTilesPosition[1] - roundPos(world.entityPosition(playerEntityId)[1]),
        self.playerTilesPosition[2] - roundPos(world.entityPosition(playerEntityId)[2], true)
    }
    if distance[1] < 0 then
        distance[1] = -1 * distance[1]
    end
    if distance[2] < 0 then
        distance[2] = -1 * distance[2]
    end
    
    if distance[1] > interactRadius or distance[2] > interactRadius then
        uninit()
    end
end

function populateList()
    self.listPath = "partListArea.scrollArea.itemList"
    widget.clearListItems(self.listPath)
    listContent = {}
    local openedFirst = false
    for i, v in ipairs(paneButton) do
        local id = widget.addListItem(self.listPath)
        local path = string.format("%s.%s", self.listPath, id)
        local icon
        local interactData = v.interactData 
        local tooltipText
        
        if type(interactData.config) == "string" then
            interactData.config = root.assetJson(v.interactData.config)
        end
        if type(interactData) == "string" then
            interactData = root.assetJson(v.interactData)
        end

        if interactData.paneLayoutOverride then
            if interactData.paneLayoutOverride.windowtitle then
                if interactData.paneLayoutOverride.windowtitle.icon then
                    icon = interactData.paneLayoutOverride.windowtitle.icon.file
                end
                if interactData.paneLayoutOverride.windowtitle.title then
                    tooltipText = interactData.paneLayoutOverride.windowtitle.title
                end
            end
        elseif interactData.config then
            if interactData.config.paneLayout then
                if interactData.config.paneLayout.windowtitle then
                    if interactData.config.paneLayout.windowtitle.icon then
                        icon = interactData.config.paneLayout.windowtitle.icon.file
                    end
                end
                if interactData.config.paneLayout.windowtitle.title then
                    tooltipText = interactData.config.paneLayout.windowtitle.title
                    if interactData.config.tooltipText then
                        tooltipText = interactData.config.tooltipText
                    end
                end
            end
        elseif interactData.paneLayout then
            if interactData.paneLayout.windowtitle then
                if interactData.paneLayout.windowtitle.icon then
                    icon = interactData.paneLayout.windowtitle.icon.file
                end
                if interactData.paneLayout.windowtitle.title then
                    tooltipText = interactData.paneLayout.windowtitle.title
                    if interactData.paneLayout.tooltipText then
                        tooltipText = interactData.paneLayout.tooltipText
                    end
                end
            end
        elseif interactData.gui then
            if interactData.gui.windowtitle then
                if interactData.gui.windowtitle.icon then
                    icon = interactData.gui.windowtitle.icon.file
                end
                if interactData.gui.windowtitle.title then
                    tooltipText = interactData.gui.windowtitle.title
                    if interactData.gui.tooltipText then
                        tooltipText = interactData.gui.tooltipText
                    end
                end
            end
        end
        if interactData.tooltipText then
            tooltipText = interactData.tooltipText
        end
        if not icon then 
            icon = "/assetmissing.png"
        end
        widget.setData(path, {
            interactAction = v.interactAction,
            interactData = interactData
        })
        widget.setImage(string.format("%s.icon", path), icon)
        listContent[string.format("%s.%s", self.listPath, id)] = {
            tooltip = {
                description = tooltipText
            }
        }
        if not openedFirst then
            widget.setListSelected(self.listPath, id)
            player.interact(v.interactAction, interactData, sourceEntity)
            openedFirst = true
        end
    end
end

function paneSelected()
    local id = widget.getListSelected(self.listPath)
    self.selectedItem = id

    if self.selectedItem ~= nil then
        local Data = widget.getData(string.format("%s.%s", self.listPath, self.selectedItem))
        self.interactAction = Data.interactAction
        self.interactData = Data.interactData
        player.interact(Data.interactAction, Data.interactData, sourceEntity)
        player.interact(Data.interactAction, Data.interactData, sourceEntity)
    end
end

function btn(button)
    if button == "reopenBtn" then
        player.interact(self.interactAction, self.interactData, sourceEntity)
    end
end


function createTooltip(mousePosition)
    local part = {}
    local partId

    for n,w in pairs(config.getParameter("gui")) do
        if widget.inMember(n, mousePosition) then
            part = config.getParameter("gui")[n]
            partId = n
            break
        end
    end
    for n,w in pairs(listContent) do
        if widget.inMember(n, mousePosition) then
            part = listContent[n]
            break
        end
    end

    if part["tooltip"] == nil then
    return
    end
    
    local inputs = part["tooltip"]
    local tooltip = config.getParameter("tooltipLayout")
    if part["tooltip"] then
        local descriptionText = string.gsub(inputs["description"], '^%s*(.-)%s*$', '%1')
        local stringLength = string.len(descriptionText)
        local imageLength = 60
        local imageHeight = 14
        local imageTexturePath = "/interface/rightBarTooltipBg.png?crop;1;1;2;13?scalenearest=%s;1?border=1;ffffff;ffffff"
        tooltip["background"]["fileBody"] = string.format(imageTexturePath, (stringLength * 4) + 12)
        tooltip.descriptionLabel.value = descriptionText
        tooltip.descriptionLabel.position[1] = (( (stringLength * 4) + 15 ) / 2)
    end
    return tooltip
end

function uninit()
    if spawnedEntity then
        pane.playSound("/sfx/blocks/footstep_snow.ogg")
        world.damageTiles(
            {self.playerTilesPosition},
            "foreground",
            self.playerTilesPosition,
            "beamish",
            10000,
            99
        )
    end
    pane.dismiss()
end