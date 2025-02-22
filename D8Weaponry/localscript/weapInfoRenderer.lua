-- This is rendered localy and not on other client screen's 
-- information about the selected weapon if compatible (ammo, ability charge, ect)
require "/scripts/util.lua"
require "/scripts/vec2.lua"
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
end--For any external Drawable, draw before those of the weapons...
local d8Weaponry_var = {
    config = {},
    pixel = 0.125,
    time = 0,
    memoryClearTimer = 0,
    memory = {
    },
    weapon = {
        count = 1,
        name = "don't think too much about why there a descriptor here",
        parameters = {
        }
    },
    d8WeaponryDrawableList = {},
    weapParam = {},
    weapConf = {},
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
    if xsb then require "/shared/xStarboundPatch/luaLinking.lua" end

    d8WeaponryUtils[player.uniqueId()] = {}
    d8WeaponryUtils[player.uniqueId()]["drawableList"] = {}
    d8Weaponry_var.config = root.assetJson("/D8Weaponry.config")
    if player.getProperty("d8Weap") then
        d8Weaponry_var.config = util.mergeTable(d8Weaponry_var.config, player.getProperty("d8Weap")["renderCfg"] or {})
    else
        cfg = {}
        cfg["renderCfg"] = d8Weaponry_var.config
        cfg["info"] = nil
        player.setProperty("d8Weap", cfg)
    end
    message.setHandler("d8Weaponry_updaterenderCfg", function(_, isLocal)
        if player.getProperty("d8Weap") then
            d8Weaponry_var.config = util.mergeTable(d8Weaponry_var.config, player.getProperty("d8Weap")["renderCfg"])
        end
    end)

    if d8Weaponry_var.config["opacityMax"] then
        d8Weaponry_var.opacityMax = d8Weaponry_var.config["opacityMax"]
        d8Weaponry_var.opacity = d8Weaponry_var.config["opacityMax"]
    end
    --sb.logInfo("shared %s", shared)
    d8Weaponry_var.config["prevPlayerVelocity"] = world.entityVelocity(player.id())
end

function update(dt)
    vanillaUpdate(dt)
    if _ENV["xCallbackCheckRequest"] then xCallbackCheckRequest("d8WeapUtils:callback") end
    d8Weaponry_var.config["nextPlayerVelocity"] = world.entityVelocity(player.id())

    d8Weaponry_var.config["playerVelocity"] = {
        -( (d8Weaponry_var.config["nextPlayerVelocity"][1] - d8Weaponry_var.config["nextPlayerVelocity"][1]) / dt),
        -( (d8Weaponry_var.config["nextPlayerVelocity"][2] - d8Weaponry_var.config["nextPlayerVelocity"][2]) / dt)
    }

    d8Weaponry_var.config["prevPlayerVelocity"] = world.entityVelocity(player.id())
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
            d8Weaponry_var.renderIndex = 0
            d8Weaponry_var.rendereredAmount = 0
            if d8WeaponryUtils[player.uniqueId()]["drawableList"] then
                for name, drawable in pairs(d8WeaponryUtils[player.uniqueId()]["drawableList"]) do
                    d8weaponry_drawableUpdate(drawable, name, d8Weaponry_var.renderIndex)
                end
            end
            if pcall(function()
                    local result = type(d8Weaponry_var.weapon["parameters"]["d8Weaponry"])
                    if result == "table" and (player.primaryHandItem() or player.altHandItem()) then
                        return result 
                    else error()
                    end 
                end) then
                d8Weaponry_var.memoryClearTimer = 1
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
                    local size = d8Weaponry_var.barOffset + value.size[2]
                    
					d8weaponry_renderBar(0,  -size-(1*(d8Weaponry_var.renderIndex)), max, count, index)
                    d8Weaponry_var.renderIndex = d8Weaponry_var.rendereredAmount + 1
                    d8Weaponry_var.rendereredAmount = d8Weaponry_var.rendereredAmount + 1
                end
                
                d8Weaponry_var.time = ( (-175) + (d8Weaponry_var.time + (12*(dt))) ) % 175
            else
                d8Weaponry_var.time = 0
                if d8Weaponry_var.opacity > 0 then
                    for index, value in ipairs(d8Weaponry_var.weapConf) do
                        local max = value[value["ammoMaxName"]]
                        local count = value[value["ammoCountName"]]
                        if not d8Weaponry_var.memory[index] then
                            d8Weaponry_var.memory[index] = {}
                            d8Weaponry_var.memory[index]["ammoText"] = "/assetmissing.png"
                            d8Weaponry_var.memory[index]["barText"] = "/assetmissing.png"
                        end
                        if type(value) == "table" then
                            local size = d8Weaponry_var.barOffset + value.size[2]
                            
                            d8weaponry_renderBar(0,  -size-(1*(d8Weaponry_var.rendereredAmount)), max, count, index)
                            d8Weaponry_var.rendereredAmount = d8Weaponry_var.rendereredAmount + 1
                        end
                    end
                    if not (player.primaryHandItem() or player.altHandItem()) then
                        if d8Weaponry_var.memoryClearTimer < 0 and type(d8Weaponry_var.weapConf) == "table" then
                            d8weaponry_clearMemory()
                        else
                            d8Weaponry_var.memoryClearTimer = d8Weaponry_var.memoryClearTimer - dt
                        end
                    end
                else
                    d8weaponry_clearMemory()
                end
            end
            if d8Weaponry_var.renderIndex > 0 then
                if d8Weaponry_var.textOpacity < 185 then
                    d8Weaponry_var.textOpacity = d8Weaponry_var.textOpacity + 14
                    if d8Weaponry_var.textOpacity > 185 then
                        d8Weaponry_var.textOpacity = 185
                    end
                end
                d8Weaponry_var.barOffset = util.clamp(d8Weaponry_var.barOffset + (4*dt), 2, 3)
                if d8Weaponry_var.opacity < d8Weaponry_var.opacityMax then
                    d8Weaponry_var.opacity = d8Weaponry_var.opacity + 4
                    if d8Weaponry_var.opacity > d8Weaponry_var.opacityMax then
                        d8Weaponry_var.opacity = d8Weaponry_var.opacityMax
                    end
                end
            else
                if d8Weaponry_var.textOpacity > 0 then
                    d8Weaponry_var.textOpacity = d8Weaponry_var.textOpacity - 9
                    if d8Weaponry_var.textOpacity < 0 then
                        d8Weaponry_var.textOpacity = 0
                    end
                end
                if d8Weaponry_var.opacity ~= 0 then
                    d8Weaponry_var.opacity = d8Weaponry_var.opacity - 2
                end
                if d8Weaponry_var.opacity < 0 then
                    d8Weaponry_var.opacity = 0
                end
                d8Weaponry_var.barOffset = util.clamp(d8Weaponry_var.barOffset - (1.5*dt), 2, 4)
            end
        end
    end
end

function d8weaponry_clearMemory() -- Cleaning Scripts Memory of weapons parameters
    d8Weaponry_var.weapon["parameters"]["d8Weaponry"] = {}
    d8Weaponry_var.memory = {}
    d8Weaponry_var.weapConf = {}
end

function teleportOut()
    vanillaTeleportOut()
end

function uninit()
    vanillaUninit()

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
            if value.isBar then
                local pendingRendering = copy(value)
                local name = value.ressourceName
                pendingRendering.isBar = true
                pendingRendering.size = {0,0}
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
            end
            currentIndex = (currentIndex + 1)
        end
    elseif not validprimary and validsecondary then
        concatedParam["d8Weaponry"] = {}
        for index, value in ipairs(secondaryConf["parameters"]["d8Weaponry"]) do
            if value.isBar then
                local pendingRendering = copy(value)
                local name = value.ressourceName
                pendingRendering.isBar = true
                pendingRendering.size = {0,0}
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
            end
            currentIndex = (currentIndex + 1)
        end
    elseif validprimary and validsecondary then
        -- preparation
        concatedParam["d8Weaponry"] = {}
        --concatedParam = oldConcatParam(concatedParam)
        for index, value in ipairs(primaryConf["parameters"]["d8Weaponry"]) do
            if value.isBar then
                local pendingRendering = copy(value)
                local name = value.ressourceName
                pendingRendering.isBar = true
                pendingRendering.size = {0,0}
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
            end
            currentIndex = (currentIndex + 1)
        end
        for index, value in ipairs(secondaryConf["parameters"]["d8Weaponry"]) do
            if value.isBar then
                local pendingRendering = copy(value)
                local name = value.ressourceName
                pendingRendering.isBar = true
                pendingRendering.size = {0,0}
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
            end
            currentIndex = (currentIndex + 1)
        end
    end
    
    return concatedParam
end

function d8weaponry_renderBar(barX, barY, amountMax, count, slot, ammoText, barText, RGB)
    local playerVelocity = d8Weaponry_var.config["playerVelocity"]
    local renderConf = {}
    local useSegmentedBar = true
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
    --numberOnly = true -- Setting to true until i fix the issue's with the segmented bar
    
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
                image = string.format("%s:?scalenearest=%s;1?multiply=7F7F7F", barText, segmentSize),
                position = {
                    (ammoPos[1] + 0.45) + (segmentSize*segmentNum),
                    ammoPos[2]
                },
                color = {255,255,255, d8Weaponry_var.opacity},
                fullbright = true,
                rotation = 0
            }
            if d8Weaponry_var.config["sideLeaning"] == "left" then
                drawable["position"][1] = (ammoPos[1] - 0.45) - (segmentSize*segmentNum)
            end
            if RGB then
                drawable["image"] = string.format("%s:?scalenearest=%s;1?hueshift=%s?multiply=7F7F7F", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360)
            end
            if string.find(barText, ":") then
                if RGB then
                    drawable["image"] = string.format("%s?scalenearest=%s;1?hueshift=%s?multiply=7F7F7F", barText, segmentSize, ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360)
                else
                    drawable["image"] = string.format("%s?scalenearest=%s;1?multiply=7F7F7F", barText, segmentSize)
                end
            end
            drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
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
        d8Weaponry_var.memory[slot]["slideTimer"] = d8Weaponry_var.memory[slot]["slideTimer"] or 0
        d8Weaponry_var.memory[slot]["invertSlide"] = d8Weaponry_var.memory[slot]["invertSlide"] or false
        local slideTimer = 0
        if d8Weaponry_var.memory[slot]["lastAmmoCount"] and d8Weaponry_var.memory[slot]["lastAmmoCount"] > segmentNum then
            local min = d8Weaponry_var.memory[slot]["lastAmmoCount"]
            if min <= 0 then
                min = 1
            end
            d8Weaponry_var.memory[slot]["slideTimer"] = 0.25--segmentNum / (min / segmentSize)
            d8Weaponry_var.memory[slot]["invertSlide"] = false
        elseif d8Weaponry_var.memory[slot]["lastAmmoCount"] and d8Weaponry_var.memory[slot]["lastAmmoCount"] < segmentNum  then
            local min = d8Weaponry_var.memory[slot]["lastAmmoCount"]
            if min <= 0 then
                min = 1
            end
            d8Weaponry_var.memory[slot]["slideTimer"] = 0.25--segmentNum / (min / segmentSize)
            d8Weaponry_var.memory[slot]["invertSlide"] = true
        end

        if d8Weaponry_var.memory[slot]["slideTimer"] > 0 then
            local diff = d8Weaponry_var.memory[slot]["lastAmmoCount"] - segmentNum
            slideTimer = 1 * d8Weaponry_var.memory[slot]["slideTimer"] --util.clamp(diff, 2.7, diff) * d8Weaponry_var.memory[slot]["slideTimer"]
            if d8Weaponry_var.memory[slot]["invertSlide"] then
                slideTimer = 1 * d8Weaponry_var.memory[slot]["slideTimer"]
            end
            d8Weaponry_var.memory[slot]["slideTimer"] = d8Weaponry_var.memory[slot]["slideTimer"] - (script.updateDt() * (2))
            if d8Weaponry_var.memory[slot]["slideTimer"] < 0 then
                d8Weaponry_var.memory[slot]["slideTimer"] = 0
            end
        end
        local highestSegmentNum = segmentNum
        if useSegmentedBar then
            while segmentNum > 0 do
                local staticPos = (ammoPos[1] + 0.45) + (segmentSize*(segmentNum))
                local slided = staticPos
                if renderConf["animateBar"] then
                    --slided = (ammoPos[1] + (0.45 / (segmentSize/slideTimer))) + (segmentSize*(segmentNum))
                    if d8Weaponry_var.memory[slot]["invertSlide"] then
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
                    image = string.format("%s:?scalenearest=%s;1", barText, segmentSize),
                    position = {
                        util.clamp(slided, staticPos, slided),
                        ammoPos[2]
                    },
                    color = {255,255,255, d8Weaponry_var.opacity},
                    fullbright = true,
                    rotation = 0
                }
                if d8Weaponry_var.config["sideLeaning"] == "left" then
                    drawable["position"][1] = (ammoPos[1] - 0.45) - (segmentSize*segmentNum)
                end
                if RGB then
                    drawable["image"] = drawable["image"] .. string.format("?hueshift=%s", ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360)
                end
                drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
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
            local lastCullPercent = d8Weaponry_var.memory[slot]["lastCullPercent"] or cull
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
                image = string.format("%s?crop;0;0;1;7?scalenearest=%s;1?crop;0;0;%s;7", barText, size, lastCullPercent),
                position = {
                    staticPos,
                    ammoPos[2]-0.4
                },
                color = {255,255,255, d8Weaponry_var.opacity},
                fullbright = true,
                centered = false,
                rotation = 0
            }
            if d8Weaponry_var.config["sideLeaning"] == "left" then
                drawable["position"][1] = (ammoPos[1] - 0.2) - (segmentSize)
            end
            if RGB then
                drawable["image"] = drawable["image"] .. string.format("?hueshift=%s", ((math.ceil(time)-((segmentNum+time)*(360/amountMax))))%360)
            end
            drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
            localAnimator.addDrawable(drawable, "ForegroundOverlay-1")

            if lastCullPercent <= (cull + 0.2) and lastCullPercent >= (cull - 0.2) then
                d8Weaponry_var.memory[slot]["lastCullPercent"] = cull
            else
                d8Weaponry_var.memory[slot]["lastCullPercent"] = lastCullPercent
            end
        end
        
    end
    
    local drawable = {
        image = ammoText,
        position = ammoPos,
        color = {255,255,255, d8Weaponry_var.opacity},
        fullbright = true,
        rotation = ((math.pi/180) * Rotate)
    }
    drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
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
    end
    
    d8Weaponry_var.memory[slot]["lastAmmoCount"] = util.clamp(count, 0, 20)
end

function d8weaponry_outpostSignNumber(count, ammoPos, opacity, segmentSize, complete, numberOnly)
    local playerVelocity = d8Weaponry_var.config["playerVelocity"]
    local number = math.ceil(count-20)
    if complete then
        number = math.ceil(count)
    end
    
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
        image = string.format("/objects/outpost/number%s/icon.png:?brightness=100", thousand),
        position = {
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*d8Weaponry_var.pixel),
            ammoPos[2]
        },
        color = {255,255,255, d8Weaponry_var.opacity},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 8
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?brightness=100", hundred),
        position = {
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*d8Weaponry_var.pixel),
            ammoPos[2]
        },
        color = {255,255,255, d8Weaponry_var.opacity},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 16
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?brightness=100", ten),
        position = {
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*d8Weaponry_var.pixel),
            ammoPos[2]
        },
        color = {255,255,255, d8Weaponry_var.opacity},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 24
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?brightness=100", digit),
        position = {
            (ammoPos[1] + 0.45) + segmentOffset + (numberOffset*d8Weaponry_var.pixel),
            ammoPos[2]
        },
        color = {255,255,255, d8Weaponry_var.opacity},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
end

function d8weaponry_drawableUpdate(drawable, name, pos)--Way less annoing to handles effect/stat script in the renderer instead of their own scripts... maybe it not a good idea
    local playerVelocity = d8Weaponry_var.config["playerVelocity"]
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
    end
    if drawable.isBuilt then
        if drawable.keepPos then
            drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
            localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
            return 
        end
        local size = d8Weaponry_var.barOffset + drawable.size[2]
        drawable.position[2] = drawable.position[2] -size-(1*(d8Weaponry_var.renderIndex))
        drawable["position"] = vec2.sub(drawable["position"], playerVelocity)
        localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
        d8Weaponry_var.renderIndex = d8Weaponry_var.renderIndex + 1
        d8Weaponry_var.rendereredAmount = d8Weaponry_var.rendereredAmount + 1
    end
end

function xCallback(requestCfg)
    local drawable, Uuid = requestCfg.drawable, requestCfg.Uuid
    if requestCfg.callback == "send" then
        if d8WeaponryUtils.drawableList[drawable.name] then
            d8WeaponryUtils:update(drawable, Uuid)
        else
            d8WeaponryUtils:add(drawable, Uuid)
        end
    elseif requestCfg.callback == "remove" then
        d8WeaponryUtils:remove(drawable, Uuid)
    elseif requestCfg.callback == "updateCfg" then
        d8WeaponryUtils:updateCfg(Uuid)
    end
end

function d8WeaponryUtils:add(drawable, Uuid)
    if Uuid ~= player.uniqueId() then return end
    if type(drawable) ~= "table" then sb.logError("[d8WeaponryUtils:add] Following Drawable isn't a table\n"..sb.printJson(drawable, 1)) return end
    if not drawable.name then sb.logError("[d8WeaponryUtils:remove] Following Drawable lack a name"..sb.printJson(drawable, 1)) return end
    d8WeaponryUtils[player.uniqueId()]["drawableList"][drawable.name] = drawable
end

function d8WeaponryUtils:remove(drawable, Uuid)
    if Uuid ~= player.uniqueId() then return end
    if type(drawable) == "string" then drawable = {name = drawable} end
    if type(drawable) ~= "table" then sb.logError("[d8WeaponryUtils:remove] Following Drawable isn't a table\n"..sb.printJson(drawable, 1)) return end
    if not drawable.name then sb.logError("[d8WeaponryUtils:remove] Following Drawable lack a name"..sb.printJson(drawable, 1)) return end
    local newList = {}
    for name, drawable in pairs(d8WeaponryUtils[player.uniqueId()]["drawableList"]) do
        if name ~= drawable.name then
            newList[name] = drawable
        end
    end
    d8WeaponryUtils[player.uniqueId()]["drawableList"] = newList
end

function d8WeaponryUtils:update(drawable, Uuid)
    if Uuid ~= player.uniqueId() then return end
    self:remove(drawable)
    self:add(drawable)
end

function d8WeaponryUtils:updateCfg(Uuid)
    if player.getProperty("d8Weap") and player.uniqueId() == Uuid then
        d8Weaponry_var.config = util.mergeTable(d8Weaponry_var.config, player.getProperty("d8Weap")["renderCfg"])
        
        d8Weaponry_var.opacityMax = d8Weaponry_var.config["opacityMax"]
        d8Weaponry_var.opacity = d8Weaponry_var.config["opacityMax"]
    end
end