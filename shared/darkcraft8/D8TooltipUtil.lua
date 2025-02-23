require "/scripts/util.lua"
require "/scripts/vec2.lua"

D8Tooltip = {} -- I wouldn't be supprised if this util become my most used one when released
function D8Tooltip:init()
    -- add an invisible/hidden textLabel to get the size of the whole string with the current font
    if not widget.getSize("D8Tooltip_LblWidget") then
        local lblWidget = {
            type = "label",
            position = {-100, -100},
            hAnchor = "mid",
            vAnchor = "mid",
            wrapWidth = root.assetJson("/shared/darkcraft8/d8ToolTipUtil/tooltip.config").text.descriptionLabel.wrapWidth,
            zlevel = 1
        }
        pane.addWidget(lblWidget, "D8Tooltip_LblWidget")
    end
    --
end

function D8Tooltip:update(dt)
    if self.tooltipCo then
        local status, message = coroutine.resume(self.tooltipCo)
    end
end

function D8Tooltip:uninit()
    player.setProperty("d8TooltipUtilOpen", false)
end

function D8Tooltip:cursorOverride(mousePosition)-- simple check to close any scripted tooltip pane, made with vanilla behavior in mind
    if self.oldMousePosition and not pane.setPosition then
        local diff = vec2.sub(self.oldMousePosition or {0, 0}, mousePosition)
        if math.abs(diff[1]) > 5 or math.abs(diff[2]) > 5 then 
            player.setProperty("d8TooltipUtilOpen", false)
        end
    end
end

function D8Tooltip:text(tooltipText)
    if tooltipText then
        local tooltip = root.assetJson("/shared/darkcraft8/d8ToolTipUtil/tooltip.config").text
        
        local borderSize = 1
        local borderColor = config.getParameter("tooltipCfg.borderColor", "FFFFFFff")

        local getStringSize = function(stringText)
            if not widget.getSize("D8Tooltip_LblWidget") then
                local lblWidget = {
                    type = "label",
                    position = {-100, -100},
                    hAnchor = "mid",
                    vAnchor = "mid",
                    wrapWidth = tooltip.descriptionLabel.wrapWidth,
                    zlevel = 1
                }
                pane.addWidget(lblWidget, "D8Tooltip_LblWidget")
            end

            widget.setText("D8Tooltip_LblWidget", stringText)
            local stringTextSize = widget.getSize("D8Tooltip_LblWidget")
            widget.setText("D8Tooltip_LblWidget", "")
            return stringTextSize
        end
        local stringTextSize = getStringSize(tooltipText)
        local stringLength = string.len(string.gsub(tooltipText, '%^[^^.*;]*;', ''))
        local imageLength = 4
        local imageHeight = 4
        local imageTexturePath = "/interface/rightBarTooltipBg.png?crop;1;1;2;2?scalenearest=%s;%s?border=%s;%s;%s"
        local extendedLength = imageLength + stringTextSize[1]--(1 + borderSize) + (4.25 * (stringLength))
        local extendedHeight = imageHeight + stringTextSize[2]
        
        tooltip["background"]["fileBody"] = string.format(imageTexturePath, extendedLength, extendedHeight, borderSize, borderColor, borderColor)
        tooltip.descriptionLabel.value = tooltipText
        tooltip.descriptionLabel.position[1] = (extendedLength * 0.5) + (borderSize)
        tooltip.descriptionLabel.position[2] = (extendedHeight * 0.5) + (borderSize)
        return tooltip
    end
    
    return
end
-- older sibling to scriptedItemList that doesn't open a scripted pane but item icon's are less pretty/accurate.
function D8Tooltip:vanillaBasedItemList(itemList, override)
    local tooltip = {
        panefeature = {
            type = "panefeature",
            offset = {-5, 0}
        },
        background = {
            type = "background",
            fileHeader = "/interface/craftingtooltip/header.png",
            fileBody = "/interface/craftingtooltip/body.png",
            fileFooter = "/interface/craftingtooltip/footer.png"
        },
        title = {
            type = "label",
            position = {76, 33}, -- Height of itemList is added to this y position
            hAnchor = "mid",
            vAnchor = "top",
            wrapWidth = 116,
            value = "INGREDIENTS"
        },
        itemList = {
            type = "layout",
            layoutType = "basic",
            rect = {0, 21, 145, 22}, -- Max Height should be increased based on the amount of item descriptor
            position = {0, 0},
            children = {
            }
        }
    }
    local pathTemplate = "itemList.children" .. ""
    local listTemplate = {
        type = "layout",
        layoutType = "basic",
        rect = {0, 0, 145, 22}, -- both Height should be increased based on the amount of item descriptor
        children = {
            backgroundImg = {
                type = "image",
                file = "/interface/craftingtooltip/listitem.png",
                position = {1, 0},
                zlevel = -1
            },
            itemName = {
                type = "label",
                position = {27, 11},
                hAnchor = "left",
                vAnchor = "mid",
                wrapWidth = 66,
                lineSpacing = 1.0,
                value = "Pootis Bird"
            },
            itemRarity = {
                type = "image",
                position = {4, 2},
                file = "/interface/inventory/itemborder"
            },
            itemIcon = { -- duplicate depending on the amount of inventoryIcon Drawable
                type = "image",
                position = {4, 1},
                file = "/D8Encyclopedia/Pane/icon.png",
                zlevel = 1,
                centered = true,
                minSize = {0, 0},
                maxSize = {18, 18}
            },
            count = {
                type = "label",
                position = {134, 7},
                hAnchor = "right",
                value = "404"
            }
        }
    }
    tooltip.title.value = override.title or "ITEM"
    local numberOfItem = 0
    for index, descriptor in ipairs(itemList) do
        local cfg = root.itemConfig(descriptor)
        local name = descriptor
        local itemCount = 1
        if type(descriptor) == "table" then
            name = index .. "|" .. (descriptor.name or descriptor.item or descriptor.itemName)
            itemCount = descriptor.count or 1
        else
            name = index .. "|" .. name
        end
        tooltip.itemList.children[name] = copy(listTemplate)

        tooltip.itemList.children[name]["children"]["itemName"]["value"] = (cfg.parameters.shortdescription or cfg.config.shortdescription)
        if override.mimicRecipeTooltip then
            local itemPlayerCount = 0
            if type(descriptor) == "table" then
                itemPlayerCount = player.hasCountOfItem({
                    name = (descriptor.name or descriptor.item or descriptor.itemName),
                    count = 1,
                    parameters = cfg.parameters
                })
            else
                itemPlayerCount = player.hasCountOfItem(descriptor)  
            end
            if itemPlayerCount >= itemCount then
                tooltip.itemList.children[name]["children"]["count"]["value"] = "^green;" .. itemPlayerCount .. "/" .. itemCount
            else
                tooltip.itemList.children[name]["children"]["count"]["value"] = "^red;" .. itemPlayerCount .. "/" .. itemCount
            end
        else
            tooltip.itemList.children[name]["children"]["count"]["value"] = tostring(itemCount)
        end
        tooltip.itemList.children[name]["children"]["itemRarity"]["file"] = string.format("/interface/inventory/itemborder%s.png", string.lower(cfg.parameters.rarity or cfg.config.rarity))
        local inventoryIcon = cfg.parameters.inventoryIcon or cfg.config.inventoryIcon
        if type(inventoryIcon) == "table" then
            local template = copy(listTemplate["children"]["itemIcon"])
            if inventoryIcon[1] ~= nil then
                local drawableSizeInSlot = {0, 0}
                for index, drawable in ipairs(inventoryIcon) do 
                    local image = drawable.image or ""
                    if not string.find(image, "/") then image = cfg.directory .. drawable.image end
                    local imageSize = root.imageSize(image)                    
                    if drawable.position then imageSize = vec2.add(imageSize, drawable.position) end

                    if drawableSizeInSlot[1] < imageSize[1] then drawableSizeInSlot[1] = imageSize[1] end
                    if drawableSizeInSlot[2] < imageSize[2] then drawableSizeInSlot[2] = imageSize[2] end
                end
                for index, drawable in ipairs(inventoryIcon) do 
                    if index == 1 then
                        local image = drawable.image or ""
                        if not string.find(image, "/") then image = cfg.directory .. drawable.image end
                        local pos = copy(listTemplate["children"]["itemIcon"]["position"])
                        if drawable.position then pos = vec2.add(pos, drawable.position) end
                        pos = vec2.add(pos, vec2.div(root.imageSize(tooltip.itemList.children[name]["children"]["itemRarity"]["file"]), 2))

                        if (drawableSizeInSlot[1] > 16) or (drawableSizeInSlot[2] > 16) then
                            pos = copy(listTemplate["children"]["itemIcon"]["position"])
                            if drawable.position then pos = vec2.add(pos, drawable.position) end
                            local imageSize = root.imageSize(image)
                            imageSize = vec2.mul(imageSize, {0.125, 0})
                            local slotSize = vec2.div(root.imageSize(tooltip.itemList.children[name]["children"]["itemRarity"]["file"]), 2)
                            pos = vec2.add(pos, {math.abs(pos[1] - slotSize[1]), 0})

                            tooltip.itemList.children[name]["children"]["itemIcon"]["centered"] = false
                            tooltip.itemList.children[name]["children"]["itemIcon"]["maxSize"] = {22, 22}
                        end
                        tooltip.itemList.children[name]["children"]["itemIcon"]["file"] = image 
                        tooltip.itemList.children[name]["children"]["itemIcon"]["position"] = pos
                    else
                        tooltip.itemList.children[name]["children"]["itemIcon" .. index] = template
                        local image = drawable.image or ""
                        if not string.find(image, "/") then image = cfg.directory .. drawable.image end
                        local pos = copy(listTemplate["children"]["itemIcon"]["position"])
                        if drawable.position then pos = vec2.add(pos, drawable.position) end
                        pos = vec2.add(pos, vec2.div(root.imageSize(tooltip.itemList.children[name]["children"]["itemRarity"]["file"]), 2))
                        
                        if (drawableSizeInSlot[1] > 16) or (drawableSizeInSlot[2] > 16) then
                            pos = copy(listTemplate["children"]["itemIcon"]["position"])
                            if drawable.position then pos = vec2.add(pos, drawable.position) end
                            local imageSize = root.imageSize(image)
                            imageSize = vec2.mul(imageSize, {0.125, 0})
                            local slotSize = vec2.div(root.imageSize(tooltip.itemList.children[name]["children"]["itemRarity"]["file"]), 2)
                            pos = vec2.add(pos, {math.abs(pos[1] - slotSize[1]), 0})
                            
                            tooltip.itemList.children[name]["children"]["itemIcon" .. index]["centered"] = false
                            tooltip.itemList.children[name]["children"]["itemIcon" .. index]["maxSize"] = {22, 22}
                        end

                        tooltip.itemList.children[name]["children"]["itemIcon" .. index]["file"] = image
                        tooltip.itemList.children[name]["children"]["itemIcon" .. index]["position"] = pos
                        tooltip.itemList.children[name]["children"]["itemIcon" .. index]["zlevel"] = tooltip.itemList.children[name]["children"]["itemIcon" .. index]["zlevel"] + index
                    end
                end
            end
        else
            if string.find(inventoryIcon, "/") then -- isn't absolute
                tooltip.itemList.children[name]["children"]["itemIcon"]["file"] = inventoryIcon
                tooltip.itemList.children[name]["children"]["itemIcon"]["position"] = vec2.add(listTemplate["children"]["itemIcon"]["position"], vec2.div(root.imageSize(tooltip.itemList.children[name]["children"]["itemRarity"]["file"]), 2))
            else
                tooltip.itemList.children[name]["children"]["itemIcon"]["file"] = cfg.directory .. inventoryIcon
                tooltip.itemList.children[name]["children"]["itemIcon"]["position"] = vec2.add(listTemplate["children"]["itemIcon"]["position"], vec2.div(root.imageSize(tooltip.itemList.children[name]["children"]["itemRarity"]["file"]), 2))
            end
        end
        tooltip.itemList.children[name]["rect"][2] = (22 * (#itemList - (numberOfItem + 1)))
        tooltip.itemList.children[name]["rect"][4] =  22 + (22 * (#itemList - (numberOfItem + 1)))
        numberOfItem = numberOfItem + 1
    end
    local bodyHeight = (22 * numberOfItem)
    tooltip.background.fileBody = tooltip.background.fileBody .. "?scalenearest=1;" .. 2 + bodyHeight -- 38
    tooltip.title.position[2] = tooltip.title.position[2] + (-1 + bodyHeight)
    tooltip.itemList.rect[4] = tooltip.itemList.rect[4] + (24 * numberOfItem)
    return tooltip
end
-- create and open a scripted pane instead of creating a normal tooltip
-- this func create a item list... can be told to mimic the recipe ingredient(s) list of the vanilla crafting pane(s)
function D8Tooltip:scriptedItemList(itemList, mousePosition, override, backgroundImage)
    if player.getProperty("d8TooltipUtilOpen") then return nil end -- stop the creation of a new pane if one is already open
    local vanillaConfig = root.assetJson("/interface/craftingtooltip/craftingtooltip.config")
    local override = override or {}
    local tooltip = root.assetJson("/shared/darkcraft8/d8ToolTipUtil/tooltip.config").scriptedItemList
    tooltip.gui.title = vanillaConfig.title

    local pathTemplate = "itemList.children" .. ""
    local listTemplate = {
        type = "layout",
        layoutType = "basic",
        rect = {0, 0, 145, 22}, -- both Height should be increased based on the amount of item descriptor
        children = {
            backgroundImg = vanillaConfig.itemList.schema.listTemplate.background,
            itemName = vanillaConfig.itemList.schema.listTemplate.itemName,
            itemIcon = {
                type = "itemslot",
                position = {4, 2},
                zlevel = 1,
                showCount = false, 
                callback = "null"
            },
            count = vanillaConfig.itemList.schema.listTemplate.count
        }
    }
    tooltip.gui.title.value = override.title or vanillaConfig.title.value or "ITEM"

    if not backgroundImage then
        tooltip.gui.background.fileHeader = vanillaConfig.background.stretchSet["end"] or "/interface/craftingtooltip/header.png"
        tooltip.gui.background.fileBody = vanillaConfig.background.stretchSet.inner or "/interface/craftingtooltip/body.png"
        tooltip.gui.background.fileFooter = vanillaConfig.background.stretchSet.begin or "/interface/craftingtooltip/footer.png"
    else
        tooltip.gui.background.fileHeader = backgroundImage.stretchSet["end"] or "/interface/craftingtooltip/header.png"
        tooltip.gui.background.fileBody = backgroundImage.stretchSet.inner or "/interface/craftingtooltip/body.png"
        tooltip.gui.background.fileFooter = backgroundImage.stretchSet.begin or "/interface/craftingtooltip/footer.png"
    end
    
    local numberOfItem = 0
    for index, descriptor in ipairs(itemList) do
        local cfg = root.itemConfig(descriptor)
        local name = descriptor
        local itemCount = 1
        if type(descriptor) == "table" then
            name = index .. "|" .. (descriptor.name or descriptor.item or descriptor.itemName)
            itemCount = descriptor.count or 1
        else
            name = index .. "|" .. name
        end
        tooltip.gui.itemList.children[name] = copy(listTemplate)

        tooltip.gui.itemList.children[name]["children"]["itemName"]["value"] = (cfg.parameters.shortdescription or cfg.config.shortdescription)
        
        if itemCount > 0 then
            if override.mimicRecipeTooltip then
                local itemPlayerCount = 0
                if type(descriptor) == "table" then
                    itemPlayerCount = player.hasCountOfItem({
                        name = (descriptor.name or descriptor.item or descriptor.itemName),
                        count = 1,
                        parameters = cfg.parameters
                    })
                else
                    itemPlayerCount = player.hasCountOfItem(descriptor)  
                end
                if itemPlayerCount >= itemCount then
                    tooltip.gui.itemList.children[name]["children"]["count"]["value"] = "^green;" .. itemPlayerCount .. "/" .. itemCount
                else
                    tooltip.gui.itemList.children[name]["children"]["count"]["value"] = "^red;" .. itemPlayerCount .. "/" .. itemCount
                end
            else
                tooltip.gui.itemList.children[name]["children"]["count"]["value"] = tostring(itemCount)
            end
        else
            tooltip.gui.itemList.children[name]["children"]["count"]["value"] = ""
        end

        tooltip.itemSlotList[name] = {
            path = "itemList." .. name .. ".itemIcon",
            item = descriptor
        }

        tooltip.gui.itemList.children[name]["rect"][2] = (22 * (#itemList - (numberOfItem + 1)))
        tooltip.gui.itemList.children[name]["rect"][4] =  22 + (22 * (#itemList - (numberOfItem + 1)))


        numberOfItem = numberOfItem + 1
    end
    local bodyHeight = (22 * numberOfItem)
    tooltip.gui.background.fileBody = tooltip.gui.background.fileBody .. "?scalenearest=1;" .. 2 + bodyHeight -- 38
    tooltip.gui.title.position[2] = tooltip.gui.title.position[2] + (-1 + bodyHeight)
    tooltip.gui.itemList.rect[4] = tooltip.gui.itemList.rect[4] + (24 * numberOfItem)

    if not self.tooltipCo then
        tooltip.gui.panefeature.offset = mousePosition
        local offset = {0,0}
        offset = vec2.add(offset, root.imageSize(tooltip.gui.background.fileFooter))
        offset = vec2.add(offset, root.imageSize(tooltip.gui.background.fileBody))
        offset = vec2.add(offset, root.imageSize(tooltip.gui.background.fileHeader))
        if vec2.sub(tooltip.gui.panefeature.offset, {-10, offset[2] - 10})[2] > 0 then
            if not pane.setPosition then
                tooltip.gui.panefeature.offset = vec2.sub(tooltip.gui.panefeature.offset, {-10, offset[2] - 10})
            else
                tooltip.gui.panefeature.offset = {0, 0}
                player.setProperty("d8TooltipUtil_offset", {-10, offset[2] - 10})
            end
        else
            if not pane.setPosition then
                tooltip.gui.panefeature.offset = vec2.sub(tooltip.gui.panefeature.offset, {-5, 15})
            else
                tooltip.gui.panefeature.offset = {0, 0}
                player.setProperty("d8TooltipUtil_offset", {-5, 15})
            end
        end

        self.tooltipCo = self:prepareScriptedTooltip(tooltip, mousePosition)
        D8Tooltip.oldMousePosition = mousePosition
    end

    --local trickTooltipToNOTUpdate = {} -- old trick so that the tooltip func doesn't try to open an another pane... no longer used as the closing is now handled by a custom func that use the cursor override
    --trickTooltipToNOTUpdate.background = copy(tooltip.gui.background)
    --trickTooltipToNOTUpdate.background.fileHeader = trickTooltipToNOTUpdate.background.fileHeader .. "?multiply=ffffff00"
    --trickTooltipToNOTUpdate.background.fileBody = trickTooltipToNOTUpdate.background.fileBody .. "?multiply=ffffff00"
    --trickTooltipToNOTUpdate.background.fileFooter = trickTooltipToNOTUpdate.background.fileFooter .. "?multiply=ffffff00"

    return
end

-- HOoo Boy!, that openup so many stupid idea XD... could also be used to make event based on mousePosition... also i think the only way to get mouse position on update time :O
-- cursorOverride is given the mousePosition in the screen instead of the pane allowing coders to position any pane next to the cursor
local _cursorOverride = cursorOverride -- incase someone load the script after init/the cursorOverride function
function cursorOverride(mousePosition)
    D8Tooltip:cursorOverride(mousePosition)
    if not vec2.eq((self.mousePosition or {0, 0}), mousePosition) then self.mousePosition = mousePosition end --sb.logInfo("new mousePosition = %s", self.mousePosition)

    local override
    if _cursorOverride then override = _cursorOverride(mousePosition) end
    return override
end

-- prepare the coroutine for the openning of the scripted Tooltip Pane
function D8Tooltip:prepareScriptedTooltip(tooltip, mousePosition) 
    local co = coroutine.create(function(tooltip, mousePosition)
        local tooltip, mousePosition = tooltip, mousePosition
        player.setProperty("d8TooltipUtilOpen", false) -- failsafe
        coroutine.yield()
        player.interact("ScriptPane", tooltip)
        self.tooltipCo = nil
    end)
    coroutine.resume(co, tooltip, mousePosition)
    return co
end