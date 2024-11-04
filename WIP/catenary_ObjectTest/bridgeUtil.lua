require("/WIP/catenary_ObjectTest/catenaryUtil.lua")
require "/scripts/vec2.lua"
require "/scripts/util.lua"

function calculatePath(startPosition, endPosition, segmentDivider, offset) -- create a segmented path because starbound has a limit on entity size
    local path = {}
    local segmentDivider = (segmentDivider or 4)
    local lengthSupression = 0
    local distBetweenPos = distMerge(world.distance(endPosition, startPosition)) / segmentDivider
    local diffBetweenPosVec = vec2.div(world.distance(endPosition, startPosition), segmentDivider)
    if distBetweenPos % 2 ~= 0 then

    end
    local segment = 0
    local endPointTest = copy(startPosition)
    
    endPointTest[1] = endPointTest[1] * segment
    endPointTest[1] = endPointTest[1] * segmentDivider

    if world.distance(endPosition, endPointTest)[1] > 0.1 or world.distance(endPosition, endPointTest)[1] < -0.1 then
        lengthSupression = world.distance(endPosition, endPointTest)[1] / segmentDivider
    end
    local maxSegment = util.round(math.abs(distBetweenPos))
    while segment < maxSegment + 1 do 
        local entityPos = distanceToNextSegment(diffBetweenPosVec, distBetweenPos, segment, segmentDivider)
        --entityPos = catenaryfication(entityPos, segment, maxSegment, diffBetweenPosVec, distBetweenPos)
        if diffBetweenPosVec[1] < 0 then diffBetweenPosVec[1] = (-1) * diffBetweenPosVec[1] end
        --if diffBetweenPosVec[2] < 0 then diffBetweenPosVec[2] = (-1) * diffBetweenPosVec[2] end

        if segment == 0 then
            entityPos = {0,0}
        elseif segment == maxSegment then
            local distBetweenEndpoints = world.distance(endPosition, vec2.add(startPosition, entityPos))
            entityPos = vec2.add(entityPos, distBetweenEndpoints)
        end

        --table.insert(path, oldLength(diffBetweenPosVec, segment, maxSegment, lengthSupression, segmentDivider))
        entityPos = vec2.add(entityPos, offset or {0, 0})
        table.insert(path, entityPos)
        segment = segment + 1
    end
    fakeBridgeCurve(path, startPosition, distBetweenPos)
    return path
end

function distanceToNextSegment(diffBetweenPosVec, distBetweenPos, segment, segmentDivider)
    local entityPos = {0, 0} 
    entityPos[1] = entityPos[1] + (diffBetweenPosVec[1] * segment)
    entityPos[2] = entityPos[2] + (diffBetweenPosVec[2] * segment)
    entityPos[1] = entityPos[1] / (distBetweenPos / segmentDivider)
    entityPos[2] = entityPos[2] / (distBetweenPos / segmentDivider)

    return entityPos
end

function catenaryfication(entityPos, segment, maxSegment, diffBetweenPosVec, distBetweenPos)
    local entityPos = copy(entityPos)
    local roundingThingamagig = (util.round(math.abs(distBetweenPos / ((-(maxSegment/2)) + (1 + segment))))) / 10
    if roundingThingamagig > 3 then
        roundingThingamagig = (util.round(math.abs(distBetweenPos / ((-(maxSegment/2)) + (1 + (segment - 1)))))) / 10
        roundingThingamagig = roundingThingamagig + 0.2
    end
    sb.logInfo("roundingThingamagig %s", roundingThingamagig)
    local curvatureMath = ( math.cosh( (1 + diffBetweenPosVec[2]) / 2 ) )
    local curvePercent = 0.5 - math.abs(-0.5 + (segment / maxSegment))
    local curve = (curvatureMath * roundingThingamagig)
    entityPos[2] = entityPos[2] - curve

    return entityPos
end

function lengthSuppresion(entityPos, segmentDivider, lengthSupression)
    return ( (entityPos * segmentDivider) * (1 / lengthSupression)) * 4
end

function distMerge(distance)
    return distance[1] + distance[2]
end

function fakeBridgeCurve(path, startPosition, distBetweenPos)
    local grav = world.gravity(startPosition)
    for index, value in ipairs(path) do
        if index ~= 1 and index ~= #path then
            local percent = 0.5 - math.abs(-0.5 + (index / #path))
            local vDist = -math.abs(world.distance(value, path[index + 1])[2])
            local gravEffect = ((grav - vDist) / (distBetweenPos * (grav*0.05)) * percent)--util.clamp(((grav - vDist) / distBetweenPos * percent), -1, 1)
            --sb.logInfo("%s", vDist)
            --sb.logInfo("%s", gravEffect)
            
            value[2] = value[2] - gravEffect
        end
    end
end