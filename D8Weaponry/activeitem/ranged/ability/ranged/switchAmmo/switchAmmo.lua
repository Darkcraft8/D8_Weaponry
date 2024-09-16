require "/scripts/util.lua"

SwitchAmmo = WeaponAbility:new()

function SwitchAmmo:init()
    self.currentAmmoType = config.getParameter("currentAmmoType", self.currentAmmoType)
    self.primaryAbility = config.getParameter("primaryAbility")
    self:updateAbility()
end

function SwitchAmmo:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) then
    if shiftHeld then
        if not self.shiftAltAbility then
            self:setState(self.switchAmmoPrevious)
        end
    else
        self:setState(self.switchAmmoNext)
    end
  end
  
  self.lastFireMode = fireMode
end

function SwitchAmmo:switchAmmoNext()
    local finish = false
    local currentStep = 0
    if not self.primaryAbility.stances["reload1"] then
      finish = true
    end

    while not finish do
        currentStep = currentStep + 1
        self.weapon:setStance(self.primaryAbility.stances[string.format("reload%s", currentStep)])
        self.weapon:updateAim()
        if self.primaryAbility.stances[string.format("reload%s", currentStep)] then
            if self.primaryAbility.stances[string.format("reload%s", currentStep)].duration then
                util.wait(self.primaryAbility.stances[string.format("reload%s", currentStep)].duration)
            end
        end

        if not self.primaryAbility.stances[string.format("reload%s", currentStep + 1)] then
          finish = true
        end
    end

    self.currentAmmoType = self.currentAmmoType + 1
    self:updateAbility()
end

function SwitchAmmo:switchAmmoPrevious()
    local finish = false
    local currentStep = 0
    if not self.primaryAbility.stances["reload1"] then
      finish = true
    end

    while not finish do
        currentStep = currentStep + 1
        self.weapon:setStance(self.primaryAbility.stances[string.format("reload%s", currentStep)])
        self.weapon:updateAim()
        if self.primaryAbility.stances[string.format("reload%s", currentStep)] then
            if self.primaryAbility.stances[string.format("reload%s", currentStep)].duration then
                util.wait(self.primaryAbility.stances[string.format("reload%s", currentStep)].duration)
            end
        end

        if not self.primaryAbility.stances[string.format("reload%s", currentStep + 1)] then
          finish = true
        end
    end

    self.currentAmmoType = self.currentAmmoType - 1
    self:updateAbility()
end

function SwitchAmmo:updateAbility()
    local ability = self.weapon.abilities[self.targetAbility]

    if self["ammoSwap"][self.currentAmmoType] then
        concatParam = self["ammoSwap"][self.currentAmmoType]
    else
        self.currentAmmoType = 1
        concatParam = self["ammoSwap"][1]
    end

    util.mergeTable(ability, concatParam["ability"])

    activeItem.setInstanceValue("currentAmmoType", self.currentAmmoType)
    local tooltipFields = config.getParameter("tooltipFields", {})
    tooltipFields.ammo1NameLabel = concatParam["ability"]["ammoName"] or concatParam["ability"]["ammoType"]
    activeItem.setInstanceValue("tooltipFields", tooltipFields)

    if self.changeWeaponryRender then
        activeItem.setInstanceValue("d8Weaponry", concatParam["d8Weaponry"])
    end
    if self.primaryAbility["ammoCountName"] then
        activeItem.setInstanceValue("durabilityHit", -config.getParameter(ability["ammoCountName"], 0))
    end
end

function SwitchAmmo:uninit() end