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
local d8Weaponry_var = {
    config = "replaceMe",
    pixel = 0.125,
    time = 0,
    memory = {
    },
    weapon = {
        count = 1,
        name = "don't think too much about why there a descriptor here",
        parameters = {
        }
    },
    d8WeaponryDrawableList = {},
    weapParam = "replaceMe",
    weapConf = "replaceMe",
    primaryConf = {},
    secondaryConf = {},
    initTimer = 2,
    opacityMax = {8,5},
    opacity = {0,0},
    textOpacity = 0,
    barOffset = 0,
    prevPrimary = {
        count = 1,
        name = "don't think too much about why there a descriptor here",
        parameters = {
        }
    },
    prevSecondary = {
        count = 1,
        name = "don't think too much about why there a descriptor here",
        parameters = {
        }
    }
}

function init()
    vanillaInit()
    d8Weaponry_var.config = root.assetJson("/D8Weaponry.config")
    if d8Weaponry_var.config["opacityMax"] then
        d8Weaponry_var.opacityMax = d8Weaponry_var.config["opacityMax"]
    end
end

function update(dt)
    vanillaUpdate(dt)
    if d8Weaponry_var.config["customAmmoRenderer"] then
        if d8Weaponry_var.initTimer > 0 then
            d8Weaponry_var.initTimer = d8Weaponry_var.initTimer - 1
        else
            if player.primaryHandItem() or player.altHandItem() then
                local primary = player.primaryHandItem()
                local secondary = player.altHandItem()
                local same = true
                local concatedParam = d8weaponry_weaponAnalisis(primary, secondary)
                d8Weaponry_var.weapon["parameters"] = concatedParam
            end
            local renderIndex = 0
            --sb.logInfo("%s", d8WeaponryUtils)
            --if d8WeaponryUtils.drawableList then
            --    for pos, drawable in ipairs(d8WeaponryUtils.drawableList) do
            --        d8weaponry_drawableUpdate(drawable, pos)
            --    end
            --end
            if pcall(function()
                    local result = type(d8Weaponry_var.weapon["parameters"]["d8Weaponry"])
                    if result == "table" and (player.primaryHandItem() or player.altHandItem()) then
                        return result 
                    else error()
                    end 
                end) then
                if d8Weaponry_var.textOpacity < 185 then
                    d8Weaponry_var.textOpacity = d8Weaponry_var.textOpacity + 14
                    if d8Weaponry_var.textOpacity > 185 then
                        d8Weaponry_var.textOpacity = 185
                    end
                end
                d8Weaponry_var.barOffset = util.clamp(d8Weaponry_var.barOffset + (4*dt), 2, 3)
                if d8Weaponry_var.opacity[1] < d8Weaponry_var.opacityMax[1] or d8Weaponry_var.opacity[2] < d8Weaponry_var.opacityMax[2] then
                    if d8Weaponry_var.opacity[2] == 9 then
                        d8Weaponry_var.opacity[1] = d8Weaponry_var.opacity[1] + 4
                        d8Weaponry_var.opacity[2] = 0
                    else
                        d8Weaponry_var.opacity[2] = d8Weaponry_var.opacity[2] + 4
                    end
                    if d8Weaponry_var.opacity[1] > d8Weaponry_var.opacityMax[1] then
                        d8Weaponry_var.opacity[1] = d8Weaponry_var.opacityMax[1]
                    end
                    if (d8Weaponry_var.opacity[2] > d8Weaponry_var.opacityMax[2] and d8Weaponry_var.opacity[1] == d8Weaponry_var.opacityMax[1]) or d8Weaponry_var.opacity[2] > 9 then
                        d8Weaponry_var.opacity[2] = d8Weaponry_var.opacityMax[2]
                    end
                end

                d8Weaponry_var.weapParam = d8Weaponry_var.weapon["parameters"]
                d8Weaponry_var.weapConf = d8Weaponry_var.weapon["parameters"]["d8Weaponry"]
                for index, value in ipairs(d8Weaponry_var.weapConf) do
                    local max = value[value["ammoMaxName"]]
                    local count = value[value["ammoCountName"]]
                    if not d8Weaponry_var.memory[index] then
                        d8Weaponry_var.memory[index] = {}
                        d8Weaponry_var.memory[index]["ammoText"] = "/assetmissing.png"
                        d8Weaponry_var.memory[index]["barText"] = "/assetmissing.png"
                    end
                    d8weaponry_renderBar(0, -d8Weaponry_var.barOffset-(1*(renderIndex)), max, count, index)
                    renderIndex = renderIndex + 1
                end
                
                d8Weaponry_var.time = ( (-175) + (d8Weaponry_var.time + (12*(dt))) ) % 175
            else
                d8Weaponry_var.time = 0
                if d8Weaponry_var.textOpacity > 0 then
                    d8Weaponry_var.textOpacity = d8Weaponry_var.textOpacity - 9
                    if d8Weaponry_var.textOpacity < 0 then
                        d8Weaponry_var.textOpacity = 0
                    end
                end
                d8Weaponry_var.barOffset = util.clamp(d8Weaponry_var.barOffset - (1.5*dt), 2, 4)
                if d8Weaponry_var.opacity[1] > 0 or d8Weaponry_var.opacity[2] > 0 then
                    if d8Weaponry_var.opacity[2] == 0 then
                        d8Weaponry_var.opacity[1] = d8Weaponry_var.opacity[1] - 2
                        d8Weaponry_var.opacity[2] = 9
                    else
                        d8Weaponry_var.opacity[2] = d8Weaponry_var.opacity[2] - 2
                    end
                    if d8Weaponry_var.opacity[1] < 0 then
                        d8Weaponry_var.opacity[1] = 0
                    end
                    if d8Weaponry_var.opacity[2] < 0 then
                        d8Weaponry_var.opacity[2] = 0
                    end
                    
                    for index, value in ipairs(d8Weaponry_var.weapConf) do
                        local max = value[value["ammoMaxName"]]
                        local count = value[value["ammoCountName"]]
                        if not d8Weaponry_var.memory[index] then
                            d8Weaponry_var.memory[index] = {}
                            d8Weaponry_var.memory[index]["ammoText"] = "/assetmissing.png"
                            d8Weaponry_var.memory[index]["barText"] = "/assetmissing.png"
                        end
                        d8weaponry_renderBar(0,  -d8Weaponry_var.barOffset-(1*(renderIndex)), max, count, index)
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

function d8weaponry_drawableUpdate(drawable, pos)--Way less annoing to handles effect/stat script in the renderer instead of their own scripts... maybe it not a good idea
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
                table.remove(d8Weaponry_var.weapon["parameters"]["d8Weaponry"], index)
            end
        end
        table.insert(d8Weaponry_var.weapon["parameters"]["d8Weaponry"], pos, pendingRendering)
    elseif propertyName and isBar then

    end

end

function d8weaponry_weaponAnalisis(primary, secondary)
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
                local cost = (pendingRendering["cost"] or 1.0)
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
                local cost = (pendingRendering["cost"] or 1.0)
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
                local cost = (pendingRendering["cost"] or 1.0)
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
                local cost = (pendingRendering["cost"] or 1.0)
                pendingRendering[pendingRendering["ammoMaxName"]] = (status.resourceMax(name or value["ammoMaxName"]) / cost)
                pendingRendering[pendingRendering["ammoCountName"]] = (status.resource(name or value["ammoCountName"]) / cost)
            end
            table.insert(concatedParam["d8Weaponry"], pendingRendering)
            currentIndex = (currentIndex + 1)
        end
    end
    
    return concatedParam
end

function d8weaponry_renderBar(barX, barY, amountMax, count, slot, ammoText, barText, RGB)
    local renderConf = {}
    local useSegmentedBar = false
    if not amountMax then
        amountMax = 20
    end
    if not count then
        count = 0
    end
    if d8Weaponry_var.weapon["parameters"]["d8Weaponry"] and type(d8Weaponry_var.weapon["parameters"]["d8Weaponry"]) == "table"  then
        renderConf = d8Weaponry_var.weapon["parameters"]["d8Weaponry"][slot]
        if renderConf then
            if renderConf["ammoText"] then
                d8Weaponry_var.memory[slot]["ammoText"] = renderConf["ammoText"]
                ammoText = renderConf["ammoText"]
            end
            if renderConf["barText"] then
                d8Weaponry_var.memory[slot]["barText"] = renderConf["barText"]
                barText = renderConf["barText"]
            end
            if renderConf["RGB"] then
                d8Weaponry_var.memory[slot]["RGB"] = renderConf["RGB"]
                RGB = renderConf["RGB"]
            end
            if renderConf["Rotate"] then
                d8Weaponry_var.memory[slot]["Rotate"] = renderConf["Rotate"]
                Rotate = renderConf["Rotate"]
            end
            if renderConf["invertRender"] then
                count = amountMax - count
            end
            if renderConf["useSegmentedBar"] then
                useSegmentedBar = renderConf["useSegmentedBar"]
            end
        else
            return
        end
    end
    local numberOnly = d8Weaponry_var.config["numberOnly"]
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
        local amountMax = 1 + (1.34 / d8Weaponry_var.pixel)
        ammoPos[1] = barX - ((util.clamp(amountMax, 1, 20) - (util.clamp(amountMax, 1, 20)/2)) * (sizeNumberThing/4))
    end
    local windowSize
    local posMultiply = 14
    if starExtensions then
        windowSize = window.size()
        windowSize = {windowSize[1] / (posMultiply * 1.015), windowSize[2] / (posMultiply / 1.07)}
    end
    if d8Weaponry_var.config["sideLeaning"] ~= "center" then
        ammoPos[1] = barX
    end
    local ammoText = d8Weaponry_var.memory[slot]["ammoText"]
    local barText = d8Weaponry_var.memory[slot]["barText"]
    local RGB = d8Weaponry_var.memory[slot]["RGB"]
    local Rotate = d8Weaponry_var.memory[slot]["Rotate"] or 0
    local posOffset = d8Weaponry_var.config["posOffset"]
    ammoPos[1] = ammoPos[1] + posOffset[1]
    ammoPos[2] = ammoPos[2] + posOffset[2]

    local segmentSize = (1/(amountMax/(amountMax/sizeNumberThing)))
    if numberOnly then
        d8weaponry_outpostSignNumber(count, ammoPos, d8Weaponry_var.opacity, 0.5, true, numberOnly)
    else
        local segmentNum = util.clamp(math.ceil(amountMax), 0, 20)
        
        while segmentNum > 0 do
            local drawable = {
                image = string.format("%s:?scalenearest=%s;1?multiply=7F7F7F%s%s", barText, segmentSize, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2]),
                position = {
                    (ammoPos[1] + 0.45) + (segmentSize*segmentNum),
                    ammoPos[2]
                },
                color = {255,255,255},
                fullbright = true,
                rotation = 0
            }
            if d8Weaponry_var.config["sideLeaning"] == "left" then
                drawable["position"][1] = (ammoPos[1] - 0.45) - (segmentSize*segmentNum)
            end
            if RGB then
                drawable["image"] = string.format("%s:?scalenearest=%s;1?hueshift=%s?multiply=7F7F7F%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2])
            end
            if string.find(barText, ":") then
                if RGB then
                    drawable["image"] = string.format("%s?scalenearest=%s;1?hueshift=%s?multiply=7F7F7F%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2])
                else
                    drawable["image"] = string.format("%s?scalenearest=%s;1?multiply=7F7F7F%s%s", barText, segmentSize, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2])
                end
            end
            if not starExtensions or not d8Weaponry_var.config["starExtensions"]["useUiAnimator"] then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            elseif not starExtensions then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            elseif d8Weaponry_var.config["starExtensions"]["posAnchor"] == "player" then
                localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            else
                local drawX = drawable["position"][1]
                local drawY = drawable["position"][2]
                local anchor = d8Weaponry_var.config["starExtensions"]["posAnchor"]
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
        if useSegmentedBar then
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
                    image = string.format("%s:?scalenearest=%s;1?multiply=FFFFFF%s%s", barText, segmentSize, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2]),
                    position = {
                        util.clamp(slided, staticPos, slided),
                        ammoPos[2]
                    },
                    color = {255,255,255},
                    fullbright = true,
                    rotation = 0
                }
                if d8Weaponry_var.config["sideLeaning"] == "left" then
                    drawable["position"][1] = (ammoPos[1] - 0.45) - (segmentSize*segmentNum)
                end
                if RGB then
                    drawable["image"] = string.format("%s:?scalenearest=%s;1?hueshift=%s?multiply=FFFFFF%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2])
                end
                if string.find(barText, ":") then
                    if RGB then
                        drawable["image"] = string.format("%s?scalenearest=%s;1?hueshift=%s?multiply=FFFFFF%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2])
                    else
                        drawable["image"] = string.format("%s?scalenearest=%s;1?multiply=FFFFFF%s%s", barText, segmentSize, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2])
                    end
                end
                if not starExtensions or not d8Weaponry_var.config["starExtensions"]["useUiAnimator"] then
                    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
                elseif not starExtensions then
                    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
                elseif d8Weaponry_var.config["starExtensions"]["posAnchor"] == "player" then
                    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
                else
                    local drawX = drawable["position"][1]
                    local drawY = drawable["position"][2]
                    local anchor = d8Weaponry_var.config["starExtensions"]["posAnchor"]
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
        else
            local size = util.clamp(math.ceil(amountMax), 0, 20)*4
            local cull = (util.clamp(math.ceil(count), 0, 20))*4
            local lastCullPercent = memory[slot]["lastCullPercent"] or cull
            if lastCullPercent ~= cull then
                local multiply = lastCullPercent

                if lastCullPercent == 0 then
                    multiply = 1
                end

                if lastCullPercent > cull then
                    lastCullPercent = util.clamp(lastCullPercent - ( (math.ceil(4 * (lastCullPercent))) * script.updateDt()), 0.1, size)
                else
                    lastCullPercent = util.clamp(lastCullPercent + ( (math.ceil(4 * (lastCullPercent))) * script.updateDt()), 0.1, size)
                end
            end
            local staticPos = ((ammoPos[1] + 0.2) + (segmentSize))
            local slided = staticPos
            local drawable = {
                image = string.format("%s:?crop;0;0;1;7?scalenearest=%s;1?multiply=FFFFFF%s%s?crop;0;0;%s;7", barText, size, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2], lastCullPercent),
                position = {
                    staticPos,
                    ammoPos[2]-0.4
                },
                color = {255,255,255},
                fullbright = true,
                centered = false,
                rotation = 0
            }
            if d8Weaponry_var.config["sideLeaning"] == "left" then
                drawable["position"][1] = (ammoPos[1] - 0.2) - (segmentSize)
            end
            if RGB then
                drawable["image"] = string.format("%s:?crop;0;0;1;7?scalenearest=%s;1?hueshift=%s?multiply=FFFFFF%s%s?crop;0;0;%s;7", barText, size, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2], lastCullPercent)
            end
            if string.find(barText, ":") then
                if RGB then
                    drawable["image"] = string.format("%s?scalenearest=%s;1?hueshift=%s?multiply=FFFFFF%s%s", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2])
                else
                    drawable["image"] = string.format("%s?crop;0;0;1;7?scalenearest=%s;1?multiply=FFFFFF%s%s?crop;0;0;%s;7", barText, size, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2], lastCullPercent)
                end
            end
            localAnimator.addDrawable(drawable, "ForegroundOverlay-1")

            if lastCullPercent <= (cull + 0.2) and lastCullPercent >= (cull - 0.2) then
                memory[slot]["lastCullPercent"] = cull
            else
                memory[slot]["lastCullPercent"] = lastCullPercent
            end
        end
        
    end
    
    local drawable = {
        image = string.format("%s:?multiply=FFFFFF%s%s", ammoText, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2]),
        position = ammoPos,
        color = {255,255,255},
        fullbright = true,
        rotation = ((math.pi/180) * Rotate)
    }
    if string.find(ammoText, ":") then
        drawable["image"] = string.format("%s?multiply=FFFFFF%s%s", ammoText, d8Weaponry_var.opacity[1], d8Weaponry_var.opacity[2])
    end
    if not starExtensions or not d8Weaponry_var.config["starExtensions"]["useUiAnimator"] then
        localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    elseif not starExtensions then
        localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    elseif d8Weaponry_var.config["starExtensions"]["posAnchor"] == "player" then
        localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    else
        local drawX = drawable["position"][1]
        local drawY = drawable["position"][2]
        local anchor = d8Weaponry_var.config["starExtensions"]["posAnchor"]
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
        d8weaponry_outpostSignNumber(count, ammoPos, d8Weaponry_var.opacity, segmentSize)
        --d8weaponry_particleNumber(textOpacity, count, ammoPos, segmentSize)
    end
    
    d8Weaponry_var.memory[slot]["lastAmmoCount"] = util.clamp(count, 0, 20)
end

function d8weaponry_outpostSignNumber(count, ammoPos, opacity, segmentSize, complete, numberOnly)
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
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*d8Weaponry_var.pixel),
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
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*d8Weaponry_var.pixel),
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
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*d8Weaponry_var.pixel),
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
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*d8Weaponry_var.pixel),
            ammoPos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
end

function d8weaponry_particleNumber(textOpacity, count, ammoPos, segmentSize)
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