-- why ins't there a actionOnHit with piercing projectiles ?

function hit(hitEntity)
    local actionOnPierce = projectile.getParameter("actionOnPierce")
    if actionOnPierce and projectile.getParameter("piercing") then
        projectile.processAction(actionOnPierce)
    end
end