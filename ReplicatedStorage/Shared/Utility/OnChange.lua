-- @ScriptType: ModuleScript
--!strict

type Overload = (
	-- Overload 1: Provided Callback, return a Connection
	(<V>(Object: Instance, State: string?, Callback: (newValue: V) -> ()) -> RBXScriptConnection) &
	-- Overload 2: No Callback, Return a Signal
	((Object: Instance, State: string?) -> RBXScriptSignal)
)

return function<V>(Object: Instance | ValueBase, State: string?, Callback: ((...V) -> ())?): RBXScriptConnection | RBXScriptSignal
	if not State then
		if Callback then
			task.spawn(Callback, Object:IsA('ValueBase') and (Object :: BoolValue).Value or nil) -- Explicitly set the type to silence the error, since ValueBase doesn't actually have .Value
			return Object.Changed:Connect(function(...)
				Callback(...)
			end)
		else
			return Object.Changed
		end
	else
		local IsProperty: boolean, Signal: RBXScriptSignal = pcall(Object.GetPropertyChangedSignal,Object,State)
		Signal = IsProperty and Signal
			or Object:GetAttributeChangedSignal(State)

		if Callback then
			local Object = Object :: {[string]: any} -- Silence the type error
			task.spawn(Callback, IsProperty and Object[State] or Object:GetAttribute(State))
			return Signal:Connect(function()
				Callback(IsProperty and Object[State] or Object:GetAttribute(State))
			end)
		else
			return Signal
		end
	end
end :: Overload