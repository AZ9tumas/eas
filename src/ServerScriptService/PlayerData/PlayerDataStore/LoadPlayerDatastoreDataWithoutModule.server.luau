--[[

This is for Tutorial
In case BufferEncoder is/was enabled, and the player data is in 'buffer' instead of 'table/JSON(string)'

]]

local DatastoreService = game:GetService("DataStoreService")
local BufferEncoder = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("BufferEncoder"))

local Datastore = DatastoreService:GetDataStore("PlayerDataStore")

local TargetUserId = 3267747943

-- Method 1 (Convenient):
--(use the playerdatastore module LoadOfflineData while in Studio->Run without Play)
--playerdatastore:LoadOfflineData(userid, true)

-- Method 2
local Data: buffer = Datastore:GetAsync("$Player_" .. tostring(TargetUserId))

print("METHOD 2")
print(Data)
print(BufferEncoder.read(Data))

-- Method 3
-- Take the data from Datastore Manager in create.roblox.com

local HttpService = game:GetService("HttpService")

-- ex:

local data = [[
{
	"m": null,
	"t": "buffer",
	"zbase64": "KLUv/WDSAkUSAFbkfkUgrTYHgERAkIwnCgrvwjj+CLAgUIB0aQCzAK/btpK8LXL+CzcmCS6QNxWt9/MBGxNe64MG6rRHK2RnhyksvPKrra3Z3gFoAGYAZwBjU412tiSPg5OU8Z2jz3udj001PLao85rutslNwpK9IZ2Ds2mGWyTAf52LU7ylbWyRhSbBeI3EPiOvZ6+Gc3XQRZ8f9yHgPw8bKnDyR7UTY9/qtBA87+HroqUZ52dHx9iijD3jHmFfBWOLsPe8TmpDsC+p857FVxncVcv5poDj2pEmh6C9mud5rdijarLfVt1BcIsM+I3E1N5cbVbxlsTO+c/BDrl4r7bE4sC4aZar31vKsPdwnRSsd+y4P+6WekTjM34tioO0yOdFbBycpJr1mHTuQn5cyd7s+o7Mtam2eQvp1WnaNl8hc5033K6vrodgZwVMXtLhqDjS6TyxJNc7vv7lCNdX1SU7z05D0GYW752D0ztP4ezI9ZU35knnSd+SyO8cYfxHXfQRvxMlBDvzvOcmHBwUxZIBhsHJ43ECtCIlaEVKkIoKh1MHijolQNEgBIzHB4qiQhRFYQjRcDKx4LMR0xLaiGkBpQBR4nSAwIgQ5vISwlxeMvzC3KxnIfEADBmYgCCj2pkntlrFVwBwlcB5DenX5m3zGZK2i25y/UfmdqB5DBnaK7LeI1O4GRwAN+oEEDKZIQPgHDIeNqABhBwcAwgDjgEZp1H8xqUBYiPO7I9ly05nbHMeFl4F0zDE2DrNFZ/mZGCnr3KTVO4ONd/ok1MwBmUG"
}
]]

-- You wanna first put the code in a {} if its not already so JSONDecode works
-- Second ahead of JSONDecode, you wanna nullify the "m" key so roblox properly decodes it into buffer
--[[
Before:
  "m": {
    "nullValue": "NULL_VALUE",
    "kind": "nullValue"
  },

After:
  "m": null,

]]

local Decoded: buffer = HttpService:JSONDecode(data)

print("METHOD 3")
print(Decoded)
print(BufferEncoder.read(Decoded))