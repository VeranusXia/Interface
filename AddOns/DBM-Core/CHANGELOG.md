# Deadly Boss Mods Core

## [9.1.1-10-g2d09860](https://github.com/DeadlyBossMods/DeadlyBossMods/tree/2d09860fe1167fa8dca0c970682972cbbc51b0d8) (2021-07-07)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/9.1.1...2d09860fe1167fa8dca0c970682972cbbc51b0d8) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Fix transition scaling working in reverse (#606)  
    * Fix transition scaling working in reverse  
    When going from a higher scale (large) to a lower scale (small), the logic was actually working inverse and growing in side.  
- Soulrender updates  
- Updated timers for the nine with live data  
-  - Updated timers for Terragrue on live  
     - Updated timers for Eye of the jailer on live  
     - Fixed a bug on guardian where icons were never removed  
     - Fixed a bug on raznal where icons were never removed  
     - Fixed a bug on eye of jailer where spreading misery got double announced instead of aggregated. timers don't aggregate though because they can desync  
     - Sylvanas Changes:  
    *Improved wailing arrow and black arrow announces and added icons for the arrow mechanics  
    *Added short names to a few ability timers/alerts  
    *Disabled knives icons by default, it's a bad default and should only be used if not using arrows icons  
- A bit of mythic prep for sylvanas  
- Fire stage callback on variable recovery  
- antispam wasn't multiple events firing it was combat start and emerge. when boss is engaged emerged can also follow (but not always sometimes it's before the IEEU)  
- Add antispam to submerge as these events fire multiple times (#605)  
- Opportunity Strikes seems to be back based on latest journal updates  
- prep next cycle  
