local frame = CreateFrame("FRAME", nil, UIParent)
local round, timeStart, isLost, isForfeit, npcName;
frame:RegisterEvent("PET_BATTLE_OPENING_START")
frame:RegisterEvent("PET_BATTLE_CLOSE")
frame:RegisterEvent("PET_BATTLE_PET_ROUND_RESULTS")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PET_BATTLE_OPENING_START" then
        isForfeit = nil
        timeStart = time()
        round = 0
    elseif event == "PET_BATTLE_PET_ROUND_RESULTS" then
        local roundNumber = (...)
        round = roundNumber
    elseif event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") then
            local name = UnitName("target")
            npcName = name
        end
    elseif event == "PET_BATTLE_CLOSE" then
        if not C_PetBattles.IsInBattle() then
            local t = time() - timeStart
            local seconds = t
            if seconds > 3600 then
                h = floor(seconds / 3600);
                m = floor(seconds - (h) * 60);
                s = floor(seconds - (m) * 60);
                t = format("%d小时%d分%02d秒。", h, m, s)
            end
            if seconds > 120 then
                m = floor(seconds / 60);
                s = floor(seconds - (m) * 60);
                t = format("%d分%02d秒。", m, s)
            end
            if seconds < 120 then
                t = format(t .. "秒。")
            end
            local msg = "|cffffcd00Rematch: |r|cff00ffff本次与|r|cffffd700["..npcName.."]|r|cff00ffff对战:  |r";
            if isLost then
                msg = msg .. "\124TInterface\\AddOns\\Rematch\\Textures\\No:16\124t|cffff4500失败！|r"
            else
                msg = msg .. "\124TInterface\\AddOns\\Rematch\\Textures\\Ok:16\124t|cff32cd32胜利！|r"
            end
            print(msg .. "" .. "|cff00ffff共" .. round .. "轮，用时" .. t .. "|r")
        else
            isLost = false
            local selfAlive = false;
            local enemyAlive = false;
            for petEnemy = 1, C_PetBattles.GetNumPets(LE_BATTLE_PET_ENEMY) do
                local health = C_PetBattles.GetHealth(LE_BATTLE_PET_ENEMY, petEnemy)
                if health and health > 0 then
                    enemyAlive = true
                    break
                end
            end
            for petSelf = 1, C_PetBattles.GetNumPets(LE_BATTLE_PET_ALLY) do
                local health = C_PetBattles.GetHealth(LE_BATTLE_PET_ALLY, petSelf)
                if health and health > 0 then
                    selfAlive = true
                    break
                end
            end
            if (not enemyAlive and not selfAlive) or not selfAlive then
                isLost = true
            elseif selfAlive and enemyAlive then
                if isForfeit then
                    isLost = true
                else
                    isLost = false
                end
            end
        end
    end
end)
hooksecurefunc(C_PetBattles, "ForfeitGame", function()isForfeit = true end)
