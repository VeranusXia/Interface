local AS = CreateFrame("Frame")

AS:RegisterEvent("QUEST_ACCEPTED")
AS:SetScript("OnEvent", function(self, event, qid)
	if event=="QUEST_ACCEPTED" then  
		if GetNumGroupMembers() < 1 then
			return
		end
		C_QuestLog.SetSelectedQuest(qid)
		if C_QuestLog.IsPushableQuest(qid) then
			QuestLogPushQuest();
		end
	end 
end)




