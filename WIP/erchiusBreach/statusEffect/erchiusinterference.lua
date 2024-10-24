local energyRegenDone_soundTimer = 0
function init()
    effect.addStatModifierGroup({{stat = "maxEnergy", effectiveMultiplier = config.getParameter("energyModifier", 2)}})
    status.setResourcePercentage("energyRegenBlock", 1)
    status.setResourcePercentage("energy", status.resourcePercentage("energy") / config.getParameter("energyModifier", 2))
end

function update(dt)
    local energy = status.resourcePercentage("energy")
    local maxPercent = config.getParameter("maxEnergyRegen", 0.15) / config.getParameter("energyModifier", 2)
    if energy >= maxPercent then
        status.setResourcePercentage("energyRegenBlock", 1)
    end
    local diff = math.abs( energy - ( (config.getParameter("maxEnergyRegen", 0.01)/2) ) )
    if diff <= 0.003 and status.resourceLocked("energy") then
        status.setResourceLocked("energy", false)
        if energyRegenDone_soundTimer <= 0 then
            animator.playSound("energyRegenDone")
            energyRegenDone_soundTimer = 2
        end
    end
    if energyRegenDone_soundTimer > 0 then
        energyRegenDone_soundTimer = energyRegenDone_soundTimer - dt
    end
end

function uninit()
    status.setResourcePercentage("energy", status.resourcePercentage("energy") * config.getParameter("energyModifier", 2))
end