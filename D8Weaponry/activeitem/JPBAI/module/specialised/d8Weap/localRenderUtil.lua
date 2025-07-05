-- A bunch of function for using the renderer through item lua instead of parameters auto detect
-- D8Weaponry Render Compat
local d8Weap_magazineRend = {}

function d8Weap_buildDrawable_ResourceBar(resource, resourceMax, resourceName, directive)
    local drawable = {
        name = "activeItem-",
        isBuilt = true,
        size = {0,0},

        image = "",
        fullbright = true,
        position = {0, 0}
    }
    local segmentNumber = 15
    local segmentSize = 4
    local resourcePercent = (segmentNumber - math.floor((resource/resourceMax)*(segmentNumber)))
    local background = "/interface/emptybar.png"
    local foreground = "/interface/healthbar.png"
    local blend = ":?blendscreen="..foreground..";"..(resourcePercent*segmentSize)..";0" .. (directive or "")
    drawable.name = drawable.name .. resourceName
    drawable.image = background..blend
    return drawable
end

function d8Weap_buildDrawable_Magazine(curMagazine, magazine, name)
    local hand = "primary"
    local drawable = {
        name = "Magazine-",
        isBuilt = true,
        size = {0, 1},

        image = "/assetmissing.png",
        fullbright = true,
        scale = 0.6,
        position = {0, 0.05}
    }
    if curMagazine[1] then
        drawable.image = d8Weap_Magazine_Image(curMagazine, drawable.image)
    end
    local imageSize = root.imageSize(drawable.image)

    local mousePos = function()
        drawable.keepPos = true
        drawable.position = vec2.sub(activeItem.ownerAimPosition() or {0,0}, world.entityPosition(activeItem.ownerEntityId()) or {0,0})
        drawable.position = vec2.add(drawable.position, {0, -1.1})
        drawable.position = vec2.add(drawable.position, vec2.mul({5.5, -2.2}, drawable.scale))
    end
    
    --sb.logInfo("%s%s%s%s", thousand, hundred, ten, unit)
    if player.getProperty("d8Weap") then
        if player.getProperty("d8Weap")["renderCfg"] then
            if player.getProperty("d8Weap")["renderCfg"]["mousePos"] then
                mousePos()
            else
                drawable.position = vec2.add(drawable.position, {0, -1.1})
                drawable.position = vec2.add(drawable.position, vec2.mul({0, -1.1}, drawable.scale))
            end
        else
            mousePos()
        end
    else
        mousePos()
    end
    
    if activeItem then
        hand = activeItem.hand()
    end
    if hand == "alt" and (player.getProperty("d8Weap") or {})["primary"] then
        drawable.position = vec2.add(drawable.position, vec2.mul(vec2.mul(imageSize, {0, -0.125}), drawable.scale))
    end
    drawable.position = vec2.sub(drawable.position, vec2.mul(vec2.mul(imageSize, {0, -0.125}), drawable.scale))
    drawable.size = vec2.mul(drawable.size, drawable.scale)
    return drawable
end

function d8Weap_magazineRend:decomposeNumber(interger)
    if not interger then return end
    number = math.ceil(interger)
    local unit =     number % 10
    number = number // 10
    local ten =      number % 10
    number = number // 10
    local hundred =  number % 10
    number = number // 10
    local thousand = number % 10
    return thousand, hundred, ten, unit
end

function d8Weap_magazineRend:configParam(json, parameter, default)
    if json["parameters"][parameter] then return json["parameters"][parameter] end
    if json["config"][parameter] then return json["config"][parameter] end
    return default
end

function d8Weap_Magazine_Image(curMagazine, image)
    local posIndex = {
        -64,
        -48,
        -32,
        -16
    }
    local schematics = {
        "?replace;ffffff00=ffffffff?crop;0;0;1;1?scale=80;64",
        "?blendmult=<munitionIcon>;0;%s",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-16;%s",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-32;%s",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-48;%s",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-64;%s",
        "?replace;ffffffff=ffffff00",
        "?crop;0;%s;80;64"
    }
    local posShift = 16
    local shiftStrength = 0
    local image = image or "/assetmissing.png"
    image = image .. schematics[1]
    local imageSize = root.imageSize(image)
    for index = 1, (#curMagazine or 0) do
        if curMagazine[index] then
            local munitionIcon = d8Weap_magazineRend:configParam(root.itemConfig(curMagazine[index]["name"]), "inventoryIcon", "")
            local directory = root.itemConfig(curMagazine[index]["name"])["directory"]
            if not string.find(munitionIcon, "/") then munitionIcon = directory .. munitionIcon end
            local thousand, hundred, ten, unit = d8Weap_magazineRend:decomposeNumber(curMagazine[index]["count"])
            local shiftValue = (-48 + (posShift * shiftStrength))
            image = image .. string.gsub(string.format(schematics[2], shiftValue), '<munitionIcon>', munitionIcon)
            
            if (thousand ~= 0 or hundred ~= 0 or ten ~= 0 or unit ~= 0 ) then
                local first
                local second
                local third
                local fourth
                if thousand ~= 0 then
                    first = thousand
                    second = hundred
                    third = ten
                    fourth = unit
                elseif hundred ~= 0 then
                    first = hundred
                    second = ten
                    third = unit
                elseif ten ~= 0 then
                    first = ten
                    second = unit
                elseif unit ~= 0 then
                    first = unit
                end
                
                if first then
                    image = image .. string.gsub(string.format(schematics[3], shiftValue), '<frame>', first)
                end
                if second then
                    image = image .. string.gsub(string.format(schematics[4], shiftValue), '<frame>', second)
                end
                if third then
                    image = image .. string.gsub(string.format(schematics[5], shiftValue), '<frame>', third)
                end
                if fourth then
                    image = image .. string.gsub(string.format(schematics[6], shiftValue), '<frame>', fourth)
                end
            end
            shiftStrength = shiftStrength + 1
        else

        end
    end
    image = image .. schematics[7]
    image = image .. string.format(schematics[8], 16 * (4 - (#curMagazine or 0)))

    return image
end