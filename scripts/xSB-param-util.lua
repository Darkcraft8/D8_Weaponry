-- Thanks Fezzed for helping me patch my lua codes

-- The line bellow where writen by fezzed
-- Use this instead of table.pack when sending parameters through messages or global variables in xStarbound.
function jsonPack(...)
    local packedArgs = table.pack(...)
    local argNum = packedArgs.n
    packedArgs.n = nil
    if argNum > 0 then
        for i = 1, argNum do
            if packedArgs[argNum] == nil then packedArgs[argNum] = null end
        end
        return jarray(packedArgs)
    else
        return jarray()
    end
end

-- Use this instead of table.unpack when receiving parameters through messages or global variables in xStarbound.
function jsonUnpack(argArr, i)
    i = i or 1
    local argNum = jsize(argArr)
    if i <= argNum then return argArr[i], jsonUnpack(argArr, i + 1) end
end