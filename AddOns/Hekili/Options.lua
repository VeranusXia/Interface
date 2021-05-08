-- Options.lua
-- Everything related to building/configuring options.

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local scripts = Hekili.Scripts
local state = Hekili.State

local format, lower, match, upper = string.format, string.lower, string.match, string.upper
local insert, remove, wipe = table.insert, table.remove, table.wipe

local callHook = ns.callHook
local getSpecializationID = ns.getSpecializationID

local GetResourceKey = ns.GetResourceKey
local SpaceOut = ns.SpaceOut

local escapeMagic = ns.escapeMagic
local fsub = ns.fsub
local formatKey = ns.formatKey
local orderedPairs = ns.orderedPairs
local tableCopy = ns.tableCopy

local GetItemInfo = ns.CachedGetItemInfo

-- Atlas/Textures
local AddTexString, GetTexString, AtlasToString, GetAtlasFile, GetAtlasCoords = ns.AddTexString, ns.GetTexString, ns.AtlasToString, ns.GetAtlasFile, ns.GetAtlasCoords


local LDB = LibStub( "LibDataBroker-1.1", true )
local LDBIcon = LibStub( "LibDBIcon-1.0", true )


local NewFeature = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t"
local GreenPlus = "Interface\\AddOns\\Hekili\\Textures\\GreenPlus"
local RedX = "Interface\\AddOns\\Hekili\\Textures\\RedX"

local BlizzBlue = "|cFF00B4FF"


-- Interrupts
do
    local db = {}

    -- Generate encounter DB.
    local function GenerateEncounterDB()
        local active = EJ_GetCurrentTier()
        wipe( db )

        for t = 1, EJ_GetNumTiers() do
            EJ_SelectTier( t )

            local i = 1
            while EJ_GetInstanceByIndex( i, true ) do
                local instanceID, name = EJ_GetInstanceByIndex( i, true )                
                i = i + 1

                local j = 1
                while EJ_GetEncounterInfoByIndex( j, instanceID ) do
                    local name, _, encounterID = EJ_GetEncounterInfoByIndex( j, instanceID )
                    db[ encounterID ] = name
                    j = j + 1
                end
            end
        end
    end

    GenerateEncounterDB()

    function Hekili:GetEncounterList()
        return db
    end
end


-- One Time Fixes
local oneTimeFixes = {
    refreshForBfA_II = function( p )
        for k, v in pairs( p.displays ) do
            if type( k ) == 'number' then
                p.displays[ k ] = nil
            end
        end

        p.runOnce.refreshForBfA_II = nil
        p.actionLists = nil
    end,

    --[[ reviseDisplayModes_20180709 = function( p )
        if p.toggles.mode.type ~= "AutoDual" and p.toggles.mode.type ~= "AutoSingle" and p.toggles.mode.type ~= "SingleAOE" then
            p.toggles.mode.type = "AutoDual"
        end

        if p.toggles.mode.value ~= "automatic" and p.toggles.mode.value ~= "single" and p.toggles.mode.value ~= "aoe" and p.toggles.mode.value ~= "dual" then
            p.toggles.mode.value = "automatic"
        end
    end, ]]

    reviseDisplayQueueAnchors_20180718 = function( p )
        for name, display in pairs( p.displays ) do
            if display.queue.offset then
                if display.queue.anchor:sub( 1, 3 ) == "TOP" or display.queue.anchor:sub( 1, 6 ) == "BOTTOM" then
                    display.queue.offsetY = display.queue.offset
                    display.queue.offsetX = 0
                else
                    display.queue.offsetX = display.queue.offset
                    display.queue.offsetY = 0
                end
                display.queue.offset = nil
            end
        end

        p.runOnce.reviseDisplayQueueAnchors_20180718 = nil
    end,

    enableAllOfTheThings_20180820 = function( p )
        for name, spec in pairs( p.specs ) do
            spec.enabled = true
        end
    end,

    wipeSpecPotions_20180910_1 = function( p )
        local latestVersion = 20180919.1

        for id, spec in pairs( class.specs ) do            
            if id > 0 and ( not p.specs[ id ].potionsReset or type( p.specs[ id ].potionsReset ) ~= 'number' or p.specs[ id ].potionsReset < latestVersion ) then
                p.specs[ id ].potion = spec.potion
                p.specs[ id ].potionsReset = latestVersion
            end
        end
        p.runOnce.wipeSpecPotions_20180910_1 = nil
    end,

    enabledArcaneMageOnce_20190309 = function( p )
        local arcane = class.specs[ 62 ]

        if arcane and not arcane.enabled then
            arcane.enabled = true
            return
        end

        -- Clears the flag if Arcane wasn't actually enabled.
        p.runOnce.enabledArcaneMageOnce_20190309 = nil
    end,

    autoconvertGlowsForCustomGlow_20190326 = function( p )
        for k, v in pairs( p.displays ) do
            if v.glow and v.glow.shine ~= nil then
                if v.glow.shine then
                    v.glow.mode = "autocast"
                else
                    v.glow.mode = "standard"
                end
                v.glow.shine = nil
            end
        end
    end,

    autoconvertDisplayToggle_20190621_1 = function( p )
        local m = p.toggles.mode
        local types = m.type

        if types then
            m.automatic = nil
            m.single = nil
            m.aoe = nil
            m.dual = nil
            m.reactive = nil
            m.type = nil
            
            if types == "AutoSingle" then
                m.automatic = true
                m.single = true
            elseif types == "SingleAOE" then
                m.single = true
                m.aoe = true
            elseif types == "AutoDual" then
                m.automatic = true
                m.dual = true
            elseif types == "ReactiveDual" then
                m.reactive = true
            end
        
            if not m[ m.value ] then
                if     m.automatic then m.value = "automatic"
                elseif m.single    then m.value = "single"
                elseif m.aoe       then m.value = "aoe"
                elseif m.dual      then m.value = "dual"
                elseif m.reactive  then m.value = "reactive" end
            end
        end
    end,

    resetPotionsToDefaults_20190717 = function( p )
        for _, v in pairs( p.specs ) do
            v.potion = nil
        end
    end,

    resetAberrantPackageDates_20190728_1 = function( p )
        for _, v in pairs( p.packs ) do
            if type( v.date ) == 'string' then v.date = tonumber( v.date ) or 0 end
            if type( v.version ) == 'string' then v.date = tonumber( v.date ) or 0 end
            if v.date then while( v.date > 21000000 ) do v.date = v.date / 10 end end
            if v.version then while( v.version > 21000000 ) do v.version = v.version / 10 end end
        end
    end,

    autoconvertDelaySweepToExtend_20190729 = function( p )
        for k, v in pairs( p.displays ) do
            if v.delays.type == "CDSW" then
                v.delays.type = "__NA"
            end
        end
    end,

    autoconvertPSCDsToCBs_20190805 = function( p )
        for _, pack in pairs( p.packs ) do
            for _, list in pairs( pack.lists ) do
                for i, entry in ipairs( list ) do
                    if entry.action == "pocketsized_computation_device" then
                        entry.action = "cyclotronic_blast"
                    end
                end
            end
        end

        p.runOnce.autoconvertPSCDsToCBs_20190805 = nil -- repeat as needed.
    end,

    cleanupAnyPriorityVersionTypoes_20200124 = function ( p )
        for _, pack in pairs( p.packs ) do
            if pack.date    and pack.date    > 99999999 then pack.date    = 0 end
            if pack.version and pack.version > 99999999 then pack.version = 0 end
        end

        p.runOnce.cleanupAnyPriorityVersionTypoes_20200124 = nil -- repeat as needed.
    end,

    resetRogueMfDOption_20200226 = function( p )
        if class.file == "ROGUE" then
            p.specs[ 259 ].settings.mfd_waste = nil
            p.specs[ 260 ].settings.mfd_waste = nil
            p.specs[ 261 ].settings.mfd_waste = nil
        end
    end,

    resetAllPotions_20201209 = function( p )
        for id in pairs( p.specs ) do
            p.specs[ id ].potion = nil
        end
    end,
}


function Hekili:RunOneTimeFixes()   
    local profile = Hekili.DB.profile
    if not profile then return end

    profile.runOnce = profile.runOnce or {}

    for k, v in pairs( oneTimeFixes ) do
        if not profile.runOnce[ k ] then
            profile.runOnce[k] = true
            v( profile )
        end
    end

end


-- Display Controls
--    Single Display -- single vs. auto in one display.
--    Dual Display   -- single in one display, aoe in another.
--    Hybrid Display -- automatic in one display, can toggle to single/AOE.

local displayTemplate = {
    enabled = true,

    numIcons = 4,

    primaryWidth = 50,
    primaryHeight = 50,

    elvuiCooldown = false,

    keepAspectRatio = true,
    zoom = 30,

    frameStrata = "LOW",
    frameLevel = 10,

    queue = {
        anchor = 'RIGHT',
        direction = 'RIGHT',
        style = 'RIGHT',
        alignment = 'CENTER',

        width = 50,
        height = 50,

        -- offset = 5, -- deprecated.
        offsetX = 5,
        offsetY = 0,
        spacing = 5,

        elvuiCooldown = false,

        --[[ font = ElvUI and 'PT Sans Narrow' or 'Arial Narrow',
        fontSize = 12,
        fontStyle = "OUTLINE" ]]
    },

    visibility = {
        advanced = false,

        mode = { 
            aoe = true,
            automatic = true,
            dual = true,
            single = true,
            reactive = true,
        },

        pve = {
            alpha = 1,
            always = 1,
            target = 1,
            combat = 1,
            combatTarget = 1,
            hideMounted = false,
        },

        pvp = {
            alpha = 1,
            always = 1,
            target = 1,
            combat = 1,
            combatTarget = 1,
            hideMounted = false,
        },
    },

    border = {
        enabled = true,
        width = 1,
        coloring = 'custom',
        color = { 0, 0, 0, 1 },
    },

    range = {
        enabled = true,
        type = 'ability',
    },

    glow = {
        enabled = false,
        queued = false,
        mode = "autocast",
        coloring = "default",
        color = { 0.95, 0.95, 0.32, 1 },
    },

    flash = {
        enabled = false,
        color = { 255/255, 215/255, 0, 1 }, -- gold.
        suppress = false,
    },

    captions = {
        enabled = false,
        queued = false,

        align = "CENTER",
        anchor = "BOTTOM",
        x = 0,
        y = 0,

        font = ElvUI and 'PT Sans Narrow' or 'Arial Narrow',
        fontSize = 12,
        fontStyle = "OUTLINE",

        color = { 1, 1, 1, 1 },
    },

    indicators = {
        enabled = true,
        queued = true,

        anchor = "RIGHT",
        x = 0,
        y = 0,
    },

    targets = {
        enabled = true,

        font = ElvUI and 'PT Sans Narrow' or 'Arial Narrow',
        fontSize = 12,
        fontStyle = "OUTLINE",

        anchor = "BOTTOMRIGHT",
        x = 0,
        y = 0,

        color = { 1, 1, 1, 1 },
    },

    delays = {
        type = "__NA",
        fade = false,
        extend = true,
        elvuiCooldowns = false,

        font = ElvUI and 'PT Sans Narrow' or 'Arial Narrow',
        fontSize = 12,
        fontStyle = "OUTLINE",

        anchor = "TOPLEFT",
        x = 0,
        y = 0,

        color = { 1, 1, 1, 1 },
    },

    keybindings = {
        enabled = true,
        queued = true,

        font = ElvUI and "PT Sans Narrow" or "Arial Narrow",
        fontSize = 12,
        fontStyle = "OUTLINE",

        lowercase = false,

        queuedFont = ElvUI and "PT Sans Narrow" or "Arial Narrow",
        queuedFontSize = 12,
        queuedFontStyle = "OUTLINE",

        queuedLowercase = false,

        anchor = "TOPRIGHT",
        x = 1,
        y = -1,

        cPortOverride = true,
        cPortZoom = 0.6,

        color = { 1, 1, 1, 1 },
        queuedColor = { 1, 1, 1, 1 },
    },

}


local actionTemplate = {
    enabled = true,
    action = "wait",
    criteria = "",
    caption = "",
    description = "",

    -- Shared Modifiers
    chain = 0,  -- NYI
    early_chain_if = "",  -- NYI

    cycle_targets = 0,
    max_cycle_targets = 3,
    max_energy = 0,

    interrupt = 0,  --NYI
    interrupt_if = "",  --NYI
    interrupt_immediate = 0,  -- NYI

    travel_speed = nil,

    line_cd = 0,
    moving = 0,
    sync = "",

    use_while_casting = 0,
    use_off_gcd = 0,

    wait_on_ready = 0, -- NYI

    -- Call/Run Action List
    list_name = "default",
    strict = nil,

    -- Pool Resource
    wait = "0.5",
    for_next = 1,
    extra_amount = "0",

    -- Potion
    potion = "default",

    -- Variable
    op = "set",
    condition = "",
    default = "",
    value = "",
    value_else = "",
    var_name = "unnamed",

    -- Wait
    sec = 1,
}


local packTemplate = {
    spec = 0,
    builtIn = false,

    author = UnitName("player"),
    desc = "这是Hekili的行动清单.",
    source = "",
    date = date("%Y-%m-%d %H:%M"),
    warnings = "",

    hidden = false,

    lists = {
        precombat = {
        },
        default = {
        },
    }
}


local specTemplate = ns.specTemplate


-- Default Table
function Hekili:GetDefaults()
    local defaults = {
        global = {
            styles = {},
        },

        profile = {
            enabled = true,
            minimapIcon = false,
            autoSnapshot = true,

            toggles = {
                pause = {
                    key = "ALT-SHIFT-P",
                },

                snapshot = {
                    key = "ALT-SHIFT-[",                    
                },

                mode = {
                    key = "ALT-SHIFT-N",
                    -- type = "AutoSingle",
                    automatic = true,
                    single = true,
                    value = "automatic",
                },

                cooldowns = {
                    key = "ALT-SHIFT-R",
                    value = false,
                    override = false,
                    separate = false,
                },

                defensives = {
                    key = "ALT-SHIFT-T",
                    value = false,
                    separate = false,
                },

                potions = {
                    key = "",
                    value = false,
                },

                interrupts = {
                    key = "ALT-SHIFT-I",
                    value = false,
                    separate = false,
                },

                essences = {
                    key = "ALT-SHIFT-G",
                    value = true,
                    override = true,
                },

                custom1 = {
                    key = "",
                    value = false,
                    name = "Custom #1"
                },

                custom2 = {
                    key = "",
                    value = false,
                    name = "Custom #2"
                }
            },

            specs = {                              
                ['**'] = {
                    abilities = {
                        ['**'] = {
                            disabled = false,
                            toggle = "default",
                            clash = 0,
                            targetMin = 0,
                            targetMax = 0,
                            boss = false
                        }
                    },
                    items = {
                        ['**'] = {
                            disabled = false,
                            toggle = "default",
                            clash = 0,
                            targetMin = 0,
                            targetMax = 0,
                            boss = false,
                            criteria = nil
                        }
                    },                    
                    settings = {},
                    cooldowns = {},
                    utility = {},
                    defensives = {},
                    custom1 = {},
                    custom2 = {},
                },
            },

            packs = {
                ['**'] = packTemplate
            },                       

            notifications = {
                enabled = true,

                x = 0,
                y = 0,

                font = ElvUI and "Expressway" or "Arial Narrow",
                fontSize = 20,
                fontStyle = "OUTLINE",

                width = 600,
                height = 40,
            },

            displays = {
                Primary = {
                    enabled = true,
                    builtIn = true,

                    name = "Primary",

                    relativeTo = "SCREEN",
                    displayPoint = "TOP",
                    anchorPoint = "BOTTOM",

                    x = 0,
                    y = -225,

                    numIcons = 3,
                    order = 1,

                    flash = {
                        color = { 1, 0, 0, 1 },
                    },

                    glow = {
                        enabled = true,
                        mode = "autocast"
                    },
                },

                AOE = {
                    enabled = true,
                    builtIn = true,

                    name = "AOE",

                    x = 0,
                    y = -170,

                    numIcons = 3,
                    order = 2,

                    flash = { 
                        color = { 0, 1, 0, 1 },
                    },

                    glow = {
                        enabled = true,
                        mode = "autocast",
                    },
                },

                Cooldowns = {
                    enabled = true,
                    builtIn = true,

                    name = "Cooldowns",
                    filter = 'cooldowns',

                    x = 0,
                    y = -280,

                    numIcons = 1,
                    order = 3,

                    flash = {
                        color = { 0, 0, 1, 1 },
                    },

                    glow = {
                        enabled = true,
                        mode = "autocast",
                    },
                },

                Defensives = {
                    enabled = true,
                    builtIn = true,

                    name = "Defensives",
                    filter = 'defensives',

                    x = -110,
                    y = -225,

                    numIcons = 1,
                    order = 4,

                    flash = {
                        color = { 0, 0, 1, 1 },
                    },

                    glow = {
                        enabled = true,
                        mode = "autocast",
                    },
                },

                Interrupts = {
                    enabled = true,
                    builtIn = true,

                    name = "Interrupts",
                    filter = 'interrupts',

                    x = -55,
                    y = -225,

                    numIcons = 1,
                    order = 5,

                    flash = {
                        color = { 1, 1, 1, 1 },
                    },

                    glow = {
                        enabled = true,
                        mode = "autocast",
                    },
                },

                ['**'] = displayTemplate
            },

            -- STILL NEED TO REVISE.
            Clash = 0,
            -- (above)

            runOnce = {
            },

            clashes = {
            },
            trinkets = {
                ['**'] = {
                    disabled = false,
                    minimum = 0,
                    maximum = 0,
                }
            },

            interrupts = {
                pvp = {},
                encounters = {},
            },

            iconStore = {
                hide = false,
            },
        },
    }

    return defaults
end


do
    local shareDB = {
        displays = {},
        styleName = "",
        export = "",
        exportStage = 0,

        import = "",
        imported = {},
        importStage = 0
    }

    function Hekili:GetDisplayShareOption( info )
        local n = #info
        local option = info[ n ]

        if shareDB[ option ] then return shareDB[ option ] end
        return shareDB.displays[ option ]
    end


    function Hekili:SetDisplayShareOption( info, val, v2, v3, v4 )
        local n = #info
        local option = info[ n ]

        if type(val) == 'string' then val = val:trim() end
        if shareDB[ option ] then shareDB[ option ] = val; return end

        shareDB.displays[ option ] = val
        shareDB.export = ""
    end



    local frameStratas = ns.FrameStratas

    -- Display Config.
    function Hekili:GetDisplayOption( info )
        local n = #info
        local display, category, option = info[ 2 ], info[ 3 ], info[ n ]

        if category == "shareDisplays" then
            return self:GetDisplayShareOption( info )
        end

        local conf = self.DB.profile.displays[ display ]
        if category ~= option and category ~= 'main' then
            conf = conf[ category ]
        end

        if option == 'color' then return unpack( conf.color ) end
        if option == 'frameStrata' then return frameStratas[ conf.frameStrata ] or 3 end
        if option == 'name' then return display end

        return conf[ option ]
    end


    function Hekili:SetDisplayOption( info, val, v2, v3, v4 )
        local n = #info
        local display, category, option = info[ 2 ], info[ 3 ], info[ n ]
        local set = false

        if category == "shareDisplays" then
            self:SetDisplayShareOption( info, val, v2, v3, v4 )
            return
        end

        local conf = self.DB.profile.displays[ display ]
        if category ~= option and category ~= 'main' then conf = conf[ category ] end

        if option == 'color' or option == 'queuedColor' then
            conf[ option ] = { val, v2, v3, v4 }
            set = true
        elseif option == 'frameStrata' then
            conf.frameStrata = frameStratas[ val ] or "LOW"
            set = true
        end

        if not set then 
            val = type( val ) == 'string' and val:trim() or val
            conf[ option ] = val 
        end

        self:BuildUI()
    end


    local function GetNotifOption( info )
        local n = #info
        local option = info[ n ]

        local conf = Hekili.DB.profile.notifications

        return conf[ option ]
    end

    local function SetNotifOption( info, val )
        local n = #info
        local option = info[ n ]

        local conf = Hekili.DB.profile.notifications

        conf[ option ] = val
        Hekili:BuildUI()
    end

    local ACD = LibStub( "AceConfigDialog-3.0" )
    local LSM = LibStub( "LibSharedMedia-3.0" )
    local SF = SpellFlash or SpellFlashCore

    local fontStyles = {
        ["MONOCHROME"] = "Monochrome",
        ["MONOCHROME,OUTLINE"] = "Monochrome, Outline",
        ["MONOCHROME,THICKOUTLINE"] = "Monochrome, Thick Outline",
        ["NONE"] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline"
    }

    local fontElements = {
        font = {
            type = "select",
            name = "字体",
            order = 1,
            width = 1.5,
            dialogControl = 'LSM30_Font',
            values = LSM:HashTable("font"),
        },

        fontSize = {
            type = "range",
            name = "大小",
            order = 2,
            min = 8,
            max = 64,
            step = 1,
            width = 1.5
        },

        fontStyle = {
            type = "select",
            name = "风格",
            order = 3,
            values = fontStyles,
            width = 1.5
        },

        color = {
            type = "color",
            name = "颜色",
            order = 4, 
            width = 1.5           
        }
    }

    local anchorPositions = {
        TOP = '上',
        TOPLEFT = '上左',
        TOPRIGHT = '上右',
        BOTTOM = '下',
        BOTTOMLEFT = '下左',
        BOTTOMRIGHT = '下右',
        LEFT = '左',
        LEFTTOP = '左上',
        LEFTBOTTOM = '左下',
        RIGHT = '右',
        RIGHTTOP = '右上',
        RIGHTBOTTOM = '右下',
    }


    local realAnchorPositions = {
        TOP = '上',
        TOPLEFT = '上左',
        TOPRIGHT = '上右',
        BOTTOM = '下',
        BOTTOMLEFT = '下左',
        BOTTOMRIGHT = '下右',
        CENTER = "中",
        LEFT = '左',
        RIGHT = '右',
    }


    local function getOptionTable( info, notif )
        local disp = info[2]
        local tab = Hekili.Options.args.displays

        if notif then
            tab = tab.args.nPanel
        else
            tab = tab.plugins[ disp ][ disp ]
        end

        for i = 3, #info do
            tab = tab.args[ info[i] ]
        end

        return tab
    end

    local function rangeXY( info, notif )
        local tab = getOptionTable( info, notif )

        local monitor = ( tonumber( GetCVar( 'gxMonitor' ) ) or 0 ) + 1
        local resolutions = { GetScreenResolutions() }
        local resolution = resolutions[ GetCurrentResolution() ] or GetCVar( "gxWindowedResolution" )
        local width, height = resolution:match( "(%d+)x(%d+)" )

        width = tonumber( width )
        height = tonumber( height )

        for i, str in ipairs( resolutions ) do
            local w, h = str:match( "(%d+)x(%d+)" )
            w, h = tonumber( w ), tonumber( h )

            if w > width then width = w end
            if h > height then height = h end
        end

        tab.args.x.min = -1 * width
        tab.args.x.max = width
        tab.args.x.softMin = -1 * width * 0.5
        tab.args.x.softMax = width * 0.5

        tab.args.y.min = -1 * height
        tab.args.y.max = height
        tab.args.y.softMin = -1 * height * 0.5
        tab.args.y.softMax = height * 0.5
    end


    local function setWidth( info, field, condition, if_true, if_false )
        local tab = getOptionTable( info )

        if condition then
            tab.args[ field ].width = if_true or "full"
        else
            tab.args[ field ].width = if_false or "full"
        end
    end


    local function rangeIcon( info )
        local tab = getOptionTable( info )

        local display = info[2]
        local data = display and Hekili.DB.profile.displays[ display ]

        if data then
            tab.args.x.min = -1 * max( data.primaryWidth, data.queue.width )
            tab.args.x.max = max( data.primaryWidth, data.queue.width )

            tab.args.y.min = -1 * max( data.primaryHeight, data.queue.height )
            tab.args.y.max = max( data.primaryHeight, data.queue.height )

            return
        end

        tab.args.x.min = -50
        tab.args.x.max = 50

        tab.args.y.min = -50
        tab.args.y.max = 50
    end


    local function newDisplayOption( db, name, data, pos )
        name = tostring( name )

        local fancyName

        if name == "Defensives" then fancyName = AtlasToString( "nameplates-InterruptShield" ) .. " " .. name
        elseif name == "Interrupts" then fancyName = AtlasToString( "communities-icon-redx" ) .. " " .. name
        elseif name == "Cooldowns" then fancyName = NewFeature .. " " .. name
        else fancyName = name end

        return {
            ['btn'..name] = {
                type = 'execute',
                name = fancyName,
                desc = data.desc,
                order = 10 + pos,
                func = function () ACD:SelectGroup( "Hekili", "displays", name ) end,
            },

            [name] = {
                type = 'group',
                name = function ()
                    if data.builtIn then return '|cFF00B4FF' .. fancyName .. '|r' end
                    return fancyName
                end,
                childGroups = "tab",
                desc = data.desc,
                order = 100 + pos,
                args = {
                    main = {
                        type = 'group',
                        name = "主体",
                        desc = "包括显示位置, 图标, 主图标大小/形状等.",
                        order = 1,

                        args = {
                            enabled = {
                                type = "toggle",
                                name = "启用",
                                desc = "如果禁用, 此显示在任何情况下都不会出现.",
                                order = 0.5,
                                hidden = function () return name == "Primary" or name == "AOE" or name == "Cooldowns"  or name == "Defensives" or name == "Interrupts" end
                            },

                            elvuiCooldown = {
                                type = "toggle",
                                name = NewFeature .. " 应用ElvUI冷却风格",
                                desc = "如果安装了ElvUI, 可以将ElvUI的冷却时间样式应用到队列图标上.\n\n禁用此设置需要重新加载用户界面(|cFFFFD100/reload|r).",
                                width = "full",
                                order = 0.51,
                                hidden = function () return _G["ElvUI"] == nil end,
                            },

                            numIcons = {
                                type = 'range',
                                name = "图标显示",
                                desc = "指定要显示的建议数量. 每个图标都显示了一个额外的时间推进步骤.",
                                min = 1,
                                max = 10,
                                step = 1,
                                width = "full",
                                order = 1,
                                hidden = function( info, val )
                                    local n = #info
                                    local display = info[2]

                                    if display == "Defensives" or display == "Interrupts" then
                                        return true
                                    end

                                    return false
                                end,
                            },

                            pos = {
                                type = "group",
                                inline = true,
                                name = function( info ) rangeXY( info ); return "Position" end,
                                order = 10,

                                args = {
                                    --[[
                                    relativeTo = {
                                        type = "select",
                                        name = "锚定到",
                                        values = {
                                            SCREEN = "屏幕",
                                            PERSONAL = "个人资源展示",
                                            CUSTOM = "自定义"
                                        },
                                        order = 1,
                                        width = 1.49,
                                    },

                                    customFrame = {
                                        type = "input",
                                        name = "自定义框架",
                                        desc = "指定此显示将锚定到的框架的名称.\n" ..
                                                "如果框架不存在, 将不显示.",
                                        order = 1.1,
                                        width = 1.49,
                                        hidden = function() return data.relativeTo ~= "CUSTOM" end,
                                    },

                                    setParent = {
                                        type = "toggle",
                                        name = "将父级设置为锚点",
                                        desc = "如果勾选, 当锚显示/隐藏时, 将显示/隐藏.",
                                        order = 3.9,
                                        width = 1.49,
                                        hidden = function() return data.relativeTo == "SCREEN" end,
                                    },

                                    preXY = {
                                        type = "description",
                                        name = " ",
                                        width = "full",
                                        order = 97
                                    }, ]]

                                    x = {
                                        type = "range",
                                        name = "X",
                                        desc = "设置此显示的主图标相对于屏幕中央的水平位置. " ..
                                            "负值将向左移动显示正值将向右移动.",
                                        min = -512,
                                        max = 512,
                                        step = 1,

                                        order = 98,
                                        width = 1.49,
                                    },

                                    y = {
                                        type = "range",
                                        name = "Y",
                                        desc = "设置此显示的主图标相对于屏幕中央的垂直位置. " ..
                                            "负值将向下移动正值将使其向上移动.",
                                        min = -384,
                                        max = 384,
                                        step = 1,

                                        order = 99,
                                        width = 1.49,
                                    },
                                },
                            },

                            primaryIcon = {
                                type = "group",                                
                                name = "主要图标",
                                inline = true,
                                order = 15,
                                args = {
                                    primaryWidth = {
                                        type = "range",
                                        name = "宽度",
                                        desc = "指定主图标的宽度" .. name .. "显示.",
                                        min = 10,
                                        max = 500,
                                        step = 1,

                                        width = 1.49,
                                        order = 1,
                                    },

                                    primaryHeight = {
                                        type = "range",
                                        name = "高度",
                                        desc = "指定主图标的高度" .. name .. "显示.",
                                        min = 10,
                                        max = 500,
                                        step = 1,

                                        width = 1.49,
                                        order = 2,                                            
                                    },
                                },
                            },

                            advancedFrame = {
                                type = "group",
                                name = "框架层",
                                inline = true,
                                order = 16,
                                args = {
                                    frameStrata = {
                                        type = "select",
                                        name = "层级",
                                        desc =  "框架层级决定了这个显示是在哪个图形层上绘制的.\n" ..
                                                "默认层为MEDIUM.",
                                        values = {
                                            "BACKGROUND",
                                            "LOW",
                                            "MEDIUM",
                                            "HIGH",
                                            "DIALOG",
                                            "FULLSCREEN",
                                            "FULLSCREEN_DIALOG",
                                            "TOOLTIP"
                                        },
                                        width = 1.49,
                                        order = 1,
                                    },

                                    frameLevel = {
                                        type = "range",
                                        name = "级别",
                                        desc = "框架级别决定了显示器在其当前图层中的位置.\n\n" ..
                                                "默认值为|cFFFFD10010|r.",
                                        min = 1,
                                        max = 10000,
                                        step = 1,
                                        width = 1.49,
                                        order = 2,
                                    }
                                }
                            },

                            zoom = {
                                type = "range",
                                name = "图标放大",
                                desc = "选择此显示中的图标纹理的缩放百分比. (大约30%的人会删掉默认的暴雪边框.)",
                                min = 0,
                                max = 100,
                                step = 1,

                                width = 1.49,
                                order = 20,
                            },

                            keepAspectRatio = {
                                type = "toggle",
                                name = "保持长宽比",
                                desc = "如果你的主图标或队列图标不是正方形的，勾选这个选项将防止图标纹理 " ..
                                    "被拉伸和扭曲，而是裁剪这些纹理.",
                                disabled = function( info, val )
                                    return not ( data.primaryHeight ~= data.primaryWidth or ( data.numIcons > 1 and data.queue.height ~= data.queue.width ) )
                                end,
                                width = 1.49,
                                order = 25,
                            },
                        },
                    },

                    queue = {
                        type = "group",
                        name = "队列",
                        desc = "当可以显示多个图标时包括定位, 大小, 形状和位置设置.",
                        order = 2,
                        disabled = function ()
                            return data.numIcons == 1
                        end,

                        args = {
                            elvuiCooldown = {
                                type = "toggle",
                                name = NewFeature .. " 应用ElvUI冷却风格",
                                desc = "如果安装了ElvUI, 可以将ElvUI的冷却时间样式应用到队列图标上.\n\n禁用此设置需要重新加载用户界面(|cFFFFD100/reload|r).",
                                width = "full",
                                order = 0.5,
                                hidden = function () return _G["ElvUI"] == nil end,
                            },

                            anchor = {
                                type = 'select',
                                name = '锚定到',
                                desc = "选择主图标上的点将把队列图标附加到主图标上.",
                                values = anchorPositions,
                                width = "full",
                                order = 1,
                            },

                            offsetX = {
                                type = 'range',
                                name = '队列水平偏移',
                                desc = '指定队列相对于此显示的主图标上的定位点的偏移量(以像素为单位).',
                                min = -100,
                                max = 500,
                                step = 1,
                                width = "full",
                                order = 2,
                            },

                            offsetY = {
                                type = 'range',
                                name = '队列垂直偏移',
                                desc = '指定队列相对于此显示的主图标上的定位点的偏移量(以像素为单位).',
                                min = -100,
                                max = 500,
                                step = 1,
                                width = "full",
                                order = 2,
                            },


                            direction = {
                                type = 'select',
                                name = '方向',
                                desc = "选择图标队列的方向.",
                                values = {
                                    TOP = '上',
                                    BOTTOM = '下',
                                    LEFT = '左',
                                    RIGHT = '右'
                                },
                                width = "full",
                                order = 5,
                            },


                            width = {
                                type = 'range',
                                name = '宽度',
                                desc = "选择图标队列的宽度.",
                                min = 10,
                                max = 500,
                                step = 1,
                                bigStep = 1,
                                order = 10,
                                width = "full"
                            },

                            height = {
                                type = 'range',
                                name = '高度',
                                desc = "选择图标队列的高度.",
                                min = 10,
                                max = 500,
                                step = 1,
                                bigStep = 1,
                                order = 11,
                                width = "full"
                            },

                            spacing = {
                                type = 'range',
                                name = '间隔',
                                desc = "选择队列中图标之间的像素数.",
                                min = ( data.queue.direction == "LEFT" or data.queue.direction == "RIGHT" ) and -data.queue.width or -data.queue.height,
                                max = 500,
                                step = 1,
                                order = 16,
                                width = 'full'
                            },
                        },
                    },

                    visibility = {
                        type = 'group',
                        name = '可见度',
                        desc = "PvE/PvP中的可见度和透明度设置.",
                        order = 3,

                        args = {

                            advanced = {
                                type = "toggle",
                                name = "高级",
                                desc = "如果勾选, 则提供了微调显示可见性和透明度的选项.",
                                width = "full",
                                order = 1,
                            },

                            simple = {
                                type = 'group',
                                inline = true,
                                name = "",
                                hidden = function() return data.visibility.advanced end,
                                get = function( info )
                                    local option = info[ #info ]

                                    if option == 'pveAlpha' then return data.visibility.pve.alpha
                                    elseif option == 'pvpAlpha' then return data.visibility.pvp.alpha end
                                end,
                                set = function( info, val )
                                    local option = info[ #info ]

                                    if option == 'pveAlpha' then data.visibility.pve.alpha = val
                                    elseif option == 'pvpAlpha' then data.visibility.pvp.alpha = val end

                                    Hekili:BuildUI()
                                end,
                                order = 2,
                                args = {
                                    pveAlpha = {
                                        type = "range",
                                        name = "PvE透明度",
                                        desc = "设置PvE战斗时显示的透明度. 如果设置为0, 则在PvE中不会出现.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        order = 1,
                                        width = "full",
                                    },
                                    pvpAlpha = {
                                        type = "range",
                                        name = "PvP透明度",
                                        desc = "设置PvP战斗时显示的透明度. 如果设置为0, 则在PvP中不会出现.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        order = 1,
                                        width = "full",
                                    },
                                }
                            },

                            pveComplex = {
                                type = 'group',
                                inline = true,
                                name = "PvE",
                                get = function( info )
                                    local option = info[ #info ]

                                    return data.visibility.pve[ option ]
                                end,
                                set = function( info, val )
                                    local option = info[ #info ]

                                    data.visibility.pve[ option ] = val
                                    Hekili:BuildUI()
                                end,
                                hidden = function() return not data.visibility.advanced end,
                                order = 2,
                                args = {
                                    always = {
                                        type = "range",                                        
                                        name = "总是",
                                        desc = "如果非零, 在PvE时无论是否在战斗中始终会显示.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full",
                                        order = 1,
                                    },

                                    combat = {
                                        type = "range",
                                        name = "战斗",
                                        desc = "如果非零, 在PvE战斗中始终显示.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full",
                                        order = 2,
                                    },

                                    target = {
                                        type = "range",
                                        name = "目标",
                                        desc = "如果非零, 当你有一个可攻击的PvE目标时会始终显示.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full",
                                        order = 3,
                                    },

                                    combatTarget = {
                                        type = "range",
                                        name = "战斗/目标",
                                        desc = "如果非零, 当你在战斗中并且有一个可攻击的PvE目标时会始终显示.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full",
                                        order = 4,
                                    },

                                    hideMounted = {
                                        type = "toggle",
                                        name = "上坐骑时隐藏",
                                        desc = "如果勾选, 则当上马时显示将不可见(除非在战斗中).",
                                        width = "full",
                                        order = 1.1,
                                    }
                                },
                            },

                            pvpComplex = {
                                type = 'group',
                                inline = true,
                                name = "PvP",
                                get = function( info )
                                    local option = info[ #info ]

                                    return data.visibility.pvp[ option ]
                                end,
                                set = function( info, val )
                                    local option = info[ #info ]

                                    data.visibility.pvp[ option ] = val
                                    Hekili:BuildUI()
                                    Hekili:UpdateDisplayVisibility()
                                end,
                                hidden = function() return not data.visibility.advanced end,
                                order = 2,
                                args = {
                                    always = {
                                        type = "range",                                        
                                        name = "总是",
                                        desc = "如果非零, 在PvP时无论是否在战斗中始终会显示.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full",
                                        order = 1,
                                    },

                                    combat = {
                                        type = "range",
                                        name = "战斗",
                                        desc = "如果非零, 在PvP战斗中始终显示.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full",
                                        order = 2,
                                    },

                                    target = {
                                        type = "range",
                                        name = "目标",
                                        desc = "如果非零, 当你有一个可攻击的PvP目标时会始终显示.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full",
                                        order = 3,
                                    },

                                    combatTarget = {
                                        type = "range",
                                        name = "战斗/目标",
                                        desc = "如果非零, 当你在战斗中并且有一个可攻击的PvP目标时会始终显示.",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full",
                                        order = 4,
                                    },

                                    hideMounted = {
                                        type = "toggle",
                                        name = "上坐骑时隐藏",
                                        desc = "如果勾选, 则当上马时显示将不可见(除非在战斗中).",
                                        width = "full",
                                        order = 1.1,
                                    }
                                },
                            },
                        },
                    },

                    keybindings = {
                        type = "group",
                        name = "键绑定",
                        desc = "显示图标上的键绑定文本选项.",
                        order = 7,

                        args = {
                            enabled = {
                                type = "toggle",
                                name = "启用",
                                order = 1,
                                width = 'full',                                
                            },

                            queued = {
                                type = "toggle",
                                name = "为队列图标启用",
                                order = 2,
                                width = "full",
                                disabled = function () return data.keybindings.enabled == false end,
                            },

                            pos = {
                                type = "group",
                                inline = true,
                                name = function( info ) rangeIcon( info ); return "Position" end,
                                order = 3,
                                args = {
                                    anchor = {
                                        type = "select",
                                        name = '锚点',
                                        order = 2,
                                        width = 'full',
                                        values = realAnchorPositions
                                    },

                                    x = {
                                        type = "range",
                                        name = "X偏移",
                                        order = 3,
                                        width = "full",
                                        min = -max( data.primaryWidth, data.queue.width ),
                                        max = max( data.primaryWidth, data.queue.width ),
                                        disabled = function( info )
                                            return false
                                        end,
                                        step = 1,
                                    },

                                    y = {
                                        type = "range",
                                        name = "Y偏移",
                                        order = 4,
                                        width = "full",
                                        min = -max( data.primaryHeight, data.queue.height ),
                                        max = max( data.primaryHeight, data.queue.height ),
                                        step = 1,
                                    }                                    
                                }
                            },

                            textStyle = {
                                type = "group",
                                inline = true,
                                name = "文本",
                                order = 5,
                                args = fontElements,
                            },

                            lowercase = {
                                type = "toggle",
                                name = "使用小写",
                                order = 5.1,
                                width = "full",
                            },

                            separateQueueStyle = {
                                type = "toggle",
                                name = "对队列使用不同的设置",
                                order = 6,
                                width = "full",
                            },

                            queuedTextStyle = {
                                type = "group",
                                inline = true,
                                name = "队列文本样式",
                                order = 7,
                                hidden = function () return not data.keybindings.separateQueueStyle end,
                                args = {
                                    queuedFont = {
                                        type = "select",
                                        name = "Font",
                                        order = 1,
                                        width = 1.5,
                                        dialogControl = 'LSM30_Font',
                                        values = LSM:HashTable("font"),
                                    },
                            
                                    queuedFontSize = {
                                        type = "range",
                                        name = "大小",
                                        order = 2,
                                        min = 8,
                                        max = 64,
                                        step = 1,
                                        width = 1.5
                                    },
                            
                                    queuedFontStyle = {
                                        type = "select",
                                        name = "样式",
                                        order = 3,
                                        values = fontStyles,
                                        width = 1.5
                                    },
                            
                                    queuedColor = {
                                        type = "color",
                                        name = "颜色",
                                        order = 4, 
                                        width = 1.5           
                                    }
                                },
                            },

                            queuedLowercase = {
                                type = "toggle",
                                name = "在队列中使用小写",
                                order = 7.1,
                                width = "full",
                                hidden = function () return not data.keybindings.separateQueueStyle end,
                            },

                            cPort = {
                                name = NewFeature.."控制台端口",
                                type = "group",
                                inline = true,
                                order = 10,
                                args = {
                                    cPortOverride = {
                                        type = "toggle",
                                        name = "使用控制台端口按钮",
                                        order = 6,
                                        width = "full",
                                    },
        
                                    cPortZoom = {
                                        type = "range",
                                        name = "控制台端口按钮缩放",
                                        desc = "控制台端口按钮纹理周围通常有大量空白填充. " ..
                                            "放大后会移除一些填充物以帮助图标上的按钮贴合. 默认值是|cFFFFD1000.6|r.",
                                        order = 7,
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        width = "full"
                                    },
                                },
                                hidden = function() return ConsolePort == nil end,
                            },

                        }
                    },

                    border = {
                        type = "group",
                        name = "边框",
                        desc = "启用/禁用或设置图标边框的颜色.\n\n" ..
                            "如果你使用Masque或其他工具给你的Hekili图标添加皮肤你可能会想禁用这个功能.",
                        order = 4,

                        args = {
                            enabled = {
                                type = "toggle",
                                name = "启用",
                                desc = "如果启用, 此显示中的每个图标将有一个薄薄的边框.",
                                order = 1,
                                width = "full",
                            },

                            fit = {
                                type = "toggle",
                                name = "边框内部",
                                desc = "如果启用, 启用边框时按钮边框将位于按钮内部(而不是其周围).",
                                order = 2,
                                width = "full",
                            },

                            thickness = {
                                type = "range",
                                name = NewFeature .. " 边框厚度",
                                desc = "确定边框厚度(宽度). 默认是1.",
                                softMin = 1,
                                softMax = 20,
                                step = 1,
                                order = 2.5,
                                width = "full",
                            },

                            coloring = {
                                type = "select",
                                name = "着色模式",
                                desc = "指定是否使用职业颜色边框或指定颜色.",
                                width = "full",
                                order = 3,
                                values = {
                                    class = "使用职业颜色",
                                    custom = "指定自定义颜色"
                                },
                                disabled = function() return data.border.enabled == false end,
                            },

                            color = {
                                type = "color",
                                name = "边框颜色",
                                desc = "启用边框后边框将使用此颜色.",
                                order = 4,
                                width = "full",
                                disabled = function () return data.border.enabled == false end,
                                hidden = function () return data.border.coloring ~= 'custom' end,
                            }
                        }
                    },

                    range = {
                        type = "group",
                        name = "范围",
                        desc = "范围检查警告的首选项(如果需要).",
                        order = 5,
                        args = {
                            enabled = {
                                type = "toggle",
                                name = "启用",
                                desc = "如果启用, 当你不在敌人的射程范围内时该插件将提供一个红色警告高亮显示.",
                                width = "full",
                                order = 1,
                            },

                            type = {
                                type = "select",
                                name = '范围检查',
                                desc = "选择此显示要使用的范围检查和范围颜色的种类.\n\n" ..
                                    "|cFFFFD100技能|r - 每种技能在超出范围时都会以红色高亮显示.\n\n" ..
                                    "|cFFFFD100近战攻击|r - 如果你在近战范围之外所有的技能都会用红色高亮显示.\n\n" ..
                                    "|cFFFFD100不含|r - 如果一个技能不在范围内将不建议使用.",
                                values = {
                                    ability = "每个技能",
                                    melee = "近战攻击范围",
                                    xclude = "不含范围外"
                                },
                                width = "full",
                                order = 2,
                                disabled = function () return data.range.enabled == false end,
                            }
                        }
                    },

                    glow = {
                        type = "group",
                        name = "发光",
                        desc = "首选发光或叠加.",
                        order = 6,
                        args = {
                            enabled = {
                                type = "toggle",
                                name = "启用",
                                desc = "如果启用, 当第一个图标的技能激活高亮(或叠加)时它也将在此显示高亮.",
                                width = "full",
                                order = 1,
                            },

                            queued = {
                                type = "toggle",
                                name = "为队列图标启用",
                                desc = "如果启用, 有技能激活高亮(或叠加)也会在你的队列中高亮.\n\n" ..
                                    "这可能并不理想, 到了未来某个节点高亮可能已经不再是正确的了.",
                                width = "full",
                                order = 2,
                                disabled = function() return data.glow.enabled == false end,
                            },

                            mode = {
                                type = "select",
                                name = "高亮风格",
                                desc = "为显示选择高亮风格.",
                                width = "full",
                                order = 3,
                                values = {
                                    default = "默认按钮高亮",
                                    autocast = "自动高亮",
                                    pixel = "像素高亮",
                                },
                                disabled = function() return data.glow.enabled == false end,
                            },

                            coloring = {
                                type = "select",
                                name = "着色模式",
                                desc = "选择此高亮效果的着色模式.",
                                width = "full",
                                order = 4,
                                values = {
                                    default = "使用默认颜色",
                                    class = "使用职业颜色",
                                    custom = "指定一个自定义颜色"
                                },
                                disabled = function() return data.glow.enabled == false end,
                            },

                            color = {
                                type = "color",
                                name = "高亮颜色",
                                desc = "为显示选择自定义的高亮颜色.",
                                width = "full",
                                order = 5,
                                hidden = function() return data.glow.coloring ~= "custom" end,
                            },
                        },
                    },

                    flash = {
                        type = "group",
                        name = "SpellFlash",
                        desc = function ()
                            if SF then
                                return "如果启用, 该插件可以在推荐使用时在技能栏上闪烁技能."
                            end
                            return "该功能需要SpellFlash插件或库才能正常运行."
                        end,
                        order = 8,
                        args = {
                            warning = {
                                type = "description",
                                name = "这些设置不可用, 因为没有安装或禁用SpellFlash插件/库所以无法使用.",
                                order = 0,
                                fontSize = "medium",
                                width = "full",
                                hidden = function () return SF ~= nil end,
                            },

                            enabled = {
                                type = "toggle",
                                name = "启用",
                                desc = "如果启用, 该插件将在此显示的第一个推荐技能上显示彩色高亮.",

                                width = "full",
                                order = 1,
                                hidden = function () return SF == nil end,
                            },

                            color = {
                                type = "color",
                                name = "颜色",
                                desc = "指定SpellFlash高亮颜色.",
                                order = 2,

                                width = "full",
                                hidden = function () return SF == nil end,
                            },

                            suppress = {
                                type = "toggle",
                                name = "隐藏显示",
                                desc = "如果选中, 该插件将不显示此显示并仅通过SpellFlash进行推荐.",
                                order = 3,
                                width = "full",
                                hidden = function () return SF == nil end,
                            }
                        },
                    },

                    captions = {
                        type = "group",
                        name = "解释",
                        desc = "标题是简短的描述有时(很少)在动作列表中用来描述为什么要显示动作.",
                        order = 9,
                        args = {
                            enabled = {
                                type = "toggle",
                                name = "启用",
                                desc = "如果启用, 当显示的第一个功能具有描述性标题时将显示该标题.",
                                order = 1,
                                width = "full",
                            },

                            queued = {
                                type = "toggle",
                                name = "为队列图标启用",
                                desc = "如果启用, 将酌情显示队列能力的描述性标题.",
                                order = 2,
                                width = "full",                                
                                disabled = function () return data.captions.enabled == false end,
                            },

                            position = {
                                type = "group",
                                inline = true,
                                name = function( info ) rangeIcon( info ); return "Position" end,
                                order = 3,
                                args = {
                                    align = {
                                        type = "select",                                        
                                        name = "对齐",
                                        order = 1,
                                        width = "full",
                                        values = {
                                            LEFT = "左",
                                            RIGHT = "右",
                                            CENTER = "中"
                                        },
                                    },

                                    anchor = {
                                        type = "select",
                                        name = '锚点',
                                        order = 2,
                                        width = 'full',
                                        values = {
                                            TOP = '高',
                                            BOTTOM = '低',
                                        }
                                    },

                                    x = {
                                        type = "range",
                                        name = "X偏移",
                                        order = 3,
                                        width = "full",
                                        step = 1,
                                    },

                                    y = {
                                        type = "range",
                                        name = "Y偏移",
                                        order = 4,
                                        width = "full",
                                        step = 1,
                                    }
                                }
                            },

                            textStyle = {
                                type = "group",
                                inline = true,
                                name = "文本",
                                order = 4,
                                args = fontElements,
                            },
                        }
                    },

                    targets = {
                        type = "group",
                        name = "目标",
                        desc = "目标计数指示器可以显示第一个建议上.",
                        order = 10,
                        args = {
                            enabled = {
                                type = "toggle",
                                name = "启用",
                                desc = "如果启用, 该插件将显示此显示中活动(或虚拟)目标的数量.",
                                order = 1,
                                width = "full",
                            },

                            pos = {
                                type = "group",
                                inline = true,
                                name = function( info ) rangeIcon( info ); return "位置" end,
                                order = 2,
                                args = {
                                    anchor = {
                                        type = "select",
                                        name = "锚点到",
                                        values = realAnchorPositions,
                                        order = 1,
                                        width = "full",
                                    },

                                    x = {
                                        type = "range",
                                        name = "X偏移",
                                        min = -max( data.primaryWidth, data.queue.width ),
                                        max = max( data.primaryWidth, data.queue.width ),
                                        step = 1,
                                        order = 2,
                                        width = "full",
                                    },

                                    y = {
                                        type = "range",
                                        name = "Y偏移",
                                        min = -max( data.primaryHeight, data.queue.height ),
                                        max = max( data.primaryHeight, data.queue.height ),
                                        step = 1,
                                        order = 2,
                                        width = "full",
                                    }
                                }
                            },

                            textStyle = {
                                type = "group",
                                inline = true,
                                name = "文本",
                                order = 3,
                                args = fontElements,
                            },
                        }
                    },

                    delays = {
                        type = "group",
                        name = "延迟",
                        desc = "当一个技能在未来一段时间被推荐时，颜色指示器或倒数计时器 " ..
                            "可以传达存在延迟的信息.",
                        order = 11,
                        args = {
                            type = {
                                type = "select",
                                name = "指示器",
                                desc = "指定在施放技能之前应等待的指示器的类型.",
                                values = {
                                    __NA = "无指示器",
                                    ICON = "显示图标(颜色)",
                                    TEXT = "显示文本(倒计时)",
                                },                        
                                width = "full",
                                order = 1,
                            },

                            extend = {
                                type = "toggle",
                                name = "延长冷却时间",
                                desc = "如果选中, 主图标的冷却时间扫描将继续直到该技能被使用为止.",
                                width = "full",
                                order = 1.4,
                            },

                            fade = {
                                type = "toggle",
                                name = "淡化无法使用",
                                desc = "当你应该等待才能使用该技能时淡出主图标, 类似于当技能缺少所需资源时.",
                                width = "full",
                                order = 1.5
                            },

                            pos = {
                                type = "group",
                                inline = true,
                                name = function( info ) rangeIcon( info ); return "位置" end,
                                order = 2,
                                args = {
                                    anchor = {
                                        type = "select",
                                        name = '锚点',
                                        order = 2,
                                        width = 'full',
                                        values = realAnchorPositions
                                    },

                                    x = {
                                        type = "range",
                                        name = "X偏移",
                                        order = 3,
                                        width = "full",
                                        min = -max( data.primaryWidth, data.queue.width ),
                                        max = max( data.primaryWidth, data.queue.width ),
                                        step = 1,
                                    },

                                    y = {
                                        type = "range",
                                        name = "Y偏移",
                                        order = 4,
                                        width = "full",
                                        min = -max( data.primaryHeight, data.queue.height ),
                                        max = max( data.primaryHeight, data.queue.height ),
                                        step = 1,
                                    }                                    
                                }
                            },

                            textStyle = {
                                type = "group",
                                inline = true,
                                name = "文本",
                                order = 3,
                                args = fontElements,
                                hidden = function () return data.delays.type ~= "TEXT" end,
                            },
                        }
                    },

                    indicators = {
                        type = "group",
                        name = "指示器",
                        desc = "指示器是可以指示目标改变或(稀有)取消光环的小图标.",
                        order = 11,
                        args = {
                            enabled = {
                                type = "toggle",
                                name = "启用",
                                desc = "如果启用, 目标交换、光环取消等小指示器会出现在主图标上.",
                                order = 1,
                                width = "full",
                            },

                            queued = {
                                type = "toggle",
                                name = "为队列图标启用",
                                desc = "如果启用, 这些指示器将在适当时显示在队列图标和主图标上.",
                                order = 2,
                                width = "full",
                                disabled = function () return data.indicators.enabled == false end,
                            },

                            pos = {
                                type = "group",
                                inline = true,
                                name = function( info ) rangeIcon( info ); return "位置" end,
                                order = 2,
                                args = {
                                    anchor = {
                                        type = "select",
                                        name = "锚点到",
                                        values = realAnchorPositions,
                                        order = 1,
                                        width = "full",
                                    },

                                    x = {
                                        type = "range",
                                        name = "X偏移",
                                        min = -max( data.primaryWidth, data.queue.width ),
                                        max = max( data.primaryWidth, data.queue.width ),
                                        step = 1,
                                        order = 2,
                                        width = "full",
                                    },

                                    y = {
                                        type = "range",
                                        name = "Y偏移",
                                        min = -max( data.primaryHeight, data.queue.height ),
                                        max = max( data.primaryHeight, data.queue.height ),
                                        step = 1,
                                        order = 2,
                                        width = "full",
                                    }
                                }
                            },                            
                        }
                    },
                },
            },
        }
    end


    function Hekili:EmbedDisplayOptions( db )
        db = db or self.Options
        if not db then return end

        local section = db.args.displays or {
            type = "group",
            name = "显示",
            childGroups = "tree",
            cmdHidden = true,
            get = 'GetDisplayOption',
            set = 'SetDisplayOption',
            order = 30,

            args = {
                header = {
                    type = "description",
                    name = "Hekili最多具有四个内置显示(以蓝色标识), 可以显示各种建议." ..
                        "插件的建议基于优先级, " ..
                        "这些优先级通常(但不限于)基于SimulationCraft配置文件, " ..
                        "以便可以将性能与模拟结果进行比较.",
                    fontSize = "medium",
                    width = "full",
                    order = 1,
                },

                displays = {
                    type = "header",
                    name = "显示",
                    order = 10,                    
                },


                nPanelHeader = {
                    type = "header",
                    name = "通知面板",
                    order = 950,
                },

                nPanelBtn = {
                    type = "execute",
                    name = "通知面板",
                    desc = "当战斗中的设置被更改或切换时, 通知面板会提供 " ..
                        "简短的更新.",
                    func = function ()
                        ACD:SelectGroup( "Hekili", "displays", "nPanel" )
                    end,
                    order = 951,
                },

                nPanel = {
                    type = "group",
                    name = "|cFF1EFF00通知面板|r",
                    desc = "当战斗中的设置被更改或切换时, 通知面板会提供 " ..
                        "简短的更新.",
                    order = 952,
                    get = GetNotifOption,
                    set = SetNotifOption,
                    args = {
                        enabled = {
                            type = "toggle",
                            name = "启用",
                            order = 1,
                            width = "full",
                        },

                        posRow = {
                            type = "group",
                            name = function( info ) rangeXY( info, true ); return "位置" end,
                            inline = true,
                            order = 2,
                            args = {
                                x = {
                                    type = "range",
                                    name = "X",
                                    desc = "输入通知面板相对于屏幕中心的水平位置." ..
                                        "负值使面板向左移动; " ..
                                        "正值使面板向右移动.",
                                    min = -512,
                                    max = 512,
                                    step = 1,

                                    width = "full",
                                    order = 1,
                                },

                                y = {
                                    type = "range",
                                    name = "Y",
                                    desc = "输入通知面板相对于屏幕中心的垂直位置." ..
                                        "负值使面板向下移动; " ..
                                        "正值使面板向上移动.",
                                    min = -384,
                                    max = 384,
                                    step = 1,

                                    width = "full",
                                    order = 2,
                                },
                            }
                        },

                        sizeRow = {
                            type = "group",
                            name = "大小",
                            inline = true,
                            order = 3,
                            args = {
                                width = {
                                    type = "range",
                                    name = "宽度",
                                    min = 50,
                                    max = 1000,
                                    step = 1,

                                    width = "full",
                                    order = 1,
                                },

                                height = {
                                    type = "range",
                                    name = "高度",
                                    min = 20,
                                    max = 600,
                                    step = 1,

                                    width = "full",
                                    order = 2,
                                },
                            }
                        },

                        fontGroup = {
                            type = "group",
                            inline = true,
                            name = "文本",

                            order = 5,
                            args = fontElements,
                        },
                    }                    
                },

                fontHeader = {
                    type = "header",
                    name = "字体",
                    order = 960,
                },

                fontWarn = {
                    type = "description",
                    name = "更改下面的字体将修改所有显示上的|cFFFF0000所有|r文本.\n" ..
                            "要单独修改文本, 请选择显示(在左侧)并选择相应的文本.",
                    order = 960.01,
                },
            
                font = {
                    type = "select",
                    name = "字体",
                    order = 960.1,
                    width = 1.5,
                    dialogControl = 'LSM30_Font',
                    values = LSM:HashTable("font"),
                    get = function( info )
                        -- Display the information from Primary, Keybinds.
                        return Hekili.DB.profile.displays.Primary.keybindings.font
                    end,
                    set = function( info, val )
                        -- Set all fonts in all displays.
                        for name, display in pairs( Hekili.DB.profile.displays ) do
                            display.captions.font = val
                            display.delays.font = val
                            display.keybindings.font = val
                            display.targets.font = val
                        end
                        Hekili:BuildUI()
                    end,
                },
        
                fontSize = {
                    type = "range",
                    name = "大小",
                    order = 960.2,
                    min = 8,
                    max = 64,
                    step = 1,
                    get = function( info )
                        -- Display the information from Primary, Keybinds.
                        return Hekili.DB.profile.displays.Primary.keybindings.fontSize
                    end,
                    set = function( info, val )
                        -- Set all fonts in all displays.
                        for name, display in pairs( Hekili.DB.profile.displays ) do
                            display.captions.fontSize = val
                            display.delays.fontSize = val
                            display.keybindings.fontSize = val
                            display.targets.fontSize = val
                        end
                        Hekili:BuildUI()
                    end,
                    width = 1.5,
                },
        
                fontStyle = {
                    type = "select",
                    name = "样式",
                    order = 960.3,
                    values = {
                        ["MONOCHROME"] = "单色",
                        ["MONOCHROME,OUTLINE"] = "单色, 轮廓",
                        ["MONOCHROME,THICKOUTLINE"] = "单色, 轮廓加粗",
                        ["NONE"] = "无",
                        ["OUTLINE"] = "轮廓",
                        ["THICKOUTLINE"] = "轮廓加粗"
                    },
                    get = function( info )
                        -- Display the information from Primary, Keybinds.
                        return Hekili.DB.profile.displays.Primary.keybindings.fontStyle
                    end,
                    set = function( info, val )
                        -- Set all fonts in all displays.
                        for name, display in pairs( Hekili.DB.profile.displays ) do
                            display.captions.fontStyle = val
                            display.delays.fontStyle = val
                            display.keybindings.fontStyle = val
                            display.targets.fontStyle = val
                        end
                        Hekili:BuildUI()
                    end,
                    width = 1.5,
                },

                color = {
                    type = "color",
                    name = "颜色",
                    order = 960.4,
                    get = function( info )
                        return unpack( Hekili.DB.profile.displays.Primary.keybindings.color )
                    end,
                    set = function( info, ... )
                        for name, display in pairs( Hekili.DB.profile.displays ) do
                            display.captions.color = { ... }
                            display.delays.color = { ... }
                            display.keybindings.color = { ... }
                            display.targets.color = { ... }
                        end
                        Hekili:BuildUI()
                    end,
                    width = 1.5
                },

                shareHeader = {
                    type = "header",
                    name = "分享",
                    order = 996,
                },

                shareBtn = {
                    type = "execute",
                    name = "分享样式",
                    desc = "你的显示样式可以通过这些导出字符串与其他插件用户共享.\n\n" ..
                        "你也可以在这里导入一个共享的导出字符串.",
                    func = function ()
                        ACD:SelectGroup( "Hekili", "displays", "shareDisplays" )
                    end,
                    order = 998,
                },

                shareDisplays = {
                    type = "group",
                    name = "|cFF1EFF00分享样式|r",
                    desc = "你的显示样式可以通过这些导出字符串与其他插件用户共享.\n\n" ..
                        "你也可以在这里导入一个共享的导出字符串.",
                    childGroups = "tab",
                    get = 'GetDisplayShareOption',
                    set = 'SetDisplayShareOption',
                    order = 999,
                    args = {
                        import = {
                            type = "group",
                            name = "导入",
                            order = 1,
                            args = {
                                stage0 = {
                                    type = "group",
                                    name = "",
                                    inline = true,
                                    order = 1,
                                    args = {
                                        guide = {
                                            type = "description",
                                            name = "选择已保存的样式或在提供的框中粘贴导入字符串.",
                                            order = 1,
                                            width = "full",
                                            fontSize = "medium",
                                        },

                                        separator = {
                                            type = "header",
                                            name = "导入字符串",
                                            order = 1.5,                                             
                                        },

                                        selectExisting = {
                                            type = "select",
                                            name = "选择一个已保存的样式",
                                            order = 2,
                                            width = "full",
                                            get = function()
                                                return "0000000000"
                                            end,
                                            set = function( info, val )
                                                local style = self.DB.global.styles[ val ]

                                                if style then shareDB.import = style.payload end
                                            end,
                                            values = function ()
                                                local db = self.DB.global.styles
                                                local values = {
                                                    ["0000000000"] = "选择保存的样式"
                                                }

                                                for k, v in pairs( db ) do
                                                    values[ k ] = k .. " (|cFF00FF00" .. v.date .. "|r)"
                                                end

                                                return values
                                            end,
                                        },

                                        importString = {
                                            type = "input",
                                            name = "导入字符串",
                                            get = function () return shareDB.import end,
                                            set = function( info, val )
                                                val = val:trim()
                                                shareDB.import = val
                                            end,
                                            order = 3,
                                            multiline = 5,
                                            width = "full",
                                        },

                                        btnSeparator = {
                                            type = "header",
                                            name = "导入",
                                            order = 4,
                                        },

                                        importBtn = {
                                            type = "execute",
                                            name = "导入样式",
                                            order = 5,
                                            func = function ()
                                                shareDB.imported, shareDB.error = self:DeserializeStyle( shareDB.import )

                                                if shareDB.error then
                                                    shareDB.import = "提供的导入字符串无法解压.\n" .. shareDB.error
                                                    shareDB.error = nil
                                                    shareDB.imported = {}
                                                else
                                                    shareDB.importStage = 1
                                                end
                                            end,
                                            disabled = function ()
                                                return shareDB.import == ""
                                            end,
                                        },
                                    },
                                    hidden = function () return shareDB.importStage ~= 0 end,
                                },

                                stage1 = {
                                    type = "group",
                                    inline = true,
                                    name = "",
                                    order = 1,
                                    args = {
                                        guide = {
                                            type = "description",
                                            name = function ()
                                                local creates, replaces = {}, {}

                                                for k, v in pairs( shareDB.imported ) do
                                                    if rawget( self.DB.profile.displays, k ) then
                                                        table.insert( replaces, k )
                                                    else
                                                        table.insert( creates, k )
                                                    end
                                                end

                                                local o = ""

                                                if #creates > 0 then
                                                    o = o .. "导入的样式将创建以下显示:  "
                                                    for i, display in orderedPairs( creates ) do
                                                        if i == 1 then o = o .. display
                                                        else o = o .. ", " .. display end
                                                    end
                                                    o = o .. ".\n"
                                                end

                                                if #replaces > 0 then
                                                    o = o .. "导入的样式将覆盖以下显示:  "
                                                    for i, display in orderedPairs( replaces ) do
                                                        if i == 1 then o = o .. display
                                                        else o = o .. ", " .. display end
                                                    end
                                                    o = o .. "."
                                                end

                                                return o
                                            end,
                                            order = 1,
                                            width = "full",
                                            fontSize = "medium",
                                        },

                                        separator = {
                                            type = "header",
                                            name = "申请变更",
                                            order = 2,
                                        },

                                        apply = {
                                            type = "execute",
                                            name = "申请变更",
                                            order = 3,
                                            confirm = true,
                                            func = function ()
                                                for k, v in pairs( shareDB.imported ) do
                                                    if type( v ) == "table" then self.DB.profile.displays[ k ] = v end
                                                end

                                                shareDB.import = ""
                                                shareDB.imported = {}
                                                shareDB.importStage = 2

                                                self:EmbedDisplayOptions()
                                                self:BuildUI()
                                            end,
                                        },

                                        reset = {
                                            type = "execute",
                                            name = "重置",
                                            order = 4,
                                            func = function ()
                                                shareDB.import = ""
                                                shareDB.imported = {}
                                                shareDB.importStage = 0
                                            end,
                                        },
                                    },
                                    hidden = function () return shareDB.importStage ~= 1 end,
                                },

                                stage2 = {
                                    type = "group",
                                    inline = true,
                                    name = "",
                                    order = 3,
                                    args = {
                                        note = {
                                            type = "description",
                                            name = "成功应用了导入的设置!\n\n如果需要单击重置重新开始.",
                                            order = 1,
                                            fontSize = "medium",
                                            width = "full",
                                        },

                                        reset = {
                                            type = "execute",
                                            name = "重置",
                                            order = 2,
                                            func = function ()
                                                shareDB.import = ""
                                                shareDB.imported = {}
                                                shareDB.importStage = 0
                                            end,
                                        }
                                    },
                                    hidden = function () return shareDB.importStage ~= 2 end,
                                }
                            },
                            plugins = {                                
                            }
                        },

                        export = {
                            type = "group",
                            name = "导出",
                            order = 2,
                            args = {
                                stage0 = {
                                    type = "group",
                                    name = "",
                                    inline = true,
                                    order = 1,
                                    args = {
                                        guide = {
                                            type = "description",
                                            name = "选择要导出的显示样式设置, 然后单击导出样式以生成导出字符串.",
                                            order = 1,
                                            fontSize = "medium",
                                            width = "full",
                                        },

                                        displays = {
                                            type = "header",
                                            name = "显示",
                                            order = 2,
                                        },

                                        exportHeader = {
                                            type = "header",
                                            name = "导出",
                                            order = 1000,
                                        },

                                        exportBtn = {
                                            type = "execute",
                                            name = "导出样式",
                                            order = 1001,
                                            func = function ()
                                                local disps = {}
                                                for key, share in pairs( shareDB.displays ) do
                                                    if share then table.insert( disps, key ) end
                                                end

                                                shareDB.export = self:SerializeStyle( unpack( disps ) )
                                                shareDB.exportStage = 1
                                            end,
                                            disabled = function ()
                                                local hasDisplay = false

                                                for key, value in pairs( shareDB.displays ) do
                                                    if value then hasDisplay = true; break end
                                                end

                                                return not hasDisplay
                                            end,
                                        },                                        
                                    },
                                    plugins = {
                                        displays = {}
                                    },
                                    hidden = function ()
                                        local plugins = self.Options.args.displays.args.shareDisplays.args.export.args.stage0.plugins.displays
                                        wipe( plugins )

                                        local i = 1
                                        for dispName, display in pairs( self.DB.profile.displays ) do
                                            local pos = 20 + ( display.builtIn and display.order or i )
                                            plugins[ dispName ] = {
                                                type = "toggle",
                                                name = function ()
                                                    if display.builtIn then return "|cFF00B4FF" .. dispName .. "|r" end
                                                    return dispName
                                                end,
                                                order = pos,
                                                width = "full"
                                            }
                                            i = i + 1
                                        end

                                        return shareDB.exportStage ~= 0 
                                    end,
                                },

                                stage1 = {
                                    type = "group",
                                    name = "",
                                    inline = true,
                                    order = 1,
                                    args = {
                                        exportString = {
                                            type = "input",
                                            name = "样式字符串",
                                            order = 1,
                                            multiline = 8,
                                            get = function () return shareDB.export end,
                                            set = function () end,
                                            width = "full",
                                            hidden = function () return shareDB.export == "" end,
                                        },

                                        instructions = {
                                            type = "description",
                                            name = "你可以复制上面的字符串来分享选择的显示风格设置, " ..
                                                "或者使用下面的选项来存储这些设置(待日后检索).",
                                            order = 2,
                                            width = "full",
                                            fontSize = "medium"
                                        },

                                        store = {
                                            type = "group",
                                            inline = true,
                                            name = "",
                                            order = 3,
                                            hidden = function () return shareDB.export == "" end,
                                            args = {
                                                separator = {
                                                    type = "header",
                                                    name = "保存样式",
                                                    order = 1,
                                                },

                                                exportName = {
                                                    type = "input",
                                                    name = "样式名称",
                                                    get = function () return shareDB.styleName end,
                                                    set = function( info, val )
                                                        val = val:trim()
                                                        shareDB.styleName = val
                                                    end,
                                                    order = 2,
                                                    width = "double",                                            
                                                },

                                                storeStyle = {
                                                    type = "execute",
                                                    name = "存储导出字符串",
                                                    desc = "通过存储导出字符串可以保存这些显示设置, 如果对设置进行更改可以在以后检索这些设置.\n\n" ..
                                                        "存储的样式可以从任何一个角色中检索, 即使使用不同的配置文件也可以检索到存储的样式.",
                                                    order = 3,
                                                    confirm = function ()
                                                        if shareDB.styleName and self.DB.global.styles[ shareDB.styleName ] ~= nil then
                                                            return "已经有一种样式名字是 '" .. shareDB.styleName .. "' -- 覆盖他?"
                                                        end
                                                        return false
                                                    end,
                                                    func = function ()
                                                        local db = self.DB.global.styles
                                                        db[ shareDB.styleName ] = {
                                                            date = tonumber( date("%Y%m%d.%H%M%S") ),
                                                            payload = shareDB.export,
                                                        }
                                                        shareDB.styleName = ""
                                                    end,
                                                    disabled = function ()
                                                        return shareDB.export == "" or shareDB.styleName == ""
                                                    end,
                                                }                
                                            }
                                        },


                                        restart = {
                                            type = "execute",
                                            name = "Restart",
                                            order = 4,
                                            func = function ()
                                                shareDB.styleName = ""
                                                shareDB.export = ""
                                                wipe( shareDB.displays )
                                                shareDB.exportStage = 0
                                            end,
                                        }
                                    },
                                    hidden = function () return shareDB.exportStage ~= 1 end
                                }
                            },
                            plugins = {
                                displays = {}
                            },
                        }
                    }
                },
            },
            plugins = {},
        }

        wipe( section.plugins )

        local i = 1

        for name, data in pairs( self.DB.profile.displays ) do
            local pos = data.builtIn and data.order or i
            section.plugins[ name ] = newDisplayOption( db, name, data, pos )
            if not data.builtIn then i = i + 1 end
        end

        db.args.displays = section

    end
end


ns.ClassSettings = function ()

    local option = {
        type = 'group',
        name = "职业/专精",
        order = 20,
        args = {},
        childGroups = "select",
        hidden = function()
            return #class.toggles == 0 and #class.settings == 0
        end
    }

    option.args.toggles = {
        type = 'group',
        name = '切换',
        order = 10,
        inline = true,
        args = {
        },
        hidden = function()
            return #class.toggles == 0
        end
    }

    for i = 1, #class.toggles do
        option.args.toggles.args[ 'Bind: ' .. class.toggles[i].name ] = {
            type = 'keybinding',
            name = class.toggles[i].option,
            desc = class.toggles[i].oDesc,
            order = ( i - 1 ) * 2
        }
        option.args.toggles.args[ 'State: ' .. class.toggles[i].name ] = {
            type = 'toggle',
            name = class.toggles[i].option,
            desc = class.toggles[i].oDesc,
            width = 'double',
            order = 1 + ( i - 1 ) * 2
        }
    end

    option.args.settings = {
        type = 'group',
        name = '设置',
        order = 20,
        inline = true,
        args = {},
        hidden = function()
            return #class.settings == 0
        end
    }

    for i, setting in ipairs(class.settings) do
        option.args.settings.args[ setting.name ] = setting.option
        option.args.settings.args[ setting.name ].order = i
    end

    return option

end


local abilityToggles = {}

ns.AbilitySettings = function ()

    local option = {
        type = 'group',
        name = "技能和物品",
        order = 65,
        childGroups = 'select',
        args = {
            heading = {
                type = 'description',
                name = "这些设置允许对技能进行小的改动从而影响到插件的建议. " ..
                    "仔细阅读鼠标提示因为某些选项如果被误用可能会导致奇怪或不理想的行为.\n",
                order = 1,
                width = "full",
            }
        }
    }

    local abilities = {} 
    for k, v in pairs( class.abilities ) do
        if not v.unlisted and v.name and not abilities[ v.name ] and ( v.id > 0 or v.id < -99 ) then
            abilities[ v.name ] = v.key
        end
    end

    for k, v in pairs( abilities ) do
        local ability = class.abilities[ k ]

        local abOption = {
            type = 'group',
            name = ability.name or k or v,
            order = 2,
            -- childGroups = "inline",
            args = {
                exclude = {
                    type = 'toggle',
                    name = function () return '禁用 ' .. ( ability.item and ability.link or k ) end,
                    desc = function () return "如果勾选, 这个技能将|cFFFF0000永远|r不会被插件推荐. " ..
                        "这可能会对某些职业或专精造成问题, 如果其他技能需要你使用" .. ( ability.item and ability.link or k ) .. "." end,
                    width = 'full',
                    order = 1
                },
                toggle = {
                    type = 'select',
                    name = '需要主动切换',
                    desc = "指定要在插件操作列表中使用的此操作所需的切换. " ..
                        "当切换到关闭时技能会被视为不可用, 插件会假装它们处于冷却状态(除非另有规定).",
                    width = 'full',
                    order = 2,
                    values = function ()
                        wipe( abilityToggles )

                        abilityToggles[ 'none' ] = 'None'
                        abilityToggles[ 'default' ] = 'Default' .. ( ability.toggle and ( ' |cFFFFD100(' .. ability.toggle .. ')|r' ) or ' |cFFFFD100(none)|r' )
                        abilityToggles[ 'cooldowns' ] = 'Cooldowns'
                        abilityToggles[ 'defensives' ] = 'Defensives'
                        abilityToggles[ 'interrupts' ] = 'Interrupts'
                        abilityToggles[ 'potions' ] = 'Potions'

                        return abilityToggles
                    end,
                },
                clash = {
                    type = 'range',
                    name = '冲突值',
                    desc = "如果将其设置为零以上, 则该插件将假装" .. k .. "冷却时间比实际时间要早得多.  " ..
                        "当某技能具有很高的优先级并且希望插件将其考虑得比实际就绪时早一些时这可能会有所帮助.",
                    width = "full",
                    min = -1.5,
                    max = 1.5,
                    step = 0.05,
                    order = 3
                },

                spacer01 = {
                    type = "description",
                    name = " ",
                    width = "full",
                    order = 19,
                    hidden = function() return ability.item == nil end,
                },

                itemHeader = {
                    type = "description",
                    name = "|cFFFFD100可用物品|r",
                    order = 20,
                    fontSize = "medium",
                    width = "full",
                    hidden = function() return ability.item == nil end,
                },

                itemDescription = {
                    type = "description",
                    name = function () return "此技能需要装备" .. ( ability.link or ability.name ) .. ". 可以通过操作列表中的|cFF00CCFF[使用物品]|r推荐该物品. " ..
                        "如果不希望插件通过|cff00ccff[使用物品]|r推荐此技能则可以在此处禁用它. " ..
                        "还可为要使用的物品指定最小或最大目标数.\n" end,
                    order = 21,
                    width = "full",
                    hidden = function() return ability.item == nil end,
                },

                spacer02 = {
                    type = "description",
                    name = " ",
                    width = "full",
                    order = 49
                },
            }
        }

        if ability and ability.item then
            if class.itemSettings[ ability.item ] then
                for setting, config in pairs( class.itemSettings[ ability.item ].options ) do
                    abOption.args[ setting ] = config
                end
            end
        end

        abOption.hidden = function( info )
            -- Hijack this function to build toggle list for action list entries.

            abOption.args.listHeader = abOption.args.listHeader or {
                type = "description",
                name = "|cFFFFD100操作列表|r",
                order = 50,
                fontSize = "medium",
                width = "full",
            }
            abOption.args.listHeader.hidden = true

            abOption.args.listDescription = abOption.args.listDescription or {
                type = "description",
                name = "该技能在下面的操作列表中列出. 如果需要可以在此处禁用任何条目.",
                order = 51,
                width = "full",
            }
            abOption.args.listDescription.hidden = true

            for key, opt in pairs( abOption.args ) do
                if key:match( "^(%d+):(%d+)" ) then
                    opt.hidden = true
                end
            end

            local entries = 51

            for i, list in ipairs( Hekili.DB.profile.actionLists ) do
                if list.Name ~= "Usable Items" then
                    for a, action in ipairs( list.Actions ) do
                        if action.Ability == v then
                            entries = entries + 1

                            local toggle = option.args[ v ].args[ i .. ':' .. a ] or {}

                            toggle.type = "toggle"
                            toggle.name = "Disable " .. ( ability.item and ability.link or k ) .. " (#|cFFFFD100" .. a .. "|r) in |cFFFFD100" .. ( list.Name or "Unnamed List" ) .. "|r"
                            toggle.desc = "This ability is used in entry #" .. a .. " of the |cFFFFD100" .. list.Name .. "|r action list."
                            toggle.order = entries
                            toggle.width = "full"
                            toggle.hidden = false

                            abOption.args[ i .. ':' .. a ] = toggle
                        end
                    end
                end
            end

            if entries > 51 then
                abOption.args.listHeader.hidden = false
                abOption.args.listDescription.hidden = false
            end

            return false
        end

        option.args[ v ] = abOption
    end

    return option

end


ns.TrinketSettings = function ()

    local option = {
        type = 'group',
        name = "饰品/装备",
        order = 22,
        args = {
            heading = {
                type = 'description',
                name = "这些设置适用于通过操作列表中的[使用物品]操作使用的饰品/装备.  不必 " ..
                    "手动编辑操作列表, 可以启用/禁用特定的饰品或者 " ..
                    "在允许使用饰品之前要求敌人的最小或最大数量.\n\n" ..
                    "|cFFFFD100如果操作列表中具有特定条件的特定饰品的特定条目则可能要在此处禁 " ..
                    "用饰品.|r",
                order = 1,
                width = "full",
            }
        },
        childGroups = 'select'
    }

    local trinkets = Hekili.DB.profile.trinkets

    for i, setting in pairs( class.itemSettings ) do
        option.args[ setting.key ] = {
            type = "group",
            name = setting.name,
            order = 10 + i,
            -- inline = true,
            args = setting.options
        }

        option.args[ setting.key ].hidden = function( info )

            -- Hide toggles in case they're outdated.
            for k, v in pairs( setting.options ) do
                if k:match( "^(%d+):(%d+)$") then
                    v.hidden = true
                end
            end

            for i, list in ipairs( Hekili.DB.profile.actionLists ) do
                local entries = 100

                if list.Name ~= 'Usable Items' then
                    for a, action in ipairs( list.Actions ) do
                        if action.Ability == setting.key then
                            entries = entries + 1
                            local toggle = option.args[ setting.key ].args[ i .. ':' .. a ] or {}

                            local name = type( setting.name ) == 'function' and setting.name() or setting.name 

                            toggle.type = "toggle"
                            toggle.name = "禁用 " .. name .. " 在|cFFFFD100" .. ( list.Name or "(没有列表名称)" ) .. " (#" .. a .. ")|r"
                            toggle.desc = "此技能用于输入 #" .. a .. " 的|cFFFFD100" .. list.Name .. "|r操作列表.\n\n" ..
                                "这通常意味着使用此物品有特定于职业或专精的条件. " ..
                                "如果不希望通过此操作列表推荐此物品请选中此框."
                            toggle.order = entries
                            toggle.width = "full"
                            toggle.hidden = false

                            option.args[ setting.key ].args[ i .. ':' .. a ] = toggle
                        end
                    end
                end
            end

            return false
        end

        trinkets[ setting.key ] = trinkets[ setting.key ] or {
            disabled = false,
            minimum = 1,
            maximum = 0
        }

    end

    return option

end


do
    local impControl = {
        name = "",
        source = UnitName( "player" ) .. " @ " .. GetRealmName(),
        apl = "在这里粘贴SimulationCraft优先级列表或配置文件.",

        lists = {},        
        warnings = ""
    }

    Hekili.ImporterData = impControl


    local function AddWarning( s )
        if impControl.warnings then
            impControl.warnings = impControl.warnings .. s .. "\n"
            return
        end

        impControl.warnings = s .. "\n"
    end


    function Hekili:GetImporterOption( info )
        return impControl[ info[ #info ] ]
    end


    function Hekili:SetImporterOption( info, value )
        if type( value ) == 'string' then value = value:trim() end
        impControl[ info[ #info ] ] = value
        impControl.warnings = nil
    end


    function Hekili:ImportSimcAPL( name, source, apl, pack )

        name = name or impControl.name
        source = source or impControl.source
        apl = apl or impControl.apl

        impControl.warnings = ""

        local lists = {
            precombat = "",
            default = "",
        }

        local count = 0

        -- Rename the default action list to 'default'
        apl = "\n" .. apl
        apl = apl:gsub( "actions(%+?)=", "actions.default%1=" )

        local comment

        for line in apl:gmatch( "\n([^\n^$]*)") do
            local newComment = line:match( "^# (.+)" )
            if newComment then comment = newComment end

            local list, action = line:match( "^actions%.(%S-)%+?=/?([^\n^$]*)" )

            if list and action then
                lists[ list ] = lists[ list ] or ""

                --[[ if action:sub( 1, 6 ) == "potion" then
                    local potion = action:match( ",name=(.-),") or action:match( ",name=(.-)$" ) or class.potion or ""
                    action = action:gsub( potion, "\"" .. potion .. "\"" )
                end ]]

                if action:sub( 1, 16 ) == "call_action_list" or action:sub( 1, 15 ) == "run_action_list" then
                    local name = action:match( ",name=(.-)," ) or action:match( ",name=(.-)$" )
                    if name then action:gsub( ",name=" .. name, ",name=\"" .. name .. "\"" ) end
                end

                if comment then
                    action = action .. ',description=' .. comment:gsub( ",", ";" )
                    comment = nil
                end

                lists[ list ] = lists[ list ] .. "actions+=/" .. action .. "\n"
            end
        end

        local count = 0
        local output = {}

        for name, list in pairs( lists ) do
            local import, warnings = self:ParseActionList( list )

            if warnings then
                AddWarning( "警告: 导入'" .. name .. "'需要进行一些自动更改." )

                for i, warning in ipairs( warnings ) do
                    AddWarning( warning )
                end

                AddWarning( "" )
            end

            if import then
                output[ name ] = import

                for i, entry in ipairs( import ) do
                    entry.enabled = not ( entry.action == 'heroism' or entry.action == 'bloodlust' )
                end

                count = count + 1
            end
        end

        local use_items_found = false

        for _, list in pairs( output ) do
            for i, entry in ipairs( list ) do
                if entry.action == "use_items" then use_items_found = true end
            end
        end

        if not use_items_found then
            AddWarning( "在这个导入中没有找到'use_items'动作." )
        end

        if not output.default then output.default = {} end
        if not output.precombat then output.precombat = {} end  

        if count == 0 then
            AddWarning( "没有从此配置文件导入任何操作列表." )
        else
            AddWarning( "导入" .. count .. "操作列表." )
        end

        return output, impControl.warnings
    end
end


local optionBuffer = {}

local buffer = function( msg )
    optionBuffer[ #optionBuffer + 1 ] = msg
end

local getBuffer = function()
    local output = table.concat( optionBuffer )
    wipe( optionBuffer )
    return output
end

local getColoredName = function( tab )
    if not tab then return '(无)'
    elseif tab.Default then return '|cFF00C0FF' .. tab.Name .. '|r'
else return '|cFFFFC000' .. tab.Name .. '|r' end
end


local snapshots = {
    displays = {},
    snaps = {},
    empty = {},

    display = "none",
    snap = {},
}


local config = {
    qsDisplay = 99999,

    qsShowTypeGroup = false,
    qsDisplayType = 99999,
    qsTargetsAOE = 3,

    displays = {}, -- auto-populated and recycled.
    displayTypes = {
        [1] = "初级",
        [2] = "AOE",
        [3] = "自动",
        [99999] = " "
    },

    expanded = {
        cooldowns = true
    },
    adding = {},
}


function Hekili:NewGetOption( info )

    local depth = #info
    local option = depth and info[depth] or nil

    if not option then return end

    if config[ option ] then return config[ option ] end

    return
end


function Hekili:NewSetOption( info, value )

    local depth = #info
    local option = depth and info[depth] or nil

    if not option then return end

    local nValue = tonumber( value )
    local sValue = tostring( value )

    if option == 'qsShowTypeGroup' then config[option] = value
    else config[option] = nValue end

    return
end


local specs = {}
local activeSpec

local function GetCurrentSpec()
    activeSpec = activeSpec or GetSpecializationInfo( GetSpecialization() )
    return activeSpec
end

local function SetCurrentSpec( _, val )
    activeSpec = val
end

local function GetCurrentSpecList()
    return specs
end


do
    local packs = {}

    local specNameByID = {}
    local specIDByName = {}

    local ACD = LibStub( "AceConfigDialog-3.0" )

    local shareDB = {
        actionPack = "",
        packName = "",
        export = "",

        import = "",
        imported = {},
        importStage = 0
    }


    function Hekili:GetPackShareOption( info )
        local n = #info
        local option = info[ n ]

        return shareDB[ option ]
    end


    function Hekili:SetPackShareOption( info, val, v2, v3, v4 )
        local n = #info
        local option = info[ n ]

        if type(val) == 'string' then val = val:trim() end

        shareDB[ option ] = val

        if option == "actionPack" and rawget( self.DB.profile.packs, shareDB.actionPack ) then
            shareDB.export = self:SerializeActionPack( shareDB.actionPack )
        else
            shareDB.export = ""
        end
    end


    function Hekili:SetSpecOption( info, val )
        local n = #info
        local spec, option = info[1], info[n]

        spec = specIDByName[ spec ]
        if not spec then return end

        if type( val ) == 'string' then val = val:trim() end

        self.DB.profile.specs[ spec ] = self.DB.profile.specs[ spec ] or {}
        self.DB.profile.specs[ spec ][ option ] = val

        if option == "package" then self:UpdateUseItems(); self:ForceUpdate( "SPEC_PACKAGE_CHANGED" )
        elseif option == "potion" and state.spec[ info[1] ] then class.potion = val
        elseif option == "enabled" then ns.StartConfiguration() end

        Hekili:UpdateDamageDetectionForCLEU()
    end


    function Hekili:GetSpecOption( info )
        local n = #info
        local spec, option = info[1], info[n]

        spec = specIDByName[ spec ]
        if not spec then return end

        self.DB.profile.specs[ spec ] = self.DB.profile.specs[ spec ] or {}

        if option == "potion" then
            local p = self.DB.profile.specs[ spec ].potion

            if not class.potionList[ p ] then
                return class.potions[ p ] and class.potions[ p ].key or p
            end
        end 

        return self.DB.profile.specs[ spec ][ option ]
    end


    function Hekili:SetSpecPref( info, val )
    end

    function Hekili:GetSpecPref( info )
    end


    function Hekili:SetAbilityOption( info, val )
        local n = #info
        local ability, option = info[2], info[n]

        local spec = GetCurrentSpec()

        self.DB.profile.specs[ spec ].abilities[ ability ][ option ] = val
        if option == "toggle" then Hekili:EmbedAbilityOption( nil, ability ) end
    end

    function Hekili:GetAbilityOption( info )
        local n = #info
        local ability, option = info[2], info[n]

        local spec = GetCurrentSpec()

        return self.DB.profile.specs[ spec ].abilities[ ability ][ option ]
    end


    function Hekili:SetItemOption( info, val )
        local n = #info
        local item, option = info[2], info[n]

        local spec = GetCurrentSpec()

        self.DB.profile.specs[ spec ].items[ item ][ option ] = val
        if option == "toggle" then Hekili:EmbedItemOption( nil, item ) end
    end

    function Hekili:GetItemOption( info )
        local n = #info
        local item, option = info[2], info[n]

        local spec = GetCurrentSpec()

        return self.DB.profile.specs[ spec ].items[ item ][ option ]
    end


    function Hekili:EmbedAbilityOption( db, key )
        db = db or self.Options
        if not db or not key then return end

        local ability = class.abilities[ key ]
        if not ability then return end

        local toggles = {}

        local k = class.abilityList[ ability.key ]
        local v = ability.key

        if not k or not v then return end

        local useName = class.abilityList[ v ] and class.abilityList[v]:match("|t (.+)$") or ability.name

        if not useName then
            Hekili:Error( "No name available for %s (id:%d) in EmbedAbilityOption.", ability.key or "no_id", ability.id or 0 )
            useName = ability.key or ability.id or "???"
        end

        local option = db.args.abilities.plugins.actions[ v ] or {}

        option.type = "group"
        option.name = function () return ( state:IsDisabled( v, true ) and "|cFFFF0000" or "" ) .. useName .. "|r" end
        option.order = 1
        option.set = "SetAbilityOption"
        option.get = "GetAbilityOption"
        option.args = {
            disabled = {
                type = "toggle",
                name = function () return "禁用 " .. ( ability.item and ability.link or k ) end,
                desc = function () return "如果勾选, 此技能|cffff0000永远|r不会被插件推荐. " ..
                    "这可能会给某些专精带来问题, 如果其他技能需要使用 " .. ( ability.item and ability.link or k ) .. "." end,
                width = 1.5,
                order = 1,
            },

            boss = {
                type = "toggle",
                name = "仅限BOSS战",
                desc = "如果勾选, 插件将不推荐" .. k .. "除非BOSS战. 如果不勾选, " .. k .. "在任何类型的战斗中都可以被推荐.",
                width = 1.5,
                order = 1.1,
            },                    

            keybind = {
                type = "input",
                name = "重写按键绑定文本",
                desc = "如果指定了该选项, 则在推荐此技能时插件将显示此文本来代替自动检测到的绑定文本.  " ..
                    "如果插件错误地检测到按键绑定这将很有帮助.",
                validate = function( info, val )
                    val = val:trim()
                    if val:len() > 6 then return "按键绑定的长度不得超过6个字符." end
                    return true
                end,
                width = 1.5,
                order = 2,
            },

            toggle = {
                type = "select",
                name = "需要切换",
                desc = "指定要在插件操作列表中使用的此操作所需的切换. " ..
                    "当关闭时技能被视为不可用, 并且插件将假装处于冷却状态(除非另有说明).",
                width = 1.5,
                order = 3,
                values = function ()
                    table.wipe( toggles )

                    local t = class.abilities[ v ].toggle or "none"
                    if t == "essences" then t = "covenants" end

                    toggles.none = "None"
                    toggles.default = "Default |cffffd100(" .. t .. ")|r"
                    toggles.cooldowns = "Cooldowns"
                    toggles.essences = "Covenants"
                    toggles.defensives = "Defensives"
                    toggles.interrupts = "Interrupts"
                    toggles.potions = "Potions"
                    toggles.custom1 = "Custom 1"
                    toggles.custom2 = "Custom 2"

                    return toggles
                end,
            },

            targetMin = {
                type = "range",
                name = "最低目标",
                desc = "如果设置为零以上, 则插件将仅允许" .. k .. "被推荐, 如果至少有这么多检测到的敌人. 还必须满足所有其他操作列表条件.\n设置为零以忽略.",
                width = 1.5,
                min = 0,
                max = 15,
                step = 1,
                order = 3.1,
            },

            targetMax = {
                type = "range",
                name = "最高目标",
                desc = "如果设置为零以上, 则插件将仅允许" .. k .. "被推荐, 如果检测到这么多敌人(或更少). 还必须满足所有其他操作列表条件.\n设置为零以忽略.",
                width = 1.5,
                min = 0,
                max = 15,
                step = 1,
                order = 3.2,
            },

            clash = {
                type = "range",
                name = "冲突",
                desc = "如果将其设置为零以上, 则该插件将假装" .. k .. "冷却时间比实际时间要早得多.  " ..
                    "当某技能具有很高的优先级并且希望插件将其考虑得比实际就绪时早一些时这可能会有所帮助.",
                width = 3,
                min = -1.5,
                max = 1.5,
                step = 0.05,
                order = 4,
            },
        }

        db.args.abilities.plugins.actions[ v ] = option
    end

    function Hekili:EmbedAbilityOptions( db )
        db = db or self.Options
        if not db then return end

        local abilities = {}
        local toggles = {}

        for k, v in pairs( class.abilityList ) do
            local a = class.abilities[ k ]
            if a and ( a.id > 0 or a.id < -100 ) and a.id ~= 61304 and not a.item then
                abilities[ v ] = k
            end
        end

        for k, v in orderedPairs( abilities ) do
            local ability = class.abilities[ v ]
            local useName = class.abilityList[ v ] and class.abilityList[v]:match("|t (.+)$") or ability.name

            if not useName then
                Hekili:Error( "No name available for %s (id:%d) in EmbedAbilityOptions.", ability.key or "no_id", ability.id or 0 )
                useName = ability.key or ability.id or "???"
            end

            local option = {
                type = "group",
                name = function () return ( state:IsDisabled( v, true ) and "|cFFFF0000" or "" ) .. useName .. "|r" end,
                order = 1,
                set = "SetAbilityOption",
                get = "GetAbilityOption",
                args = {
                    disabled = {
                        type = "toggle",
                        name = function () return "禁用 " .. ( ability.item and ability.link or k ) end,
                        desc = function () return "如果勾选, 此技能|cffff0000永远|r不会被插件推荐. " ..
                            "这可能会给某些专精带来问题, 如果其他技能需要使用" .. ( ability.item and ability.link or k ) .. "." end,
                        width = 1.5,
                        order = 1,
                    },

                    boss = {
                        type = "toggle",
                        name = "仅限BOSS战",
                        desc = "如果勾选, 插件将不推荐" .. k .. "除非BOSS战. 如果不勾选, " .. k .. "在任何类型的战斗中都可以被推荐.",
                        width = 1.5,
                        order = 1.1,
                    },                    

                    keybind = {
                        type = "input",
                        name = "重写按键绑定文本",
                        desc = "如果指定了该选项, 则在推荐此技能时插件将显示此文本来代替自动检测到的绑定文本. " ..
                            "如果插件错误地检测到按键绑定这将很有帮助.",
                        validate = function( info, val )
                            val = val:trim()
                            if val:len() > 6 then return "按键绑定的长度不得超过6个字符." end
                            return true
                        end,
                        width = 1.5,
                        order = 2,
                    },

                    toggle = {
                        type = "select",
                        name = "需要切换",
                        desc = "指定要在插件操作列表中使用的此操作所需的切换. " ..
                            "当关闭时技能被视为不可用, 并且插件将假装处于冷却状态(除非另有说明).",
                        width = 1.5,
                        order = 3,
                        values = function ()
                            table.wipe( toggles )

                            local t = class.abilities[ v ].toggle or "none"
                            if t == "essences" then t = "covenants" end

                            toggles.none = "None"
                            toggles.default = "Default |cffffd100(" .. t .. ")|r"
                            toggles.cooldowns = "Cooldowns"
                            toggles.essences = "Covenants"
                            toggles.defensives = "Defensives"
                            toggles.interrupts = "Interrupts"
                            toggles.potions = "Potions"
                            toggles.custom1 = "Custom 1"
                            toggles.custom2 = "Custom 2"

                            return toggles
                        end,
                    },

                    targetMin = {
                        type = "range",
                        name = "最低目标",
                        desc = "如果设置为零以上, 则插件将仅允许" .. k .. "被推荐, 如果至少有这么多检测到的敌人. 还必须满足所有其他操作列表条件.\n设置为零以忽略.",
                        width = 1.5,
                        min = 0,
                        max = 15,
                        step = 1,
                        order = 3.1,
                    },

                    targetMax = {
                        type = "range",
                        name = "最高目标",
                        desc = "如果设置为零以上, 则插件将仅允许" .. k .. "被推荐, 如果检测到这么多敌人(或更少). 还必须满足所有其他操作列表条件.\n设置为零以忽略.",
                        width = 1.5,
                        min = 0,
                        max = 15,
                        step = 1,
                        order = 3.2,
                    },

                    clash = {
                        type = "range",
                        name = "冲突",
                        desc = "如果将其设置为零以上, 则该插件将假装" .. k .. "冷却时间比实际时间要早得多.  " ..
                            "当某技能具有很高的优先级并且希望插件将其考虑得比实际就绪时早一些时这可能会有所帮助.",
                        width = 3,
                        min = -1.5,
                        max = 1.5,
                        step = 0.05,
                        order = 4,
                    },
                }
            }

            db.args.abilities.plugins.actions[ v ] = option
        end
    end


    function Hekili:EmbedItemOption( db, item )
        db = db or self.Options
        if not db then return end

        local ability = class.abilities[ item ]
        local toggles = {}

        local k = class.itemList[ ability.item ] or ability.name
        local v = ability.itemKey or ability.key

        if not item or not ability.item or not k then
            Hekili:Error( "Unable to find %s / %s / %s in the itemlist.", item or "unknown", ability.item or "unknown", k or "unknown" )
            return
        end

        local option = db.args.items.plugins.equipment[ v ] or {}

        option.type = "group"
        option.name = function () return ( state:IsDisabled( v, true ) and "|cFFFF0000" or "" ) .. ability.name .. "|r" end
        option.order = 1
        option.set = "SetItemOption"
        option.get = "GetItemOption"
        option.args = {
            disabled = {
                type = "toggle",
                name = function () return "禁用 " .. ( ability.item and ability.link or k ) end,
                desc = function () return "如果勾选, 此技能|cffff0000永远|r不会被插件推荐. " ..
                    "这可能会给某些专精带来问题, 如果其他技能需要使用 " .. ( ability.item and ability.link or k ) .. "." end,
                width = 1.5,
                order = 1,
            },

            boss = {
                type = "toggle",
                name = "仅限BOSS战",
                desc = "如果勾选, 插件将不推荐" .. k .. "除非BOSS战. 如果不勾选, " .. k .. "在任何类型的战斗中都可以被推荐.",
                width = 1.5,
                order = 1.1,
            },

            keybind = {
                type = "input",
                name = "重写按键绑定文本",
                desc = "如果指定了该选项, 则在推荐此技能时插件将显示此文本来代替自动检测到的绑定文本.  " ..
                    "如果插件错误地检测到按键绑定这将很有帮助.",
                validate = function( info, val )
                    val = val:trim()
                    if val:len() > 6 then return "按键绑定的长度不得超过6个字符." end
                    return true
                end,
                width = 1.5,
                order = 2,
            },

            toggle = {
                type = "select",
                name = "需要切换",
                desc = "指定要在插件操作列表中使用的此操作所需的切换. " ..
                    "当关闭时技能被视为不可用, 并且插件将假装处于冷却状态(除非另有说明).",
                width = 1.5,
                order = 3,
                values = function ()
                    table.wipe( toggles )

                    toggles.none = "None"
                    toggles.default = "Default" .. ( class.abilities[ v ].toggle and ( " |cffffd100(" .. class.abilities[ v ].toggle .. ")|r" ) or " |cffffd100(none)|r" )
                    toggles.cooldowns = "Cooldowns"
                    toggles.essences = "Covenants"
                    toggles.defensives = "Defensives"
                    toggles.interrupts = "Interrupts"
                    toggles.potions = "Potions"
                    toggles.custom1 = "Custom 1"
                    toggles.custom2 = "Custom 2"

                    return toggles
                end,
            },

            --[[ clash = {
                type = "range",
                name = "Clash",
                desc = "If set above zero, the addon will pretend " .. k .. " has come off cooldown this much sooner than it actually has.  " ..
                    "This can be helpful when an ability is very high priority and you want the addon to prefer it over abilities that are available sooner.",
                width = "full",
                min = -1.5,
                max = 1.5,
                step = 0.05,
                order = 4,
            }, ]]

            targetMin = {
                type = "range",
                name = "最低目标",
                desc = "如果设置为零以上, 则插件将仅允许" .. k .. "被推荐, 如果至少有这么多检测到的敌人. 还必须满足所有其他操作列表条件.\n设置为零以忽略.",
                width = 1.5,
                min = 0,
                max = 15,
                step = 1,
                order = 5,
            },

            targetMax = {
                type = "range",
                name = "最高目标",
                desc = "如果设置为零以上, 则插件将仅允许" .. k .. "被推荐, 如果检测到这么多敌人(或更少). 还必须满足所有其他操作列表条件.\n设置为零以忽略.",
                width = 1.5,
                min = 0,
                max = 15,
                step = 1,
                order = 6,
            },
        }

        db.args.items.plugins.equipment[ v ] = option
    end


    function Hekili:EmbedItemOptions( db )
        db = db or self.Options
        if not db then return end

        local abilities = {}
        local toggles = {}

        for k, v in pairs( class.abilities ) do
            if v.item and not abilities[ v.itemKey or v.key ] then
                local name = class.itemList[ v.item ] or v.name
                if name then abilities[ name ] = v.itemKey or v.key end
            end
        end

        for k, v in orderedPairs( abilities ) do
            local ability = class.abilities[ v ]
            local option = {
                type = "group",
                name = function () return ( state:IsDisabled( v, true ) and "|cFFFF0000" or "" ) .. ability.name .. "|r" end,
                order = 1,
                set = "SetItemOption",
                get = "GetItemOption",
                args = {
                    disabled = {
                        type = "toggle",
                        name = function () return "禁用 " .. ( ability.item and ability.link or k ) end,
                        desc = function () return "如果勾选, 此技能|cffff0000永远|r不会被插件推荐. " ..
                            "这可能会给某些专精带来问题, 如果其他技能需要你使用" .. ( ability.item and ability.link or k ) .. "." end,
                        width = 1.5,
                        order = 1,
                    },

                    boss = {
                        type = "toggle",
                        name = "仅限BOSS战",
                        desc = "如果勾选, 插件将不推荐" .. k .. "除非BOSS战. 如果不勾选, " .. k .. "在任何类型的战斗中都可以被推荐.",
                        width = 1.5,
                        order = 1.1,
                    },

                    keybind = {
                        type = "input",
                        name = "重写按键绑定文本",
                        desc = "如果指定了该选项, 则在推荐此技能时插件将显示此文本来代替自动检测到的绑定文本. " ..
                            "如果插件错误地检测到按键绑定这将很有帮助.",
                        validate = function( info, val )
                            val = val:trim()
                            if val:len() > 6 then return "按键绑定的长度不得超过6个字符." end
                            return true
                        end,
                        width = 1.5,
                        order = 2,
                    },

                    toggle = {
                        type = "select",
                        name = "需要切换",
                        desc = "指定要在插件操作列表中使用的此操作所需的切换. " ..
                            "当关闭时技能被视为不可用, 并且插件将假装处于冷却状态(除非另有说明).",
                        width = 1.5,
                        order = 3,
                        values = function ()
                            table.wipe( toggles )

                            toggles.none = "None"
                            toggles.default = "Default" .. ( class.abilities[ v ].toggle and ( " |cffffd100(" .. class.abilities[ v ].toggle .. ")|r" ) or " |cffffd100(none)|r" )
                            toggles.cooldowns = "Cooldowns"
                            toggles.essences = "Covenants"
                            toggles.defensives = "Defensives"
                            toggles.interrupts = "Interrupts"
                            toggles.potions = "Potions"
                            toggles.custom1 = "Custom 1"
                            toggles.custom2 = "Custom 2"

                            return toggles
                        end,
                    },

                    --[[ clash = {
                        type = "range",
                        name = "Clash",
                        desc = "If set above zero, the addon will pretend " .. k .. " has come off cooldown this much sooner than it actually has.  " ..
                            "This can be helpful when an ability is very high priority and you want the addon to prefer it over abilities that are available sooner.",
                        width = "full",
                        min = -1.5,
                        max = 1.5,
                        step = 0.05,
                        order = 4,
                    }, ]]

                    targetMin = {
                        type = "range",
                        name = "最低目标",
                        desc = "如果设置为零以上, 则插件将仅允许" .. k .. "被推荐, 如果至少有这么多检测到的敌人. 还必须满足所有其他操作列表条件.\n设置为零以忽略.",
                        width = 1.5,
                        min = 0,
                        max = 15,
                        step = 1,
                        order = 5,
                    },

                    targetMax = {
                        type = "range",
                        name = "最高目标",
                        desc = "如果设置为零以上, 则插件将仅允许" .. k .. "被推荐, 如果检测到这么多敌人(或更少). 还必须满足所有其他操作列表条件.\n设置为零以忽略.",
                        width = 1.5,
                        min = 0,
                        max = 15,
                        step = 1,
                        order = 6,
                    },
                }
            }

            db.args.items.plugins.equipment[ v ] = option
        end

        self.NewItemInfo = false
    end


    local nToggles = 0
    local tAbilities = {}
    local tItems = {}


    local function BuildToggleList( options, specID, section, useName, description )
        local db = options.args.toggles.plugins[ section ]
        local e

        local function tlEntry( key )
            if db[ key ] then return db[ key ] end
            db[ key ] = {}
            return db[ key ]
        end

        if db then
            for k, v in pairs( db ) do
                v.hidden = true
            end
        else
            db = {}
        end

        nToggles = nToggles + 1

        local hider = function()
            return not config.expanded[ section ]
        end

        local settings = Hekili.DB.profile.specs[ specID ]

        wipe( tAbilities )
        for k, v in pairs( class.abilityList ) do
            local a = class.abilities[ k ]
            if a and ( a.id > 0 or a.id < -100 ) and a.id ~= 61304 and not a.item then
                if settings.abilities[ k ].toggle == section or a.toggle == section and settings.abilities[ k ].toggle == 'default' then
                    tAbilities[ k ] = v
                end
            end
        end

        e = tlEntry( section .. "Spacer" )
        e.type = "description"
        e.name = ""
        e.order = nToggles
        e.width = "full"

        e = tlEntry( section .. "Expander" )
        e.type = "execute"
        e.name = ""
        e.order = nToggles + 0.01
        e.width = 0.15
        e.image = function ()
            if not config.expanded[ section ] then return "Interface\\AddOns\\Hekili\\Textures\\WhiteRight" end
            return "Interface\\AddOns\\Hekili\\Textures\\WhiteDown"
        end
        e.imageWidth = 20
        e.imageHeight = 20
        e.func = function( info )
            config.expanded[ section ] = not config.expanded[ section ]
        end

        if type( useName ) == "function" then
            useName = useName()
        end
        
        e = tlEntry( section .. "Label" )
        e.type = "description"
        e.name = useName or section
        e.order = nToggles + 0.02
        e.width = 2.85
        e.fontSize = "large"

        if description then
            e = tlEntry( section .. "Description" )
            e.type = "description"
            e.name = description
            e.order = nToggles + 0.05
            e.width = "full"
            e.hidden = hider
        else
            if db[ section .. "Description" ] then db[ section .. "Description" ].hidden = true end
        end

        local settings = Hekili.DB.profile.specs[ specID ]
        local count, offset = 0, 0

        for ability, isMember in orderedPairs( tAbilities ) do
            if isMember then
                if count % 2 == 0 then
                    e = tlEntry( section .. "LB" .. count )
                    e.type = "description"
                    e.name = ""
                    e.order = nToggles + 0.1 + offset
                    e.width = "full"
                    e.hidden = hider
                  
                    offset = offset + 0.001
                end

                e = tlEntry( section .. "Remove" .. ability )
                e.type = "execute"
                e.name = ""
                e.desc = function ()
                    local a = class.abilities[ ability ]
                    local desc
                    if a then
                        if a.item then desc = a.link or a.name
                        else desc = a.name end
                    end
                    desc = desc or ability

                    return "移除" .. desc .. "从" .. ( useName or section ) .. "切换."
                end
                e.image = RedX
                e.imageHeight = 16
                e.imageWidth = 16
                e.order = nToggles + 0.1 + offset
                e.width = 0.15
                e.func = function ()
                    settings.abilities[ ability ].toggle = 'none'
                    -- e.hidden = true
                    Hekili:EmbedSpecOptions()
                end
                e.hidden = hider

                offset = offset + 0.001


                e = tlEntry( section .. ability .. "Name" )
                e.type = "description"
                e.name = function ()
                    local a = class.abilities[ ability ]
                    if a then
                        if a.item then return a.link or a.name end
                        return a.name
                    end
                    return ability
                end
                e.order = nToggles + 0.1 + offset
                e.fontSize = "medium"
                e.width = 1.35
                e.hidden = hider

                offset = offset + 0.001

                --[[ e = tlEntry( section .. "Toggle" .. ability )
                e.type = "toggle"
                e.icon = RedX
                e.name = function ()
                    local a = class.abilities[ ability ]
                    if a then
                        if a.item then return a.link or a.name end
                        return a.name
                    end
                    return ability
                end
                e.desc = "Remove this from " .. ( useName or section ) .. "?"
                e.order = nToggles + 0.1 + offset
                e.width = 1.5
                e.hidden = hider
                e.get = function() return true end
                e.set = function()
                    settings.abilities[ ability ].toggle = 'none'
                    Hekili:EmbedSpecOptions()
                end

                offset = offset + 0.001 ]]

                count = count + 1
            end
        end


        e = tlEntry( section .. "FinalLB" )
        e.type = "description"
        e.name = ""
        e.order = nToggles + 0.993
        e.width = "full"
        e.hidden = hider
        
        e = tlEntry( section .. "AddBtn" )
        e.type = "execute"
        e.name = ""
        e.image = "Interface\\AddOns\\Hekili\\Textures\\GreenPlus"
        e.imageHeight = 16
        e.imageWidth = 16
        e.order = nToggles + 0.995
        e.width = 0.15
        e.func = function ()
            config.adding[ section ]  = true
        end
        e.hidden = hider
        

        e = tlEntry( section .. "AddText" )
        e.type = "description"
        e.name = "添加技能"
        e.fontSize = "medium"
        e.width = 1.35
        e.order = nToggles + 0.996
        e.hidden = function ()
            return hider() or config.adding[ section ]
        end

        
        e = tlEntry( section .. "Add" )
        e.type = "select"
        e.name = ""
        e.values = class.abilityList
        e.order = nToggles + 0.997
        e.width = 1.35
        e.get = function () end
        e.set = function ( info, val )
            local a = class.abilities[ val ]
            if a then
                settings[ a.item and "items" or "abilities" ][ val ].toggle = section
                config.adding[ section ] = false
                Hekili:EmbedSpecOptions()
            end
        end
        e.hidden = function ()
            return hider() or not config.adding[ section ]
        end


        e = tlEntry( section .. "Reload" )
        e.type = "execute"
        e.name = ""
        e.order = nToggles + 0.998
        e.width = 0.15
        e.image = GetAtlasFile( "transmog-icon-revert" )
        e.imageCoords = GetAtlasCoords( "transmog-icon-revert" )
        e.imageWidth = 16
        e.imageHeight = 16
        e.func = function ()
            for k, v in pairs( settings.abilities ) do
                local a = class.abilities[ k ]
                if a and not a.item and v.toggle == section or ( class.abilities[ k ].toggle == section ) then v.toggle = 'default' end
            end
            for k, v in pairs( settings.items ) do
                local a = class.abilities[ k ]
                if a and a.item and v.toggle == section or ( class.abilities[ k ].toggle == section ) then v.toggle = 'default' end
            end
            Hekili:EmbedSpecOptions()
        end
        e.hidden = hider
        

        e = tlEntry( section .. "ReloadText" )
        e.type = "description"
        e.name = "重新加载默认值"
        e.fontSize = "medium"
        e.order = nToggles + 0.999
        e.width = 1.35
        e.hidden = hider
        

        options.args.toggles.plugins[ section ] = db
    end


    -- Options table constructors.
    function Hekili:EmbedSpecOptions( db )
        db = db or self.Options
        if not db then return end

        local i = 1

        while( true ) do
            local id, name, description, texture, role = GetSpecializationInfo( i )

            if not id then break end

            local spec = class.specs[ id ]

            if spec then
                local sName = lower( name )
                specNameByID[ id ] = sName
                specIDByName[ sName ] = id

                specs[ id ] = '|T' .. texture .. ':0|t ' .. name

                local options = {
                    type = "group",
                    -- name = specs[ id ],
                    name = name,
                    icon = texture,
                    -- iconCoords = { 0.1, 0.9, 0.1, 0.9 },
                    desc = description,
                    order = 50 + i,
                    childGroups = "tab",
                    get = "GetSpecOption",
                    set = "SetSpecOption",

                    args = {
                        core = {
                            type = "group",
                            name = "核心",
                            desc = "核心功能和专精选择" .. specs[ id ] .. ".",
                            order = 1,
                            args = {
                                enabled = {
                                    type = "toggle",
                                    name = "启用",
                                    desc = "如果勾选, 该插件将根据所选的优先级列表为" .. name .. "提供优先级建议.",
                                    order = 0,
                                    width = "full",
                                },
        
        
                                --[[ packInfo = {
                                    type = 'group',
                                    name = "",
                                    inline = true,
                                    order = 1,
                                    args = {
                                        
                                    }
                                }, ]]

                                package = {
                                    type = "select",
                                    name = "优先级",
                                    desc = "该插件在进行优先级推荐时将使用所选的包.",
                                    order = 1,
                                    width = 2.85,
                                    values = function( info, val )
                                        wipe( packs )

                                        for key, pkg in pairs( self.DB.profile.packs ) do
                                            local pname = pkg.builtIn and "|cFF00B4FF" .. key .. "|r" or key
                                            if pkg.spec == id then
                                                packs[ key ] = '|T' .. texture .. ':0|t ' .. pname
                                            end
                                        end

                                        packs[ '(none)' ] = '(none)'

                                        return packs
                                    end,
                                },

                                openPackage = {
                                    type = 'execute',
                                    name = "",
                                    desc = "打开并查看此优先级包及其操作列表.",
                                    order = 1.1,
                                    width = 0.15,
                                    image = GetAtlasFile( "shop-games-magnifyingglass" ),
                                    imageCoords = GetAtlasCoords( "shop-games-magnifyingglass" ),
                                    imageHeight = 24,
                                    imageWidth = 24,
                                    disabled = function( info, val )
                                        local pack = self.DB.profile.specs[ id ].package
                                        return rawget( self.DB.profile.packs, pack ) == nil
                                    end,
                                    func = function ()
                                        ACD:SelectGroup( "Hekili", "packs", self.DB.profile.specs[ id ].package )
                                    end,
                                },

                                blankLine1 = {
                                    type = 'description',
                                    name = '',
                                    order = 1.2,
                                    width = 'full'                                            
                                },

                                potion = {
                                    type = "select",
                                    name = "默认药水",
                                    desc = "当推荐一个药水时, 除非操作列表中另有规定则插件会建议使用这个药水.",
                                    order = 2,
                                    width = 3,
                                    values = function ()
                                        local v = {}
        
                                        for k, p in pairs( class.potionList ) do
                                            if k ~= "default" then v[ k ] = p end
                                        end
        
                                        return v
                                    end,
                                },

                                blankLine2 = {
                                    type = 'description',
                                    name = '',
                                    order = 2.1, 
                                    width = 'full'
                                }

                            },
                            plugins = {
                                settings = {}
                            },
                        },

                        targets = {
                            type = "group",
                            name = "目标",
                            desc = "有关如何识别和计算敌人的设置.",
                            order = 3,
                            args = {
                                -- Nameplate Quasi-Group
                                nameplates = {
                                    type = "toggle",
                                    name = "使用姓名版检测",
                                    desc = "如果勾选, 该插件将计算在你的角色周围小范围内任何有可见姓名版的敌人. " ..
                                        "这是典型的|cFFFF0000近战|r专精的理想选择.",
                                    width = "full",
                                    order = 1,
                                },

                                nameplateRange = {
                                    type = "range",
                                    name = "姓名版检测范围",
                                    desc = "当勾选了|cFFFFD100使用姓名版检测|r时, 插件将计算在你的角色的这个半径范围内有可见姓名版的敌人.",
                                    width = "full",
                                    hidden = function()
                                        return self.DB.profile.specs[ id ].nameplates == false
                                    end,
                                    min = 5,
                                    max = 100,
                                    step = 1,
                                    order = 2,
                                },

                                nameplateSpace = {
                                    type = "description",
                                    name = " ",
                                    width = "full",
                                    hidden = function()
                                        return self.DB.profile.specs[ id ].nameplates == false
                                    end,
                                    order = 3,
                                },


                                -- Pet-Based Cluster Detection
                                petbased = {
                                    type = "toggle",
                                    name = "使用基于宠物的检测",
                                    desc = function ()
                                        local msg = "如果勾选并正确配置, 当你的目标也在你的宠物范围内时, 插件将把你的宠物附近的目标算作有效目标."

                                        if Hekili:HasPetBasedTargetSpell() then
                                            local spell = Hekili:GetPetBasedTargetSpell()
                                            local name, _, tex = GetSpellInfo( spell )
                                            
                                            msg = msg .. "\n\n|T" .. tex .. ":0|t |cFFFFD100" .. name .. "|r 在你的动作栏上, 并将用于你所有的 " .. UnitClass("player") .. " 宠物."
                                        end

                                        return msg
                                    end,
                                    width = "full",
                                    hidden = function ()
                                        return Hekili:GetPetBasedTargetSpells() == nil
                                    end,
                                    order = 3.1
                                },

                                addPetAbility = {
                                    type = "description",
                                    name = function ()
                                        local out = "要想进行宠物侦测, 你必须从|cFF00FF00宠物的技能书|r中获取一个技能，并将其放在|cFF00FF00你的|r动作栏上.\n\n"
                                        local spells = Hekili:GetPetBasedTargetSpells()

                                        if not spells then return " " end

                                        out = out .. "对于%s, |T%d:0|t |cFFFFD100%s|r 由于其范围, 建议使用.  它将适用于所有的宠物."

                                        if spells.count > 1 then
                                            out = out .. "\n替代方案: "
                                        end

                                        local n = 0

                                        for spell in pairs( spells ) do                                            
                                            if type( spell ) == "number" then
                                                n = n + 1

                                                local name, _, tex = GetSpellInfo( spell )

                                                if n == 1 then
                                                    out = string.format( out, UnitClass( "player" ), tex, name )
                                                elseif n == 2 and spells.count == 2 then
                                                    out = out .. "|T" .. tex .. ":0|t |cFFFFD100" .. name .. "|r."
                                                elseif n ~= spells.count then
                                                    out = out .. "|T" .. tex .. ":0|t |cFFFFD100" .. name .. "|r, "
                                                else
                                                    out = out .. "and |T" .. tex .. ":0|t |cFFFFD100" .. name .. "|r."
                                                end
                                            end
                                        end
                                        
                                        return out
                                    end,
                                    fontSize = "medium",
                                    width = "full",
                                    hidden = function ( info, val )
                                        if Hekili:GetPetBasedTargetSpells() == nil then return true end
                                        if self.DB.profile.specs[ id ].petbased == false then return true end
                                        if self:HasPetBasedTargetSpell() then return true end

                                        return false
                                    end,
                                    order = 3.11,
                                },


                                -- Damage Detection Quasi-Group
                                damage = {
                                    type = "toggle",
                                    name = "检测伤害敌人",
                                    desc = "如果勾选, 该插件将把过去几秒内你打到的敌人(或打到你的敌人)算作主动的敌人. " ..
                                        "这对于|cFFFF0000远程|r专精来说是典型的理想选择.",
                                    width = "full",
                                    order = 4,                                    
                                },

                                damageDots = {
                                    type = "toggle",
                                    name = "检测Dot敌人",
                                    desc = "勾选该选项后, 插件将继续计算随着时间的流逝而受到伤害的敌人的数量(出血等), 即使他们不在附近或受到了其他伤害.\n\n" ..
                                        "这对于近战专业来说可能并不理想, 因为敌人可能会在你施放dot/流血之后就会游走. 如果与|cFFFFD100使用姓名版检测|r一起使用, 将过滤已不在近战范围内的dot敌人.\n\n" ..
                                        "对于具有随时间推移的伤害效果的远程专精应该启用这个功能.",
                                    width = 1.49,
                                    hidden = function () return self.DB.profile.specs[ id ].damage == false end,
                                    order = 5,
                                },

                                damagePets = {
                                    type = "toggle",
                                    name = "检测被宠物伤害的敌人",
                                    desc = "如果勾选, 该插件将计算你的宠物或仆从在过去几秒内击中(或击中你)的敌人.  " ..
                                        "如果你的宠物/仆从分布在战场上, 这可能会使目标数量产生误导.",
                                    width = 1.49,
                                    hidden = function () return self.DB.profile.specs[ id ].damage == false end,
                                    order = 5.1
                                },

                                damageRange = {
                                    type = "range",
                                    name = "按范围过滤伤害敌人",
                                    desc = "如果设置为0以上, 该插件将试图避免计算最后一次看到时已经超出范围的目标. 这是基于缓存数据可能不准确.",
                                    width = "full",
                                    hidden = function () return self.DB.profile.specs[ id ].damage == false end,
                                    min = 0,
                                    max = 100,
                                    step = 1,
                                    order = 5.2,
                                },

                                damageExpiration = {
                                    type = "range",
                                    name = "伤害监测超时",
                                    desc = "当|cFFFFD100检测伤害敌人|r被选中时, 加载项将记住敌人, 直到他们在这段时间内被忽略/未伤害为止. " ..
                                        "如果敌人死亡或被消灭也会被遗忘. 当敌人散开或移动出范围时这很有帮助.",
                                    width = "full",
                                    softMin = 3,
                                    min = 1,
                                    max = 10,
                                    step = 0.1,
                                    hidden = function() return self.DB.profile.specs[ id ].damage == false end,
                                    order = 5.3,
                                },

                                damageSpace = {
                                    type = "description",
                                    name = " ",
                                    width = "full",
                                    hidden = function() return self.DB.profile.specs[ id ].damage == false end,
                                    order = 7,
                                },

                                cycle = {
                                    type = "toggle",
                                    name = "推荐目标互换",
                                    desc = "启用目标互换时, 当你应该在不同的目标上使用某项技能时插件可能会显示一个图标(|TInterface\\Addons\\Hekili\\Textures\\Cycle:0|t). " ..
                                        "对于某些只想对另一个目标(例如踏风)施加debuf效果的专精来说这种方法效果很好, 但是对于专注于根据持续时间来维持dot/debuff的专精(例如痛苦)可能效果不佳. " ..
                                        "该功能将在未来的更新中进行改进.",
                                    width = "full",
                                    order = 8
                                },

                                cycle_min = {
                                    type = "range",
                                    name = "最小目标死亡时间",
                                    desc = "当选中|cffffd100推荐目标互换时|r, 该值决定了哪些目标会被计入目标互换. 如果设置为5, 那么插件将不建议切换到小于5秒内死亡的目标上. " ..
                                            "这样做有利于避免对会死得太快的目标施加伤害超时效果.\n\n" ..
                                            "设置为0计数所有检测到的目标.",
                                    width = "full",
                                    min = 0,
                                    max = 15,
                                    step = 1,
                                    hidden = function() return not self.DB.profile.specs[ id ].cycle end,
                                    order = 9
                                },

                                aoe = {
                                    type = "range",
                                    name = "AOE显示: 最低目标",
                                    desc = "当显示AOE时, 如果有这么多的目标可用则会提出建议.",
                                    width = "full",
                                    min = 2,
                                    max = 10,
                                    step = 1,
                                    order = 10,
                                },
                            }
                        },

                        toggles = {
                            type = "group",
                            name = "切换",
                            desc = "指定此专精的每个切换按键绑定控制哪些技能.",
                            order = 2,
                            args = {
                                toggleDesc = {
                                    type = "description",
                                    name = "本节显示了当你在该职业中切换每个专精时哪些技能被启用/禁用.  装备和饰品可以通过各自的部分进行调整 (左).\n\n" ..
                                        "移除一个技能的切换无论切换是否处于激活状态, 它都会保持|cFF00FF00启用|r的状态.",
                                    fontSize = "medium",
                                    order = 1,
                                    width = 3,
                                }
                            },
                            plugins = {
                                cooldowns = {},
                                essences = {},
                                defensives = {},
                                utility = {},
                                custom1 = {},
                                custom2 = {},
                            }
                        },

                        performance = {
                            type = "group",
                            name = "性能",
                            order = 10,
                            args = {
                                throttleRefresh = {
                                    type = "toggle",
                                    name = "限制更新",
                                    desc = "默认情况下, 插件将在任何相关的战斗事件发生后更新其建议. " ..
                                        "但是有些战斗事件会连续快速发生导致CPU占用率较高游戏性能下降.\n\n" ..
                                        "如果选择了|cffffd100限制更新|r, 可以指定该专精的|cffffd100最大更新频率|r.",
                                    order = 1,
                                    width = 1
                                },

                                maxRefresh = {
                                    type = "range",
                                    name = "最大更新频率",
                                    desc = "指定插件每秒更新建议的最大次数.\n\n" ..
                                        "如果设置为|cffffd1004|r, 则插件更新建议的频率不会超过每|cffffd1000.25|r秒更新一次.\n\n" ..
                                        "如果设置为|cffffd10020|r, 则插件更新建议的频率不会超过每|cffffd1000.05|r秒更新一次.\n\n" ..
                                        "一般情况下在战斗中每秒会更新5-7次.",
                                    order = 1.1,
                                    width = 2,
                                    min = 4,
                                    max = 20,
                                    step = 1,
                                    hidden = function () return self.DB.profile.specs[ id ].throttleRefresh == false end,
                                },

                                perfSpace = {
                                    type = "description",
                                    name = " ",
                                    order = 1.9,
                                    width = "full"
                                },

                                throttleTime = {
                                    type = "toggle",
                                    name = "限制时间",
                                    desc = "默认情况下, 插件将花费所需的时间来生成显示请求的建议数量. " ..
                                        "然而复杂的战斗场景或优先级列表有时会耗费过多的时间影响你的FPS的使用.\n\n" ..
                                        "如果选择|cffffd100限制时间|r, 则可以指定加载项在生成辅助建议时将使用的|cffffd100最大更新时间|r.",
                                    order = 2,
                                    width = 1,
                                },

                                maxTime = {
                                    type = "range",
                                    name = "最大更新时间(ms)",
                                    desc = "指定插件更新建议时可以使用的最大时间(以毫秒为单位).\n\n" ..
                                        "如果设置为|cffffd10010|r，那么建议应该不会影响到100FPS系统.\n(1 秒 / 100 帧 = 10ms)\n\n" ..
                                        "如果设置为|cffffd10016|r, 那么建议应该不会影响到60FPS系统.\n(1 秒 / 60 帧 = 16.7ms)\n\n" ..
                                        "不论此设置如何该插件都会始终生成其第一条建议.",
                                    order = 2.1,
                                    min = 5,
                                    max = 1000,
                                    width = 2,
                                    hidden = function () return self.DB.profile.specs[ id ].throttleTime == false end,
                                },
                                
                                throttleSpace = {
                                    type = "description",
                                    name = " ",
                                    order = 3,
                                    width = "full",
                                    hidden = function () return self.DB.profile.specs[ id ].throttleRefresh == false end,
                                },

                                gcdSync = {
                                    type = "toggle",
                                    name = "全局CD后开始",
                                    desc = "如果勾选, 该插件的第一个建议将被延迟到你的初级和AOE中的GCD开始时显示. 如果在全局CD过程中出现饰品或无GCD技能, 这可以减少闪烁. " ..
                                        "但会导致在GCD激活时使用技能(如鲁莽)在队列中向后放.",
                                    width = "full",
                                    order = 4,
                                },

                                enhancedRecheck = {
                                    type = "toggle",
                                    name = "强化复查",
                                    desc = "当插件无法在当前推荐某个技能时, 它会在未来的几个时间点重新检查行动的条件.  如果勾选, 该功能将使插件能够对使用 '变量' 功能的条目进行额外检查.  " ..
                                        "这可能会使用更多的CPU, 但可以减少插件无法进行推荐的可能性.",
                                    width = "full",
                                    order = 5,
                                }

                            }
                        }
                    },
                }
                
                local specCfg = class.specs[ id ] and class.specs[ id ].settings
                local specProf = self.DB.profile.specs[ id ]

                if #specCfg > 0 then
                    options.args.core.plugins.settings.prefSpacer = {
                        type = "description",
                        name = " ",
                        order = 100,
                        width = "full"
                    }

                    options.args.core.plugins.settings.prefHeader = {
                        type = "header",
                        name = "性能",
                        order = 100.1,
                    }

                    for i, option in ipairs( specCfg ) do
                        if i > 1 and i % 2 == 1 then
                            -- Insert line break.
                            options.args.core.plugins.settings[ sName .. "LB" .. i ] = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = option.info.order - 0.01
                            }
                        end

                        options.args.core.plugins.settings[ option.name ] = option.info
                        if self.DB.profile.specs[ id ].settings[ option.name ] == nil then
                            self.DB.profile.specs[ id ].settings[ option.name ] = option.default
                        end
                    end
                end

                -- Toggles
                BuildToggleList( options, id, "cooldowns", "CD" )
                BuildToggleList( options, id, "essences", "艾泽里特精华" )
                BuildToggleList( options, id, "interrupts", "实用 / 打断" )
                BuildToggleList( options, id, "defensives", "防御",   "防御的切换一般是针对坦克专业的, " ..
                                                                            "因为在战斗中你可能会因为各种原因想要开启/关闭推荐的伤害减免能力, " ..
                                                                            "所以防御性的切换一般是针对坦克专业的. " ..
                                                                            "DPS玩家可能会想添加自己的减伤技能, " ..
                                                                            "但也需要将能力添加到自己的自定义优先级包中." )
                BuildToggleList( options, id, "custom1", function ()
                    return specProf.custom1Name or "自定义1"
                end )
                BuildToggleList( options, id, "custom2", function ()
                    return specProf.custom2Name or "自定义2"
                end )

                db.plugins.specializations[ sName ] = options
            end

            i = i + 1
        end

    end


    local packControl = {
        listName = "default",
        actionID = "0001",

        makingNew = false,
        newListName = nil,

        showModifiers = false,

        newPackName = "",
        newPackSpec = "",
    }


    local nameMap = {
        call_action_list = "list_name",
        run_action_list = "list_name",
        potion = "potion",
        variable = "var_name",
        op = "op"
    }


    local defaultNames = {
        list_name = "default",
        potion = "prolonged_power",
        var_name = "unnamed_var",
    }


    local toggleToNumber = {
        cycle_targets = true,
        for_next = true,
        max_energy = true,
        strict = true,
        use_off_gcd = true,
        use_while_casting = true,
    }


    local function GetListEntry( pack )
        local entry = rawget( Hekili.DB.profile.packs, pack )

        if rawget( entry.lists, packControl.listName ) == nil then
            packControl.listName = "default"
        end

        if entry then entry = entry.lists[ packControl.listName ] else return end

        if rawget( entry, tonumber( packControl.actionID ) ) == nil then
            packControl.actionID = "0001"
        end

        local listPos = tonumber( packControl.actionID )
        if entry and listPos > 0 then entry = entry[ listPos ] else return end

        return entry
    end


    function Hekili:GetActionOption( info )
        local n = #info
        local pack, option = info[ 2 ], info[ n ]

        if rawget( self.DB.profile.packs[ pack ].lists, packControl.listName ) == nil then
            packControl.listName = "default"
        end

        local actionID = tonumber( packControl.actionID )
        local data = self.DB.profile.packs[ pack ].lists[ packControl.listName ]

        if option == 'position' then return actionID
        elseif option == 'newListName' then return packControl.newListName end

        if not data then return end
        data = data[ actionID ]

        if option == "inputName" or option == "selectName" then
            option = nameMap[ data.action ]
            if not data[ option ] then data[ option ] = defaultNames[ option ] end
        end

        if option == "op" and not data.op then return "set" end

        if option == "potion" then
            if not data.potion then return "default" end
            if not class.potionList[ data.potion ] then
                return class.potions[ data.potion ] and class.potions[ data.potion ].key or data.potion
            end
        end

        if toggleToNumber[ option ] then return data[ option ] == 1 end
        return data[ option ]
    end


    function Hekili:SetActionOption( info, val )
        local n = #info
        local pack, option = info[ 2 ], info[ n ]

        local actionID = tonumber( packControl.actionID )
        local data = self.DB.profile.packs[ pack ].lists[ packControl.listName ]

        if option == 'newListName' then
            packControl.newListName = val:trim()
            return
        end

        if not data then return end
        data = data[ actionID ]

        if option == "inputName" or option == "selectName" then option = nameMap[ data.action ] end

        if toggleToNumber[ option ] then val = val and 1 or 0 end
        if type( val ) == 'string' then val = val:trim() end

        data[ option ] = val

        if option == "enable_moving" and not val then
            data.moving = nil
        end

        if option == "line_cd" and not val then
            data.line_cd = nil
        end

        if option == "use_off_gcd" and not val then
            data.use_off_gcd = nil
        end

        if option == "strict" and not val then
            data.strict = nil
        end

        if option == "use_while_casting" and not val then
            data.use_while_casting = nil
        end

        if option == "action" then
            self:LoadScripts()
        else
            self:LoadScript( pack, packControl.listName, actionID )
        end

        if option == "enabled" then
            Hekili:UpdateDisplayVisibility()
        end
    end


    function Hekili:GetPackOption( info )
        local n = #info
        local category, subcat, option = info[ 2 ], info[ 3 ], info[ n ]

        if rawget( self.DB.profile.packs, category ) and rawget( self.DB.profile.packs[ category ].lists, packControl.listName ) == nil then
            packControl.listName = "default"
        end

        if option == "newPackSpec" and packControl[ option ] == "" then
            packControl[ option ] = GetCurrentSpec()
        end

        if packControl[ option ] ~= nil then return packControl[ option ] end        

        if subcat == 'lists' then return self:GetActionOption( info ) end

        local data = rawget( self.DB.profile.packs, category )
        if not data then return end

        if option == 'date' then return tostring( data.date ) end

        return data[ option ]
    end


    function Hekili:SetPackOption( info, val )
        local n = #info
        local category, subcat, option = info[ 2 ], info[ 3 ], info[ n ]

        if packControl[ option ] ~= nil then
            packControl[ option ] = val
            if option == "listName" then packControl.actionID = "0001" end
            return
        end

        if subcat == 'lists' then return self:SetActionOption( info, val ) end
        -- if subcat == 'newActionGroup' or ( subcat == 'actionGroup' and subtype == 'entry' ) then self:SetActionOption( info, val ); return end

        local data = rawget( self.DB.profile.packs, category )
        if not data then return end

        if type( val ) == 'string' then val = val:trim() end
        
        if option == "desc" then
            -- Auto-strip comments prefix
            val = val:gsub( "^#+ ", "" )
            val = val:gsub( "\n#+ ", "\n" )
        end

        data[ option ] = val
    end


    function Hekili:EmbedPackOptions( db )
        db = db or self.Options
        if not db then return end

        local packs = db.args.packs or {
            type = "group",
            name = "优先级",
            desc = "优先级(或行动包)是捆绑于操作列表, 用于为每个专精提出建议.",
            get = 'GetPackOption',
            set = 'SetPackOption',
            order = 65,
            childGroups = 'tree',
            args = {
                packDesc = {
                    type = "description",
                    name = "优先级(或行动包)是捆绑于操作列表, 用于为每个专精提出建议. " ..
                        "它们可以定制和共享.",
                    order = 1,
                    fontSize = "medium",
                },

                newPackHeader = {
                    type = "header",
                    name = "创建一个新的优先级",
                    order = 200
                },

                newPackName = {
                    type = "input",
                    name = "优先级名称",
                    desc = "为此包输入新的唯一名称. 仅允许使用字母数字字符, 空格, 下划线和撇号.",
                    order = 201,
                    width = "full",
                    validate = function( info, val )
                        val = val:trim()
                        if rawget( Hekili.DB.profile.packs, val ) then return "请指定一个专精包名称."
                        elseif val == "UseItems" then return "UseItems是一个保留名称."
                        elseif val == "(none)" then return "别自作聪明了, 小姐."
                        elseif val:find( "[^a-zA-Z0-9 _']" ) then return "在包名中只允许使用字母数字字符, 空格, 下划线和省略号." end
                        return true
                    end,
                },

                newPackSpec = {
                    type = "select",
                    name = "专精",
                    order = 202,
                    width = "full",
                    values = specs,
                },

                createNewPack = {
                    type = "execute",
                    name = "创建新包",
                    order = 203,
                    disabled = function()
                        return packControl.newPackName == "" or packControl.newPackSpec == ""
                    end,
                    func = function ()
                        Hekili.DB.profile.packs[ packControl.newPackName ].spec = packControl.newPackSpec
                        Hekili:EmbedPackOptions()
                        ACD:SelectGroup( "Hekili", "packs", packControl.newPackName )
                        packControl.newPackName = ""
                        packControl.newPackSpec = ""
                    end,
                },

                shareHeader = {
                    type = "header",
                    name = "分享",
                    order = 100,
                },

                shareBtn = {
                    type = "execute",
                    name = "分享优先级",
                    desc = "每个优先级可以通过这些导出字符串与其他插件用户共享.\n\n" ..
                        "你也可以在这里导入一个共享的导出字符串.",
                    func = function ()
                        ACD:SelectGroup( "Hekili", "packs", "sharePacks" )
                    end,
                    order = 101,
                },

                sharePacks = {
                    type = "group",
                    name = "|cFF1EFF00分享优先级|r",
                    desc = "每个优先级可以通过这些导出字符串与其他插件用户共享.\n\n" ..
                        "你也可以在这里导入一个共享的导出字符串.",
                    childGroups = "tab",
                    get = 'GetPackShareOption',
                    set = 'SetPackShareOption',
                    order = 1001,
                    args = {
                        import = {
                            type = "group",
                            name = "导入",
                            order = 1,
                            args = {
                                stage0 = {
                                    type = "group",
                                    name = "",
                                    inline = true,
                                    order = 1,
                                    args = {
                                        guide = {
                                            type = "description",
                                            name = "在此处粘贴优先级导入字符串以开始.",
                                            order = 1,
                                            width = "full",
                                            fontSize = "medium",
                                        },

                                        separator = {
                                            type = "header",
                                            name = "导入字符串",
                                            order = 1.5,                                             
                                        },

                                        importString = {
                                            type = "input",
                                            name = "导入字符串",
                                            get = function () return shareDB.import end,
                                            set = function( info, val )
                                                val = val:trim()
                                                shareDB.import = val
                                            end,
                                            order = 3,
                                            multiline = 5,
                                            width = "full",
                                        },

                                        btnSeparator = {
                                            type = "header",
                                            name = "导入",
                                            order = 4,
                                        },

                                        importBtn = {
                                            type = "execute",
                                            name = "导入优先级",
                                            order = 5,
                                            func = function ()
                                                shareDB.imported, shareDB.error = self:DeserializeActionPack( shareDB.import )

                                                if shareDB.error then
                                                    shareDB.import = "提供的导入字符串无法解压.\n" .. shareDB.error
                                                    shareDB.error = nil
                                                    shareDB.imported = {}
                                                else
                                                    shareDB.importStage = 1
                                                end
                                            end,
                                            disabled = function ()
                                                return shareDB.import == ""
                                            end,
                                        },
                                    },
                                    hidden = function () return shareDB.importStage ~= 0 end,
                                },

                                stage1 = {
                                    type = "group",
                                    inline = true,
                                    name = "",
                                    order = 1,
                                    args = {
                                        packName = {
                                            type = "input",
                                            order = 1,
                                            name = "包名称",
                                            get = function () return shareDB.imported.name end,
                                            set = function ( info, val ) shareDB.imported.name = val:trim() end,
                                            width = "full",
                                        },

                                        packDate = {
                                            type = "input",
                                            order = 2,
                                            name = "包日期",
                                            get = function () return tostring( shareDB.imported.date ) end,
                                            set = function () end,
                                            width = "full",
                                            disabled = true,
                                        },

                                        packSpec = {
                                            type = "input",
                                            order = 3,
                                            name = "包专精",
                                            get = function () return select( 2, GetSpecializationInfoByID( shareDB.imported.payload.spec or 0 ) ) or "无专精设置" end,
                                            set = function () end,
                                            width = "full",
                                            disabled = true,
                                        },

                                        guide = {
                                            type = "description",
                                            name = function ()
                                                local listNames = {}

                                                for k, v in pairs( shareDB.imported.payload.lists ) do
                                                    table.insert( listNames, k )
                                                end

                                                table.sort( listNames )

                                                local o

                                                if #listNames == 0 then
                                                    o = "导入的优先权没有包含列表."
                                                elseif #listNames == 1 then
                                                    o = "导入的优先级有一个操作列表:  " .. listNames[1] .. "."
                                                elseif #listNames == 2 then
                                                    o = "导入的优先级有两个操作列表:  " .. listNames[1] .. " 和 " .. listNames[2] .. "."
                                                else
                                                    o = "导入的优先级包括以下清单:  "
                                                    for i, name in ipairs( listNames ) do
                                                        if i == 1 then o = o .. name
                                                        elseif i == #listNames then o = o .. ", 和 " .. name .. "."
                                                        else o = o .. ", " .. name end
                                                    end
                                                end

                                                return o
                                            end,
                                            order = 4,
                                            width = "full",
                                            fontSize = "medium",
                                        },

                                        separator = {
                                            type = "header",
                                            name = "申请变更",
                                            order = 10,
                                        },

                                        apply = {
                                            type = "execute",
                                            name = "申请变更",
                                            order = 11,
                                            confirm = function ()
                                                if rawget( self.DB.profile.packs, shareDB.imported.name ) then
                                                    return "你已经有一个\"" .. shareDB.imported.name .. "\"优先级.\n覆盖他?"
                                                end
                                                return "从导入的数据创建一个名为\"" .. shareDB.imported.name .. "\"的新优先级?"
                                            end,
                                            func = function ()
                                                self.DB.profile.packs[ shareDB.imported.name ] = shareDB.imported.payload
                                                shareDB.imported.payload.date = shareDB.imported.date
                                                shareDB.imported.payload.version = shareDB.imported.date

                                                shareDB.import = ""
                                                shareDB.imported = {}
                                                shareDB.importStage = 2

                                                self:LoadScripts()
                                                self:EmbedPackOptions()
                                            end,
                                        },

                                        reset = {
                                            type = "execute",
                                            name = "重置",
                                            order = 12,
                                            func = function ()
                                                shareDB.import = ""
                                                shareDB.imported = {}
                                                shareDB.importStage = 0
                                            end,
                                        },
                                    },
                                    hidden = function () return shareDB.importStage ~= 1 end,
                                },

                                stage2 = {
                                    type = "group",
                                    inline = true,
                                    name = "",
                                    order = 3,
                                    args = {
                                        note = {
                                            type = "description",
                                            name = "成功应用了导入的设置!\n\n如果需要的话单击重置重新开始.",
                                            order = 1,
                                            fontSize = "medium",
                                            width = "full",
                                        },

                                        reset = {
                                            type = "execute",
                                            name = "重置",
                                            order = 2,
                                            func = function ()
                                                shareDB.import = ""
                                                shareDB.imported = {}
                                                shareDB.importStage = 0
                                            end,
                                        }
                                    },
                                    hidden = function () return shareDB.importStage ~= 2 end,
                                }
                            },
                            plugins = {                                
                            }
                        },

                        export = {
                            type = "group",
                            name = "导出",
                            order = 2,
                            args = {
                                guide = {
                                    type = "description",
                                    name = "选择要导出的优先级包.",
                                    order = 1,
                                    fontSize = "medium",
                                    width = "full",
                                },

                                actionPack = {
                                    type = "select",
                                    name = "优先级",
                                    order = 2,
                                    values = function ()
                                        local v = {}

                                        for k, pack in pairs( Hekili.DB.profile.packs ) do
                                            if pack.spec and class.specs[ pack.spec ] then
                                                v[ k ] = k
                                            end
                                        end

                                        return v
                                    end,
                                    width = "full"
                                },

                                exportString = {
                                    type = "input",
                                    name = "优先级导出字符串(CTRL+A选择，CTRL+C复制)",
                                    order = 3,
                                    get = function ()
                                        if rawget( Hekili.DB.profile.packs, shareDB.actionPack ) then
                                            shareDB.export = self:SerializeActionPack( shareDB.actionPack )
                                        else
                                            shareDB.export = ""
                                        end
                                        return shareDB.export 
                                    end,
                                    set = function () end,
                                    width = "full",
                                    hidden = function () return shareDB.export == "" end,
                                },
                            },
                        }
                    }
                },                
            },
            plugins = {
                packages = {},
                links = {},
            }
        }

        wipe( packs.plugins.packages )
        wipe( packs.plugins.links )

        local count = 0

        for pack, data in orderedPairs( self.DB.profile.packs ) do
            if data.spec and class.specs[ data.spec ] and not data.hidden then
                packs.plugins.links.packButtons = packs.plugins.links.packButtons or {
                    type = "header",
                    name = "已安装的包",
                    order = 10,
                }

                packs.plugins.links[ "btn" .. pack ] = {
                    type = "execute",
                    name = pack,
                    order = 11 + count,
                    func = function ()
                        ACD:SelectGroup( "Hekili", "packs", pack )
                    end,
                }

                local opts = packs.plugins.packages[ pack ] or {
                    type = "group",
                    name = function ()
                        local p = rawget( Hekili.DB.profile.packs, pack )
                        if p.builtIn then return '|cFF00B4FF' .. pack .. '|r' end
                        return pack
                    end,
                    childGroups = "tab",
                    order = 100 + count,
                    args = {
                        pack = {
                            type = "group",
                            name = data.builtIn and ( BlizzBlue .. "摘要|r" ) or "摘要",
                            order = 1,
                            args = {
                                isBuiltIn = {
                                    type = "description",
                                    name = function ()
                                        return BlizzBlue .. "这是一个默认的优先级包. 它将在插件更新时自动更新. " ..
                                            "如果您想自定义此优先级，请点击|TInterface\\Addons\\Hekili\\Textures\\WhiteCopy:0|t.|r复制一份"
                                    end,
                                    fontSize = "medium",
                                    width = 3,
                                    order = 0.1,
                                    hidden = not data.builtIn
                                },                                

                                lb01 = {
                                    type = "description",
                                    name = "",
                                    order = 0.11,
                                    hidden = not data.builtIn
                                },

                                toggleActive = {
                                    type = "toggle",
                                    name = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        if p and p.builtIn then return BlizzBlue .. "激活|r" end
                                        return "激活"
                                    end,
                                    desc = "如果勾选, 那插件对这个专精的推荐就是基于这个优先级包的推荐.",
                                    order = 0.2,
                                    width = 3,
                                    get = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        return Hekili.DB.profile.specs[ p.spec ].package == pack
                                    end,
                                    set = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        if Hekili.DB.profile.specs[ p.spec ].package == pack then
                                            if p.builtIn then
                                                Hekili.DB.profile.specs[ p.spec ].package = "(none)"
                                            else
                                                for def, data in pairs( Hekili.DB.profile.packs ) do
                                                    if data.spec == p.spec and data.builtIn then
                                                        Hekili.DB.profile.specs[ p.spec ].package = def
                                                        return
                                                    end
                                                end
                                            end
                                        else
                                            Hekili.DB.profile.specs[ p.spec ].package = pack
                                        end
                                    end,
                                },
                                
                                lb04 = {
                                    type = "description",
                                    name = "",
                                    order = 0.21,
                                    width = "full"
                                },

                                packName = {
                                    type = "input",
                                    name = "优先级名称",
                                    order = 0.25,
                                    width = 2.7,
                                    validate = function( info, val )
                                        val = val:trim()
                                        if rawget( Hekili.DB.profile.packs, val ) then return "请指定一个专精包名称."
                                        elseif val == "UseItems" then return "UseItems是一个保留名称."
                                        elseif val == "(none)" then return "别自作聪明了, 小姐."
                                        elseif val:find( "[^a-zA-Z0-9 _'()]" ) then return "在包名中只允许使用字母数字字符, 空格, 下划线和省略号." end
                                        return true
                                    end,
                                    get = function() return pack end,
                                    set = function( info, val )
                                        local profile = Hekili.DB.profile
                                        
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        Hekili.DB.profile.packs[ pack ] = nil
                                        
                                        val = val:trim()
                                        Hekili.DB.profile.packs[ val ] = p

                                        for _, spec in pairs( Hekili.DB.profile.specs ) do
                                            if spec.package == pack then spec.package = val end
                                        end
                                        
                                        Hekili:EmbedPackOptions()
                                        Hekili:LoadScripts()
                                        ACD:SelectGroup( "Hekili", "packs", val )
                                    end,                                    
                                    disabled = data.builtIn
                                },

                                copyPack = {
                                    type = "execute",
                                    name = "",
                                    desc = "复制优先级",
                                    order = 0.26, 
                                    width = 0.15,
                                    image = [[Interface\AddOns\Hekili\Textures\WhiteCopy]],
                                    imageHeight = 20,
                                    imageWidth = 20,
                                    confirm = function () return "创建此优先级包的副本?" end,
                                    func = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        
                                        local newPack = tableCopy( p )
                                        newPack.builtIn = false
                                        newPack.basedOn = pack

                                        local newPackName, num = pack:match("^(.+) %((%d+)%)$")

                                        if not num then
                                            newPackName = pack
                                            num = 1
                                        end

                                        num = num + 1
                                        while( rawget( Hekili.DB.profile.packs, newPackName .. " (" .. num .. ")" ) ) do
                                            num = num + 1
                                        end
                                        newPackName = newPackName .. " (" .. num ..")"

                                        Hekili.DB.profile.packs[ newPackName ] = newPack
                                        Hekili:EmbedPackOptions()
                                        Hekili:LoadScripts()
                                        ACD:SelectGroup( "Hekili", "packs", newPackName )
                                    end
                                },

                                reloadPack = {
                                    type = "execute",
                                    name = "",
                                    desc = "重载优先级",
                                    order = 0.27,
                                    width = 0.15,
                                    image = GetAtlasFile( "transmog-icon-revert" ),
                                    imageCoords = GetAtlasCoords( "transmog-icon-revert" ),
                                    imageWidth = 25,
                                    imageHeight = 24,
                                    confirm = function ()
                                        return "从默认值重新加载此优先级包?"
                                    end,
                                    hidden = not data.builtIn,
                                    func = function ()
                                        Hekili.DB.profile.packs[ pack ] = nil
                                        Hekili:RestoreDefault( pack )
                                        Hekili:EmbedPackOptions()
                                        Hekili:LoadScripts()
                                        ACD:SelectGroup( "Hekili", "packs", pack )
                                    end
                                },

                                deletePack = {
                                    type = "execute",
                                    name = "",
                                    desc = "删除优先级",
                                    order = 0.27,
                                    width = 0.15,
                                    image = GetAtlasFile( "communities-icon-redx" ),
                                    imageCoords = GetAtlasCoords( "communities-icon-redx" ),
                                    imageHeight = 24,
                                    imageWidth = 24,
                                    confirm = function () return "删除这套优先权?" end,
                                    func = function ()
                                        local defPack

                                        local specId = data.spec
                                        local spec = specId and Hekili.DB.profile.specs[ specId ]

                                        if specId then
                                            for pId, pData in pairs( Hekili.DB.profile.packs ) do
                                                if pData.builtIn and pData.spec == specId then
                                                    defPack = pId
                                                    if spec.package == pack then spec.package = pId; break end
                                                end
                                            end
                                        end

                                        Hekili.DB.profile.packs[ pack ] = nil
                                        Hekili.Options.args.packs.plugins.packages[ pack ] = nil

                                        -- Hekili:EmbedPackOptions()
                                        ACD:SelectGroup( "Hekili", "packs" )
                                    end,                                    
                                    hidden = data.builtIn
                                },

                                lb02 = {
                                    type = "description",
                                    name = "",
                                    order = 0.3,
                                    width = "full",
                                },

                                spec = {
                                    type = "select",
                                    name = "专精",
                                    order = 1,
                                    width = 3,
                                    values = specs,
                                    disabled = data.builtIn
                                },

                                lb03 = {
                                    type = "description",
                                    name = "",
                                    order = 1.01,
                                    width = "full",
                                    hidden = data.builtIn
                                },

                                --[[ applyPack = {
                                    type = "execute",
                                    name = "Use Priority",
                                    order = 1.5,
                                    width = 1,
                                    func = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        Hekili.DB.profile.specs[ p.spec ].package = pack
                                    end,
                                    hidden = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        return Hekili.DB.profile.specs[ p.spec ].package == pack
                                    end,
                                }, ]]

                                desc = {
                                    type = "input",
                                    name = "描述",
                                    multiline = 15,
                                    order = 2,
                                    width = "full",
                                },
                            }
                        },

                        profile = {
                            type = "group",
                            name = "配置",
                            desc = "如果这个优先级是用SimulationCraft配置文件生成的, 则可以在这里存储或检索配置文件. " ..
                                "该配置文件也可以被重新导入或用较新的配置文件覆盖.",
                            order = 2,
                            args = {
                                signature = {
                                    type = "group",
                                    inline = true,
                                    name = "",
                                    order = 3,
                                    args = {
                                        source = {
                                            type = "input",
                                            name = "来源",
                                            desc = "如果优先级基于SimulationCraft配置文件或热门指南, " ..
                                                "则最好提供源头的链接(尤其是在共享之前).",
                                            order = 1,
                                            width = 3,
                                        },

                                        break1 = {
                                            type = "description",
                                            name = "",
                                            width = "full",
                                            order = 1.1,
                                        },

                                        author = {
                                            type = "input",
                                            name = "作者",
                                            desc = "在创建新的优先权时作者会自动填写. " ..
                                                "你可以在这里更新.",
                                            order = 2,
                                            width = 2,
                                        },

                                        date = {
                                            type = "input",
                                            name = "最新更新",
                                            desc = "当对该优先事项的操作列表作出任何更改时该日期会自动更新.",
                                            width = 1,
                                            order = 3,
                                            set = function () end,
                                            get = function ()
                                                local d = data.date or 0

                                                if type(d) == "string" then return d end
                                                return format( "%.4f", d )
                                            end,
                                        },
                                    },
                                },

                                profile = {
                                    type = "input",
                                    name = "配置",
                                    desc = "如果此包的操作列表是从SimulationCraft的配置文件中导入的, 该配置文件包含在这里.",
                                    order = 4,
                                    multiline = 20,
                                    width = "full",
                                },

                                warnings = {
                                    type = "description",
                                    name = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        return "|cFFFFD100导入日志|r\n" .. ( p.warnings or "" ) .. "\n\n"
                                    end,
                                    order = 5,
                                    fontSize = "medium",
                                    width = "full",                                
                                    hidden = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        return not p.warnings or p.warnings == ""
                                    end,
                                },

                                reimport = {
                                    type = "execute",
                                    name = "导入",
                                    desc = "从上述配置中重建操作列表.",
                                    order = 5,
                                    func = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        local profile = p.profile:gsub( '"', '' )

                                        local result, warnings = Hekili:ImportSimcAPL( nil, nil, profile )

                                        wipe( p.lists )

                                        for k, v in pairs( result ) do
                                            p.lists[ k ] = v
                                        end

                                        p.warnings = warnings
                                        p.date = tonumber( date("%Y%m%d.%H%M%S") )

                                        if not p.lists[ packControl.listName ] then packControl.listName = "default" end

                                        local id = tonumber( packControl.actionID )
                                        if not p.lists[ packControl.listName ][ id ] then packControl.actionID = "zzzzzzzzzz" end

                                        self:LoadScripts()
                                    end,
                                },
                            }
                        },

                        lists = {
                            type = "group",
                            childGroups = "select",
                            name = "操作列表",
                            desc = "操作列表是用来决定在什么时间使用哪些技能的.",
                            order = 3,
                            args = {
                                listName = {
                                    type = "select",
                                    name = "操作列表",
                                    desc = "选择要查看或修改的操作列表.",
                                    order = 1,
                                    width = 2.7,
                                    values = function ()
                                        local v = {
                                            -- ["zzzzzzzzzz"] = "|cFF00FF00Add New Action List|r"
                                        }

                                        local p = rawget( Hekili.DB.profile.packs, pack )

                                        for k in pairs( p.lists ) do
                                            local err = false

                                            if Hekili.Scripts and Hekili.Scripts.DB then
                                                local scriptHead = "^" .. pack .. ":" .. k .. ":"
                                                for k, v in pairs( Hekili.Scripts.DB ) do                                                            
                                                    if k:match( scriptHead ) and v.Error then err = true; break end
                                                end
                                            end

                                            if err then
                                                v[ k ] = "|cFFFF0000" .. k .. "|r"                                                        
                                            elseif k == 'precombat' or k == 'default' then
                                                v[ k ] = "|cFF00B4FF" .. k .. "|r"
                                            else
                                                v[ k ] = k
                                            end
                                        end

                                        return v
                                    end,
                                },

                                newListBtn = {
                                    type = "execute",
                                    name = "",
                                    desc = "创建一个新的操作列表",
                                    order = 1.1,
                                    width = 0.15,
                                    image = "Interface\\AddOns\\Hekili\\Textures\\GreenPlus",
                                    -- image = GetAtlasFile( "communities-icon-addgroupplus" ),
                                    -- imageCoords = GetAtlasCoords( "communities-icon-addgroupplus" ),
                                    imageHeight = 20,
                                    imageWidth = 20,
                                    func = function ()
                                        packControl.makingNew = true
                                    end,
                                },

                                delListBtn = {
                                    type = "execute",
                                    name = "",
                                    desc = "删除此操作列表",
                                    order = 1.2,
                                    width = 0.15,
                                    image = RedX,
                                    -- image = GetAtlasFile( "communities-icon-redx" ),
                                    -- imageCoords = GetAtlasCoords( "communities-icon-redx" ),
                                    imageHeight = 20,
                                    imageWidth = 20,
                                    confirm = function() return "删除该操作列表?" end,
                                    disabled = function () return packControl.listName == "default" or packControl.listName == "precombat" end,
                                    func = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        p.lists[ packControl.listName ] = nil
                                        Hekili:LoadScripts()
                                        packControl.listName = "default"
                                    end,                                                
                                },

                                lineBreak = {
                                    type = "description",
                                    name = "",
                                    width = "full",
                                    order = 1.9
                                },

                                actionID = {
                                    type = "select",
                                    name = "条目",
                                    desc = "在此操作列表中选择要修改的条目.\n\n" ..
                                        "红色的条目为禁用, 未设置任何操作, 有条件错误或使用禁用/关闭的操作.",
                                    order = 2,
                                    width = 2.4,
                                    values = function ()
                                        local v = {}

                                        local data = rawget( Hekili.DB.profile.packs, pack )
                                        local list = rawget( data.lists, packControl.listName )

                                        if list then
                                            local last = 0

                                            for i, entry in ipairs( list ) do
                                                local key = format( "%04d", i )
                                                local action = entry.action
                                                local desc

                                                local warning, color = false

                                                if not action then
                                                    action = "Unassigned"
                                                    warning = true
                                                else
                                                    if not class.abilities[ action ] then warning = true
                                                    else
                                                        if state:IsDisabled( action, true ) then warning = true end
                                                        action = class.abilityList[ action ] and class.abilityList[ action ]:match( "|t (.+)$" ) or class.abilities[ action ] and class.abilities[ action ].name or action
                                                    end
                                                end

                                                local scriptID = pack .. ":" .. packControl.listName .. ":" .. i
                                                local script = Hekili.Scripts.DB[ scriptID ]

                                                if script and script.Error then warning = true end

                                                local cLen = entry.criteria and entry.criteria:len()

                                                if entry.caption and entry.caption:len() > 0 then
                                                    desc = entry.caption

                                                elseif entry.action == "variable" then
                                                    if entry.op == "reset" then
                                                        desc = format( "reset |cff00ccff%s|r", entry.var_name or "未分配" )
                                                    elseif entry.op == "default" then
                                                        desc = format( "|cff00ccff%s|r default = |cffffd100%s|r", entry.var_name or "未分配", entry.value or "0" )
                                                    elseif entry.op == "set" or entry.op == "setif" then
                                                        desc = format( "set |cff00ccff%s|r = |cffffd100%s|r", entry.var_name or "未分配", entry.value or "无" )
                                                    else
                                                        desc = format( "%s |cff00ccff%s|r (|cffffd100%s|r)", entry.op or "设置", entry.var_name or "未分配", entry.value or "无" )
                                                    end

                                                    if cLen and cLen > 0 then
                                                        desc = format( "%s, if |cffffd100%s|r", desc, entry.criteria )
                                                    end

                                                elseif entry.action == "call_action_list" or entry.action == "run_action_list" then
                                                    if not entry.list_name or not rawget( data.lists, entry.list_name ) then
                                                        desc = "|cff00ccff(未设置)|r"
                                                        warning = true
                                                    else
                                                        desc = "|cff00ccff" .. entry.list_name .. "|r"
                                                    end

                                                    if cLen and cLen > 0 then
                                                        desc = desc .. ", if |cffffd100" .. entry.criteria .. "|r"
                                                    end

                                                elseif cLen and cLen > 0 then
                                                    desc = "|cffffd100" .. entry.criteria .. "|r"

                                                end

                                                if not entry.enabled then
                                                    warning = true
                                                    color = "|cFF808080"
                                                end

                                                if desc then desc = desc:gsub( "[\r\n]", "" ) end

                                                if not color then
                                                    color = warning and "|cFFFF0000" or "|cFFFFD100"
                                                end

                                                if desc then
                                                    v[ key ] = color .. i .. ".|r " .. action .. " - " .. "|cFFFFD100" .. desc .. "|r"
                                                else
                                                    v[ key ] = color .. i .. ".|r " .. action
                                                end

                                                last = i + 1
                                            end
                                        end

                                        return v
                                    end,
                                    hidden = function ()
                                        return packControl.makingNew == true
                                    end,
                                },

                                moveUpBtn = {
                                    type = "execute",
                                    name = "",
                                    image = "Interface\\AddOns\\Hekili\\Textures\\WhiteUp",
                                    -- image = GetAtlasFile( "hud-MainMenuBar-arrowup-up" ),
                                    -- imageCoords = GetAtlasCoords( "hud-MainMenuBar-arrowup-up" ),
                                    imageHeight = 20,
                                    imageWidth = 20,
                                    width = 0.15,
                                    order = 2.1,
                                    func = function( info )
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        local data = p.lists[ packControl.listName ]
                                        local actionID = tonumber( packControl.actionID )

                                        local a = table.remove( data, actionID )
                                        table.insert( data, actionID - 1, a )
                                        packControl.actionID = format( "%04d", actionID - 1 )

                                        local listName = format( "%s:%s:", pack, packControl.listName )
                                        scripts:SwapScripts( listName .. actionID, listName .. ( actionID - 1 ) )
                                    end,
                                    disabled = function ()
                                        return tonumber( packControl.actionID ) == 1
                                    end,
                                    hidden = function () return packControl.makingNew end,
                                },
                                
                                moveDownBtn = {
                                    type = "execute",
                                    name = "",
                                    image = "Interface\\AddOns\\Hekili\\Textures\\WhiteDown",
                                    -- image = GetAtlasFile( "hud-MainMenuBar-arrowdown-up" ),
                                    -- imageCoords = GetAtlasCoords( "hud-MainMenuBar-arrowdown-up" ),
                                    imageHeight = 20,
                                    imageWidth = 20,
                                    width = 0.15,
                                    order = 2.2,
                                    func = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        local data = p.lists[ packControl.listName ]
                                        local actionID = tonumber( packControl.actionID )

                                        local a = table.remove( data, actionID )
                                        table.insert( data, actionID + 1, a )
                                        packControl.actionID = format( "%04d", actionID + 1 )

                                        local listName = format( "%s:%s:", pack, packControl.listName )
                                        scripts:SwapScripts( listName .. actionID, listName .. ( actionID + 1 ) )
                                    end,
                                    disabled = function()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        return not p.lists[ packControl.listName ] or tonumber( packControl.actionID ) == #p.lists[ packControl.listName ]
                                    end,
                                    hidden = function () return packControl.makingNew end,
                                },                                                                                

                                newActionBtn = {
                                    type = "execute",
                                    name = "",
                                    image = "Interface\\AddOns\\Hekili\\Textures\\GreenPlus",
                                    -- image = GetAtlasFile( "communities-icon-addgroupplus" ),
                                    -- imageCoords = GetAtlasCoords( "communities-icon-addgroupplus" ),
                                    imageHeight = 20,
                                    imageWidth = 20,
                                    width = 0.15,
                                    order = 2.3,
                                    func = function()
                                        local data = rawget( self.DB.profile.packs, pack )
                                        if data then
                                            table.insert( data.lists[ packControl.listName ], { {} } )
                                            packControl.actionID = format( "%04d", #data.lists[ packControl.listName ] )
                                        else
                                            packControl.actionID = "0001"
                                        end
                                    end,
                                    hidden = function () return packControl.makingNew end,
                                },

                                delActionBtn = {
                                    type = "execute",
                                    name = "",
                                    image = RedX,
                                    -- image = GetAtlasFile( "communities-icon-redx" ),
                                    -- imageCoords = GetAtlasCoords( "communities-icon-redx" ),
                                    imageHeight = 20,
                                    imageWidth = 20,
                                    width = 0.15,
                                    order = 2.4,
                                    confirm = function() return "删去此条目?" end,
                                    func = function ()
                                        local id = tonumber( packControl.actionID )
                                        local p = rawget( Hekili.DB.profile.packs, pack )

                                        table.remove( p.lists[ packControl.listName ], id )

                                        if not p.lists[ packControl.listName ][ id ] then id = id - 1; packControl.actionID = format( "%04d", id ) end
                                        if not p.lists[ packControl.listName ][ id ] then packControl.actionID = "zzzzzzzzzz" end

                                        self:LoadScripts()
                                    end,
                                    disabled = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                        return not p.lists[ packControl.listName ] or #p.lists[ packControl.listName ] < 2 
                                    end,
                                    hidden = function () return packControl.makingNew end,
                                },

                                --[[ actionGroup = {
                                    type = "group",
                                    inline = true,
                                    name = "",
                                    order = 3,
                                    hidden = function ()
                                        local p = rawget( Hekili.DB.profile.packs, pack )

                                        if packControl.makingNew or rawget( p.lists, packControl.listName ) == nil or packControl.actionID == "zzzzzzzzzz" then
                                            return true
                                        end
                                        return false
                                    end,
                                    args = {                                    
                                        entry = {
                                            type = "group",
                                            inline = true,
                                            name = "",
                                            order = 2,
                                            -- get = 'GetActionOption',
                                            -- set = 'SetActionOption',
                                            hidden = function( info )
                                                local id = tonumber( packControl.actionID )
                                                local p = rawget( Hekili.DB.profile.packs, pack )
                                                return not packControl.actionID or packControl.actionID == "zzzzzzzzzz" or not p.lists[ packControl.listName ][ id ]
                                            end,
                                            args = { ]]
                                                enabled = {
                                                    type = "toggle",
                                                    name = "启用",
                                                    desc = "如果禁用, 即使符合标准该条目也不会显示.",
                                                    order = 3.0,
                                                    width = "full",
                                                },

                                                action = {
                                                    type = "select",
                                                    name = "操作",
                                                    desc = "选择在满足该条目的标准时建议采取的操作.",
                                                    values = class.abilityList,
                                                    order = 3.1,
                                                    width = 1.5,
                                                },

                                                caption = {
                                                    type = "input",
                                                    name = "标题",
                                                    desc = "标题是|cFFFF0000非常|r简短的描述可以出现在推荐技能的图标上.\n\n" ..
                                                        "这对于理解为什么在某一特定时间推荐某项技能是很有帮助.\n\n" ..
                                                        "需要在每个显示上启用字幕.",
                                                    order = 3.2,
                                                    width = 1.5,
                                                    validate = function( info, val )
                                                        val = val:trim()
                                                        if val:len() > 20 then return "标题应在20个字符或以下." end
                                                        return true
                                                    end,
                                                    hidden = function()
                                                        local e = GetListEntry( pack )
                                                        local ability = e.action and class.abilities[ e.action ]

                                                        return not ability or ( ability.id < 0 and ability.id > -10 )
                                                    end,
                                                },

                                                list_name = {
                                                    type = "select",
                                                    name = "操作列表",
                                                    values = function ()
                                                        local e = GetListEntry( pack )
                                                        local v = {}

                                                        local p = rawget( Hekili.DB.profile.packs, pack )

                                                        for k in pairs( p.lists ) do
                                                            if k ~= packControl.listName then
                                                                if k == 'precombat' or k == 'default' then
                                                                    v[ k ] = "|cFF00B4FF" .. k .. "|r"
                                                                else
                                                                    v[ k ] = k
                                                                end
                                                            end
                                                        end

                                                        return v
                                                    end,
                                                    order = 3.2,
                                                    width = 1.2,
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return not ( e.action == "call_action_list" or e.action == "run_action_list" )
                                                    end,                                                    
                                                },

                                                buff_name = {
                                                    type = "select",
                                                    name = "Buff名称",
                                                    order = 3.2,
                                                    width = 1.5,
                                                    desc = "指定要删除的buff.",
                                                    values = class.auraList,
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return e.action ~= "cancel_buff"
                                                    end,
                                                },

                                                potion = {
                                                    type = "select",
                                                    name = "药水",
                                                    order = 3.2,
                                                    -- width = "full",
                                                    values = class.potionList,
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return e.action ~= "potion"
                                                    end,
                                                    width = 1.2,
                                                },

                                                sec = {
                                                    type = "input",
                                                    name = "秒",
                                                    order = 3.2,
                                                    width = 1.2,
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return e.action ~= "wait"
                                                    end,
                                                },

                                                max_energy = {
                                                    type = "toggle",
                                                    name = "最大能量",
                                                    order = 3.2,
                                                    width = 1.2,
                                                    desc = "勾选后, 该条目将要求玩家有足够的能量来触发凶猛撕咬的全部伤害加成.",
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return e.action ~= "ferocious_bite"
                                                    end,
                                                },

                                                description = {
                                                    type = "input",
                                                    name = "说明",
                                                    desc = "这允许你提供文本来解释这个条目，这将显示当你鼠标悬停是能够看到" ..
                                                        "为什么这个条目被推荐.",
                                                    order = 3.205,
                                                    width = "full",
                                                },

                                                lb01 = {
                                                    type = "description",
                                                    name = "",
                                                    order = 3.21,
                                                    width = "full"
                                                },

                                                var_name = {
                                                    type = "input",
                                                    name = "变量名",
                                                    order = 3.3,
                                                    width = 1.5,
                                                    desc = "为该变量指定一个名称. 变量必须小写除下划线外没有空格或符号.",
                                                    validate = function( info, val )
                                                        if val:len() < 3 then return "变量的长度必须至少为3个字符." end

                                                        local check = formatKey( val )
                                                        if check ~= val then return "输入的无效字符. 再试一次." end

                                                        return true
                                                    end,
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return e.action ~= "variable"
                                                    end,
                                                },

                                                op = {
                                                    type = "select",
                                                    name = "行动",
                                                    values = {
                                                        add = "加",
                                                        ceil = "向上取整",
                                                        default = "设置默认",
                                                        div = "除",
                                                        floor = "向下取整",
                                                        max = "最大",
                                                        min = "最小",
                                                        mod = "取模",
                                                        mul = "乘",
                                                        pow = "幂",
                                                        reset = "重置",
                                                        set = "设置",
                                                        setif = "条件设置",
                                                        sub = "减",
                                                    },
                                                    order = 3.31,
                                                    width = 1.5,
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return e.action ~= "variable"
                                                    end,
                                                },

                                                modPooling = {
                                                    type = "group",
                                                    inline = true,
                                                    name = "",
                                                    order = 3.5,
                                                    args = {
                                                        for_next = {
                                                            type = "toggle",
                                                            name = function ()
                                                                local n = packControl.actionID; n = tonumber( n ) + 1
                                                                local e = Hekili.DB.profile.packs[ pack ].lists[ packControl.listName ][ n ]

                                                                local ability = e and e.action and class.abilities[ e.action ]
                                                                ability = ability and ability.name or "未设置"

                                                                return "下一个条目的资源 (" .. ability ..")"
                                                            end,
                                                            desc = "如果勾选, 该插件将汇集资源直到下一个条目有足够的资源可以使用.",
                                                            order = 5,
                                                            width = 1.5,
                                                            hidden = function ()
                                                                local e = GetListEntry( pack )
                                                                return e.action ~= "pool_resource"
                                                            end,
                                                        },

                                                        wait = {
                                                            type = "input",
                                                            name = "资源时间",
                                                            desc = "以秒为单位将时间指定为数字或计算为数字的表达式.\n" ..
                                                                "默认值为|cFFFFD1000.5|r. 例如表达式是|cFFFFD100energy.time_to_max|r.",
                                                            order = 6,
                                                            width = 1.5,
                                                            multiline = 3,
                                                            hidden = function ()
                                                                local e = GetListEntry( pack )
                                                                return e.action ~= "pool_resource" or e.for_next == 1
                                                            end,
                                                        },

                                                        extra_amount = {
                                                            type = "input",
                                                            name = "额外的资源",
                                                            desc = "除了下一个条目所需的资源外还需指定额外资源的数量.",
                                                            order = 6,
                                                            width = 1.5,
                                                            hidden = function ()
                                                                local e = GetListEntry( pack )
                                                                return e.action ~= "pool_resource" or e.for_next ~= 1
                                                            end,
                                                        },
                                                    },
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return e.action ~= 'pool_resource'
                                                    end,
                                                },

                                                criteria = {
                                                    type = "input",
                                                    name = "条件",
                                                    order = 3.6,
                                                    width = "full",
                                                    multiline = 6,
                                                    dialogControl = "HekiliCustomEditor",
                                                    arg = function( info )
                                                        local pack, list, action = info[ 2 ], packControl.listName, tonumber( packControl.actionID )        
                                                        local results = {}

                                                        state.reset()

                                                        local apack = rawget( self.DB.profile.packs, pack )

                                                        -- Let's load variables, just in case.
                                                        for name, alist in pairs( apack.lists ) do
                                                            for i, entry in ipairs( alist ) do
                                                                if name ~= list or i ~= action then
                                                                    if entry.action == "variable" and entry.var_name then
                                                                        state:RegisterVariable( entry.var_name, pack .. ":" .. name .. ":" .. i, name )
                                                                    end
                                                                end
                                                            end
                                                        end

                                                        local entry = apack and apack.lists[ list ]
                                                        entry = entry and entry[ action ]        

                                                        state.this_action = entry.action

                                                        local scriptID = pack .. ":" .. list .. ":" .. action
                                                        state.scriptID = scriptID
                                                        scripts:StoreValues( results, scriptID )

                                                        return results, list, action
                                                    end,                                      
                                                },

                                                value = {
                                                    type = "input",
                                                    name = "值",
                                                    desc = "当调用此变量时提供要存储(或计算)的值.",
                                                    order = 3.61,
                                                    width = "full",
                                                    multiline = 3,
                                                    dialogControl = "HekiliCustomEditor",
                                                    arg = function( info )
                                                        local pack, list, action = info[ 2 ], packControl.listName, tonumber( packControl.actionID )        
                                                        local results = {}

                                                        state.reset()

                                                        local apack = rawget( self.DB.profile.packs, pack )

                                                        -- Let's load variables, just in case.
                                                        for name, alist in pairs( apack.lists ) do
                                                            for i, entry in ipairs( alist ) do
                                                                if name ~= list or i ~= action then
                                                                    if entry.action == "variable" and entry.var_name then
                                                                        state:RegisterVariable( entry.var_name, pack .. ":" .. name .. ":" .. i, name )
                                                                    end
                                                                end
                                                            end
                                                        end

                                                        local entry = apack and apack.lists[ list ]
                                                        entry = entry and entry[ action ]        

                                                        state.this_action = entry.action

                                                        local scriptID = pack .. ":" .. list .. ":" .. action
                                                        state.scriptID = scriptID
                                                        scripts:StoreValues( results, scriptID, "value" )

                                                        return results, list, action
                                                    end,
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        return e.action ~= "variable" or e.op == "reset" or e.op == "ceil" or e.op == "floor"
                                                    end,
                                                },

                                                value_else = {
                                                    type = "input",
                                                    name = "其他值",
                                                    desc = "如果不满足该变量的条件，提供要存储(或计算)的值.",
                                                    order = 3.62,
                                                    width = "full",
                                                    multiline = 3,
                                                    dialogControl = "HekiliCustomEditor",
                                                    arg = function( info )
                                                        local pack, list, action = info[ 2 ], packControl.listName, tonumber( packControl.actionID )        
                                                        local results = {}

                                                        state.reset()

                                                        local apack = rawget( self.DB.profile.packs, pack )

                                                        -- Let's load variables, just in case.
                                                        for name, alist in pairs( apack.lists ) do
                                                            for i, entry in ipairs( alist ) do
                                                                if name ~= list or i ~= action then
                                                                    if entry.action == "variable" and entry.var_name then
                                                                        state:RegisterVariable( entry.var_name, pack .. ":" .. name .. ":" .. i )
                                                                    end
                                                                end
                                                            end
                                                        end

                                                        local entry = apack and apack.lists[ list ]
                                                        entry = entry and entry[ action ]        

                                                        state.this_action = entry.action

                                                        local scriptID = pack .. ":" .. list .. ":" .. action
                                                        state.scriptID = scriptID
                                                        scripts:StoreValues( results, scriptID, "value_else" )

                                                        return results, list, action
                                                    end,
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        -- if not e.criteria or e.criteria:trim() == "" then return true end
                                                        return e.action ~= "variable" or e.op == "reset" or e.op == "ceil" or e.op == "floor"
                                                    end,
                                                },

                                                showModifiers = {
                                                    type = "toggle",
                                                    name = "显示修饰符",
                                                    desc = "如果勾选, 可能会设置一些额外的修饰符和条件.",
                                                    order = 20,
                                                    width = "full",
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        local ability = e.action and class.abilities[ e.action ]

                                                        return not ability -- or ( ability.id < 0 and ability.id > -100 )
                                                    end,
                                                },

                                                modCycle = {
                                                    type = "group",
                                                    inline = true,
                                                    name = "",
                                                    order = 21,
                                                    args = {
                                                        cycle_targets = {
                                                            type = "toggle",
                                                            name = "循环目标",
                                                            desc = "如果勾选, 插件将检查每个可用的目标并显示是否切换目标.",
                                                            order = 1,
                                                            width = "single",
                                                        },

                                                        max_cycle_targets = {
                                                            type = "input",
                                                            name = "最大循环目标",
                                                            desc = "如果勾选循环目标, 插件将检查到指定的目标数量.",
                                                            order = 2,
                                                            width = "double",
                                                            disabled = function( info )
                                                                local e = GetListEntry( pack )
                                                                return e.cycle_targets ~= 1
                                                            end,
                                                        }
                                                    },
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        local ability = e.action and class.abilities[ e.action ]

                                                        return not packControl.showModifiers or ( not ability or ( ability.id < 0 and ability.id > -100 ) )
                                                    end,
                                                },

                                                modMoving = {
                                                    type = "group",
                                                    inline = true,
                                                    name = "",
                                                    order = 22,
                                                    args = {
                                                        enable_moving = {
                                                            type = "toggle",
                                                            name = "检查动作",
                                                            desc = "如果勾选, 那么只有当你的角色动作与设定相匹配时才可以推荐这个条目.",
                                                            order = 1,
                                                        },

                                                        moving = {
                                                            type = "select",
                                                            name = "动作",
                                                            desc = "如果设置, 这个条目只能在你的动作符合设置的情况下才能推荐给你.",
                                                            order = 2,
                                                            width = "double",
                                                            values = {
                                                                [0]  = "静止",
                                                                [1]  = "移动"
                                                            },
                                                            disabled = function( info )
                                                                local e = GetListEntry( pack )
                                                                return not e.enable_moving
                                                            end,
                                                        }
                                                    },
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        local ability = e.action and class.abilities[ e.action ]

                                                        return not packControl.showModifiers or ( not ability or ( ability.id < 0 and ability.id > -100 ) )
                                                    end,
                                                },

                                                modAsyncUsage = {
                                                    type = "group",
                                                    inline = true,
                                                    name = "",
                                                    order = 22.1,
                                                    args = {
                                                        use_off_gcd = {
                                                            type = "toggle",
                                                            name = "使用关闭全局冷却时间",
                                                            desc = "如果勾选, 即使全局冷却时间(GCD)处于激活状态该条目也可以被选中.",
                                                            order = 1,
                                                            width = 0.99,
                                                        },
                                                        use_while_casting = {
                                                            type = "toggle",
                                                            name = "施法时使用",
                                                            desc = "如果勾选, 即使你已经在施放或引导该条目也可以被选中.",
                                                            order = 2,
                                                            width = 0.99
                                                        },
                                                        only_cwc = {
                                                            type = "toggle",
                                                            name = "引导期间",
                                                            desc = "如果勾选, 这个条目只能在你正在引导另一个法术时使用.",
                                                            order = 3,
                                                            width = 0.99
                                                        }
                                                    },
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        local ability = e.action and class.abilities[ e.action ]

                                                        return not packControl.showModifiers or ( not ability or ( ability.id < 0 and ability.id > -100 ) )
                                                    end,                                                    
                                                },

                                                modCooldown = {
                                                    type = "group",
                                                    inline = true,
                                                    name = "",
                                                    order = 23,
                                                    args = {
                                                        --[[ enable_line_cd = {
                                                            type = "toggle",
                                                            name = "Line Cooldown",
                                                            desc = "If enabled, this entry cannot be recommended unless the specified amount of time has passed since its last use.",
                                                            order = 1,
                                                        }, ]]

                                                        line_cd = {
                                                            type = "input",
                                                            name = "进入冷却",
                                                            desc = "如果设置了, 除非上次使用该技能的时间已经过去否则不推荐此条目.",
                                                            order = 1,
                                                            width = "full", 
                                                            --[[ disabled = function( info )
                                                                local e = GetListEntry( pack )
                                                                return not e.enable_line_cd
                                                            end, ]]
                                                        },
                                                    },
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        local ability = e.action and class.abilities[ e.action ]

                                                        return not packControl.showModifiers or ( not ability or ( ability.id < 0 and ability.id > -100 ) )
                                                    end,
                                                },

                                                modAPL = {
                                                    type = "group",
                                                    inline = true,
                                                    name = "",
                                                    order = 24,
                                                    args = {
                                                        strict = {
                                                            type = "toggle",
                                                            name = "严格/时间不明感",
                                                            desc = "如果勾选, 插件将假定该条目不是时效性的, 如果目前不符合标准则不会链接优先级列表中的操作.",
                                                            order = 1,
                                                            width = "full",                                                            
                                                        }                                                    
                                                    },
                                                    hidden = function ()
                                                        local e = GetListEntry( pack )
                                                        local ability = e.action and class.abilities[ e.action ]

                                                        return not packControl.showModifiers or ( not ability or not ( ability.key == "call_action_list" or ability.key == "run_action_list" ) )
                                                    end,
                                                },

                                                --[[ deleteHeader = {
                                                    type = "header",
                                                    name = "Delete Action",
                                                    order = 100,
                                                    hidden = function ()
                                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                                        return #p.lists[ packControl.listName ] < 2 end
                                                },

                                                delete = {
                                                    type = "execute",
                                                    name = "Delete Entry",
                                                    order = 101,
                                                    confirm = true,
                                                    func = function ()
                                                        local id = tonumber( packControl.actionID )
                                                        local p = rawget( Hekili.DB.profile.packs, pack )

                                                        table.remove( p.lists[ packControl.listName ], id )

                                                        if not p.lists[ packControl.listName ][ id ] then id = id - 1; packControl.actionID = format( "%04d", id ) end
                                                        if not p.lists[ packControl.listName ][ id ] then packControl.actionID = "zzzzzzzzzz" end

                                                        self:LoadScripts()
                                                    end,
                                                    hidden = function ()
                                                        local p = rawget( Hekili.DB.profile.packs, pack )
                                                        return #p.lists[ packControl.listName ] < 2 
                                                    end
                                                }
                                            },
                                        },
                                    }
                                }, ]]

                                newListGroup = {
                                    type = "group",
                                    inline = true,
                                    name = "",
                                    order = 2,
                                    hidden = function ()
                                        return not packControl.makingNew
                                    end,
                                    args = {
                                        newListName = {
                                            type = "input",
                                            name = "列表名字",
                                            order = 1,
                                            validate = function( info, val )
                                                local p = rawget( Hekili.DB.profile.packs, pack )

                                                if val:len() < 2 then return "操作列表的名称至少要有2个字符的长度."
                                                elseif rawget( p.lists, val ) then return "该名称已经有一个操作列表."
                                                elseif val:find( "[^a-zA-Z0-9_]" ) then return "列表名称中只能使用字母数字字符和下划线." end
                                                return true
                                            end,
                                            width = 3,
                                        },

                                        lineBreak = {
                                            type = "description",
                                            name = "",
                                            order = 1.1,
                                            width = "full"
                                        },

                                        createList = {
                                            type = "execute",
                                            name = "增加列表",
                                            disabled = function() return packControl.newListName == nil end,
                                            func = function ()
                                                local p = rawget( Hekili.DB.profile.packs, pack )
                                                p.lists[ packControl.newListName ] = { {} }                                                
                                                packControl.listName = packControl.newListName
                                                packControl.makingNew = false

                                                packControl.actionID = "0001"
                                                packControl.newListName = nil

                                                Hekili:LoadScript( pack, packControl.listName, 1 )
                                            end,
                                            width = 1,
                                            order = 2,
                                        },

                                        cancel = {
                                            type = "execute",
                                            name = "删除",
                                            func = function ()
                                                packControl.makingNew = false
                                            end,
                                        }
                                    }
                                },

                                newActionGroup = {
                                    type = "group",
                                    inline = true,
                                    name = "",
                                    order = 3,
                                    hidden = function ()
                                        return packControl.makingNew or packControl.actionID ~= "zzzzzzzzzz"
                                    end,
                                    args = {
                                        createEntry = {
                                            type = "execute",
                                            name = "创建新条目",
                                            order = 1,
                                            func = function ()
                                                local p = rawget( Hekili.DB.profile.packs, pack )
                                                table.insert( p.lists[ packControl.listName ], {} )
                                                packControl.actionID = format( "%04d", #p.lists[ packControl.listName ] )
                                            end,
                                        }
                                    }
                                }
                            },
                            plugins = {
                            }
                        },

                        export = {
                            type = "group",
                            name = "导出",
                            order = 4,
                            args = {
                                exportString = {
                                    type = "input",
                                    name = "导出字符串(CTRL+A选择, CTRL+C复制)",
                                    get = function( info )
                                        return self:SerializeActionPack( pack )
                                    end,
                                    set = function () return end,
                                    order = 1,
                                    width = "full"
                                }
                            }
                        }
                    },
                }

                --[[ wipe( opts.args.lists.plugins.lists )

                local n = 10
                for list in pairs( data.lists ) do
                    opts.args.lists.plugins.lists[ list ] = EmbedActionListOptions( n, pack, list )
                    n = n + 1
                end ]]

                packs.plugins.packages[ pack ] = opts
                count = count + 1
            end
        end

        collectgarbage()
        db.args.packs = packs
    end

end


do
    do
        local completed = false
        local SetOverrideBinds

        SetOverrideBinds = function ()
            if InCombatLockdown() then
                C_Timer.After( 5, SetOverrideBinds )
                return
            end

            if completed then
                ClearOverrideBindings( Hekili_Keyhandler )
                completed = false
            end

            for name, toggle in pairs( Hekili.DB.profile.toggles ) do
                if toggle.key and toggle.key ~= "" then
                    SetOverrideBindingClick( Hekili_Keyhandler, true, toggle.key, "Hekili_Keyhandler", name )
                    completed = true
                end
            end
        end

        function Hekili:OverrideBinds()
            SetOverrideBinds()
        end
    end


    local ACD = LibStub( "AceConfigDialog-3.0" )

    local modeTypes = {
        oneAuto = 1,
        oneSingle = 2,
        oneAOE = 3,
        twoDisplays = 4,
        reactive = 5,
    }    

    local function SetToggle( info, val )
        local self = Hekili
        local p = self.DB.profile
        local n = #info
        local bind, option = info[ 2 ], info[ n ]

        local toggle = p.toggles[ bind ]
        if not toggle then return end

        if option == 'value' then
            if bind == 'pause' then self:TogglePause()
            elseif bind == 'mode' then toggle.value = val
            else self:FireToggle( bind ) end

        elseif option == 'type' then
            toggle.type = val

            if val == "AutoSingle" and not ( toggle.value == "automatic" or toggle.value == "single" ) then toggle.value = "automatic" end
            if val == "AutoDual" and not ( toggle.value == "automatic" or toggle.value == "dual" ) then toggle.value = "automatic" end
            if val == "SingleAOE" and not ( toggle.value == "single" or toggle.value == "aoe" ) then toggle.value = "single" end
            if val == "ReactiveDual" and toggle.value ~= "reactive" then toggle.value = "reactive" end

        elseif option == 'key' then
            for t, data in pairs( p.toggles ) do
                if data.key == val then data.key = "" end
            end

            toggle.key = val
            self:OverrideBinds()

        elseif option == 'override' then
            toggle[ option ] = val
            ns.UI.Minimap:RefreshDataText()

        else
            toggle[ option ] = val

        end
    end

    local function GetToggle( info )
        local self = Hekili
        local p = Hekili.DB.profile
        local n = #info
        local bind, option = info[2], info[ n ]

        local toggle = bind and p.toggles[ bind ]
        if not toggle then return end

        if bind == 'pause' and option == 'value' then return self.Pause end
        return toggle[ option ]
    end

    -- Bindings.
    function Hekili:EmbedToggleOptions( db )
        db = db or self.Options
        if not db then return end

        db.args.toggles = db.args.toggles or {
            type = 'group',
            name = '切换',
            order = 20,
            get = GetToggle,
            set = SetToggle,
            args = {
                info = {
                    type = "description",
                    name = "切换是按键绑定, 可以使用它们来指导插件的建议及其显示方式.",
                    order = 0.5,
                    fontSize = "medium",
                },

                cooldowns = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 2,
                    args = {
                        key = {
                            type = "keybinding",
                            name = "CD",
                            desc = "设置一个键来切换冷却时间建议的开启/关闭.",
                            order = 1,
                        },

                        value = {
                            type = "toggle",
                            name = "显示CD",
                            desc = "如果勾选, 可以推荐标记为冷却时间的技能.",
                            order = 2,                            
                        },

                        separate = {
                            type = "toggle",
                            name = NewFeature .. " 单独显示",
                            desc = "如果勾选, CD将单独显示在你的CD显示中.\n\n" ..
                                "这是一个实验性的功能对于某些专精来说可能效果不好.",
                            order = 3,
                        },

                        lineBreak = {
                            type = "description",
                            name = "",
                            width = "full",
                            order = 3.1,
                        },

                        indent = {
                            type = "description",
                            name = "",
                            width = 1,
                            order = 3.2
                        },

                        override = {
                            type = "toggle",
                            name = "嗜血至上",
                            desc = "如果勾选, 当嗜血(或类似效果)处于活动状态时, 即使不勾选显示CD插件也会推荐CD技能.",
                            order = 4,
                        }
                    }
                },

                essences = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 2.1,
                    args = {
                        key = {
                            type = "keybinding",
                            name = "精华",
                            desc = "设置一个键来切换开启/关闭艾泽瑞特精华的推荐功能.",
                            order = 1,
                        },

                        value = {
                            type = "toggle",
                            name = "显示精华",
                            desc = "如果勾选, 可以推荐艾泽里特精华的能力.",
                            order = 2,                            
                        },

                        override = {
                            type = "toggle",
                            name = "CD覆盖",
                            desc = "如果勾选, 在启用CD时即使不勾选显示精华插件也会推荐艾泽里特精华.",
                            order = 3,
                        },
                    }
                },                

                defensives = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 5,
                    args = {
                        key = {
                            type = "keybinding",
                            name = "防御",
                            desc = "设置一个键, 以切换防御/减伤建议的开启/关.\n" ..
                                "\n这只适用于坦克专精.",
                            order = 1,
                        },

                        value = {
                            type = "toggle",
                            name = "显示防御",
                            desc = "如果勾选, 可以推荐标记为防御型的技能.\n" ..
                                "\n这只适用于坦克专精.",
                            order = 2,                            
                        },

                        separate = {
                            type = "toggle",
                            name = "分开显示",
                            desc = "如果勾选, 防御/减伤技能将在你的防御显示中单独显示.\n" ..
                                "\n这只适用于坦克专精.",
                            order = 3,
                        }
                    }
                },

                interrupts = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 4,
                    args = {
                        key = {
                            type = "keybinding",
                            name = "打断",
                            desc = "设置一个键用于切换打断的开启/关闭.",
                            order = 1,                            
                        },

                        value = {
                            type = "toggle",
                            name = "显示打断",
                            desc = "如果勾选, 可以推荐标记为打断的技能.",
                            order = 2,
                        },

                        separate = {
                            type = "toggle",
                            name = "分开显示",
                            desc = "如果勾选, 打断技能将仅在打断显示中单独显示(如果启用的话).",
                            order = 3,
                        }
                    }
                },

                potions = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 6,
                    args = {
                        key = {
                            type = "keybinding",
                            name = "药水",
                            desc = "设置一个键来切换药水建议的开启/关闭.",
                            order = 1,
                        },

                        value = {
                            type = "toggle",
                            name = "显示药水",
                            desc = "如果勾选, 可以推荐标记为药水的技能.",
                            order = 2,
                        },
                    }
                },

                displayModes = {
                    type = "header",
                    name = "显示模式",
                    order = 10,
                },

                mode = {
                    type = "group",
                    inline = true,
                    name = "",
                    order = 10.1,
                    args = {
                        key = {
                            type = 'keybinding',
                            name = '显示模式',
                            desc = "按此键将在下列选项中循环显示模式的选项.",
                            order = 1,
                            width = 1,
                        },

                        value = {
                            type = "select",
                            name = "当前显示模式",
                            desc = "选择当前的显示模式.",
                            values = {
                                automatic = "自动",
                                single = "单目标",
                                aoe = "AOE (多目标)",
                                dual = "固定式双显示",
                                reactive = "反应式双显示"
                            },
                            width = 2,
                            order = 1.02,
                        },

                        modeLB2 = {
                            type = "description",
                            name = "选择要使用的|cFFFFD100显示模式|r. 每当按下|cFFFFD100显示模式|r按键绑定后，插件就会切换到下一个被选中的模式.",
                            fontSize = "medium",
                            width = "full",
                            order = 1.03
                        },

                        automatic = {
                            type = "toggle",
                            name = "自动",
                            desc = "如果勾选, 显示模式切换可以选择自动模式.\n\n初级显示会根据检测到的敌人数量显示建议(根据专精选项).",
                            width = 1.5,
                            order = 1.1,
                        },

                        single = {
                            type = "toggle",
                            name = "单目标",
                            desc = "如果勾选, 显示模式切换可以选择单目标模式.\n\n主显示推荐就好像你有一个目标一样(即使发现了更多的目标).",
                            width = 1.5,
                            order = 1.2,
                        },

                        aoe = {
                            type = "toggle",
                            name = "AOE(多目标)",
                            desc = function ()
                                return format( "如果勾选, 显示模式切换可以选择AOE模式.\n\n主显示推荐好像你有多个(%d)目标一样(即使检测到的更少).\n\n" ..
                                                "目标的数量是在你的专精选项中设置的.", self.DB.profile.specs[ state.spec.id ].aoe or 3 )
                            end,
                            width = 1.5,
                            order = 1.3,
                        },

                        dual = {
                            type = "toggle",
                            name = "固定式双显示",
                            desc = function ()
                                return format( "如果勾选, 显示模式切换可以选择固定式双显示模式.\n\n主显示是单个目标的建议而AOE显示屏显示的是多个(%d)目标的建议(即使检测到的更少).\n\n" ..
                                                "AOE目标的数量是在你的专精选项中设置的.", self.DB.profile.specs[ state.spec.id ].aoe or 3 )
                            end,
                            width = 1.5,
                            order = 1.4,
                        },

                        reactive = {
                            type = "toggle",
                            name = "反应式双显示",
                            desc = "如果勾选, 显示模式切换可以选择反应式双显示模式.\n\n主显示单个目标建议而AOE保持隐藏状态, 直到/除非检测到其他目标.",
                            width = 1.5,
                            order = 1.5,
                        },

                        --[[ type = {
                            type = "select",
                            name = "Modes",
                            desc = "Select the Display Modes that can be cycled using your Display Mode key.\n\n" ..
                                "|cFFFFD100Auto vs. Single|r - Using only the Primary display, toggle between automatic target counting and single-target recommendations.\n\n" .. 
                                "|cFFFFD100Single vs. AOE|r - Using only the Primary display, toggle between single-target recommendations and AOE (multi-target) recommendations.\n\n" ..
                                "|cFFFFD100Auto vs. Dual|r - Toggle between one display using automatic target counting and two displays, with one showing single-target recommendations and the other showing AOE recommendations.  This will use additional CPU.\n\n" ..
                                "|cFFFFD100Reactive AOE|r - Use the Primary display for single-target recommendations, and when additional enemies are detected, show the AOE display.  (Disables Mode Toggle)",
                            values = {
                                AutoSingle = "Auto vs. Single",
                                SingleAOE = "Single vs. AOE",
                                AutoDual = "Auto vs. Dual",
                                ReactiveDual = "Reactive AOE",
                            },
                            order = 2,
                        }, ]]
                    },
                },

                troubleshooting = {
                    type = "header",
                    name = "故障排除",
                    order = 20,                    
                },

                pause = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 20.1,
                    args = {
                        key = {
                            type = 'keybinding',
                            name = function () return Hekili.Pause and "取消暂停" or "暂停" end,
                            desc =  "设置一个键来暂停处理操作列表. " ..
                                    "当前显示将被冻结, 可以将鼠标移到每个图标上查看显示的操作信息.\n\n" ..
                                    "这也将创建一个快照可用于故障排除和错误报告.",
                            order = 1,
                        },
                        value = {
                            type = 'toggle',
                            name = '暂停',
                            order = 2,
                        },
                    }
                },

                snapshot = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 20.2,
                    args = {
                        key = {
                            type = 'keybinding',
                            name = '快照',
                            desc = "设置一个键来制作快照(无需暂停)可以在快照选项卡上查看. 这对于测试和调试来说是有用的信息.",
                            order = 1,
                        },
                    }
                },

                customHeader = {
                    type = "header",
                    name = "自定义",
                    order = 30,
                },

                custom1 = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 30.1,
                    args = {
                        key = {
                            type = "keybinding",
                            name = "自定义#1",
                            desc = "设置一个键来切换你的第一个自定义设置.",
                            order = 1,
                        },

                        value = {
                            type = "toggle",
                            name = "显示自定义#1",
                            desc = "如果勾选, 可以推荐与自定义#1相关的技能.",
                            order = 2,
                        },

                        name = {
                            type = "input",
                            name = "自定义#1名字",
                            desc = "为这个自定义切换开关指定一个名称.",
                            order = 3
                        }
                    }
                },

                custom2 = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 30.2,
                    args = {
                        key = {
                            type = "keybinding",
                            name = "自定义#2",
                            desc = "设置一个键来切换你的第一个自定义设置.",
                            order = 1,
                        },

                        value = {
                            type = "toggle",
                            name = "显示自定义#2",
                            desc = "如果勾选, 可以推荐与自定义#2相关的技能.",
                            order = 2,
                        },

                        name = {
                            type = "input",
                            name = "自定义#1名字",
                            desc = "为这个自定义切换开关指定一个名称.",
                            order = 3
                        }
                    }
                },                

                --[[ specLinks = {
                    type = "group",
                    inline = true,
                    name = "",
                    order = 10,
                    args = {
                        header = {
                            type = "header",
                            name = "Specializations",
                            order = 1,
                        },

                        specsInfo = {
                            type = "description",
                            name = "There may be additional toggles or settings for your specialization(s).  Use the buttons below to jump to that section.",
                            order = 2,
                            fontSize = "medium",
                        },                        
                    },
                    hidden = function( info )
                        local hide = true

                        for i = 1, 4 do
                            local id, name, desc = GetSpecializationInfo( i )
                            if not id then break end

                            local sName = lower( name )

                            if db.plugins.specializations[ sName ] then
                                db.args.toggles.args.specLinks.args[ sName ] = db.args.toggles.args.specLinks.args[ sName ] or {
                                    type = "execute",
                                    name = name,
                                    desc = desc,
                                    order = 5 + i,
                                    func = function ()
                                        ACD:SelectGroup( "Hekili", sName )
                                    end,
                                }
                                hide = false
                            end
                        end

                        return hide
                    end,
                } ]]
            }
        }
    end
end


do
    -- Generate a spec skeleton.
    local listener = CreateFrame( "Frame" )

    Hekili:ProfileFrame( "SkeletonListener", listener )

    local indent = ""
    local output = {}

    local function key( s )
        return ( lower( s or '' ):gsub( "[^a-z0-9_ ]", "" ):gsub( "%s", "_" ) )
    end

    local function increaseIndent()
        indent = indent .. "    "
    end

    local function decreaseIndent()
        indent = indent:sub( 1, indent:len() - 4 )
    end

    local function append( s )
        insert( output, indent .. s )
    end

    local function appendAttr( t, s )
        if t[ s ] ~= nil then
            if type( t[ s ] ) == 'string' then
                insert( output, indent .. s .. ' = "' .. tostring( t[s] ) .. '",' )
            else
                insert( output, indent .. s .. ' = ' .. tostring( t[s] ) .. ',' )
            end
        end
    end

    local spec = ""
    local specID = 0

    local mastery_spell = 0

    local resources = {}
    local talents = {}
    local pvptalents = {}
    local auras = {}
    local abilities = {}

    listener:RegisterEvent( "PLAYER_SPECIALIZATION_CHANGED" )
    listener:RegisterEvent( "PLAYER_ENTERING_WORLD" )
    listener:RegisterEvent( "UNIT_AURA" )
    listener:RegisterEvent( "SPELLS_CHANGED" )
    listener:RegisterEvent( "UNIT_SPELLCAST_SUCCEEDED" )
    listener:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" )

    local applications = {}
    local removals = {}

    local lastAbility = nil
    local lastTime = 0    

    local function CLEU( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
        if sourceName and UnitIsUnit( sourceName, "player" ) and type( spellName ) == 'string' then
            local now = GetTime()
            local token = key( spellName )

            if subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_APPLIED_DOSE" or subtype == "SPELL_AURA_REFRESH" or 
               subtype == "SPELL_PERIODIC_AURA_APPLIED" or subtype == "SPELL_PERIODIC_AURA_APPLIED_DOSE" or subtype == "SPELL_PERIODIC_AURA_REFRESH" then
                -- the last ability probably refreshed this aura.
                if lastAbility and now - lastTime < 0.25 then
                    -- Go ahead and attribute it to the last cast.
                    local a = abilities[ lastAbility ]

                    if a then
                        a.applies = a.applies or {}
                        a.applies[ token ] = spellID
                    end
                else
                    insert( applications, { s = token, i = spellID, t = now } )
                end
            elseif subtype == "SPELL_AURA_REMOVED" or subtype == "SPELL_AURA_REMOVED_DOSE" or subtype == "SPELL_AURA_REMOVED" or 
                   subtype == "SPELL_PERIODIC_AURA_REMOVED" or subtype == "SPELL_PERIODIC_AURA_REMOVED_DOSE" or subtype == "SPELL_PERIODIC_AURA_BROKEN" then
                if lastAbility and now - lastTime < 0.25 then
                    -- Go ahead and attribute it to the last cast.
                    local a = abilities[ lastAbility ]

                    if a then
                        a.applies = a.applies or {}
                        a.applies[ token ] = spellID
                    end
                else
                    insert( removals, { s = token, i = spellID, t = now } )
                end
            end
        end
    end

    local function skeletonHandler( self, event, ... )
        local unit = select( 1, ... )

        if ( event == "PLAYER_SPECIALIZATION_CHANGED" and UnitIsUnit( unit, "player" ) ) or event == "PLAYER_ENTERING_WORLD" then
            local sID, s = GetSpecializationInfo( GetSpecialization() )
            if specID ~= sID then 
                wipe( resources )
                wipe( auras )
                wipe( abilities )
            end
            specID = sID
            spec = s

            mastery_spell = GetSpecializationMasterySpells( GetSpecialization() )

            for k, i in pairs( Enum.PowerType ) do
                if k ~= "NumPowerTypes" and i >= 0 then
                    if UnitPowerMax( "player", i ) > 0 then resources[ k ] = i end
                end
            end

            wipe( talents )
            for j = 1, 7 do
                for k = 1, 3 do
                    local tID, name, _, _, _, sID = GetTalentInfoBySpecialization( GetSpecialization(), j, k )
                    name = key( name )
                    insert( talents, { name = name, talent = tID, spell = sID } )
                end
            end

            wipe( pvptalents )
            local row = C_SpecializationInfo.GetPvpTalentSlotInfo( 1 )

            for i, tID in ipairs( row.availableTalentIDs ) do
                local _, name, _, _, _, sID = GetPvpTalentInfoByID( tID )
                name = key( name )
                insert( pvptalents, { name = name, talent = tID, spell = sID } )
            end

            local haste = UnitSpellHaste( "player" )
            haste = 1 + ( haste / 100 )

            for i = 1, GetNumSpellTabs() do
                local tab, _, offset, n = GetSpellTabInfo( i )

                if i == 2 or tab == spec then
                    for j = offset, offset + n do
                        local name, _, texture, castTime, minRange, maxRange, spellID = GetSpellInfo( j, "spell" )

                        if name and spellID ~= mastery_spell then 
                            local token = key( name )

                            castTime = castTime / 1000

                            local cost, min_cost, max_cost, cost_per_sec, cost_percent, resource

                            local costs = GetSpellPowerCost( spellID )

                            if costs then
                                for k, v in pairs( costs ) do
                                    if not v.hasRequiredAura or IsPlayerSpell( v.requiredAuraID ) then
                                        cost = v.costPercent > 0 and v.costPercent / 100 or v.cost
                                        cost_per_sec = v.costPerSecond
                                        resource = key( v.name )
                                        break
                                    end
                                end
                            end

                            local passive = IsPassiveSpell( spellID )
                            local harmful = IsHarmfulSpell( spellID )
                            local helpful = IsHelpfulSpell( spellID )

                            local _, charges, _, recharge = GetSpellCharges( spellID )
                            local cooldown
                            if recharge then cooldown = recharge
                            else
                                cooldown = GetSpellBaseCooldown( spellID )
                                if cooldown then cooldown = cooldown / 1000 end
                            end

                            local selfbuff = SpellIsSelfBuff( spellID )
                            local talent = IsTalentSpell( spellID )

                            if selfbuff or passive then
                                auras[ token ] = auras[ token ] or {}
                                auras[ token ].id = spellID
                            end

                            if not passive then
                                local a = abilities[ token ] or {}

                                -- a.key = token
                                a.desc = GetSpellDescription()
                                if a.desc then a.desc = a.desc:gsub( "\n", " " ):gsub( "\r", " " ):gsub( " ", " " ) end
                                a.id = spellID
                                a.spend = cost
                                a.spendType = resource
                                a.spendPerSec = cost_per_sec
                                a.cast = castTime
                                a.gcd = "spell"

                                a.texture = texture

                                if talent then a.talent = token end

                                a.startsCombat = not helpful

                                a.cooldown = cooldown
                                if a.charges and a.charges > 1 then 
                                    a.charges = charges
                                    a.recharge = recharge
                                end

                                abilities[ token ] = a
                            end
                        end
                    end
                end
            end
        elseif event == "SPELLS_CHANGED" then
            local haste = UnitSpellHaste( "player" )
            haste = 1 + ( haste / 100 )

            for i = 1, GetNumSpellTabs() do
                local tab, _, offset, n = GetSpellTabInfo( i )

                if tab == spec then
                    for j = offset, offset + n do
                        local name, _, texture, castTime, minRange, maxRange, spellID = GetSpellInfo( j, "spell" )

                        if name and spellID ~= mastery_spell then 
                            local token = key( name )

                            if castTime % 10 > 0 then
                                -- We can catch hasted cast times 90% of the time...
                                castTime = castTime * haste
                            end
                            castTime = castTime / 1000

                            local cost, min_cost, max_cost, spendPerSec, cost_percent, resource

                            local costs = GetSpellPowerCost( spellID )

                            if costs then
                                for k, v in pairs( costs ) do
                                    if not v.hasRequiredAura or IsPlayerSpell( v.requiredAuraID ) then
                                        cost = v.costPercent > 0 and v.costPercent / 100 or v.cost
                                        spendPerSec = v.costPerSecond
                                        resource = key( v.name )
                                        break
                                    end
                                end
                            end

                            local passive = IsPassiveSpell( spellID )
                            local harmful = IsHarmfulSpell( spellID )
                            local helpful = IsHelpfulSpell( spellID )

                            local _, charges, _, recharge = GetSpellCharges( spellID )
                            local cooldown
                            if recharge then cooldown = recharge
                            else
                                cooldown = GetSpellBaseCooldown( spellID )
                                if cooldown then cooldown = cooldown / 1000 end
                            end

                            local selfbuff = SpellIsSelfBuff( spellID )
                            local talent = IsTalentSpell( spellID )

                            if selfbuff or passive then
                                auras[ token ] = auras[ token ] or {}
                                auras[ token ].id = spellID
                            end

                            if not passive then
                                local a = abilities[ token ] or {}

                                -- a.key = token
                                a.desc = GetSpellDescription()
                                if a.desc then a.desc = a.desc:gsub( "\n", " " ):gsub( "\r", " " ):gsub( " ", " " ) end
                                a.id = spellID
                                a.spend = cost
                                a.spendType = resource
                                a.spendPerSec = spendPerSec
                                a.cast = castTime
                                a.gcd = "spell"

                                a.texture = texture

                                if talent then a.talent = token end

                                a.startsCombat = not helpful

                                a.cooldown = cooldown
                                a.charges = charges
                                a.recharge = recharge

                                abilities[ token ] = a
                            end
                        end
                    end
                end
            end
        elseif event == "UNIT_AURA" then
            if UnitIsUnit( unit, "player" ) or UnitCanAttack( "player", unit ) then
                for i = 1, 40 do
                    local name, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, _, spellID, canApplyAura, _, castByPlayer = UnitBuff( unit, i, "PLAYER" )

                    if not name then break end

                    local token = key( name )

                    local a = auras[ token ] or {}

                    if duration == 0 then duration = 3600 end

                    a.id = spellID
                    a.duration = duration
                    a.type = debuffType
                    a.max_stack = max( a.max_stack or 1, count )

                    auras[ token ] = a
                end

                for i = 1, 40 do
                    local name, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, _, spellID, canApplyAura, _, castByPlayer = UnitDebuff( unit, i, "PLAYER" )

                    if not name then break end

                    local token = key( name )

                    local a = auras[ token ] or {}

                    if duration == 0 then duration = 3600 end

                    a.id = spellID
                    a.duration = duration
                    a.type = debuffType
                    a.max_stack = max( a.max_stack or 1, count )

                    auras[ token ] = a
                end
            end

        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if UnitIsUnit( "player", unit ) then
                local spellID = select( 3, ... )
                local token = spellID and class.abilities[ spellID ] and class.abilities[ spellID ].key

                local now = GetTime()

                if not token then return end

                lastAbility = token
                lastTime = now

                local a = abilities[ token ]

                if not a then 
                    return 
                end

                for k, v in pairs( applications ) do
                    if now - v.t < 0.5 then
                        a.applies = a.applies or {}
                        a.applies[ v.s ] = v.i
                    end
                    applications[ k ] = nil
                end

                for k, v in pairs( removals ) do
                    if now - v.t < 0.5 then
                        a.removes = a.removes or {}
                        a.removes[ v.s ] = v.i
                    end
                    removals[ k ] = nil
                end
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            CLEU( event, CombatLogGetCurrentEventInfo() )
        end
    end

    function Hekili:StartListeningForSkeleton()
        listener:SetScript( "OnEvent", skeletonHandler )

        skeletonHandler( listener, "PLAYER_SPECIALIZATION_CHANGED", "player" )
        skeletonHandler( listener, "SPELLS_CHANGED" )
    end


    function Hekili:EmbedSkeletonOptions( db )
        db = db or self.Options
        if not db then return end

        db.args.skeleton = db.args.skeleton or {
            type = "group",
            name = "骨架",
            order = 100,
            args = {
                spooky = {
                    type = "input",
                    name = "骨架",
                    desc = "当前规格的粗略骨架, 仅用于开发目的.",
                    order = 1,
                    get = function( info )
                        return Hekili.Skeleton or ""
                    end,
                    multiline = 25,
                    width = "full"
                },
                regen = {
                    type = "execute",
                    name = "生成骨架",
                    order = 2,
                    func = function()
                        indent = ""
                        wipe( output )

                        append( "if UnitClassBase( 'player' ) == '" .. UnitClassBase( "player" ) .. "' then" )
                        increaseIndent()

                        append( "local spec = Hekili:NewSpecialization( " .. specID .. " )\n" )

                        for k, i in pairs( resources ) do
                            append( "spec:RegisterResource( Enum.PowerType." .. k .. " )" )
                        end

                        append( "" )
                        append( "-- Talents" )
                        append( "spec:RegisterTalents( {" )                        
                        increaseIndent()

                        for i, tal in ipairs( talents ) do
                            append( tal.name .. " = " .. tal.talent .. ", -- " .. tal.spell .. ( ( i % 3 == 0 and i < #talents ) and "\n" or "" ) )
                        end

                        decreaseIndent()
                        append( "} )\n" )

                        append( "-- PvP Talents" )
                        append( "spec:RegisterPvpTalents( { " )
                        increaseIndent()

                        for i, tal in ipairs( pvptalents ) do
                            append( tal.name .. " = " .. tal.talent .. ", -- " .. tal.spell )
                        end
                        decreaseIndent()
                        append( "} )\n" )

                        append( "-- Auras" )
                        append( "spec:RegisterAuras( {" )
                        increaseIndent()

                        for k, aura in orderedPairs( auras ) do
                            append( k .. " = {" )
                            increaseIndent()
                            append( "id = " .. aura.id .. "," )

                            for key, value in pairs( aura ) do
                                if key ~= "id" then
                                    if type(value) == 'string' then
                                        append( key .. ' = "' .. value .. '",' )
                                    else
                                        append( key .. " = " .. value .. "," )
                                    end
                                end
                            end

                            decreaseIndent()
                            append( "}," )
                        end

                        decreaseIndent()
                        append( "} )\n" )


                        append( "-- Abilities" )
                        append( "spec:RegisterAbilities( {" )
                        increaseIndent()

                        local count = 1
                        for k, a in orderedPairs( abilities ) do
                            if count > 1 then append( "\n" ) end
                            count = count + 1
                            append( k .. " = {" )
                            increaseIndent()
                            appendAttr( a, "id" )
                            appendAttr( a, "cast" )
                            appendAttr( a, "charges" )
                            appendAttr( a, "cooldown" )
                            appendAttr( a, "recharge" )
                            appendAttr( a, "gcd" )
                            append( "" )
                            appendAttr( a, "spend" )
                            appendAttr( a, "spendPerSec" )
                            appendAttr( a, "spendType" )
                            if a.spend ~= nil or a.spendPerSec ~= nil or a.spendType ~= nil then
                                append( "" )
                            end
                            appendAttr( a, "talent" )
                            if a.cooldown >= 60 then append( "toggle = \"cooldowns\",\n" ) end
                            if a.talent ~= nil then append( "" ) end
                            appendAttr( a, "startsCombat" )
                            appendAttr( a, "texture" )
                            append( "" )
                            append( "handler = function ()" )

                            if a.applies or a.removes then
                                increaseIndent()
                                if a.applies then
                                    for name, id in pairs( a.applies ) do
                                        append( "-- applies " .. name .. " (" .. id .. ")" )
                                    end
                                end
                                if a.removes then
                                    for name, id in pairs( a.removes ) do
                                        append( "-- removes " .. name .. " (" .. id .. ")" )
                                    end
                                end
                                decreaseIndent()
                            end
                            append( "end," )
                            decreaseIndent()
                            append( "}," )
                        end

                        decreaseIndent()
                        append( "} )\n" )

                        Hekili.Skeleton = table.concat( output, "\n" )
                    end,
                }
            },
            hidden = function()
                return not Hekili.Skeleton
            end,
        }

    end
end


do
    local selectedError = nil
    local errList = {}

    function Hekili:EmbedErrorOptions( db )
        db = db or self.Options
        if not db then return end

        db.args.errors = {
            type = "group",
            name = "错误",
            order = 99,
            args = {
                errName = {
                    type = "select",
                    name = "错误识别",
                    width = "full",
                    order = 1,

                    values = function()
                        wipe( errList )

                        for i, err in ipairs( self.ErrorKeys ) do
                            local eInfo = self.ErrorDB[ err ]

                            errList[ i ] = "[" .. eInfo.last .. " (" .. eInfo.n .. "x)] " .. err
                        end

                        return errList
                    end,

                    get = function() return selectedError end,
                    set = function( info, val ) selectedError = val end,
                },

                errorInfo = {
                    type = "input",
                    name = "错误信息",
                    width = "full",
                    multiline = 10,
                    order = 2,

                    get = function ()
                        if selectedError == nil then return "" end
                        return Hekili.ErrorKeys[ selectedError ]
                    end,

                    dialogControl = "HekiliCustomEditor",
                }
            },
            hidden = function() return #self.ErrorKeys == 0 end,
        }
    end
end


function Hekili:GenerateProfile()
    local s = state

    local spec = s.spec.key

    local talents
    for k, v in orderedPairs( s.talent ) do
        if v.enabled then
            if talents then talents = format( "%s\n    %s", talents, k )
            else talents = k end
        end
    end

    local pvptalents
    for k,v in orderedPairs( s.pvptalent ) do
        if v.enabled then
            if pvptalents then pvptalents = format( "%s\n   %s", pvptalents, k )
            else pvptalents = k end
        end
    end

    local covenants = { "kyrian", "necrolord", "night_fae", "venthyr" }
    local covenant = "none"
    for i, v in ipairs( covenants ) do
        if state.covenant[ v ] then covenant = v; break end
    end

    local conduits
    for k,v in orderedPairs( s.conduit ) do
        if v.enabled then
            if conduits then conduits = format( "%s\n   %s = %d", conduits, k, v.rank )
            else conduits = format( "%s = %d", k, v.rank ) end
        end
    end

    local soulbinds
    
    local activeBind = C_Soulbinds.GetActiveSoulbindID()
    if activeBind then
        soulbinds = "[" .. formatKey( C_Soulbinds.GetSoulbindData( activeBind ).name ) .. "]"
    end

    for k,v in orderedPairs( s.soulbind ) do
        if v.enabled then
            if soulbinds then soulbinds = format( "%s\n   %s = %d", soulbinds, k, v.rank )
            else soulbinds = format( "%s = %d", k, v.rank ) end
        end
    end    

    local sets
    for k, v in orderedPairs( class.gear ) do
        if s.set_bonus[ k ] > 0 then
            if sets then sets = format( "%s\n    %s = %d", sets, k, s.set_bonus[k] )
            else sets = format( "%s = %d", k, s.set_bonus[k] ) end
        end
    end

    local gear, items
    for k, v in orderedPairs( state.set_bonus ) do
        if v > 0 then
            if type(k) == 'string' then
            if gear then gear = format( "%s\n    %s = %d", gear, k, v )
            else gear = format( "%s = %d", k, v ) end
            elseif type(k) == 'number' then
                if items then items = format( "%s, %d", items, k )
                else items = tostring(k) end
            end
        end
    end

    local legendaries
    for k, v in orderedPairs( state.legendary ) do
        if k ~= "no_trait" and v.rank > 0 then
            if legendaries then legendaries = format( "%s\n    %s = %d", legendaries, k, v.rank )
            else legendaries = format( "%s = %d", k, v.rank ) end
        end
    end

    local settings
    for k, v in orderedPairs( state.settings.spec ) do        
        if type( v ) ~= "table" then
            if settings then settings = format( "%s\n    %s = %s", settings, k, tostring( v ) )
            else settings = format( "%s = %s", k, tostring( v ) ) end
        end
    end
    for k, v in orderedPairs( state.settings.spec.settings ) do
        if type( v ) ~= "table" then
            if settings then settings = format( "%s\n    %s = %s", settings, k, tostring( v ) )
            else settings = format( "%s = %s", k, tostring( v ) ) end
        end
    end

    local toggles
    for k, v in orderedPairs( self.DB.profile.toggles ) do
        if type( v ) == "table" and rawget( v, "value" ) ~= nil then
            if toggles then toggles = format( "%s\n    %s = %s", toggles, k, tostring( v.value ) )
            else toggles = format( "%s = %s", k, tostring( v.value ) ) end
        end
    end

    return format( "构建: %s\n" ..
        "等级: %d (%d)\n" ..
        "职业: %s\n" ..
        "专精: %s\n\n" ..
        "天赋: %s\n\n" ..
        "pvp天赋: %s\n\n" ..
	"盟约: %s\n\n" ..
        "导灵器: %s\n\n" ..
        "灵魂羁绊: %s\n\n" ..
        "套装: %s\n\n" ..
        "装备: %s\n\n" ..
        "橙装: %s\n\n" ..
        "物品IDs: %s\n\n" ..
        "设置: %s\n\n" ..
        "切换: %s\n",
        Hekili.Version or "无信息",
        UnitLevel( 'player' ) or 0, UnitEffectiveLevel( 'player' ) or 0,
        class.file or "无",
        spec or "无",
        talents or "无",
        pvptalents or "无",
        covenant or "无",
        conduits or "无",
        soulbinds or "无",
        sets or "无",
        gear or "无",
        legendaries or "无",
        items or "无",
        settings or "无",
        toggles or "无" )
end


function Hekili:GetOptions()
    local Options = {
        name = "Hekili",
        type = "group",
        handler = Hekili,
        get = 'GetOption',
        set = 'SetOption',
        childGroups = "tree",
        args = {
            general = {
                type = "group",
                name = "常规",
                order = 10,
                childGroups = "tab",
                args = {
                    enabled = {
                        type = "toggle",
                        name = "启用",
                        desc = "启用或禁用插件.",
                        order = 1
                    },

                    minimapIcon = {
                        type = "toggle",
                        name = "隐藏迷你地图图标",
                        desc = "如果勾选, 最小化地图图标将被隐藏.",
                        order = 2,
                    },

                    welcome = {
                        type = 'description',
                        name = "",
                        fontSize = "medium",
                        image = "Interface\\Addons\\Hekili\\Textures\\Taco256",
                        imageWidth = 192,
                        imageHeight = 192,
                        order = 5,
                        width = "full"
                    },

                    supporters = {
                        type = "description",
                        name = function ()
                            return "|cFF00CCFF感谢我们的支持者!|r\n\n" .. ns.Patrons .. ".\n\n" ..
                                "请参阅 |cFFFFD100问题报告|r标签了解有关报告bug的信息.\n\n"
                        end,
                        fontSize = "medium",
                        order = 6,
                        width = "full"
                    },

                    curse = {
                        type = "input",
                        name = "Curse",
                        order = 10,
                        get = function () return "https://www.curseforge.com/wow/addons/hekili" end,
                        set = function () end,
                        width = "full",
                        dialogControl = "SFX-Info-URL",
                    },

                    github = {
                        type = "input",
                        name = "GitHub",
                        order = 11,
                        get = function () return "https://github.com/Hekili/hekili/" end,
                        set = function () end,
                        width = "full",
                        width = "full",
                        dialogControl = "SFX-Info-URL",
                    },

                    simulationcraft = {
                        type = "input",
                        name = "SimC",
                        order = 12,
                        get = function () return "https://github.com/simulationcraft/simc/wiki" end,
                        set = function () end,
                        width = "full",
                        dialogControl = "SFX-Info-URL",
                    }
                }
            },

            abilities = {
                type = "group",
                name = "技能",
                order = 80,
                childGroups = "select",
                args = {
                    spec = {
                        type = "select",
                        name = "专精",
                        desc = "这些选项适用于选择专精.",
                        order = 0.1,
                        width = "full",
                        set = SetCurrentSpec,
                        get = GetCurrentSpec,
                        values = GetCurrentSpecList,
                    },                
                },
                plugins = {
                    actions = {}
                }
            },

            items = {
                type = "group",
                name = "装备和饰品",
                order = 81,
                childGroups = "select",
                args = {
                    spec = {
                        type = "select",
                        name = "专精",
                        desc = "这些选项适用于选择专精.",
                        order = 0.1,
                        width = "full",
                        set = SetCurrentSpec,
                        get = GetCurrentSpec,
                        values = GetCurrentSpecList,
                    },    
                },
                plugins = {
                    equipment = {}
                }
            },

            issues = {
                type = "group",
                name = "问题报告",
                order = 85,
                args = {
                    header = {
                        type = "description",
                        name = "如果在使用该插件时遇到技术问题, 请通过下面的链接提交问题报告. " ..
                            "提交报告时请包括以下信息(专精, 天赋, 特质, 装备), 为方便起见可以复制和粘贴这些信息. " ..
                            "如果对插件的建议有疑问, 最好提供一个快照(其中包括这些信息).",
                        order = 10,
                        fontSize = "medium",
                        width = "full",
                    },
                    profile = {
                        type = "input",
                        name = "角色数据",
                        order = 20,
                        width = "full",
                        multiline = 10,
                        get = 'GenerateProfile',
                        set = function () end,
                    },
                    link = {
                        type = "input",
                        name = "链接",
                        order = 30,
                        width = "full",
                        get = function() return "http://github.com/Hekili/hekili/issues" end,
                        set = function() return end,
                        dialogControl = "SFX-Info-URL"
                    },
                }
            },

            snapshots = {
                type = "group",
                name = "快照",
                order = 86,
                args = {
                    autoSnapshot = {
                        type = "toggle",
                        name = "无法进行推荐时自动快照",
                        desc = "如果勾选, 每当它无法生成推荐时插件将自动创建一个快照.\n\n" ..
                            "这个自动快照每场战斗只能发生一次.",
                        order = 1,
                        width = "full"
                    },

                    prefHeader = {
                        type = "header",
                        name = "快照/故障排除",
                        order = 2,
                        width = "full"
                    },

                    header = {
                        type = "description",
                        name = function()
                            return "快照是插件的决策过程日志其中包含一组建议. " ..
                            "如果对插件的建议有疑问或不同意, 回顾一下快照可以帮助确定是什么因素导致看到的具体建议.\n\n" ..                            
                            "快照仅捕获特定的时间点, 因此必须在看到关注的特定建议时进行快照. 你可以生成" ..
                            "快照, 通过使用 |cffffd100快照|r 绑定 ( |cffffd100" .. ( Hekili.DB.profile.toggles.snapshot.key or "未绑定" ) .. "|r )从切换部分.\n\n" ..
                            "还可以使用以下命令冻结插件的建议|cffffd100暂停|r 绑定 ( |cffffd100" .. ( Hekili.DB.profile.toggles.pause.key or "未绑定" ) .. "|r ). 这样做会冻结插件的建议, 让你将鼠标移到显示上查看满足了哪些条件才能显示这些建议. " ..
                            "再按一次暂停以解冻插件.\n\n" ..
                            "最后, 使用此面板底部的设置, 可以要求插件在无法提出建议时自动生成快照.\n"
                        end,
                        fontSize = "medium",
                        order = 10,
                        width = "full",
                    },

                    Display = {
                        type = "select",
                        name = "显示",
                        desc = "选择要显示(如果已拍摄任何快照).",
                        order = 11,
                        values = function( info )
                            local displays = snapshots.displays

                            for k in pairs( ns.snapshots ) do
                                displays[k] = k
                            end

                            return displays
                        end,
                        set = function( info, val )
                            snapshots.display = val
                        end,
                        get = function( info )
                            return snapshots.display
                        end,
                        width = 2.6
                    },

                    SnapID = {
                        type = "select",
                        name = "#",
                        desc = "选择要显示(如果已拍摄任何快照).",
                        order = 12,
                        values = function( info )
                            for k, v in pairs( ns.snapshots ) do
                                snapshots.snaps[ k ] = snapshots.snaps[ k ] or {}

                                for idx in pairs( v ) do
                                    snapshots.snaps[ k ][ idx ] = idx
                                end
                            end

                            return snapshots.display and snapshots.snaps[ snapshots.display ] or snapshots.empty
                        end,
                        set = function( info, val )
                            snapshots.snap[ snapshots.display ] = val
                        end,
                        get = function( info )
                            return snapshots.snap[ snapshots.display ]
                        end,
                        width = 0.7
                    },
                    
                    Snapshot = {
                        type = 'input',
                        name = "日志",
                        desc = "任何可用的调试信息都可以在这里找到.",
                        order = 13,
                        get = function( info )
                            local display = snapshots.display
                            local snap = display and snapshots.snap[ display ]

                            return snap and ( "点击这里, 按CTRL+A, CTRL+C复制快照.\n\n" .. ns.snapshots[ display ][ snap ] )
                        end,
                        set = function() end,
                        width = "full"
                    },
                }
            },
        },

        plugins = {
            specializations = {},
        }
    }

    self:EmbedToggleOptions( Options )

    self:EmbedDisplayOptions( Options )

    self:EmbedPackOptions( Options )

    self:EmbedAbilityOptions( Options )

    self:EmbedItemOptions( Options )

    self:EmbedSpecOptions( Options )

    self:EmbedSkeletonOptions( Options )

    self:EmbedErrorOptions( Options )

    return Options
end


function Hekili:TotalRefresh( noOptions )

    if Hekili.PLAYER_ENTERING_WORLD then
        self:SpecializationChanged()
        self:RestoreDefaults()
    end

    for i, queue in pairs( ns.queue ) do
        for j, _ in pairs( queue ) do
            ns.queue[ i ][ j ] = nil
        end
        ns.queue[ i ] = nil
    end

    callHook( "onInitialize" )

    self:RunOneTimeFixes()
    ns.checkImports()

    -- self:LoadScripts()
    if not noOptions then self:RefreshOptions() end
    self:UpdateDisplayVisibility()
    self:BuildUI()

    self:OverrideBinds()

    -- LibStub("LibDBIcon-1.0"):Refresh( "Hekili", self.DB.profile.iconStore )
    
    if WeakAuras and WeakAuras.ScanEvents then
        for name in pairs( Hekili.DB.profile.toggles ) do
            WeakAuras.ScanEvents( "HEKILI_TOGGLE" )
        end
    end

end


function Hekili:RefreshOptions()
    if not self.Options then return end

    -- db.args.abilities = ns.AbilitySettings()

    self:EmbedDisplayOptions()
    self:EmbedPackOptions()
    self:EmbedSpecOptions()
    self:EmbedAbilityOptions()
    self:EmbedItemOptions()

    -- Until I feel like making this better at managing memory.
    collectgarbage()
end


function Hekili:GetOption( info, input )
    local category, depth, option = info[1], #info, info[#info]
    local profile = Hekili.DB.profile

    if category == 'general' then
        return profile[ option ]

    elseif category == 'bindings' then

        if option:match( "TOGGLE" ) or option == "HEKILI_SNAPSHOT" then
            return select( 1, GetBindingKey( option ) )

        elseif option == 'Pause' then
            return self.Pause

        else
            return profile[ option ]

        end

    elseif category == 'displays' then

        -- This is a generic display option/function.
        if depth == 2 then
            return nil

            -- This is a display (or a hook).
        else
            local dispKey, dispID = info[2], tonumber( match( info[2], "^D(%d+)" ) )
            local hookKey, hookID = info[3], tonumber( match( info[3] or "", "^P(%d+)" ) )
            local display = profile.displays[ dispID ]

            -- This is a specific display's settings.
            if depth == 3 or not hookID then

                if option == 'x' or option == 'y' then
                    return tostring( display[ option ] )

                elseif option == 'spellFlashColor' or option == 'iconBorderColor' then
                    if type( display[option] ) ~= 'table' then display[option] = { r = 1, g = 1, b = 1, a = 1 } end
                    return display[option].r, display[option].g, display[option].b, display[option].a

                elseif option == 'Copy To' or option == 'Import' then
                    return nil

                else
                    return display[ option ]

                end

                -- This is a priority hook.
            else
                local hook = display.Queues[ hookID ]

                if option == 'Move' then
                    return hookID

                else
                    return hook[ option ]

                end

            end

        end

    elseif category == 'actionLists' then

        -- This is a general action list option.
        if depth == 2 then
            return nil

        else
            local listKey, listID = info[2], tonumber( match( info[2], "^L(%d+)" ) )
            local actKey, actID = info[3], tonumber( match( info[3], "^A(%d+)" ) )
            local list = listID and profile.actionLists[ listID ]

            -- This is a specific action list.
            if depth == 3 or not actID then
                return list[ option ]

                -- This is a specific action.
            elseif listID and actID then
                local action = list.Actions[ actID ]

                if option == 'ConsumableArgs' then option = 'Args' end

                if option == 'Move' then
                    return actID

                else
                    return action[ option ]

                end

            end

        end

    elseif category == "snapshots" then
        return profile[ option ]
    end

    ns.Error( "GetOption() - should never see." )

end


local getUniqueName = function( category, name )
    local numChecked, suffix, original = 0, 1, name

    while numChecked < #category do
        for i, instance in ipairs( category ) do
            if name == instance.Name then
                name = original .. ' (' .. suffix .. ')'
                suffix = suffix + 1
                numChecked = 0
            else
                numChecked = numChecked + 1
            end
        end
    end

    return name
end


function Hekili:SetOption( info, input, ... )
    local category, depth, option, subcategory = info[1], #info, info[#info], nil
    local Rebuild, RebuildUI, RebuildScripts, RebuildOptions, RebuildCache, Select
    local profile = Hekili.DB.profile

    if category == 'general' then
        -- We'll preset the option here; works for most options.
        profile[ option ] = input

        if option == 'enabled' then
            for i, buttons in ipairs( ns.UI.Buttons ) do
                for j, _ in ipairs( buttons ) do
                    if input == false then
                        buttons[j]:Hide()
                    else
                        buttons[j]:Show()
                    end
                end
            end

            if input == true then self:Enable()
            else self:Disable() end

            return

        elseif option == 'minimapIcon' then
            profile.iconStore.hide = input

            if LDBIcon then
                if input then
                    LDBIcon:Hide( "Hekili" )
                else
                    LDBIcon:Show( "Hekili" )
                end
            end

        elseif option == 'Audit Targets' then
            return

        end

        -- General options do not need add'l handling.
        return

    elseif category == 'bindings' then

        local revert = profile[ option ]
        profile[ option ] = input

        if option:match( "TOGGLE" ) or option == "HEKILI_SNAPSHOT" then
            if GetBindingKey( option ) then
                SetBinding( GetBindingKey( option ) )
            end
            SetBinding( input, option )
            SaveBindings( GetCurrentBindingSet() )

        elseif option == 'Mode' then
            profile[option] = revert
            self:ToggleMode()

        elseif option == 'Pause' then
            profile[option] = revert
            self:TogglePause()
            return

        elseif option == 'Cooldowns' then
            profile[option] = revert
            self:ToggleCooldowns()
            return

        elseif option == 'Artifact' then
            profile[option] = revert
            self:ToggleArtifact()
            return

        elseif option == 'Potions' then
            profile[option] = revert
            self:TogglePotions()
            return

        elseif option == 'Hardcasts' then
            profile[option] = revert
            self:ToggleHardcasts()
            return

        elseif option == 'Interrupts' then
            profile[option] = revert
            self:ToggleInterrupts()
            return

        elseif option == 'Switch Type' then
            if input == 0 then
                if profile['Mode Status'] == 1 or profile['Mode Status'] == 2 then
                    -- Check that the current mode is supported.
                    profile['Mode Status'] = 0
                    self:Print("开关类型更新; 恢复到单目标状态.")
                end
            elseif input == 1 then
                if profile['Mode Status'] == 1 or profile['Mode Status'] == 3 then
                    profile['Mode Status'] = 0
                    self:Print("开关类型更新; 恢复到单目标状态.")
                end
            end

        elseif option == 'Mode Status' or option:match("Toggle_") or option == 'BloodlustCooldowns' or option == 'CooldownArtifact' then
            -- do nothing, we're good.

        else -- Toggle Names.
            if input:trim() == "" then
                profile[ option ] = nil
            end

        end

        -- Bindings do not need add'l handling.
        return

  

    elseif category == 'actionLists' then

        if depth == 2 then

            if option == 'New Action List' then
                local key = ns.newActionList( input )
                if key then
                    RebuildOptions, RebuildCache = true, true
                end

            elseif option == 'Import Action List' then
                local import = ns.deserializeActionList( input )

                if not import or type( import ) == 'string' then
                    Hekili:Print("无法从给定的输入字符串导入.")
                    return
                end

                import.Name = getUniqueName( profile.actionLists, import.Name )
                profile.actionLists[ #profile.actionLists + 1 ] = import
                Rebuild = true

            end

        else
            local listKey, listID = info[2], info[2] and tonumber( match( info[2], "^L(%d+)" ) )
            local actKey, actID = info[3], info[3] and tonumber( match( info[3], "^A(%d+)" ) )
            local list = profile.actionLists[ listID ]

            if depth == 3 or not actID then

                local revert = list[ option ]
                list[option] = input

                if option == 'Name' then
                    Hekili.Options.args.actionLists.args[ listKey ].name = input
                    if input ~= revert and list.Default then list.Default = false end

                elseif option == 'Enabled' or option == 'Specialization' then
                    RebuildCache = true

                elseif option == 'Script' then
                    list[ option ] = input:trim()
                    RebuildScripts = true

                    -- Import/Exports
                elseif option == 'Copy To' then
                    list[option] = nil

                    local index = #profile.actionLists + 1

                    profile.actionLists[ index ] = tableCopy( list )
                    profile.actionLists[ index ].Name = input
                    profile.actionLists[ index ].Default = false

                    Rebuild = true

                elseif option == 'Import Action List' then
                    list[option] = nil

                    local import = ns.deserializeActionList( input )

                    if not import or type( import ) == 'string' then
                        Hekili:Print("无法从给定的输入字符串导入.")
                        return
                    end

                    import.Name = list.Name
                    table.remove( profile.actionLists, listID )
                    table.insert( profile.actionLists, listID, import )
                    -- profile.actionLists[ listID ] = import
                    Rebuild = true

                elseif option == 'SimulationCraft' then
                    list[option] = nil

                    local import, warnings = self:ImportSimulationCraftActionList( input )

                    if warnings then
                        Hekili:Print( "|cFFFF0000警告:|r\n在输入操作列表期间注意到以下问题." )
                        for i = 1, #warnings do
                            Hekili:Print( warnings[i] )
                        end
                    end

                    if not import then
                        Hekili:Print( "没有成功导入任何操作." )
                        return
                    end

                    wipe( list.Actions )

                    for i, entry in ipairs( import ) do

                        local key = ns.newAction( listID, class.abilities[ entry.Ability ].name )

                        local action = list.Actions[ i ]

                        action.Ability = entry.Ability
                        action.Args = entry.Args

                        action.CycleTargets = entry.CycleTargets
                        action.MaximumTargets = entry.MaximumTargets
                        action.CheckMovement = entry.CheckMovement or false
                        action.Movement = entry.Movement
                        action.ModName = entry.ModName or ''
                        action.ModVarName = entry.ModVarName or ''

                        action.Indicator = 'none'

                        action.Script = entry.Script
                        action.Enabled = true
                    end

                    Rebuild = true

                end

                -- This is a specific action.
            else
                local list = profile.actionLists[ listID ]
                local action = list.Actions[ actID ]

                action[ option ] = input

                if option == 'Name' then
                    Hekili.Options.args.actionLists.args[ listKey ].args[ actKey ].name = '|cFFFFD100' .. actID .. '.|r ' .. input

                elseif option == 'Enabled' then
                    RebuildCache = true

                elseif option == 'Move' then
                    action[ option ] = nil
                    local placeholder = table.remove( list.Actions, actID )
                    table.insert( list.Actions, input, placeholder )
                    Rebuild, Select = true, 'A'..input

                elseif option == 'Script' or option == 'Args' then
                    input = input:trim()
                    RebuildScripts = true

                elseif option == 'ReadyTime' then
                    list[ option ] = input:trim()
                    RebuildScripts = true

                elseif option == 'ConsumableArgs' then
                    action[ option ] = nil
                    action.Args = input
                    RebuildScripts = true

                end

            end
        end
    elseif category == "snapshots" then
        profile[ option ] = input
    end

    if Rebuild then
        ns.refreshOptions()
        ns.loadScripts()
        Hekili:BuildUI()
    else
        if RebuildOptions then ns.refreshOptions() end
        if RebuildScripts then ns.loadScripts() end
        if RebuildCache and not RebuildUI then Hekili:UpdateDisplayVisibility() end
        if RebuildUI then Hekili:BuildUI() end
    end

    if ns.UI.Minimap then ns.UI.Minimap:RefreshDataText() end

    if Select then
        LibStub( "AceConfigDialog-3.0" ):SelectGroup( "Hekili", category, info[2], Select )
    end

end



do
    local validCommands = {
        makedefaults = true,
        import = true,
        skeleton = true,
        recover = true,
        
        profile = true,
        set = true,
        enable = true,
        disable = true
    }

    local info = {}


    function Hekili:CmdLine( input )
        if not input or input:trim() == "" or input:trim() == "makedefaults" or input:trim() == "import" or input:trim() == "skeleton" then
            if input:trim() == 'makedefaults' then
                Hekili.MakeDefaults = true

            elseif input:trim() == 'import' then
                Hekili.AllowSimCImports = true

            elseif input:trim() == 'skeleton' then
                self:StartListeningForSkeleton()
                self:Print( "插件现在将收集专精信息. 选择所有的天赋和使用所有的技能以获得最好的结果." )
                self:Print( "有关更多信息请参阅骨架选项卡. ")
                Hekili.Skeleton = ""
            end
            ns.StartConfiguration()
            return

        elseif input:trim() == "center" then                
            for i, v in ipairs( Hekili.DB.profile.displays ) do
                ns.UI.Buttons[i][1]:ClearAllPoints()
                ns.UI.Buttons[i][1]:SetPoint("CENTER", 0, (i-1) * 50 )
            end
            self:SaveCoordinates()
            return

        elseif input:trim() == "recover" then
            self.DB.profile.displays = {}
            self.DB.profile.actionLists = {}
            self:RestoreDefaults()
            -- ns.convertDisplays()
            self:BuildUI()
            self:Print("恢复默认显示和操作列表.")
            return
        
        end

        if input then
            input = input:trim()
            local args = {}

            for arg in string.gmatch( input, "%S+" ) do
                insert( args, lower( arg ) )
            end

            if args[1] == "set" then
                local spec = Hekili.DB.profile.specs[ state.spec.id ]
                local prefs = spec.settings
                local settings = class.specs[ state.spec.id ].settings

                local index

                if args[2] then
                    if args[2] == "target_swap" then
                        index = -1
                    elseif args[2] == "mode" then
                        index = -2
                    else
                        for i, setting in ipairs( settings ) do
                            if setting.name == args[2] then
                                index = i
                                break
                            end
                        end
                    end
                end

                if #args == 1 or not index then
                    -- No arguments, list options.
                    local output = "使用 |cFFFFD100/hekili set|r 通过聊天或宏调整你的专精选项.\n\n可选方案 " .. state.spec.name .. " 是:"

                    local hasToggle, hasNumber = true, false
                    local exToggle, exNumber

                    for i, setting in ipairs( settings ) do
                        if setting.info.type == "toggle" then
                            output = format( "%s\n - |cFFFFD100%s|r = |cFF00FF00%s|r (%s)", output, setting.name, prefs[ setting.name ] and "ON" or "OFF", setting.info.name )
                            exToggle = setting.name
                        elseif setting.info.type == "range" then
                            output = format( "%s\n - |cFFFFD100%s|r = |cFF00FF00%.2f|r, min: %.2f, max: %.2f (%s)", output, setting.name, prefs[ setting.name ], ( setting.info.min and format( "%.2f", setting.info.min ) or "N/A" ), ( setting.info.max and format( "%.2f", setting.info.max ) or "N/A" ), setting.info.name )
                            hasNumber = true
                            exNumber = setting.name
                        end
                    end

                    output = format( "%s\n - |cFFFFD100target_swap|r = |cFF00FF00%s|r (%s)", output, spec.cycle and "ON" or "OFF", "Recommend Target Swaps" )

                    output = format( "%s\n\n要控制你的显示模式 (当前 |cFF00FF00%s|r):\n - 切换模式:  |cFFFFD100/hek set mode|r\n - 设置模式 - |cFFFFD100/hek set mode aoe|r (or |cFFFFD100自动|r, |cFFFFD100单体|r, |cFFFFD100双目标|r, |cFFFFD100被动|r)", output, self.DB.profile.toggles.mode.value or "unknown" )


                    if not hasToggle and not hasNumber then
                        output = output .. "cFFFFD100<无>|r"
                    end

                    if hasToggle then
                        output = format( "%s\n\n要设置一个|cFFFFD100切换|r, 请使用以下命令:\n" ..
                            " - 开/关:  |cFFFFD100/hek set %s|r\n" ..
                            " - 设置为开:  |cFFFFD100/hek set %s on|r\n" ..
                            " - 设置为关:  |cFFFFD100/hek set %s off|r\n" ..
                            " - 重置为默认:  |cFFFFD100/hek set %s default|r", output, exToggle, exToggle, exToggle, exToggle )
                    end

                    if hasNumber then
                        output = format( "%s\n\n要设置一个|cFFFFD100数|r值, 请使用以下命令:\n" ..
                            " - 设置为 #:  |cFFFFD100/hek set %s #|r\n" ..
                            " - 重置为默认:  |cFFFFD100/hek set %s default|r", output, exNumber, exNumber )
                    end

                    Hekili:Print( output )
                    return
                end

                -- Two or more arguments, we're setting (or querying).

                if index == -1 then
                    local to

                    if args[3] then
                        if args[3] == "on" then to = true
                        elseif args[3] == "off" then to = false
                        elseif args[3] == "default" then to = false
                        else
                            Hekili:Print( format( "'%s' 不是一个有效的选项 |cFFFFD100%s|r.", args[3] ) )
                            return
                        end
                    else
                        to = not spec.cycle
                    end
                    
                    Hekili:Print( format( "建议目标替换设置为 %s.", ( to and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r" ) ) )

                    spec.cycle = to

                    Hekili:ForceUpdate( "CLI_TOGGLE" )
                    return
                elseif index == -2 then
                    if args[3] then
                        Hekili:SetMode( args[3] )
                    else
                        Hekili:FireToggle( "mode" )
                    end
                    return
                end

                local setting = settings[ index ]

                if setting.info.type == "toggle" then
                    local to

                    if args[3] then
                        if args[3] == "on" then to = true
                        elseif args[3] == "off" then to = false
                        elseif args[3] == "default" then to = setting.default
                        else
                            Hekili:Print( format( "'%s' 不是一个有效的选项 |cFFFFD100%s|r.", args[3] ) )
                            return
                        end
                    else
                        to = not prefs[ setting.name ]
                    end
                    
                    Hekili:Print( format( "%s 设置为 %s.", setting.info.name, ( to and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r" ) ) )

                    info[ 1 ] = setting.name
                    setting.info.set( info, to )

                    Hekili:ForceUpdate( "CLI_TOGGLE" )
                    return

                elseif setting.info.type == "range" then
                    local to

                    if args[3] == "default" then
                        to = setting.default
                    else
                        to = tonumber( args[3] )
                    end

                    if to and ( ( setting.info.min and to < setting.info.min ) or ( setting.info.max and to > setting.info.max ) ) then
                        Hekili:Print( format( "%s的值必须在%s和%s之间.", args[2], ( setting.info.min and format( "%.2f", setting.info.min ) or "N/A" ), ( setting.info.max and format( "%.2f", setting.info.max ) or "N/A" ) ) )
                        return
                    end

                    if not to then
                        Hekili:Print( format( "你必须为%s提供一个数字值 (或默认值).", args[2] ) )
                        return
                    end

                    Hekili:Print( format( "%s 设置为 |cFF00B4FF%.2f|r.", setting.info.name, to ) )
                    prefs[ setting.name ] = to
                    Hekili:ForceUpdate( "CLI_NUMBER" )
                    return

                end

            
            elseif args[1] == "profile" then
                if not args[2] then
                    local output = "使用 |cFFFFD100/hekili profile name|r通过命令行或宏来调换配置文件.\n有效配置 |cFFFFD100名|r是:"

                    for name, prof in ns.orderedPairs( Hekili.DB.profiles ) do
                        output = format( "%s\n - |cFFFFD100%s|r %s", output, name, Hekili.DB.profile == prof and "|cFF00FF00(current)|r" or "" )
                    end

                    output = format( "%s\n创建一个新的配置文件, 见 |cFFFFD100/hekili|r > |cFFFFD100Profiles|r.", output )

                    Hekili:Print( output )
                    return
                end

                local profileName = input:match( "%s+(.+)$" )

                if not rawget( Hekili.DB.profiles, profileName ) then
                    local output = format( "'%s' 不是有效的配置文件名称.\n有效配置 |cFFFFD100名|r是:", profileName )

                    local count = 0

                    for name, prof in ns.orderedPairs( Hekili.DB.profiles ) do
                        count = count + 1
                        output = format( "%s\n - |cFFFFD100%s|r %s", output, name, Hekili.DB.profile == prof and "|cFF00FF00(current)|r" or "" )
                    end

                    output = format( "%s\n创建一个新的配置文件, 见 |cFFFFD100/hekili|r > |cFFFFD100Profiles|r.", output )

                    Hekili:Print( output )
                    return
                end

                Hekili:Print( format( "将配置文件设置为 |cFF00FF00%s|r.", profileName ) )
                self.DB:SetProfile( profileName )
                return

            elseif args[1] == "enable" or args[1] == "disable" then
                local enable = args[1] == "enable"

                for i, buttons in ipairs( ns.UI.Buttons ) do
                    for j, _ in ipairs( buttons ) do
                        if not enable then
                            buttons[j]:Hide()
                        else
                            buttons[j]:Show()
                        end
                    end
                end

                self.DB.profile.enabled = enable
    
                if enable then
                    Hekili:Print( "插件 |cFFFFD100启用|r." )
                    self:Enable()
                else
                    Hekili:Print( "插件 |cFFFFD100禁用|r." )
                    self:Disable()
                end

            else
                LibStub( "AceConfigCmd-3.0" ):HandleCommand( "hekili", "Hekili", input )
            end
        end
    end
end


-- Import/Export
-- Nicer string encoding from WeakAuras, thanks to Stanzilla.

local bit_band, bit_lshift, bit_rshift = bit.band, bit.lshift, bit.rshift
local string_char = string.char

local bytetoB64 = {
    [0]="a","b","c","d","e","f","g","h",
    "i","j","k","l","m","n","o","p",
    "q","r","s","t","u","v","w","x",
    "y","z","A","B","C","D","E","F",
    "G","H","I","J","K","L","M","N",
    "O","P","Q","R","S","T","U","V",
    "W","X","Y","Z","0","1","2","3",
    "4","5","6","7","8","9","(",")"
}

local B64tobyte = {
    a = 0, b = 1, c = 2, d = 3, e = 4, f = 5, g = 6, h = 7,
    i = 8, j = 9, k = 10, l = 11, m = 12, n = 13, o = 14, p = 15,
    q = 16, r = 17, s = 18, t = 19, u = 20, v = 21, w = 22, x = 23,
    y = 24, z = 25, A = 26, B = 27, C = 28, D = 29, E = 30, F = 31,
    G = 32, H = 33, I = 34, J = 35, K = 36, L = 37, M = 38, N = 39,
    O = 40, P = 41, Q = 42, R = 43, S = 44, T = 45, U = 46, V = 47,
    W = 48, X = 49, Y = 50, Z = 51,["0"]=52,["1"]=53,["2"]=54,["3"]=55,
    ["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["("]=62,[")"]=63
}

-- This code is based on the Encode7Bit algorithm from LibCompress
-- Credit goes to Galmok (galmok@gmail.com)
local encodeB64Table = {};

local function encodeB64(str)
    local B64 = encodeB64Table;
    local remainder = 0;
    local remainder_length = 0;
    local encoded_size = 0;
    local l=#str
    local code
    for i=1,l do
        code = string.byte(str, i);
        remainder = remainder + bit_lshift(code, remainder_length);
        remainder_length = remainder_length + 8;
        while(remainder_length) >= 6 do
            encoded_size = encoded_size + 1;
            B64[encoded_size] = bytetoB64[bit_band(remainder, 63)];
            remainder = bit_rshift(remainder, 6);
            remainder_length = remainder_length - 6;
        end
    end
    if remainder_length > 0 then
        encoded_size = encoded_size + 1;
        B64[encoded_size] = bytetoB64[remainder];
    end
    return table.concat(B64, "", 1, encoded_size)
end

local decodeB64Table = {}

local function decodeB64(str)
    local bit8 = decodeB64Table;
    local decoded_size = 0;
    local ch;
    local i = 1;
    local bitfield_len = 0;
    local bitfield = 0;
    local l = #str;
    while true do
        if bitfield_len >= 8 then
            decoded_size = decoded_size + 1;
            bit8[decoded_size] = string_char(bit_band(bitfield, 255));
            bitfield = bit_rshift(bitfield, 8);
            bitfield_len = bitfield_len - 8;
        end
        ch = B64tobyte[str:sub(i, i)];
        bitfield = bitfield + bit_lshift(ch or 0, bitfield_len);
        bitfield_len = bitfield_len + 6;
        if i > l then
            break;
        end
        i = i + 1;
    end
    return table.concat(bit8, "", 1, decoded_size)
end

local Compresser = LibStub:GetLibrary("LibCompress");
local Encoder = Compresser:GetChatEncodeTable()
local Serializer = LibStub:GetLibrary("AceSerializer-3.0");


local function TableToString(inTable, forChat)
    local serialized = Serializer:Serialize(inTable);
    local compressed = Compresser:CompressHuffman(serialized);
    if(forChat) then
        return encodeB64(compressed);
    else
        return Encoder:Encode(compressed);
    end
end


local function StringToTable(inString, fromChat)
    local decoded;
    if(fromChat) then
        decoded = decodeB64(inString);
    else
        decoded = Encoder:Decode(inString);
    end
    local decompressed, errorMsg = Compresser:Decompress(decoded);
    if not(decompressed) then
        return "解压时出错: "..errorMsg;
    end
    local success, deserialized = Serializer:Deserialize(decompressed);
    if not(success) then
        return "解压出错 "..deserialized;
    end
    return deserialized;
end


function ns.serializeDisplay( display )
    if not Hekili.DB.profile.displays[ display ] then return nil end
    local serial = tableCopy( Hekili.DB.profile.displays[ display ] )

    -- Change actionlist IDs to actionlist names so we can validate later.
    if serial.precombatAPL ~= 0 then serial.precombatAPL = Hekili.DB.profile.actionLists[ serial.precombatAPL ].Name end
    if serial.defaultAPL ~= 0 then serial.defaultAPL = Hekili.DB.profile.actionLists[ serial.defaultAPL ].Name end

    return TableToString( serial, true )
end

Hekili.SerializeDisplay = ns.serializeDisplay


function ns.deserializeDisplay( str )
    local display = StringToTable( str, true )

    if type( display.precombatAPL ) == 'string' then
        for i, list in ipairs( Hekili.DB.profile.actionLists ) do
            if display.precombatAPL == list.Name then
                display.precombatAPL = i
                break
            end
        end

        if type( display.precombatAPL ) == 'string' then
            display.precombatAPL = 0
        end
    end

    if type( display.defaultAPL ) == 'string' then
        for i, list in ipairs( Hekili.DB.profile.actionLists ) do
            if display.defaultAPL == list.Name then
                display.defaultAPL = i
                break
            end
        end

        if type( display.defaultAPL ) == 'string' then
            display.defaultAPL = 0
        end
    end

    return display
end

Hekili.DeserializeDisplay = ns.deserializeDisplay


function Hekili:SerializeActionPack( name )
    local pack = rawget( self.DB.profile.packs, name )
    if not pack then return end

    local serial = {
        type = "package",
        name = name,
        date = tonumber( date("%Y%m%d.%H%M%S") ),
        payload = tableCopy( pack )
    }

    serial.payload.builtIn = false

    return TableToString( serial, true )
end


function Hekili:DeserializeActionPack( str )
    local serial = StringToTable( str, true )

    if not serial or type( serial ) == "string" or serial.type ~= "package" then
        return serial or "无法从提供的字符串中恢复优先级."
    end

    serial.payload.builtIn = false

    return serial
end


function Hekili:SerializeStyle( ... )
    local serial = {
        type = "style",
        date = tonumber( date("%Y%m%d.%H%M%S") ),
        payload = {}
    }

    local hasPayload = false

    for i = 1, select( "#", ... ) do
        local dispName = select( i, ... )
        local display = rawget( self.DB.profile.displays, dispName )

        if not display then return "试图将无效的显示序列化 (" .. dispName .. ")" end

        serial.payload[ dispName ] = tableCopy( display )
        hasPayload = true
    end

    if not hasPayload then return "没有选择要导出的显示." end
    return TableToString( serial, true )
end


function Hekili:DeserializeStyle( str )
    local serial = StringToTable( str, true )

    if not serial or type( serial ) == 'string' or not serial.type == "style" then
        return nil, serial
    end

    return serial.payload
end


function ns.serializeActionList( num ) 
    if not Hekili.DB.profile.actionLists[ num ] then return nil end
    local serial = tableCopy( Hekili.DB.profile.actionLists[ num ] )
    return TableToString( serial, true )
end


function ns.deserializeActionList( str )
    return StringToTable( str, true )
end



local ignore_actions = {
    -- call_action_list = 1,
    -- run_action_list = 1,
    snapshot_stats = 1,
    -- auto_attack = 1,
    -- use_item = 1,
    flask = 1,
    food = 1,
    augmentation = 1
}


local function make_substitutions( i, swaps, prefixes, postfixes ) 
    if not i then return nil end

    for k,v in pairs( swaps ) do

        for token in i:gmatch( k ) do

            local times = 0
            while (i:find(token)) do
                local strpos, strend = i:find(token)

                local pre = i:sub( strpos - 1, strpos - 1 )
                local j = 2

                while ( pre == '(' and strpos - j > 0 ) do
                    pre = i:sub( strpos - j, strpos - j )
                    j = j + 1
                end

                local post = i:sub( strend + 1, strend + 1 )
                j = 2

                while ( post == ')' and strend + j < i:len() ) do
                    post = i:sub( strend + j, strend + j )
                    j = j + 1
                end

                local start = strpos > 1 and i:sub( 1, strpos - 1 ) or ''
                local finish = strend < i:len() and i:sub( strend + 1 ) or ''

                if not ( prefixes and prefixes[ pre ] ) and pre ~= '.' and pre ~= '_' and not pre:match('%a') and not ( postfixes and postfixes[ post ] ) and post ~= '.' and post ~= '_' and not post:match('%a') then
                    i = start .. '\a' .. finish
                else
                    i = start .. '\v' .. finish
                end

            end

            i = i:gsub( '\v', token )
            i = i:gsub( '\a', v )

        end

    end

    return i

end


local function accommodate_targets( targets, ability, i, line, warnings )
    local insert_targets = targets
    local insert_ability = ability

    if ability == 'storm_earth_and_fire' then
        insert_targets = type( targets ) == 'number' and min( 2, ( targets - 1 ) ) or 2
        insert_ability = 'storm_earth_and_fire_target'
    elseif ability == 'windstrike' then
        insert_ability = 'stormstrike'
    end

    local swaps = {}

    swaps["d?e?buff%."..insert_ability.."%.up"] = "active_dot."..insert_ability.. ">=" ..insert_targets
    swaps["d?e?buff%."..insert_ability.."%.down"] = "active_dot."..insert_ability.. "<" ..insert_targets
    swaps["dot%."..insert_ability.."%.up"] = "active_dot."..insert_ability..'>=' ..insert_targets
    swaps["dot%."..insert_ability.."%.ticking"] = "active_dot."..insert_ability..'>=' ..insert_targets
    swaps["dot%."..insert_ability.."%.down"] = "active_dot."..insert_ability..'<' ..insert_targets
    swaps["up"] = "active_dot."..insert_ability..">=" ..insert_targets
    swaps["ticking"] = "active_dot."..insert_ability..">=" ..insert_targets
    swaps["down"] = "active_dot."..insert_ability.."<" ..insert_targets 

    return make_substitutions( i, swaps )
end
ns.accomm = accommodate_targets


local function Sanitize( segment, i, line, warnings )
    if i == nil then return end

    local operators = {
        [">"] = true,
        ["<"] = true,
        ["="] = true,
        ["~"] = true,
        ["+"] = true,
        ["-"] = true,
        ["%%"] = true,
        ["*"] = true
    }

    local maths = {
        ['+'] = true,
        ['-'] = true,
        ['*'] = true,
        ['%%'] = true
    }

    for token in i:gmatch( "stealthed" ) do
        while( i:find(token) ) do
            local strpos, strend = i:find(token)

            local pre = strpos > 1 and i:sub( strpos - 1, strpos - 1 ) or ''
            local post = strend < i:len() and i:sub( strend + 1, strend + 1 ) or ''
            local start = strpos > 1 and i:sub( 1, strpos - 1 ) or ''
            local finish = strend < i:len() and i:sub( strend + 1 ) or ''

            if pre ~= '.' and pre ~= '_' and not pre:match('%a') and post ~= '.' and post ~= '_' and not post:match('%a') then
                i = start .. '\a' .. finish
            else
                i = start .. '\v' .. finish
            end

        end

        i = i:gsub( '\v', token )
        i = i:gsub( '\a', token..'.rogue' )
    end

    for token in i:gmatch( "cooldown" ) do
        while( i:find(token) ) do
            local strpos, strend = i:find(token)

            local pre = strpos > 1 and i:sub( strpos - 1, strpos - 1 ) or ''
            local post = strend < i:len() and i:sub( strend + 1, strend + 1 ) or ''
            local start = strpos > 1 and i:sub( 1, strpos - 1 ) or ''
            local finish = strend < i:len() and i:sub( strend + 1 ) or ''

            if pre ~= '.' and pre ~= '_' and not pre:match('%a') and post ~= '.' and post ~= '_' and not post:match('%a') then
                i = start .. '\a' .. finish
            else
                i = start .. '\v' .. finish
            end
        end

        i = i:gsub( '\v', token )
        i = i:gsub( '\a', 'action_cooldown' )
    end

    for token in i:gmatch( "equipped%.[0-9]+" ) do
        local itemID = tonumber( token:match( "([0-9]+)" ) )
        local itemName = GetItemInfo( itemID )
        local itemKey = formatKey( itemName )

        if itemKey and itemKey ~= '' then
            i = i:gsub( tostring( itemID ), itemKey )
        end

    end   

    local times = 0

    i, times = i:gsub( "==", "=" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Corrected equality check from '==' to '=' (" .. times .. "x)." )
    end

    i, times = i:gsub( "([^%%])[ ]*%%[ ]*([^%%])", "%1 / %2" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted SimC syntax % to Lua division operator (/) (" .. times .. "x)." )
    end
    
    i, times = i:gsub( "%%%%", "%%" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted SimC syntax %% to Lua modulus operator (%) (" .. times .. "x)." )
    end

    i, times = i:gsub( "covenant%.([%w_]+)%.enabled", "covenant.%1" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'covenant.X.enabled' to 'covenant.X' (" .. times .. "x)." )
    end

    i, times = i:gsub( "talent%.([%w_]+)([%+%-%*%%/&|= ()<>])", "talent.%1.enabled%2" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'talent.X' to 'talent.X.enabled' (" .. times .. "x)." )
    end

    i, times = i:gsub( "talent%.([%w_]+)$", "talent.%1.enabled" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'talent.X' to 'talent.X.enabled' at EOL (" .. times .. "x)." )
    end

    i, times = i:gsub( "legendary%.([%w_]+)([%+%-%*%%/&|= ()<>])", "legendary.%1.enabled%2" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'legendary.X' to 'legendary.X.enabled' (" .. times .. "x)." )
    end

    i, times = i:gsub( "legendary%.([%w_]+)$", "legendary.%1.enabled" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'legendary.X' to 'legendary.X.enabled' at EOL (" .. times .. "x)." )
    end

    i, times = i:gsub( "([^%.])runeforge%.([%w_]+)([%+%-%*%%/=&| ()<>])", "%1runeforge.%2.enabled%3" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'runeforge.X' to 'runeforge.X.enabled' (" .. times .. "x)." )
    end

    i, times = i:gsub( "([^%.])runeforge%.([%w_]+)$", "%1runeforge.%2.enabled" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'runeforge.X' to 'runeforge.X.enabled' at EOL (" .. times .. "x)." )
    end

    i, times = i:gsub( "^runeforge%.([%w_]+)([%+%-%*%%/&|= ()<>)])", "runeforge.%1.enabled%2" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'runeforge.X' to 'runeforge.X.enabled' (" .. times .. "x)." )
    end

    i, times = i:gsub( "^runeforge%.([%w_]+)$", "runeforge.%1.enabled" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'runeforge.X' to 'runeforge.X.enabled' at EOL (" .. times .. "x)." )
    end

    i, times = i:gsub( "conduit%.([%w_]+)([%+%-%*%%/&|= ()<>)])", "conduit.%1.enabled%2" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'conduit.X' to 'conduit.X.enabled' (" .. times .. "x)." )
    end

    i, times = i:gsub( "conduit%.([%w_]+)$", "conduit.%1.enabled" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'conduit.X' to 'conduit.X.enabled' at EOL (" .. times .. "x)." )
    end

    i, times = i:gsub( "soulbind%.([%w_]+)([%+%-%*%%/&|= ()<>)])", "soulbind.%1.enabled%2" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'soulbind.X' to 'soulbind.X.enabled' (" .. times .. "x)." )
    end

    i, times = i:gsub( "soulbind%.([%w_]+)$", "soulbind.%1.enabled" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'soulbind.X' to 'soulbind.X.enabled' at EOL (" .. times .. "x)." )
    end

    i, times = i:gsub( "pet%.[%w_]+%.([%w_]+)%.", "%1." )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'pet.X.Y...' to 'Y...' (" .. times .. "x)." )
    end

    i, times = i:gsub( "(essence%.[%w_]+)%.([%w_]+)%.rank(%d)", "(%1.%2&%1.rank>=%3)" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'essence.X.[major|minor].rank#' to '(essence.X.[major|minor]&essence.X.rank>=#)' (" .. times .. "x)." )
    end

    i, times = i:gsub( "pet%.[%w_]+%.[%w_]+%.([%w_]+)%.", "%1." )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'pet.X.Y.Z...' to 'Z...' (" .. times .. "x)." )
    end

    -- target.1.time_to_die is basically the end of an encounter.
    i, times = i:gsub( "target%.1%.time_to_die", "time_to_die" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'target.1.time_to_die' to 'time_to_die' (" .. times .."x)." )
    end

    -- target.time_to_pct_XX.remains is redundant, Monks.
    i, times = i:gsub( "time_to_pct_(%d+)%.remains", "time_to_pct_%1" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'time_to_pct_XX.remains' to 'time_to_pct_XX' (" .. times .. "x)." )
    end

    i, times = i:gsub( "trinket%.1%.", "trinket.t1." )
    if times > 0 then        
        table.insert( warnings, "Line " .. line .. ": Converted 'trinket.1.X' to 'trinket.t1.X' (" .. times .. "x)." )        
    end

    i, times = i:gsub( "trinket%.2%.", "trinket.t2." )
    if times > 0 then        
        table.insert( warnings, "Line " .. line .. ": Converted 'trinket.2.X' to 'trinket.t2.X' (" .. times .. "x)." )        
    end

    i, times = i:gsub( "trinket%.([%w_][%w_][%w_]+)%.cooldown", "cooldown.%1" )
    if times > 0 then        
        table.insert( warnings, "Line " .. line .. ": Converted 'trinket.abc.cooldown' to 'cooldown.abc' (" .. times .. "x)." )        
    end

    i, times = i:gsub( "min:[a-z0-9_%.]+(,?$?)", "%1" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Removed min:X check (not available in emulation) (" .. times .. "x)." )
    end

    i, times = i:gsub( "([%|%&]position_back)", "" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Removed position_back check (not available in emulation) (" .. times .. "x)." )
    end

    i, times = i:gsub( "(position_back[%|%&]?)", "" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Removed position_back check (not available in emulation) (" .. times .. "x)." )
    end

    i, times = i:gsub( "max:[a-z0-9_%.]+(,?$?)", "%1" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Removed max:X check (not available in emulation) (" .. times .. "x)." )
    end

    i, times = i:gsub( "(incanters_flow_time_to%.%d+)(^%.)", "%1.any%2")
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted directionless 'incanters_flow_time_to.X' to 'incanters_flow_time_to.X.any' (" .. times .. "x)." )
    end

    i, times = i:gsub( "exsanguinated%.([a-z0-9_]+)", "debuff.%1.exsanguinated" )
    if times > 0 then
        table.insert( warnings, "Line " .. line .. ": Converted 'exsanguinated.X' to 'debuff.X.exsanguinated' (" .. times .. "x).") 
    end

    if segment == 'c' then
        for token in i:gmatch( "target" ) do
            local times = 0
            while (i:find(token)) do
                local strpos, strend = i:find(token)

                local pre = i:sub( strpos - 1, strpos - 1 )
                local post = i:sub( strend + 1, strend + 1 )

                if pre ~= '_' and post ~= '.' then
                    i = i:sub( 1, strpos - 1 ) .. '\v.unit' .. i:sub( strend + 1 )
                    times = times + 1
                else
                    i = i:sub( 1, strpos - 1 ) .. '\v' .. i:sub( strend + 1 )
                end
            end

            if times > 0 then
                table.insert( warnings, "Line " .. line .. ": Converted non-specific 'target' to 'target.unit' (" .. times .. "x)." )
            end
            i = i:gsub( '\v', token )
        end
    end 


    for token in i:gmatch( "player" ) do
        local times = 0
        while (i:find(token)) do
            local strpos, strend = i:find(token)

            local pre = i:sub( strpos - 1, strpos - 1 )
            local post = i:sub( strend + 1, strend + 1 )

            if pre ~= '_' and post ~= '.' then
                i = i:sub( 1, strpos - 1 ) .. '\v.unit' .. i:sub( strend + 1 )
                times = times + 1
            else
                i = i:sub( 1, strpos - 1 ) .. '\v' .. i:sub( strend + 1 )
            end
        end

        if times > 0 then
            table.insert( warnings, "Line " .. line .. ": Converted non-specific 'player' to 'player.unit' (" .. times .. "x)." )
        end
        i = i:gsub( '\v', token )
    end

    return i
end


local function strsplit( str, delimiter )
    local result = {}
    local from = 1

    if not delimiter or delimiter == "" then
        result[1] = str
        return result
    end

    local delim_from, delim_to = string.find( str, delimiter, from )

    while delim_from do
        table.insert( result, string.sub( str, from, delim_from - 1 ) )
        from = delim_to + 1
        delim_from, delim_to = string.find( str, delimiter, from )
    end

    table.insert( result, string.sub( str, from ) )
    return result
end


--[[ local function StoreModifier( entry, key, value )

    if key ~= 'if' and key ~= 'ability' then
        if not entry.Args then entry.Args = key .. '=' .. value
        else entry.Args = entry.Args .. "," .. key .. "=" .. value end
    end

    if key == 'if' then
        entry.Script = value

    elseif key == 'cycle_targets' then
        entry.CycleTargets = tonumber( value ) == 1 and true or false

    elseif key == 'max_cycle_targets' then
        entry.MaximumTargets = value

    elseif key == 'moving' then
        entry.CheckMovement = true
        entry.Moving = tonumber( value )

    elseif key == 'name' then
        local v = value:match( '"(.*)"'' ) or value
        entry.ModName = v
        entry.ModVarName = v

    elseif key == 'value' then -- for 'variable' type, overwrites Script
        entry.Script = value

    elseif key == 'target_if' then
        entry.TargetIf = value

    elseif key == 'pct_health' then
        entry.PctHealth = value

    elseif key == 'interval' then
        entry.Interval = value

    elseif key == 'for_next' then
        entry.PoolForNext = tonumber( value ) ~= 0

    elseif key == 'wait' then
        entry.PoolTime = tonumber( value ) or 0

    elseif key == 'extra_amount' then
        entry.PoolExtra = tonumber( value ) or 0

    elseif key == 'sec' then
        entry.WaitSeconds = value

    end

end ]]

do
    local parseData = {
        warnings = {},
        missing = {},
    }

    local nameMap = {
        call_action_list = "list_name",
        run_action_list = "list_name",
        potion = "potion",
        variable = "var_name",
        cancel_buff = "buff_name",
        op = "op",
    }

    function Hekili:ParseActionList( list )

        local line, times = 0, 0
        local output, warnings, missing = {}, parseData.warnings, parseData.missing

        wipe( warnings )
        wipe( missing )

        list = list:gsub( "(|)([^|])", "%1|%2" ):gsub( "|||", "||" )

        local n = 0
        for aura in list:gmatch( "buff%.([a-zA-Z0-9_]+)" ) do
            if not class.auras[ aura ] then
                missing[ aura ] = true
                n = n + 1
            end
        end

        for aura in list:gmatch( "active_dot%.([a-zA-Z0-9_]+)" ) do
            if not class.auras[ aura ] then
                missing[ aura ] = true
                n = n + 1
            end
        end

        for i in list:gmatch( "action.-=/?([^\n^$]*)") do
            line = line + 1

            if i:sub(1, 3) == 'jab' then
                for token in i:gmatch( 'cooldown%.expel_harm%.remains>=gcd' ) do

                    local times = 0
                    while (i:find(token)) do
                        local strpos, strend = i:find(token)

                        local pre = strpos > 1 and i:sub( strpos - 1, strpos - 1 ) or ''
                        local post = strend < i:len() and i:sub( strend + 1, strend + 1 ) or ''
                        local repl = ( ( strend < i:len() and pre ) and pre or post ) or ""

                        local start = strpos > 2 and i:sub( 1, strpos - 2 ) or ''
                        local finish = strend < i:len() - 1 and i:sub( strend + 2 ) or ''

                        i = start .. repl .. finish
                        times = times + 1
                    end
                    table.insert( warnings, "Line " .. line .. ": Removed unnecessary expel_harm cooldown check from action entry for jab (" .. times .. "x)." )
                end
            end

            --[[ for token in i:gmatch( 'spell_targets[.%a_]-' ) do

                local times = 0
                while (i:find(token)) do
                    local strpos, strend = i:find(token)

                    local start = strpos > 2 and i:sub( 1, strpos - 1 ) or ''
                    local finish = strend < i:len() - 1 and i:sub( strend + 1 ) or ''

                    i = start .. enemies .. finish
                    times = times + 1
                end
                table.insert( warnings, "Line " .. line .. ": Replaced unsupported '" .. token .. "' with '" .. enemies .. "' (" .. times .. "x)." )
            end ]]

            if i:sub(1, 13) == 'fists_of_fury' then
                for token in i:gmatch( "energy.time_to_max>cast_time" ) do
                    local times = 0
                    while (i:find(token)) do
                        local strpos, strend = i:find(token)

                        local pre = strpos > 1 and i:sub( strpos - 1, strpos - 1 ) or ''
                        local post = strend < i:len() and i:sub( strend + 1, strend + 1 ) or ''
                        local repl = ( ( strend < i:len() and pre ) and pre or post ) or ""

                        local start = strpos > 2 and i:sub( 1, strpos - 2 ) or ''
                        local finish = strend < i:len() - 1 and i:sub( strend + 2 ) or ''

                        i = start .. repl .. finish
                        times = times + 1
                    end
                    table.insert( warnings, "Line " .. line .. ": Removed unnecessary energy cap check from action entry for fists_of_fury (" .. times .. "x)." )
                end
            end

            local components = strsplit( i, "," )
            local result = {}

            for a, str in ipairs( components ) do                
                -- First element is the action, if supported.
                if a == 1 then
                    local ability = str:trim()

                    if ability and ( ability == 'use_item' or class.abilities[ ability ] ) then
                        if ability == "pocketsized_computation_device" then ability = "cyclotronic_blast" end
                        if ability == "any_dnd" or ability == "wound_spender" then
                            result.action = ability
                        else
                            result.action = class.abilities[ ability ] and class.abilities[ ability ].key or ability
                        end
                    elseif not ignore_actions[ ability ] then
                        table.insert( warnings, "Line " .. line .. ": Unsupported action '" .. ability .. "'." )
                        result.action = ability
                    end

                else
                    local key, value = str:match( "^(.-)=(.-)$" )

                    if key and value then
                        if key == 'if' or key == 'condition' then key = 'criteria' end

                        if key == 'criteria' or key == 'target_if' or key == 'value' or key == 'value_else' or key == 'sec' or key == 'wait' then
                            value = Sanitize( 'c', value, line, warnings )
                            value = SpaceOut( value )
                        end

                        if key == 'description' then
                            value = value:gsub( ";", "," )
                        end

                        result[ key ] = value
                    end
                end
            end

            if nameMap[ result.action ] then
                result[ nameMap[ result.action ] ] = result.name
                result.name = nil
            end

            if result.target_if then result.target_if = result.target_if:gsub( "min:", "" ):gsub( "max:", "" ) end

            if result.for_next then result.for_next = tonumber( result.for_next ) end
            if result.cycle_targets then result.cycle_targets = tonumber( result.cycle_targets ) end
            if result.max_energy then result.max_energy = tonumber( result.max_energy ) end

            if result.use_off_gcd then result.use_off_gcd = tonumber( result.use_off_gcd ) end
            if result.use_while_casting then result.use_while_casting = tonumber( result.use_while_casting ) end
            if result.strict then result.strict = tonumber( result.strict ) end
            if result.moving then result.enable_moving = true; result.moving = tonumber( result.moving ) end

            if result.target_if and not result.criteria then
                result.criteria = result.target_if
                result.target_if = nil
            end

            if result.action == 'use_item' then
                if result.effect_name and class.abilities[ result.effect_name ] then
                    result.action = class.abilities[ result.effect_name ].key
                elseif result.name and class.abilities[ result.name ] then
                    result.action = result.name
                end
            end

            if result.action == 'variable' and not result.op then
                result.op = 'set'
            end

            table.insert( output, result )
        end

        if n > 0 then
            table.insert( warnings, "The following auras were used in the action list but were not found in the addon database:" )
            for k in orderedPairs( missing ) do
                table.insert( warnings, " - " .. k )
            end
        end

        return #output > 0 and output or nil, #warnings > 0 and warnings or nil    
    end
end



local warnOnce = false

-- Key Bindings
function Hekili:TogglePause( ... )

    Hekili.btns = ns.UI.Buttons

    if not self.Pause then
        self.ActiveDebug = true

        for i, display in pairs( ns.UI.Displays ) do
            if self:IsDisplayActive( i ) and display.alpha > 0 then
                self:ProcessHooks( i )
            end
        end

        self.Pause = true
        
        if self:SaveDebugSnapshot() then
            if not warnOnce then
                self:Print( "快照可以通过/hekili查看(直到你重新加载你的用户界面)." )
                warnOnce = true
            else
                self:Print( "快照保存." )
            end
        end
        
        self.ActiveDebug = false
    else
        self.Pause = false
    end

    local MouseInteract = self.Pause or self.Config

    for _, group in pairs( ns.UI.Buttons ) do
        for _, button in pairs( group ) do
            if button:IsShown() then
                button:EnableMouse( MouseInteract )
            end
        end
    end

    self:Print( ( not self.Pause and "UN" or "" ) .. "PAUSED." )
    self:Notify( ( not self.Pause and "UN" or "" ) .. "PAUSED" )

end


-- Key Bindings
function Hekili:MakeSnapshot( dispName, isAuto )
    if isAuto and not Hekili.DB.profile.autoSnapshot then return end

    self.ActiveDebug = true
    local success = false

    for i, display in pairs( ns.UI.Displays ) do
        if self:IsDisplayActive( i ) and display.alpha > 0 and ( dispName == nil or display.id == dispName ) then
            self:ProcessHooks( i )
            self:SaveDebugSnapshot( i )
            success = true
        end
    end

    self.ActiveDebug = false

    if success then
        self:Print( "快照保存." )
        self:Print( "快照可以通过/hekili查看(直到你重新加载你的用户界面)." )
    end
end



function Hekili:Notify( str, duration )
    if not self.DB.profile.notifications.enabled then
        self:Print( str )
        return
    end

    HekiliNotificationText:SetText( str )
    HekiliNotificationText:SetTextColor( 1, 0.8, 0, 1 )
    UIFrameFadeOut( HekiliNotificationText, duration or 3, 1, 0 )
end


do
    local modes = {
        "automatic", "single", "aoe", "dual", "reactive"
    }

    local modeIndex = {
        automatic = { 1, "Automatic" },
        single = { 2, "Single-Target" },
        aoe = { 3, "AOE (Multi-Target)" },
        dual = { 4, "Fixed Dual" },
        reactive = { 5, "Reactive Dual" },
    }

    local toggles = setmetatable( {
        custom1 = "Custom #1",
        custom2 = "Custom #2",
    }, {
        __index = function( t, k )
            if k == "essences" then k = "covenants" end
            
            local name = k:gsub( "^(.)", strupper )
            t[k] = name
            return name
        end,
    } )


    function Hekili:SetMode( mode )
        mode = lower( mode:trim() )
        
        if not modeIndex[ mode ] then
            Hekili:Print( "设置模式失败:  '%s' 不是有效模式.\n尝试 |cFFFFD100自动|r, |cFFFFD100单体|r, |cFFFFD100aoe|r, |cFFFFD100双目标|r, or |cFFFFD100被动|r." )
            return
        end

        self.DB.profile.toggles.mode.value = mode

        if self.DB.profile.notifications.enabled then
            self:Notify( "Mode: " .. modeIndex[ mode ][2] )
        else
            self:Print( modeIndex[ mode ][2] .. " 模式启动." )
        end        
    end


    function Hekili:FireToggle( name )
        local toggle = name and self.DB.profile.toggles[ name ]

        if not toggle then return end

        if name == 'mode' then
            local current = toggle.value
            local c_index = modeIndex[ current ][ 1 ]

            local i = c_index + 1

            while true do
                if i > #modes then i = i % #modes end
                if i == c_index then break end

                local newMode = modes[ i ]

                if toggle[ newMode ] then
                    toggle.value = newMode
                    break
                end

                i = i + 1
            end

            if self.DB.profile.notifications.enabled then
                self:Notify( "Mode: " .. modeIndex[ toggle.value ][2] )
            else
                self:Print( modeIndex[ toggle.value ][2] .. " mode activated." )
            end

        elseif name == 'pause' then
            self:TogglePause()
            return

        elseif name == 'snapshot' then
            self:MakeSnapshot()
            return

        else
            toggle.value = not toggle.value

            if toggle.name then toggles[ name ] = toggle.name end

            if self.DB.profile.notifications.enabled then
                self:Notify( toggles[ name ] .. ": " .. ( toggle.value and "ON" or "OFF" ) )
            else
                self:Print( toggles[ name ].. ( toggle.value and " |cFF00FF00ENABLED|r." or " |cFFFF0000DISABLED|r." ) )
            end
        end

        if WeakAuras and WeakAuras.ScanEvents then WeakAuras.ScanEvents( "HEKILI_TOGGLE", name, toggle.value ) end
        if ns.UI.Minimap then ns.UI.Minimap:RefreshDataText() end
        self:UpdateDisplayVisibility()

        self:ForceUpdate( "HEKILI_TOGGLE", true )
    end


    function Hekili:GetToggleState( name, class )
        local t = name and self.DB.profile.toggles[ name ]

        return t and t.value
    end
end
