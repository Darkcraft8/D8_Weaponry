require("/WIP/catenary_ObjectTest/catenaryUtil.lua")
require("/WIP/catenary_ObjectTest/bridgeUtil.lua")
require("/scripts/vec2.lua")
require("/scripts/util.lua")

bridgeConfig = {}
function init()
    bridgeConfig = config.getParameter("bridgeConfig", {})
    storage.collisionEntityId = storage.collisionEntityId or {}
end

function update()
    local startPosition = object.position()
    local endPosition = findPole(bridgeConfig.outputNodeId)
    if endPosition then
        if self.prevEndPosition then 
            if sb.printJson(endPosition) == sb.printJson(self.prevEndPosition) then return end
        end

        local animatorConfig = {
            parts = bridgeConfig.parts,
            startPosition = startPosition,
            endPosition = endPosition
        }
            
        object.setConfigParameter("animatorConfig", animatorConfig)
        resetCollision()
        for index, value in ipairs(endPosition) do
            setCollision(startPosition, value, index)
        end
        self.prevEndPosition = endPosition
    else
        resetCollision()
        self.prevEndPosition = nil
        object.setConfigParameter("animatorConfig", nil)
    end
end

function isBridgePole()
    return true
end

function getPartConfig()
    --sb.logInfo("Giving parts config %s", bridgeConfig.parts)
    return bridgeConfig.parts
end

function findPole(nodeId)
    local nodeId = nodeId or 0
    local endPosition = {}
    if object.isOutputNodeConnected(nodeId) then
        local connectedObject = object.getOutputNodeIds(nodeId)
        for targetEntityId, _ in pairs(connectedObject) do
            if world.callScriptedEntity(targetEntityId, "isBridgePole") then
                local pos = world.callScriptedEntity(targetEntityId, "object.position")
                if pos then
                    table.insert(endPosition, pos)
                end
            end
        end
    end
    if endPosition[1] then
        return endPosition
    else
        return false
    end
end
function uninit()
    resetCollision()
end

function resetCollision()
    if storage.collisionEntityId then
        for _, id in ipairs(storage.collisionEntityId) do
            if world.entityExists(id) then
                world.callScriptedEntity(id, "dismiss")
            end
        end
        storage.collisionEntityId = {}
    end
end

function setCollision(startPosition, endPosition, index, old)
    --sb.logInfo("%s", vec2.sub(endPosition, startPosition))
    --sb.logInfo("%s", param.physicsCollisions.platform.collision)
    --sb.logInfo("%s", startPosition)
    --sb.logInfo("%s", endPosition)
    --local old = true
    if startPosition and endPosition then
        for index, parts in ipairs(bridgeConfig.parts) do
            if parts.collisionKind then
                local path = calculatePath(startPosition, endPosition, nil, parts.offset)
                for index, pos in ipairs(path or {}) do --Make the brigde segmented because the game vehicle collision is a box
                    local param = {
                        physicsCollisions = {
                            platform = {
                                collision = {
                                    {0, 0},
                                    {0, 0}
                                },
                                collisionKind = collisionKind
                            }
                        }
                    }
                    if path[index+1] then -- set collision end to next pos
                        param.physicsCollisions.platform.collision[2] = vec2.sub(path[index+1], pos)
                    end

                    local entityPos = vec2.add(object.position(), pos or {0, 0})
                        
                    local entityId = world.spawnVehicle("d8Weaponry_bridgeCollisionEntity", entityPos, param)
                    table.insert(storage.collisionEntityId, entityId)
                end
            end
        end
    end
end