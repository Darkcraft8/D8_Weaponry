behaviorEx = {}
-- A bunch of extra function that arent focused on the behavior logic

-----------------------------------------------------------------------------------

function behaviorEx.getParameter(args) -- bridge for getParameter/getInstanceValue
    if not args then return end
    if args.parameter ~= nil then return config.getParameter(args.parameter, args.defaultValue) end
end

function behaviorEx.setParameter(args) -- bridge for setParameter/setInstanceValue
    if not args then return end
    if args.parameter ~= nil and args.value ~= nil then activeItem.setInstanceValue(args.parameter, args.value) end
end

-----------------------------------------------------------------------------------

-- Value
function behaviorEx.modValue(args)
    if not args then return end
    if args.parameter and args.value then 
        local newValue = config.getParameter(args.parameter, 0) + args.value
        activeItem.setInstanceValue(args.parameter, newValue)
    end
end

function behaviorEx.valueDiff(args)
    if not args then return false end
    if args.parameter and args.value then
        local diffType = args.diffType or "above" -- above, bellow or between
        local currentValue = config.getParameter(args.parameter, 0)
        if type(currentValue) ~= 'number' then sb.logError("%s ins't a number/value", args.parameter) return false end
        if diffType == "above" then
            if type(args.value) == "table" then
                return (currentValue > args.value[1])
            else
                return (currentValue > args.value)
            end
        elseif diffType == "bellow" then
            if type(args.value) == "table" then
                return (currentValue < args.value[1])
            else
                return (currentValue < args.value)
            end
        elseif diffType == "between" then
            if type(args.value) ~= "table" then sb.logError("%s ins't a table of two value", args.value) return false end
            if type(args.value[1]) ~= 'number' or type(args.value[2]) ~= 'number' then sb.logError("%s ins't a table of two value", args.value) return false end

            return ( (currentValue <= args.value[1]) == (currentValue >= args.value[2]) )
        end
    end
end

-----------------------------------------------------------------------------------

-- Function's to interact with player resources|status like a consumable but better
function behaviorEx.hasResources(args) -- return if the resources in the table are available
    if not args then return end
    for i, cfg in ipairs(args) do
        if cfg.count then
            if not status.resource(cfg.resource) >= cfg.count then return false end
        else
            if not status.resourcePositive(cfg.resource) then return false end
        end
    end
    return true
end

function behaviorEx.modResources(args) -- modifie the resource depending on the given operation
    if not args then return end
    for i, cfg in ipairs(args) do 
        if args.op == "give" then
            status.giveResource(args.resource, args.amount)
        elseif args.op == "consume" then
            status.consumeResource(args.resource, args.amount)
        elseif args.op == "overConsume" then
            status.overConsumeResource(args.resource, args.amount)
        elseif args.op == "set" then
            status.setResource(args.resource, args.amount)
        end
    end
end

function behaviorEx.status(args)
    if not args then return end
    local activeEffect = status.activeUniqueStatusEffectSummary()
end

-----------------------------------------------------------------------------------

function behaviorEx.emptyTable(args) -- Todo
end

-----------------------------------------------------------------------------------
-- Events
function behavior_hitbox(event) -- todo
    local hitboxInfo = event.hitbox or {}
    local poly = animator.partPoly(hitboxInfo.partName, hitboxInfo.polyName or "damageArea")
    local damageLine, damagePoly
    local knockback = event.knockback or 0
    local damage = event.baseDamage or 0
    if not poly then sb.logError("behavior_hitbox | poly not found for %s : %s", hitboxInfo.partName, hitboxInfo.polyName) return end
    if #poly == 2 then damageLine = poly else damagePoly = poly end
    if (event.damageScalingFunction or Weapon) and damage then damage = call({callback = event.damageScalingFunction or "Weapon.basicDamage", args = event}) end    
    if knockback and event.directionalKnockback then knockback = knockbackMomentum(knockback, event.knockbackMode, self.aimAngle or 0, self.aimDirection or 0) end
    local damageSource = {
        poly = damagePoly,
        line = damageLine,
        damage = damage,
        trackSourceEntity = event.trackSourceEntity,
        sourceEntity = activeItem.ownerEntityId(),
        team = activeItem.ownerTeam(),
        damageSourceKind = event.damageSourceKind,
        statusEffects = event.statusEffects,
        knockback = knockback or 0,
        rayCheck = true,
        damageRepeatGroup = damageRepeatGroup(event.timeoutGroup),
        damageRepeatTimeout = event.timeout or 0.1
    }
    if not self.damageSources then self.damageSources = {} end
    if not self.damageSourcesTimer then self.damageSourcesTimer = {} end
    self.damageSources[behaviorName] = damageSource
    self.damageSourcesTimer[behaviorName] = event.duration or event.timeout or 0.1
end

function behavior_monster(event)
    local monsterCfg = event.parameter or {}
    if event.level then 
        monsterCfg.level = event.level
    else 
        monsterCfg.level = 1
        if event.scalingFunction then -- Prepare Scaling based on weapon stat or scaling function
            monsterCfg.level = call({callback = event.scalingFunction, args = event})
        elseif Weapon then
            monsterCfg.level = Weapon.level
        end
    end
    local pos = spawnPosition(event)
    
    local status, message = pcall(world.spawnMonster(event.type, pos, monsterCfg))
    --sb.logInfo("%s", pos) sb.logInfo("%s", event.type) sb.logInfo("%s", monsterCfg)
    --sb.logInfo("spawnMonster | %s, %s", status, message)
    if not message then sb.logError("monster | %s", message) end
end

function behavior_projectile(event)
    local projectileCfg = event.parameter or {}
    local pos = spawnPosition(event)
    if event.scalingFunction or Weapon then -- Prepare Scaling based on weapon stat or scaling function
        local callback = call({callback = event.scalingFunction or "Weapon.basicDamage", args = event})
        projectileCfg.power = callback
        projectileCfg.powerMultiplier = activeItem.ownerPowerMultiplier()
    end
    for i = 1, (event.count or 1) do
        local direction = aimVector(event.inaccuracy or 0)
        local projectileId = world.spawnProjectile(event.type, pos, activeItem.ownerEntityId(), direction, event.posRelativeToOwner, projectileCfg)
    end
end

function behaviorEx.velocity(event)

end

function behaviorEx.setBehavior(event) -- used to force a behavior change for things that require it ex: a parry that change the next few attack when succesfull
    setBehavior(event.behaviorName)
end
-----------------------------------------------------------------------------------

-- Weapon.Lua Func
function damageRepeatGroup(mode)
    mode = mode or ""
    return activeItem.ownerEntityId() .. config.getParameter("itemName") .. activeItem.hand() .. mode
end

function knockbackMomentum(knockback, knockbackMode, aimAngle, aimDirection)
    knockbackMode = knockbackMode or "aim"
  
    if type(knockback) == "table" then
      return knockback
    end
  
    if knockbackMode == "facing" then
      return {aimDirection * knockback, 0}
    elseif knockbackMode == "aim" then
      local aimVector = vec2.rotate({knockback, 0}, aimAngle)
      aimVector[1] = aimDirection * aimVector[1]
      return aimVector
    end
    return knockback
end

-----------------------------------------------------------------------------------
-- Math
function damageMath() end -- Todo 

-----------------------------------------------------------------------------------
-- damageArea Handler

function behaviorEx.damageAreaUpdate(dt)
    local effectiveSources = {}
    for name, timer in pairs(self.damageSourcesTimer or {}) do 
        if timer > 0 then self.damageSourcesTimer[name] = timer - dt end
        if timer <= 0 then self.damageSourcesTimer[name] = nil self.damageSources[name] = nil else table.insert(effectiveSources, self.damageSources[name]) end
    end
    activeItem.setItemDamageSources(effectiveSources or {})
end
-----------------------------------------------------------------------------------