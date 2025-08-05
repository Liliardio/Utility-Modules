-- @ScriptType: ModuleScript
return function(List: any, ApplyOrder: boolean?)
	table.sort(List, function(a: string, b: string): boolean
		if typeof(a) == 'Instance' and a:IsA('UIComponent') then
			return false
		end
		local a,b = typeof(a) == 'Instance' and a.Name or a, typeof(b) == 'Instance' and b.Name or b
		a,b = tostring(a),tostring(b)

		if b:gsub("%s+%d+", "") == (a:gsub("%s+%d+", "")) or tonumber(a) or tonumber(b) then
			return (tonumber(a:match("%d+")) or 0) < (tonumber(b:match("%d+")) or 0)
		else
			return a:upper() < b:upper()
		end
	end)
	
	if ApplyOrder then
		for i,v in List do
			if typeof(v) ~= 'Instance' or not v:IsA('GuiObject') then continue end
			v.LayoutOrder = i
		end
	end
	return List
end