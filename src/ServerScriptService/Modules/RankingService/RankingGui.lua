local RankingGui = {}
RankingGui.__index = RankingGui

-- === CUSTOM TYPES
export type RankingEntry = {
	UserId: number,
	Value: number,
}

export type Options = {
	rankingType: string?,
	title: string?,
	maxEntries: number?,
	nameResolver: ((number) -> string)?,
	headerBackgroundColor: Color3?,
	headerBackgroundTransparency: number?,
	columnBackgroundColor: Color3?,
	columnBackgroundTransparency: number?,
	rowBackgroundColor: Color3?,
	rowBackgroundTransparency: number?,
	rowHighlightBackgroundColor: Color3?,
	rowHighlightBackgroundTransparency: number?,
	titleTextColor: Color3?,
	columnHeaderTextColor: Color3?,
	rowTextColor: Color3?,
	emptyStateTextColor: Color3?,
}

-- === CONSTANTS
local DEFAULT_MAX_ENTRIES: number = 10
local HEADER_HEIGHT: number = 64
local COLUMN_HEADER_HEIGHT: number = 40
local ROW_HEIGHT: number = 48
local TITLE_TEXT_SIZE: number = 36
local COLUMN_TEXT_SIZE: number = 22
local ROW_TEXT_SIZE: number = 24
local EMPTY_TEXT_SIZE: number = 22
local DEFAULT_HEADER_BACKGROUND_COLOR = Color3.fromRGB(20, 20, 20)
local DEFAULT_HEADER_BACKGROUND_TRANSPARENCY = 0.2
local DEFAULT_COLUMN_BACKGROUND_COLOR = DEFAULT_HEADER_BACKGROUND_COLOR
local DEFAULT_COLUMN_BACKGROUND_TRANSPARENCY = 0.3
local DEFAULT_ROW_BACKGROUND_COLOR = Color3.fromRGB(25, 25, 25)
local DEFAULT_ROW_BACKGROUND_TRANSPARENCY = 0.4
local DEFAULT_ROW_HIGHLIGHT_BACKGROUND_COLOR = Color3.fromRGB(64, 128, 255)
local DEFAULT_ROW_HIGHLIGHT_BACKGROUND_TRANSPARENCY = 0.2
local DEFAULT_TITLE_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local DEFAULT_COLUMN_HEADER_TEXT_COLOR = Color3.fromRGB(200, 200, 200)
local DEFAULT_ROW_TEXT_COLOR = DEFAULT_TITLE_TEXT_COLOR
local DEFAULT_EMPTY_STATE_TEXT_COLOR = Color3.fromRGB(180, 180, 180)

-- === CONSTRUCTOR
function RankingGui.new(surfaceGui: SurfaceGui, options: Options?)
	assert(surfaceGui and surfaceGui:IsA("SurfaceGui"), "RankingGui.new expects a SurfaceGui instance")
	options = options or {}

	local self = setmetatable({}, RankingGui)
	self.surfaceGui = surfaceGui
	self.rankingType = options.rankingType or surfaceGui.Name
	self.maxEntries = options.maxEntries or DEFAULT_MAX_ENTRIES
	self.nameResolver = options.nameResolver
	self.title = options.title or self.rankingType
	self.items = {}
	self.emptyLabel = nil
	self.headerBackgroundColor = options.headerBackgroundColor or DEFAULT_HEADER_BACKGROUND_COLOR
	self.headerBackgroundTransparency = options.headerBackgroundTransparency or DEFAULT_HEADER_BACKGROUND_TRANSPARENCY
	self.columnBackgroundColor = options.columnBackgroundColor or self.headerBackgroundColor or DEFAULT_COLUMN_BACKGROUND_COLOR
	self.columnBackgroundTransparency = options.columnBackgroundTransparency or DEFAULT_COLUMN_BACKGROUND_TRANSPARENCY
	self.rowBackgroundColor = options.rowBackgroundColor or DEFAULT_ROW_BACKGROUND_COLOR
	self.rowBackgroundTransparency = options.rowBackgroundTransparency or DEFAULT_ROW_BACKGROUND_TRANSPARENCY
	self.rowHighlightBackgroundColor = options.rowHighlightBackgroundColor or DEFAULT_ROW_HIGHLIGHT_BACKGROUND_COLOR
	self.rowHighlightBackgroundTransparency = options.rowHighlightBackgroundTransparency
		or DEFAULT_ROW_HIGHLIGHT_BACKGROUND_TRANSPARENCY
	self.titleTextColor = options.titleTextColor or DEFAULT_TITLE_TEXT_COLOR
	self.columnHeaderTextColor = options.columnHeaderTextColor or DEFAULT_COLUMN_HEADER_TEXT_COLOR
	self.rowTextColor = options.rowTextColor or DEFAULT_ROW_TEXT_COLOR
	self.emptyStateTextColor = options.emptyStateTextColor or DEFAULT_EMPTY_STATE_TEXT_COLOR

	surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	self.container = surfaceGui:FindFirstChild("RankingContainer")
	if not self.container then
		self.container = Instance.new("Frame")
		self.container.Name = "RankingContainer"
		self.container.BackgroundTransparency = 1
		self.container.BorderSizePixel = 0
		self.container.Size = UDim2.fromScale(1, 1)
		self.container.Parent = surfaceGui
	end
	self.container.ClipsDescendants = false

	local padding = self.container:FindFirstChildOfClass("UIPadding")
	if not padding then
		padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 20)
		padding.PaddingBottom = UDim.new(0, 20)
		padding.PaddingLeft = UDim.new(0, 20)
		padding.PaddingRight = UDim.new(0, 20)
		padding.Parent = self.container
	end

	self.layout = self.container:FindFirstChildOfClass("UIListLayout")
	if not self.layout then
		self.layout = Instance.new("UIListLayout")
		self.layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		self.layout.VerticalAlignment = Enum.VerticalAlignment.Top
		self.layout.SortOrder = Enum.SortOrder.LayoutOrder
		self.layout.Padding = UDim.new(0, 8)
		self.layout.Parent = self.container
	end

	self:CreateHeader()

	return self
end

-- === GLOBAL FUNCTIONS
function RankingGui:CreateHeader(): ()
	local header = self.container:FindFirstChild("Header")
	if not header then
		header = Instance.new("Frame")
		header.Name = "Header"
		header.Parent = self.container
	end
	header.BackgroundColor3 = self.headerBackgroundColor
	header.BackgroundTransparency = self.headerBackgroundTransparency
	header.BorderSizePixel = 0
	header.LayoutOrder = 0
	header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)

	local headerCorner = header:FindFirstChildOfClass("UICorner")
	if not headerCorner then
		headerCorner = Instance.new("UICorner")
		headerCorner.Parent = header
	end
	headerCorner.CornerRadius = UDim.new(0, 8)

	local headerPadding = header:FindFirstChildOfClass("UIPadding")
	if not headerPadding then
		headerPadding = Instance.new("UIPadding")
		headerPadding.Parent = header
	end
	headerPadding.PaddingLeft = UDim.new(0, 16)
	headerPadding.PaddingRight = UDim.new(0, 16)

	local titleLabel = header:FindFirstChild("Title")
	if not titleLabel then
		titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Parent = header
	end
	titleLabel.AnchorPoint = Vector2.new(0, 0.5)
	titleLabel.Position = UDim2.fromScale(0, 0.5)
	titleLabel.Size = UDim2.new(1, -32, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = string.format("%s Leaderboard", self.title)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextScaled = false
	titleLabel.TextSize = TITLE_TEXT_SIZE
	titleLabel.TextColor3 = self.titleTextColor
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center

	local columnHeader = self.container:FindFirstChild("ColumnLabels")
	if not columnHeader then
		columnHeader = Instance.new("Frame")
		columnHeader.Name = "ColumnLabels"
		columnHeader.Parent = self.container
	end
	columnHeader.BackgroundTransparency = self.columnBackgroundTransparency
	columnHeader.BackgroundColor3 = self.columnBackgroundColor
	columnHeader.BorderSizePixel = 0
	columnHeader.LayoutOrder = 1
	columnHeader.Size = UDim2.new(1, 0, 0, COLUMN_HEADER_HEIGHT)

	local columnCorner = columnHeader:FindFirstChildOfClass("UICorner")
	if not columnCorner then
		columnCorner = Instance.new("UICorner")
		columnCorner.Parent = columnHeader
	end
	columnCorner.CornerRadius = UDim.new(0, 8)

	local columnPadding = columnHeader:FindFirstChildOfClass("UIPadding")
	if not columnPadding then
		columnPadding = Instance.new("UIPadding")
		columnPadding.Parent = columnHeader
	end
	columnPadding.PaddingLeft = UDim.new(0, 16)
	columnPadding.PaddingRight = UDim.new(0, 24)

	local rowLayout = columnHeader:FindFirstChildOfClass("UIListLayout")
	if not rowLayout then
		rowLayout = Instance.new("UIListLayout")
		rowLayout.Parent = columnHeader
	end
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 8)

	local function ensureColumn(
		name: string,
		text: string,
		size: UDim2,
		alignment: Enum.TextXAlignment,
		layoutOrder: number
	): TextLabel
		local label = columnHeader:FindFirstChild(name)
		if not label then
			label = Instance.new("TextLabel")
			label.Name = name
			label.Parent = columnHeader
		end
		label.LayoutOrder = layoutOrder
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Size = size
		label.Font = Enum.Font.GothamBold
		label.Text = text
		label.TextColor3 = self.columnHeaderTextColor
		label.TextScaled = false
		label.TextSize = COLUMN_TEXT_SIZE
		label.TextXAlignment = alignment
		label.TextYAlignment = Enum.TextYAlignment.Center
		return label
	end

	ensureColumn("Rank", "RANK", UDim2.new(0.2, 0, 1, 0), Enum.TextXAlignment.Left, 1)
	ensureColumn("Player", "PLAYER", UDim2.new(0.5, 0, 1, 0), Enum.TextXAlignment.Left, 2)
	ensureColumn("Value", "VALUE", UDim2.new(0.3, 0, 1, 0), Enum.TextXAlignment.Right, 3)
end

function RankingGui:CreateEmptyState(): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "EmptyState"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.LayoutOrder = 2
	label.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	label.Font = Enum.Font.Gotham
	label.Text = "No data yet"
	label.TextColor3 = self.emptyStateTextColor
	label.TextScaled = false
	label.TextSize = EMPTY_TEXT_SIZE
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = self.container
	return label
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
	if typeof(value) ~= "number" then
		return tostring(value)
	end

	return tostring(value)
end

function RankingGui:CreateRow(index: number, displayName: string, value: number, highlight: boolean): Frame
	local row = Instance.new("Frame")
	row.Name = `Row_{index}`
	row.BackgroundTransparency = highlight and self.rowHighlightBackgroundTransparency or self.rowBackgroundTransparency
	row.BackgroundColor3 = highlight and self.rowHighlightBackgroundColor or self.rowBackgroundColor
	row.BorderSizePixel = 0
	row.LayoutOrder = index + 1
	row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 24)
	padding.Parent = row

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = row

	local function createLabel(
		name: string,
		text: string,
		size: UDim2,
		alignment: Enum.TextXAlignment,
		font: Enum.Font,
		isBold: boolean
	)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Size = size
		label.Font = isBold and Enum.Font.GothamBold or font
		label.Text = text
		label.TextColor3 = self.rowTextColor
		label.TextScaled = false
		label.TextSize = ROW_TEXT_SIZE
		label.TextXAlignment = alignment
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Parent = row
		return label
	end

	createLabel("Rank", tostring(index), UDim2.new(0.2, 0, 1, 0), Enum.TextXAlignment.Left, Enum.Font.Gotham, true)
	createLabel("Player", displayName, UDim2.new(0.5, 0, 1, 0), Enum.TextXAlignment.Left, Enum.Font.Gotham, false)
	createLabel(
		"Value",
		self:FormatValue(value),
		UDim2.new(0.3, 0, 1, 0),
		Enum.TextXAlignment.Right,
		Enum.Font.Gotham,
		false
	)

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
		local row = self:CreateRow(index, displayName, entry.Value, highlightId ~= nil and highlightId == userIdNumber)
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
end

return RankingGui
