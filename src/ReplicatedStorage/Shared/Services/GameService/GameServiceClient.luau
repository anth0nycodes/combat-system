--!strict
local GameServiceClient = {}

-- Game Services
local SG = game:GetService("StarterGui")

function GameServiceClient.Init()
	SG:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end

return GameServiceClient
