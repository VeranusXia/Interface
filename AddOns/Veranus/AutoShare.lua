local AS = CreateFrame("Frame")

AS:RegisterEvent("QUEST_ACCEPTED")
AS:SetScript("OnEvent", function(self, event, ...)
	if event=="QUEST_ACCEPTED" then  
		if GetNumGroupMembers() < 1 then
			return
		end
		SelectQuestLogEntry(...);
		if GetQuestLogPushable() then
			QuestLogPushQuest();
		end
	end 
end)




