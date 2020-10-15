# SavedInstances

## [9.0.0](https://github.com/SavedInstances/SavedInstances/tree/9.0.0) (2020-09-19)
[Full Changelog](https://github.com/SavedInstances/SavedInstances/compare/8.3.5...9.0.0) [Previous Releases](https://github.com/SavedInstances/SavedInstances/releases)

- Update Actions  
- core: update ElvUI and Tukui skin  
- Add BigWigs packager  
- libs: remove LDB from git  
- compatibility: clean up random daily ignore list  
    * random classic & timewalking no longer marked donetoday (live & ptr)  
    * random cata is not marked donetoday at max level (live & ptr)  
- core: new defaults  
- Fix Libs embedding  
- refactor: generic module upvalues  
- refactor: maxlvl -> SI.maxLevel  
- Add GitHub CI  
- tradeskill: update Shadowlands wormhole item  
- core: remove Artifact and Cloak level  
- core: update LFG and PvP deserter check  
    * use new GetPlayerAuraBySpellID  
    * remove Ashran queue spell id, it's now one of the epic battlegrounds  
- paragon: update Shadowlands factions  
- core: fix rest xp calc  
- LFR: update Castle Nathria  
- currency: update Shadowlands currencies  
- MP: KeystoneReportTarget default config  
- compatibility: level squish  
- chore: update TOC for 9.0.1  
- all: update cache & remove unused var  
- debug: tweak :QuestDebug  
- compatibility: update .luacheckrc  
- compatibility: C\_CurrencyInfo changes  
- compatibility: C\_QuestLog changes  
- compatibility: fix Emissary  
- compatibility: use API to get weekly reset time  
- compatibility: MAX\_PLAYER\_LEVEL\_TABLE  
- compatibility: LibQTip-1.0 repo uri update  
- refactor: fix load order  
- refactor: fix TradeSkill rename &  
    combine addon and core  
- refactor: fix :Debug  
- MP: fix rebase missing refactor stuffs  
- MP: clean up :ExportKeys  
- refactor: clean up dialogs  
- Mythic Plus: use BAG\_UPDATE\_DELAYED  
    to reduce refresh function call  
- refactor: quick fix on mis repalcing  
- refactor: move thisToon,  
    message functions, debug functions, time functions to their files  
- refactor: move GetTimeToTime  
- refactor: move SI\_GetUnitAura,  
    reduce :SetOwner call  
- refactor: Part II: combine addon and core to SI  
- refactor: Part I: renames, moving files and more  
