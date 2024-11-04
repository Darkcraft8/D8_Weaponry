require("/shared/darkcraft8/machinery/V0_0_1/object/machinery/utils/resource.lua")
-- Need to ask Sva if im allowed to make a compac script on my end to allow to transfer power/energy from/to Arcana Power Script

-- Compact for Arcana Power Script and D8Machinery


function D8Machinery:useArcana_Power(entityId)
    --local useD8Machinery = world.callScriptedEntity(entityId, "D8Machinery.useD8Machinery") --Call the D8Machinery Check Function
    --local useArcana_Power = world.callScriptedEntity(entityId, "arcana_power.getPower") --Call getPower from arcana_power Function

    if useD8Machinery then return false end
    if useArcana_Power then return true end
    return false
end

function D8Machinery:compactBuild()
    --if not checkList then checkList = {} end
    --table.insert(checkList, "D8Machinery.useArcana_Power")
end
