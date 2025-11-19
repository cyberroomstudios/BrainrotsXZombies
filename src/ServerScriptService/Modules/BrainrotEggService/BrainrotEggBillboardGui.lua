local BrainrotEggBillboardGui = {}
BrainrotEggBillboardGui.__index = BrainrotEggBillboardGui

-- === CUSTOM TYPES
export type BrainrotEggBillboardGui = {
	new: (attachPart: BasePart, eggSize: Vector3, eggName: string) -> BrainrotEggBillboardGui,
	UpdateProgress: (self: BrainrotEggBillboardGui, progress: number, timeRemaining: number) -> (),
	SetHatched: (self: BrainrotEggBillboardGui) -> (),
	Destroy: (self: BrainrotEggBillboardGui) -> (),
	GetBillboardGui: (self: BrainrotEggBillboardGui) -> BillboardGui,
}

type Private = {
	BillboardGui: BillboardGui,
	TimeLabel: TextLabel,
	ProgressBar: Frame,
}

-- === PRIVATE VARIABLES
local __: { [BrainrotEggBillboardGui]: Private } = setmetatable({}, { __mode = "k" })

-- === CONSTANTS
local BILLBOARD_SIZE = UDim2.new(4, 0, 1.5, 0)
local BACKGROUND_COLOR = Color3.fromRGB(0, 0, 0)
local BACKGROUND_TRANSPARENCY = 0.5
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local TEXT_COLOR_HATCHED = Color3.fromRGB(0, 255, 0)
local PROGRESS_BAR_COLOR = Color3.fromRGB(0, 255, 0)
local PROGRESS_BG_COLOR = Color3.fromRGB(50, 50, 50)

-- === CONSTRUCTOR
function BrainrotEggBillboardGui.new(attachPart: BasePart, eggSize: Vector3, eggName: string): BrainrotEggBillboardGui
	assert(attachPart ~= nil, "BrainrotEggBillboardGui.new expects a BasePart")
	assert(attachPart:IsA("BasePart"), "BrainrotEggBillboardGui.new expects a BasePart instance")
	assert(eggSize ~= nil, "BrainrotEggBillboardGui.new expects eggSize Vector3")

	local self: BrainrotEggBillboardGui = setmetatable({}, BrainrotEggBillboardGui)

	-- Create BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HatchingProgress"
	billboardGui.Size = BILLBOARD_SIZE
	billboardGui.StudsOffset = Vector3.new(0, eggSize.Y + 1, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Adornee = attachPart
	billboardGui.Parent = attachPart

	-- Background frame
	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = BACKGROUND_COLOR
	frame.BackgroundTransparency = BACKGROUND_TRANSPARENCY
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.1, 0)
	uiCorner.Parent = frame

	-- TextLabel for time remaining
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TimeLabel"
	textLabel.Size = UDim2.new(1, 0, 0.5, 0)
	textLabel.Position = UDim2.new(0, 0, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = TEXT_COLOR
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = "Hatching..."
	textLabel.Parent = frame

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBackground"
	progressBg.Size = UDim2.new(0.9, 0, 0.2, 0)
	progressBg.Position = UDim2.new(0.05, 0, 0.65, 0)
	progressBg.BackgroundColor3 = PROGRESS_BG_COLOR
	progressBg.BorderSizePixel = 0
	progressBg.Parent = frame

	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0.5, 0)
	progressBgCorner.Parent = progressBg

	-- Progress bar fill
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = PROGRESS_BAR_COLOR
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBg

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0.5, 0)
	progressBarCorner.Parent = progressBar

	-- Store private data
	__[self] = {
		BillboardGui = billboardGui,
		TimeLabel = textLabel,
		ProgressBar = progressBar,
	}

	return self
end

-- === PUBLIC METHODS
function BrainrotEggBillboardGui:UpdateProgress(progress: number, timeRemaining: number): ()
	local private = __[self]
	if not private then
		return
	end

	-- Clamp progress between 0 and 1
	progress = math.clamp(progress, 0, 1)

	-- Update progress bar
	private.ProgressBar.Size = UDim2.new(progress, 0, 1, 0)

	-- Update time label
	local minutes = math.floor(timeRemaining / 60)
	local seconds = math.floor(timeRemaining % 60)
	private.TimeLabel.Text = string.format("Hatching: %02d:%02d", minutes, seconds)
end

function BrainrotEggBillboardGui:SetHatched(): ()
	local private = __[self]
	if not private then
		return
	end

	-- Update text and color
	private.TimeLabel.Text = "Ready to Collect!"
	private.TimeLabel.TextColor3 = TEXT_COLOR_HATCHED

	-- Set progress bar to full
	private.ProgressBar.Size = UDim2.new(1, 0, 1, 0)
end

function BrainrotEggBillboardGui:GetBillboardGui(): BillboardGui
	local private = __[self]
	return private and private.BillboardGui or nil
end

function BrainrotEggBillboardGui:Destroy(): ()
	local private = __[self]
	if not private then
		return
	end

	if private.BillboardGui then
		private.BillboardGui:Destroy()
	end

	__[self] = nil
end

return BrainrotEggBillboardGui
