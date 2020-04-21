-------------------------------------------------------
-------------------- Queue Window ---------------------
-------------------------------------------------------
Ahoy.QueueWindowFrame = CreateFrame("Frame",nil,Ahoy.MainFrame)
Ahoy.QueueWindowFrame:SetWidth(100) -- Set these to whatever height/width is needed 
Ahoy.QueueWindowFrame:SetHeight(100) -- for your Texture
Ahoy.QueueWindowFrame:SetPoint("CENTER",0,0)
local QueueWindowFrame_Texture = Ahoy.QueueWindowFrame:CreateTexture() 
QueueWindowFrame_Texture:SetAllPoints() 
QueueWindowFrame_Texture:SetTexture("Interface/timer/challenges-logo")
Ahoy.QueueWindowFrame.background = QueueWindowFrame_Texture