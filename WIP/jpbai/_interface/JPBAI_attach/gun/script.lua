require("/WIP/jpbai/_interface/JPBAI_attach/main.lua")
require "/shared/darkcraft8/D8TooltipUtil.lua"

local listContent = {}
local attachList = {}
local cfgListMode = "default"

function init()
    getCurrentItem()
    buildAttachList()
end

function update(dt)
    updateItemIcon()
end

function uninit()
    giveCurrentItemBack()
end

function attachKindSelected()
    local list = "attachKind.list"
    local selected = widget.getListSelected(list)

    if selected then
        local data = widget.getData(list .. "." .. selected)

        if data.func then
            if _ENV[data.func] then
                _ENV[data.func]()
            end
        end
    end
end

function attachCfgSelected()
    local list = "attachCfg.list"
    local selected = widget.getListSelected(list)

    if selected then
        local data = widget.getData(list .. "." .. selected)
        if cfgListMode == "munition" then
            local magCap = getParameter("magazineCapacity", getConfig("magazineCapacity", 0))
            local slotItem = widget.itemSlotItem(list .. "." .. selected .. ".itemIcon")
            local curSwapSlotItem = player.swapSlotItem()
            local returnedItem
            if curSwapSlotItem then
                if d8WeapItem.isMunition(curSwapSlotItem) then
                    curSwapSlotItemString = {
                        name = curSwapSlotItem["name"],
                        parameters = curSwapSlotItem["parameters"]
                    }
                    local curMag = getParameter("magazine", getConfig("magazine", {}))
                    local munitionAmount = d8WeapItem.munitionAmount()
                    if magCap > munitionAmount then
                        if curSwapSlotItem["count"] > (magCap - munitionAmount) then
                            returnedItem = {
                                name = curSwapSlotItem["name"],
                                count = curSwapSlotItem["count"] - (magCap - munitionAmount),
                                parameters = curSwapSlotItem["parameters"]
                            }
                            curSwapSlotItem["count"] = (magCap - munitionAmount)
                        end
                        if not swapSlotItem["parameters"]["magazine"] then swapSlotItem["parameters"]["magazine"] = getConfig("magazine", {}) end
                        if munitionAmount > 0 then
                            local itemToString = sb.printJson({
                                name = curMag[1]["name"],
                                parameters = curMag[1]["parameters"]
                            })
                            if itemToString == sb.printJson(curSwapSlotItemString) then
                                swapSlotItem["parameters"]["magazine"][1]["count"] = swapSlotItem["parameters"]["magazine"][1]["count"] + curSwapSlotItem["count"]
                            else
                                table.insert(swapSlotItem["parameters"]["magazine"], 1, curSwapSlotItem)
                            end
                        else
                            table.insert(swapSlotItem["parameters"]["magazine"], curSwapSlotItem)
                        end
                        --player.setSwapSlotItem(returnedItem)
                    end
                end
            elseif data.index then
                if not swapSlotItem["parameters"]["magazine"] then swapSlotItem["parameters"]["magazine"] = getConfig("magazine", {}) end
                local index = data.index
                local item = {
                    name = swapSlotItem["parameters"]["magazine"][index]["name"],
                    parameters = swapSlotItem["parameters"]["magazine"][index]["parameters"],
                    count = 1
                }
                swapSlotItem["parameters"]["magazine"][index]["count"] = swapSlotItem["parameters"]["magazine"][index]["count"] - 1
                --player.giveItem(item)
                if swapSlotItem["parameters"]["magazine"][index]["count"] <= 0 then
                    table.remove(swapSlotItem["parameters"]["magazine"], index)
                end
            end
            buildMagazine()
            buildAttachList()
        end
    end
end

function buildAttachList()
    local attachCfg = getParameter("attachCfg", getConfig("attachCfg", {}))
    local attach = getParameter("attach", getConfig("attach", {}))
    attachCfg.munition = {
        kind = "munition",
        name = "Munition Arrangement : " .. d8WeapItem.munitionAmount() .. "/" .. getParameter("magazineCapacity", getConfig("magazineCapacity", {})),
        func = "munition",
        icon = "/WIP/jpbai/_interface/JPBAI_attach/gun/icon/munition.png"
    }
    local list = "attachKind.list"
    widget.clearListItems(list)
    for _, path in ipairs(attachList) do 
        listContent[path] = nil
    end
    attachList = {}
    for attachName, attachCfg in pairs(attachCfg) do 
        local id = widget.addListItem(list)
        local path = list .. "." .. id
        local item = {
            name = "perfectlygenericitem",
            parameters = {
                shortdescription = attachCfg.name or attachName,
                description = "",
                inventoryIcon = attachCfg.icon,
                placementImage = "/assetmissing.png"
            },
            count = 0
        }
        widget.setItemSlotItem(path .. ".itemIcon", item)
        widget.setData(path, {
            func = attachCfg.func
        })
        listContent[path] = " " .. attachCfg.name or attachName .. "  "
        table.insert(attachList, path)
    end
end

function munition()
    cfgListMode = "munition"
    buildMagazine()
end

function buildMagazine()
    local magCap = getParameter("magazineCapacity", getConfig("magazineCapacity", 0))
    local curMag = getParameter("magazine", getConfig("magazine", {}))
    local list = "attachCfg.list"
    widget.clearListItems(list)
    for index, itemDescriptor in ipairs(curMag) do 
        local id = widget.addListItem(list)
        local path = list .. "." .. id
        local shortDescription = item.getParameter(itemDescriptor, "shortDescription", item.getConfig(itemDescriptor, "shortDescription", "<Error 404> : ShortDescription Not Found"))
        widget.setItemSlotItem(path .. ".itemIcon", itemDescriptor)
        widget.setText(path .. ".itemName", shortDescription)
        widget.setData(path, {
            index = index
        })
    end
    if #curMag == 0 then
        local id = widget.addListItem(list)
        local path = list .. "." .. id
        local shortDescription = "add munition"
        local item = {
            name = "perfectlygenericitem",
            parameters = {
                shortdescription = shortDescription,
                description = "click with a munition to add it to the magazine arrangement",
                inventoryIcon = "/WIP/jpbai/_interface/JPBAI_attach/gun/icon/munition.png",
                placementImage = "/WIP/jpbai/_interface/JPBAI_attach/gun/icon/munition.png"
            },
            count = 0
        }
        widget.setItemSlotItem(path .. ".itemIcon", item)
        widget.setText(path .. ".itemName", shortDescription)
    end
end

-- d8Weap --
d8WeapItem = d8WeapItem or {}
function d8WeapItem.munitionAmount()
    local curMag = getParameter("magazine", getConfig("magazine", {}))
    local amount = 0
    for _, item in ipairs(curMag) do 
        if type(item) == "table" then 
            amount = amount + item.count
        else
            amount = amount + 1
        end
    end
    return amount
end

function d8WeapItem.isMunition(itemDesc)
    return item.getParameter(itemDesc, "projectileType", item.getConfig(itemDesc, "projectileType", false))
end

-- item --
item = item or {}
function item.getParameter(itemDesc, variable, defaultValue) -- return the value of the variable in "parameters" or nil otherwise
    return root.createItem(itemDesc)["parameters"][variable] or defaultValue
end

function item.getConfig(itemDesc, variable, defaultValue) -- return the value of the variable in "config" or nil otherwise
    return root.itemConfig(itemDesc)["config"][variable] or defaultValue
end

-- tooltip --
function createTooltip(mousePosition)
    local part
    local partId
    local tooltip

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

    if part == nil then return end
    if type(part) == "string" then tooltip = D8Tooltip:text(part) end

    return tooltip
end