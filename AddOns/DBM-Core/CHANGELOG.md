# Deadly Boss Mods Core

## [9.0.8-8-g9406e0c](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/9406e0c429008da0f7a68c2f95cda12477e3c532) (2020-12-13)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.0.8...9406e0c429008da0f7a68c2f95cda12477e3c532) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Fixed a bug where Cadre was using an AI timer instead of the better hard coded timer it already has  
    Added a general count announce for drain essence that's on for healers by default  
- Made melee check slightly more robust. It'll at least pick up balance druids temporarily shifted into bear/cat form, but only if lunar power > 0  
- Made boss health checking more robust against nil errors if cached health value isn't set correctly or doesn't exist yet.  
- Bump HF and sync revisions on last  
- Hungering Destroyer  
     - Fixed issue where miasma marker might try to set star on multiple melee  
     - Also fixed issue where star would get assigned to no body (and instead an icon that option isn't supposed to use, gets used instead) because there are no melee selected by miasma  
- Fix  
- Actually fix the original issue (#415)  
- prep next dev cycle this time, forgot to with last one and every alpha was flagged as a release version, oops.  
