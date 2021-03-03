# Deadly Boss Mods Core

## [9.0.21-12-gc742b1e](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/c742b1e4b35ec8de4638c19557e96a2361eff10b) (2021-03-02)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.0.21...c742b1e4b35ec8de4638c19557e96a2361eff10b) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Fix Lua exception (#517)  
    Bad table entry, reported by user :)  
- Clear paused status on a bar when :Start or :Stop is called on a timer object. Start should always clear previous status of timer.  
- Add new test condition  
- Update README.md  
- Update README.md  
- Forgot these  
- tiny bit of post tier cleanup  
- Fix  
- updated timer recovery to send paused bar status. This will fix a bug where a user reloading bars they think are "stuck" won't ACTUALLY break them for real when recovery gets them back.  
    Changed sync handler for it to avoid out of date syncs also messing it up that don't have paused status.  
- tweak last  
- Maybe this will fix bar errors. bar frame names will now generate unique integer EVERY SINGLE COMMIT. Shouldn't break DBMs bar handling but should make it an utter NIGHTMARE for anyone trying to modify them. Hate having to ruin 3rd party skinning like this, but if it's breaking DBM it has to come to a stop.  
- bump alpha  
