--load all compact files from compact.config... that's it
--Seem more like a patching technique for lua script's, oh well

function compactInit()
    for _, compact in ipairs(root.assetJson("/shared/darkcraft8/machinery/V0_0_1/object/machinery/compact.config")) do 
        require(compact)
        if D8Machinery.compactBuild then
            D8Machinery:compactBuild()
            D8Machinery.compactBuild = nil
            --sb.logInfo("checkList %s", checkList or {})
        end
    end
end