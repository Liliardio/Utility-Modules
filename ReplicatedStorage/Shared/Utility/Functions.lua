-- @ScriptType: ModuleScript
--!strict
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Type = 'Functions'
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
return function (Name: string, Local: boolean?, ...: any | (Player: Player?, ...any) -> (boolean)): (RemoteFunction & BindableFunction) | any
	local Folder = Local and LocalFolder or SharedFolder
	local Function: BindableFunction & RemoteFunction = (Folder:FindFirstChild(Name) or not Local and not RunService:IsServer() and Folder:WaitForChild(Name))
	or Instance.new(Local and 'BindableFunction' or 'RemoteFunction')

	if not Function.Parent then
		Function.Name = Name
		Function.Parent = Folder
	end

	local Arguments = {...}

	if type(Arguments[1]) == 'function' then
		if Local then
			Function.OnInvoke = (...)
		elseif RunService:IsClient() then
			Function.OnClientInvoke = (...)
		else
			Function.OnServerInvoke = (...)
		end
	elseif Arguments[1] then
		if Local then
			return Function:Invoke(...)
		elseif RunService:IsClient() then
			return Function:InvokeServer(...)
		elseif typeof(Arguments[1]) == 'Instance' and Arguments[1]:IsA('Player') then
			return Function:InvokeClient(... :: Player | any)
		end
	end

	return Function
end
