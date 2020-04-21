
--local flashGraphic = "Interface\\AddOns\\Ahoy\\Flash.blp";
Ahoy.ScoreBuffer = {}
Ahoy.ScoreTime = 0.0;
Ahoy.TimeLimit = 2;
local Gained = 0;
local checking = false;

function Ahoy_FlashReset()
	Ahoy.ScoreBuffer = {}
	Ahoy.ScoreTime = 0.0;
	Gained = 0;
end

function Ahoy_PlayFlashCard()
	if Gained > 1000 and Gained < 2000 then
		print (1000);
		PlaySoundFile("Interface\\AddOns\\Ahoy\\UI\\eggsandbacon")
	end
	if Gained > 2000 and Gained < 3000 then
		print (2000);
		-- 2000+
	end
	if Gained > 3000 then
		print (3000);
	end

	-- reset
	Ahoy_FlashReset()
end

-- triggered when azerite is gained --
function Ahoy_UpdateFlashScore(amount)
	if checking == false then
		Ahoy.ScoreBuffer[Ahoy.ScoreTime] = amount;
		--local gained = 0;
		for t = 0, Ahoy.TimeLimit, 0.1 do
			local value = Ahoy.ScoreBuffer[Ahoy.ScoreTime - t];
			if value ~= nil then
				Gained = Gained + value
			end
		end
		if Gained > 1000 then
			Ahoy__wait(1, Ahoy_PlayFlashCard)
			checking = true;
		end
	else
		if (amount ~= nil) then
			Gained = Gained + amount;
		end
	end
end