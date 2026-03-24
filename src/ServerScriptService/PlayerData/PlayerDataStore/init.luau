--[[

	PlayerDataStore Module
	Author: Ranu - Roblox User: @RanuRbx (3267747943)
	DevForum Thread: https://devforum.roblox.com/t/playerdatastore/3926077
	
	-- Your Player Default Template Data is in DefaultData ModuleScript.
	-- Reconciliation happens automatically.
	
	-- We begin with explaining reference here as we'll need it soon.
	
	-- Reference meaning:
	--   - If "reference" is mentioned anywhere, it means it comes with the
	--     original source, object, or data that can be directly used or
	--     looked up.
	--   - A reference is not a copy — it points to the existing value or
	--     instance, so changes to the original are reflected in the
	--     reference as well.
	--   - This is useful when working with Roblox instances, tables,
	--     or other objects that should not be duplicated.
	
	-- Reference Here comes with tables, not primitive values such as numbers, booleans, strings.
	
	-- Example of Reference:
	
	Example #1:
	--print(PlayerDataStore:GetData(player))
	-- all of these changes will be saved directly in the cache
	--PlayerDataStore:GetData(player).Test = {}
	--PlayerDataStore:GetValue(player, "Test").TestInisde = true
	--PlayerDataStore:GetData(player).Test.TestInside = false
	
	Example #2
	--local OfflineLoadedData = PlayerDataStore:LoadOfflineData(3267747943)
	--print(OfflineLoadedData)
	 -- all of these changes will be saved directly in the cache
	--OfflineLoadedData.Hi = {}
	--OfflineLoadedData.Hi2 = {}
	--OfflineLoadedData.Hi3 = false
	--OfflineLoadedData.Hi4 = 6
	--PlayerDataStore:SaveOfflineData(3267747943, OfflineLoadedData)
	
	The difference between these and SetValue, etc is that SetValue supports both online and offline modes.
	
	Note: For Mass Operations (more than a single operation) especially if they're offline:
		Use UpdateData Instead of (SetValue / Manually LoadOfflineData/SaveOfflineData).
	
	
	Note: GetValue, FetchValue, SetValue, Increment, RemoveKey support (Nested key path).
	
	Example:
		:SetValue(player, "d", "b,", "c", true)
	is equivalent to
		usercacheddata.d.b.c = true

	Note: SetValue, Increment, RemoveKey, UpdateData (support offline/online modes)
	Note: GetData, GetValue, HasData, WaitForData only accept player instance (not userid)
	Note: EraseUserData only supports userids and they shouldn't be in the game / other servers.
	- EraseUserData was introduced for GDPR laws.
	
	Note: Most functions yield.
	
	Functions:
	
	* DataStoreModule.BindToLeave(callback: LeaveCallback): LeaveConnection
		
	1. GetData(player: Player, no_wait: boolean?): table?	[comes with Reference]
	   - Returns the full data table for the player.
	   - Returns nil if data is not loaded.
	
	2. GetValue(player: Player, ...: string): (any, boolean)	[can come with Reference]
	   - Returns the value for a specific key in the player's data.
	   - Returns nil if data not loaded or key doesn't exist.
	   - Second return value is false if the player's data wasn't loaded, otherwise true.
	   
	   # Recommended to Use Instead #
	2.5. FetchValue(player: Player | number | string, ...: string): any	[can come with Reference]
	   - Retrieves a nested value from a player's offline data.
	   - If they are online in the server, then it will use their current cached data from the server.
	   - Accepts a Player instance, userId (number), or userId (string).
	   - If the player is currently online, falls back to GetValue.
	   - Returns nil if data is missing or the key path does not exist.
	   
	3. SetValue(player: Player | number | string, ...: any)
		- Sets a nested value inside the player's session data or offline data using a variable number of keys.
		- The first argument can be a Player instance, a userId number, or a userId string.
		- The following arguments are one or more keys followed by the final value to set.
		- If the player is online, waits for their data to load; if data is not loaded, returns early without setting.
		- If the player is offline, loads their offline data, applies the nested set, saves the data, and publishes a message for synchronization.
		- Returns true on success; otherwise returns nil.

	4. UpdateData(player: Player | number | string, changes: table)
		- Applies multiple updates to the player's session data or offline data in one call.
		- The first argument can be a Player instance, a userId number, or a userId string.
		- The second argument is a table of key/value pairs representing updates.
		- Nested tables are supported, and will automatically create intermediate tables if they do not exist.
		- If the player is online, waits for their data to load and applies all changes in memory.
		- If the player is offline, loads their offline data, applies all changes, saves the data once,
		  and publishes a "BulkUpdate" message for synchronization.
		- Returns true if all updates were successfully applied; otherwise returns false.
	
	5. Increment(player: Player | number | string, ...: any) -- returns true if succeeded
	   - Increments a nested numeric key by the specified amount.
	   - Initializes missing nested structure and key to 0 if needed.
	   - Supports both online and offline data (if OfflineModeEnabled).
	   - Does nothing if data is not loaded or unavailable.
	   - Returns true on success; otherwise returns nil.
	   
	6. Insert(player: Player | number | string, ...: any): boolean?
	    - Inserts a value into a nested table inside the player's session data or offline data.
	    - The first argument can be a Player instance, a userId number, or a userId string.
	    - The following arguments are one or more keys specifying the nested path followed by the value to insert.
	        • All keys except the last argument must resolve to a table.
	        • The last argument is the value that will be appended to the table.
	    - If the player is online, waits for their data to load; if the path does not resolve to a table, the insertion fails.
	    - If the player is offline, loads their offline data, appends the value to the nested table, saves the data, and publishes an "Insert" message for synchronization.
	    - Returns true if the insertion was successful, false if the value already exists or insertion failed, or nil if data is unavailable.

	7. QueueInsert(player: Player | number | string, tbl: any, offlineModeOnly: boolean?): boolean?
	   - Adds a value or table to the player's queue (`__meta.QueueTbl`) in session or offline data.
	   - Waits for session data if the player is online (unless `offlineModeOnly` is true).
	   - For offline data, loads, inserts, saves, and publishes a "QueueInsert" message for synchronization.
	   - Returns true if inserted successfully, false if insertion failed.
	   
	   * :GetQueueTbl(player: Player | number | string): { { GUID: string, Info: any } }?
	
	8. HasData(player: Player): boolean
	   - Returns true if player data is loaded in session cache, else false.
	
	9. RemoveKey(player: Player | number | string, ...: any) -- returns true if succeeded
	   - Removes a specific nested key from the player's data.
	   - Works for both online and offline players:
	     • If the player is online and session data is loaded, it modifies sessionData.
	     • If the player is offline, it loads and updates the offline data file.
	   - Does nothing if data is not loaded or path is invalid.
	   - Returns true on success; otherwise returns nil.
	   
  	10. * GDPR Compliance - Right to Erase User Data:
		:EraseUserData(userId: number | string)
		
		
	>> Advanced From Here <<
	
	* (Advanced) :WaitForData(player: Player, timeout: number?): boolean
	    - Waits for player data to be loaded or timeout (default 15s).
	    - Returns true if data is loaded and player still in game; false otherwise.
	    
	* (Advanced) :Reconcile(player: Player | number | string, data) : boolean
	* (Advanced) :GetDefaultTemplate() : typeof(Template)
	* (Advanced) :_DontSaveOnLeaveForPlayer(player: Player | number | string) : boolean
	    
	* (Advanced) Specific Offline Datastore Functions:
		:LoadOfflineData(player: Player | number | string, doNotLock: boolean?)	[can come with Reference]
		:SaveOfflineData(player: Player | number | string, data: any, forced: boolean?)
		
		(Online / Offline)
		:FetchValue(player: Player | number | string, ...: string): any	[can come with Reference]
		
	* IMPORTANT: If you're going to use the 3 functions above, during modification, It's recommended to also call
		DataStoreModule:_PublishMessage for example:
			DataStoreModule:_PublishMessage("SetValue", userId, GUID, args)
			
			ex: DataStoreModule:_PublishMessage("SetValue", userId, GUID, "Test1", "InsideTest", true)
			
		^^ It's needed to publish the changes to other servers in case the player is in the other servers ^^
		
	To stay away from all of the hassle, you can just use UpdateData method.
		
		
	>> Do NOT Use those that start with an underscore (TOO ADVANCED) <<
	
	^ _LoadData(player: Player) -- returns a dictionary of the player's data
	   - Loads the player's data from the DataStore and initializes session cache.
	   - Kicks player if data lock cannot be acquired or loading fails.
	
	^ _SaveData(player: Player, ReleaseLock: boolean?)
	   - Saves the player's current session data back to the DataStore.
	   - Optional ReleaseLock to release the data lock (not recommended to call manually).
	
	^ _RemovePlayerCache(player: Player)
	   - Clears cached session data for the given player. (CAN LEAD TO COMPLETE USER DATA LOSS)
	
	^ _RemoveAllPlayerCache()
	    - Clears cached session data for all players. (CAN LEAD TO COMPLETE USER DATA LOSS)
	
	^ _SaveAll(ReleaseLock: boolean?)
	    - Saves all currently cached player data to the DataStore.
	    - Optionally releases all data locks.
	    
	^ _clearOfflineHandle(player: Player | number | string) : boolean
	    
	^ DataStoreModule:_PublishMessage
	^ DataStoreModule:_ReconcileDefault
	^ DataStoreModule:_handleData
	
	INFO:
		- Saving is automatic on Player Leave/Game Shutdown.
		- Autosave every 240 seconds.
		- Has Session lock, meaning it yields if multiple servers are accessing/writing to the same player datastore
			(at start when the player is just joining).
		- Player kick system is active after multiple failed attempts.
		- Uses MessageService for cross-server synchronization in offline mode (if they are in them) to update cached data there.
		
		- All data is encoded and decoded using BufferEncoder Module:
			devforum.roblox.com/t/bufferencoder-very-efficient-table-to-buffer-serializer-that-doesn%E2%80%99t-use-schemas/3584699
			
		- If ExtraDelayToLoadPlayerData Setting is enabled (enabled as default), then it'll load the players data
			after n second(s) of them joining (yields).
		
		* The Following Methods Support Offline Mode:
			- SetValue
			- UpdateData
			- Increment
			- RemoveKey
			- FetchValue
			
			- LoadOfflineData
			- SaveOfflineData
	
	WARNING:
		- All Writing Functions and Most Reading Functions yield, normally max yielding duration is around 5 seconds (max: ~10)
		- For Saving, max yielding duration is around 3.5 seconds per normal save queue.
		- WaitForData default timeout is 10 seconds.
		- If WaitForData timeout is reached and the timeout >= DefaultWaitingTimeout, it will kick out the player.
		
		- 4 MB limit per player data store (can result in error / break).
		
	CAUTION:
		- :GetValue doesn't return a reference for non-tables, that means if you edit the result of it, it won't change the actual data.
		
		Example 1: :GetValue(player, "dataEx") = true -- wouldn't change the actual data (if it is a Primitive Value)
		Example 2: However, if dataEx is a table {} and you use :GetValue(player, "dataEx").test = 100,
		then it will change the .test data inside of the actual table
		
		* If you modify any of the timeouts/cooldown/yielding timeouts, then you might need to edit some other
			hard-codded values along with it
			
		* If you can make use of :Increment instead of :SetValue, then do it
			it can prevent certain scenarios where data loss could possibly happen.
			
		* If you're expecting to GetValue a player, even after they've left,
			then make use of FetchValue instead of GetValue, it supports both Online and Offline modes.
			
		* Via Command line, if you require the DataStoreModule and use its online/WaitForData methods then it would glitch out 
			due to it not having session data for the players. 
			
	IMPORTANT: Do NOT use the advanced offline functions if the player is in the server.
	Also do NOT require the module from another state/level, such as if you have pressed Play in Studio, and then
	later you go to the Server, and from command line you require it again. (DO NOT)
	
	
	IMPORTANT: __meta. 
		____LastVersion, ____LastModuleVersion, ____BufferEncoderEverUsedOn,
		____DataCreatedAt, ____DataUpdatedAt,
		Queue, QueueTbl
		will automatically be set 
		by the module, so don't ever modify it / do not put those names into the DefaultData Template.
--]]

-- Offline Operations 
--[[

- For sensitive things such as Gifting offline players Products, you can use :QueueInsert
	- and later read the table, and read the data.
	- You have to erase data manually after.
	
- If you ever use LoadOfflineData, make sure to use SaveOfflineData after, or _clearOfflineHandle
	- otherwise it can cause issues. You have to make sure the handle gets closed.

--]]


-- Configuration

-- Note: Most of these should not be edited later, after the module being required and getting modified from there.
-- Modify it from the Studio Editor instead, and not at run-time.
local DataStoreModule = {
	DebugOnlyInStudio = false, -- Feel free to enable/disable this (affects both below if enabled)
	Debugging = true, -- Feel free to enable/disable this
	FullDebugInfo = false, -- Feel free to enable/disable this
	
	--[[
		Enable this, if you are planning to disable BufferEncoder in future (with existing data).
		
		It will tell you whether your data would get corrupted or not if you disable it.
	]]
	DebugJSON_Notes = false, -- Feel free to enable/disable this
	
	Version = "0.5.2m3", -- This should only be changed by the developer of this module
	
	--[[
		BufferEncoder is a table to buffer serializer that is designed to be as performant as possible while being able to
		serialize any type of table you want with all datatypes realistically used in tables.
		
		It automatically serializes the table for you without having to define a schema for how the table is serialized
		
		It is designed to be safe if enabled/disabled, and then changed later on.
		However, it is not recommended to change it later on.
		
		<b>WARNING</b>: If you have data types that JSON doesn't support and BufferEncoder supports, then
			if you go from Enabled to Disabled later on, it can corrupt those users' data if their data was JSON-saved.
	]]
	BufferEncoder = true, -- Recommended to be true (Enabled as default)

	MemoryStoreSessionLock = true, -- Session-locking -> Recommended to be enabled
	DisableMemoryStoreSessionLockOnStudio = true, -- Overrides above if enabled
	BeSoftOnMemoryStoreErrors = true, --[[
	If Roblox MemoryStore ever fails, then session-locking would return false for all players
	and then the module would end up not letting players in / kicking players out.
	
	If this is enabled, in case Roblox MemoryStore fails then it would let it pass and return true.
	(Would turn off session-locks for those cases)
	
	This is smartly designed, so even if its true: at first attempt it would still not let errors pass,
	however, at second attempt it would let them pass if there's MemoryStore failure still.
	
	There has been only one recorded case of this happening in history of Roblox since MemoryStore has been made,
	As of September 8th, 2025
	]]
	
	--[[ The Following 3 Configs could be useful for testing in Studio 
		such as pretending to be a 'new player' joining the game,
		in that case you could enable LoadDefaultDataAlwaysInStudio, DoNotSaveDataInStudio together.
		
		In normal circumstances you should keep them disabled.
	]]
	-- Careful, ideally the last 2 options here need the 3 options below them to be enabled.
	-- So they don't delete actual data.
	DoNotSaveDataInStudio = false, -- cancels both SaveData and SaveOfflineData
	--[[ If you are going to disable DoNotSaveDataInStudio, then you may also wanna consider 
		disabling ListenToMessageService]]
	DeleteUserDataAtLeaveInStudio = false, -- The option above it needs to be enabled for this to work.
	-- Note: The Config Above is affected by InStudioUseDifferentDataStore, so if:
	-- InStudioUseDifferentDataStore is disabled, this would delete actual data.
	LoadDefaultDataAlwaysInStudio = false, -- leads to data loss for your Studio Player Data (Note: gets executed after actual data gets loaded)
	
	--[[
		This overrides 2 of the options above and does the all the following:
			1. Enables DoNotSaveDataInStudio
			2. Enables LoadDefaultDataAlwaysInStudio
	]]
	PretendToBeNewUserInStudio = false,
	
	--[[ The following 3 configs are recommended to be enabled.
	     When enabled, the Studio Datastore/Memorystore/MGSVC of this module
	     will be separate from the Client one.
	     
	     This ensures that actions in Studio do not interfere with the Client.
	]]
	-- Should Studio Datastores be different than Client?
	-- Preferably make all the 3 true or false.
	InStudioUseDifferentDataStore = true, -- = MOCKING DATASTORE
	InStudioUseDifferentSessionLock = true, -- Different sessionlocking key from client?
	InStudioUseDifferentMessageTopic = true, -- Probably irrelevant in studio anyway
	
	-- Overrides the options above.
	--[[
		This is so if you ever wanted to require the module from there to
			do any of the following:
		1. Delete User Data
		2. Load User Offline Data
		3. Edit User Offline Data
		4. Save User Offline Data
	
		If enabled: It would affect their 'actual' (client) data even if the 3 configs above it are enabled.
		If disabled: It would affect their studio data or client data based on the 3 configs above.
		
		A case where this could be used is when Roblox due to GDPR, requests you to delete a user data,
		then in that case you would go to Studio -> Press Run, and in the command line you would execute this:
		
		local PlayerDataStore = require(Location.PlayerDataStore);
		PlayerDataStore:EraseUserData(userId)
	]]
	-- Reminder: Overrides the options above.
	EraseUser_Use_NormalDatastore_Always = true, -- So 'Actual' Users data would be resetted through Studio if used.
	Offline_Functions_Use_NormalDatastore_Always = true, -- Similar to above, it affects methods like SetValue 
	-- when its in offline. This also affects offline methods like LoadOfflineData and SaveOfflineData.
	
	--[[
		If you want to test Offline functions in Studio, and you want them to affect the Studio Datastore
			instead of the actual client data then you should temporarily disable:
				Offline_Functions_Use_NormalDatastore_Always
				
		If you want to test erasing user data in studio, and have it not affect client actual data then
			temporarily disable EraseUser_Use_NormalDatastore_Always
			
		Note: If disabled, they'll be affected by InStudioUseDifferentDataStore.
	]]

	KickPlayerOnWaitingDataTimeout = true, -- Do not touch / Should be enabled
	DefaultWaitingTimeout = 15, -- Recommended to be 15 seconds (Not recommended to be touched)

	ExtraDelayToLoadPlayerData = 1, -- 1 seconds extra delay [Recommended to have this at 1 seconds] (it can affect others)
	
	--[[
		If double messages is enabled, it sends 2 messages per offline operation instead of 1.
		
		If enabled, it can prevent very rare scenarios where cross-server data is not saved.
		If MessageService limits are important to you, you could disable this.
	]]
	DoubleMessages = true,
	
	--[[
		If these are enabled, then if you use methods like :SetValue, and even if the player is offline
		then their actual/studio data (depending on Offline_Functions_Use_NormalDatastore_Always) would be affected.
		
		This is useful if you want to edit data while the player is not in game.
		As default both are enabled.
		
		A scenario where this would be needed:
			You have a game where you can Gift Currency to other players, and when you press it,
			it first shows you a dev product to buy it, and if you buy the dev product, it gives the player the currency.
			
			However, if the player leaves the game before the dev product is bought,
				then the currency would not be given normally.
				
			With these enabled, then it would give them the currency even after they left.
		
		However, if you are not going to have anything related to 'editing offline players data' usually after they leave
		during runtime, then it's recommended to disable both configs below.
		Having these enabled with no need and improper use could lead to unintended consequences.
		
		It affects methods like :SetValue, :Increment and some other methods.
	]]
	OfflineModeEnabled = true,
	ListenToMessageService = true,
	
	-- Do not touch
	Cache = {
		Running = false,
	}
}

if DataStoreModule.PretendToBeNewUserInStudio then
	DataStoreModule.DoNotSaveDataInStudio = true
	DataStoreModule.LoadDefaultDataAlwaysInStudio = true
end

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local ServerStorage = game:GetService("ServerStorage")

local DataHandler = require(ServerStorage:WaitForChild("DataHandler"))

export type MessageActionPossibleNames = "SetValue" | "Increment" | "RemoveKey" | "BulkUpdate"

local IsStudio = RunService:IsStudio()

if DataStoreModule.DebugOnlyInStudio then
	if not IsStudio then
		DataStoreModule.Debugging = false
		DataStoreModule.FullDebugInfo = false
	end
end

-- DataStore API access check:

if IsStudio == true then
	task.spawn(function()
		local new_state = "NoAccess"

		local status, message = pcall(function()
			-- This will error if current instance has no Studio API access:
			DataStoreService:GetDataStore("____PS"):SetAsync("____PS", os.time())
		end)

		local no_internet_access = status == false and string.find(message, "ConnectFail", 1, true) ~= nil

		if no_internet_access == true then
			warn(`[{script.Name}]: No internet access - check your network connection`)
		end

		if status == false and
			(string.find(message, "403", 1, true) ~= nil or -- Cannot write to DataStore from studio if API access is not enabled
				string.find(message, "must publish", 1, true) ~= nil or -- Game must be published to access live keys
				no_internet_access == true) then -- No internet access

			new_state = if no_internet_access == true then "NoInternet" else "NoAccess"
			print(`[{script.Name}]: Roblox API services unavailable - data will not be saved`)
		else
			new_state = "Access"
			print(`[{script.Name}]: Roblox API services available - data can be saved`)
		end
	end)
end

-- Warnings for Poor Configuration
if IsStudio then
	if DataStoreModule.PretendToBeNewUserInStudio then
		print(`[{script.Name}]: PretendToBeNewUserInStudio is enabled - pretending to be a new user in Studio`)
	end
	
	if DataStoreModule.DoNotSaveDataInStudio then
		print(`[{script.Name}]: Data Saving has been disabled - data won't be saved in Studio`)
		
		if DataStoreModule.DeleteUserDataAtLeaveInStudio then
			print(`[{script.Name}]: DeleteUserDataAtLeave is enabled - player data will be deleted when they leave in Studio`)
		end
	end

	if DataStoreModule.LoadDefaultDataAlwaysInStudio then
		print(`[{script.Name}]: LoadDefaultData has been enabled - default data will be loaded for all players in Studio`)
	end
	
	if not DataStoreModule.OfflineModeEnabled then
		print(`[{script.Name}]: OfflineMode is disabled - Offline data won't be affected`)
	else
		if not DataStoreModule.ListenToMessageService then
			print(`[{script.Name}]: MessageService is disabled - offline data will not be synchronized with other servers`)
		end
	end
	
	if DataStoreModule.ExtraDelayToLoadPlayerData ~= 1 then
		print(`[{script.Name}]: ExtraDelayToLoadPlayerData is not default (1 seconds) - it is currently set to {DataStoreModule.ExtraDelayToLoadPlayerData} seconds`)
	end
	
	if DataStoreModule.DefaultWaitingTimeout ~= 15 then
		print(`[{script.Name}]: DefaultWaitingTimeout is not default (15 seconds) - it is currently set to {DataStoreModule.DefaultWaitingTimeout} seconds`)
	end
	
	if not DataStoreModule.KickPlayerOnWaitingDataTimeout then
		print(`[{script.Name}]: KickPlayerOnWaitingDataTimeout is disabled - player will not be kicked if data does not load`)
	end
	
	if not DataStoreModule.Offline_Functions_Use_NormalDatastore_Always then
		print(`[{script.Name}]: Offline_Functions_Use_NormalDatastore_Always is not the default configuration`)
	end
	
	if not DataStoreModule.EraseUser_Use_NormalDatastore_Always then
		print(`[{script.Name}]: EraseUser_Use_NormalDatastore_Always is not the default configuration`)
	end
	
	if not DataStoreModule.InStudioUseDifferentDataStore then
		print(`[{script.Name}]: InStudioUseDifferentDataStore is not the default configuration`)
	end
	
	if not DataStoreModule.InStudioUseDifferentSessionLock then
		print(`[{script.Name}]: InStudioUseDifferentSessionLock is not the default configuration`)
	end
	
	if not DataStoreModule.InStudioUseDifferentMessageTopic then
		print(`[{script.Name}]: InStudioUseDifferentMessageTopic is not the default configuration`)
	end
	
	if not DataStoreModule.BeSoftOnMemoryStoreErrors then
		print(`[{script.Name}]: BeSoftOnMemoryStoreErrors is not the default configuration`)
	end
	
	if not DataStoreModule.MemoryStoreSessionLock then
		print(`[{script.Name}]: Session-locking is disabled`)
	end
	
	if not DataStoreModule.BufferEncoder then
		print(`[{script.Name}]: BufferEncoder is not enabled`)
	end
	
	if not DataStoreModule.DoubleMessages then
		print(`[{script.Name}]: DoubleMessages is disabled`)
	end
end

local Configuration = script.Configuration

local OriginalDataStoreName = Configuration.DataStoreName.Value

local DataStoreKeyName = Configuration.PlayerDataStoreKey.Value
local DataStoreName = OriginalDataStoreName

if IsStudio then
	if DataStoreModule.InStudioUseDifferentMessageTopic then
		Configuration.MessageTopicName.Value = Configuration.MessageTopicName.Value .. "$Studio"
	end

	if DataStoreModule.InStudioUseDifferentSessionLock then
		Configuration.SessionMemoryStoreName.Value = Configuration.SessionMemoryStoreName.Value .. "$Studio"
	end
end

local MessageTopicName = Configuration.MessageTopicName.Value

local AutoSave = Configuration.AutoSave.Value
local AutoSaveInterval = Configuration.AutoSaveEverySecond.Value

local RefreshSessionsEverySecond = Configuration.RefreshSessionsEverySecond.Value

local MainDataStoreName = DataStoreName

local originaldataStore = DataStoreService:GetDataStore(DataStoreName)
local dataStoreStudio
if (IsStudio and DataStoreModule.InStudioUseDifferentDataStore) then
	dataStoreStudio = DataStoreService:GetDataStore(DataStoreName .. "$Studio")
	MainDataStoreName = DataStoreName .. "$Studio"
end

local dataStore = (IsStudio and DataStoreModule.InStudioUseDifferentDataStore) and dataStoreStudio or originaldataStore

local Template = require(script.DefaultData)
local serverId = game.JobId

-- Internal States

export type LeaveCallback = (player: Player) -> ()
export type LeaveConnection = {
	Disconnect: () -> ()
}

local leaveCallbacks: { LeaveCallback } = {}

local CachedLastSessionUpdates = {}
local sessionData: { [string]: typeof(Template) } = {}

local OfflineHandles: { [string]: typeof(Template) } = {}

local Sessions = {}

local cachedLastSaves = {}
local cachedDisabledSaves = {}

-- Table to keep track of save request queues per user.
-- Each userId maps to a list (queue) of save requests.
local saveQueues = {}

local SessionLocksReleasedBeforeShutdown = {}
local IsServerShuttingDown = false

local HelperModule = script:WaitForChild("HelperModules")
local Utility = require(script.Utility)

-- Buffer Encoder
local BufferEncoder = require(HelperModule:WaitForChild("BufferEncoder"))

-- Session Lock
local SessionLockModule = require(HelperModule:WaitForChild("SessionLocks"))
local OfflineSessionLockModule = require(HelperModule:WaitForChild("OfflineSessionLocks"))

-- Helper Modules
local DeepCopyModule = require(HelperModule:WaitForChild("DeepCopy"))

local function DebugLog(...)
	if DataStoreModule.Debugging then
		local IsDebugOnlyInStudioPass: boolean = not DataStoreModule.DebugOnlyInStudio or IsStudio
		if IsDebugOnlyInStudioPass then
			print("[V" .. DataStoreModule.Version .. "] [PlayerDataStore]:", ...)
		end
	end
end

-- 📤 Publish a message (send to all listening servers)
local function publishMessage(message)
	if DataStoreModule.FullDebugInfo then
		local IsDebugOnlyInStudioPass: boolean = not DataStoreModule.DebugOnlyInStudio or IsStudio
		if IsDebugOnlyInStudioPass then
			DebugLog("Publishing Message to: " .. MessageTopicName .. " | Message:", message)
		end
	end
	
	local success, err = pcall(function()
		MessagingService:PublishAsync(MessageTopicName, message)
	end)

	if not success then
		warn("[PlayerDataStore]: Failed to publish message:", err)
	end
end

--[[
	getDefaultData

	Returns a deep copy of the default player data to avoid reference issues.
	Useful when assigning a clean dataset to new users.

	@return table -- A fresh deep-copied version of the default template
]]
local function getDefaultData(): typeof(Template)
	return DeepCopyModule.DeepCopy(Template)  -- prevents shared reference issues
end

-- Check state of Default Data

if not Utility.isJSONAcceptable(getDefaultData()) then
	if DataStoreModule.BufferEncoder then
		if DataStoreModule.DebugJSON_Notes then
			DebugLog("Default Data Template is not JSON-encodable!")
		end
	else
		warn("[PlayerDataStore] Default Data Template is not JSON-encodable!")
	end
end

local function addToQueue(userData: typeof(Template), GUID: string)
	if not userData or not GUID then return false end

	userData.__meta = userData.__meta or {}
	userData.__meta.Queue = userData.__meta.Queue or {}

	-- Check if GUID already exists
	for _, existingGUID in ipairs(userData.__meta.Queue) do
		if existingGUID == GUID then
			return false -- already exists, do not add
		end
	end
	
	-- Enforce max queue size (remove oldest entries) using repeat
	repeat
		if #userData.__meta.Queue <= 100 then
			break
		end
		table.remove(userData.__meta.Queue, 1)
	until #userData.__meta.Queue <= 100

	table.insert(userData.__meta.Queue, GUID)
	return true -- successfully added
end

local function decodeData(data)
	local decoded
	local success

	-- If data is a buffer, try BufferEncoder first
	if typeof(data) == "buffer" then
		success, decoded = pcall(BufferEncoder.read, data)
		if not success or typeof(decoded) ~= "table" then
			warn("[PlayerDataStore] Failed to decode buffer:", decoded)

			warn("[PlayerDataStore] Possible Data Corruption - Failed to decode BUFFER")
			warn("[PlayerDataStore] Resetting Data")

			return getDefaultData()
		end
		
		if not Utility.isJSONAcceptable(decoded) then
			if DataStoreModule.BufferEncoder then
				if DataStoreModule.DebugJSON_Notes then
					DebugLog("Decoding - Data is not valid JSON - if you turn off BufferEncoder later, the data could get corrupted.")
				end
			else
				warn("[PlayerDataStore] Decoding - Data is not valid JSON, could be corrupted")
			end
		end
		
		return decoded
	end
	
	-- If data is a string, try JSON decode
	if typeof(data) == "string" then
		if not Utility.isJSONAcceptable(data) then
			warn("[PlayerDataStore] Decoding - Data is not valid JSON, could be corrupted")
		end
		
		success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
		if not success or typeof(decoded) ~= "table" then
			warn("[PlayerDataStore] Failed to decode JSON:", decoded)
			warn("[PlayerDataStore] Resetting Data")
			return getDefaultData()
		end
		return decoded
	end

	-- If data is already a table, just use it
	if typeof(data) == "table" then
		if not Utility.isJSONAcceptable(data) then
			warn("[PlayerDataStore] Decoding Table - Data is not valid JSON, could be corrupted")
		end
		
		return data
	end

	-- If none match, reset
	warn("[PlayerDataStore] Unknown data type, Possible Data Corruption - Failed to decode data")
	warn("[PlayerDataStore] Unknown data type, resetting:", typeof(data), data)

	return getDefaultData()
end

local function encodeData(data)
	local encoded
	local success

	-- Ensure we are encoding a table
	if typeof(data) ~= "table" then
		warn("[PlayerDataStore] encodeData received non-table data, converting to default template data")
		data = getDefaultData()
	end

	if DataStoreModule.BufferEncoder then
		-- Try to encode with BufferEncoder
		success, encoded = pcall(BufferEncoder.write, data)
		
		if success then
			if not Utility.isJSONAcceptable(data) then
				if DataStoreModule.DebugJSON_Notes then
					DebugLog("Encoding - Data is not valid JSON - if you turn off BufferEncoder later, the data could get corrupted.")
				end
			end
			
			return encoded
		else
			warn("[PlayerDataStore] Failed to encode with BufferEncoder:", encoded)
			warn("[PlayerDataStore] Falling back to JSON encoding")
		end
	end
	
	if not Utility.isJSONAcceptable(data) then
		warn("[PlayerDataStore] Encoding - Data is not valid JSON, could be corrupted")
	end

	-- Fallback to JSON encoding
	success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if success then
		return encoded
	else
		warn("[PlayerDataStore] Failed to encode JSON:", encoded)
		warn("[PlayerDataStore] Returning default empty data template as string")
		return HttpService:JSONEncode(getDefaultData())
	end
end

local function logDataSize(encodedData, playerName)
	if typeof(encodedData) == "buffer" then
		-- BufferEncoder data
		local lengthInBytes = buffer.len(encodedData)
		local lengthInKB = lengthInBytes / 1024
		DebugLog(string.format(
			"Player Datastore Buffer Size for Player: %s = %.3f KB",
			playerName, lengthInKB
			))
	else
		-- JSON or fallback data
		local success, jsonResult = pcall(HttpService.JSONEncode, HttpService, encodedData)
		if success then
			local lengthInBytes = #jsonResult
			local lengthInKB = lengthInBytes / 1024
			DebugLog(string.format(
				"Player Datastore JSON Size for Player: %s = %.3f KB",
				playerName, lengthInKB
				))
		else
			warn("Player Datastore - Failed to JSON encode table for size check:", playerName, jsonResult)
		end
	end
end

-- Function to refresh locks for all players
local function RefreshAllPlayersSessionLocks()
	for _, player in pairs(Players:GetPlayers()) do
		local userId = tostring(player.UserId)
		if not sessionData[userId] then continue end
		if CachedLastSessionUpdates[userId] == nil then continue end

		if os.clock() - CachedLastSessionUpdates[userId] < RefreshSessionsEverySecond then continue end

		CachedLastSessionUpdates[userId] = os.clock()

		local success = SessionLockModule:TryLockPlayer(userId, true, false) -- Pass 'true' to reset timeout
		if success then
			DebugLog("Refreshed lock for player:", player.Name)
		else
			warn("Failed to refresh lock for player:", player.Name)
		end

		if sessionData[userId] then
			CachedLastSessionUpdates[userId] = os.clock()
		end

		task.wait(0.2)
	end
end

local function DeepReconcile(target, defaults, userId, path)
	for key, value in pairs(defaults) do
		local currentPath = path and (path .. "." .. key) or key

		if target[key] == nil then
			target[key] = value
			DebugLog("Reconciled missing key for userId", userId, "->", currentPath, "=", value)
		elseif typeof(value) == "table" and typeof(target[key]) == "table" then
			DeepReconcile(target[key], value, userId, currentPath)
		end
	end
end

function DataStoreModule:Reconcile(player: Player | number | string, data) : boolean
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)
	
	-- Wait for data to be loaded before returning it
	if not DataStoreModule:WaitForData(player) then
		-- Data not loaded (timeout or player left)
		return false
	end
	
	if not sessionData[userId] then return false end

	DeepReconcile(sessionData[userId], data, userId)
	
	if not Utility.isJSONAcceptable(data) then
		if DataStoreModule.BufferEncoder then
			if DataStoreModule.DebugJSON_Notes then
				DebugLog("Reconcile - Data is not JSON-encodable!")
			end
		else
			warn("[PlayerDataStore] Reconcile - Data is not JSON-encodable!")
		end
	end
	
	return true
end

function DataStoreModule:_ReconcileDefault(userId, data)
	local userId = tostring(userId)

	local defaultData = getDefaultData()
	--sessionData[userId] = sessionData[userId] or {}

	DeepReconcile(data or sessionData[userId] or {}, defaultData, userId)
end

function DataStoreModule:GetDefaultTemplate(): typeof(Template)
	return getDefaultData()
end

--- Loads player data from the DataStore, with session locking and fallback logic.
-- If no data exists, default data is used. Handles basic player onboarding flags.
-- Kicks the player if the session is locked elsewhere or if data fails to load.
-- 
-- @param player Player -- The player whose data should be loaded.
-- 
-- @return table|boolean -- Returns the session data table if successful, or false if loading failed.
function DataStoreModule:_LoadData(player: Player) : (typeof(Template) | boolean)?
	local userId = tostring(player.UserId)

	DebugLog("Loading data for", player.Name)
	DebugLog("Datastore Name:", MainDataStoreName)

	if DataStoreModule.ExtraDelayToLoadPlayerData then
		local dt: number = 0
		local delayTime: number = DataStoreModule.ExtraDelayToLoadPlayerData

		-- + 1 second random
		delayTime = delayTime + Random.new():NextNumber(0, 1)

		if cachedLastSaves[userId] then
			delayTime += 2
		end

		while dt < delayTime do
			if not player.Parent or not player:IsDescendantOf(Players) then
				return
			end

			dt += task.wait(0.1)
		end
	end

	if cachedLastSaves[userId] and (os.clock() - cachedLastSaves[userId] < 60) then
		player:Kick("Your last data is currently being saved.")
		return
	end

	if sessionData[userId] then return end
	if CachedLastSessionUpdates[userId] then return end
	
	if Sessions[userId] then
		task.wait(1)
		
		if Sessions[userId] then
			player:Kick("Your last data cache hasn't been cleared yet.")
			return
		end
	end
	
	if IsServerShuttingDown then
		player:Kick("Server is shutting down.")
		return
	end
	
	if not player:IsDescendantOf(Players) then return end
	local IsStudioMemoryStoreSessionDisabled = IsStudio and DataStoreModule.DisableMemoryStoreSessionLockOnStudio

	if not IsStudioMemoryStoreSessionDisabled then
		if OfflineHandles[userId] or OfflineSessionLockModule:IsPlayerLocked(userId) then
			for i = 1, 3 do -- total = 4 attempts
				DebugLog(string.format("Offline Lock Check attempt %d failed for %s, retrying in %d seconds...", i, player.Name, 1))
				
				task.wait(1)

				if not player:IsDescendantOf(Players) then return end

				if OfflineHandles[userId] or OfflineSessionLockModule:IsPlayerLocked(userId) then
					if i == 3 then
						player:Kick("Your data is currently being accessed from an offline handle.")
						return
					end
				else
					break
				end
			end
		end
	end

	local maxRetries = 5
	local retryDelay = 1 -- seconds
	local lockSuccess = false

	if DataStoreModule.MemoryStoreSessionLock and not IsStudioMemoryStoreSessionDisabled then
		for attempt = 1, maxRetries do
			if not player.Parent or not Players:FindFirstChild(player.Name) then return end

			if attempt == 1 or attempt == maxRetries then
				if DataStoreModule.BeSoftOnMemoryStoreErrors then
					-- Only at first attempt fail, possible to return false (At memorystore errors)
					lockSuccess = SessionLockModule:TryLockPlayer(userId, nil, attempt ~= 1)
				else
					lockSuccess = SessionLockModule:TryLockPlayer(userId, nil, false)
				end
				if lockSuccess then
					break
				else
					DebugLog(string.format("Lock attempt %d failed for %s, retrying in %d seconds...", attempt, player.Name, retryDelay))
					task.wait(retryDelay)
				end
			else
				task.wait(retryDelay)
			end

			if sessionData[userId] then return end
			if CachedLastSessionUpdates[userId] then return end
		end

		if not lockSuccess then
			player:Kick("Your data is currently being accessed from another server.")
			return
		end
	end

	if sessionData[userId] then return end
	if CachedLastSessionUpdates[userId] then return end

	if not player:IsDescendantOf(Players) then return end
	
	DebugLog("Truly Loading data for", player.Name)

	local success, data = pcall(function()
		return dataStore:GetAsync(DataStoreKeyName .. "_" .. userId)
	end)

	if not player.Parent or not Players:FindFirstChild(player.Name) then return end
	if sessionData[userId] then return end
	if CachedLastSessionUpdates[userId] then return end

	CachedLastSessionUpdates[userId] = os.clock()

	if success then
		if IsStudio and DataStoreModule.LoadDefaultDataAlwaysInStudio then
			DebugLog("[STUDIO-ONLY] Loading Default Data for", player.Name, "in Studio")

			sessionData[userId] = getDefaultData() :: typeof(Template)
		else
			if not data then
				DebugLog("Player is new * No data found for", player.Name, "- using default template")
				sessionData[userId] = getDefaultData() :: typeof(Template)
			else
				local data = decodeData(data)

				DebugLog("Data loaded for", player.Name, data)

				sessionData[userId] = data :: typeof(Template)
				DataStoreModule:_ReconcileDefault(userId)
			end
		end

		if (DataStoreModule.Debugging and IsStudio) or DataStoreModule.FullDebugInfo then
			local IsDebugOnlyInStudioPass: boolean = not DataStoreModule.DebugOnlyInStudio or IsStudio
			
			if IsDebugOnlyInStudioPass then
				logDataSize(sessionData[userId], player.Name)
			end
		end
		
		Sessions[userId] = true

		return sessionData[userId] :: typeof(Template)
	else
		warn("Failed to load data for", player.Name, ":", data)

		player:Kick("Server Failed to load your data.")
		--sessionData[userId] = getDefaultData()
		return false
	end
end

--- Loads data for an offline player from the DataStore.
-- Accepts either a Player instance, userId (number), or userId as a string.
-- Uses default data if no existing data is found or if decoding fails.
--
-- @param player Player | number | string -- The Player instance or userId of the offline player.
--
-- @return table|boolean -- Returns the data table if successful, or false if loading failed.
function DataStoreModule:LoadOfflineData(player: Player | number | string, doNotLock: boolean?): typeof(Template)?
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)

	DebugLog("Loading Offline data for", userId)

	if sessionData[userId] then
		return sessionData[userId]
	end
	
	if OfflineHandles[userId] then
		return OfflineHandles[userId]
	end

	if not DataStoreModule.Offline_Functions_Use_NormalDatastore_Always then
		DebugLog("Datastore Name:", MainDataStoreName)
	else
		DebugLog("Datastore Name:", DataStoreName)
	end
	
	if not doNotLock then
		local lockSuccess = OfflineSessionLockModule:TryLockPlayer(userId, nil, true)

		if not lockSuccess then
			warn("[LoadOfflineData] Failed to lock session for player:", userId)
		end
	end

	local success, data = pcall(function()
		local dataStore = DataStoreModule.Offline_Functions_Use_NormalDatastore_Always and originaldataStore or dataStore
		return dataStore:GetAsync(DataStoreKeyName .. "_" .. userId)
	end)

	if success then
		if not data then
			DebugLog("Player is new * No Offline data found for", userId, "- using default template")
			data = getDefaultData()
		else
			data = decodeData(data)

			DebugLog("Offline Data loaded for", userId, data)

			DataStoreModule:_ReconcileDefault(userId, data)
		end

		if (DataStoreModule.Debugging and IsStudio) or DataStoreModule.FullDebugInfo then
			local IsDebugOnlyInStudioPass: boolean = not DataStoreModule.DebugOnlyInStudio or IsStudio
			
			if IsDebugOnlyInStudioPass then
				logDataSize(data, userId)
			end
		end

		OfflineHandles[userId] = data
		return data
	else
		warn("[PlayerDataStore]: Failed to load offline data for", userId, ":", data)

		return false
	end
end

--[[
	Saves a player's session data to the DataStore with queueing.

	If multiple save requests for the same player come in,
	they are queued and processed sequentially to avoid
	conflicts or skipping saves.

	@param player Player -- The player whose data is being saved
	@param ReleaseLock boolean? -- Should release lock for player after save? (optional)
]]
function DataStoreModule:_SaveData(player: Player, ReleaseLock: boolean?)
	local userId = tostring(player.UserId)
	
	DebugLog("Saving Player Data:", player.Name)

	-- Check if session data exists for player; if none, no point saving
	if not sessionData[userId] then
		DebugLog("No session data to save for", player.Name)

		cachedLastSaves[userId] = nil
		return
	end
	
	if cachedDisabledSaves[userId] then
		DebugLog("Saving Canceled due to previous request of disabling save for player:", player.Name)

		cachedLastSaves[userId] = nil
		return
	end

	if IsStudio then
		if DataStoreModule.DoNotSaveDataInStudio then
			DebugLog("[STUDIO-ONLY]: Not saving user data:", player.Name)

			return
		end
	end

	-- Initialize queue for this user if it doesn't exist yet
	if not saveQueues[userId] then
		saveQueues[userId] = {}
	end

	-- Add this save request's ReleaseLock flag to the user's queue
	table.insert(saveQueues[userId], ReleaseLock or false)

	-- If the queue length is greater than 1, it means a save is already running,
	-- so just return here. The queued saves will be processed in order by the loop below.
	if #saveQueues[userId] > 1 then
		DebugLog("Save already queued for", player.Name)
		return
	end

	cachedLastSaves[userId] = os.clock()

	-- Spawn a new task to process this player's save queue asynchronously
	task.spawn(function()
		DebugLog("Datastore Name:", MainDataStoreName)

		-- Process each queued save request one by one
		while #saveQueues[userId] > 0 do
			-- Get the ReleaseLock flag for the current save request at the front of the queue
			local currentReleaseLock = saveQueues[userId][1]

			local maxRetries = 3 -- maximum save attempts
			local attempt = 0
			local success, err

			-- Try to save data with retry and backoff
			while attempt < maxRetries do
				attempt += 1

				-- Get latest session data before each attempt
				local currentData = sessionData[userId]
				if not currentData then
					-- If session data disappeared, log and break out of retry loop
					DebugLog("No session data to save for", player.Name)
					break
				end

				local encodedSuccess, encodedData

				if typeof(currentData) == 'table' then
					currentData.__meta = currentData.__meta or {}
					
					local TIME = os.time()	
					
					if not currentData.__meta.____DataCreatedAt then
						currentData.__meta.____DataCreatedAt = TIME
					end
					
					currentData.__meta.____DataUpdatedAt = TIME
					
					if not currentData.__meta.____LastVersion or typeof(currentData.__meta.____LastVersion) ~= 'number' then
						currentData.__meta.____LastVersion = 1
					else
						currentData.__meta.____LastVersion += 1
					end
					
					currentData.__meta.____LastModuleVersion = DataStoreModule.Version
					
					if DataStoreModule.BufferEncoder then
						currentData.__meta.____BufferEncoderEverUsedOn = true
					end
					
					encodedData = encodeData(currentData)
					encodedSuccess = encodedData ~= nil
					
					local attempts = 0
					local maxAttempts = 3 -- original attempt + 2 retries

					while attempts < maxAttempts do
						attempts = attempts + 1
						success, err = pcall(function()
							dataStore:SetAsync(DataStoreKeyName .. "_" .. userId, encodedData)
						end)

						if success then
							break -- exit loop if save succeeded
						else
							warn("Attempt " .. attempts .. " failed: " .. tostring(err))
							wait(1) -- optional small delay before retrying
						end
					end

					if not success then
						warn("Failed to save data after " .. maxAttempts .. " attempts.")
					end

					if (DataStoreModule.Debugging and IsStudio) or DataStoreModule.FullDebugInfo then
						local IsDebugOnlyInStudioPass: boolean = not DataStoreModule.DebugOnlyInStudio or IsStudio
						if IsDebugOnlyInStudioPass then
							logDataSize(encodedData, player.Name)
						end
					end
				else
					warn("DataStoreModule:_SaveData - GIVEN DATA IS NOT TABLE FOR SAVE:", player.Name)

					break
				end

				if success and encodedData then
					-- Save successful, log and break out of retry loop
					DebugLog("Data saved for", player.Name, currentData)
					--DebugLog("Data saved for", player.Name, decodeData(encodeData))
					break
				else
					-- Save failed, warn with error and backoff before retrying
					warn("Attempt", attempt, "failed to save data for", player.Name, ":", err)
					task.wait(1 + attempt * 0.5) -- incremental delay between retries
				end
			end

			-- If all retries failed, warn user
			if not success then
				warn("All attempts failed to save data for", player.Name)
			end

			-- If ReleaseLock flag was true, release the session lock for this user
			if currentReleaseLock then
				SessionLockModule:ReleaseLock(userId)
			end

			-- Remove the processed save request from the queue
			table.remove(saveQueues[userId], 1)
		end

		-- Clear cachedLastSaves if the player is not in-game
		if not Players:FindFirstChild(player.Name) then
			cachedLastSaves[userId] = nil
		end

		-- After processing all queued saves, clear the queue to free memory
		saveQueues[userId] = nil

	end)
end

--[[
	SaveOfflineData saves a player's offline data to the DataStore.
	
	@param player Player | number | string -- The player instance, userId number, or userId string whose data is being saved.
	@param data any -- The data table to be saved for the player.
	@param forced boolean? -- Optional flag to force saving without session lock check.
	
	@returns true|false
]]
function DataStoreModule:SaveOfflineData(player: Player | number | string, data: any, forced: boolean?)
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)
	
	local clearOfflineDataResult = DataStoreModule:_clearOfflineHandle(player)
	if not clearOfflineDataResult then
		warn("[PlayerDataStore]: Failed to clear offline handle properly for player:",userId)
	end

	if not data or typeof(data) ~= 'table' then
		warn("[PlayerDataStore]: Invalid data for offline save:", player, data)
	end
	
	if IsStudio then
		if DataStoreModule.DoNotSaveDataInStudio then
			DebugLog("[STUDIO-ONLY]: Not offline saving user data:", userId)

			return
		end
	end
	
	if not forced then
		local IsSessionLocked: boolean = SessionLockModule:IsPlayerLocked(userId)
		
		if IsSessionLocked then
			DebugLog("Couldn't offline save due to session being locked, for player:", userId)
			
			return false
		end
	end

	--local encodedSuccess, encodedData = pcall(BufferEncoder.write, data)
	
	data.__meta = data.__meta or {}
	
	local TIME = os.time()
	
	if not data.__meta.____DataCreatedAt then
		data.__meta.____DataCreatedAt = TIME
	end
	
	data.__meta.____DataUpdatedAt = TIME
	
	if not data.__meta.____LastVersion or typeof(data.__meta.____LastVersion) ~= 'number' then
		data.__meta.____LastVersion = 1
	else
		data.__meta.____LastVersion += 1
	end
	
	data.__meta.____LastModuleVersion = DataStoreModule.Version
	
	if DataStoreModule.BufferEncoder then
		data.__meta.____BufferEncoderEverUsedOn = true
	end
	
	DebugLog("Offline Saving Player Data:", userId)
	
	if not DataStoreModule.Offline_Functions_Use_NormalDatastore_Always then
		DebugLog("Datastore Name:", MainDataStoreName)
	else
		DebugLog("Datastore Name:", DataStoreName)
	end
	
	local encodedData = encodeData(data)
	local encodedSuccess = encodedData ~= nil
	
	local success, err

	if encodedSuccess and encodedData then
		local dataStore = DataStoreModule.Offline_Functions_Use_NormalDatastore_Always and originaldataStore or dataStore
		-- Attempt to save data using pcall for error handling
		success, err = pcall(function()
			dataStore:SetAsync(DataStoreKeyName .. "_" .. userId, encodedData)
		end)

		if (DataStoreModule.Debugging and IsStudio) or DataStoreModule.FullDebugInfo then
			local IsDebugOnlyInStudioPass: boolean = not DataStoreModule.DebugOnlyInStudio or IsStudio
			if IsDebugOnlyInStudioPass then
				logDataSize(encodedData, userId)
			end
		end
	else
		warn("[PlayerDataStore]: FAILED TO ENCODE OFFLINE DATA FOR SAVE:", userId)
		return false
	end

	if success and encodedData then
		-- Save successful
		DebugLog("Offline Data saved for", userId, data)

		return true
	else
		-- Save failed, warn with error and backoff
		warn("[PlayerDataStore]: Offline Data save failed for", userId, data)
		return false
	end
end

function DataStoreModule:_PublishMessage(Action: MessageActionPossibleNames, userId: Player | number | string, GUID: string, args)
	if typeof(userId) == "Instance" then
		userId = tostring(userId.UserId)
	elseif typeof(userId) == 'number' then 
		userId = tostring(userId)
	end

	local CurrentTimeUnixUTC = os.time()

	publishMessage({
		Action = Action,
		UserId = userId,
		Arguments = args,
		Time = CurrentTimeUnixUTC,
		GUID = GUID or HttpService:GenerateGUID(false),
		ServerId = serverId
	})
end

--[[
	Returns the player's current session data.
	You can use this to read or modify the player's data during gameplay.
	Will wait for the data to be loaded unless `no_wait` is true.

	@param player Player -- The player whose data you want to access
	@param no_wait boolean? -- If true, the function will not wait for data to load; may return nil if data isn't ready
	@return table? -- The player's data table, or nil if data is not loaded
	@usage
		local data = DataStoreModule:GetData(player)
		if data then
			print(data.Stats.Kills)
		end

		local data_no_wait = DataStoreModule:GetData(player, true)
		if data_no_wait then
			data_no_wait.Stats.XP += 10
		end
]]
function DataStoreModule:GetData(player: Player, no_wait: boolean?): typeof(Template)?
	local userId = tostring(player.UserId)

	if not no_wait then
		-- Wait for data to be loaded before returning it
		if not DataStoreModule:WaitForData(player) then
			-- Data not loaded (timeout or player left)
			return nil
		end
	end

	return sessionData[userId]
end

--[[
	Returns a nested value from the player's session data using one or more keys.

	This function safely navigates through the data table using the provided key path.
	If any part of the path is missing or invalid, it returns nil instead of erroring.

	Usage:
	local primaryWeapon = DataStoreModule:GetValue(player, "Inventory", "Weapons", "Primary")

	@param player Player -- The player whose data to retrieve
	@param ... string -- A variadic list of keys to navigate through the data (e.g., "Inventory", "Weapons", "Primary")
	@return (any, boolean) -- The nested value found at the key path, or nil if not found/invalid. 
	                         The second return value is false if the player's data wasn't loaded, otherwise true.
]]
function DataStoreModule:GetValue(player: Player, ...: string): (any, boolean)
	local userId = tostring(player.UserId)

	-- Ensure data is loaded for the player
	if not DataStoreModule:WaitForData(player) then
		return nil, false
	end

	-- Get the root data table for the player
	local data = sessionData[userId]
	if not data then return nil end

	-- Keys provided via varargs
	local keys = { ... }
	local current = data

	-- Traverse the nested keys
	for _, key in ipairs(keys) do
		if typeof(current) ~= "table" then
			-- Not a table, can't index further
			return nil
		end

		current = current[key]

		if current == nil then
			-- Key does not exist
			return nil
		end
	end

	-- Final nested value
	return current, true
end

--[[
	Retrieves a nested value from a player's offline (non-session) data using a key path.

	If the player is currently online, this function will automatically delegate to GetValue,
	which accesses live session data. If offline, it loads the user's saved data from the datastore
	and attempts to read the value using the provided keys.

	This function is safe: it returns nil if the data is missing or any key along the path is invalid.

	Usage:
	local level = DataStoreModule:FetchValue(123456789, "Stats", "Level")

	@param player Player | number | string -- The player instance or user ID whose data to access
	@param ... string -- A list of keys specifying the nested path within the data table
	@return any -- The nested value, or nil if not found
]]
function DataStoreModule:FetchValue(player: Player | number | string, ...: string): any
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)

	local UserOnlineData

	-- If the player is online, fallback to GetValue
	if typeof(player) == "Instance" and player and player.Parent then
		UserOnlineData = DataStoreModule:GetValue(player, ...)
	end

	if not UserOnlineData then
		-- Handle offline data
		local data = DataStoreModule:LoadOfflineData(userId)
		if not data then
			DebugLog("[ERROR] * Offline Get Failed: No data for", userId)
			return nil
		end

		local keys = { ... }
		return Utility.getNestedValue(data, keys)
	else
		return UserOnlineData
	end
end

--[[
	Sets a nested value in the player's session data or offline data using a sequence of keys.

	Example usage:
		SetValue(player, "Settings", "Audio", "Volume", 0.5)
		This sets:
			sessionData[userId].Settings.Audio.Volume = 0.5
		or for offline data:
			offlineData.Settings.Audio.Volume = 0.5

	@param player Player | number | string
		- A Player instance, or a userId number/string identifying the player.
		- If a userId is provided, it attempts to find the Player instance for online data.
	
	@param ... any
		- A variable number of arguments:
			- All but the last argument are keys (strings or numbers) specifying the nested path.
			- The last argument is the value to set at the nested location.

	Notes:
	- If the player is online and their session data is loaded, modifies sessionData.
	- Otherwise, loads and modifies offline data, then saves it.
	- Internally, the keys and value are extracted from the varargs (...):
		- keys = all arguments except the last one
		- value = the last argument
]]
function DataStoreModule:SetValue(player: Player | number | string, ...: any) : boolean?
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)
	local keys, value, args = Utility.parseArgs(...)

	local IsPlayerOnline: boolean = false

	if typeof(player) == "Instance" and player and player.Parent then
		-- Ensure data is loaded for this player
		if not DataStoreModule:WaitForData(player) then
			DebugLog("[ERROR] * Set Failed: Data not loaded for", player.Name)
		else
			IsPlayerOnline = true
		end

		if IsPlayerOnline then
			local current = sessionData[userId]
			if not current then
				DebugLog("[ERROR] * Set Failed: No session data for", player.Name)
				return
			end

			Utility.setNestedValue(current, keys, value)

			DebugLog("Set", table.concat(keys, "."), "=", value, "for", player.Name)
			
			if not Utility.isJSONAcceptable(current) then
				if DataStoreModule.BufferEncoder then
					if DataStoreModule.DebugJSON_Notes then
						DebugLog("SetValue - Data is not JSON-encodable!")
					end
				else
					warn("[PlayerDataStore] SetValue - Data is not JSON-encodable!")
				end
			end

			return true
		end
	end

	if not player or not IsPlayerOnline then
		-- Offline DataStore

		if not DataStoreModule.OfflineModeEnabled then return false end

		local UserOfflineData = DataStoreModule:LoadOfflineData(userId)

		if UserOfflineData then
			local current = UserOfflineData

			Utility.setNestedValue(current, keys, value)

			DebugLog("Offline Set", table.concat(keys, "."), "=", value, "for", userId)
			
			if not Utility.isJSONAcceptable(current) then
				if DataStoreModule.BufferEncoder then
					if DataStoreModule.DebugJSON_Notes then
						DebugLog("Offline SetValue - Data is not JSON-encodable!")
					end
				else
					warn("[PlayerDataStore] Offline SetValue - Data is not JSON-encodable!")
				end
			end

			--local CurrentTimeUnixUTC = os.time()

			--publishMessage({
			--	Action = "SetValue",
			--	UserId = userId,
			--	Arguments = args,
			--	Time = CurrentTimeUnixUTC
			--})
			
			local GUID: string = HttpService:GenerateGUID(false)
			addToQueue(UserOfflineData, GUID)

			if DataStoreModule.DoubleMessages then
				DataStoreModule:_PublishMessage("SetValue", userId, GUID, args)
			end
			local SavedOfflineDataResult = DataStoreModule:SaveOfflineData(userId, UserOfflineData)
			DataStoreModule:_PublishMessage("SetValue", userId, GUID, args)
			return SavedOfflineDataResult
		else
			DebugLog("[ERROR] * Offline Set Failed: No data for", userId)
			return false
		end
	end

	return false
end

--[[
	Applies multiple updates to a player's data in one call.

	Example:
		UpdateData(player, { Wins = 5, Losses = 2 })

	You can also do nested tables:
		UpdateData(player, { Stats = { Kills = 10, Deaths = 3 } })

	@param player Player | number | string
		- A Player instance, userId number, or userId string identifying the player.
		- If a Player is provided, the update applies to their in-memory session data.
		- If a userId is provided, the function attempts to find the Player instance;
		  if not found, it will modify offline data instead.

	@param changes table
		- A table of key/value pairs representing updates.
		- Nested tables are supported for hierarchical updates.

	@returns boolean
		- true if all updates were successfully applied.
		- false if data was not available, player data failed to load,
		  or offline save failed.
]]
function DataStoreModule:UpdateData(player: Player | number | string, changes: {[any]: any}) : boolean
	if type(changes) ~= "table" then
		DebugLog("[ERROR] * UpdateData Failed: changes must be a table")
		return false
	end
	
	if not Utility.isJSONAcceptable(changes) then
		if DataStoreModule.BufferEncoder then
			if DataStoreModule.DebugJSON_Notes then
				DebugLog("UpdateData - Data is not JSON-encodable!")
			end
		else
			warn("[PlayerDataStore] UpdateData - Data is not JSON-encodable!")
		end
	end

	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)

	local IsPlayerOnline: boolean = false
	local currentData

	if typeof(player) == "Instance" and player and player.Parent then
		-- Ensure session data is loaded
		if not DataStoreModule:WaitForData(player) then
			DebugLog("[ERROR] * UpdateData Failed: Data not loaded for", player.Name)
			return false
		end
		IsPlayerOnline = true
		currentData = sessionData[userId]
	end
	
	if not IsPlayerOnline then
		-- Offline mode
		if not DataStoreModule.OfflineModeEnabled then return false end
		currentData = DataStoreModule:LoadOfflineData(userId)
		if not currentData then
			DebugLog("[ERROR] * Offline UpdateData Failed: No data for", userId)
			return false
		end
	end

	-- Recursive helper to apply nested updates
	local function applyChanges(tbl: table, prefix: {string}?)
		prefix = prefix or {}

		for key, value in pairs(tbl) do
			local keys = table.clone(prefix)
			table.insert(keys, key)

			if type(value) == "table" then
				applyChanges(value, keys)
			else
				Utility.setNestedValue(currentData, keys, value)
				DebugLog("UpdateData", table.concat(keys, "."), "=", value, "for", userId)
			end
		end
	end

	applyChanges(changes)

	if not IsPlayerOnline then
		local GUID: string = HttpService:GenerateGUID(false)
		addToQueue(currentData, GUID)
		
		-- Save once for offline data
		
		if DataStoreModule.DoubleMessages then
			DataStoreModule:_PublishMessage("BulkUpdate", userId, GUID, changes)
		end
		local SavedOfflineDataResult = DataStoreModule:SaveOfflineData(userId, currentData)
		DataStoreModule:_PublishMessage("BulkUpdate", userId, GUID, changes)
		return SavedOfflineDataResult
	end

	return true
end

--[[ 
	Inserts a value into a nested table in the player's session data or offline data.

	@param player Player | number | string
		- A Player instance, or a userId number/string identifying the player.

	@param ... any
		- All but the last argument are keys specifying the nested path (must resolve to a table).
		- The last argument is the value to insert into that table.
]]
function DataStoreModule:Insert(player: Player | number | string, ...: any): boolean?
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)
	local keys, value, args = Utility.parseArgs(...)

	local IsPlayerOnline: boolean = false

	if typeof(player) == "Instance" and player and player.Parent then
		if not self:WaitForData(player) then
			DebugLog("[ERROR] * Insert Failed: Data not loaded for", player.Name)
		else
			IsPlayerOnline = true
		end

		if IsPlayerOnline then
			local current = sessionData[userId]
			if not current then
				DebugLog("[ERROR] * Insert Failed: No session data for", player.Name)
				return
			end

			local target = Utility.getNestedValue(current, keys)
			if type(target) ~= "table" then
				DebugLog("[ERROR] * Insert Failed: Target is not a table at", table.concat(keys, "."))
				return
			end

			table.insert(target, value)
			DebugLog("Inserted", value, "into", table.concat(keys, "."), "for", player.Name)

			return true
		end
	end

	if not player or not IsPlayerOnline then
		if not self.OfflineModeEnabled then return false end

		local UserOfflineData = self:LoadOfflineData(userId)
		if not UserOfflineData then
			DebugLog("[ERROR] * Offline Insert Failed: No data for", userId)
			return false
		end

		local target = Utility.getNestedValue(UserOfflineData, keys)
		if type(target) ~= "table" then
			DebugLog("[ERROR] * Offline Insert Failed: Target is not a table at", table.concat(keys, "."))
			return false
		end

		table.insert(target, value)
		DebugLog("Offline Inserted", value, "into", table.concat(keys, "."), "for", userId)

		local GUID: string = HttpService:GenerateGUID(false)
		addToQueue(UserOfflineData, GUID)
		
		if DataStoreModule.DoubleMessages then
			self:_PublishMessage("Insert", userId, GUID, args)
		end
		local SavedOfflineDataResult = self:SaveOfflineData(userId, UserOfflineData)
		self:_PublishMessage("Insert", userId, GUID, args)
		return SavedOfflineDataResult
	end

	return false
end

--[[
    QueueInsert(player: Player | number | string, tbl: table | any, offlineModeOnly: boolean?): boolean?

    Adds a value to a player's queue table in their session data or offline data.
    
    @param player Player | number | string
        - The Player instance, or a userId (number/string) identifying the player.
        - If a userId is provided, attempts to find the online Player first.
    
    @param tbl table | any
        - The value to insert into the player's queue.
        - Can be a table, string, number, boolean, or any Lua value.
        - If a table, it is inserted as-is (not wrapped in another table).
    
    @param offlineModeOnly boolean? (optional)
        - If true, skips attempting to insert into online session data
          and only inserts into offline data (if OfflineModeEnabled).
        - Defaults to false.

    Behavior:
    - If the player is online and offlineModeOnly is false:
        • Waits for their session data to load.
        • Inserts the value into `sessionData[userId].__meta.QueueTbl`.
    - If the player is offline or offlineModeOnly is true:
        • Loads offline data (via LoadOfflineData).
        • Inserts the value into `offlineData.__meta.QueueTbl`.
        • Generates a GUID and stores it in `__meta.Queue` for synchronization.
        • Saves the offline data.
        • Publishes a message via MessagingService for cross-server updates.

    Returns:
        - `true` if the value was successfully inserted.
        - `false` if insertion failed (data not loaded, etc.).
]]
function DataStoreModule:QueueInsert(player: Player | number | string, tbl: any, offlineModeOnly: boolean?): boolean?
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)

	local IsPlayerOnline: boolean = false

	if not offlineModeOnly then
		if typeof(player) == "Instance" and player and player.Parent then
			if not self:WaitForData(player) then
				DebugLog("[ERROR] * Queue Insert Failed: Data not loaded for", player.Name)
			else
				IsPlayerOnline = true
			end

			if IsPlayerOnline then
				local current = sessionData[userId]
				if not current then
					DebugLog("[ERROR] * Queue Insert Failed: No session data for", player.Name)
					return
				end
				
				current.__meta = current.__meta or {}
				current.__meta.QueueTbl = current.__meta.QueueTbl or {}
				
				local GUID: string = HttpService:GenerateGUID(false)
				local Args = {
					GUID = GUID,
					Info = tbl,
				}

				table.insert(current.__meta.QueueTbl, Args)
				DebugLog("Queue Inserted", tbl, "into", "__meta.QueueTbl", "for", player.Name)

				return true
			end
		end
	end

	if not player or not IsPlayerOnline then
		if not self.OfflineModeEnabled then return false end
		if player and player:IsDescendantOf(Players) then return false end

		local UserOfflineData = self:LoadOfflineData(userId)
		if not UserOfflineData then
			DebugLog("[ERROR] * Offline Queue Insert Failed: No data for", userId)
			return false
		end
		
		UserOfflineData.__meta = UserOfflineData.__meta or {}
		UserOfflineData.__meta.QueueTbl = UserOfflineData.__meta.QueueTbl or {}

		local GUID: string = HttpService:GenerateGUID(false)
		local Args = {
			GUID = GUID,
			Info = tbl,
		}

		table.insert(UserOfflineData.__meta.QueueTbl, Args)
		DebugLog("Offline Queue Inserted", tbl, "into", "__meta.QueueTbl", "for", userId)
		
		addToQueue(UserOfflineData, GUID)
		
		if DataStoreModule.DoubleMessages then
			self:_PublishMessage("QueueInsert", userId, GUID, Args)
		end
		local SavedOfflineDataResult = self:SaveOfflineData(userId, UserOfflineData)
		self:_PublishMessage("QueueInsert", userId, GUID, Args)
		return SavedOfflineDataResult
	end

	return false
end

--[[
	Increments a nested numeric value in the player's session data using a variable number of keys.
	If the nested key does not exist, it initializes it to 0 before incrementing.
	Supports both online (active players) and offline data (using OfflineMode).
	
	Example usage:
		DataStoreModule:Increment(player, "Stats", "Kills", 1)
		→ Increments sessionData[userId].Stats.Kills by 1

	@param player Player | number | string -- The player object, UserId number, or UserId string
	@param ... any -- A variable number of arguments where all but the last are keys, and the last is the numeric increment amount
]]
function DataStoreModule:Increment(player: Player | number | string, ...: any): boolean?
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)

	local args = { ... }
	-- Last argument is the amount to increment by
	local amount = tonumber(args[#args]) -- Try to parse last arg as number 
	local keys
	if amount then
		-- Last arg is a number → slice it out
		keys = table.move(args, 1, #args-1, 1, {})
	else
		-- Last arg is not a number → use all args
		amount = 1
		keys = table.move(args, 1, #args, 1, {})
	end

	local IsPlayerOnline: boolean = false

	if typeof(player) == "Instance" and player and player.Parent then
		-- Online session
		if not DataStoreModule:WaitForData(player) then
			DebugLog("[ERROR] * Increment Failed: Data not loaded for", player.Name)
		else
			IsPlayerOnline = true
		end

		if IsPlayerOnline then
			local current = sessionData[userId]
			if not current then
				DebugLog("[ERROR] * Increment Failed: No session data for", player.Name)
				return false
			end

			local oldValue = tonumber(Utility.getNestedValue(current, keys)) or 0
			local newValue = oldValue + amount
			Utility.setNestedValue(current, keys, newValue)

			DebugLog(
				(amount >= 0 and "Incremented" or "Decremented"),
				table.concat(keys, "."),
				"from", oldValue, "to", newValue,
				"for", player.Name
			)

			return true
		end
	end

	if not player or not IsPlayerOnline then
		-- Offline mode
		if not DataStoreModule.OfflineModeEnabled then return false end

		local UserOfflineData = DataStoreModule:LoadOfflineData(userId)

		if UserOfflineData then
			local oldValue = tonumber(Utility.getNestedValue(UserOfflineData, keys) or 0) or 0
			local newValue = oldValue + amount
			Utility.setNestedValue(UserOfflineData, keys, newValue)

			DebugLog(
				(amount >= 0 and "Offline Incremented" or "Offline Decremented"),
				table.concat(keys, "."),
				"from", oldValue, "to", newValue,
				"for", userId
			)

			--local CurrentTimeUnixUTC = os.time()

			--publishMessage({
			--	Action = "Increment",
			--	UserId = userId,
			--	Arguments = args,
			--	Time = CurrentTimeUnixUTC
			--})
			
			local GUID: string = HttpService:GenerateGUID(false)
			addToQueue(UserOfflineData, GUID)

			if DataStoreModule.DoubleMessages then
				self:_PublishMessage("Increment", userId, GUID, args)
			end
			local SavedOfflineDataResult = self:SaveOfflineData(userId, UserOfflineData)
			self:_PublishMessage("Increment", userId, GUID, args)
			return SavedOfflineDataResult
		else
			DebugLog("[ERROR] * Offline Increment Failed: No data for", userId)
			return false
		end
	end

	return false
end

--[[
	Checks if the player's data has been loaded.

	@param player Player -- The player to check
	@return boolean -- True if session data exists
]]
function DataStoreModule:HasData(player: Player): boolean
	local userId = tostring(player.UserId)

	local hasData = sessionData[userId] ~= nil
	if DataStoreModule.FullDebugInfo then
		local IsDebugOnlyInStudioPass: boolean = not DataStoreModule.DebugOnlyInStudio or IsStudio
		if IsDebugOnlyInStudioPass then
			DebugLog("HasData check for", player.Name, ":", hasData)
		end
	end
	return hasData
end

--[[
    Waits until the player's data has been loaded or the player leaves the game,
    or until an optional timeout is reached.

    @param player Player -- The player to wait for
    @param timeout number? -- Optional timeout in seconds (default is 10 seconds)

    @return boolean -- Returns true if the player's data is loaded and the player is still in the game;
                      returns false if the player leaves or timeout is reached before data loads.
]]
function DataStoreModule:WaitForData(player: Player, timeout: number?)
	-- Return true if data has been loaded
	if DataStoreModule:HasData(player) then
		return true
	end

	-- Return false immediately if player left the game
	if not player.Parent or not Players:FindFirstChild(player.Name) then
		DebugLog("[WaitForData] Player left before waiting:", player.Name)
		return false
	end

	local DefaultWaitingTimeout = DataStoreModule.DefaultWaitingTimeout
	timeout = timeout or DefaultWaitingTimeout -- default timeout is 15 seconds
	local startTime = os.clock()

	DebugLog("[WaitForData] Waiting for data for player:", player.Name, "Timeout:", timeout)

	while true do
		-- Return false immediately if player left the game
		if not player.Parent or not Players:FindFirstChild(player.Name) then
			DebugLog("[WaitForData] Player left during wait:", player.Name)
			return false
		end

		-- Return true if data has been loaded
		if DataStoreModule:HasData(player) then
			DebugLog("[WaitForData] Data loaded during wait for player:", player.Name)

			task.wait(0.1)
			return true
		end

		-- Return false if timeout is reached
		if os.clock() - startTime >= timeout then
			DebugLog("[WaitForData] Timeout reached waiting for data for player:", player.Name)

			if DataStoreModule.KickPlayerOnWaitingDataTimeout and timeout >= DefaultWaitingTimeout then
				if Players:FindFirstChild(player.Name) then
					player:Kick("PlayerDataStore load timeout...")
				end
			end

			return false
		end

		task.wait(0.1) -- avoid tight loop, check every 0.1 seconds
	end
end

--[[
	Removes a nested key from the player's data table (session or offline) using a sequence of keys.

	Example usage:
		DataStoreModule:RemoveKey(player, "Settings", "Audio", "Volume")
		This removes:
			- sessionData[userId].Settings.Audio.Volume (if online), or
			- offlineData.Settings.Audio.Volume (if offline)

	@param player Player | number | string
		- A Player instance, or a userId number/string identifying the player.
		- If a userId is provided, it attempts to find the Player instance for online data.
	
	@param ... any
		- A sequence of keys specifying the nested path to remove.

	Notes:
	- If the player is online and their session data is loaded, modifies sessionData.
	- Otherwise, loads and modifies offline data, then saves it.
]]
function DataStoreModule:RemoveKey(player: Player | number | string, ...: any) : boolean?
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)

	local keys = { ... }
	if #keys == 0 then
		DebugLog("[ERROR] * RemoveKey Failed: No keys provided")
		return false
	end

	local IsPlayerOnline: boolean = false

	if typeof(player) == "Instance" and player and player.Parent then
		-- Online session data
		if not DataStoreModule:WaitForData(player) then
			DebugLog("[ERROR] * RemoveKey Failed: Data not loaded for", player.Name)
		else
			IsPlayerOnline = true
		end

		if IsPlayerOnline then
			local current = sessionData[userId]
			if not current then
				DebugLog("[ERROR] * RemoveKey Failed: No session data for", player.Name)
				return false
			end

			-- Traverse to the second-to-last key
			for i = 1, #keys - 1 do
				local key = keys[i]
				if typeof(current[key]) ~= "table" then
					DebugLog("[WARNING] * RemoveKey Failed: Path does not exist at", table.concat(keys, ".", 1, i), "for", player.Name)
					return false
				end
				current = current[key]
			end

			local finalKey = keys[#keys]
			if current[finalKey] ~= nil then
				current[finalKey] = nil
				DebugLog("Removed", table.concat(keys, "."), "from", player.Name)

				return true
			else
				DebugLog("[WARNING] * Key not found:", table.concat(keys, "."), "for", player.Name)

				return false
			end
		end
	end

	if not player or not IsPlayerOnline then
		-- Offline mode
		if not DataStoreModule.OfflineModeEnabled then return false end

		local UserOfflineData = DataStoreModule:LoadOfflineData(userId)

		if UserOfflineData then
			local current = UserOfflineData

			for i = 1, #keys - 1 do
				local key = keys[i]
				if typeof(current[key]) ~= "table" then
					DebugLog("[WARNING] * Offline RemoveKey Failed: Path does not exist at", table.concat(keys, ".", 1, i), "for", userId)
					return false
				end
				current = current[key]
			end

			local finalKey = keys[#keys]
			if current[finalKey] ~= nil then
				current[finalKey] = nil
				DebugLog("Offline Removed", table.concat(keys, "."), "for", userId)

				local CurrentTimeUnixUTC = os.time()

				--publishMessage({
				--	Action = "RemoveKey",
				--	UserId = userId,
				--	Arguments = keys,
				--	Time = CurrentTimeUnixUTC
				--})
				
				local GUID: string = HttpService:GenerateGUID(false)
				addToQueue(UserOfflineData, GUID)

				if DataStoreModule.DoubleMessages then
					self:_PublishMessage("RemoveKey", userId, GUID, keys)
				end
				local SavedOfflineDataResult = self:SaveOfflineData(userId, UserOfflineData)
				self:_PublishMessage("RemoveKey", userId, GUID, keys)
				return SavedOfflineDataResult
			else
				DebugLog("[WARNING] * Offline Key not found:", table.concat(keys, "."), "for", userId)
			end
		else
			DebugLog("[ERROR] * Offline RemoveKey Failed: No data for", userId)
		end
	end

	return false
end


--[[
	Removes a player's session data from memory (not from the data store).

	@param player Player -- The player to remove from session cache
]]
function DataStoreModule:_RemovePlayerCache(player: Player)
	local userId = tostring(player.UserId)

	DebugLog("Removing player cache for", player.Name)
	sessionData[userId] = nil
end

--[[
	Removes all cached session data for all players from memory.
	
	This is useful if you want to completely wipe the in-memory session cache,
	e.g., after a mass save or during testing.

	Warning: This does NOT save or modify any data in the DataStore itself.
	Call `:_SaveAll()` first if you want to persist changes before clearing memory.
]]
function DataStoreModule:_RemoveAllPlayerCache()
	DebugLog("Clearing all session data from memory")
	sessionData = {}
end

--[[
	Saves data for all currently connected players.
	
	This is useful for:
	- Manual saving (e.g., via an admin command or timed autosave)
	- Ensuring all player data is saved before a server shutdown
	
	Usage:
	Call DataStoreModule:_SaveAll() when needed, such as from a BindToClose handler or a timer.
	
	@param ReleaseLock boolean? -- Should release lock for player?
]]

function DataStoreModule:_SaveAll(ReleaseLock: boolean?)
	DebugLog("Saving data for all players...")
	for _, player in ipairs(Players:GetPlayers()) do
		local userId = tostring(player.UserId)

		if cachedLastSaves[userId] and os.clock() - cachedLastSaves[userId] < AutoSaveInterval then continue end

		DataStoreModule:_SaveData(player)

		if saveQueues[userId] ~= nil and #saveQueues[userId] > 0 then
			repeat task.wait() until saveQueues[userId] == nil or #saveQueues[userId] <= 0
		end

		if ReleaseLock and not SessionLocksReleasedBeforeShutdown[userId] then
			SessionLockModule:ReleaseLock(userId)
		end

		task.wait()
	end
end

function DataStoreModule:EraseUserDataGAME(userId: number | string)
	userId = tostring(userId)

	local dataStore = originaldataStore

	local success, removedValue = pcall(function()
		return dataStore:RemoveAsync(DataStoreKeyName .. "_" .. userId)
	end)

	if success then
		DebugLog("EraseUserData - Delete User Data Successful for UserID:", userId)

		return true
	else
		DebugLog("[ERROR] * EraseUserData Failed for UserID: ", userId, removedValue)
	end

	return false
end

-- In compliance with GDPR - Request to erase all data associated with the user's account.
function DataStoreModule:EraseUserData(userId: number | string)
	userId = tostring(userId)

	local dataStore = DataStoreModule.EraseUser_Use_NormalDatastore_Always and originaldataStore or dataStore

	local success, removedValue = pcall(function()
		return dataStore:RemoveAsync(DataStoreKeyName .. "_" .. userId)
	end)

	if success then
		DebugLog("EraseUserData - Delete User Data Successful for UserID:", userId)

		return true
	else
		DebugLog("[ERROR] * EraseUserData Failed for UserID: ", userId, removedValue)
	end

	return false
end

--- Prevents saving a player's data to the DataStore when they leave the game.
--- 
--- This only affects the player's current session. If the player rejoins,
--- their data will load and save normally again.
---
--- It doesn't affect SaveOfflineData.
---
--- ⚠️ Note:
--- - This is not 100% reliable if you have logic that triggers a save immediately
---   when the player leaves (e.g. calling `SetValue`).
--- - Always perform your own checks (e.g. with `:HasData`) before triggering those functions that support offline/online.
---
--- @param player Player | number | string
---   The player whose data should not be saved on leave.
---   - `Player`: Roblox Player instance.
---   - `number`: The UserId of the player.
---   - `string`: The UserId as a string.
---
--- @return boolean
---   Returns `true` if the flag to disable saving was successfully set,
---   or `false` if the player's data was not loaded or unavailable.
function DataStoreModule:_DontSaveOnLeaveForPlayer(player: Player | number | string) : boolean
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)

	-- Wait for data to be loaded before returning it
	if not DataStoreModule:WaitForData(player) then
		-- Data not loaded (timeout or player left)
		return false
	end

	if not sessionData[userId] then return false end
	
	DebugLog("Disabling save on leave for player: " .. player.Name .. " at the request of the server.")
	
	cachedDisabledSaves[userId] = true
	
	return true
end

function DataStoreModule:_clearOfflineHandle(player: Player | number | string) : boolean
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)

	if OfflineHandles[userId] then
		OfflineHandles[userId] = nil
		OfflineSessionLockModule:ReleaseLock(userId)
		return true
	else
		return false
	end
end

-- Returns the player's queue table if available
function DataStoreModule:GetQueueTbl(player: Player | number | string): { { GUID: string, Info: any } }?
	local player: Player?, userId: string = Utility:resolvePlayerAndUserId(player)
	if not player then return nil end

	local userData = sessionData[userId]
	if not userData then return nil end

	local meta = userData.__meta
	if not meta then return nil end

	local queue: { { GUID: string, Info: any } }? = meta.QueueTbl
	return queue
end

function DataStoreModule:_EnsureProfileLoaded(Player: Player)
	if not Player:GetAttribute("ProfileLoaded") then
		while not Player:GetAttribute("ProfileLoaded") do
			if not Player:IsDescendantOf(Players) then
				return false
			end
			task.wait(0.1)
		end
	end

	return true
end

--[[
	Registers a callback function that runs when a player leaves the game.
	This gets executed right before PlayerDataStore releases/saves session.

	@param callback (player: Player) -> ()
		A function that takes the player instance and performs cleanup or saving operations.

	@return LeaveConnection
		A handle with a :Disconnect() method to remove this callback later.

	@example
	local conn = DataStoreModule.BindToLeave(function(player)
		print("Saving data for", player.Name)
	end)

	-- Later you can also disconnect it:
	conn:Disconnect()
]]
function DataStoreModule.BindToLeave(callback: LeaveCallback): LeaveConnection
	if typeof(callback) ~= "function" then
		error("BindToLeave expects a function, got " .. typeof(callback))
	end

	table.insert(leaveCallbacks, callback)
	local index = #leaveCallbacks

	local handle: LeaveConnection = {}
	function handle:Disconnect()
		-- Try removing at stored index first
		if leaveCallbacks[index] == callback then
			table.remove(leaveCallbacks, index)
		else
			-- fallback: search in case indices shifted
			for i, cb in ipairs(leaveCallbacks) do
				if cb == callback then
					table.remove(leaveCallbacks, i)
					break
				end
			end
		end
	end

	return handle
end


-- Internal: Run all leave callbacks for a player and yield until all finish
local function runLeaveCallbacks(player: Player)
	local total = #leaveCallbacks
	if total == 0 then return end

	local doneCount = 0

	for _, callback in ipairs(leaveCallbacks) do
		task.spawn(function()
			local success, err = pcall(callback, player)
			if not success then
				warn(`[PlayerDataStore] Error in leave callback: {err}`)
			end
			doneCount += 1
		end)
	end

	-- Yield until all callbacks complete
	while doneCount < total do
		task.wait()
	end
end

-- Internal cleanup on leave
local function onPlayerAdded(player)
	local userId = tostring(player.UserId)
	DebugLog(player.Name, "joined the game")
	
	if player:GetAttribute("ProfileLoaded") then return end
	
	if DataHandler.earlyPlayerAdded then
		task.spawn(DataHandler.earlyPlayerAdded, player)
	end
	
	if DataHandler.characterAdded then
		task.spawn(DataHandler.characterAdded, player)
	end
	
	local Profile = DataStoreModule:_LoadData(player)

	if Profile then
		local ProfileData: typeof(Template) = sessionData[userId]

		if ProfileData then
			if player:GetAttribute("ProfileLoaded") then return end
			player:SetAttribute("ProfileLoaded", true)

			DataHandler.playerAdded(player, ProfileData)
		end
	end
end

local function onPlayerRemoving(player)
	local userId = tostring(player.UserId)
	
	DebugLog(player.Name, "leaving the game")
	
	DataHandler.playerRemoving(player)
	
	runLeaveCallbacks(player)

	DataStoreModule:_SaveData(player)

	if saveQueues[userId] ~= nil and #saveQueues[userId] > 0 then
		repeat task.wait(0.1) until saveQueues[userId] == nil or #saveQueues[userId] <= 0
	end

	CachedLastSessionUpdates[userId] = nil
	sessionData[userId] = nil

	if IsServerShuttingDown then
		SessionLocksReleasedBeforeShutdown[userId] = true
	end
	
	if DataHandler.latePlayerRemoving then
		task.spawn(DataHandler.latePlayerRemoving, player)
	end

	SessionLockModule:ReleaseLock(userId)
	DebugLog(player.Name, " released session lock")

	cachedLastSaves[userId] = nil
	cachedDisabledSaves[userId] = nil

	if IsStudio then
		if DataStoreModule.DoNotSaveDataInStudio then
			if DataStoreModule.DeleteUserDataAtLeaveInStudio then
				DebugLog("[STUDIO-ONLY] - Deleting User Data at Leave:", userId)

				local success, removedValue = pcall(function()
					return dataStore:RemoveAsync(DataStoreKeyName .. "_" .. userId)
				end)

				if success then
					DebugLog("[STUDIO-ONLY] - Delete User Data Successful for UserID:", userId)
				else
					DebugLog("[STUDIO-ONLY] - [ERROR] * Delete User Data Failed for UserID: ", userId, removedValue)
				end
			end
		end
	end
	
	Sessions[userId] = nil
end

----------------------------------------------------
-- 📬 Handle incoming messages
----------------------------------------------------
function DataStoreModule:_handleMessage(data)
	if typeof(data) ~= "table" or not data.Action or not data.UserId then
		DebugLog("MessageService: Invalid message format")
		return
	end
	
	if not data.ServerId then return end
	if data.ServerId == serverId then return end

	local userId = tostring(data.UserId)

	local player = Players:GetPlayerByUserId(tonumber(userId))
	if not player then return end

	DebugLog("MessageService:", data.Action, "for user", userId)

	local HasValidArguments = typeof(data.Arguments) == "table" and next(data.Arguments) ~= nil
	if not HasValidArguments then
		warn("DataStoreModule:_handleMessage: Invalid Arguments")
		return 
	end

	if not self:WaitForData(player) then
		return
	end

	local userData = sessionData[userId]
	if not userData then return end
	
	local GUID = data.GUID
	if not GUID then return end
	
	local AddedToQueue: boolean = addToQueue(userData, GUID)
	if not AddedToQueue then return end -- already exists

		----------------------------------------
		-- 🧱 Action: SetValue
		----------------------------------------
	if data.Action == "SetValue" then
		local keys, value = Utility.parseArgs(table.unpack(data.Arguments))
		Utility.setNestedValue(userData, keys, value)

		DebugLog("MessageService: Applied SetValue", table.concat(keys, "."), "=", value)

		----------------------------------------
		-- 🧩 Action: BulkUpdate
		----------------------------------------
	elseif data.Action == "BulkUpdate" then
		local function applyChanges(tbl, prefix)
			prefix = prefix or {}
			for key, value in pairs(tbl) do
				local path = table.clone(prefix)
				table.insert(path, key)

				if type(value) == "table" then
					applyChanges(value, path)
				else
					Utility.setNestedValue(userData, path, value)
					DebugLog("MessageService: Applied BulkUpdate key:", table.concat(path, "."), "value:", value)
				end
			end
		end

		applyChanges(data.Arguments)
		
		----------------------------------------
		-- 🧱 Action: Insert
		----------------------------------------
	elseif data.Action == "Insert" then
		local keys, value = Utility.parseArgs(table.unpack(data.Arguments))
		local target = Utility.getNestedValue(userData, keys)

		if type(target) ~= "table" then
			DebugLog("[ERROR] Insert failed: Target is not a table at", table.concat(keys, "."))
			return
		end

		table.insert(target, value)
		DebugLog("MessageService: Inserted", value, "into", table.concat(keys, "."))

		----------------------------------------
		-- 📨 Action: QueueInsert
		----------------------------------------
	elseif data.Action == "QueueInsert" then
		local tbl = data.Arguments
		if not tbl then
			DebugLog("[ERROR] QueueInsert failed: no value provided")
			return
		end

		-- Ensure __meta.QueueTbl exists
		userData.__meta = userData.__meta or {}
		userData.__meta.QueueTbl = userData.__meta.QueueTbl or {}

		table.insert(userData.__meta.QueueTbl, tbl)
		DebugLog("MessageService: QueueInserted", tbl, "into __meta.QueueTbl for user", userId)

		----------------------------------------
		-- ❌ Action: RemoveKey
		----------------------------------------
	elseif data.Action == "RemoveKey" then
		local keys = data.Arguments
		local current = userData

		for i = 1, #keys - 1 do
			if typeof(current[keys[i]]) ~= "table" then return end
			current = current[keys[i]]
		end

		local finalKey = keys[#keys]
		current[finalKey] = nil

		DebugLog("MessageService: Removed key", table.concat(keys, "."))

		----------------------------------------
		-- ➕ Action: Increment
		----------------------------------------
	elseif data.Action == "Increment" then
		local args = data.Arguments
		local amount = tonumber(args[#args]) or 1
		local keys = table.move(args, 1, #args - (tonumber(args[#args]) and 1 or 0), 1, {})

		local oldValue = tonumber(Utility.getNestedValue(userData, keys) or 0) or 0
		local newValue = oldValue + amount
		Utility.setNestedValue(userData, keys, newValue)

		DebugLog("MessageService: Incremented", table.concat(keys, "."), "from", oldValue, "to", newValue)
	end

	if not Utility.isJSONAcceptable(userData) then
		if DataStoreModule.BufferEncoder then
			if DataStoreModule.DebugJSON_Notes then
				DebugLog("MessageService - "..data.Action.." - Data is not JSON-encodable - UserId:", userId)
			end
		else
			warn("[PlayerDataStore] MessageService - "..data.Action.." - Data is not JSON-encodable - UserId:", userId)
		end
	end
end

if RunService:IsServer() and RunService:IsRunning() and not DataStoreModule.Cache.Running then
	DataStoreModule.Cache.Running = true
	-- This block runs only on the live server (not in Studio edit mode or command line)
	
	-- Save Data on Close
	game:BindToClose(function()
		IsServerShuttingDown = true

		wait(0.1)
		
		DebugLog("Server shutting down")
		
		-- Wait until Sessions is empty
		while next(Sessions) or next(sessionData) do
			task.wait(0.1)
		end

		--DebugLog("Server shutting down - Saving Data")

		--DataStoreModule:_SaveAll(true)
		
		task.wait()
	end)
	
	-- 📥 Subscribe to messages (receive from other servers)
	local function subscribeToMessages()
		if not DataStoreModule.ListenToMessageService then return end
		
		local success, connection = pcall(function()
			return MessagingService:SubscribeAsync(MessageTopicName, function(message)
				if not DataStoreModule.ListenToMessageService then return end

				local data = message.Data

				DebugLog("Received message from another server:", data)

				return DataStoreModule:_handleMessage(data)
			end)
		end)

		if not success then
			warn("[PlayerDataStore]: Failed to subscribe to messages:", connection)
		else
			DebugLog("MessageService: Subscribed to topic:", MessageTopicName)
		end
	end

	subscribeToMessages()
	
	DataHandler.init(function(player: Player, no_wait: boolean?) : typeof(Template)
		return DataStoreModule:GetData(player, no_wait) :: typeof(Template)
	end)

	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for i, Player in pairs(Players:GetPlayers()) do
		--onPlayerAdded(Player)
		task.spawn(onPlayerAdded, Player)
	end

	-- Autosave

	if AutoSave then
		task.spawn(function()
			while true do
				task.wait(AutoSaveInterval)

				if IsServerShuttingDown then break end

				DataStoreModule:_SaveAll()
			end
		end)
	end

	task.spawn(function()
		while true do
			wait(RefreshSessionsEverySecond)
			RefreshAllPlayersSessionLocks()
		end
	end)
end

return DataStoreModule