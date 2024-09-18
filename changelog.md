# Dev 1.1.0
## Addition : 
    Makarov Pistol
    Recipes for creation of volatile powder analogue "Gunpowder" to ease early game munition production
    Temperature global tag for usage with staturation and brightness *currently only used by the wip minigun*

    Stance "emptyToReload" for animation to be done if the weapon is empty before doing the reload animation
        come with the emptyToReloadAddAmmo ability parameters

    Stance "reloadAfterEmpty" for animation to be played if the weapon is empty after doing the reload animation

    weaponDirective globalTag parameters for "emptyToReload", "reload", "reloadAfterEmpty" stances

## Change : 
    Gunsmithing Pane now has three category "weapon", "munition" and "conversion"
    Gunsmith Table no longer use the complex mode of the script and now use the basic one
    Tungsten Shotgun *Physical Variant* updated to use the new "emptyToReload" stances and weaponDirective globalTag for better animation
    Iron Assault Rifle *Physical Variant* converted the two last "reload" stances to "reloadAfterEmpty" stances

## Buff :
    Gunsmith Table now require 2 coal instead of 4 core fragment total
    Higher tier Table allow craft ammunition with more speed and in greater yeld

## Nerf : 
    Double Barrel shotgun got nerfed from 202 to 42 (test done at closerange armorless)

## Work in progress :
    The Minigun a fast firing weapon of T4
    The Glock a polivalent T1 -> T3 pistol... almost finished required more test for balancing
