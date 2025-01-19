-- Utils for output/input node functions

D8Machinery_node = {}
function D8Machinery_node:sendResource(resourceCfg, entityId)
    D8Machinery_node:sendResources({resourceCfg}, entityId)
end

function D8Machinery_node:sendResources(resourceTable, entityId)
    local nodeIds = entityId or object.getOutputNodeIds(D8Machinery_node:getResourceOutputNode())
    for _, resourceCfg in ipairs(resourceTable) do
        if type(nodeIds) == "number" then

        else
            local validTarget = self:findValidResourceTarget(resourceCfg)
            local targetAmount = self:targetAmount(validTarget)
            local sentAmount = resourceCfg.count / targetAmount

            for id, node in pairs(validTarget or {}) do
                local overflow = world.callScriptedEntity(id, "D8Machinery_resourceUtil.addResource", nil, {resource = resourceCfg.resource, count = sentAmount})
                D8Machinery_resourceUtil:removeResource({resource = resourceCfg.resource, count = (sentAmount - overflow)})
            end
        end
    end
end

function D8Machinery_node:findValidResourceTarget(resourceCfg)
    local possibleTarget = object.getOutputNodeIds(D8Machinery_node:getResourceOutputNode())
    local validTarget = nil
    local fillToMax = resourceCfg.fillToMax or false

    for id, node in pairs(possibleTarget) do
        local hasSpaceForResource = false
        if not fillToMax then
            hasSpaceForResource = world.callScriptedEntity(id, "D8Machinery_resourceUtil.hasSpaceForResource", nil, resourceCfg)
        else
            local resourceAmount = world.callScriptedEntity(id, "D8Machinery_resourceUtil.getResource", nil, resourceCfg.resource)
            local resourceAmountMax = world.callScriptedEntity(id, "D8Machinery_resourceUtil.getMaxResource", nil, resourceCfg.resource)
            hasSpaceForResource = resourceAmount < resourceAmountMax
        end
        
        if hasSpaceForResource then
            if not validTarget then validTarget = {} end
            validTarget[id] = node
        end
    end

    return validTarget
end

function D8Machinery_node:hasConnectedObjectToInputNode()
    if not object.getOutputNodeIds(D8Machinery_node:getResourceInputNode())[1] then return false else return true end
end

function D8Machinery_node:hasConnectedObjectToOutputNode()
    if not object.getOutputNodeIds(D8Machinery_node:getResourceOutputNode())[1] then return false else return true end
end

function D8Machinery_node:targetAmount(targetArray)
    local targetAmount = 0
    for _, _ in pairs(targetArray) do
        targetAmount = targetAmount + 1
    end

    return targetAmount
end

function D8Machinery_node:getResourceOutputNode()
    return D8Machinery.scriptConfig.node.resourceOutput or 0
end
function D8Machinery_node:getResourceInputNode()
    return D8Machinery.scriptConfig.node.resourceInput or 0
end

function D8Machinery_node:getItemOutputNode()
    return D8Machinery.scriptConfig.node.itemOutput or 0
end
function D8Machinery_node:getItemInputNode()
    return D8Machinery.scriptConfig.node.itemInput or 0
end