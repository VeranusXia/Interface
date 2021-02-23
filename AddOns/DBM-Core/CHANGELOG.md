# Deadly Boss Mods Core

## [9.0.21-5-gfc249c4](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/fc249c476fcd29719cb2ccb4beda3ab90d91b157) (2021-02-22)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.0.21...fc249c476fcd29719cb2ccb4beda3ab90d91b157) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Fix  
- updated timer recovery to send paused bar status. This will fix a bug where a user reloading bars they think are "stuck" won't ACTUALLY break them for real when recovery gets them back.  
    Changed sync handler for it to avoid out of date syncs also messing it up that don't have paused status.  
- tweak last  
- Maybe this will fix bar errors. bar frame names will now generate unique integer EVERY SINGLE COMMIT. Shouldn't break DBMs bar handling but should make it an utter NIGHTMARE for anyone trying to modify them. Hate having to ruin 3rd party skinning like this, but if it's breaking DBM it has to come to a stop.  
- bump alpha  
