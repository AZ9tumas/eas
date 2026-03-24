local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local monthStrMap = {
	Jan = 1,
	Feb = 2,
	Mar = 3,
	Apr = 4,
	May = 5,
	Jun = 6,
	Jul = 7,
	Aug = 8,
	Sep = 9,
	Oct = 10,
	Nov = 11,
	Dec = 12
}

local isInited = false
local originTime = nil
local responseTime = nil
local responseDelay = nil


local function RFC2616DateStringToUnixTimestamp(dateStr: string)
	local day, monthStr, year, hour, min, sec = dateStr:match(".*, (.*) (.*) (.*) (.*):(.*):(.*) .*")
	local month = monthStrMap[monthStr]
	local date = {
		day=day,
		month=month,
		year=year,
		hour=hour,
		min=min,
		sec=sec
	}
	
	return os.time(date :: any)
end


local SyncedTime = {}

function SyncedTime.inited()
	return isInited
end

function SyncedTime.init()
	if not isInited then
		local ok = pcall(function()
			assert(not RunService:IsClient())

			local requestTime = tick()
			local response = HttpService:RequestAsync({
				Url = "http://google.com"
			} :: any) 
			local dateStr = response.Headers.date
			originTime = RFC2616DateStringToUnixTimestamp(dateStr)
			responseTime = tick()
			-- Estimate the response delay due to latency to be half the rtt time
			responseDelay = (responseTime-requestTime)/2
		end)
		if not ok then
			if RunService:IsServer() or RunService:IsStudio() then
				warn("Cannot get time from google.com. Make sure that http requests are enabled!")
			end
			originTime = os.time()
			responseTime = tick()
			responseDelay = 0
		end
		
		isInited = true
	end
end

function SyncedTime.time(): number
	if not isInited then
		SyncedTime.init()
	end
	if type(originTime) ~= "number" or type(responseTime) ~= "number" or type(responseDelay) ~= "number" then
		return 0
	end
	return originTime + tick() - responseTime - responseDelay
end


task.spawn(SyncedTime.init)
return SyncedTime