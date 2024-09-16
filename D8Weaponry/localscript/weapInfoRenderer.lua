-- This is rendered localy and not on other client screen's 
-- information about the selected weapon if compatible (ammo, ability charge, ect)
require "/scripts/util.lua"
require "/scripts/interp.lua"

local vanillaInit = init
local vanillaUpdate = update
local vanillaTeleportOut = teleportOut
local vanillaUninit = uninit

local d8WeaponryUtils = getmetatable('').d8WeaponryUtils
if type(d8WeaponryUtils) ~= "table" then
    d8WeaponryUtils = {
        drawableList = {
        }
    }
    getmetatable('').d8WeaponryUtils = d8WeaponryUtils
end--For any external Drawable, draw before those of the weapons... currently disabled

local config 
local pixel = 0.125
local time = 0

local memory = {
}
local weapon = {
    count = 1,
    name = "don't think too much about why there a descriptor here",
    parameters = {
    }
}
local d8WeaponryDrawableList = {} 
local weapParam
local weapConf
local primaryConf = {}
local secondaryConf = {}

local initTimer = 2
local opacityMax = {8,5}
local opacity = {0,0}
local textOpacity = 0
local barOffset = 0

local prevPrimary = {
    count = 1,
    name = "don't think too much about why there a descriptor here",
    parameters = {
    }
}
local prevSecondary = {
    count = 1,
    name = "don't think too much about why there a descriptor here",
    parameters = {
    }
}

function init()
    vanillaInit()
    config = root.assetJson("/D8Weaponry.config")
    if config["opacityMax"] then
        opacityMax = config["opacityMax"]
    end
end

function update(dt)
    vanillaUpdate(dt)
    if config["customAmmoRenderer"] then
        if initTimer > 0 then
            initTimer = initTimer - 1
        else
            if player.primaryHandItem() or player.altHandItem() then
                local primary = player.primaryHandItem()
                local secondary = player.altHandItem()
                local same = true
                local concatedParam = weaponAnalisis(primary, secondary)
                weapon["parameters"] = concatedParam
            end
            local renderIndex = 0
            --sb.logInfo("%s", d8WeaponryUtils)
            --if d8WeaponryUtils.drawableList then
            --    for pos, drawable in ipairs(d8WeaponryUtils.drawableList) do
            --        drawableUpdate(drawable, pos)
            --    end
            --end
            if pcall(function()
                    local result = type(weapon["parameters"]["d8Weaponry"])
                    if result == "table" and (player.primaryHandItem() or player.altHandItem()) then
                        return result 
                    else error()
                    end 
                end) then
                if textOpacity < 185 then
                    textOpacity = textOpacity + 14
                    if textOpacity > 185 then
                        textOpacity = 185
                    end
                end
                barOffset = util.clamp(barOffset + (4*dt), 2, 3)
                if opacity[1] < opacityMax[1] or opacity[2] < opacityMax[2] then
                    if opacity[2] == 9 then
                        opacity[1] = opacity[1] + 4
                        opacity[2] = 0
                    else
                        opacity[2] = opacity[2] + 4
                    end
                    if opacity[1] > opacityMax[1] then
                        opacity[1] = opacityMax[1]
                    end
                    if (opacity[2] > opacityMax[2] and opacity[1] == opacityMax[1]) or opacity[2] > 9 then
                        opacity[2] = opacityMax[2]
                    end
                end

                weapParam = weapon["parameters"]
                weapConf = weapon["parameters"]["d8Weaponry"]
                for index, value in ipairs(weapConf) do
                    local max = value[value["ammoMaxName"]]
                    local count = value[value["ammoCountName"]]
                    if not memory[index] then
                        memory[index] = {}
                        memory[index]["ammoText"] = "/assetmissing.png"
                        memory[index]["barText"] = "/assetmissing.png"
                    end
                    renderBar(0, -barOffset-(1*(renderIndex)), max, count, index)
                    renderIndex = renderIndex + 1
                end
                
                time = ( (-175) + (time + (12*(dt))) ) % 175
            else
                time = 0
                if textOpacity > 0 then
                    textOpacity = textOpacity - 9
                    if textOpacity < 0 then
                        textOpacity = 0
                    end
                end
                barOffset = util.clamp(barOffset - (1.5*dt), 2, 4)
                if opacity[1] > 0 or opacity[2] > 0 then
                    if opacity[2] == 0 then
                        opacity[1] = opacity[1] - 2
                        opacity[2] = 9
                    else
                        opacity[2] = opacity[2] - 2
                    end
                    if opacity[1] < 0 then
                        opacity[1] = 0
                    end
                    if opacity[2] < 0 then
                        opacity[2] = 0
                    end
                    
                    for index, value in ipairs(weapConf) do
                        local max = value[value["ammoMaxName"]]
                        local count = value[value["ammoCountName"]]
                        if not memory[index] then
                            memory[index] = {}
                            memory[index]["ammoText"] = "/assetmissing.png"
                            memory[index]["barText"] = "/assetmissing.png"
                        end
                        renderBar(0,  -barOffset-(1*(renderIndex)), max, count, index)
                        renderIndex = renderIndex + 1
                    end
                end
            end
        end
    end
end

function teleportOut()
    vanillaTeleportOut()

end

function uninit()
    vanillaUninit()

end

function drawableUpdate(drawable, pos)--Way less annoing to handles effect/stat script in the renderer instead of their own scripts... maybe it not a good idea
    local ressourceName = drawable.ressourceName
    local propertyName = drawable.propertyName
    local isBar = drawable.isBar
    local skip = false

    if ressourceName and isBar then
        local pendingRendering = copy(drawable)
        local name = ressourceName

        pendingRendering["ammoMaxName"] = string.format("Max-%s", name)
        pendingRendering["ammoCountName"] = string.format("%s", name)
        pendingRendering[pendingRendering["ammoMaxName"]] = (status.resourceMax(name))
        pendingRendering[pendingRendering["ammoCountName"]] = (status.resource(name))
        
        for index, value in ipairs(weapon["parameters"]["d8Weaponry"]) do
            local match = true
            for a,b in pairs(value) do
                if pendingRendering[a] ~= b then
                    match = false
                end
            end

            if match then
                table.remove(weapon["parameters"]["d8Weaponry"], index)
            end
        end
        table.insert(weapon["parameters"]["d8Weaponry"], pos, pendingRendering)
    elseif propertyName and isBar then

    end

end

function weaponAnalisis(primary, secondary)
    local validprimary
    local validsecondary
    local concatedParam = {}
    local currentIndex = 0
    if primary then
        if primary["parameters"]["d8Weaponry"] then
            validprimary = true
            primaryConf = primary
        end
    end
    if secondary then
        if secondary["parameters"]["d8Weaponry"] then
            validsecondary = true
            secondaryConf = secondary
        end
    end
    if validprimary and not validsecondary then
        concatedParam["d8Weaponry"] = {}
        for index, value in ipairs(primaryConf["parameters"]["d8Weaponry"]) do
            local pendingRendering = copy(value)
            local name = value.ressourceName
            pendingRendering["ammoMaxName"] = string.format("%sMax-%s", currentIndex, name or pendingRendering["ammoMaxName"])
            pendingRendering["ammoCountName"] = string.format("%s-%s", currentIndex, name or pendingRendering["ammoCountName"])
            pendingRendering[name or pendingRendering["ammoMaxName"]]    = primaryConf["parameters"][value["ammoMaxName"]]-- or primaryConf["config"][value["ammoMaxName"]]
            pendingRendering[name or pendingRendering["ammoCountName"]]  = primaryConf["parameters"][value["ammoCountName"]]-- or primaryConf["config"][value["ammoCountName"]]
            
            if value.isRessource then
                local cost = 0
                if primaryConf["parameters"]["primaryAbility"] then
                    cost = (primaryConf["parameters"]["primaryAbility"]["energyUsage"] * primaryConf["parameters"]["primaryAbility"]["fireTime"] * (primaryConf["parameters"]["primaryAbility"]["energyUsageMultiplier"] or 1.0) )
                else
                    --cost = (primaryConf["config"]["primaryAbility"]["energyUsage"] * primaryConf["config"]["primaryAbility"]["fireTime"] * (primaryConf["config"]["primaryAbility"]["energyUsageMultiplier"] or 1.0) )
                end
                pendingRendering[pendingRendering["ammoMaxName"]] = (status.resourceMax(name or value["ammoMaxName"]) / cost)
                pendingRendering[pendingRendering["ammoCountName"]] = (status.resource(name or value["ammoCountName"]) / cost)
                
            end
            table.insert(concatedParam["d8Weaponry"], pendingRendering)
            currentIndex = (currentIndex + 1)
        end
    elseif not validprimary and validsecondary then
        concatedParam["d8Weaponry"] = {}
        for index, value in ipairs(secondaryConf["parameters"]["d8Weaponry"]) do
            local pendingRendering = copy(value)
            local name = value.ressourceName
            pendingRendering["ammoMaxName"] = string.format("%sMax-%s", currentIndex, name or pendingRendering["ammoMaxName"])
            pendingRendering["ammoCountName"] = string.format("%s-%s", currentIndex, name or pendingRendering["ammoCountName"])
            pendingRendering[name or pendingRendering["ammoMaxName"]]    = secondaryConf["parameters"][value["ammoMaxName"]]-- or secondaryConf["config"][value["ammoMaxName"]]
            pendingRendering[name or pendingRendering["ammoCountName"]]  = secondaryConf["parameters"][value["ammoCountName"]]-- or secondaryConf["config"][value["ammoCountName"]]
            if value.isRessource then
                local cost = 0
                if secondaryConf["parameters"]["primaryAbility"] then
                    cost = (secondaryConf["parameters"]["primaryAbility"]["energyUsage"] * secondaryConf["parameters"]["primaryAbility"]["fireTime"] * (secondaryConf["parameters"]["primaryAbility"]["energyUsageMultiplier"] or 1.0) )
                else
                    --cost = (secondaryConf["config"]["primaryAbility"]["energyUsage"] * secondaryConf["config"]["primaryAbility"]["fireTime"] * (secondaryConf["config"]["primaryAbility"]["energyUsageMultiplier"] or 1.0) )
                end
                pendingRendering[pendingRendering["ammoMaxName"]] = (status.resourceMax(name or value["ammoMaxName"]) / cost)
                pendingRendering[pendingRendering["ammoCountName"]] = (status.resource(name or value["ammoCountName"]) / cost)
            end
            table.insert(concatedParam["d8Weaponry"], pendingRendering)
            currentIndex = (currentIndex + 1)
        end
    elseif validprimary and validsecondary then
        -- preparation
        concatedParam["d8Weaponry"] = {}
        --concatedParam = oldConcatParam(concatedParam)
        for index, value in ipairs(primaryConf["parameters"]["d8Weaponry"]) do
            local pendingRendering = copy(value)
            local name = value.ressourceName
            pendingRendering["ammoMaxName"] = string.format("%sMax-%s", currentIndex, name or pendingRendering["ammoMaxName"])
            pendingRendering["ammoCountName"] = string.format("%s-%s", currentIndex, name or pendingRendering["ammoCountName"])
            pendingRendering[name or pendingRendering["ammoMaxName"]]    = primaryConf["parameters"][value["ammoMaxName"]]-- or primaryConf["config"][value["ammoMaxName"]]
            pendingRendering[name or pendingRendering["ammoCountName"]]  = primaryConf["parameters"][value["ammoCountName"]]-- or primaryConf["config"][value["ammoCountName"]]
            if value.isRessource then
                local cost = 1
                if primaryConf["parameters"]["primaryAbility"] then
                    cost = (primaryConf["parameters"]["primaryAbility"]["energyUsage"] * primaryConf["parameters"]["primaryAbility"]["fireTime"] * (primaryConf["parameters"]["primaryAbility"]["energyUsageMultiplier"] or 1.0) )
                else
                    --cost = (primaryConf["config"]["primaryAbility"]["energyUsage"] * primaryConf["config"]["primaryAbility"]["fireTime"] * (primaryConf["config"]["primaryAbility"]["energyUsageMultiplier"] or 1.0) )
                end
                pendingRendering[pendingRendering["ammoMaxName"]] = (status.resourceMax(name or value["ammoMaxName"]) / cost)
                pendingRendering[pendingRendering["ammoCountName"]] = (status.resource(name or value["ammoCountName"]) / cost)
            end
            table.insert(concatedParam["d8Weaponry"], pendingRendering)
            currentIndex = (currentIndex + 1)
        end
        for index, value in ipairs(secondaryConf["parameters"]["d8Weaponry"]) do
            local pendingRendering = copy(value)
            local name = value.ressourceName
            pendingRendering["ammoMaxName"] = string.format("%sMax-%s", currentIndex, name or pendingRendering["ammoMaxName"])
            pendingRendering["ammoCountName"] = string.format("%s-%s", currentIndex, name or pendingRendering["ammoCountName"])
            pendingRendering[name or pendingRendering["ammoMaxName"]]    = secondaryConf["parameters"][value["ammoMaxName"]]-- or secondaryConf["config"][value["ammoMaxName"]]
            pendingRendering[name or pendingRendering["ammoCountName"]]  = secondaryConf["parameters"][value["ammoCountName"]]-- or secondaryConf["config"][value["ammoCountName"]]
            if value.isRessource then
                local cost = 1
                if secondaryConf["parameters"]["primaryAbility"] then
                    cost = (secondaryConf["parameters"]["primaryAbility"]["energyUsage"] * secondaryConf["parameters"]["primaryAbility"]["fireTime"] * (secondaryConf["parameters"]["primaryAbility"]["energyUsageMultiplier"] or 1.0) )
                else
                    --cost = (secondaryConf["config"]["primaryAbility"]["energyUsage"] * secondaryConf["config"]["primaryAbility"]["fireTime"] * (secondaryConf["config"]["primaryAbility"]["energyUsageMultiplier"] or 1.0) )
                end
                pendingRendering[pendingRendering["ammoMaxName"]] = (status.resourceMax(name or value["ammoMaxName"]) / cost)
                pendingRendering[pendingRendering["ammoCountName"]] = (status.resource(name or value["ammoCountName"]) / cost)
            end
            table.insert(concatedParam["d8Weaponry"], pendingRendering)
            currentIndex = (currentIndex + 1)
        end
    end
    
    return concatedParam
end

function renderBar(barX, barY, amountMax, count, slot, ammoText, barText, RGB)
    local renderConf = {}
    if not amountMax then
        amountMax = 0
    end
    if not count then
        count = 0
    end
    if weapon["parameters"]["d8Weaponry"] and type(weapon["parameters"]["d8Weaponry"]) == "table"  then
        renderConf = weapon["parameters"]["d8Weaponry"][slot]
        if renderConf then
            if renderConf["ammoText"] then
                memory[slot]["ammoText"] = renderConf["ammoText"]
                ammoText = renderConf["ammoText"]
            end
            if renderConf["barText"] then
                memory[slot]["barText"] = renderConf["barText"]
                barText = renderConf["barText"]
            end
            if renderConf["RGB"] then
                memory[slot]["RGB"] = renderConf["RGB"]
                RGB = renderConf["RGB"]
            end
            if renderConf["Rotate"] then
                memory[slot]["Rotate"] = renderConf["Rotate"]
                Rotate = renderConf["Rotate"]
            end
            if renderConf["invertRender"] then
                count = amountMax - count
            end
        else
            return
        end
    end
    local numberOnly = config["numberOnly"]
    if renderConf["numberOnly"] ~= nil then
        numberOnly = renderConf["numberOnly"]
    end
    
    local sizeNumberThing = 2
    local ammoPosAMOffsetValue = (1.5 / 0.45)
    local ammoPosAMOffset = amountMax + ammoPosAMOffsetValue
    local ammoPos = {
        barX - ((util.clamp(ammoPosAMOffset, 1, 20 + ammoPosAMOffsetValue) - (util.clamp(ammoPosAMOffset, 1, 20 + ammoPosAMOffsetValue)/2)) * (sizeNumberThing/4)),
        barY
    }
    if numberOnly then
        local amountMax = 1 + (1.34 / pixel)
        ammoPos[1] = barX - ((util.clamp(amountMax, 1, 20) - (util.clamp(amountMax, 1, 20)/2)) * (sizeNumberThing/4))
    end
    local windowSize
    local posMultiply = 14
    if starExtensions then
        windowSize = window.size()
        windowSize = {windowSize[1] / (posMultiply * 1.015), windowSize[2] / (posMultiply / 1.07)}
    end
    if config["sideLeaning"] ~= "center" then
        ammoPos[1] = barX
    end
    local ammoText = memory[slot]["ammoText"]
    local barText = memory[slot]["barText"]
    local RGB = memory[slot]["RGB"]
    local Rotate = memory[slot]["Rotate"] or 0
    local posOffset = config["posOffset"]
    ammoPos[1] = ammoPos[1] + posOffset[1]
    ammoPos[2] = ammoPos[2] + posOffset[2]

    local segmentSize = (1/(amountMax/(amountMax/sizeNumberThing)))
    if numberOnly then
        outpostSignNumber(count, ammoPos, opacity, 0.5, true, numberOnly)
    else
        local segmentNum = util.clamp(math.ceil(amountMax), 0, 20)
        
        while segmentNum > 0 do
            local drawable = {
                image = string.format("%s:?scalenearest=%s;1?multiply=7F7F7F%s%s", barText, segmentSize, opacity[1], opacity[2]),
                position = {
                    (ammoPos[1] + 0.45) + (segmentSize*segmentNum),
                    ammoPos[2]
                },
                color = {255,255,255},
                fullbright = true,
                rotation = 0
            }
            if config["sideLeaning"] == "left" then
                drawable["position"][1] = (ammoPos[1] - 0.45) - (segmentSize*segmentNum)
            end
            if RGB then
                drawable["image"] = string.format("%s:?scalenearest=%s;1?hueshift=%s?multiply=7F7F7F%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, opacity[1], opacity[2])
            end
            if string.find(barText, ":") then
                if RGB then
                    drawable["image"] = string.format("%s?scalenearest=%s;1?hueshift=%s?multiply=7F7F7F%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, opacity[1], opacity[2])
                else
                    drawable["image"] = string.format("%s?scalenearest=%s;1?multiply=7F7F7F%s%s", barText, segmentSize, opacity[1], opacity[2])
                end
            end
            if not starExtensions or not config["starExtensions"]["useUiAnimator"] then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            elseif not starExtensions then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            elseif config["starExtensions"]["posAnchor"] == "player" then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            else
                local drawX = drawable["position"][1]
                local drawY = drawable["position"][2]
                local anchor = config["starExtensions"]["posAnchor"]
                -- default is bottomLeft
                drawY = drawable["position"][2] + 8
                if anchor == "bottomRight" then
                    drawX = drawable["position"][1] + windowSize[1]
                    drawY = drawable["position"][2] + 8
                elseif anchor == "topRight" then
                    drawX = drawable["position"][1] + windowSize[1]
                    drawY = drawable["position"][2] + windowSize[2]
                elseif anchor == "middleTop" then
                    drawX = drawable["position"][1] + (windowSize[1]/2)
                    drawY = drawable["position"][2] + windowSize[2]
                elseif anchor == "center" then
                    drawX = drawable["position"][1] + (windowSize[1]/2)
                    drawY = drawable["position"][2] + (windowSize[2]/2) + 2
                elseif anchor == "middleBottom" then
                    drawX = drawable["position"][1] + (windowSize[1]/2)
                    drawY = drawable["position"][2] + 8
                elseif anchor == "middleRight" then
                    drawX = drawable["position"][1] + windowSize[1]
                    drawY = drawable["position"][2] + (windowSize[2]/2) + 2
                elseif anchor == "middleLeft" then
                    drawY = drawable["position"][2] + (windowSize[2]/2) + 2
                elseif anchor == "topLeft" then
                    drawY = drawable["position"][2] + windowSize[2]
                end

                interface.drawDrawable(drawable, {((posOffset[1] + 1) + drawX) * posMultiply, (posOffset[2] + drawY) * posMultiply}, 2, {255,255,255})
            end
            segmentNum = segmentNum - 1
        end
        
        local segmentNum = util.clamp(math.ceil(count), 0, 20)
        memory[slot]["slideTimer"] = memory[slot]["slideTimer"] or 0
        memory[slot]["invertSlide"] = memory[slot]["invertSlide"] or false
        local slideTimer = 0
        if memory[slot]["lastAmmoCount"] and memory[slot]["lastAmmoCount"] > segmentNum then
            local min = memory[slot]["lastAmmoCount"]
            if min <= 0 then
                min = 1
            end
            memory[slot]["slideTimer"] = 0.25--segmentNum / (min / segmentSize)
            memory[slot]["invertSlide"] = false
        elseif memory[slot]["lastAmmoCount"] and memory[slot]["lastAmmoCount"] < segmentNum  then
            local min = memory[slot]["lastAmmoCount"]
            if min <= 0 then
                min = 1
            end
            memory[slot]["slideTimer"] = 0.25--segmentNum / (min / segmentSize)
            memory[slot]["invertSlide"] = true
        end

        if memory[slot]["slideTimer"] > 0 then
            local diff = memory[slot]["lastAmmoCount"] - segmentNum
            slideTimer = 1 * memory[slot]["slideTimer"] --util.clamp(diff, 2.7, diff) * memory[slot]["slideTimer"]
            if memory[slot]["invertSlide"] then
                slideTimer = 1 * memory[slot]["slideTimer"]
            end
            memory[slot]["slideTimer"] = memory[slot]["slideTimer"] - (script.updateDt() * (2))
            if memory[slot]["slideTimer"] < 0 then
                memory[slot]["slideTimer"] = 0
            end
        end
        local highestSegmentNum = segmentNum
        while segmentNum > 0 do
            local staticPos = (ammoPos[1] + 0.45) + (segmentSize*(segmentNum))
            local slided = staticPos
            if renderConf["animateBar"] then
                --slided = (ammoPos[1] + (0.45 / (segmentSize/slideTimer))) + (segmentSize*(segmentNum))
                if memory[slot]["invertSlide"] then
                    if segmentNum == highestSegmentNum then
                        local math = (segmentSize*slideTimer)
                        slided = (staticPos + math)
                    else
                        slided = staticPos
                    end
                else
                    if segmentNum == highestSegmentNum then
                        local math = (segmentSize*slideTimer)
                        slided = (staticPos + math)
                        
                    else
                        slided = staticPos
                    end
                end
            end
            local drawable = {
                image = string.format("%s:?scalenearest=%s;1?multiply=FFFFFF%s%s", barText, segmentSize, opacity[1], opacity[2]),
                position = {
                    util.clamp(slided, staticPos, slided),
                    ammoPos[2]
                },
                color = {255,255,255},
                fullbright = true,
                rotation = 0
            }
            if config["sideLeaning"] == "left" then
                drawable["position"][1] = (ammoPos[1] - 0.45) - (segmentSize*segmentNum)
            end
            if RGB then
                drawable["image"] = string.format("%s:?scalenearest=%s;1?hueshift=%s?multiply=FFFFFF%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, opacity[1], opacity[2])
            end
            if string.find(barText, ":") then
                if RGB then
                    drawable["image"] = string.format("%s?scalenearest=%s;1?hueshift=%s?multiply=FFFFFF%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, opacity[1], opacity[2])
                else
                    drawable["image"] = string.format("%s?scalenearest=%s;1?multiply=FFFFFF%s%s", barText, segmentSize, opacity[1], opacity[2])
                end
            end
            if not starExtensions or not config["starExtensions"]["useUiAnimator"] then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            elseif not starExtensions then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            elseif config["starExtensions"]["posAnchor"] == "player" then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            else
                local drawX = drawable["position"][1]
                local drawY = drawable["position"][2]
                local anchor = config["starExtensions"]["posAnchor"]
                -- default is bottomLeft
                drawY = drawable["position"][2] + 8
                if anchor == "bottomRight" then
                    drawX = drawable["position"][1] + windowSize[1]
                    drawY = drawable["position"][2] + 8
                elseif anchor == "topRight" then
                    drawX = drawable["position"][1] + windowSize[1]
                    drawY = drawable["position"][2] + windowSize[2]
                elseif anchor == "middleTop" then
                    drawX = drawable["position"][1] + (windowSize[1]/2)
                    drawY = drawable["position"][2] + windowSize[2]
                elseif anchor == "center" then
                    drawX = drawable["position"][1] + (windowSize[1]/2)
                    drawY = drawable["position"][2] + (windowSize[2]/2) + 2
                elseif anchor == "middleBottom" then
                    drawX = drawable["position"][1] + (windowSize[1]/2)
                    drawY = drawable["position"][2] + 8
                elseif anchor == "middleRight" then
                    drawX = drawable["position"][1] + windowSize[1]
                    drawY = drawable["position"][2] + (windowSize[2]/2) + 2
                elseif anchor == "middleLeft" then
                    drawY = drawable["position"][2] + (windowSize[2]/2) + 2
                elseif anchor == "topLeft" then
                    drawY = drawable["position"][2] + windowSize[2]
                end

                interface.drawDrawable(drawable, {((posOffset[1] + 1) + drawX) * posMultiply, (posOffset[2] + drawY) * posMultiply}, 2, {255,255,255})
            end
            segmentNum = segmentNum - 1
        end
    end
    
    local drawable = {
        image = string.format("%s:?multiply=FFFFFF%s%s", ammoText, opacity[1], opacity[2]),
        position = ammoPos,
        color = {255,255,255},
        fullbright = true,
        rotation = ((math.pi/180) * Rotate)
    }
    if string.find(ammoText, ":") then
        drawable["image"] = string.format("%s?multiply=FFFFFF%s%s", ammoText, opacity[1], opacity[2])
    end
    if not starExtensions or not config["starExtensions"]["useUiAnimator"] then
        localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    elseif not starExtensions then
        localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    elseif config["starExtensions"]["posAnchor"] == "player" then
        localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    else
        local drawX = drawable["position"][1]
        local drawY = drawable["position"][2]
        local anchor = config["starExtensions"]["posAnchor"]
        -- default is bottomLeft
        drawY = drawable["position"][2] + 8
        if anchor == "bottomRight" then
            drawX = drawable["position"][1] + windowSize[1]
            drawY = drawable["position"][2] + 8
        elseif anchor == "topRight" then
            drawX = drawable["position"][1] + windowSize[1]
            drawY = drawable["position"][2] + windowSize[2]
        elseif anchor == "middleTop" then
            drawX = drawable["position"][1] + (windowSize[1]/2)
            drawY = drawable["position"][2] + windowSize[2]
        elseif anchor == "center" then
            drawX = drawable["position"][1] + (windowSize[1]/2)
            drawY = drawable["position"][2] + (windowSize[2]/2) + 2
        elseif anchor == "middleBottom" then
            drawX = drawable["position"][1] + (windowSize[1]/2)
            drawY = drawable["position"][2] + 8
        elseif anchor == "middleRight" then
            drawX = drawable["position"][1] + windowSize[1]
            drawY = drawable["position"][2] + (windowSize[2]/2) + 2
        elseif anchor == "middleLeft" then
            drawY = drawable["position"][2] + (windowSize[2]/2) + 2
        elseif anchor == "topLeft" then
            drawY = drawable["position"][2] + windowSize[2]
        end


        interface.drawDrawable(drawable, {((posOffset[1] + 1) + drawX) * posMultiply, (posOffset[2] + drawY) * posMultiply}, 2, {255,255,255})
    end

    if count > 20 and not numberOnly then
        outpostSignNumber(count, ammoPos, opacity, segmentSize)
        --particleNumber(textOpacity, count, ammoPos, segmentSize)
    end
    
    memory[slot]["lastAmmoCount"] = util.clamp(count, 0, 20)
end

function outpostSignNumber(count, ammoPos, opacity, segmentSize, complete, numberOnly)
    local number = math.ceil(count-20)
    if complete then
        number = math.ceil(count)
    end
    local numberTable = {}
    
    local digit =    number % 10
    number = number // 10
    local ten =      number % 10
    number = number // 10
    local hundred =  number % 10
    number = number // 10
    local thousand = number % 10

    local numberOffset = 0
    local segmentOffset = (segmentSize*21.5)
    if numberOnly then
        segmentOffset = 1
    end
    local drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?multiply=FFFFFF%s%s?brightness=100", thousand, opacity[1], opacity[2]),
        position = {
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*pixel),
            ammoPos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 8
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?multiply=FFFFFF%s%s?brightness=100", hundred, opacity[1], opacity[2]),
        position = {
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*pixel),
            ammoPos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 16
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?multiply=FFFFFF%s%s?brightness=100", ten, opacity[1], opacity[2]),
        position = {
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*pixel),
            ammoPos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 24
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?multiply=FFFFFF%s%s?brightness=100", digit, opacity[1], opacity[2]),
        position = {
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*pixel),
            ammoPos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
end

function particleNumber(textOpacity, count, ammoPos, segmentSize)
    local particle = {
        type = "text",
        size = 0.5,
        color = {0, 255, 0, textOpacity},
        fade = 0.0,
        initialVelocity = {0, 0.0},
        finalVelocity = {0, 0.0},
        approach = {0, 0},
        timeToLive = 0.015,
        layer = "front",
        string = string.format("x%s", count-20),
        variance = {
        }
    }
    local ceiltest = (math.ceil(count-20) == count-20)
    if not ceiltest then
        particle["string"] = string.format("x~%s", math.ceil(count-20))
    end
    local playerPos = world.entityPosition(player.id())
    localAnimator.spawnParticle(particle,{
        playerPos[1] + (ammoPos[1] + 0.45) + (segmentSize*23),
        playerPos[2] + ammoPos[2]
    })
end