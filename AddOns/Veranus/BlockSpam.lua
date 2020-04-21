local AddonName, BlockSpam = ...

-- Function
--local CanReportPlayer, SendReportPlayer, InitiateReportPlayer, PlayerLocation = C_ReportSystem.CanReportPlayer, C_ReportSystem.SendReportPlayer, C_ReportSystem.InitiateReportPlayer, PlayerLocation
local PlayerLocation = PlayerLocation
local CanReportPlayer = C_ReportSystem.CanReportPlayer;
local ReportPlayer = C_ChatInfo.ReportPlayer;

local SendWho = C_FriendList.SendWho;
local C_Timer = C_Timer
-- Const
local REPORT_SPAMMING = "Spamming";
local WHO_TAG_NAME = "n-";
local WHO_TAG_EXACT = "x-";

local ChannelChatName = "Chat"
local ChannelEmoteName = "Emote"
local ChannelRepeatName = "Repeat"

local FriendNotes = "BlockMan"

local Chat_Event_List = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_CHANNEL",
}

local Emote_Event_List = {
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_TRADESKILLS",
}

local System_Event_List = {
    "CHAT_MSG_SYSTEM",
}

local DB
local BLACK
local LEVEL
local EMOTE;
local G = _G
local VERSION = "1.0.8"
local DeltaMax = 1000000
local ClearThreshold = 18000;

local debug_log = false;
local debug_stamp = false;

local debug_save = true;
-- switch
local toReport = false;
local toIgnore = true;
local isCheckingLevel = false;
local toLevel = true;
local toLevelAnchor = 0
local addAnchor = 0;

local EmoteMax = 100;
local ChatLenMax = 30;
local HashMax = 7
local ManMax = 20
local currLineId = 0
local playerName

function BlockSpam.trim(line)
    --Log("line", line)
    local word = string.gsub(line, "[%s%p%w]", "")
    --Log("word", word)
    return word
end

local function Log(...)
    if debug_log then
        print(...)
    end
end

local function LogTable(tag, arg)
    if debug_log then
        Log(tag .. "======\n:" .. type(arg))
        if arg and type(arg) == "table" then
            for k, v in pairs(arg) do
                Log(k, v)
                --if v and type(v) == "table" then
                --    LogTable("child", v)
                --end
            end
        end

    end
end

function BlockSpam.sendWho(name)
    SendWho(WHO_TAG_EXACT .. name);
end

function BlockSpam.clearRepeatChannel(...)
    local channel = DB[ChannelRepeatName]
    local nowTime = GetTime();
    if channel then
        if channel["clearAnchor"] and ((nowTime - channel["clearAnchor"]) < ClearThreshold) then
            return ;
        end
        channel["clearAnchor"] = nowTime;
        for k, man in pairs(channel) do
            if man and type(man) == "table" and man["manNum"] and man["manNum"] == 1 then
                channel[k] = nil;
            end
        end
    end
end

function BlockSpam.clearChatChannel(...)
    local channel = DB[ChannelChatName]
    local nowTime = GetTime();
    if channel then
        if channel["clearAnchor"] and ((nowTime - channel["clearAnchor"]) < ClearThreshold) then
            return ;
        end
        channel["clearAnchor"] = nowTime;

        for k, man in pairs(channel) do
            if man and type(man) == "table" and man["stamp"] and (nowTime - man["stamp"] > ClearThreshold) then
                channel[k] = nil;
            end
        end
    end
end

function BlockSpam.isRepeatEmote(line)
    local lineHash = BlockSpam.getLineHash(line);
    local isRepeat = false;
    --Log("lineHash", lineHash);
    if EMOTE then
        for i = 0, EmoteMax do
            local idx = tostring(i);
            if EMOTE[idx] and EMOTE[idx] == lineHash then
                --Log("EMOTE isRepeat", EMOTE[idx]);
                isRepeat = true;
                break;
            end
        end
        if not isRepeat then
            local saveIdx = EMOTE["index"];
            saveIdx = (saveIdx + 1) % EmoteMax;
            EMOTE[tostring(saveIdx)] = lineHash;
            EMOTE["index"] = saveIdx;
        end
    end
    return isRepeat;
end

function BlockSpam.toCheckLevel()
    local friendNum = C_FriendList.GetNumFriends();
    Log("toCheckLevel", friendNum)
    if friendNum > 75 then
        return false;
    else
        return true;
    end
end

function BlockSpam.clearBlockFriend()
    local friendNum = C_FriendList.GetNumFriends()
    Log("friendNum",friendNum)
    local removeList = {}
    local removeIdx = 0
    --Log("clearBlockFriend friendNum", friendNum)
    for i = friendNum, 0, -1 do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        --LogTable("friendInfo", friendInfo)
        if friendInfo and FriendNotes == friendInfo["notes"] then
            removeList[removeIdx] = friendInfo["name"];
            removeIdx = removeIdx + 1
        end
    end

    for _, v in pairs(removeList) do
        C_FriendList.RemoveFriend(v);
    end

end

function BlockSpam.tryBlockManByLevel(talkMan)
    if not talkMan["checkLevel"] then
        talkMan["checkLevel"] = true;

        C_Timer.After(5, function()
            BlockSpam.doTryBlockManByLevel(talkMan);
        end);
    else
        --Log("tryBlockManByLevel CHECKED",talkMan["name"])
        BlockSpam.clearBlockFriend();
    end
end

function BlockSpam.doTryBlockManByLevel(talkMan)
    local name = talkMan["name"]
    local separateIdx = string.find(name, "-")
    local nameMin
    if separateIdx then
        separateIdx = separateIdx - 1
        nameMin = string.sub(name, 1, separateIdx)
    end
    --Log("name", name, nameMin)

    --Log("tryLevel ", name)
    addAnchor = GetTime();
    C_FriendList.AddFriend(name, FriendNotes)
    C_Timer.After(3, function()
        local friendInfo = C_FriendList.GetFriendInfo(name);
        if not friendInfo then
            friendInfo = C_FriendList.GetFriendInfo(nameMin);
        end

        if friendInfo then
            -- BlockSpam.printTab("friendInfo",friendInfo)
            BlockSpam.tryBlockByInfo(talkMan, friendInfo)
        end

        C_FriendList.RemoveFriend(name);

        BlockSpam.clearBlockFriend();
        isCheckingLevel = false
    end);
end

function BlockSpam.tryBlockByInfo(talkMan, friendInfo)
    local connected = friendInfo["connected"]
    local name = friendInfo["name"]
    local className = friendInfo["className"]
    local area = friendInfo["area"]
    local notes = friendInfo["notes"]
    local guid = friendInfo["guid"]
    local level = friendInfo["level"]

    talkMan["level"] = level;
    talkMan["className"] = className;
    talkMan["area"] = area;
    --Log("name", name, level)
    if BlockSpam.isBlockByLevel(level) then
        BlockSpam.saveBlackList(talkMan, "level")
    end
    BlockSpam.saveLevelInfo(talkMan["name"], level);
end

function BlockSpam.isBlockByLevel(level)
    if level < 20 or level == 55 or level == 98 or level == 110 then
        return true
    else
        return false
    end
end

function BlockSpam.isBlackMan(name)
    if BLACK[name] then
        return true;
    else
        return false;
    end
end
function BlockSpam.saveBlackList(talkMan, reason)
    local name = talkMan["name"]
    --Log("saveBlackList", name)
    local blackMan = BLACK[name]
    if not blackMan then
        blackMan = {}
        BLACK[name] = blackMan
    end

    blackMan["name"] = name;
    local line = talkMan["line"]
    local hash = talkMan["lineHash"]
    local repeatNum, deltaAvg = BlockSpam.getRepeatLine(talkMan, line, hash)
    blackMan["line"] = line;
    blackMan["repeat"] = repeatNum;
    blackMan["average"] = deltaAvg;
    blackMan["stamp"] = math.floor(GetTime())
    blackMan["date"] = date()
    blackMan["reason"] = reason;

    if talkMan["level"] then
        blackMan["level"] = talkMan["level"];
        blackMan["className"] = talkMan["className"];
        blackMan["area"] = talkMan["area"];
    end
end

function BlockSpam.getLineHash(word)
    local hash = 0
    if word ~= nil then
        local len = #word
        if len > ChatLenMax then
            len = ChatLenMax
        end

        local list = { string.byte(word, 1, len) }

        for k, v in ipairs(list) do
            if k % 3 == 1 then
                hash = (hash + v) * 7
            end
        end
    end
    return hash
end

function BlockSpam.isRepeatMan(talkMan)
    local repeatChannel = DB[ChannelRepeatName]
    if repeatChannel then
        local hash = talkMan["lineHash"]
        local repeatLine = repeatChannel[hash]
        --LogTable("isRepeatMan repeatLine",repeatLine)
        --Log("manNum", repeatLine["manNum"])
        if repeatLine and repeatLine["manNum"] > 1 then
            return true;
        end
    end
    return false;
end

function BlockSpam.saveLineHash(talkMan, line)
    local hash = talkMan["lineHash"]
    local deltaTime = talkMan["deltaTime"]
    local index = talkMan["talkNum"] % HashMax
    talkMan[string.format("Hash-%d", index)] = hash
    talkMan[string.format("Delta-%d", index)] = deltaTime
    --LogTable("saveLineHash talkMan",talkMan)
    BlockSpam.saveRepeatLine(talkMan, line);
end

function BlockSpam.getLevelInfo(name)
    return LEVEL[name]
end
function BlockSpam.saveLevelInfo(name, level)
    LEVEL[name] = level
end

function BlockSpam.saveRepeatLine(talkMan, line)
    local hash = talkMan["lineHash"]
    if hash == 0 then
        return ;
    end

    local repeatChannel = DB[ChannelRepeatName]
    if not repeatChannel then
        repeatChannel = {}
        DB[ChannelRepeatName] = repeatChannel
    end

    local repeatLine = repeatChannel[hash];
    local manNum = 0;
    if not repeatLine then
        repeatLine = {}
        repeatChannel[hash] = repeatLine
    else
        manNum = repeatLine["manNum"]
    end

    repeatLine["lineHash"] = hash;
    repeatLine["line"] = line;

    repeatLine["stamp"] = math.floor(GetTime())
    repeatLine["date"] = date();

    local talkName = talkMan["name"]
    for i = 0, ManMax do
        local manIdx = i % ManMax;
        local repeatName = repeatLine["Man-" .. manIdx]
        --Log("saveRepeatLine", hash, i, manIdx,  repeatName, talkName)
        if not repeatName then
            repeatLine["Man-" .. manIdx] = talkName;
            manNum = manNum + 1;
            break ;
        elseif repeatName == talkName then
            break ;
        end
    end

    repeatLine["manNum"] = manNum;

end

function BlockSpam.reportMan(talkMan, guid)
    -- Log("guid", guid)
    local playerLoc = PlayerLocation:CreateFromGUID(guid)
    if CanReportPlayer(playerLoc) then
        --local reportToken = InitiateReportPlayer(REPORT_SPAMMING, playerLoc);
        --SendReportPlayer(reportToken, reason);
        --Log("ReportPlayer", talkMan["name"])
        local reason = talkMan["name"] .. " Keeping" .. "send Spam: " .. talkMan["line"]
        ReportPlayer(REPORT_SPAMMING, playerLoc, reason)
    end
end

function BlockSpam.getRepeatLine(talkMan)
    local repeatLine = 0
    local deltaAvg = 0
    local hash = talkMan["lineHash"]
    local deltaSum = 0
    local deltaNum = 0
    for i = 0, HashMax do
        local hashItem = talkMan[string.format("Hash-%d", i)]
        local deltaItem = talkMan[string.format("Delta-%d", i)]
        if hashItem and hashItem == hash then
            repeatLine = repeatLine + 1
        end

        if deltaItem and deltaItem ~= DeltaMax and deltaItem < 300 then
            deltaSum = deltaSum + deltaItem
            deltaNum = deltaNum + 1
        end
    end
    if deltaNum > 0 then
        deltaAvg = deltaSum / deltaNum
    end
    return repeatLine, deltaAvg
end

function BlockSpam.processText(frame, event, line, ...)
    if line then
        Log("processText", line)
        if BlockSpam.isRepeatEmote(line) then
            return true;
        end
    end
    return false;

end

function BlockSpam.processSystem(frame, event, line, ...)
    local args = { ... }
    --LogTable("processSystem",args)
    local lineID = args[10]
    --Log("processSystem lineID",lineID)
    if currLineId ~= lineID then
        currLineId = lineID
    else
        return false;
    end
    --local line = args[1];
    --Log("processSystem line",line)
    --Log("processSystem delta",(GetTime() - addAnchor))
    if (GetTime() - addAnchor) < 2 then
        return true;
    else
        return false;
    end
end
function BlockSpam.processChat(frame, event, message, sender, ...)
    -- Log("processChat sender",sender)
    local args = { ... }
    --LogTable("processChat",args)

    -- Log("processChat event",args[9])
    -- for k, v in ipairs({...}) do
    --  Log(k,v)
    -- end

    local lineID = args[9]

    if currLineId ~= lineID then
        currLineId = lineID
    else
        return false, message, sender, ...
    end
    --Log("processChat lineID",lineID)

    --local channelName = args[2]
    local playerName2 = args[3]
    local channelBaseName = args[7]
    local guid = args[10]

    local deltaTime = 0
    local repeatNum = 0
    -- Log("name",playerName, sender)
    if sender and string.find(sender, playerName) == nil and type(message) == "string" then
        local line = BlockSpam.trim(message)
        --block it
        if BlockSpam.isBlackMan(sender) then
            --Log("Block BLACK", line)
            return true
        end
        --make channel
        local chatName = ChannelChatName;
        local channel = DB[chatName]
        if not DB[chatName] then
            channel = {}
            DB[chatName] = channel
        end

        local nowTime = math.floor(GetTime())
        local hash = BlockSpam.getLineHash(line)
        local deltaAvg = DeltaMax;
        local repeatLine;
        local talkNum;

        --make talkMan
        local talkMan = channel[sender]
        if not channel[sender] then
            talkMan = {}
            channel[sender] = talkMan
            talkNum = 1;
            deltaAvg = DeltaMax;
            deltaTime = DeltaMax;
        else
            --LogTable("processChat talkMan",talkMan)
            talkNum = talkMan["talkNum"] + 1;
            deltaTime = math.floor(nowTime - talkMan["stamp"])
        end

        talkMan["name"] = sender
        talkMan["talkNum"] = talkNum
        talkMan["deltaTime"] = deltaTime
        talkMan["line"] = line
        talkMan["lineHash"] = hash
        talkMan["stamp"] = nowTime
        talkMan["date"] = date()
        BlockSpam.saveLineHash(talkMan, line)
        --LogTable("processChat talkMan",talkMan)

        --check repeat talkMan
        if BlockSpam.isRepeatMan(talkMan) then
            BlockSpam.saveBlackList(talkMan, "repeat")
            --Log("Block repeat", line)
            return true
        end

        repeatLine, deltaAvg = BlockSpam.getRepeatLine(talkMan)
        --Log("repeatLine deltaAvg",  sender, repeatLine, deltaAvg, message)
        --check level
        local toLevelDelta = nowTime - toLevelAnchor;
        if toLevel and repeatLine > 3 and toLevelDelta > 37 then
            toLevelAnchor = nowTime;
            local level = BlockSpam.getLevelInfo(sender);
            if level and BlockSpam.isBlockByLevel(level) then
                --Log("Block level", level, line)
                if not BlockSpam.isBlackMan then
                    BlockSpam.saveBlackList(talkMan, "level")
                end
                return true;
            elseif not level then
                BlockSpam.tryBlockManByLevel(talkMan)
            end
        end

        if toReport and deltaAvg < 35 and repeatLine > 3 then
            --report it
            BlockSpam.reportMan(talkMan, guid)
        end

        if repeatLine > 1 then
            --Log("repeatLine deltaAvg", deltaAvg)
            local slowMax;
            if deltaAvg < 15 then
                slowMax = 347.23
            elseif deltaAvg < 25 then
                slowMax = 223.23
            elseif deltaAvg < 45 then
                slowMax = 173.23
            elseif deltaAvg < 75 then
                slowMax = 127.23
            else
                slowMax = 103.23
            end

            local slowAnchor = talkMan["slowAnchor"]

            if slowAnchor then
                local deltaSlow = nowTime - slowAnchor
                if deltaSlow < slowMax then
                    --Log("Block Slow", deltaSlow, deltaAvg, sender, line)
                    return true
                else
                    talkMan["slowAnchor"] = nowTime;
                end
            else
                --Log("Block Slow First", sender, line)
                talkMan["slowAnchor"] = nowTime;
                return true
            end
        end

    end

    -- Log("blockSpam next",sender, line, deltaTime, repeatNum)
    if debug_stamp and deltaTime ~= DeltaMax then
        message = message .. " -" .. deltaTime .. "S"
    end
    return false, message, sender, ...
end

function BlockSpam.processEmote(line, sender, ...)
    local args = { ... }
    -- Log("blockEmote")
    -- BlockSpam.printTab(args)
    -- for k, v in ipairs({...}) do
    --  Log(k,v)
    -- end
    -- local lineID = args[9]
    local guid = args[10]
    local channel = DB[ChannelEmoteName]
    if not channel then
        channel = {}
        DB[ChannelEmoteName] = channel
    end

    local nowTime = math.floor(GetTime())
    local hash = BlockSpam.getLineHash(line)
    local deltaAvg = -1;
    local repeatLine;
    local talkNum;
    local deltaTime = 0
    local repeatNum = 0
    --make talkMan
    local talkMan = channel[sender]
    if not channel[sender] then
        talkMan = {}
        channel[sender] = talkMan
        talkNum = 1;
        deltaAvg = -1;
    else
        talkNum = talkMan["talkNum"] + 1;
        deltaTime = math.floor(nowTime - talkMan["stamp"])
    end

    talkMan["name"] = sender
    talkMan["talkNum"] = talkNum
    talkMan["line"] = line
    talkMan["lineHash"] = hash
    talkMan["stamp"] = nowTime
    talkMan["date"] = date()
    BlockSpam.saveLineHash(talkMan, line)

    repeatLine, deltaAvg = BlockSpam.getRepeatLine(talkMan)
    if repeatNum > 3 then
        if toReport then
            --report it
            BlockSpam.reportMan(talkMan, guid)
        end
        if toIgnore then
            C_FriendList.AddIgnore(sender)
        end
    end

end

function BlockSpam.onLoad(self, event, ...)
    Log("onLoad")
    --Saved
    if debug_save then
        DB = BlockSpamDB
        if not DB or DB["version"] ~= VERSION then
            DB = {}
            BlockSpamDB = DB
        end
        DB["version"] = VERSION
        BlockSpam.clearRepeatChannel();
        BlockSpam.clearChatChannel();
    else
        DB = {}
    end
    EMOTE = DB[ChannelEmoteName];
    if not EMOTE then
        EMOTE = {};
        EMOTE["index"] = 0;
        DB[ChannelEmoteName] = EMOTE;
    end

    LEVEL = BlackListLevel
    if not LEVEL or LEVEL["version"] ~= VERSION then
        LEVEL = {}
        BlackListLevel = LEVEL
    end
    BlackListLevel["version"] = VERSION

    BLACK = BlackListDB
    if not BLACK or BLACK["version"] ~= VERSION then
        BLACK = {}
        BlackListDB = BLACK
    end
    BLACK["version"] = VERSION

    --LogTable("DB", DB)
    --LogTable("BLACK", BLACK)
    playerName = UnitName("player")
    for _, event in pairs(Chat_Event_List) do
        ChatFrame_AddMessageEventFilter(event, BlockSpam.processChat)
    end
    for _, event in pairs(System_Event_List) do
        ChatFrame_AddMessageEventFilter(event, BlockSpam.processSystem)
    end
    for _, event in pairs(Emote_Event_List) do
        ChatFrame_AddMessageEventFilter(event, BlockSpam.processText)
    end

    --toLevel = BlockSpam.toCheckLevel();

end

function BlockSpam.onEvent(self, event, line, ...)
    -- Log("onEvent", event)
    if event == "ADDON_LOADED" then
        BlockSpam.onLoad()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        --Log("PLAYER_LOGIN")
    elseif event == "FRIENDLIST_UPDATE" then
        --Log("FRIENDLIST_UPDATE")
    end
end

local blockFrame = CreateFrame("Frame", "BlockSpam")
blockFrame:RegisterEvent("ADDON_LOADED")
blockFrame:RegisterEvent("PLAYER_LOGIN")
blockFrame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
blockFrame:RegisterEvent("CHAT_MSG_EMOTE")
blockFrame:RegisterEvent("FRIENDLIST_UPDATE")
-- blockFrame:RegisterEvent("CHAT_MSG_SYSTEM")

blockFrame:SetScript("OnEvent", BlockSpam.onEvent)

SLASH_BLOCK_SPAM1 = "/bs"
SlashCmdList["BLOCK_SPAM"] = function(msg, editBox)
    Log("BlockSpam")
end