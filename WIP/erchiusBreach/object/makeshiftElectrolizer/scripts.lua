initTimer = 2
requiredScripts = {
    "/WIP/shared/darkcraft8/object/machinery/init.lua"
}
-- just the vanilla function
function init()
    for i, script in ipairs(requiredScripts) do --A little test of mine dont think to much it will most likely be gone :P
        require(script)
    end
    D8Machinery.type = "processor"

    D8Machinery:init()
end

function update(dt)
    D8Machinery:update(dt)
end

function uninit()
    D8Machinery:uninit()
end

function die()
    D8Machinery:die()
end