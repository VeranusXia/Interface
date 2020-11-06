local  EJShowSL=CreateFrame("Frame")

EJShowSL.onEJShow = function()
    EncounterJournalInstanceSelectLootJournalTab:Show()
    EncounterJournal_TierDropDown_Select(nil, 9)
end

EJShowSL.hook = function()
    if (EJShowSL.isHooked or not EncounterJournal) then
        return nil
    end
    hooksecurefunc(EncounterJournal, 'Show', EJShowSL.onEJShow)
    EJShowSL.onEJShow()
    EJShowSL.isHooked = 1
    return nil
end

EJShowSL:RegisterUnitEvent("UNIT_AURA","player")
EJShowSL:RegisterUnitEvent("UNIT_SPELLCAST_START","player")
EJShowSL:SetScript("OnEvent",EJShowSL.hook)
 