require("/WIP/catenary_ObjectTest/catenaryUtil.lua")
require("/WIP/catenary_ObjectTest/bridgeUtil.lua")
require "/scripts/vec2.lua"
require "/scripts/util.lua"

bridgeConfig = {}
function init()
    bridgeConfig = config.getParameter("bridgeConfig", {})
    --animatorConfig = config.getParameter("animatorConfig")
end

function update()    
    animatorConfig = config.getParameter("animatorConfig")
    if animatorConfig then
        localAnimator.clearDrawables()
        for index, endPosition in pairs(animatorConfig.endPosition) do
            for index, parts in pairs(animatorConfig.parts) do
                if parts.texture then
                    local path = calculatePath(animatorConfig.startPosition, endPosition, nil, parts.offset)
                    for index, pos in ipairs(path) do
                        local drawable = {
                            image = parts.texture,
                            position = vec2.add(vec2.add(animatorConfig.startPosition, pos), parts.offset),
                            color = parts.color or {255,255,255}
                        }
                        --sb.logInfo("%s", sb.printJson(drawable))
                        if index ~= 1 and index ~= #path then
                            localAnimator.addDrawable(drawable, parts.renderLayer or "player+1")
                        end
                    end
                elseif parts.line then
                    local path = calculatePath(animatorConfig.startPosition, endPosition, nil, parts.offset)
                    for index, pos in ipairs(path) do
                        local startPos = vec2.add(animatorConfig.startPosition, pos)
                        local endPos = vec2.add(animatorConfig.startPosition, path[index-1] or pos)

                        if index == 1 then
                            endPos = vec2.add(animatorConfig.startPosition, pos)
                        end

                        local drawable = {
                            line = {startPos, endPos},
                            width = parts.width or 1,
                            color = parts.color or {255,255,255}
                        }
                        --sb.logInfo("%s, %s", index, sb.printJson(drawable))
                        localAnimator.addDrawable(drawable, parts.renderLayer or "object-1")
                    end
                end
            end
        end
    else
        localAnimator.clearDrawables()
    end
end

function drawParts()

end