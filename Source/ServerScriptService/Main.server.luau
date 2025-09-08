local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Syscore = require(ReplicatedStorage.Packages.Syscore)

Syscore.AddFolderOfModules(ServerScriptService.Systems)
Syscore.Start()
