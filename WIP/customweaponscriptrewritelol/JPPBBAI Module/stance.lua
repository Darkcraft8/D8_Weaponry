require "/scripts/util.lua"
require "/scripts/vec2.lua"
stance = {}

function stance:setStance(stanceCfg)
    self:setAimAngleAndDirection(stanceCfg)
    activeItem.setFrontArmFrame(stanceCfg.frontArmFrame)
    activeItem.setBackArmFrame(stanceCfg.backArmFrame)
    activeItem.setTwoHandedGrip(stanceCfg.twoHanded)
    activeItem.setOutsideOfHand(stanceCfg.outsideHand)
    activeItem.setHoldingItem(stanceCfg.holdItem)
end

function stance:setAimAngleAndDirection(stanceCfg)
    local allowRotate = stanceCfg.allowRotate
    local allowFlip = stanceCfg.allowFlip
    local aimOffset = aimOffset
    local aimAngle, aimDirection
    if allowRotate then
        if allowFlip then
            aimAngle, aimDirection = activeItem.aimAngleAndDirection(aimOffset[2], activeItem.ownerAimPosition())
        else
            aimAngle = activeItem.aimAngle(aimOffset[2], activeItem.ownerAimPosition())
        end
    end
    if aimAngle then 
        activeItem.setArmAngle(armAngle)
    end
    if aimDirection then
        activeItem.setFacingDirection(aimDirection)
    end
    
end