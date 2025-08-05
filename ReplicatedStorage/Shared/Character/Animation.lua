-- @ScriptType: ModuleScript
--!strict
local Cache: {[Model]: {[number]: AnimationTrack}} = {}

return function(Character: Model, Animation: number?): AnimationTrack
	assert(Animation, 'Animation ID required.')
	if not Cache[Character] then
		Cache[Character] = {}
		
		Character.AncestryChanged:Connect(function()
			if Character.Parent then return end
			Cache[Character] = nil
		end)
	end
	
	local Animator = Character:FindFirstChild('Animator',true) :: Animator
	local Anim = Instance.new('Animation')
	
	Anim.AnimationId = `rbxassetid://{Animation}`
	
	local Track = Animator:LoadAnimation(Anim)

	Cache[Character][Animation] = Track
	
	Track.Destroying:Connect(function()
		if not Cache[Character] then return end
		Cache[Character][Animation] = nil
	end)
	
	return Track
end
