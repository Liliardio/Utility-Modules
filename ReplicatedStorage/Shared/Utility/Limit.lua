-- @ScriptType: ModuleScript
--!strict

local Functions = {}

Functions.Limit = function(Value: number, Amount: number)
	local Limiter = Value >= 0 and math.min or math.max
	return Limiter(math.sign(Value) * math.abs(Amount), Value)
end;

Functions.Clamp = function(Value: number, Min: number, Max: number, Amount: number)
	if Min > Max then
		Max, Min = Min, Max
	end

	return Functions.Limit(math.clamp(Value, Min, Max), Amount)
end

return Functions