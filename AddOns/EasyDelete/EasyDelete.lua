
function Drop()
	SlashCmdList["DeleteItem"] = DeleteItemAction
	SLASH_DeleteItem1 = "/删除"
	print("EasyDelete load finish")
end 

function DeleteItemAction(item)
	if item == "" then return end
	for b = 0, 4 do
		p = GetContainerNumSlots(b)
		for i = 1, p do
			e = GetContainerItemLink(b, i)
			if e and string.find(e, item) then
				PickupContainerItem(b, i);
				DeleteCursorItem();
			end
		end
	end
end


local frame = CreateFrame("Frame", nil, UIParent);
frame:RegisterEvent("VARIABLES_LOADED");
frame:SetScript("OnEvent", Drop);
 