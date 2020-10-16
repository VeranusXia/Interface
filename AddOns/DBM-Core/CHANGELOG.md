# Deadly Boss Mods Core

## [9.0.1-6-g5ec98bd](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/5ec98bdd355eb79e42fe249afd05c885113948b3) (2020-10-15)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.0.1...5ec98bdd355eb79e42fe249afd05c885113948b3) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Es update  
- Fixed regression to RU translations that caused them to completely erase english tables instead of doing table replacements. This was causing lua errors or missing auto translations on warnings/timers that weren't yet translated into Russian  
- We can fix PvP timers, right? :P (#369)  
    All timers are handled via PvPGeneral mod.  
    Any which aren't (e.g. silvershard mines), use math rather than events to calculate their time, so don't need a resync.  
- Fix #367 (#368)  
- Forgot to bump version for next alpha cycle  
- Some short term changes to TimerTracker handling in PT to reducce chance of taint as well as change to type 3 so texture overwriting no longer required. This will likely be changed up again in future to possibly migrate to blizzards countdown timer once it is able to accomidate some needs  
