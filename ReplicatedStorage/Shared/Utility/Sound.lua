-- @ScriptType: ModuleScript
--!strict
local Audios = game:GetService('ReplicatedStorage').Assets:FindFirstChild('Audios') or Instance.new('Folder')
local Create = require('./Create')

if not Audios.Parent then
	Audios.Name = 'Audios'
	Audios.Parent = game:GetService('ReplicatedStorage').Assets
end

type SoundProperties = {
	Name: string?,
	Parent: Instance?,

	PlaybackSpeed: number?,
	Volume: number?,
	Looped: boolean?,
	TimePosition: number?,
	SoundId: string?,

	RollOffMode: Enum.RollOffMode?,
	RollOffMaxDistance: number?,
	RollOffMinDistance: number?,
	[string]: any -- Account for anything missing + ClassName
}?

type SoundPresets = {
	Preset: string | {Sound} | Folder?;
	Once: boolean?;
}?

--[[
	Creates and configures a Sound instance from a settings table.
	OR
	Plays a specific sound preset, either by passing through a Sound, a Folder of sounds, or the Name of an Instance in Audios.

	A `Once = true` setting will destroy the sound after it finishes playing.
	Giving the sound a "Start" or "JumpTo" attribute will make it play at that time.

	@param Settings The configuration table for the sound.
	@return The configured Sound instance.
]]
local SFX = function (Settings: SoundProperties & SoundPresets): Sound
	assert(type(Settings) == 'table','Provided settings is not a table')
	local R = Random.new()
	local Sound: Sound
	
	if Settings.Preset then
		if type(Settings.Preset) == 'string' then
			local Preset = Audios:FindFirstChild(Settings.Preset, true) -- Search for the first matching Instance or Container
			
			if Preset then
				if Preset:IsA('Sound') then
					Sound = Preset
				else
					local Audios = Preset:GetChildren() :: {Sound}
					R:Shuffle(Audios)
					Sound = Audios[1]
				end
			end
		elseif type(Settings.Preset) == 'table' then -- Shuffle, return first sound.
			R:Shuffle(Settings.Preset)
			Sound = Settings.Preset[1] :: Sound
		elseif typeof(Settings.Preset) == 'Instance' then -- Probably won't ever use this, but threw it in as an edge case
			if Settings.Preset:IsA('Sound') then
				Sound = Settings.Preset :: Sound
			else
				local Audios = Settings.Preset:GetChildren() :: {Sound}
				R:Shuffle(Audios)
				Sound = Audios[1]
			end
		end
	else
		Settings.ClassName = 'Sound';
		Sound = Create(Settings :: {[string]: any}) :: Sound
	end
	
	if Sound:GetAttribute('Start') or Sound:GetAttribute('JumpTo') then
		Sound.TimePosition = Sound.Playing and (Sound:GetAttribute('Start') or Sound:GetAttribute('JumpTo'))
			or Sound.TimePosition
		
		for i,v in {Sound.Played,Sound.DidLoop} :: {RBXScriptSignal} do
			v:Connect(function()
				Sound.TimePosition = Sound:GetAttribute('Start') or Sound:GetAttribute('JumpTo')
			end)
		end
	end

	if Settings.Once then
		for i,v in {Sound.Ended,Sound.DidLoop,Sound.Stopped} :: {RBXScriptSignal} do
			v:Once(function()
				pcall(game.Destroy,Sound)
			end)
		end
	end

	return Sound
end


return SFX