local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
-- Generate Base

local function CopyDeveloperFolder()
	local developerFolder = workspace:WaitForChild("developer")
	if not developerFolder then
		warn("Developer Folder Not Found")
		return
	end

	developerFolder.Parent = ReplicatedStorage
end

local function GenerateBases()
	local function GetMapTemplateFromServerStorage()
		local developerFolder = ReplicatedStorage:WaitForChild("developer")
		if not developerFolder then
			warn("Developer Folder Not Found")
			return
		end

		local mapTemplateFolder = developerFolder:WaitForChild("mapTemplate")
		if not mapTemplateFolder then
			warn("MapTemplate Folder  Not Found")
			return
		end

		local baseModel = mapTemplateFolder:WaitForChild("baseTemplate")

		if not baseModel then
			warn("baseModel Not Found")
			return
		end

		return baseModel
	end

	local map = workspace:FindFirstChild("map")

	if not map then
		warn("Map Folder Not Found")
		return
	end

	local baseLocations = map:FindFirstChild("baseLocations")

	if not baseLocations then
		warn("Base Locations Folder Not Found")
		return
	end

	local parts = baseLocations:GetChildren()
	local baseTemplate = GetMapTemplateFromServerStorage()

	if baseTemplate then
		for _, part in parts do
			local newBaseTemplate = baseTemplate:Clone()
			--newBaseTemplate.PrimaryPart:PivotTo(part.CFrame)
			newBaseTemplate:SetPrimaryPartCFrame(part.CFrame)

			newBaseTemplate.Parent = part
		end
		Workspace:SetAttribute("CONFIGURED_BASES", true)
	end
end

CopyDeveloperFolder()
GenerateBases()
