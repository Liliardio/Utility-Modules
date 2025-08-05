-- @ScriptType: ModuleScript
--!strict

return function (Properties: {[string]: any; ClassName: string; Parent: Instance?; Destroy: number?;}): Instance
	local Debris = game:GetService('Debris')
	local Object = Instance.new(Properties.ClassName);

	if Object:IsA('BasePart') then
		Object.TopSurface = Enum.SurfaceType.Smooth
		Object.BottomSurface = Enum.SurfaceType.Smooth
		Object.Anchored = true
	end

	for i, v in Properties do
		if i == 'Parent' then continue end

		if i == 'Destroy' then
			pcall(Debris.AddItem,Debris,Object,v)
			continue
		end

		pcall(function()
			if i:find('SoundId') then
				Object[i] = tonumber(v) and 'rbxassetid://' .. v
			else
				Object[i] = v
			end
		end)
	end

	Object.Parent = Properties.Parent

	return Object
end