# SavedInstances

## [9.0.3](https://github.com/SavedInstances/SavedInstances/tree/9.0.3) (2020-12-08)
[Full Changelog](https://github.com/SavedInstances/SavedInstances/compare/9.0.2...9.0.3) [Previous Releases](https://github.com/SavedInstances/SavedInstances/releases)

- Currency: tweak Renown  
    plus one to amount and totalMax  
- MythicPlus: support The Great Vault  
    need more tweak in future, like entire run history but its usable now  
- core: new defaults  
- Progress: update PvP Conquest feature  
    actually it tracks Honor but keep its name anyways :p  
    also fix Torghast weekly flag  
- Currency: track Conquest  
- Calling: introducing Calling tracking  
    this is very early version, need more enhancement  
- Progress: track Torghast Weekly  
- Quest: track Heroic Dungeon Weekly Quest  
    thanks to JourneyOver  
- time: fix :GetNextDarkmoonResetTime  
    closes #427, big thanks to Kanegasi  
- core: drop C\_QuestLog.GetAllCompletedQuestIDs  
    which causes lag,  
    and it's job can be done by C\_QuestLog.IsQuestFlaggedCompleted  
    fixes #425, fixes #437  
- Progress: disable PvP Conquest Weekly tracking  
    Will be back soon in The Great Vault version  
- Quest: track Mythic Dungeon and PvP Weekly Quest  
- currency: track Medallion of Service & reorder  
    fixes #439  
- MythicPlus: update to Shadowlands Season 1  
    * update dungeon abbr  
    * update keystone item id  
- WorldBoss: add Wrath of the Jailer  
- add redeemed soul  
- add shadowlands currencies  
- Fix id  
- Fix whitespace  
- Add Nathanos Blightcaller (Shadowlands pre-patch event)  
    Not sure how you're handling locales, so might need to be added somewhere still.  