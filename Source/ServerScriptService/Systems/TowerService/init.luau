local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Blocks = require(ReplicatedStorage.Data.Blocks)
local PlotManager = require(ServerScriptService.Systems.PlotManager)

local towerDesigns = {}
local builtTowers = {}

local TowerService = {
	Priority = 2,
}

function TowerService:GetTowerDesign(player)
	return towerDesigns[player.UserId] or {}
end

function TowerService:SetTowerDesign(player, design)
	-- Validate design
	for _, blockName in design do
		if not Blocks[blockName] then
			error("Invalid block name in design: " .. tostring(blockName))
			return
		end
	end
	towerDesigns[player.UserId] = design
end

function TowerService:GetTowerBase(player)
	return PlotManager:GetPlayersTowerBase(player)
end

function TowerService:BuildTower(player)
	local design = TowerService:GetTowerDesign(player)
	local towerBase = TowerService:GetTowerBase(player)

	if not towerBase then
		error("Player does not have a tower base.")
		return
	end

	for _, child in towerBase:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("IsTowerBlock") then
			child:Destroy()
		end
	end

	local buildPosition = towerBase.Position + Vector3.new(0, -towerBase.Size.Y / 2, 0)

	local currentHeight = 0
	for index, blockName in design do
		local blockData = Blocks[blockName]
		if not blockData then
			warn("Skipping invalid block name: " .. tostring(blockName))
			continue
		end

		local remaining = math.max(0, tonumber(blockData.Strength) or 0)
		if remaining == 0 then
			continue
		end

		while remaining > 0 do
			local segment = math.min(remaining, 100)
			segment = segment - (segment % 2)
			if segment <= 0 then
				break
			end

			for i = 1, 3 do
				local originalCFrame = CFrame.new(buildPosition + Vector3.new(0, currentHeight + (segment / 2), 0))
				local offset = originalCFrame.LookVector * (i - 2) * 2

				local trussPart = Instance.new("TrussPart")
				trussPart.Name = string.format("%s %d (%.0f)", blockName, index, segment) .. i
				trussPart.Size = Vector3.new(2, segment, 2)
				trussPart:PivotTo(originalCFrame * CFrame.new(offset))
				trussPart.Color = blockData.Color
				trussPart.Anchored = true
				trussPart.Material = blockData.Material or Enum.Material.Plastic
				trussPart.Parent = towerBase
			end

			local fillPart = Instance.new("Part")
			fillPart.Name = string.format("%s %d (%.0f) Fill", blockName, index, segment)
			fillPart.Size = Vector3.new(1.5, segment, 5.5)
			fillPart:PivotTo(CFrame.new(buildPosition + Vector3.new(0, currentHeight + (segment / 2), 0)))
			fillPart.Color = blockData.Color
			fillPart.Anchored = true
			fillPart.Material = blockData.Material or Enum.Material.Plastic
			fillPart.Parent = towerBase

			currentHeight += segment
			remaining -= segment
		end
	end

	builtTowers[player.UserId] = towerBase
end

function TowerService:PlayerAdded(player)
	-- TODO: Replace with actual design from players saved data
	towerDesigns[player.UserId] = {
		Blocks.Godsteel.Id,
		Blocks.Amberwood.Id,
		Blocks["Hard Ice"].Id,
		Blocks.Stormglass.Id,
		Blocks.Pearlstone.Id,
	}

	TowerService:BuildTower(player)
end

function TowerService:PlayerRemoving(player)
	towerDesigns[player.UserId] = nil
end

function TowerService:Init()
	for _, player in Players:GetPlayers() do
		TowerService:PlayerAdded(player)
	end

	Players.PlayerAdded:Connect(function(player)
		TowerService:PlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		TowerService:PlayerRemoving(player)
	end)
end

return TowerService
