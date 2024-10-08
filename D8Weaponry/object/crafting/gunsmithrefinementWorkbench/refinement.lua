require "/scripts/util.lua"
refinement = {}

function refinement:init()
    self.config = root.assetJson(config.getParameter("scriptsConfig"))
    self.allowedItem = self.config.upgradableItemList
    self.tiersMaterials = self.config.tiersMaterials
    self.tag = self.config.tag
    self.skipWhitelist = self.config.skipWhitelist

    refinement:reset()
end

function refinement:update(dt)
    if self.itemTimer > 0 then
        self.itemTimer = self.itemTimer - dt 
    else
        self.itemTimer = 0.25
        self:populateItem("itemListArea.scrollArea.itemList")
        if self.selectedItemCfg.level then
            self:populateMaterials("materialListArea.scrollArea.itemList")
        end
    end
end

function refinement:uninit()
    widget.clearListItems("itemListArea.scrollArea.itemList")
    widget.clearListItems("materialListArea.scrollArea.itemList")
end

function refinement:populateItem(listPath)
    widget.clearListItems(listPath)
    for _, item in ipairs(player.itemsWithTag(self.tag)) do
        if self.skipWhitelist then
            local id = widget.addListItem(listPath)
            local path = string.format("%s.%s", listPath, id)
            local cfg = root.itemConfig(item)
            local level = item.parameters.level or cfg.config.level
            local price = item.parameters.price or cfg.config.price

            widget.setItemSlotItem(string.format("%s.item", path), item)
            widget.setData(path, {
                level = level,
                price = price,
                descriptor = item
            })
        else
            for _, name in ipairs(self.allowedItem) do 
                if item.name == name then
                    local id = widget.addListItem(listPath)
                    local path = string.format("%s.%s", listPath, id)
                    local cfg = root.itemConfig(item)
                    local level = item.parameters.level or cfg.config.level
                    local price = item.parameters.price or cfg.config.price

                    widget.setItemSlotItem(string.format("%s.item", path), item)
                    widget.setData(path, {
                        level = level,
                        price = price,
                        descriptor = item
                    })
                end
            end
        end
    end
end

function refinement:populateMaterials(listPath)
    --Math Part
    widget.clearListItems(listPath)
    local price = self.selectedItemCfg.price
    local level = self.selectedItemCfg.level
    self.upgradeMaterials = {}
    if self.selectedItemCfg.level ~= 10 then
        widget.setButtonEnabled("upgradeBtn", true)
        for _, b in ipairs(self.tiersMaterials[""..math.ceil(level)]) do
            local itemConfig = root.itemConfig(b[1])
            local amount = b[2]
            local amountMath = math.ceil((price/16)/b[2])
            amountMath = math.ceil(b[2] + amountMath)
            if itemConfig["config"]["currency"] then
                if b[1] == "money" then
                    amountMath = math.ceil( (price*root.evalFunction("itemLevelPriceMultiplier", level)) - price)
                elseif b[1] == "essence" then
                    local prevValue = root.evalFunction("weaponEssenceValue", level)
                    local newValue = root.evalFunction("weaponEssenceValue", level + 1)
                    amountMath = math.ceil(newValue - prevValue)
                else
                    amountMath = math.ceil((price)*(1.15))
                end
            end

            local id = widget.addListItem(listPath)
            local path = string.format("%s.%s", listPath, id)
            local itemCount = player.hasCountOfItem(b[1])
            if  root.itemConfig(b[1])["config"]["currency"] then
                itemCount = player.currency(b[1])
            end
            local itemCfg = root.itemConfig(b[1])
            local itemName = "Upgrade : " .. (itemCfg.parameters.shortdescription or itemCfg.config.shortdescription)

            if (itemCount < amountMath) and not player.isAdmin() then
                count = string.format("^red;%s/%s", itemCount, amountMath)
                widget.setButtonEnabled("upgradeBtn", false)
            else
                count = string.format("^green;%s/%s", itemCount, amountMath)
            end

            widget.setText(string.format("%s.itemName", path), itemName)
            widget.setText(string.format("%s.count", path), count)
            widget.setItemSlotItem(string.format("%s.itemIcon", path), b[1])

            local consume = {
                descriptor = b[1],
                up = amountMath
            }
            table.insert(self.upgradeMaterials, consume)
        end
    end

    if level > 1 then
        for index, b in ipairs(self.tiersMaterials[string.format("%s", (level-1))]) do
            local itemConfig = root.itemConfig(b[1])
            local amount = b[2]
            local amountMath = math.ceil((price/16)/b[2])
            if itemConfig["config"]["currency"] then
                if b[1] == "money" then
                    amountMath = math.ceil( (price*root.evalFunction("itemLevelPriceMultiplier", level - 1)) - price)
                elseif b[1] == "essence" then
                    local prevValue = root.evalFunction("weaponEssenceValue", level - 1)
                    local newValue = root.evalFunction("weaponEssenceValue", level)
                    amountMath = math.ceil(newValue - prevValue)
                else
                    amountMath = math.ceil((price)*(1.15))
                end
            end

            if self.upgradeMaterials[index] then
                self.upgradeMaterials[index]["downName"] = b[1]
                self.upgradeMaterials[index]["down"] = amountMath
            else
                self.upgradeMaterials[index] = {}
                self.upgradeMaterials[index]["downName"] = b[1]
                self.upgradeMaterials[index]["down"] = amountMath
            end
            widget.setButtonEnabled("downgradeBtn", true)

            local id = widget.addListItem(listPath)
            local path = string.format("%s.%s", listPath, id)
            local itemCount = player.hasCountOfItem(b[1])
            local itemCfg = root.itemConfig(b[1])
            local itemName = "Downgrade : " .. (itemCfg.parameters.shortdescription or itemCfg.config.shortdescription)

            
            count = string.format("^yellow;%s", amountMath)

            widget.setText(string.format("%s.itemName", path), itemName)
            widget.setText(string.format("%s.count", path), count)
            widget.setItemSlotItem(string.format("%s.itemIcon", path), b[1])
        end
    else
        widget.setButtonEnabled("downgradeBtn", false)
    end
end

function init()
    refinement:init()
end
function update(dt)
    refinement:update(dt)
end
function uninit()
    refinement:uninit()
end

function itemSelected()
    refinement.selectedItem = widget.getListSelected("itemListArea.scrollArea.itemList")
    if refinement.selectedItem then
        local data = widget.getData(string.format("itemListArea.scrollArea.itemList.%s", refinement.selectedItem))
        refinement.selectedItemCfg.level = math.ceil(data.level) or 1
        refinement.selectedItemCfg.price = data.price or 1
        refinement.selectedItemCfg.descriptor = data.descriptor or {}
        self.itemTimer = 0
        widget.setButtonEnabled("upgradeBtn", false)
        widget.setButtonEnabled("downgradeBtn", false)
    end
end
function btn(buttonName)
    if "upgradeBtn" == buttonName then
        player.consumeItem(refinement.selectedItemCfg.descriptor, false, true)
        for _, item in ipairs(refinement.upgradeMaterials) do
            local toBeSpent = {}
            if item["descriptor"] and item["up"] then
                if type(item["descriptor"]) == "string" then
                    toBeSpent = {
                        parameters = {},
                        name = item["descriptor"],
                        count = item["up"]
                    }
                else
                    toBeSpent = item["descriptor"]
                    toBeSpent.count = item["up"]
                end
                if not player.currency(item["descriptor"]) then
                    player.consumeItem(toBeSpent)
                else
                    player.consumeCurrency(item["descriptor"], item["up"])
                end
            end
        end
        local newItem = {
            name = refinement.selectedItemCfg.descriptor.name,
            parameters = {},
            count = 1
        }
        for name, value in pairs(refinement.selectedItemCfg.descriptor.parameters) do
            if name ~= "tooltipFields" then
                newItem.parameters[name] = value
            end
            if not refinement.selectedItemCfg.descriptor.parameters.d8Weaponry_resetTooltipOnUpgrade and name == "tooltipFields" then
                newItem.parameters[name] = value
            end
        end
        local itemCfg = root.itemConfig(refinement.selectedItemCfg.descriptor)
        if itemCfg.config.upgradeParameters and (refinement.selectedItemCfg.level + 1) == 6 then
            for name, value in pairs(itemCfg.config.upgradeParameters) do
                if type(value) == "table" then
                    for name2, value2 in pairs(value) do
                        if not newItem.parameters[name] then
                            newItem.parameters[name] = {}
                        end
                        newItem.parameters[name][name2] = value2
                    end
                else
                    newItem.parameters[name] = value
                end
            end
        end
        newItem.parameters.level = refinement.selectedItemCfg.level + 1
        player.giveItem(newItem)
        
        refinement:reset()
    end
    if "downgradeBtn" == buttonName then
        player.consumeItem(refinement.selectedItemCfg.descriptor, false, true)
        for _, item in ipairs(refinement.upgradeMaterials) do
            local toBeSpent = {}
            if item["downName"] and item["down"] then
                if type(item["downName"]) == "string" then
                    toBeSpent = {
                        parameters = {},
                        name = item["downName"],
                        count = item["down"]
                    }
                else
                    toBeSpent = item["downName"]
                    toBeSpent.count = item["down"]
                end
                if not player.isAdmin() then
                    player.giveItem(toBeSpent)
                end
            end
        end
        local newItem = {
            name = refinement.selectedItemCfg.descriptor.name,
            parameters = {},
            count = 1
        }
        for name, value in pairs(refinement.selectedItemCfg.descriptor.parameters) do
            if name ~= "tooltipFields" then
                newItem.parameters[name] = value
            end
            if not refinement.selectedItemCfg.descriptor.parameters.d8Weaponry_resetTooltipOnUpgrade and name == "tooltipFields" then
                newItem.parameters[name] = value
            end
        end
        local itemCfg = root.itemConfig(refinement.selectedItemCfg.descriptor)
        if itemCfg.config.upgradeParameters and (refinement.selectedItemCfg.level) == 6 then
            for name, value in pairs(itemCfg.config.upgradeParameters) do
                if type(value) == "table" then
                    for name2, value2 in pairs(value) do
                        if not newItem.parameters[name] then
                            newItem.parameters[name] = {}
                        end
                        newItem.parameters[name][name2] = itemCfg.config[name][name2]
                    end
                else
                    newItem.parameters[name] = itemCfg.config[name]
                end
            end
        end
        newItem.parameters.level = refinement.selectedItemCfg.level - 1
        
        player.giveItem(newItem)
        refinement:reset()
    end
end

function refinement:reset()
    self.itemTimer = 0
    self.selectedItemCfg = {}
    
    widget.setButtonEnabled("upgradeBtn", false)
    widget.setButtonEnabled("downgradeBtn", false)

    self:populateItem("itemListArea.scrollArea.itemList")
    widget.clearListItems("materialListArea.scrollArea.itemList")
end

function createTooltip(mousePosition)
    local part = {}
    local partId
    local tooltip

    for n,w in pairs(config.getParameter("gui")) do
        if widget.inMember(n, mousePosition) then
            part = config.getParameter("gui")[n]
            partId = n
            break
        end
    end

    if part["tooltip"] == nil then return end
        
    local inputs = part["tooltip"]
    tooltip = config.getParameter("tooltipLayout")
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

function d8Weaponry_upgradeParameters(level, itemConfig) -- Todo

end