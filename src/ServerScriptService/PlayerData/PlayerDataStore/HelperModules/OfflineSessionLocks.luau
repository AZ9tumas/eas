local SessionLocks = {}

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local Configuration = script.Parent.Parent.Configuration
local SessionMemoryStoreName = Configuration.OfflineSessionMemoryStoreName.Value
local SessionLockTimeoutMinutes = Configuration.SessionLockTimeoutMinutes.Value

local MemoryStoreKeyName = SessionMemoryStoreName
local BeSoftOnErrors: boolean = true

-- Safely create the sorted map
local sessionKeyStore
do
	local ok, result = pcall(function()
		return MemoryStoreService:GetSortedMap(MemoryStoreKeyName)
	end)
	if ok then
		sessionKeyStore = result
	else
		warn("[OfflineSessionLocks] ⚠️ Failed to get MemoryStore SortedMap: ", result)
		sessionKeyStore = nil
	end
end


local LOCK_TIMEOUT = SessionLockTimeoutMinutes * 60
local serverId = game.JobId

function SessionLocks:GetLockKey(userId)
	return tostring(userId)
end

function SessionLocks:TryLockPlayer(userId, resetTimeout: boolean?, customBeSoftOnErrors: boolean?)
	local beSoftOnErrors = (customBeSoftOnErrors ~= nil) and customBeSoftOnErrors or BeSoftOnErrors
	
	if not sessionKeyStore then
		warn("[OfflineSessionLocks] MemoryStore SessionLock 'sessionKeyStore' Error!")
		if beSoftOnErrors then
			warn("[OfflineSessionLocks] Ignoring, however, Data corruption / Data loss possible since session lock isn't working")

			return true
		end
	end

	local key = SessionLocks:GetLockKey(userId)
	local now = os.time(os.date("!*t"))

	local success, existing = pcall(function()
		return sessionKeyStore:GetAsync(key)
	end)
	
	if not success then
		warn("[OfflineSessionLocks] MemoryStore SessionLock GetAsync Error:", existing)
		
		if beSoftOnErrors then
			return true
		end
	end

	local lockData = HttpService:JSONEncode({
		server = serverId,
		timestamp = now,
	})

	if success and existing then
		--local info = HttpService:JSONDecode(existing)
		local ok, info = pcall(function()
			return HttpService:JSONDecode(existing)
		end)
		if ok and info and (now - info.timestamp) < LOCK_TIMEOUT then
			if resetTimeout then
				-- Reset the lock timeout by re-setting the lock with updated timestamp

				local successSet, err = pcall(function()
					sessionKeyStore:SetAsync(key, lockData, LOCK_TIMEOUT)
				end)

				if successSet then
					return true -- Lock refreshed successfully
				else
					warn("[OfflineSessionLocks] Failed to reset lock timeout for user " .. userId .. ": " .. err)
					if not beSoftOnErrors then
						return false
					end
				end
			else
				warn(`[OfflineSessionLocks] User {userId} is already locked by server {info.server}`)
				return false
			end
		end
	elseif not success then
		warn("[OfflineSessionLocks] MemoryStore SessionLock Error!")
		warn(success, existing)
	end

	local successSet, err = pcall(function()
		sessionKeyStore:SetAsync(key, lockData, LOCK_TIMEOUT)
	end)

	if successSet then
		return true
	else
		warn("[OfflineSessionLocks] Failed to set lock for user " .. userId .. ": " .. err)
		if not beSoftOnErrors then
			return false
		end
	end
end

function SessionLocks:IsPlayerLocked(userId)
	if not sessionKeyStore then
		warn("[OfflineSessionLocks] MemoryStore SessionLock 'sessionKeyStore' not initialized.")
		return nil
	end

	local key = SessionLocks:GetLockKey(userId)
	local now = os.time(os.date("!*t"))

	local success, existing = pcall(function()
		return sessionKeyStore:GetAsync(key)
	end)

	if not success then
		warn("[OfflineSessionLocks] MemoryStore SessionLock GetAsync Error:", existing)
		return nil
	end

	if not existing then
		return false -- No lock found
	end

	local ok, info = pcall(function()
		return HttpService:JSONDecode(existing)
	end)

	if not ok or not info or not info.timestamp then
		warn(`[OfflineSessionLocks] Invalid session data for user {userId}`)
		return nil
	end

	-- Check if the lock is still valid
	local isLocked = (now - info.timestamp) < LOCK_TIMEOUT
	return isLocked
end

function SessionLocks:ReleaseLock(userId)
	local key = SessionLocks:GetLockKey(userId)
	pcall(function()
		sessionKeyStore:RemoveAsync(key)
	end)
end

return SessionLocks