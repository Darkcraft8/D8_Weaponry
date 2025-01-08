require("/WIP/customweaponscriptrewritelol/_item/weapon.lua")
require("/WIP/customweaponscriptrewritelol/_item/d8Weap/localRenderUtil.lua")

d8WeapItem = {}
function d8WeapItem.init()
    d8WeapItem.magazine = config.getParameter("magazine", {})
    d8WeapItem.curMagazine = config.getParameter("curMagazine", {})
    d8WeapItem.magazineCapacity = config.getParameter("magazineCapacity", 1)
    table.insert(updateFunc, "d8WeapItem.update")
    --d8WeapItem.addMunition({item = "d8Weaponry_standardbullet"})
end

function d8WeapItem.uninit()
    if d8WeapItem.curMagazine then
        activeItem.setInstanceValue("curMagazine", d8WeapItem.curMagazine)
        --sb.logInfo("%s", d8WeapItem.curMagazine)
    end
    if d8WeaponryUtils then
        d8WeaponryUtils:remove("d8WeapItem" .. config.getParameter("shortdescription", "") .. activeItem.hand())
    end
end

function d8WeapItem.update(dt, fireMode, isShiftHeld, currentMove)
    if d8WeaponryUtils then
        local drawable = d8Weap_buildDrawable_Magazine(d8WeapItem.curMagazine, d8WeapItem.magazine, "test")--d8Weap_buildDrawable_ResourceBar(d8WeapItem.curMunitionAmount(), d8WeapItem.magazineCapacity or 100, "d8WeapItem" .."-".. config.getParameter("shortdescription", "") .."-".. activeItem.hand() , directive)
        if d8WeaponryUtils.drawableList[drawable.name] then
            d8WeaponryUtils:update(drawable)
        else
            d8WeaponryUtils:add(drawable)
        end
    end
end

function d8WeapItem.consumeMag()
    if world.entityType(activeItem.ownerEntityId()) ~= "player" then return true end
    if player.isAdmin() then return true end
    --sb.logInfo("%s", Weapon.canConsumeItem(d8WeapItem.magazine))
    if Weapon.canConsumeItem(d8WeapItem.magazine) then return Weapon.consumeItem(d8WeapItem.magazine) else return false end
end

function d8WeapItem.canConsumeMag()
    if world.entityType(activeItem.ownerEntityId()) ~= "player" then return true end
    if player.isAdmin() then return true end
    return Weapon.canConsumeItem(d8WeapItem.magazine)
end

function d8WeapItem.shotMunition(args)
    if not args then return end
    local munition = root.itemConfig(d8WeapItem.nextMunition(), default)
    local configParam = function(parameter)
        if munition.parameters[parameter] then return munition.parameters[parameter] end
        if munition.config[parameter] then return munition.config[parameter] end
        return default
    end

    args.type = configParam("projectileType")
    args.count = configParam("projectileCount", 1)
    args.parameter = configParam("projectileParameter", {})
    if not args.type then return end
    behavior_projectile(args)
    d8WeapItem.consumeMunition()
end

function d8WeapItem.hasSpaceInMagazine()
    local munitionCount = 0
    for i, d in ipairs(d8WeapItem.curMagazine) do 
        if type(d) == "table" then
            for count = 1, d.count or 1 do
                munitionCount = munitionCount + 1
            end
        else
            munitionCount = munitionCount + 1
        end
    end
    if d8WeapItem.magazineCapacity <= munitionCount then return false else return true end
end

function d8WeapItem.refillCurMag()
    --sb.logInfo("%s", d8WeapItem.curMagazine)
    d8WeapItem.curMagazine = copy(d8WeapItem.magazine)
    --sb.logInfo("%s", d8WeapItem.curMagazine)
end

function d8WeapItem.addMunition(args)
    local munition = d8WeapItem.nextMunition()
    local item = args.item

    if root.itemDescriptorsMatch(item, munition, true) then
        d8WeapItem.curMagazine[1].count = d8WeapItem.curMagazine[1].count + 1
    else
        local munitionCfg = {}
        if type(item) == "string" then
            munitionCfg.name = item
            munitionCfg.count = 1
            munitionCfg.parameters = {}
        else
            munitionCfg = item
        end
        table.insert(d8WeapItem.curMagazine, 1, munitionCfg)
    end
end

function d8WeapItem.consumeMunition()
    local munition = d8WeapItem.nextMunition()
    if type(munition) == "table" then
        if munition.count > 1 then
            d8WeapItem.curMagazine[1].count = d8WeapItem.curMagazine[1].count - 1
        else
            local newMagazine = {}
            for i = 1, #d8WeapItem.curMagazine do
                if i ~= 1 then table.insert(newMagazine, d8WeapItem.curMagazine[i]) end
            end
            d8WeapItem.curMagazine = newMagazine
        end
    else
        local newMagazine = {}
        for i = 1, #d8WeapItem.curMagazine do
            if i ~= 1 then table.insert(newMagazine, d8WeapItem.curMagazine[i]) end
        end
        d8WeapItem.curMagazine = newMagazine
    end
end

function d8WeapItem.hasMunitionLoaded()
    return d8WeapItem.curMagazine[1]
end

function d8WeapItem.nextMunition() -- Return the first/next loaded munition in the list
    if d8WeapItem.curMagazine[1] then return d8WeapItem.curMagazine[1] end
end

function d8WeapItem.curMagEmpty()
    if not d8WeapItem.curMagazine[1] then return true end
end

function d8WeapItem.curMunitionAmount()
    local amount = 0
    for _, item in ipairs(d8WeapItem.curMagazine) do 
        if type(item) == "table" then 
            amount = amount + item.count
        else
            amount = amount + 1
        end
    end
    return amount
end

function d8WeapItem.setMag(args)
    if args then 
        if args.itemTable then 
            if root.createItem(args.itemTable[1]) then
                d8WeapItem.curMagazine = args.itemTable
            else sb.logError("%s Item Table not found/valid", args.itemTable) end
        else sb.logError("%s Item Table not found/valid", args.itemTable) end
    end
end
function d8WeapItem.setParameterAsTag(args)
    if args.parameter and args.tagName then
        if config.getParameter(args.parameter) then 
            animationEx.setGlobalTag({tagName = args.tagName, varNum = config.getParameter(args.parameter)}) 
        end
    end
end

function d8WeapItem.munitionScaling(args) -- similar to damagePerShot except it take the projectile info into account
    local projectileCfg = sb.jsonMerge(root.projectileConfig(args.type), args.parameters or {})
    local args = args
    args.baseDamage = (projectileCfg.power * 0.25) * (projectileCfg.speed * 0.065)
    args.knockback = (projectileCfg.speed * 0.1) + (args.baseDamage * 0.25)
    return Weapon.damagePerShot(args)
end