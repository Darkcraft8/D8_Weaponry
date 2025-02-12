movementControl = {}
function movementControl.controlModifiers(args) -- mostlikely useless to make bridge func for some if not most of these... problably should add a blacklist
    -- runningSuppressed
    --mcontroller.rotate()
    mcontroller.controlModifiers(args)
end

function movementControl.translateAboveGround(args)
    local userPos = world.entityPosition(activeItem.ownerEntityId())
end

-- [controlModifiers Possible Args]
-- movementSuppressed
-- facingSuppressed
-- runningSuppressed
-- jumpingSuppressed