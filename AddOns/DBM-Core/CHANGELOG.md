# Deadly Boss Mods Core

## [9.0.29-8-gb55e553](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/b55e553e92605ead9cb59dfebc84a93c022339af) (2021-06-01)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.0.29...b55e553e92605ead9cb59dfebc84a93c022339af) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Add a link to BCC issues in issue templates. (#588)  
- Update Rohkalo from mythic testing, still WIP do to incomplete logs as well as blizzard breaking combat log  
    Updated Kel Thuzad from mythic testing. Also WIP and incomplete because blizzard designed fight is a crappy way that makes doing accurate timers very miserable.  
    Fixed a couple bugs on Raznal but didn't update it for mythic yet. ALSO a crappy fight to work on because blizzard hates the combat log and only 1 of literally 9 abilities is even in it.  
    Updated Sylvanas from heroic testing. Incomplete since literally no one saw phase 3 except for like two guild that got there because of a bugged phase 2, but still wiped a minute into it.  
- Few general cleanup in DBT (#587)  
    - Remove deprecated functions, these should have stopped being used for a LONG while  
    - Remove bar.owner usage, and reference DBT directly (memory saving as we're not defining another reference object)  
    - Define a default of numBars instead of using or checks everywhere.  
- Add zhCN for SOD (#586)  
- Sync DBT tweaks (#585)  
- Potential fix for bars not updating on enlarge? (#584)  
- Update koKR (#583)  
- prep alpha cycle  
