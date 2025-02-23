require "/scripts/vec2.lua"

local _init = init
local _uninit = uninit
local canvas = nil
function init()
    if _init then _init() end
    if interface.bindCanvas then
        -- just here to get the mouse position from the user interface instead of the parent pane to avoid a few occuring issue... only work with openStarbound
        canvas = interface.bindCanvas("d8Tooltip")
    end
    if pane.setPosition then
        local cursorPos = player.getProperty("d8TooltipUtilCursorPos")
        if canvas then
            cursorPos = canvas:mousePosition()
        end
        local offset = player.getProperty("d8TooltipUtil_offset")
        local newPos = vec2.sub(cursorPos, offset)
        pane.setPosition(newPos)
    end
    --sb.logInfo("tooltip T100 Initiated, Prepare to code")
    player.setProperty("d8TooltipUtilOpen", true)-- say that a tooltip is open
    for _, cfg in pairs(config.getParameter("itemSlotList", {})) do
        widget.setItemSlotItem(cfg.path, cfg.item)
    end
    
end

function update()
    if not player.getProperty("d8TooltipUtilOpen") then pane.dismiss() end
    if pane.setPosition then
        local cursorPos = player.getProperty("d8TooltipUtilCursorPos")
        local screenSize
        if canvas then
            cursorPos = canvas:mousePosition()
        end
        local offset = player.getProperty("d8TooltipUtil_offset")
        local newPos = vec2.sub(cursorPos, offset)
        pane.setPosition(newPos)
    end
end

function uninit()
    if _uninit then _uninit() end
    --sb.logInfo("tooltip T100 uninitiated, Goodbye")
end