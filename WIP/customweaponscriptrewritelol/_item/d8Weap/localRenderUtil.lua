-- A bunch of function for using the renderer through item lua instead of parameters auto detect
-- D8Weaponry Render Compat
d8WeaponryUtils = getmetatable''.d8WeaponryUtils
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
    local schematics = {
        "/assetmissing.png?replace;ffffff00=ffffffff?crop;0;0;1;1?scale=80;32",
        "?blendmult=<munitionIcon>;0;-16",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-16;-16",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-32;-16",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-48;-16",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-64;-16",
        "?blendmult=<munitionIcon>;0;0",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-16;0",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-32;0",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-48;0",
        "?blendmult=/objects/outpost/number<frame>/icon.png;-64;0",
        "?replace;ffffffff=ffffff00"
    }
    local drawable = {
        name = "Magazine-",
        isBuilt = true,
        size = {0, 1},

        image = "",
        fullbright = true,
        scale = 0.6,
        position = {0,-0.05}
    }
    drawable.name = drawable.name .. name
    drawable.image = drawable.image .. schematics[1]
    if curMagazine[1] then
        local munitionIcon = d8Weap_magazineRend:configParam(root.itemConfig(curMagazine[1]["name"]), "inventoryIcon", "")
        local thousand, hundred, ten, unit = d8Weap_magazineRend:decomposeNumber(curMagazine[1]["count"])
        drawable.image = drawable.image .. string.gsub(schematics[2], '<munitionIcon>', munitionIcon)
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
                drawable.image = drawable.image .. string.gsub(schematics[3], '<frame>', first)
            end
            if second then
                drawable.image = drawable.image .. string.gsub(schematics[4], '<frame>', second)
            end
            if third then
                drawable.image = drawable.image .. string.gsub(schematics[5], '<frame>', third)
            end
            if fourth then
                drawable.image = drawable.image .. string.gsub(schematics[6], '<frame>', fourth)
            end
        end
        if curMagazine[2] then
            local munitionIcon = d8Weap_magazineRend:configParam(root.itemConfig(curMagazine[2]["name"]), "inventoryIcon", "")
            local thousand, hundred, ten, unit = d8Weap_magazineRend:decomposeNumber(curMagazine[2]["count"])
            drawable.image = drawable.image .. string.gsub(schematics[7], '<munitionIcon>', munitionIcon)
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
                    drawable.image = drawable.image .. string.gsub(schematics[8], '<frame>', first)
                end
                if second then
                    drawable.image = drawable.image .. string.gsub(schematics[9], '<frame>', second)
                end
                if third then
                    drawable.image = drawable.image .. string.gsub(schematics[10], '<frame>', third)
                end
                if fourth then
                    drawable.image = drawable.image .. string.gsub(schematics[11], '<frame>', fourth)
                end
            end
        end
    end
    --sb.logInfo("%s%s%s%s", thousand, hundred, ten, unit)
    if player.getProperty("d8Weap")["renderCfg"]["mousePos"] then
        drawable.keepPos = true
        drawable.position = vec2.sub(activeItem.ownerAimPosition(), world.entityPosition(activeItem.ownerEntityId()))
        drawable.position = vec2.add(drawable.position, vec2.mul({5.5, -2.2}, drawable.scale))
    end
    drawable.size = vec2.mul(drawable.size, drawable.scale)
    drawable.image = drawable.image .. schematics[12]
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