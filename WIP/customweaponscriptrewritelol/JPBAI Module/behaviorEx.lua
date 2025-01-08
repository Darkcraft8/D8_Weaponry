behaviorEx = {}
-- A bunch of extra function that arent focused on the behavior logic

-----------------------------------------------------------------------------------

function behaviorEx.getParameter(args) -- bridge for getParameter/getInstanceValue
    if not args then return end
    if args.parameter ~= nil then return config.getParameter(args.parameter, args.defaultValue) end
end

function behaviorEx.setParameter(args) -- bridge for setParameter/setInstanceValue
    if not args then return end
    if args.parameter ~= nil and args.value ~= nil then activeItem.setInstanceValue(args.parameter, args.value) end
end

-----------------------------------------------------------------------------------

-- Value
function behaviorEx.modValue(args)
    if not args then return end
    if args.parameter and args.value then 
        local newValue = config.getParameter(args.parameter, 0) + args.value
        activeItem.setInstanceValue(args.parameter, newValue)
    end
end

function behaviorEx.valueDiff(args)
    if not args then return false end
    if args.parameter and args.value then
        local diffType = args.diffType or "above" -- above, bellow or between
        local currentValue = config.getParameter(args.parameter, 0)
        if type(currentValue) ~= 'number' then sb.logError("%s ins't a number/value", args.parameter) return false end
        if diffType == "above" then
            if type(args.value) == "table" then
                return (currentValue > args.value[1])
            else
                return (currentValue > args.value)
            end
        elseif diffType == "bellow" then
            if type(args.value) == "table" then
                return (currentValue < args.value[1])
            else
                return (currentValue < args.value)
            end
        elseif diffType == "between" then
            if type(args.value) ~= "table" then sb.logError("%s ins't a table of two value", args.value) return false end
            if type(args.value[1]) ~= 'number' or type(args.value[2]) ~= 'number' then sb.logError("%s ins't a table of two value", args.value) return false end

            return ( (currentValue <= args.value[1]) == (currentValue >= args.value[2]) )
        end
    end
end

-----------------------------------------------------------------------------------

-- Function's to interact with player resources|status like a consumable but better
function behaviorEx.hasResources(args) -- return if the resources in the table are available
    if not args then return end
    for i, cfg in ipairs(args) do 
        if not status.resourcePositive(args.resource) then return false end
    end
    return true
end

function behaviorEx.modResources(args)
    if not args then return end
    for i, cfg in ipairs(args) do 
        if args.op == "give" then
            status.giveResource(args.resource, args.amount)
        elseif args.op == "consume" then
            status.consumeResource(args.resource, args.amount)
        elseif args.op == "overConsume" then
            status.overConsumeResource(args.resource, args.amount)
        elseif args.op == "set" then
            status.setResource(args.resource, args.amount)
        end
    end
end

function behaviorEx.status(args)
    if not args then return end
end

-----------------------------------------------------------------------------------

function behaviorEx.emptyTable()

end

-----------------------------------------------------------------------------------