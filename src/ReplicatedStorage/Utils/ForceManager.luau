--!strict
local ForceManager = {}

function ForceManager.ApplyForce(humanoidRootPart: BasePart, amount: number, duration: number)
	local attachment = Instance.new("Attachment")
	attachment.Parent = humanoidRootPart

	local LV = Instance.new("LinearVelocity")
	LV.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
	LV.LineDirection = humanoidRootPart.CFrame.LookVector
	LV.LineVelocity = amount
	LV.MaxForce = 10000
	LV.Attachment0 = attachment
	LV.Parent = humanoidRootPart

	task.delay(duration, function()
		LV:Destroy()
		attachment:Destroy()
	end)
end

return ForceManager
