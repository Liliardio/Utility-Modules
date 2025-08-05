-- @ScriptType: ModuleScript
--!strict
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Type = 'Events'
local Main = ReplicatedStorage:FindFirstChild(Type) or Instance.new('Folder')
Main.Name = Type
Main.Parent = ReplicatedStorage

local LocalFolder = Main:FindFirstChild('Local') or Instance.new('Folder')
LocalFolder.Name = 'Local'
LocalFolder.Parent = Main

local SharedFolder = Main:FindFirstChild('Shared') or Instance.new('Folder')
SharedFolder.Name = 'Shared'
SharedFolder.Parent = Main

-- Couldn't get the overload to work, so just return a merge of both properties
return function (Name: string, Local: boolean?, ...: any | (Player: Player?, ...any) -> ()): (RemoteEvent & BindableEvent)
	local Folder = Local and LocalFolder or SharedFolder
	local Event: RemoteEvent & BindableEvent = (Folder:FindFirstChild(Name) or not Local and not RunService:IsServer() and Folder:WaitForChild(Name))
		or Instance.new(Local and 'BindableEvent' or 'RemoteEvent')

	if not Event.Parent then
		Event.Name = Name
		Event.Parent = Folder
	end

	local Arguments = {...}

	if type(Arguments[1]) == 'function' then
		if Local then
			Event.Event:Connect(... :: any)
		elseif RunService:IsClient() then
			Event.OnClientEvent:Connect(... :: any)
		else
			Event.OnServerEvent:Connect(... :: any)
		end
	elseif Arguments[1] then
		if Local then
			Event:Fire(...)
		elseif RunService:IsClient() then
			Event:FireServer(...)
		elseif typeof(Arguments[1]) == 'Instance' and Arguments[1]:IsA('Player') then
			Event:FireClient(... :: Player | any)
		else
			Event:FireAllClients(...)
		end
	end

	return Event
end