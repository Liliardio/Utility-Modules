-- @ScriptType: ModuleScript
--!strict
type Activated = ((Button: GuiButton, Callback: (Count: number) -> ()) -> RBXScriptConnection)
& ((Button: GuiButton, Max: number, Callback: (Count: number) -> ()) -> RBXScriptConnection)

return function(Button: GuiButton, ...: number | (Count: number) -> ()): RBXScriptConnection
	local Count = 0
	local Max, Callback = ...

	if not tonumber(Max) then
		Callback = Max :: (Count: number) -> ()
		Max = nil
	end

	assert(typeof(Callback) == "function", 'Callback is not a function.')
	return Button.MouseButton1Down:Connect(function()
		Count += 1
		local ThisCount = Count

		if typeof(Callback) == 'function' then -- Silence type error
			Callback(ThisCount)
		end

		if Max and Count == Max then
			Count = 0
		else
			task.delay(0.2,function()
				if ThisCount == Count then
					Count = 0
				end
			end)
		end
	end)
end :: Activated