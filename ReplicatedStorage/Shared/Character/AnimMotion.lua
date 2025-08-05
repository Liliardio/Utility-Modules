-- @ScriptType: ModuleScript
--!strict
local RunService = game:GetService("RunService")


return function(Character: Model, AnimTrack: AnimationTrack)
	local Torso = Character and (Character:FindFirstChild('LowerTorso') or Character:FindFirstChild('Torso')) :: BasePart
	local RootJoint = (Torso:FindFirstChild('Root') or Character.PrimaryPart and Character.PrimaryPart:FindFirstChild('RootJoint')) :: Motor6D

	assert(Torso, 'Torso was not provided.')
	assert(RootJoint, 'Root Joint could not be detected.')
	assert(AnimTrack, 'AnimationTrack was not provided.')

	local Motion = {
		Placement = Torso.CFrame * RootJoint.C1 * RootJoint.C0:Inverse();
	}

	Motion.GetOffset = function()
		Motion.Placement = Torso.CFrame * RootJoint.C1 * RootJoint.C0:Inverse();
		return Motion.Placement
	end;
	
	Motion.AtTime = function(Time: number): CFrame
		AnimTrack:Play(0,1,0)
		AnimTrack.TimePosition = Time or AnimTrack.Length * 0.999
		Motion.Placement = Motion.GetOffset()
		return Motion.Placement
	end;
	
	Motion.Track = function(): RBXScriptConnection
		Motion.Connection = Motion.Connection or RunService.PreRender:Connect(function()
			if not AnimTrack.IsPlaying then return Motion.Connection:Disconnect() end

			Motion.Placement = Motion.GetOffset()
		end)
		return Motion.Connection
	end;
	
	Motion.MoveTo = function(Clean: boolean): ()
		local Placement = Motion.Placement
		if Motion.Connection then
			pcall(Motion.Connection.Disconnect,Motion.Connection)
		end
		AnimTrack:Play(0,1,0)
		AnimTrack.TimePosition = AnimTrack.Length
		AnimTrack:Stop(0)


		Character:PivotTo(Placement)
		Torso.CFrame = Placement * RootJoint.C0 * RootJoint.C1:Inverse()
		Motion.Clean()
	end;
	
	Motion.Clean = function(): ()
		if not Motion.Connection then return end
		Motion.Connection:Disconnect()
		AnimTrack:Destroy()
		table.clear(Motion)
	end;

	return Motion
end