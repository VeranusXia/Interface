# Hekili

## [v9.0.5-1.0.2-beta2](https://github.com/Hekili/hekili/tree/v9.0.5-1.0.2-beta2) (2021-03-20)
[Full Changelog](https://github.com/Hekili/hekili/compare/v9.0.5-1.0.2-beta1...v9.0.5-1.0.2-beta2) [Previous Releases](https://github.com/Hekili/hekili/releases)

- Arms, Fury:  Make Charge and Heroic Leap more flexible in their usage.  
    Fury:  Support Signet opener.  
- Frost Mage:  Update priority.  
- Arcane:  Default am\_spam to 0 (off), as is consistent with the current sim priority.  
- Make movement.distance return 0 unless you're actually moving (at which point, we'll assume you're moving to your target which may be wrong but hey, we all make mistakes).  
- Assassination:  Fix Shiv's Crippling Poison spell ID; more APL updates.  
- Include small optimizations for Assassination.  
- Setup CheckScript for the next action when testing pool\_resource.  
