-- @ScriptType: ModuleScript
--!strict
-- Services
local RunService = game:GetService("RunService")

-- Variables
local BaseSpeed = 25 -- Default movement speed in studs/second

-- Helper Functions
local function Bezier(t: number, p0: Vector3, p1: Vector3, p2: Vector3): Vector3
	local u = 1 - t
	local tt = t * t
	local uu = u * u
	local p = (uu * p0) + (2 * u * t * p1) + (tt * p2)
	return p
end

--[[
    @description Creates and manages a controlled jump arc for a character using physics constraints.
    @param Character: Model - The character model that will perform the jump.
    @param Data { - A table defining the jump's properties. 
    	Duration: number?; - How long should it last?
    	Height: number?; - How high?
    	Distance: number?; - How Far?
    	Target: Vector3?; - Target?
    }
    @returns {Clean: function}? - A handle object with a :Clean() method to prematurely cancel the jump and restore the character's state.
]]
return function(Character: Model, Data: {Duration: number?; Height: number?; Distance: number?; Target: (Vector3 | PVInstance | CFrame)?; })
	local Root, Humanoid = Character.PrimaryPart :: BasePart, Character:FindFirstChildWhichIsA('Humanoid') :: Humanoid
	assert(Root and Humanoid, `{Character} needs a valid PrimaryPart & Humanoid`)

	local Dive = {
		Connections = {};
		Attachment = Instance.new('Attachment', Root);
		Position = Instance.new('AlignPosition');
	}

	function Dive:Clean()
		for i,v in self.Connections :: {RBXScriptConnection} do
			pcall(v.Disconnect,v)
		end

		table.clear(self.Connections :: {RBXScriptConnection})

		for i,v in self do
			if typeof(v) == 'Instance' then
				pcall(v.Destroy,v)
			end
		end
	end

	local p0 = Root.Position
	local p2: Vector3

	if Data.Target then
		p2 = (typeof(Data.Target) == 'CFrame' and Data.Target.Position
			or typeof(Data.Target) == 'Instance' and Data.Target:GetPivot().Position
			or Data.Target) :: Vector3
	else
		local Distance = Data.Distance or 25
		p2 = Root.CFrame:PointToWorldSpace(Vector3.new(0, 0, -Distance))
	end

	local p1 = (p0 + p2) / 2 + Vector3.new(0, Data.Height or 15, 0)

	-- Determine the duration for the jump if it's not provided.
	local Duration = Data.Duration :: number
	
	if not Duration then
		local Distance = (Vector3.new(p2.X, 0, p2.Z) - Vector3.new(p0.X, 0, p0.Z)).Magnitude
		Duration = Distance > 0.1 and Distance / BaseSpeed or 0.1
	end

	do -- Align Position properties
		Dive.Position.Attachment0 = Dive.Attachment
		Dive.Position.MaxAxesForce = Vector3.new(100000, 100000, 100000) -- Avoid clipping through walls
		Dive.Position.Responsiveness = 25
		Dive.Position.MaxVelocity = 200
		Dive.Position.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		Dive.Position.Mode = Enum.PositionAlignmentMode.OneAttachment
		Dive.Position.ForceRelativeTo = Enum.ActuatorRelativeTo.Attachment0
		Dive.Position.Position = Root.Position
		Dive.Position.Parent = Root
	end

	local Start = os.clock()
	Dive.Connections.Update = RunService.PreSimulation:Connect(function()
		local Time = os.clock() - Start)
		local Alpha = math.min(Time / Duration, 1)

		local targetPosition = Bezier(Alpha, p0, p1, p2)
		Dive.Position.Position = targetPosition

		if Alpha >= 1 then
			Dive:Clean()
		end
	end)

	return Dive
end
