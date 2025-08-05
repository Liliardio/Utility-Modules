-- @ScriptType: ModuleScript
--!strict
local Attribute = {
	Increment = function(Object: Instance, Data: {[string]: number | boolean})
		for Attribute, Amount in Data do
			if type(Object:GetAttribute(Attribute)) == 'number' then 
				local Current = Object:GetAttribute(Attribute) or 0
				Amount = Amount or 0

				Object:SetAttribute(Attribute, Current + Amount)
			elseif typeof(Object:GetAttribute(Attribute)) == 'boolean' then
				Object:SetAttribute(Attribute, not Amount)
			else
				warn(`Could not increment, {Attribute} is not a number or boolean.`,debug.traceback())
			end
		end
	end;
	Set = function(Object: Instance, Data: {[string]: any})
		for Key, Value in Data do
			Object:SetAttribute(Key, Value ~= 'nil' and Value or nil)
		end
	end;
	Get = function(Object: Instance, ...: string): any
		local Data = {...}

		for i, Attribute in Data do
			Data[i] = Object:GetAttribute(Attribute)
		end

		return table.unpack(Data)
	end,
	Remove = function(Object: Instance, ...: string)
		for i, Attribute in {...} do
			Object:SetAttribute(Attribute,nil)
		end
	end,
	Check = function(Object: Instance, Data: {[string]: any}): boolean
		for Key, Value in Data do
			if Object:GetAttribute(Key) ~= (if Value ~= 'nil' then Value else nil) then
				return false
			end
		end
		
		return true
	end,
}

Attribute.Step = Attribute.Increment

return Attribute