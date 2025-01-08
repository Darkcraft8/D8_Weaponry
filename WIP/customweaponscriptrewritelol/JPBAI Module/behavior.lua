function initBehavior()
    self.behaviors = config.getParameter("behaviors", {})
    self.behavior = {}
    self.behaviorCooldown = {}
    self.behaviorTime = {}
    self.behaviorPeriodicEventTimer = {}
    self.behaviorPeriodicEventLock = {}
    self.initBehavior = config.getParameter("initBehavior", "idle")
    setBehavior(self.initBehavior)
    
    self.inflictedDamage_Listener = damageListener("inflictedDamage", inflictedDamage)
    self.inflictedHits_Listener = damageListener("inflictedHits", inflictedHits)
    self.damageTaken_Listener = damageListener("damageTaken", damageTaken)
end

function behaviorUpdate(dt, fireMode, isShiftHeld, currentMove)
    self.inflictedDamage_Listener:update()
    self.inflictedHits_Listener:update()
    self.damageTaken_Listener:update()
    if self.behavior["periodicEvent"] then
        for i, e in ipairs(self.behavior["periodicEvent"]) do 
            local triggerEvent = true
            if self.behaviorPeriodicEventTimer[behavior] then
                triggerEvent = (self.behaviorTime[behavior] > e.time)
            else
                self.behaviorPeriodicEventTimer[behavior] = dt
                triggerEvent = false
            end
            if triggerEvent and not self.behaviorPeriodicEventLock[behavior] then
                behaviorEvent(e)
                if e['repeat'] then
                    self.behaviorPeriodicEventTimer[behavior] = dt
                else
                    self.behaviorPeriodicEventLock[behavior] = true
                end
            end
        end
    end
    if self.behavior["eventOnStance"] then -- if the current stanceName is the same as the group name then we call it events
        for s, e in pairs(self.behavior["eventOnStance"]) do 
            if s == self.stanceName and not self.eventDone.stance[s] then
                self.eventDone.stance[s] = true
                behaviorEvents(e)
            end
        end
    end
    behaviorTimer(self.behaviorCooldown, "decrease")
    behaviorTimer(self.behaviorTime, "increase")
    behaviorTimer(self.behaviorPeriodicEventTimer, "increase")
    if self.behavior["possibleOutcome"] then
        for i, p in ipairs(self.behavior["possibleOutcome"]) do
            local useBehav = true
            local behavior = p.behavior
            local checkResult = {}
            for k, v in pairs(p.require) do
                if k == "fireMode" then if useBehav then useBehav = (v == fireMode) checkResult.fireMode = useBehav end end
                if k == "time" then 
                    if self.behaviorTime[behavior] then
                        if useBehav then useBehav = (self.behaviorTime[behavior] > v) end
                    else
                        self.behaviorTime[behavior] = dt
                        useBehav = false
                    end
                    checkResult.time = useBehav
                end
                if k == "move" then if useBehav then useBehav = check_Move(currentMove, v, behavior) checkResult.move = useBehav end end
                if k == "shift" then if useBehav then useBehav = (v == isShiftHeld) checkResult.shift = useBehav end end
                if k == "stance" then if useBehav then useBehav = (v == self.stanceName) checkResult.stance = useBehav end end
                if k == "function" then if useBehav then useBehav = not (not check_Function(v)) checkResult.functions = useBehav end end -- For use with extra scripts ex: custom function that check if a specific parameters is at a specific value while some boolean are true
                
                if k == "exactParam" then if useBehav then useBehav = check_ExactParam(v) checkResult.exactParam = useBehav end end
                if k == "greaterParam" then if useBehav then useBehav = check_GreaterParam(v) checkResult.greaterParam = useBehav end end
                if k == "lowerParam" then if useBehav then useBehav = check_LowerParam(v) checkResult.lowerParam = useBehav end end

                if k == "hasLineOfSight" then if useBehav then useBehav = not check_raycastToSpawnPos(v) checkResult.hasLineOfSight = useBehav end end
            end
            if p.cooldown then if useBehav then useBehav = check_Cooldown(behavior) end end
            --sb.logInfo("%s", behavior)
            --sb.logInfo("%s", checkResult)
            if useBehav == true then
                if p.cooldown then self.behaviorCooldown[behavior] = p.cooldown end
                setBehavior(behavior)
            break end
        end
    end
end

function uninitBehavior()
    resetBehavior()
end

function setBehavior(behaviorName)
    if self.behavior["eventOnUninit"] then behaviorEvents(self.behavior["eventOnUninit"]) end
    resetBehavior()
    self.behavior = self.behaviors[behaviorName]
    self.eventDone = {}
    if self.behavior["eventOnStance"] then self.eventDone.stance = {} end
    if self.behavior["stance"] then setStance(self.behavior["stance"]) end
    if self.behavior["eventOnInit"] then behaviorEvents(self.behavior["eventOnInit"]) end
end

function resetBehavior()
    self.behavior = {}
    self.behaviorCooldown = {}
    self.behaviorTime = {}
    self.behaviorPeriodicEventTimer = {}
    self.behaviorPeriodicEventLock = {}
end

function behaviorEvents(events)
    local events = events or self.behavior["events"]
    if events then 
        for i, e in ipairs(events) do 
            behaviorEvent(e)
        end
    end
end

function behaviorEvent(eventCfg) -- Handle the Different Event kind|Type
    if eventCfg.event == "monster" then behavior_monster(eventCfg) return end
    if eventCfg.event == "projectile" then behavior_projectile(eventCfg) return end
    if eventCfg.event == "function" then call(eventCfg) return end
    if eventCfg.event == "setCursor" then activeItem.setCursor(eventCfg.cursor) return end
end

function behaviorTimer(list, operation) -- increase or decrease value of time, merged into one func
    local dt = script.updateDt()
    if operation == 'decrease' then
        for n, t in pairs(list) do
            if t > 0 then list[n] = t - dt end
        end
    elseif operation == 'increase' then
        for n, t in pairs(list) do
            list[n] = t + dt
        end
    end
end

-- Events
function behavior_hitbox()
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
    local direction = aimVector(event.inaccuracy or 0)
    if event.scalingFunction or Weapon then -- Prepare Scaling based on weapon stat or scaling function
        local callback = call({callback = event.scalingFunction or "Weapon.basicDamage", args = event})
        projectileCfg.power = callback
        projectileCfg.powerMultiplier = activeItem.ownerPowerMultiplier()
    end
    for i = 1, (event.count or 1) do
        local projectileId = world.spawnProjectile(event.type, pos, activeItem.ownerEntityId(), direction, event.posRelativeToOwner, projectileCfg)
    end
end
-- Callback
function inflictedDamage(notifications)
    --sb.logInfo("damageDealt %s", notifications)
    if self.behavior["eventOnDamageDealt"] then
        for _,notification in pairs(notifications) do
            behaviorEvents(self.behavior["eventOnDamageDealt"], notification)
        end
    end
end

function inflictedHits(notifications) 
    --sb.logInfo("hitEvent %s", notifications)
    if self.behavior["eventOnHitDealt"] then 
        for _,notification in pairs(notifications) do
            behaviorEvents(self.behavior["eventOnHitDealt"], notification)
        end
    end
end

function damageTaken(notifications) 
    --sb.logInfo("damageTaken %s", notifications)
    -- -65536 seem to be world or self 
    if self.behavior["eventOnDamageTaken"] then
        for _,notification in pairs(notifications) do
            behaviorEvents(self.behavior["eventOnDamageTaken"], notification)
        end
    end
end

-- Requirement Checks
function check_Move(currentMove, value, behavior)
    local result = true
    if type(value) == "table" then
        for m, b in pairs(value) do
            if not currentMove[m] then
                if b then result = false end
            elseif currentMove[m] ~= b then
                result = false
            end
        end
    elseif type(value) == "string" then
        if currentMove[value] then return true end
    else
        sb.logError("Invalid Move Requirement Config For Behavior | %s", behavior)
    end

    return result
end

function check_Function(callbacks)
    local funcReturned = true
    for _, func in ipairs(callbacks) do 
        local args = nil
        local callback = func
        if type(func) == "table" then callback = func.callback args = func.args end
        if funcReturned then funcReturned = call({callback = callback, args = args}) end
        if not funcReturned then return funcReturned end
    end
    return funcReturned
end

function check_Cooldown(behaviorName)
    if not self.behaviorCooldown[behaviorName] then return true end
    if self.behaviorCooldown[behaviorName] <= 0 then return true end
    return false
end

function check_ExactParam(param) -- Todo
    for p, v in pairs(param) do 
        --sb.logInfo("%s, %s", sb.print(v), sb.print(config.getParameter(p)))
        --sb.logInfo("%s", sb.print(v) ~= sb.print(config.getParameter(p)))
        if sb.print(v) ~= sb.print(config.getParameter(p)) then return false end
    end
    return true
end

function check_GreaterParam(param) -- Todo
    for p, v in pairs(param) do 
        local typeKind = type(config.getParameter(p))
        if typeKind == "number" then
            if (config.getParameter(p) <= v) then
                return false
            end
        end
        if typeKind == "boolean" then
            if v == false then if config.getParameter(p) ~= nil then return false end end
            if v == true then if config.getParameter(p) ~= true then return false end end
        end
        if  typeKind == "table" then
            sb.logInfo("table can't be compared for the moment")
            return false
        end
    end
    return true
end

function check_LowerParam(param) -- Todo
    for p, v in pairs(param) do 
        local typeKind = type(v)
        if typeKind == "number" then
            if (config.getParameter(p) >= v) then
                 return false
            end 
        end
        if typeKind == "boolean" then
            if config.getParameter(p) then
                return false
            end
        end
        if typeKind == "table" then
            sb.logInfo("table can't be compared for the moment")
            return false
        end
    end
    return true
end

function check_raycastToSpawnPos(args)
    return world.lineTileCollision(mcontroller.position(), spawnPosition(args))
end
-- Other's
function spawnPosition(cfg)
    local originPos = cfg.spawnPos -- Possible | ownerHandPos, ownerPosFaceDirection, ownerPos
    local posOffset = cfg.spawnOffset
    local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
    local ownerPos = entity.position()
    local handPos = activeItem.handPosition()

    if originPos == "ownerHandPos" then
        local pos = vec2.rotate(posOffset, aimAngle)
              pos = vec2.mul(pos, {aimDirection, 1})
              pos = vec2.add(vec2.add(ownerPos, handPos), pos)
        return pos
    elseif originPos == "ownerPosFaceDirection" then
        return vec2.mul(vec2.add(ownerPos, posOffset), {aimDirection, 1})
    elseif originPos == "ownerPos" then
        return vec2.add(ownerPos, posOffset)
    elseif originPos == "fireOffset" then
        return vec2.add(firePosition(), vec2.mul(vec2.rotate(posOffset, aimAngle), {aimDirection, 1}))
    end
end

function aimVector(inaccuracy) -- straight out of gunFire.lua with one change
    local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(inaccuracy, 0))
    aimVector[1] = aimVector[1] * mcontroller.facingDirection()
    return aimVector
end

function damageMath()

end

-- Possible Requirement
-- [ if a requirement isn't set it will be ignored
--   "stance" : "" wait for the current stance to be of the same name
--   "timer" : 1
--   "fireMode" : "" require the player to shot using the abilitySlot key "Left|Right mouse click"
--   "isShiftHeld" : "false" require shift to be either held or not
-- ]