# Deadly Boss Mods Core

## [9.0.21-7-gf738096](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/f738096671b6a454108e7e449eb9d8795a27cd00) (2021-02-24)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.0.21...f738096671b6a454108e7e449eb9d8795a27cd00) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Forgot these  
- tiny bit of post tier cleanup  
- Fix  
- updated timer recovery to send paused bar status. This will fix a bug where a user reloading bars they think are "stuck" won't ACTUALLY break them for real when recovery gets them back.  
    Changed sync handler for it to avoid out of date syncs also messing it up that don't have paused status.  
- tweak last  
- Maybe this will fix bar errors. bar frame names will now generate unique integer EVERY SINGLE COMMIT. Shouldn't break DBMs bar handling but should make it an utter NIGHTMARE for anyone trying to modify them. Hate having to ruin 3rd party skinning like this, but if it's breaking DBM it has to come to a stop.  
- bump alpha  
