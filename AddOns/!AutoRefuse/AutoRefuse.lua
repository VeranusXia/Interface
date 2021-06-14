local IPM_F = CreateFrame("Frame");
local area = {
	['暴风城'] = 0,
	['奥格瑞玛'] = 0,
    ['奥利波斯'] = 0,
	}
local whiteList ={ --白名单
	['角色名-服务器'] = 1,
}
local m_recv = {}
local m_send = {}

IPM_F:RegisterEvent("PARTY_INVITE_REQUEST");
IPM_F:RegisterEvent("CHAT_MSG_WHISPER");
IPM_F:RegisterEvent("CHAT_MSG_WHISPER_INFORM");
function IPM_F:OnEvent(event, ...)
    if event == "CHAT_MSG_WHISPER_INFORM" then
        local text, playerName = ...
        m_send[playerName] = true
    elseif event == "CHAT_MSG_WHISPER" then
        local text, playerName = ...
        m_recv[playerName] = true
    elseif event == "PARTY_INVITE_REQUEST"  then
        if area[GetZoneText()] == nil or area[GetZoneText()] == 0 then
            return
        end
        local name = ...
		
		if whiteList[name] ~= nil then
			print(name)
			return
		end
		
        local num = GetNumGuildMembers()
        if num > 0 then
            for i =1, num do
                local gName = GetGuildRosterInfo(i)
                if string.find(gName, GetRealmName()) then
                    gName =strsplit("-", gName)
                end
                if name == gName then
                    return
                end
            end
        end
        local num = BNGetNumFriends()
        if num > 0 then
            for i =1, num do
                local info =  C_BattleNet.GetFriendAccountInfo(i).gameAccountInfo
                if info.clientProgram == BNET_CLIENT_WOW then
                    local gName = info.characterName.."-"..(info.realmName or "")
                    if string.find(gName, GetRealmName()) then
                        gName =strsplit("-", gName)
                    end
                    if name == gName then
                        return
                    end
                end
            end
        end
        if not m_send[name] then
            print("已拒绝 "..name.." 的组队邀请。")
            DeclineGroup()
            StaticPopup_Hide("PARTY_INVITE")
        end
    end
end
IPM_F:SetScript("OnEvent",IPM_F.OnEvent);