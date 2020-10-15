# Deadly Boss Mods Core

## [9.0.1-4-g4e3077d](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/4e3077d4404890926a80c4365069c45327060fad) (2020-10-14)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.0.1...4e3077d4404890926a80c4365069c45327060fad) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- We can fix PvP timers, right? :P (#369)  
    All timers are handled via PvPGeneral mod.  
    Any which aren't (e.g. silvershard mines), use math rather than events to calculate their time, so don't need a resync.  
- Fix #367 (#368)  
- Forgot to bump version for next alpha cycle  
- Some short term changes to TimerTracker handling in PT to reducce chance of taint as well as change to type 3 so texture overwriting no longer required. This will likely be changed up again in future to possibly migrate to blizzards countdown timer once it is able to accomidate some needs  
