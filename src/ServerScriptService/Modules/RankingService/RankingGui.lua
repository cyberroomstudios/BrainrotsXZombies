local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RankingType = require(ReplicatedStorage.Enums.rankingType)

local RankingGui = {}
RankingGui.__index = RankingGui

-- === CUSTOM TYPES
export type RankingEntry = {
	UserId: number,
	Value: number,
}

export type Options = {
	rankingType: string?,
	maxEntries: number?,
	nameResolver: ((number) -> string)?,
	title: string?,
}

-- === CONSTANTS
local DEFAULT_MAX_ENTRIES: number = 100
local MAX_SUPPORTED_ENTRIES: number = 100
local THUMBNAIL_TYPE = Enum.ThumbnailType.HeadShot
local THUMBNAIL_SIZE = Enum.ThumbnailSize.Size420x420

local PLAYER_NAME_LABEL_PATH = { "Content", "Fields", "Name" }
local PLAYER_VALUE_LABEL_PATH = { "Content", "Fields", "Value", "Name" }
local PLAYER_RANK_LABEL_PATH = { "Content", "Fields", "Rank", "Name" }
local PLAYER_IMAGE_PATH = { "PlayerImage" }

local function findDescendant(instance: Instance?, path: { string }): Instance?
	local current = instance
	for _, name in ipairs(path) do
		if current == nil then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

local function setLabelText(label: Instance?, text: string, color: Color3?)
	if not label then
		return
	end

	if label:IsA("TextLabel") or label:IsA("TextButton") then
		label.Text = text
		if color then
			label.TextColor3 = color
		end
	end
end

local function ensureGuiObject(instance: Instance?, pathDescription: string): GuiObject
	assert(instance ~= nil, `RankingGui expected {pathDescription}`)
	assert(instance:IsA("GuiObject"), `RankingGui expected {pathDescription} to be a GuiObject`)
	return instance
end

local function cloneTemplate(template: GuiObject): GuiObject
	local clone = template:Clone()
	clone.Visible = true
	return clone
end

function RankingGui.new(surfaceGui: SurfaceGui, options: Options?)
	assert(surfaceGui and surfaceGui:IsA("SurfaceGui"), "RankingGui.new expects a SurfaceGui instance")

	options = options or {}

	local self = setmetatable({}, RankingGui)
	self.surfaceGui = surfaceGui

	local mainFrame = surfaceGui:FindFirstChild("Main")
	local mainFrameObject = ensureGuiObject(mainFrame, "SurfaceGui.Main")
	local titleFrame = mainFrameObject:FindFirstChild("Title")
	if titleFrame and titleFrame:IsA("GuiObject") then
		self.titleLayer1 = titleFrame:FindFirstChild("Layer1")
		self.titleLayer2 = titleFrame:FindFirstChild("Layer2")
	end

	local contentFrame = mainFrameObject:FindFirstChild("Content")
	contentFrame = ensureGuiObject(contentFrame, "SurfaceGui.Main.Content")

	local itemsContainer = contentFrame:FindFirstChild("Content")
	assert(itemsContainer and itemsContainer:IsA("ScrollingFrame"), "RankingGui expected Main.Content.Content to be a ScrollingFrame")

	self.container = itemsContainer
	self.layout = itemsContainer:FindFirstChildOfClass("UIListLayout")

	self.templates = {}
	for _, templateName in ipairs({ "Rank1", "Rank2", "Rank3", "Rank" }) do
		local template = itemsContainer:FindFirstChild(templateName)
		if template and template:IsA("GuiObject") then
			template.Visible = false
			template.Parent = nil
			self.templates[templateName] = template
		end
	end

	assert(self.templates.Rank, "RankingGui requires a 'Rank' template to be present")
	self.defaultTemplate = self.templates.Rank

	if self.defaultTemplate:IsA("GuiObject") then
		self.defaultRowBackgroundColor = self.defaultTemplate.BackgroundColor3
		self.defaultRowBackgroundTransparency = self.defaultTemplate.BackgroundTransparency
	end
	self.highlightRowBackgroundColor = self.defaultTemplate:GetAttribute("HighlightBackgroundColor3")
	self.highlightRowBackgroundTransparency = self.defaultTemplate:GetAttribute("HighlightBackgroundTransparency")

	self.rankingType = options.rankingType or surfaceGui.Name
	self.maxEntries = math.clamp(options.maxEntries or DEFAULT_MAX_ENTRIES, 1, MAX_SUPPORTED_ENTRIES)
	self.nameResolver = options.nameResolver
	self.items = {}
	self.emptyLabel = nil
	self.thumbnailCache = {}

	self.baseRowLayoutOrder = self.defaultTemplate.LayoutOrder or 0

	surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	self:SetTitle(options.title or RankingType.GetTitle(self.rankingType))

	return self
end

function RankingGui:SetTitle(title: string?)
	local text = title or "LEADERBOARD"
	if typeof(text) == "string" then
		text = string.upper(text)
	else
		text = "LEADERBOARD"
	end

	setLabelText(self.titleLayer1, text, nil)
	setLabelText(self.titleLayer2, text, nil)
end

function RankingGui:GetTemplateForIndex(index: number): GuiObject
	if index == 1 and self.templates.Rank1 then
		return self.templates.Rank1
	elseif index == 2 and self.templates.Rank2 then
		return self.templates.Rank2
	elseif index == 3 and self.templates.Rank3 then
		return self.templates.Rank3
	end
	return self.defaultTemplate
end

function RankingGui:ApplyRowStyle(row: GuiObject, highlight: boolean): ()
	if not row:IsA("GuiObject") then
		return
	end

	if highlight then
		if typeof(self.highlightRowBackgroundColor) == "Color3" then
			row.BackgroundColor3 = self.highlightRowBackgroundColor
		end
		if typeof(self.highlightRowBackgroundTransparency) == "number" then
			row.BackgroundTransparency = self.highlightRowBackgroundTransparency
		end
		row:SetAttribute("IsHighlighted", true)
	else
		if self.defaultRowBackgroundColor then
			row.BackgroundColor3 = self.defaultRowBackgroundColor
		end
		if self.defaultRowBackgroundTransparency ~= nil then
			row.BackgroundTransparency = self.defaultRowBackgroundTransparency
		end
		row:SetAttribute("IsHighlighted", false)
	end
end

function RankingGui:GetPlayerThumbnail(userId: number?): string?
	if userId == nil or userId <= 0 then
		return nil
	end

	local cached = self.thumbnailCache[userId]
	if cached ~= nil then
		return cached ~= "" and cached or nil
	end

	local success, content = pcall(Players.GetUserThumbnailAsync, Players, userId, THUMBNAIL_TYPE, THUMBNAIL_SIZE)
	if success and typeof(content) == "string" and content ~= "" then
		self.thumbnailCache[userId] = content
		return content
	end

	self.thumbnailCache[userId] = ""
	return nil
end

function RankingGui:CreateEmptyState(): GuiObject
	local placeholder = cloneTemplate(self.defaultTemplate)
	placeholder.Name = "EmptyState"

	if placeholder:IsA("GuiBase2d") then
		placeholder.LayoutOrder = self.baseRowLayoutOrder
	end
	if placeholder:IsA("GuiObject") then
		self:ApplyRowStyle(placeholder, false)
	end

	setLabelText(findDescendant(placeholder, PLAYER_RANK_LABEL_PATH), "", nil)
	local nameLabel = findDescendant(placeholder, PLAYER_NAME_LABEL_PATH)
	setLabelText(nameLabel, "No data yet", nil)
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	end
	setLabelText(findDescendant(placeholder, PLAYER_VALUE_LABEL_PATH), "", nil)

	local imageLabel = findDescendant(placeholder, PLAYER_IMAGE_PATH)
	if imageLabel and imageLabel:IsA("ImageLabel") then
		imageLabel.Image = ""
	end

	placeholder.Parent = self.container
	return placeholder
end

function RankingGui:ResolveName(userId: number?): string
	if userId == nil then
		return "Unknown"
	end

	if self.nameResolver then
		local success, result = pcall(self.nameResolver, userId)
		if success and typeof(result) == "string" and result ~= "" then
			return result
		end
	end

	return tostring(userId)
end

function RankingGui:FormatValue(value: number): string
	return RankingType.FormatValue(self.rankingType, value)
end

function RankingGui:CreateRow(index: number, userId: number?, displayName: string, value: number, highlight: boolean): GuiObject
	local template = self:GetTemplateForIndex(index)
	local row = cloneTemplate(template)
	row.Name = `Rank_${index}`
	row:SetAttribute("UserId", userId)

	if row:IsA("GuiBase2d") then
		row.LayoutOrder = self.baseRowLayoutOrder + index - 1
	end

	if row:IsA("GuiObject") then
		self:ApplyRowStyle(row, highlight)
	end

	setLabelText(findDescendant(row, PLAYER_RANK_LABEL_PATH), string.format("#%d", index), nil)
	setLabelText(findDescendant(row, PLAYER_NAME_LABEL_PATH), displayName, nil)
	setLabelText(findDescendant(row, PLAYER_VALUE_LABEL_PATH), self:FormatValue(value), nil)

	local thumbnail = self:GetPlayerThumbnail(userId)
	local imageLabel = findDescendant(row, PLAYER_IMAGE_PATH)
	if imageLabel and imageLabel:IsA("ImageLabel") then
		imageLabel.Image = thumbnail or imageLabel.Image
	end

	return row
end

function RankingGui:SetEntries(entries: { RankingEntry }, highlightUserId: number?)
	entries = entries or {}

	for _, item in ipairs(self.items) do
		item:Destroy()
	end
	table.clear(self.items)

	if self.emptyLabel then
		self.emptyLabel:Destroy()
		self.emptyLabel = nil
	end

	if #entries == 0 then
		self.emptyLabel = self:CreateEmptyState()
		return
	end

	local limit = math.min(#entries, self.maxEntries)
	local highlightId = highlightUserId and tonumber(highlightUserId) or nil

	for index = 1, limit do
		local entry = entries[index]
		local userIdNumber = tonumber(entry.UserId)
		local displayName = self:ResolveName(userIdNumber)
		local row = self:CreateRow(index, userIdNumber, displayName, entry.Value, highlightId ~= nil and highlightId == userIdNumber)
		row.Parent = self.container
		table.insert(self.items, row)
	end
end

function RankingGui:Destroy(): ()
	for _, item in ipairs(self.items) do
		item:Destroy()
	end
	self.items = {}

	if self.emptyLabel then
		self.emptyLabel:Destroy()
		self.emptyLabel = nil
	end

	for _, template in pairs(self.templates) do
		template:Destroy()
	end
	self.templates = {}
end

return RankingGui
