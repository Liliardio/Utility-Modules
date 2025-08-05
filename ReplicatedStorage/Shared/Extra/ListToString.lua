-- @ScriptType: ModuleScript
local ListToString = function(List: {Instance | string}): string
	local String = ""
	for i, v in List do
		if typeof(v) == 'string' or typeof(v) == 'number' then
			String = `{String}{v}{i == #List and "" or ", "}`
		elseif typeof(v) == 'Instance' then
			String = `{String}{v.Name}{i == #List and "" or ", "}`
		end
	end
	return String
end

return ListToString