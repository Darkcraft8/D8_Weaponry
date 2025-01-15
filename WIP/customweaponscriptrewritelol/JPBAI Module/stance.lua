require "/scripts/activeitem/stances.lua"
require "/scripts/interp.lua"
-- Maybe i should make so that it use/change part of stance.lua
-- i will put here any stance specific function that i need to create
local oldSetStance = setStance
local oldUpdateStance = updateStance
local oldInitStances = initStances
function initStances()
    oldInitStances()
    table.insert(updateFunc, "updateStance")
end

function setStance(stanceName) -- replace and expend on the old version in stances.lua
    self.stanceName = stanceName
    self.stance = self.stances[stanceName]
    self.stanceTimer = self.stance.duration

    for a, s in pairs(self.stance.animationStates or {}) do
        animator.setAnimationState(a, s)
    end
    if self.stance.playSounds then
        for _, s in ipairs(self.stance.playSounds) do
            if animator.hasSound(s) then animator.playSound(s) end
        end
    end
    if self.stance.burstParticleEmitters then
        for _, e in ipairs(self.stance.burstParticleEmitters) do
            animator.burstParticleEmitter(e)
        end
    end
    if not self.lightFlash then
        self.lightFlash = {}
        self.lightFlashprogress = {}
        self.lightFlashDuration = {}
    end
    for lightName, value in pairs(self.stance.lightFlash or {}) do
        animator.setLightActive(lightName, true)

        self.lightFlash[lightName] = getLightColor(lightName)
        self.lightFlashprogress[lightName] = 0
        self.lightFlashDuration[lightName] = 10
        if type(value) == "number" then self.lightFlashDuration[lightName] = value end
    end
    for group, transform in pairs(self.stance.transformations or {}) do
        animator.resetTransformationGroup(group)
        local rotationCenter = transform.rotationCenter or {0, 0}
        if transform.translate then animator.translateTransformationGroup(group, transform.translate) end
        if transform.rotate then animator.rotateTransformationGroup(group, util.toRadians(transform.rotate), rotationCenter) end
        if transform.scale then animator.scaleTransformationGroup(group, transform.scale) end
        
    end

    if type(self.stance.armRotation) == "table" then
        self.armRotation = self.stance.armRotation[1]
    else
        self.armRotation = self.stance.armRotation or 0
    end
    
    if self.stance.lerpTo then
        if not coroutine.resume(self.coroutine.lerp) then
            self.coroutine.lerp = coroutine.create(function(dt) lerpStance(dt) end)
            coroutine.resume(self.coroutine.lerp, script.updateDt())
        end
    end
    
    if self.stance.resetAim then
        self.aimAngle = 0
    elseif self.stance.aimAngle then
        self.aimAngle = self.stance.aimAngle
    end

    if self.stance.frontArmFrame ~= nil then activeItem.setFrontArmFrame(self.stance.frontArmFrame) end
    if self.stance.backArmFrame ~= nil then activeItem.setBackArmFrame(self.stance.backArmFrame) end
    if self.stance.holdingItem ~= nil then activeItem.setHoldingItem(self.stance.holdingItem) end
    if self.stance.twoHanded ~= nil then activeItem.setTwoHandedGrip(self.stance.twoHanded) end

    updateAim(self.stance.allowRotate, self.stance.allowFlip)
    if self.stance.invertDirection then
        activeItem.setFacingDirection(-1 * (self.aimDirection or 0))
    end
end

function updateStance(dt) -- added updateAim in so that rotation and flip get updated
    updateAim(self.stance.allowRotate, self.stance.allowFlip)
    
    if self.coroutine.lerp then
        local status, error = coroutine.resume(self.coroutine.lerp, dt)
        if not status then
            if not error == "cannot resume dead coroutine" then sb.logError("%s", error) end
            self.coroutine.lerp = nil
        end
    else
        if self.stance.armAngularVelocity ~= nil then self.armRotation = self.armRotation + self.stance.armAngularVelocity end
        if sb.printJson(self.stance.transformations or {}) ~= "{}" then end
        for group, transform in pairs(self.stance.transformations or {}) do
            if transform.velocity then
                local rotationCenter = transform.rotationCenter or {0, 0}
                if transform.velocity.translate then animator.translateTransformationGroup(group, vec2.mul(transform.velocity.translate, dt)) end
                if transform.velocity.rotate then animator.rotateTransformationGroup(group, util.toRadians((transform.velocity.rotate * dt)), rotationCenter) end
                if transform.velocity.scale then animator.scaleTransformationGroup(group, transform.velocity.scale * dt) end
            end
        end
        if self.stance.invertDirection then activeItem.setFacingDirection(-1 * (self.aimDirection or 0)) end
    end

    for lightName, _ in pairs(self.lightFlash or {}) do
        if self.lightFlashprogress[lightName] < 1 then
            self.lightFlash[lightName] = interpColor(self.lightFlashprogress[lightName], self.lightFlash[lightName], {0, 0, 0})
            self.lightFlashprogress[lightName] = math.min(1.0, self.lightFlashprogress[lightName] + (dt / self.lightFlashDuration[lightName]))
            animator.setLightColor(lightName, self.lightFlash[lightName])
            if self.lightFlashprogress[lightName] >= 1 then
                animator.setLightActive(lightName, false)
                animator.setLightColor(lightName, getLightColor(lightName))
            end
        end
    end

    if self.stanceTimer then
        self.stanceTimer = math.max(self.stanceTimer - dt, 0)
    
        if type(self.stance.armRotation) == "table" and not self.coroutine.lerp then
          local stanceRatio = 1 - (self.stanceTimer / self.stance.duration)
          self.armRotation = util.lerp(stanceRatio, self.stance.armRotation)
        end
    
        if self.stanceTimer <= 0 and not self.coroutine.lerp then
          if self.stance.transition then
            setStance(self.stance.transition)
          end
          if self.stance.transitionFunction then
            _ENV[self.stance.transitionFunction]()
          end
        end
    end
end

function lerpStance(dt)
    local progress = 0
    local from = self.stance
    local to = self.stances[from['transition']]
    local fromAimAngle = self.aimAngle or 0
    local armProgress, aimProgress, armAngle

    util.wait(from.duration or 0.25, function(dt)
        for group, transform in pairs(from.transformations or {}) do
            if to.transformations[group] then
                animator.resetTransformationGroup(group)
                local toTranform = to.transformations[group]

                local translate = vec2.lerp(progress, transform.translate or {0, 0}, toTranform.translate or {0, 0})
                local rotate = interp.linear(progress, transform.rotate or 0, toTranform.rotate or 0)
                local rotationCenter = vec2.lerp(progress, transform.rotationCenter or {0, 0}, toTranform.rotationCenter or {0, 0})
                local scale = interp.linear(progress, transform.scale or 1 , toTranform.scale or 1)

                if transform.translate then animator.translateTransformationGroup(group, translate) end
                if transform.rotate then animator.rotateTransformationGroup(group, util.toRadians(rotate), rotationCenter) end
                if transform.scale then animator.scaleTransformationGroup(group, scale) end

            else 
                animator.resetTransformationGroup(group)
                local translate = vec2.lerp(progress, transform.translate or {0, 0}, {0, 0})
                local rotate = interp.linear(progress, transform.rotate or 0, 0)
                local rotationCenter = vec2.lerp(progress, transform.rotationCenter or {0, 0}, {0, 0})
                local scale = interp.linear(progress, transform.scale or 1, 1)

                if transform.translate then animator.translateTransformationGroup(group, translate) end
                if transform.rotate then animator.rotateTransformationGroup(group, util.toRadians(rotate), rotationCenter) end
                if transform.scale then animator.scaleTransformationGroup(group, scale) end
            end
        end
        
        local aimAngle = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
        armAngle = 0
        armProgress = util.toRadians(interp.linear(progress, from.armRotation or 0, to.armRotation or 0) )
        aimProgress = interp.linear(progress, fromAimAngle, aimAngle or 0)
        
        if (from.allowRotate and to.allowRotate) or to.allowRotate then
            armAngle = aimProgress + armProgress
        elseif from.allowRotate then
            armAngle = interp.linear(progress, fromAimAngle + util.toRadians(from.armRotation), 0 + util.toRadians(to.armRotation) )
        else
            armAngle = armProgress
        end
        activeItem.setArmAngle(armAngle)
        if progress > 0.5 then 
            if to.frontArmFrame ~= nil then activeItem.setFrontArmFrame(to.frontArmFrame) end
            if to.backArmFrame ~= nil then activeItem.setBackArmFrame(to.backArmFrame) end
            if to.invertDirection then
                activeItem.setFacingDirection(-1 * (self.aimDirection or 0))
            end
        end
        progress = math.min(1.0, progress + (dt / from.duration))
    end)
    self.armRotation = to.armRotation or 0
    if tostring.resetAim then
        self.aimAngle = 0
    elseif to.aimAngle then
        self.aimAngle = to.aimAngle
    end
    updateAim(to.allowRotate, to.allowFlip)
end

function uninitStance()
    for lightName, _ in pairs(self.lightFlash or {}) do-- reset light state and color
        animator.setLightActive(lightName, getLightState(lightName))
        animator.setLightColor(lightName, getLightColor(lightName))
    end
end

function interpColor(ratio, a, b)
    local color = {0,0,0}
    color[1] = interp.linear(ratio, a[1], b[1])
    color[2] = interp.linear(ratio, a[2], b[2])
    color[3] = interp.linear(ratio, a[3], b[3])
    return color
end

function getLightState(lightName)
    local state = false
    if self.animationCfg["lights"] then
        if self.animationCfg["lights"] then
            if self.animationCfg["lights"][lightName] then
                if self.animationCfg["lights"][lightName]["active"] ~= nil then 
                    state = self.animationCfg["lights"][lightName]["active"]
                else
                    state = false
                end
            end
        end
    end
    return state
end

function getLightColor(lightName)
    local color = {255, 255, 255}
    if self.animationCfg["lights"] then
        if self.animationCfg["lights"] then
            if self.animationCfg["lights"][lightName] then
                if self.animationCfg["lights"][lightName]["color"] then 
                    color = self.animationCfg["lights"][lightName]["color"]
                end
            end
        end
    end
    return color
end

-- Stance Variable/Parameters
-- "duration"
-- "animationState"
-- "transformations"
-- "armRotation"
-- "resetAim"
-- "twoHanded"
-- "allowRotate"
-- "allowFlip"
-- "transitionFunction"
-- "transition" can be added to a stance to change stances... don't remember seeing it used in vanilla