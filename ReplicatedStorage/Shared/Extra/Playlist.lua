-- @ScriptType: ModuleScript
--!strict
local CollectionService = game:GetService('CollectionService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

local RandomGenerator = Random.new()

type DefaultSettings = {
	DelayTime: number;
	FadeTime: number;
	Volume: number;
	IsActive: BoolValue?;
	Folder: Instance?;
}

type PlaylistConfig = {
	Parent: Instance? | nil;
	Playlist: Folder;
	Settings: DefaultSettings? | nil;
	Full: {string | Sound}?
}

type FinalSettings = DefaultSettings & {
	Start: () -> ();
	Stop: () -> ();
}

local DefaultSettings: DefaultSettings = {
	DelayTime = 60;
	FadeTime = 1;
	Volume = 0.5;
}

--[[
	Initializes the music playlist system.

	@param config Table: A configuration table for the playlist.
		- Parent Instance?: An optional parent for the sound instances.
		- Playlist Folder: The folder containing the playlist songs and the IsActive BoolValue.
		- Settings typeof(DefaultSettings)?: Optional settings to override the default.
	@return table: The active settings for the playlist, including Start and Stop functions.
]]
local function InitPlaylist(config: PlaylistConfig): FinalSettings
	assert(typeof(config) == 'table', 'InitPlaylist: config must be a table.')

	local Playlist = config.Playlist
	local ActiveSettings: FinalSettings = table.clone(DefaultSettings) :: FinalSettings

	-- Apply provided settings, ensuring Folder and IsActive are correctly set
	if config.Settings then
		for key, value in config.Settings do
			if ActiveSettings[key] ~= nil then -- Only override existing default settings
				ActiveSettings[key] = value
			end
		end
	end

	ActiveSettings.Folder = Playlist
	local IsActive = Instance.new('BoolValue')
	ActiveSettings.IsActive = IsActive
	IsActive.Name = 'IsActive'
	Playlist.Parent = config.Parent or Playlist.Parent

	-- Ensure IsActive is initially false as per original logic
	IsActive.Value = false

	local CurrentSong: Sound? = nil
	local CurrentTween: Tween? = nil
	local CurrentPlayTicket: number = 0 -- Used to prevent old tasks from interfering
	local FolderChangeConnection: RBXScriptConnection? = nil

	--[[
		Applies necessary tags and properties to a sound instance.

		@param audio Sound: The sound instance to process.
	]]
	local function ProcessSound(audio: Sound)
		if not audio:IsA('Sound') then return end

		audio:AddTag('PlaylistSongs')
		if audio:GetAttribute('Intro') then
			audio:AddTag('PlaylistIntros')
		end
		audio.Volume = 0
		audio:Pause()
		audio.Looped = true
	end

	--[[
		Handles new sounds being added to the songs container.

		@param child Instance: The child added to the container.
	]]
	local function OnChildAdded(child: Sound)
		ProcessSound(child)
	end

	--[[
		Handles sounds being removed from the songs container.

		@param child Instance: The child removed from the container.
	]]
	local function OnChildRemoved(child: Instance)
		if child:IsA('Sound') then
			child:RemoveTag('PlaylistSongs')
			child:RemoveTag('PlaylistIntros')
		end
	end

	--[[
		Resets the playlist, clearing current song and stopping any active tweens.
	]]
	local function ResetPlaylist()
		if CurrentTween then
			CurrentTween:Cancel()
			CurrentTween = nil
		end
		if CurrentSong then
			CurrentSong:Pause()
			CurrentSong.Volume = 0
			CurrentSong = nil
		end
		CurrentPlayTicket = CurrentPlayTicket + 1 -- Invalidate any pending play tasks

		-- Stop all sounds in the container
		for _, sound in Playlist:GetChildren() do
			if sound:IsA('Sound') then
				sound:Pause()
				sound.Volume = 0
			end
		end
	end

	--[[
		Finds and plays the next song in the playlist.

		@param NextSong Sound?: The specific song to play next (optional).
	]]
	local function FindAndPlaySong(NextSong: Sound?)
		if not ActiveSettings.IsActive.Value then
			return
		end

		local playTicket = CurrentPlayTicket

		local allPlaylistSongs = CollectionService:GetTagged('PlaylistSongs')
		if not NextSong then
			if #allPlaylistSongs == 0 then
				warn("No songs found in playlist.")
				ResetPlaylist()
				return
			end
			NextSong = allPlaylistSongs[RandomGenerator:NextInteger(1, #allPlaylistSongs)] :: Sound
		end

		if not NextSong or not NextSong:IsA('Sound') then
			warn("Invalid song selected for playback.")
			return
		end

		if CurrentSong and CurrentSong ~= NextSong then
			local lastSong = CurrentSong
			local fadeOutInfo = TweenInfo.new(ActiveSettings.FadeTime, Enum.EasingStyle.Sine)
			local fadeOutTween = TweenService:Create(lastSong, fadeOutInfo, {Volume = 0})

			if CurrentTween then CurrentTween:Cancel() end -- Cancel previous tween if any
			CurrentTween = fadeOutTween

			fadeOutTween:Play()

			-- Check playTicket to ensure this is still the active playback request
			fadeOutTween.Completed:Connect(function(state: Enum.PlaybackState)
				if playTicket ~= CurrentPlayTicket then return end
				lastSong:Pause()
				if CurrentTween == fadeOutTween then CurrentTween = nil end
			end)
		else
			-- If no current song or playing the same song, just cancel old tween
			if CurrentTween then CurrentTween:Cancel() end
			CurrentTween = nil
		end

		-- Play the new song
		NextSong:Play()
		local fadeInInfo = TweenInfo.new(ActiveSettings.FadeTime, Enum.EasingStyle.Sine)
		local fadeInTween = TweenService:Create(NextSong, fadeInInfo, {Volume = ActiveSettings.Volume})

		if CurrentTween then CurrentTween:Cancel() end -- Cancel any previous tween that might be running
		CurrentTween = fadeInTween

		fadeInTween:Play()

		fadeInTween.Completed:Connect(function(state)
			if playTicket ~= CurrentPlayTicket then return end
			if state == Enum.TweenStatus.Completed then
				if CurrentTween == fadeInTween then CurrentTween = nil end
			end
		end)

		CurrentSong = NextSong

		local delayTime = ActiveSettings.DelayTime
		if CurrentSong and (delayTime <= 0 or config.Full and (table.find(config.Full, CurrentSong) or table.find(config.Full, CurrentSong.Name))) then -- Fallback to song length if DelayTime is zero or negative
			delayTime = CurrentSong.TimeLength
		end

		task.delay(delayTime, function()
			if playTicket ~= CurrentPlayTicket then return end
			FindAndPlaySong()
		end)
	end

	--[[
		Initializes and manages the playback state based on IsActive.
	]]
	local function RunPlaylist()
		ResetPlaylist() -- Always reset when state changes or folder changes

		if ActiveSettings.IsActive.Value then
			local intros = CollectionService:GetTagged('PlaylistIntros')
			local initialSong = #intros > 0 and intros[RandomGenerator:NextInteger(1, #intros)] or nil
			FindAndPlaySong(initialSong)
		end
	end

	-- Initial processing of all sounds in the container
	for _, child in Playlist:GetChildren() do
		ProcessSound(child)
	end

	-- Connect to children changes in the songs container
	Playlist.ChildAdded:Connect(OnChildAdded)
	Playlist.ChildRemoved:Connect(OnChildRemoved)

	-- Detect changes to the Playlist folder's descendants to trigger a reset
	-- This helps catch if songs are added/removed directly or if the folder itself is replaced
	FolderChangeConnection = Playlist.DescendantAdded:Connect(function(descendant)
		if descendant:IsA('Sound') then
			RunPlaylist()
		end
	end)
	Playlist.DescendantRemoving:Connect(function(descendant)
		if descendant:IsA('Sound') then
			RunPlaylist()
		end
	end)

	-- Connect to IsActive value changes
	ActiveSettings.IsActive.Changed:Connect(RunPlaylist)

	-- Initial run to set up the playlist based on the current IsActive state
	RunPlaylist()

	--[[
		Updates local player's volume based on MutePlaylist attribute.

		@param audio Sound: The sound instance to adjust volume for.
	]]
	local function UpdateLocalVolume(audio: Sound)
		if not audio:IsA('Sound') then return end
		local localPlayer = game.Players.LocalPlayer
		if localPlayer and audio.IsPlaying then
			if localPlayer:GetAttribute('MutePlaylist') then
				audio.Volume = 0
			else
				-- Only apply the volume if not currently tweening to 0 (e.g., during fade out)
				-- This is a heuristic and might need fine-tuning depending on desired behavior
				if CurrentSong == audio and CurrentTween and CurrentTween.TweenInfo.Goal.Volume == 0 then
					-- Do nothing, let the tween handle it
				else
					audio.Volume = ActiveSettings.Volume
				end
			end
		end
	end

	-- Connect to sounds added by CollectionService
	CollectionService:GetInstanceAddedSignal('PlaylistSongs'):Connect(UpdateLocalVolume)

	-- Apply initial local volume settings to all existing playlist songs
	for _, sound in CollectionService:GetTagged('PlaylistSongs') do
		UpdateLocalVolume(sound)
		-- Also connect to volume property changes for individual sounds if needed, but typically managed by the system
		sound:GetPropertyChangedSignal('Volume'):Connect(function()
			UpdateLocalVolume(sound)
		end)
	end

	--[[
		Starts the playlist by setting the IsActive property to true.
	]]
	function ActiveSettings.Start()
		ActiveSettings.IsActive.Value = true
	end

	--[[
		Stops the playlist by setting the IsActive property to false.
	]]
	function ActiveSettings.Stop()
		ActiveSettings.IsActive.Value = false
	end

	-- Return the active settings for potential external use/monitoring
	return ActiveSettings
end

return InitPlaylist