require("/shared/darkcraft8/machinery/V0_0_1/object/machinery/utils/node.lua")
require("/shared/darkcraft8/machinery/V0_0_1/object/machinery/utils/resource.lua")

-- Machinery that stock resource logic is here
function D8Machinery:modeInit()
    self:buildStorageMessage()
    self:buildTransferDuration()
    
    self.scriptConfig.transferTable = config.getParameter("scriptConfig.transferTable")
end

--A bunch of message handler meant to be used for Pane... ok so pane "can't" use message...
function D8Machinery:buildStorageMessage()
    
end

function D8Machinery:buildTransferDuration()
    storage.transferDuration = {}
    for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
        storage.transferDuration[resourceCfg.resource] = resourceCfg.speed
    end
end

function D8Machinery:modeLogic(dt)
    self:isAFK()
    self:updatePaneParam(dt)

    for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
        if storage.transferDuration[resourceCfg.resource] > 0 then 
            storage.transferDuration[resourceCfg.resource] = storage.transferDuration[resourceCfg.resource] - dt
        end
    end

    if self:shouldTransfer() then
        if self.hurryUp > 0 then self:hurryUpLogic() end
        for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
            if storage.transferDuration[resourceCfg.resource] <= 0 then
                if D8Machinery_node:findValidResourceTarget(resourceCfg) then D8Machinery_node:sendResource(resourceCfg) end
                storage.transferDuration[resourceCfg.resource] = resourceCfg.speed
            end
        end
    else
        self.hurryUp = 0
    end
end

function D8Machinery:hurryUpLogic()
    if (self.hurryUp or 0) > 0 then
        for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
            self.hurryUp = self.hurryUp - resourceCfg.speed
            storage.transferDuration[resourceCfg.resource] = 0
        end
    end
end

function D8Machinery:shouldTransfer()
    local hasResourcesForOneType = false 
    local hasValidTargetForOneResource = false
    for _, resourceCfg in ipairs(self.scriptConfig.transferTable or {}) do
        if D8Machinery_resourceUtil:hasResources({resourceCfg}) then hasResourcesForOneType = true end
        if D8Machinery_node:findValidResourceTarget(resourceCfg) then hasValidTargetForOneResource = true end
    end

    if hasResourcesForOneType and hasValidTargetForOneResource then
        return true
    else
        return false
    end
end

function D8Machinery:test()
    for name, value in pairs(self.scriptConfig.resources) do
        D8Machinery_resourceUtil:setResource({resource = name, count = D8Machinery_resourceUtil:getMaxResource(name)})
    end
end

