-- @ScriptType: ModuleScript
--!strict
type Signals = RBXScriptSignal | number | () -> any
local Module = {}

Module.MultiEventWait = function(...: Signals | {Signals})
	local Signal = Instance.new("BindableEvent")
	for _, v in typeof(... :: {Signals}?) == "table" and ... or { ... } do
		task.spawn(function()
			if typeof(v) == 'RBXScriptSignal' then
				Signal:Fire(v:Wait())
			elseif typeof(v) == 'number' then
				Signal:Fire(task.wait(v))
			elseif typeof(v) == "function" then
				Signal:Fire(v())
			else
				error(`'Wait' method not available for {v}`)
			end
		end)
	end

	Signal.Event:Connect(function()
		task.defer(game.Destroy,Signal)
	end)

	return Signal.Event:Wait()
end;

Module.WhileTrue = function(Data: {Time: number; Validation: () -> boolean; Post: ((Finshed: boolean,Time: number?, Delta: number?) -> ())?; Signals: {Signals}?})
	local Start = os.clock()
	while os.clock() - Start < Data.Time and Data.Validation() do
		if Data.Signals then
			Module.MultiEventWait(Data.Signals)
		else
			task.wait()
		end
	end

	if Data.Post and Data.Validation() then
		local Delta = os.clock() - Start
		Data.Post(Delta >= Data.Time, Data.Time, Delta)
	end
end;

return Module