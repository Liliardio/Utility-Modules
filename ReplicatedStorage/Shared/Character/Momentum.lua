-- @ScriptType: ModuleScript
--!strict

--[[
	@param Character Model
	@param AnimTrack AnimationTrack
	@returns {
		Clean: () -> ();
		Momentum: Vector3;
		Position: Vector3;
	}

	Tracks the momentum and the center of said momentum from the animation(s) playing.
	Returns a table containing the calculated values and a 'Clean' function to stop the tracking.
]]
return function(Character: Model, AnimTrack: AnimationTrack): {Clean: () -> (), Momentum: Vector3, Position: Vector3}
	-- Services
	local RunService = game:GetService("RunService")

	-- Variables
	local Data: {[BasePart]: {LastPosition: Vector3}} = {}
	local History: {number} = {}
	local MaxFrames = 10

	local Connection: RBXScriptConnection

	local Tracker = {
		Momentum = Vector3.new(),
		Position = Vector3.new(),
	}

	-- Clean Up
	function Tracker.Clean()
		Connection:Disconnect()
		-- Clear table to prevent memory leaks if references are held
		for k in (Tracker) do
			Tracker[k] = nil
		end
	end
	
	-- Pre-populate the Data table with initial positions
	for _, Part: Instance in Character:GetDescendants() do
		if Part:IsA("BasePart") then
			Data[Part] = { LastPosition = Part.Position }
		end
	end

	Connection = RunService.Stepped:Connect(function(Time: number, DeltaTime: number)
		if not Character.PrimaryPart then return end
		local Torso = Character.PrimaryPart

		-- If the animation is no longer running or the character is invalid, clean up and stop.
		if not AnimTrack.IsPlaying or not Torso then
			Tracker.Clean()
			return
		end

		local Total = Vector3.new()
		local Sum = Vector3.new()
		local MagnitudeSum = 0

		-- Calculate momentum for each individual body part
		for Part: BasePart, Data: {LastPosition: Vector3} in Data do
			if Part and Part.Parent then -- Ensure part still exists
				local Displacement = Part.Position - Data.LastPosition
				local TotalVelocity = Displacement / DeltaTime
				local PhysicsVelocity = Part.AssemblyLinearVelocity

				-- Isolate the velocity from the animation and calculate momentum for this part
				local AnimationVelocity = TotalVelocity - PhysicsVelocity

				-- Accumulate totals to find the center of momentum
				Total += AnimationVelocity
				Sum += Part.Position * AnimationVelocity.Magnitude
				MagnitudeSum += AnimationVelocity.Magnitude

				-- Update last known position for the next frame
				Data.LastPosition = Part.Position
			end
		end

		-- Calculate the center of momentum, which is our ideal impact position
		if MagnitudeSum > 0 then
			Tracker.Position = Sum / MagnitudeSum
		else
			Tracker.Position = Torso.Position -- Default to torso if there's no momentum
		end

		-- --- Momentum Smoothing ---
		local MomentumMagnitude = Total.Magnitude
		table.insert(History, MomentumMagnitude)
		if #History > MaxFrames then
			table.remove(History, 1)
		end

		local  MaxMomentum = 0
		for _, MomentumMagnitude: number in History do
			 MaxMomentum = math.max( MaxMomentum, MomentumMagnitude)
		end

		-- Ensure momentum does not drop below 75% of the recent peak
		local Floor =  MaxMomentum * 0.75
		if MomentumMagnitude < Floor and MomentumMagnitude > 0 then
			-- If momentum dropped, scale it up to the floor value while preserving direction
			Tracker.Momentum = Total.Unit * Floor
		else
			Tracker.Momentum = Total
		end
	end)

	return Tracker
end
