require "/scripts/util.lua"
require "/scripts/interp.lua"

-- gunFire ability forked from gunfire.lua
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)
  self.cooldownTimer = self.fireTime
  self.temperature = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
  activeItem.setInstanceValue("durability", -config.getParameter(self.ammoMaxName))
  if not config.getParameter(self.ammoCountName) then
    activeItem.setInstanceValue(self.ammoCountName, config.getParameter(self.ammoMaxName))
  end
  passiveTimer = self.passiveTimer or 1
  animator.setGlobalTag("weaponDirective", "")
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
    if self.temperature > 0 then
      self.temperature = self.temperature - (5 * dt)
    elseif self.temperature < 0 then
      self.temperature = 0
    end
  end
  
  if not config.getParameter("tooltipFields") then
    activeItem.setInstanceValue("tooltipFields", {})
  end
  local tooltipFields = config.getParameter("tooltipFields")
  tooltipFields.ammo1Label = config.getParameter(self.ammoCountName)
  activeItem.setInstanceValue("tooltipFields", tooltipFields)
  
  animator.setGlobalTag("temperature", self.temperature)
  if self.stances.fire.animationStates then
    if ((self.temperature > 15) or animator.animationState("firing") == "fire") and not self.stances.fire.animationStates.barrelSmoke then
      animator.burstParticleEmitter("barrelSmoke")
    end
  elseif ((self.temperature > 15) or animator.animationState("firing") == "fire") then
    animator.burstParticleEmitter("barrelSmoke")
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then
    
    if not config.getParameter(self.ammoCountName) then
      activeItem.setInstanceValue(self.ammoCountName, config.getParameter(self.ammoMaxName))
    end
    if self.reloadType ~= "passive" then
      if config.getParameter(self.ammoCountName) <= 0 and ( world.entityType(activeItem.ownerEntityId()) ~= "player" or self.reloadwithattack ) or shiftHeld then
        if self.reloadType == "single" and config.getParameter(self.ammoCountName) < config.getParameter(self.ammoMaxName) or self.infMag then
          self:setState(self.reloadSingle)
        elseif self.reloadType == "most" and config.getParameter(self.ammoCountName) < config.getParameter(self.ammoMaxName) then
          self:setState(self.reloadMost)
        elseif config.getParameter(self.ammoCountName) < config.getParameter(self.ammoMaxName) then
          self:setState(self.reload)
        end
      elseif not config.getParameter("postFire") then
        self:setState(self.postFireState)
      end
    elseif not config.getParameter("postFire") and config.getParameter(self.ammoCountName) > 0 then
      self:setState(self.postFireState)
    end
  end
  
  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    

    if config.getParameter(self.ammoCountName) <= 0 and ( world.entityType(activeItem.ownerEntityId()) ~= "player" or self.reloadwithattack ) or shiftHeld then elseif config.getParameter(self.ammoCountName) >= (0 + self.ammoCost) then
      if self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
        self:setState(self.auto)
      elseif self.fireType == "burst" then
        self:setState(self.burst)
      end
    end
  elseif not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    if self.reloadType == "passive" and config.getParameter(self.ammoCountName) <= (config.getParameter(self.ammoMaxName) - 1) then
      if passiveTimer > 0 then
        passiveTimer = passiveTimer - (1 * dt)
      else
        passiveTimer = self.passiveTimer or 1
        self:changeAmmoCount(1, "add", self.ammoMaxName, self.ammoCountName)
      end
    end
  end
end

function GunFire:auto()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GunFire:burst()
  self.weapon:setStance(self.stances.fire)

  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    self:fireProjectile()
    self:muzzleFlash()
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

    util.wait(self.burstTime)
  end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function GunFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)

  if self.stances.postFire1 then
    activeItem.setInstanceValue("postFire", false)
    if self.autoPostFire then
      self:setState(self.postFireState)
    end
  end

end

function GunFire:postFireState()
  local finish = false
  local currentStep = 0
  if not self.stances["postFire1"] then
    finish = true
  end

  while not finish do
    currentStep = currentStep + 1
    if self.stances[string.format("postFire%s", currentStep)] then
      self.weapon:setStance(self.stances[string.format("postFire%s", currentStep)])
      self.weapon:updateAim()
      if self.stances[string.format("postFire%s", currentStep)] then
        if self.stances[string.format("postFire%s", currentStep)].duration then
          util.wait(self.stances[string.format("postFire%s", currentStep)].duration)
        end
      end
    else
      finish = true
    end
  end

  activeItem.setInstanceValue("postFire", true)
end

function GunFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  self:changeAmmoCount((self.stances.ammoCost or self.ammoCost or 1), "remove", self.ammoMaxName, self.ammoCountName)
  if not (self.temperature >= 50) then
    self.temperature = self.temperature + ((self.stances.fire.temp or 25) * script.updateDt())
  else
    self.temperature = self.temperature - ( (1 * params.power) )
  end

  return projectileId
end

function GunFire:firePosition()
  if self.projectileOffset then
    return vec2.add(mcontroller.position(), vec2.add(activeItem.handPosition(self.weapon.muzzleOffset), self.projectileOffset))
  end
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()
  local ammoCost = (config.getParameter(self.ammoMaxName, 1) - (self.stances.ammoCost or 1))
  return (self.baseDamage or (self.baseDps / (ammoCost / (ammoCost*(8/ammoCost) ) ) ) ) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function GunFire:reload()
    status.setResourcePercentage("energyRegenBlock", 1.0)
    if status.resource("energy") == status.resourceMax("energy") then
      status.setResource("energy", status.resource("energy")-1)
    end
    status.setResourceLocked("energy", true)
    local wasEmpty = false
    if config.getParameter(self.ammoCountName) == 0 then
      wasEmpty = true
    end
    local finish = false
    local currentStep = 0
    
    if self.stances["emptyToReload1"] and wasEmpty then
      finish = false
      currentStep = 0
      while not finish do
        currentStep = currentStep + 1
        self.weapon:setStance(self.stances[string.format("emptyToReload%s", currentStep)])

        if self.stances[string.format("emptyToReload%s", currentStep)].weaponDirective then
          animator.setGlobalTag("weaponDirective", self.stances[string.format("emptyToReload%s", currentStep)].weaponDirective)
        else
          animator.setGlobalTag("weaponDirective", "")
        end

        self.weapon:updateAim()
        if self.stances[string.format("emptyToReload%s", currentStep)] then
            if self.stances[string.format("emptyToReload%s", currentStep)].duration then
                util.wait(self.stances[string.format("emptyToReload%s", currentStep)].duration)
            end
        end

        if not self.stances[string.format("emptyToReload%s", currentStep + 1)] then
          finish = true
        end
      end
    end

    if self.stances["reload1"] then
      finish = false
      currentStep = 0
      while not finish do
          currentStep = currentStep + 1
          self.weapon:setStance(self.stances[string.format("reload%s", currentStep)])

          if self.stances[string.format("reload%s", currentStep)].weaponDirective then
            animator.setGlobalTag("weaponDirective", self.stances[string.format("reload%s", currentStep)].weaponDirective)
          else
            animator.setGlobalTag("weaponDirective", "")
          end

          self.weapon:updateAim()
          if self.stances[string.format("reload%s", currentStep)] then
              if self.stances[string.format("reload%s", currentStep)].duration then
                  util.wait(self.stances[string.format("reload%s", currentStep)].duration)
              end
          end

          if not self.stances[string.format("reload%s", currentStep + 1)] then
            finish = true
          end
      end
    end

    if world.entityType(activeItem.ownerEntityId()) == "player" then
        if self.ammoType and not player.isAdmin() then
            local ammoDescriptor = {
                name = self.ammoType,
                parameters = self.ammoParam or {},
                count = config.getParameter(self.ammoMaxName)
            }
            if player.consumeItem(ammoDescriptor,false,true) then
                self:changeAmmoCount(config.getParameter(self.ammoMaxName), "set", self.ammoMaxName, self.ammoCountName)
            end
        else
          self:changeAmmoCount(config.getParameter(self.ammoMaxName), "set", self.ammoMaxName, self.ammoCountName)
        end
    else
      self:changeAmmoCount(config.getParameter(self.ammoMaxName), "set", self.ammoMaxName, self.ammoCountName)
    end
    
    if self.stances["reloadAfterEmpty1"] and wasEmpty then
      finish = false
      currentStep = 0
      while not finish do
        currentStep = currentStep + 1
        self.weapon:setStance(self.stances[string.format("reloadAfterEmpty%s", currentStep)])

        if self.stances[string.format("reloadAfterEmpty%s", currentStep)].weaponDirective then
          animator.setGlobalTag("weaponDirective", self.stances[string.format("reloadAfterEmpty%s", currentStep)].weaponDirective)
        else
          animator.setGlobalTag("weaponDirective", "")
        end

        self.weapon:updateAim()
        if self.stances[string.format("reloadAfterEmpty%s", currentStep)] then
            if self.stances[string.format("reloadAfterEmpty%s", currentStep)].duration then
                util.wait(self.stances[string.format("reloadAfterEmpty%s", currentStep)].duration)
            end
        end

        if not self.stances[string.format("reloadAfterEmpty%s", currentStep + 1)] then
          finish = true
        end
      end
    end

    if config.getParameter("postFireOnReload") then
      self:setState(self.postFireState)
    end
    status.setResourcePercentage("energyRegenBlock", 0.0)
    status.setResourceLocked("energy", false)
    animator.setGlobalTag("weaponDirective", "")
end

function GunFire:reloadMost()
  status.setResourcePercentage("energyRegenBlock", 1.0)
  if status.resource("energy") == status.resourceMax("energy") then
    status.setResource("energy", status.resource("energy")-1)
  end
  status.setResourceLocked("energy", true)
  
  local wasEmpty = false
  if config.getParameter(self.ammoCountName) == 0 then
    wasEmpty = true
  end
  local finish = false
  local currentStep = 0
  if self.stances["emptyToReload1"] and wasEmpty then
    finish = false
    currentStep = 0
    while not finish do
      currentStep = currentStep + 1
      self.weapon:setStance(self.stances[string.format("emptyToReload%s", currentStep)])

      if self.stances[string.format("emptyToReload%s", currentStep)].weaponDirective then
        animator.setGlobalTag("weaponDirective", self.stances[string.format("emptyToReload%s", currentStep)].weaponDirective)
      else
        animator.setGlobalTag("weaponDirective", "")
      end

      self.weapon:updateAim()
      if self.stances[string.format("emptyToReload%s", currentStep)] then
          if self.stances[string.format("emptyToReload%s", currentStep)].duration then
              util.wait(self.stances[string.format("emptyToReload%s", currentStep)].duration)
          end
      end

      if not self.stances[string.format("emptyToReload%s", currentStep + 1)] then
        finish = true
      end
    end
  end

  if self.stances["reload1"] then
    finish = false
    currentStep = 0
    while not finish do
        currentStep = currentStep + 1
        self.weapon:setStance(self.stances[string.format("reload%s", currentStep)])

        if self.stances[string.format("reload%s", currentStep)].weaponDirective then
          animator.setGlobalTag("weaponDirective", self.stances[string.format("reload%s", currentStep)].weaponDirective)
        else
          animator.setGlobalTag("weaponDirective", "")
        end

        self.weapon:updateAim()
        if self.stances[string.format("reload%s", currentStep)] then
            if self.stances[string.format("reload%s", currentStep)].duration then
                util.wait(self.stances[string.format("reload%s", currentStep)].duration)
            end
        end

        if not self.stances[string.format("reload%s", currentStep + 1)] then
          finish = true
        end
    end
  end

  if world.entityType(activeItem.ownerEntityId()) == "player" then
      if self.ammoType and not player.isAdmin() then
          local ammoDescriptor = {
              name = self.ammoType,
              parameters = self.ammoParam or {},
              count = (config.getParameter(self.ammoMaxName) - config.getParameter(self.ammoCountName))
          }
          local playerAmmo = player.hasCountOfItem(ammoDescriptor, true)
          if playerAmmo < ammoDescriptor["count"] then
            ammoDescriptor["count"] = playerAmmo
          end
          if player.consumeItem(ammoDescriptor,true,true) then
              self:changeAmmoCount(ammoDescriptor["count"], "add", self.ammoMaxName, self.ammoCountName)
          end
      else
        self:changeAmmoCount((config.getParameter(self.ammoMaxName) - config.getParameter(self.ammoCountName)), "add", self.ammoMaxName, self.ammoCountName)
      end
  else
    self:changeAmmoCount((config.getParameter(self.ammoMaxName) - config.getParameter(self.ammoCountName)), "add", self.ammoMaxName, self.ammoCountName)
  end

  if config.getParameter("postFireOnReload") then
    self:setState(self.postFireState)
  end
  
  if self.stances["reloadAfterEmpty1"] and wasEmpty then
    finish = false
    currentStep = 0
    while not finish do
      currentStep = currentStep + 1
      self.weapon:setStance(self.stances[string.format("reloadAfterEmpty%s", currentStep)])

      if self.stances[string.format("reloadAfterEmpty%s", currentStep)].weaponDirective then
        animator.setGlobalTag("weaponDirective", self.stances[string.format("reloadAfterEmpty%s", currentStep)].weaponDirective)
      else
        animator.setGlobalTag("weaponDirective", "")
      end

      self.weapon:updateAim()
      if self.stances[string.format("reloadAfterEmpty%s", currentStep)] then
          if self.stances[string.format("reloadAfterEmpty%s", currentStep)].duration then
              util.wait(self.stances[string.format("reloadAfterEmpty%s", currentStep)].duration)
          end
      end

      if not self.stances[string.format("reloadAfterEmpty%s", currentStep + 1)] then
        finish = true
      end
    end
  end
  status.setResourcePercentage("energyRegenBlock", 0.0)
  status.setResourceLocked("energy", false)
end

function GunFire:reloadSingle()
  status.setResourcePercentage("energyRegenBlock", 1)
  if status.resource("energy") == status.resourceMax("energy") then
    status.setResource("energy", status.resource("energy")-1)
  end
  status.setResourceLocked("energy", true)
  local wasEmpty = false
  if config.getParameter(self.ammoCountName) == 0 then
    wasEmpty = true
  end
  local finish = false
  local currentStep = 0
  
  if self.stances["emptyToReload1"] and wasEmpty then
    while not finish do
      currentStep = currentStep + 1
      self.weapon:setStance(self.stances[string.format("emptyToReload%s", currentStep)])

      if self.stances[string.format("emptyToReload%s", currentStep)].weaponDirective then
        animator.setGlobalTag("weaponDirective", self.stances[string.format("emptyToReload%s", currentStep)].weaponDirective)
      else
        animator.setGlobalTag("weaponDirective", "")
      end

      self.weapon:updateAim()
      if self.stances[string.format("emptyToReload%s", currentStep)] then
          if self.stances[string.format("emptyToReload%s", currentStep)].duration then
              util.wait(self.stances[string.format("emptyToReload%s", currentStep)].duration)
          end
      end

      if not self.stances[string.format("emptyToReload%s", currentStep + 1)] then
        if self.emptyToReloadAddAmmo then
          if world.entityType(activeItem.ownerEntityId()) == "player" then
            if self.ammoType and not player.isAdmin() then
                local ammoDescriptor = {
                    name = self.ammoType,
                    parameters = self.ammoParam or {},
                    count = 1
                }
                if player.consumeItem(ammoDescriptor,false,true) then
                  self:changeAmmoCount(1, "add", self.ammoMaxName, self.ammoCountName)
                end
            else
              self:changeAmmoCount(1, "add", self.ammoMaxName, self.ammoCountName)
            end
          else
            self:changeAmmoCount(1, "add", self.ammoMaxName, self.ammoCountName)
          end
        end

        finish = true
      end
    end
  end

  if wasEmpty then
    if self.fireMode == (self.activatingFireMode or self.abilitySlot) and (config.getParameter(self.ammoCountName) < config.getParameter(self.ammoMaxName) or self.infMag) then
      finish = false
    end
  end
  if self.stances["reload1"] then
    currentStep = 0
    while not finish do
      currentStep = currentStep + 1
      self.weapon:setStance(self.stances[string.format("reload%s", currentStep)])
      self.weapon:updateAim()
      
      if self.stances[string.format("reload%s", currentStep)].weaponDirective then
        animator.setGlobalTag("weaponDirective", self.stances[string.format("reload%s", currentStep)].weaponDirective)
      else
        animator.setGlobalTag("weaponDirective", "")
      end

      if self.stances[string.format("reload%s", currentStep)] then
        if self.stances[string.format("reload%s", currentStep)].duration then
          util.wait(self.stances[string.format("reload%s", currentStep)].duration)
        end
      end

      if not self.stances[string.format("reload%s", currentStep + 1)] then
        status.setResourcePercentage("energyRegenBlock", 0.25)
        if world.entityType(activeItem.ownerEntityId()) == "player" then
          if self.ammoType and not player.isAdmin() then
              local ammoDescriptor = {
                  name = self.ammoType,
                  parameters = self.ammoParam or {},
                  count = 1
              }
              if player.consumeItem(ammoDescriptor,false,true) then
                self:changeAmmoCount(1, "add", self.ammoMaxName, self.ammoCountName)
              end
          else
            self:changeAmmoCount(1, "add", self.ammoMaxName, self.ammoCountName)
          end
        else
          self:changeAmmoCount(1, "add", self.ammoMaxName, self.ammoCountName)
        end

        if self.fireMode == (self.activatingFireMode or self.abilitySlot) and (config.getParameter(self.ammoCountName) < config.getParameter(self.ammoMaxName) or self.infMag) then
          currentStep = 0
        else
          finish = true
        end
      end
    end
  end

  if self.stances["reloadAfterEmpty1"] and wasEmpty then
    finish = false
    currentStep = 0
    while not finish do
      currentStep = currentStep + 1
      self.weapon:setStance(self.stances[string.format("reloadAfterEmpty%s", currentStep)])

      if self.stances[string.format("reloadAfterEmpty%s", currentStep)].weaponDirective then
        animator.setGlobalTag("weaponDirective", self.stances[string.format("reloadAfterEmpty%s", currentStep)].weaponDirective)
      else
        animator.setGlobalTag("weaponDirective", "")
      end

      self.weapon:updateAim()
      if self.stances[string.format("reloadAfterEmpty%s", currentStep)] then
          if self.stances[string.format("reloadAfterEmpty%s", currentStep)].duration then
              util.wait(self.stances[string.format("reloadAfterEmpty%s", currentStep)].duration)
          end
      end

      if not self.stances[string.format("reloadAfterEmpty%s", currentStep + 1)] then
        finish = true
      end
    end
  end
  status.setResourcePercentage("energyRegenBlock", 0.0)
  status.setResourceLocked("energy", false)
end

function GunFire:changeAmmoCount(value, mode, paramNameMax, paramNameCount)
  local math
  if mode == "set" then
    math = value
    activeItem.setInstanceValue(paramNameCount, value)
  elseif mode == "add" then
    math = config.getParameter(paramNameCount) + value
    if math > config.getParameter(paramNameMax) and not self.infMag then
      math = config.getParameter(paramNameMax)
    end
    activeItem.setInstanceValue(paramNameCount, math)
  elseif mode == "remove" then
    math = config.getParameter(paramNameCount) - value
    if math < 0 then
      math = 0
    end
    activeItem.setInstanceValue(paramNameCount, math)
  end
  
  -- durability bar rendering logic is weird... 
  -- depending on if it a tool or activeitem it logic change
  activeItem.setInstanceValue("durabilityHit", -math)
end

function GunFire:uninit()
  animator.setGlobalTag("weaponDirective", "")
end