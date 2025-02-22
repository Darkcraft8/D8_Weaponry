require "/scripts/util.lua"
require "/shared/darkcraft8/scripts/lua.lua"
--require "/shared/rxi/json.lua" -- required ?
json = json or {}
local jsonSubFunc = jsonSubFunc or {}
-- Starbound Specific --
function json.sbMerge(jA_A, jA_B) -- Trie to imitate the way parameters override config
    local isVec2 = function(val)
        return (type(val[1]) == "number" and type(val[2]) == "number" and #val == 2)
    end
    for var, val in pairs(jA_B or {}) do 
        local typeA, typeB = preciseType(jA_A[var]), preciseType(val)
        if typeB == "table" and typeA == "table" then
            if isVec2(val) and isVec2(jA_A[var]) then
                jA_A[var] = val
            else
                for i, v in ipairs(val) do
                    table.insert(jA_A[var], v)
                end
            end

        elseif typeB == "array" and typeA == "array" then
            jA_A[var] = json.sbMerge(jA_A[var], val)
    
        else
            jA_A[var] = val

        end
    end
    return jA_A
end

-- Merge, Patch and Other --
function json.merge(jA_A, jA_B)
    for var, val in pairs(jA_B or {}) do 
        local typeA, typeB = preciseType(jA_A[var]), preciseType(val)
        if typeB == "table" and typeA == "table" then
            for i, v in ipairs(val) do
                table.insert(jA_A[var], v)
            end

        elseif typeB == "array" and typeA == "array" then
            jA_A[var] = json.merge(jA_A[var], val)
    
        else
            jA_A[var] = val

        end
    end
    return jA_A
end

function json.patch() -- do i really need to make this function ?
    
end

function json.override(_, jsonArray, override)
    local newJson = {}
    sb.logInfo("jsonArray : %s,\n[------------] [----] override : %s", jsonArray, override)
    for var, val in pairs(override or jsonArray or {}) do
        if typeNew(val) == "table" or typeNew(val) == "array" then
            newJson[var] = json:override((jsonArray or {})[var] or {}, val)
        else
            newJson[var] = val
        end
    end
    return newJson
end

function json.luaToPatch(old, new)
    --sb.logInfo("[lua to json Patch] : start")
    local newPatch = jsonSubFunc:luaToPatch_Analyse(new, old)

    --sb.logInfo("[lua to json Patch] : result\n\n%s\n", sb.printJson(newPatch, 1))
    --sb.logInfo("[lua to json Patch] : end")
    return newPatch
end

-- Local Sub Functions --
function jsonSubFunc.varIsTableOrArray(_, var, jsonArray)
    local type = preciseType((jsonArray or old)[var])
    if type == "table" or type == "array" then
        return true
    else
        return false
    end
end

function jsonSubFunc.varExist(_, var, jsonArray)
    if (jsonArray or {})[var] then return true else return false end
end

function jsonSubFunc.luaToPatch_Analyse(_, new, old, parent)
    local patch = {}
    local path = "/"
    if parent then
        path = parent .. "/"
    end
    
    for var, val in pairs(new) do
        -- Preparing Json Patch Operations --
        local opp = {
            test = { op = "test", path = path .. var },
            add = { op = "add", path = path .. var, value = val },
            replace = { op = "replace", path = path .. var, value = val },
            remove = { op = "remove", path = path .. var },
            move = { op = "move", from = "<from>", path = path .. var},
            copy = { op = "copy", from = "<from>", path = path .. var},
            
            testInv = { op = "test", path = path .. var, inverse = true },
            tableAdd = { op = "add", path = path .. var .. "/-", value = val},
            newVar = { op = "add", path = path .. var, value = {_null = nil}}
        }

        if jsonSubFunc:varExist(var, old) then
            local type = preciseType(val)
            --sb.logInfo("type %s", type)
            if type == "table" then
                local patchSection = {}
                table.insert(patchSection, opp.testInv)
                table.insert(patchSection, opp.add)
                table.insert(patch, patchSection)

                local patchSectionB = {}
                table.insert(patchSectionB, opp.test)
                for _, valB in ipairs(val) do
                    local tableAdd = { op = "add", path = path .. var .. "/-", value = valB}
                    table.insert(patchSectionB, tableAdd)
                end
                table.insert(patch, patchSectionB)
                --sb.logInfo("[lua to json Patch] : table add %s,\n%s,\n%s", val, sb.printJson(patchSection, 1), sb.printJson(patchSectionB, 1))

            elseif type == "array" then
                local patchSection = {}
                table.insert(patchSection, opp.testInv)
                table.insert(patchSection, opp.newVar)
                table.insert(patch, patchSection)

                --sb.logInfo("[lua to json Patch] : arrays %s,\n%s", val, sb.printJson(patchSection))
                for index, patchSection in ipairs(jsonSubFunc:luaToPatch_Analyse(val, old[var], path .. var)) do 
                    table.insert(patch, patchSection)
                end
            elseif type == "string" or type == "number" then
                local patchSection = {}
                table.insert(patchSection, opp.testInv)
                table.insert(patchSection, opp.add)
                table.insert(patch, patchSection)
                
                local patchSectionB = {}
                table.insert(patchSectionB, opp.test)
                table.insert(patchSectionB, opp.replace)
                table.insert(patch, patchSectionB)
                --sb.logInfo("[lua to json Patch] : %s replace %s,\n%s,\n%s", type, val, sb.printJson(patchSection, 1), sb.printJson(patchSectionB, 1))

            end
        else
            local patchSection = {}
            table.insert(patchSection, opp.testInv)
            table.insert(patchSection, opp.add)
            table.insert(patch, patchSection)
            local type = preciseType(val)
            --sb.logInfo("type %s", type)
            if type == "table" then
                local patchSectionB = {}
                table.insert(patchSectionB, opp.test)
                table.insert(patchSectionB, opp.replace)
                table.insert(patch, patchSectionB)
                --sb.logInfo("[lua to json Patch] : add %s, %s,\n%s,\n%s", type, val, sb.printJson(patchSection, 1), sb.printJson(patchSectionB, 1))

            elseif type == "array" then
                local patchSectionB = {}
                table.insert(patchSectionB, opp.test)
                table.insert(patchSectionB, opp.replace)
                table.insert(patch, patchSectionB)
                --sb.logInfo("[lua to json Patch] : add %s,\n%s,\n%s", type, val, sb.printJson(patchSection, 1), sb.printJson(patchSectionB, 1))

            elseif type == "string" or type == "number" then
                local patchSectionB = {}
                table.insert(patchSectionB, opp.test)
                table.insert(patchSectionB, opp.replace)
                table.insert(patch, patchSectionB)
                --sb.logInfo("[lua to json Patch] : add %s,\n%s,\n%s", type, val, sb.printJson(patchSection, 1), sb.printJson(patchSectionB, 1))
            end
        end
    end
    if not parent then
        --sb.logInfo("[lua to json Patch] : old removal handling")
        for var, val in pairs(old or {}) do
            -- Preparing Json Patch Operations --
            local opp = {
                test = { op = "test", path = path .. var },
                add = { op = "add", path = path .. var, value = val },
                replace = { op = "replace", path = path .. var, value = val },
                remove = { op = "remove", path = path .. var },
                move = { op = "move", from = "<from>", path = path .. var},
                copy = { op = "copy", from = "<from>", path = path .. var},
                
                testInv = { op = "test", path = path .. var, inverse = true },
                tableAdd = { op = "add", path = path .. var .. "/-", value = val},
                newVar = { op = "add", path = path .. var, value = {_null = nil}}
            }

            if not jsonSubFunc:varExist(var, new) then
                local patchSection = {}    
                table.insert(patchSection, opp.test)
                table.insert(patchSection, opp.remove)

                table.insert(patch, patchSection)
                --sb.logInfo("[lua to json Patch] : remove %s,\n%s", val, sb.printJson(patchSection, 1))
            end
        end
    end
    return patch
end