require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"
require "/D8Weaponry/activeitem/ranged/d8weap_gunfire_fork.lua"

AltFireAttack = GunFire:new()

function AltFireAttack:new(abilityConfig)
  local primary = config.getParameter("primaryAbility")
  return GunFire.new(self, sb.jsonMerge(primary, abilityConfig))
end

function AltFireAttack:init()
  self.cooldownTimer = self.fireTime
end

function AltFireAttack:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  local tooltipFields = config.getParameter("tooltipFields")
  if tooltipFields.ammo2Label then
    tooltipFields.ammo2Label = config.getParameter(self.ammoCountName)
    activeItem.setInstanceValue("tooltipFields", tooltipFields)
  end

  if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then
    
    if not config.getParameter(self.ammoCountName) then
      activeItem.setInstanceValue(self.ammoCountName, config.getParameter(self.ammoMaxName))
    end
    if config.getParameter(self.ammoCountName) <= 0 and self.reloadwithattack or shiftHeld then
        if self.reloadType == "singleAmmo" then
            if config.getParameter(self.ammoCountName) < config.getParameter(self.ammoMaxName) or self.infMag then
                self:setState(self.reloadSingle)
            end
        else
            if config.getParameter(self.ammoCountName) < config.getParameter(self.ammoMaxName) then
                self:setState(self.reload)
            end
        end
    elseif not config.getParameter("postFire") then
      self:setState(self.postFireState)
    end
  end
  
  if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    
    if config.getParameter(self.ammoCountName) <= 0 and self.reloadwithattack or shiftHeld then elseif config.getParameter(self.ammoCountName) >= (0 + self.ammoCost) then
        if self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
            self:setState(self.auto)
        elseif self.fireType == "burst" then
            self:setState(self.burst)
        end
    end
  elseif not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    if self.reloadType == "passive" then
      if passiveTimer > 0 then
        passiveTimer = passiveTimer - (1 * dt)
      else
        passiveTimer = self.passiveTimer or 1
        self:changeAmmoCount(1, "add", self.ammoMaxName, self.ammoCountName)
      end
    end
  end
end

function AltFireAttack:muzzleFlash()
  if not self.hidePrimaryMuzzleFlash then
    animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
    animator.setAnimationState("firing", "fire")
    animator.setLightActive("muzzleFlash", true)
  end
  
  if self.useParticleEmitter == nil or self.useParticleEmitter then
    animator.burstParticleEmitter("altMuzzleFlash", true)
  end

  if self.usePrimaryFireSound then
    animator.playSound("fire")
  else
    animator.playSound("altFire")
  end
end

function AltFireAttack:firePosition()
  if self.firePositionPart then
    return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint(self.firePositionPart, "firePosition")))
  else
    return GunFire.firePosition(self)
  end
end

function AltFireAttack:changeAmmoCount(value, mode, paramNameMax, paramNameCount)
    local math
    if mode == "set" then
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
    
end