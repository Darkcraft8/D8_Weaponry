-- Function for Machine Resources

D8Machinery_resourceUtil = {}
function D8Machinery_resourceUtil:setResource(resourceCfg)
    D8Machinery.scriptConfig.resources[resourceCfg.resource] = resourceCfg.count
end

function D8Machinery_resourceUtil:addResource(resourceCfg)
    if D8Machinery_resourceUtil:getResource(resourceCfg.resource) then
        if D8Machinery_resourceUtil:getResource(resourceCfg.resource) + resourceCfg.count > (D8Machinery_resourceUtil:getMaxResource(resourceCfg.resource) or 1000) then
            D8Machinery_resourceUtil:setResource({resource = resourceCfg.resource, count = D8Machinery_resourceUtil:getMaxResource(resourceCfg.resource) or 1000})
            return (D8Machinery_resourceUtil:getResource(resourceCfg.resource) + resourceCfg.count) - (D8Machinery_resourceUtil:getMaxResource(resourceCfg.resource) or 1000)
        else
            D8Machinery_resourceUtil:setResource({resource = resourceCfg.resource, count = D8Machinery_resourceUtil:getResource(resourceCfg.resource) + resourceCfg.count})
            return 0
        end
    else
        return resourceCfg.count
    end
end

function D8Machinery_resourceUtil:addResources(resourceTable)
    for _, v in ipairs(resourceTable) do
        D8Machinery_resourceUtil:addResource(v)
    end
end

function D8Machinery_resourceUtil:removeResource(resourceCfg)
    if D8Machinery_resourceUtil:getResource(resourceCfg.resource) then
        if D8Machinery_resourceUtil:getResource(resourceCfg.resource) - resourceCfg.count < 0 then
            D8Machinery_resourceUtil:setResource({resource = resourceCfg.resource, count = 0})

            return math.abs(D8Machinery_resourceUtil:getResource(resourceCfg.resource) - resourceCfg.count), false
        else
            D8Machinery_resourceUtil:setResource({resource = resourceCfg.resource, count = D8Machinery_resourceUtil:getResource(resourceCfg.resource) - resourceCfg.count})
            return D8Machinery_resourceUtil:getResource(resourceCfg.resource), true
        end
    else
        return resourceCfg.count
    end
end

function D8Machinery_resourceUtil:removeResources(resourceTable)
    local consumedAllResources = true
    for _, v in ipairs(resourceTable) do
        local amount, boolean = D8Machinery_resourceUtil:removeResource(v)
        consumedAllResources = boolean
    end
    return consumedAllResources
end

function D8Machinery_resourceUtil:getResource(resourceName)
    return D8Machinery.scriptConfig.resources[resourceName]
end

function D8Machinery_resourceUtil:getMaxResource(resourceName)
    return D8Machinery.scriptConfig.maxResources[resourceName]
end

function D8Machinery_resourceUtil:getResources(resourceTable)
    local Resources = {}
    for _, v in ipairs(resourceTable) do        
        local resourceValue = D8Machinery_resourceUtil:getResource(v.resource)
        Resources[v.resource] = resourceValue
    end
    return Resources
end

function D8Machinery_resourceUtil:hasResources(resourceTable, countOverride) --return true if the requested resources are present
    if not resourceTable then return false end
    if type(resourceTable) ~= "table" then return false end

    for i, v in ipairs(resourceTable) do
        if D8Machinery_resourceUtil:getResource(v.resource) < (countOverride or v.count) then return false end
    end
    return true
end

function D8Machinery_resourceUtil:hasSpaceForResource(resourceCfg)
    local currentResourceAmount = D8Machinery_resourceUtil:getResource(resourceCfg.resource)
    local maxResourceCapacity = D8Machinery_resourceUtil:getMaxResource(resourceCfg.resource)
    
    if not currentResourceAmount or not maxResourceCapacity then return false end
    if currentResourceAmount + resourceCfg.count > maxResourceCapacity then return false end
    return true
end

function D8Machinery_resourceUtil:hasSpaceForResources(resourceTable)
    for _, resourceCfg in ipairs(resourceTable) do 
        if not D8Machinery_resourceUtil:hasSpaceForResource(resourceCfg) then return false end
    end
    return true
end