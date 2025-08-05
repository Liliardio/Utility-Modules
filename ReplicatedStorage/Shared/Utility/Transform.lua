-- @ScriptType: ModuleScript
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Module = {}

Module.GetCFrame = function(...: any): CFrame
	local Positions = {...}

	for i, Obj in Positions do
		if typeof(Obj) == 'Instance' then
			Obj = Obj:IsA("Player") and Obj.Character
				or Obj:IsA('PVInstance') and Obj
			return Obj and Obj:GetPivot()
				or error(`Could not convert {Obj} into a CFrame`, 2)
		end

		Positions[i] = typeof(Obj) == 'CFrame' and Obj
			or typeof(Obj) == "Vector3" and CFrame.new(Obj)
			or error(`Could not convert {Obj} into a CFrame`, 2)
	end

	return table.unpack(Positions) :: CFrame
end;

Module.GetPosition = function(...: any): Vector3
	local Positions: {any} = table.pack(Module.GetCFrame(...))

	for i,v in Positions do
		if not Positions then continue end
		Positions[i] = if type(i) ~= 'number' then nil else v.Position
	end

	return table.unpack(Positions) :: Vector3
end;


Module.LookAt = function(Object1: any,Object2: any)
	local P1,P2 = Module.GetPosition(Object1), Module.GetPosition(Object2)
	return CFrame.lookAt(P1,P2)
end;

Module.Magnitude = function(Obj1: any, Obj2: any): number
	return Obj2 and (Module.GetPosition(Obj1) - Module.GetPosition(Obj2)).Magnitude
		or typeof(Obj1) == "Instance"
		and Obj1:IsA("BasePart")
		and (Obj1.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
end;

Module.GetDirection = function <T> (LookAt: Vector3, Directions: T): keyof <T>
	local Name: any
	local Closest: Vector3?

	for i, v in Directions :: {[string]: Vector3} do
		if not Closest or Closest:Angle(LookAt) > v:Angle(LookAt) then
			Closest = v
			Name = i
		end
	end

	return Name
end;

return Module