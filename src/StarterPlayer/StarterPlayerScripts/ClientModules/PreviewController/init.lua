local PreviewController = {}

-- Init Bridg Net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = ReplicatedStorage.Utility
local BridgeNet2 = require(Utility.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("PreviewService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridg Net

local UserInputService = game:GetService("UserInputService")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseController = require(Players.LocalPlayer.PlayerScripts.ClientModules.BaseController)
local ClientUtil = require(Players.LocalPlayer.PlayerScripts.ClientModules.ClientUtil)

local currentItemName = ""
local currenItemType = ""
function PreviewController:Init()
	PreviewController:InitButtonListerns()
end

function PreviewController:InitButtonListerns()
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end -- ignora se o jogador estiver digitando em um TextBox

		if input.KeyCode == Enum.KeyCode.R then
			local slot = nil
			local subSlot = nil
			if workspace:FindFirstChild("Preview") then
				local preview = workspace.Preview
				local previewPos = preview:GetPivot().Position
				local regionSize = Vector3.new(2, 50, 2)

				local detector = Instance.new("Part")
				detector.Size = regionSize
				detector.CFrame = CFrame.new(previewPos.X, 6.25, previewPos.Z)
				detector.Anchored = true
				detector.CanCollide = true -- precisa ser true para GetTouchingParts
				detector.Transparency = 1
				detector.Parent = workspace

				-- Pega todas as partes que estão tocando
				local touching = detector:GetTouchingParts()

				local slot, subSlot
				for _, p in ipairs(touching) do
					if p:GetAttribute("GRID_TYPE") == "SUB_SLOT" then
						slot = p.Parent.Name
						subSlot = p.Name
					end
				end

				detector:Destroy()

				local result = bridge:InvokeServerAsync({
					[actionIdentifier] = "SetItem",
					data = {
						ItemType = currenItemType,
						ItemName = currentItemName,
						Slot = slot,
						SubSlot = subSlot,
					},
				})
			end
		end
	end)
end

function PreviewController:GetStartBasePart()
	local base = BaseController:GetBase()

	if base then
		local baseTemplate = ClientUtil:WaitForDescendants(base, "baseTemplate")

		local baseSlots = ClientUtil:WaitForDescendants(baseTemplate, "baseSlots")

		local slots = ClientUtil:WaitForDescendants(baseSlots, "slots")

		local model1 = ClientUtil:WaitForDescendants(slots, "1")

		local part1 = ClientUtil:WaitForDescendants(model1, "1")

		return part1.Position
	end
end

function PreviewController:GetItemFromTypeAndName(unitType: string, unitName: string)
	local unitsFolder = ReplicatedStorage.developer.units
	local items = {
		["BLOCK"] = unitsFolder.blocks,
		["MELEE"] = unitsFolder.melee,
		["RANGED"] = unitsFolder.ranged,
		["TRAP"] = unitsFolder.trap,
	}

	if items[unitType] then
		local item = items[unitType]:FindFirstChild(unitName)

		if item then
			return item:Clone()
		end
	end
end

function PreviewController:Start(unitType: string, unitName: string)
	currentItemName = unitName
	currenItemType = unitType

	local gridSize = Vector3.new(4, 2, 4) -- tamanho da grid
	local gridOrigin = PreviewController:GetStartBasePart() -- ponto inicial da grid (ajuste para sua grid real)

	-- Remove qualquer preview antigo
	if workspace:FindFirstChild("Preview") then
		workspace.Preview:Destroy()
	end

	local model = PreviewController:GetItemFromTypeAndName(unitType, unitName)
	model.PrimaryPart.Transparency = 0.5
	model.PrimaryPart.CanCollide = false
	model.PrimaryPart.CanCollide = false
	model.PrimaryPart.Anchored = true

	local rotation = CFrame.Angles(0, (player:GetAttribute("BASE") % 2 == 0 and 0 or math.rad(180)), 0)

	model:SetPrimaryPartCFrame(CFrame.new(model.PrimaryPart.Position + Vector3.new(0, 0, 0)) * rotation)

	-- Ignora o player e o preview no raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character, model }

	local function getMousePosition()
		local unitRay = mouse.UnitRay
		local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)
		if raycastResult then
			return raycastResult.Position
		end
		return nil
	end

	-- Função para alinhar com a grid
	local function snapToGridXZ(pos)
		local relative = pos - gridOrigin

		-- Calcula X e Z alinhados à grid
		local x = math.floor(relative.X / gridSize.X + 0.5) * gridSize.X
		local z = math.floor(relative.Z / gridSize.Z + 0.5) * gridSize.Z

		-- Bounding box do modelo
		local bboxCFrame, bboxSize = model:GetBoundingBox()
		local baseY = bboxCFrame.Position.Y - (bboxSize.Y / 2)

		-- Chão alvo
		local targetY = 8.501
		local offsetY = targetY - baseY

		-- Move o modelo inteiro
		local newPivot = model:GetPivot()
			+ Vector3.new(x + gridOrigin.X - bboxCFrame.Position.X, offsetY, z + gridOrigin.Z - bboxCFrame.Position.Z)

		model:PivotTo(newPivot)

		-- Retorna só a posição final do pivot (se precisar usar depois)
		return newPivot.Position
	end

	local startPos = getMousePosition()
	if startPos then
		local snapped = snapToGridXZ(startPos)
		model:PivotTo(CFrame.new(snapped))
	end

	model.Name = "Preview"
	model.Parent = workspace

	local smoothFactor = 0.4 -- movimento suave
	local currentPosition = model:GetPivot().Position

	-- Cria a parte de visualização
	local previewPart = Instance.new("Part")
	previewPart.Name = "PreviewArea"
	previewPart.Anchored = true
	previewPart.CanCollide = false

	previewPart.Transparency = 0
	previewPart.Color = Color3.fromRGB(76, 0, 255) -- azul claro
	previewPart.Material = Enum.Material.ForceField
	previewPart.Shape = Enum.PartType.Cylinder
	previewPart.Parent = workspace

	-- Defina aqui os offsets da área
	local xOffset = 10 -- esquerda/direita
	local zOffset = 15 -- frente/trás
	local yHeight = 0.1 -- altura fixa

	local radius = 15
	local thickness = 0.1

	-- No Roblox, Cylinder é deitado no eixo X por padrão
	previewPart.Size = Vector3.new(thickness, radius * 2, radius * 2)

	-- Rotaciona para ficar deitado no chão
	previewPart.CFrame = CFrame.new(Vector3.new(0, 0, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local horizontalCFrameRotation = CFrame.Angles(0, 0, math.rad(90))

	self.previewConnection = RunService.RenderStepped:Connect(function()
		local targetPos = getMousePosition()
		if targetPos then
			local snapped = snapToGridXZ(targetPos)

			-- Move o modelo
			model:PivotTo(CFrame.new(snapped))

			-- Alinha a parte da área no mesmo centro
			previewPart.CFrame = CFrame.new(snapped + Vector3.new(0, 0, 0)) * horizontalCFrameRotation
		end
	end)
end

return PreviewController
