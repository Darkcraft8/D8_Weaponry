-- Json Parameters Powered Behavior Based Active Item 
-- JPPBBAI >:D
newJPPBBAI = {}
function newJPPBBAI:new(itemCfg)
    local newItem = itemCfg or {}

    newItem.elementalType = config.getParameter("elementalType", "physical")
    newItem.behaviorState = config.getParameter("initBehavior", "idle")
    newItem.behaviorCfg = config.getParameter("behaviorCfg", {})
    setmetatable(newItem, extend(self))
    return newItem
end

function newJPPBBAI:init()

end

function newJPPBBAI:update(dt, fireMode, isShiftHeld, currentMoveCfg)

end

function newJPPBBAI:uninit()

end
