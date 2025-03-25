# 1.1.5
## Addition :
- Makarov JPBAI Version (T1) (Unobtainable)

## Change : 
- JPBAI Framework is now it own mod! this mean that you no longer need d8Weaponry to use it and that it in a stable state
- now require two dependency : 
  - [JPBAI Framework][JPBAIFramework]
  - [Darkcraft8 Shared Files][D8SharedFiles]
- `Darkcraft8 Shared Files`
  - the old local renderer has been deleted and d8Weaponry now use the one from *Darkcraft8 Shared Files*, this one use message handlers to receive(if sent localy) drawable to be drawn that get added to a list (also come with a util script that has 3 functions to effortlessly communicate with the renderer)

## Buff :

## Nerf : 

## Fix : 
	- `JPBAI Framework`
    - fixed issue's with the buildscript
      - would crash if a tooltip script didn't exist
    - `oSb and it fork(this include xSb) exclusive`
      - there is now a postLoad script that fetch any named JPBAI behavior with the `jpbaiBehaviorCfg` file extension (those are written in json still) and add them to the buildscript list of behavior

## Work in progress :
- Medieval Weapon Pack 1
  - Crossbow (T1)
    - Need to be converted to jpbai framework
    - Wooden Bolt (T1) finished
    - More Bolt
  - Need to make more weapon

- French Weapon Pack 1
  - Famas (T1) And (JPBAI) Chauchat
    - need to finishe new attachment and part system
      - munition arrangement almost finished, just need to add black/white list (a famas firing a crossbow bolt doesn't make much sense)
  - Need to make more weapon

- Erchius Breach
  - dungeon not finished
  - weapons need to be rewriten

- New **Redacted** Weapon
  - Interface
  - **Redacted** Texture

[D8SharedFiles]: /changelog.md 'Go to Mod Page'
[JPBAIFramework]: /changelog.md 'Go to Mod Page'