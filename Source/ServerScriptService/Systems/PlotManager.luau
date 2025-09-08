local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plotTemplate =
	ReplicatedStorage.Assets.PlotTemplate :: Folder & { Base: BasePart, DesignRack: BasePart, TowerBase: BasePart }
local plotsFolder = workspace:FindFirstChild("Plots") :: Folder

local plots = {}
local occupiedPlots = {}

local function getAvailablePlot()
	for plot, data in plots do
		if not data.owner then
			return plot
		end
	end
	return nil
end

local PlotManager = {}

function PlotManager:GetPlayersTowerBase(player)
	local plotData = occupiedPlots[player]
	if plotData then
		return plotData.towerBase
	end
	return nil
end

function PlotManager:PlayerAdded(player)
	local selectedPlot = getAvailablePlot()
	if not selectedPlot then
		error("No available plots for player: " .. player.Name)
		return
	end

	local plotModel = Instance.new("Model")
	for _, item in plotTemplate:GetChildren() do
		local clonedItem = item:Clone()
		clonedItem.Transparency = 1
		clonedItem.Parent = plotModel
	end

	plotModel.PrimaryPart = plotModel.Base
	plotModel.Name = "Plot_" .. player.UserId
	plotModel.Parent = workspace

	plotModel:PivotTo(selectedPlot:GetPivot())

	plots[selectedPlot].owner = player
	occupiedPlots[player] = {
		plot = selectedPlot,
		plotBase = plotModel.Base,
		towerBase = plotModel.TowerBase,
		designRack = plotModel.DesignRack,
	}
end

function PlotManager:PlayerRemoving(player)
	local plotData = occupiedPlots[player]
	if plotData then
		plots[plotData.plot].owner = nil
		occupiedPlots[player] = nil
	end
end

function PlotManager:Init()
	if not plotsFolder then
		warn("Plots folder not found in workspace.")
		return
	end

	for _, plot in plotsFolder:GetChildren() do
		plots[plot] = {
			owner = nil,
			plot = plot,
		}
	end

	Players.PlayerAdded:Connect(function(player)
		PlotManager:PlayerAdded(player)
	end)

	for _, player in pairs(Players:GetPlayers()) do
		PlotManager:PlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		PlotManager:PlayerRemoving(player)
	end)
end

return PlotManager
