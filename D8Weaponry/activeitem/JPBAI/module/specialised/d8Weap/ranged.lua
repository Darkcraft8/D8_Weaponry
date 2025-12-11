require("/jpbai/module/specialised/weapon.lua")
require("/D8Weaponry/activeitem/JPBAI/module/specialised/d8Weap/localRenderUtil.lua")
require "/shared/darkcraft8/localScript/deployment/rendererUtil.lua"
require "/shared/darkcraft8/util/item.lua"

d8WeapItem = {}
function d8WeapItem.init()
    D8Shared_BuildItemFunction()

    d8WeapItem.magazine = descriptMag(config.getParameter("magazine", {}))
    d8WeapItem.reloadOverride = config.getParameter("reloadOverride")
    d8WeapItem.curMagazine = descriptMag(config.getParameter("curMagazine", {}))
    d8WeapItem.magazineCapacity = config.getParameter("magazineCapacity", 1)
    table.insert(updateFunc, "d8WeapItem.update")
    --d8WeapItem.addMunition({item = "d8Weaponry_standardbullet"})
    if player then
        local property = player.getProperty("d8Weap") or {}
        property[activeItem.hand()] = true
        player.setProperty("d8Weap", property)

        rpcAddedDrawable = d8SharedRendererUtil.addDrawable(d8Weap_buildDrawable_Magazine(d8WeapItem.curMagazine, d8WeapItem.magazine, "d8WeapItem"), 0,  "d8WeapItem" .. config.getParameter("shortdescription", "") .. activeItem.hand())
    end
end

function d8WeapItem.uninit()
    if d8WeapItem.curMagazine then activeItem.setInstanceValue("curMagazine", d8WeapItem.curMagazine) end
    if player then
        local property = player.getProperty("d8Weap") or {}
        property[activeItem.hand()] = false
        player.setProperty("d8Weap", property)

        d8SharedRendererUtil.removeDrawable("d8WeapItem" .. config.getParameter("shortdescription", "") .. activeItem.hand())
    end
end

function d8WeapItem.update(dt, fireMode, isShiftHeld, currentMove)
    if player then
        d8WeapItem.updateTooltip()
        if not rpcAddedDrawable then
            rpcAddedDrawable = d8SharedRendererUtil.addDrawable(d8Weap_buildDrawable_Magazine(d8WeapItem.curMagazine, d8WeapItem.magazine, "d8WeapItem"), 0,  "d8WeapItem" .. config.getParameter("shortdescription", "") .. activeItem.hand())
        else
            d8SharedRendererUtil.updateDrawable(d8Weap_buildDrawable_Magazine(d8WeapItem.curMagazine, d8WeapItem.magazine, "d8WeapItem"), "d8WeapItem" .. config.getParameter("shortdescription", "") .. activeItem.hand())
        end
    end
end

function d8WeapItem.consumeMag()
    if world.entityType(activeItem.ownerEntityId()) ~= "player" then return true end
    if (player.isAdmin() or config.getParameter("admin", config.getParameter("d8WeapMods.infAmmo", false))) then return true end
    --sb.logInfo("%s", Weapon.canConsumeItem(d8WeapItem.magazine))
    if Weapon.canConsumeItem(d8WeapItem.reloadOverride or d8WeapItem.magazine) then return Weapon.consumeItem(d8WeapItem.reloadOverride or d8WeapItem.magazine) else return false end
end

function d8WeapItem.canConsumeMag()
    if world.entityType(activeItem.ownerEntityId()) ~= "player" then return true end
    if (player.isAdmin() or config.getParameter("admin", config.getParameter("d8WeapMods.infAmmo", false))) then return true end
    return Weapon.canConsumeItem(d8WeapItem.reloadOverride or d8WeapItem.magazine)
end

function d8WeapItem.shotMunition(spawnPos, spawnOffset, scalingFunction, damage, inaccuracy, projectileType, projectileCount, projectileParameter)
    local spawnPos, spawnOffset, scalingFunction, damage, inaccuracy, projectileType, projectileCount, projectileParameter = copy(spawnPos), copy(spawnOffset), copy(scalingFunction), copy(damage), copy(inaccuracy or 0), copy(projectileType), copy(projectileCount), copy(projectileParameter)
    local munition = root.itemConfig(d8WeapItem.nextMunition(), default)
    local configParam = function(parameter)
        if munition.parameters[parameter] then return munition.parameters[parameter] end
        if munition.config[parameter] then return munition.config[parameter] end
        return default
    end
    local args = {}
    args.spawnPos = spawnPos
    args.spawnOffset = spawnOffset
    args.scalingFunction = scalingFunction
    args.damage = damage
    
    args.type = projectileType or configParam("projectileType")
    args.count = projectileCount or configParam("projectileCount", 1)
    args.parameter = projectileParameter or configParam("projectileParameter", {})
    if configParam("projectileInaccuracy") then
        args.inaccuracy = inaccuracy + configParam("projectileInaccuracy", 0)
    else
        args.inaccuracy = (inaccuracy * args.count)
    end
    if not args.type then return end
    --sb.logInfo("%s", args.damage)
    --sb.logInfo("projectileConfig(%s) %s", args.type, root.projectileConfig(args.type))
    local useHitscan = (args.parameter.speed or root.projectileConfig(args.type).speed or 0) >= 250--disabledbecausehitscanfuncisnotfinished--
    if useHitscan then
        --[[ simulated
        if args.scalingFunction or Weapon then -- Scale based on weapon stat or scaling function
            local callback = call({callback = args.scalingFunction or "Weapon.basicDamage", args = args})
            args.parameter.power = args.parameter.power or callback
            args.parameter.powerMultiplier = args.parameter.powerMultiplier or activeItem.ownerPowerMultiplier()
        end

        Weapon.hitscan(args.type, args.parameter, range, spawnPosition(args), args.inaccuracy)
        --]]
        --[[ speed-up projectile]]
        local speed = 700
        local projectileConfig = root.projectileConfig(args.type)
        local configParam = function(paramName, defaultValue)
            return args.parameter[paramName] or projectileConfig[paramName] or defaultValue
        end
        args.parameter.movementSettings = configParam("movementSettings", {})
        args.parameter.movementSettings.maximumCorrection = 10
        args.parameter.movementSettings.speedLimit = speed
        args.parameter.speed = speed
        args.parameter.periodicAction = configParam("periodicActions", {})
        
        --args.type = "d8weap_physicalHitscan"
        behavior_projectile(args)
        --]]
    else
        behavior_projectile(args)
    end
    d8WeapItem.consumeMunition()
end

function d8WeapItem.hasSpaceInMagazine()
    if (player.isAdmin() or config.getParameter("admin", config.getParameter("d8WeapMods.infAmmo", false))) then return true end
    local munitionCount = 0
    for i, d in ipairs(d8WeapItem.curMagazine or {}) do 
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
    d8WeapItem.curMagazine = descriptMag(copy(d8WeapItem.magazine))
    activeItem.setInstanceValue("curMagazine", d8WeapItem.curMagazine)
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
    activeItem.setInstanceValue("curMagazine", d8WeapItem.curMagazine)
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
    d8WeapItem.curMagazine = descriptMag(d8WeapItem.curMagazine)
    activeItem.setInstanceValue("curMagazine", d8WeapItem.curMagazine)
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
                d8WeapItem.curMagazine = descriptMag(args.itemTable)
            else sb.logError("[JPBAI Framework] %s Item Table not found/valid", args.itemTable) end
        else sb.logError("[JPBAI Framework] %s Item Table not found/valid", args.itemTable) end
    end
end
function d8WeapItem.setParameterAsTag(args)
    if args.parameter and args.tagName then
        if config.getParameter(args.parameter) then 
            animationEx.setGlobalTag({tagName = args.tagName, varNum = config.getParameter(args.parameter)}) 
        end
    end
end

function d8WeapItem.munitionScaling(_args) -- similar to damagePerShot except it take the projectile info into account
    if not _args then return end
    if not _args.type then return end

    local projectileCfg = sb.jsonMerge(root.projectileConfig(_args.type), _args.parameters or {})
    local args = copy(_args)
    
    args.baseDamage = ((args.damage or projectileCfg.power) * 0.25) * (projectileCfg.speed * 0.065)
    args.knockback = (projectileCfg.speed * 0.1) + (args.baseDamage * 0.25)
    --sb.logInfo("baseDamage %s", args.baseDamage)
    --sb.logInfo("damagePerShot %s", Weapon.damagePerShot(args))
    return Weapon.damagePerShot(args)
end

function d8WeapItem.updateTooltip()
    local tooltipFields = item.getItemParameter("tooltipFields", {})
    local damageTable = {}
    local damageValue = 0
    for _, munition in ipairs(config.getParameter("magazine", {})) do
        local munition = root.itemConfig(munition)
        local configParam = function(parameter)
            if munition.parameters[parameter] then return munition.parameters[parameter] end
            if munition.config[parameter] then return munition.config[parameter] end
            return default
        end
        local args = {}
        args.type = configParam("projectileType")
        args.count = configParam("projectileCount", 1)
        args.parameter = configParam("projectileParameter", {})
        if args.type then
            table.insert(damageTable, d8WeapItem.munitionScaling(args))
        end
    end
    for _, damage in ipairs(damageTable) do 
        local diff = damage - damageValue
        damageValue = damageValue + diff
    end
    
    if tooltipFields.damagePerShotLabel ~= "~"..util.round(damageValue) then
        tooltipFields.damagePerShotLabel = "~"..util.round(damageValue)
        activeItem.setInstanceValue("tooltipFields", tooltipFields)
    end
    local updateToolTip = function(curMagazine)
        local tooltipFields = item.getItemParameter("tooltipFields", {})
        local newImage = d8Weap_Magazine_Image(curMagazine or {})
        if newImage ~= tooltipFields.magazineImage then
            tooltipFields.magazineImage = newImage
            activeItem.setInstanceValue("tooltipFields", tooltipFields)
        end
    end
    updateToolTip(d8WeapItem.curMagazine)
end

function descriptMag(curMag)
    for i = 1, #curMag do 
        if type(curMag[i]) == "string" then
            curMag[i] = root.createItem(curMag[i])
        elseif type(curMag[i]) == "table" then
            if not curMag[i].parameters then
                curMag[i].parameters = {}
            end
            if not curMag[i].count then
                curMag[i].count = 1
            end
        end
    end
    return curMag
end