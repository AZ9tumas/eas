-- This is a script you would create in ServerScriptService, for example.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cmdr = require(script.Parent:WaitForChild("Cmdr"))

Cmdr:RegisterDefaultCommands() -- This loads the default set of commands that ranu comes with. (Optional)
Cmdr:RegisterHooksIn(script:WaitForChild("Hooks"))