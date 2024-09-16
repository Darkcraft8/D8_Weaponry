local pixel = 0.125

function init()
end

function update()
    if not root.assetJson("/D8Weaponry.config")["customAmmoRenderer"] then
        localAnimator.clearDrawables()
        local ownerPosition = activeItemAnimation.ownerPosition()
        local barOffset = {-2.8, -3}
        local d8WeaponryRenderer = {}

        for i, v in ipairs(config.getParameter("d8Weaponry")) do
            pos = {
                ownerPosition[1] + barOffset[1],
                ownerPosition[2] + barOffset[2] - i
            }
            local test = {
                image = v.ammoText.."?multiply=FFFFFF75?brightness=100",
                position = {
                    pos[1],
                    pos[2]
                },
                color = {255,255,255},
                fullbright = true,
                rotation = ((math.pi/180) * 1)
            }
            localAnimator.addDrawable(test, "ForegroundOverlay-1")
            local count = config.getParameter(v.ammoCountName)
            outpostSignNumber(count, pos)
        end
        
    end
end

function outpostSignNumber(count, pos)
    number = math.ceil(count)
    local numberTable = {}
    
    local digit =    number % 10
    number = number // 10
    local ten =      number % 10
    number = number // 10
    local hundred =  number % 10
    number = number // 10
    local thousand = number % 10

    local numberOffset = 0
    segmentOffset = 1

    local drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?multiply=FFFFFF75?brightness=100", thousand),
        position = {
            (pos[1] + 0.45) + 1 + (numberOffset*pixel),
            pos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 8
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?multiply=FFFFFF75?brightness=100", hundred),
        position = {
            (pos[1] + 0.45) + 1 + (numberOffset*pixel),
            pos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 16
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?multiply=FFFFFF75?brightness=100", ten),
        position = {
            (pos[1] + 0.45) + 1 + (numberOffset*pixel),
            pos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
    numberOffset = 24
    drawable = {
        image = string.format("/objects/outpost/number%s/icon.png:?multiply=FFFFFF75?brightness=100", digit),
        position = {
            (pos[1] + 0.45) + 1 + (numberOffset*pixel),
            pos[2]
        },
        color = {255,255,255},
        fullbright = true,
        rotation = 0,
        scale = 0.5
    }
    localAnimator.addDrawable(drawable, "ForegroundOverlay-1")
end