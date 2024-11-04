initTimer = 2
requiredScripts = {
    "/shared/darkcraft8/machinery/V0_0_1/object/machinery/init.lua"
}
-- just the vanilla function
function init()
    for i, script in ipairs(requiredScripts) do --A little test of mine dont think to much it will most likely be gone :P
        require(script)
    end
    D8Machinery:init()
end