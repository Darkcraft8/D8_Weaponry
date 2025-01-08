animationEx = {}
-- a bunch of bridge function for animator
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