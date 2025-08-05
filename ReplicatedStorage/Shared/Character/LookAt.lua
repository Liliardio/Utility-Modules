-- @ScriptType: ModuleScript
--!strict
local Cache = {}

return function(Object: PVInstance, Destination: CFrame?): AlignOrientation?
	local Object = Object:IsA('Model') and Object.PrimaryPart or Object
	if not Object:IsA('BasePart') then return nil end
	
	Cache[Object] = Cache[Object] or Instance.new('AlignOrientation')
	local LookAt = Cache[Object]
	
	LookAt.Attachment0 = LookAt.Attachment0 or Instance.new('Attachment',Object)
	LookAt.Mode = Enum.OrientationAlignmentMode.OneAttachment
	LookAt.MaxTorque = math.huge
	LookAt.Responsiveness = 25
	LookAt.AlignType = Enum.AlignType.PrimaryAxisParallel
	
	Destination = if Destination == Destination and Destination ~= Object:GetPivot() then Destination
		else nil
	LookAt.CFrame = Destination
		or LookAt.CFrame
	LookAt.Enabled = not not Destination
	LookAt.Parent = (LookAt.Parent
		or Object.Parent == workspace and Object
		or Object.Parent) :: Instance?

	local Attachment0, Attachment1 = LookAt.Attachment0, LookAt.Attachment1
	LookAt.AncestryChanged:Connect(function()
		if not LookAt:IsDescendantOf(game) then
			Cache[Object] = nil
			pcall(game.Destroy,Attachment0)
			pcall(game.Destroy,Attachment1)
			pcall(game.Destroy,LookAt)
		end
	end)
	
	return LookAt
end