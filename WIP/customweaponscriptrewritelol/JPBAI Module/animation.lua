animationEx = {}
-- a bunch of bridge function for animator
function animationEx.init()

end

function animationEx.randGlobalTag(args)
    local tagName, varNum = args.tagName, args.varNum
    animator.setGlobalTag(tagName, math.random(1, varNum or 1))
end

function animationEx.randPartTag(args)
    local partType, tagName, varNum = args.partType, args.tagName, args.varNum
    animator.setPartTag(partType, tagName, math.random(1, varNum or 1))
end

function animationEx.setGlobalTag(args)
    local tagName, varNum = args.tagName, args.varNum
    animator.setGlobalTag(tagName, varNum)
end

function animationEx.setPartTag(args)
    local partType, tagName, varNum = args.partType, args.tagName, args.varNum
    animator.setPartTag(partType, tagName, varNum)
end

function animationEx.pitchShift(args) -- pitch the shift a bit to make sound not repetitif
    local range = args.range or 50
    local pitch = getSoundPitch(args.soundName)
    --sb.logInfo("ogPitch %s", pitch)
    local modif = ( (math.random(0, range) - (range/2)) / (100 + range) )
    pitch = pitch + modif
    --sb.logInfo("modifier %s", modif)
    --sb.logInfo("newPitch %s", pitch)
    animator.setSoundPitch(args.soundName, pitch)
end

function getSoundPitch(soundName)
    if self.animationCfg["sounds"] then
        if self.animationCfg["sounds"][soundName] then
            return self.animationCfg["sounds"][soundName]["pitchMultiplier"] or 1.0
        end
    end
    return 1.0
end