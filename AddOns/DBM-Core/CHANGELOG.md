# Deadly Boss Mods Core

## [9.0.8-16-ga612a85](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/a612a85e3abcd5a333d02e240ba5f6e4ea4d3a48) (2020-12-13)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.0.8...a612a85e3abcd5a333d02e240ba5f6e4ea4d3a48) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Fix typo  
- Add last remaining feature requested  
- Apparently I straight up forgot to finish Executor Tarvold mod. I literally had a warning started that wasn't hooked up to anything. Anyways, fixed it so now Castigate should have better warnings.  
- Kael Update  
     - Some minor timer updates  
     - Upgraded Blazing Surge from a regular warning to special warning  
     - Enabled Concussive smash timer (may need testing)  
     - Added optional Feiry strike special warning (off by default). In addition, also added a general announce for it that's on by default for melee (although if you turn special warning on the general one is surpressed of course)  
    Hungering Destroyer Update  
     - Added optional off by default pre warning for volatile injection that announces beginning of cast. Some players wanted to know when to early spread evev though you don't know who victims are until cast finishes.  
- Fixed a bug where the icon option for setting icon on dutiful might throw a lua error instead  
    Fixed ravenous feast timer on generals, it's much shorter now.  
    Fixed spell name for Chain slam general target warning.  
    Added edge of annihilation cast timer to artificer and changed glyph of destruction target timer to on by default for everyone.  
- Fixed pkgmeta  
- Misc Castle Updates  
     - Added target timer for tank explotion to artificer for healers and tanks by default  
     - Fixed a bug where tank debuff yell countdown didn't aborb if player died before it finished as well  
     - Added optional soak special warning for bottled anima (off by default). can be turned on for a more prominant warning and customizing sound.  
     - Added icon marking for dutiful spawn on council of blood  
     - Drycoded more suspected (and confirmed) mythic mechanics into Sire mod  
- Shorten all position yells on Sire to just be "SpellName <number>"  
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
