--// YUKO HUB PHOTO-STYLE UI TEMPLATE (UPDATED)
--// LocalScript in StarterGui

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer

local BACKGROUND_IMAGE = "rbxassetid://99181989793980"
local ICON_IMAGE = "rbxassetid://99181989793980"

local MENU_W, MENU_H = 280, 380
local TOP_H = 38
local TAB_H = 26

local WHITE = Color3.fromRGB(245, 245, 245)
local MUTED = Color3.fromRGB(135, 135, 135)
local BLACK = Color3.fromRGB(8, 8, 8)
local PANEL = Color3.fromRGB(8, 25, 8)
local CONTROL = Color3.fromRGB(15, 45, 15)
local CONTROL_2 = Color3.fromRGB(30, 80, 30)
local GREEN = Color3.fromRGB(70, 255, 105)

-- =================== STATE ===================
local State = {
	dropActive = false,
	infJumpEnabled = false,
	infJumpMode = "hold",
	holdInfJumpConn = nil,
	dropMethod = "Stand",
	antiBatBypass = false,
	antiBatCooldown = false,
	antiRagdoll = false,
	antiRagdollEnabled = false,
	AutoBat = false,
	BatAimbot = false,
	autoBatToggled = false,
	autoLeftEnabled = false,
	autoRightEnabled = false,
	guiVisible = true,
	-- Lagger and Carry toggles
	laggerToggled = false,
	carryToggled = false,
	lastMoveDir = Vector3.zero,
	fpsBoostEnabled = false,
	unwalkEnabled = false,
	autoStealEnabled = false,
	autoStealMode = "Normal",
	instaResetOnMedusa = false,
	guiLocked = false,
	mobileBtnSize = 50,
	showPlayerSpeed = false,
	hittingCooldown = false,
}

local MOVE_KEYS = {
	[Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true,
	[Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
}

local autoTPHeight = 20
local _lastTPTime = 0

-- Speed settings: Normal, Carry, Lagger Normal, Lagger Carry
local NS, CS = 60, 30       -- Normal Speed, Carry Speed
local LS, LS2 = 15, 24.5    -- Lagger Normal, Lagger Carry
local autoSwitchSpeed = false   -- auto-switch to carry when walking slow

local autoBatEnabled = false
local autoSwingEnabled = false
local aimbotSpeed = 56
local _aimbotTarget = nil

local AP = {
	L1 = Vector3.new(-476.48, -6.28, 92.73),
	L2 = Vector3.new(-483.12, -4.95, 94.80),
	L_FACE = Vector3.new(-482.25, -4.96, 92.09),
	R1 = Vector3.new(-476.16, -6.52, 25.62),
	R2 = Vector3.new(-483.06, -5.03, 25.48),
	R_FACE = Vector3.new(-482.06, -6.93, 35.47),
}

local desiredFOV = 70
local removeAccsEnabled = false

local medusaCounterEnabled = false
local medusaDebounce = false
local medusaLastUsed = 0
local MEDUSA_COOLDOWN = 25

local batCounterEnabled = false
local batCounterDebounce = false
local autoTPDownEnabled = false

local Connections = {}
local Conns = {anchor = {}, batCounter = nil, aimbot = nil}

local Keybinds = {
	tpDown = Enum.KeyCode.F,
	drop = Enum.KeyCode.X,
	aimbot = Enum.KeyCode.E,
	laggerToggle = Enum.KeyCode.G,    -- Lagger mode toggle
	carryToggle = Enum.KeyCode.C,     -- Carry mode toggle
	manualJump = Enum.KeyCode.Space,
}

local STEAL_RADIUS = 9
local STEAL_DURATION = 0.2
local STEAL_HOLD_MIN = 1.3
local STEAL_HOLD_MAX = 2.6
local STEAL_ENTRY_DELAY = 0.3
local STEAL_COOLDOWN = 0.05
local STEAL_PRIME_RANGE = 80

local stealProgress = 0
local stealLabel = "IDLE"
local stealIsActive = false
local stealStartTime = 0
local stealPhase = "idle"

-- ============== CONFIG SAVE/LOAD ==============
local CONFIG_FILE = "YukoHubConfig.json"

local uiScaleObj
local positions = {}

local function gatherConfig(YukoHub)
	local function ks(name YukoHub) return Keybinds[name]and Keybinds[name].Name or nil end
	return {
		NS = NS, CS = CS, LS = LS, LS2 = LS2,
		autoSwitchSpeed = autoSwitchSpeed,
		aimbotSpeed = aimbotSpeed,
		autoTPHeight = autoTPHeight,
		desiredFOV = desiredFOV,
		STEAL_RADIUS = STEAL_RADIUS,
		STEAL_DURATION = STEAL_DURATION,
		STEAL_PRIME_RANGE = STEAL_PRIME_RANGE,
		STEAL_HOLD_MIN = STEAL_HOLD_MIN,
		STEAL_HOLD_MAX = STEAL_HOLD_MAX,
		STEAL_ENTRY_DELAY = STEAL_ENTRY_DELAY,
		STEAL_COOLDOWN = STEAL_COOLDOWN,
		autoStealMode = State.autoStealMode,
		autoStealEnabled = State.autoStealEnabled,
		dropMethod = State.dropMethod,
		infJumpEnabled = State.infJumpEnabled,
		infJumpMode = State.infJumpMode,
		instaResetOnMedusa = State.instaResetOnMedusa,
		antiRagdoll = State.antiRagdoll,
		antiBatBypass = State.antiBatBypass,
		unwalkEnabled = State.unwalkEnabled,
		fpsBoostEnabled = State.fpsBoostEnabled,
		removeAccessories = removeAccsEnabled,
		medusaCounter = medusaCounterEnabled,
		batCounter = batCounterEnabled,
		autoSwing = autoSwingEnabled,
		autoTPDown = autoTPDownEnabled,
		guiLocked = State.guiLocked,
		mobileBtnSize = State.mobileBtnSize,
		showPlayerSpeed = State.showPlayerSpeed,
		laggerToggled = State.laggerToggled,
		carryToggled = State.carryToggled,
		keys = {
			tpDown = ks("tpDown"),
			drop = ks("drop"),
			aimbot = ks("aimbot"),
			laggerToggle = ks("laggerToggle"),
			carryToggle = ks("carryToggle"),
			manualJump = ks("manualJump"),
		},
	}
end

local function _writeConfig(tbl)
	if writefile then
		pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(tbl)) end)
	end
end

local function saveConfig()
	local c = gatherConfig()
	c.positions = {}
	for name, frame in pairs(positions) do
		if frame and frame.Parent then
			local p = frame.Position
			c.positions[name] = {xs = p.X.Scale, xo = p.X.Offset, ys = p.Y.Scale, yo = p.Y.Offset}
		end
	end
	if uiScaleObj then c.uiScale = uiScaleObj.Scale end
	_writeConfig(c)
end

local function readConfig()
	if not isfile or not isfile(CONFIG_FILE) then return nil end
	local ok, raw = pcall(readfile, CONFIG_FILE)
	if not ok or not raw then return nil end
	local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 then return nil end
	return d
end

local function applyEarlyConfig()
	local d = readConfig()
	if not d then return end
	if d.NS then NS = d.NS end
	if d.CS then CS = d.CS end
	if d.LS then LS = d.LS end
	if d.LS2 then LS2 = d.LS2 end
	if d.autoSwitchSpeed ~= nil then autoSwitchSpeed = d.autoSwitchSpeed end
	if d.aimbotSpeed then aimbotSpeed = d.aimbotSpeed end
	if d.autoTPHeight then autoTPHeight = d.autoTPHeight end
	if d.desiredFOV then desiredFOV = d.desiredFOV end
	if d.STEAL_RADIUS then STEAL_RADIUS = d.STEAL_RADIUS end
	if d.STEAL_DURATION then STEAL_DURATION = d.STEAL_DURATION end
	if d.STEAL_PRIME_RANGE then STEAL_PRIME_RANGE = d.STEAL_PRIME_RANGE end
	if d.STEAL_HOLD_MIN then STEAL_HOLD_MIN = d.STEAL_HOLD_MIN end
	if d.STEAL_HOLD_MAX then STEAL_HOLD_MAX = d.STEAL_HOLD_MAX end
	if d.STEAL_ENTRY_DELAY then STEAL_ENTRY_DELAY = d.STEAL_ENTRY_DELAY end
	if d.STEAL_COOLDOWN then STEAL_COOLDOWN = d.STEAL_COOLDOWN end
	if d.autoStealMode then State.autoStealMode = d.autoStealMode end
	if d.dropMethod then State.dropMethod = d.dropMethod end
	if d.infJumpEnabled ~= nil then State.infJumpEnabled = d.infJumpEnabled end
	if d.infJumpMode then State.infJumpMode = d.infJumpMode end
	if d.instaResetOnMedusa ~= nil then State.instaResetOnMedusa = d.instaResetOnMedusa end
	if d.guiLocked ~= nil then State.guiLocked = d.guiLocked end
	if d.mobileBtnSize then State.mobileBtnSize = d.mobileBtnSize end
	if d.showPlayerSpeed ~= nil then State.showPlayerSpeed = d.showPlayerSpeed end
	if d.laggerToggled ~= nil then State.laggerToggled = d.laggerToggled end
	if d.carryToggled ~= nil then State.carryToggled = d.carryToggled end
	if d.antiRagdoll ~= nil then State.antiRagdoll = d.antiRagdoll; State.antiRagdollEnabled = d.antiRagdoll end
	if d.antiBatBypass ~= nil then State.antiBatBypass = d.antiBatBypass end
	if d.unwalkEnabled ~= nil then State.unwalkEnabled = d.unwalkEnabled end
	if d.fpsBoostEnabled ~= nil then State.fpsBoostEnabled = d.fpsBoostEnabled end
	if d.removeAccessories ~= nil then removeAccsEnabled = d.removeAccessories end
	if d.medusaCounter ~= nil then medusaCounterEnabled = d.medusaCounter end
	if d.batCounter ~= nil then batCounterEnabled = d.batCounter end
	if d.autoSwing ~= nil then autoSwingEnabled = d.autoSwing end
	if d.autoTPDown ~= nil then autoTPDownEnabled = d.autoTPDown end
	if d.autoStealEnabled ~= nil then State.autoStealEnabled = d.autoStealEnabled end
	if d.keys then
		for k, v in pairs(d.keys) do
			if v and Enum.KeyCode[v] then Keybinds[k] = Enum.KeyCode[v] end
		end
	end
end

applyEarlyConfig()

-- =================== UPDATED INSTA RESET (from provided code) ===================
local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"

-- Hook to capture the remote event (runs once)
pcall(function()
	if hookfunction and newcclosure then
		local oldFire
		oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
			if not cursedResetRemote and typeof(self) == "Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3) == "RE/" then
				cursedResetRemote = self
			end
			return oldFire(self, ...)
		end))
	end
end)

-- Fallback search if hook didn't capture
task.spawn(function()
	task.wait(2)
	if cursedResetRemote then return end
	for _, desc in ipairs(game:GetDescendants()) do
		if desc:IsA("RemoteEvent") and desc.Name:sub(1,3) == "RE/" then
			cursedResetRemote = desc
			break
		end
	end
end)

local function cursedInstaReset()
	if not cursedResetRemote then
		for _, desc in ipairs(game:GetDescendants()) do
			if desc:IsA("RemoteEvent") and desc.Name:sub(1,3) == "RE/" then
				cursedResetRemote = desc
				break
			end
		end
	end
	if not cursedResetRemote then return end

	local character = LP.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LP, "balloon") end)
		return
	end

	local resetDetected = false
	local conns = {}
	if humanoid then
		table.insert(conns, humanoid.Died:Connect(function() resetDetected = true end))
	end
	if character then
		table.insert(conns, character.AncestryChanged:Connect(function(_, parent)
			if not parent then resetDetected = true end
		end))
	end

	task.spawn(function()
		for _ = 1, 50 do
			if resetDetected then break end
			pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LP, "balloon") end)
			task.wait()
		end
		for _, conn in ipairs(conns) do
			pcall(function() conn:Disconnect() end)
		end
	end)
end

-- =================== UTIL ===================
local function new(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function corner(obj, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = obj; return c
end

local function stroke(obj, col, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = col or Color3.fromRGB(0, 0, 0); s.Thickness = thick or 1; s.Transparency = trans or 0
	s.Parent = obj; return s
end

local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function makeDraggable(frame, handle, posName)
	handle = handle or frame
	local dragging, dragInput, dragStart, startPos = false
	handle.InputBegan:Connect(function(input)
		if State.guiLocked then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if posName then saveConfig(YukoHub) end
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if State.guiLocked then return end
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	if posName then positions[posName] = frame end
end

-- cleanup
for _, name in ipairs({"YukoHubhotoUI", "YukoHubMobileButtons", "BalenciStealBar", "BalenciHeadDisplay"}) do
	local g = LP.PlayerGui:FindFirstChild(YukoHub)
	if g then g:Destroy() end
end

local gui = new("ScreenGui", {
	Name = "YukoHubPhotoUI", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50,
}, LP:WaitForChild("PlayerGui"))

local main = new("Frame", {
	Name = "Main", Size = UDim2.fromOffset(MENU_W, MENU_H),
	Position = UDim2.new(0, 36, 0.5, -(MENU_H / 2)),
	BackgroundColor3 = PANEL, BorderSizePixel = 0, ClipsDescendants = true, Active = true,
}, gui)
corner(main, 8); stroke(main, Color3.fromRGB(0, 0, 0), 2)

uiScaleObj = new("UIScale", {Scale = 1}, main)

local topbar = new("Frame", {
	Size = UDim2.new(1, 0, 0, TOP_H), BackgroundColor3 = Color3.fromRGB(6, 20, 6),
	BorderSizePixel = 0, ZIndex = 20,
}, main)

local icon = new("ImageLabel", {
	Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(8, 9),
	BackgroundColor3 = Color3.fromRGB(20, 60, 20), Image = ICON_IMAGE,
	ScaleType = Enum.ScaleType.Crop, ZIndex = 22,
}, topbar)
corner(icon, 5); stroke(icon, Color3.fromRGB(40, 120, 40), 1)

new("TextLabel", {
	Size = UDim2.fromOffset(110, 14), Position = UDim2.fromOffset(34, 6),
	BackgroundTransparency = 1, Text = "Yuko Hub", TextColor3 = WHITE,
	Font = Enum.Font.GothamBlack, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22,
}, topbar)

new("TextLabel", {
	Size = UDim2.fromOffset(110, 10), Position = UDim2.fromOffset(34, 20),
	BackgroundTransparency = 1, Text = "Yuko HUB BUYER",
	TextColor3 = Color3.fromRGB(80, 180, 80), Font = Enum.Font.GothamBold,
	TextSize = 7, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22,
}, topbar)

local statsBox = new("Frame", {
	Size = UDim2.fromOffset(60, 26), Position = UDim2.new(1, -94, 0, 6),
	BackgroundColor3 = Color3.fromRGB(10, 30, 10), BorderSizePixel = 0, ZIndex = 22,
}, topbar)
corner(statsBox, 5)

local pingLabel = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 11), Position = UDim2.fromOffset(0, 2),
	BackgroundTransparency = 1, Text = "32ms", TextColor3 = GREEN,
	Font = Enum.Font.GothamBlack, TextSize = 7, ZIndex = 23,
}, statsBox)

local fpsLabel = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 11), Position = UDim2.fromOffset(0, 13),
	BackgroundTransparency = 1, Text = "401 fps",
	TextColor3 = Color3.fromRGB(145, 145, 145), Font = Enum.Font.GothamBold, TextSize = 7, ZIndex = 23,
}, statsBox)

local minBtn = new("TextButton", {
	Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -26, 0, 10),
	BackgroundColor3 = Color3.fromRGB(12, 40, 12), BorderSizePixel = 0, Text = "-",
	TextColor3 = Color3.fromRGB(185, 185, 185), Font = Enum.Font.GothamBlack, TextSize = 10, ZIndex = 23,
}, topbar)
corner(minBtn, 4)

makeDraggable(main, topbar, "main")

local mini = new("TextButton", {
	Name = "Mini", Size = UDim2.fromOffset(110, 26),
	Position = UDim2.new(0, 36, 0.85, 0),
	BackgroundColor3 = Color3.fromRGB(6, 20, 6), BorderSizePixel = 0, Text = "Yuko Hub",
	TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextSize = 10, Visible = false, Active = true,
}, gui)
corner(mini, 5); stroke(mini, Color3.fromRGB(0, 0, 0), 2)
makeDraggable(mini, nil, "mini")

minBtn.MouseButton1Click:Connect(function() main.Visible = false; mini.Visible = true end)
mini.MouseButton1Click:Connect(function() main.Visible = true; mini.Visible = false end)

local body = new("Frame", {
	Size = UDim2.new(1, 0, 1, -(TOP_H + TAB_H)), Position = UDim2.fromOffset(0, TOP_H),
	BackgroundColor3 = Color3.fromRGB(2, 10, 2), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 1,
}, main)

new("ImageLabel", {
	Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = BACKGROUND_IMAGE,
	ScaleType = Enum.ScaleType.Crop, ZIndex = 1,
}, body)

local darkOverlay = new("Frame", {
	Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 20, 0),
	BackgroundTransparency = 0.28, BorderSizePixel = 0, ZIndex = 2,
}, body)

new("Frame", {
	Size = UDim2.new(0, 85, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 15, 0),
	BackgroundTransparency = 0.34, BorderSizePixel = 0, ZIndex = 3,
}, body)

new("Frame", {
	Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromOffset(85, 0),
	BackgroundColor3 = Color3.fromRGB(45, 45, 45), BackgroundTransparency = 0.55,
	BorderSizePixel = 0, ZIndex = 4,
}, body)

local pageHost = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 5}, body)

local tabbar = new("Frame", {
	Size = UDim2.new(1, 0, 0, TAB_H), Position = UDim2.new(0, 0, 1, -TAB_H),
	BackgroundColor3 = Color3.fromRGB(5, 18, 5), BorderSizePixel = 0, ZIndex = 30,
}, main)

local pages, tabButtons = {}, {}
local activeTab

-- Tab names: Combat, Steal, Motions, Lagger/Bat, Graphics, Config
local tabNames = {"Combat","Steal","Motions","Lagger/Bat","Graphics","Config"}

local function createPage(name)
	local page = new("ScrollingFrame", {
		Name = name .. "Page", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
		Visible = false, ZIndex = 6,
	}, pageHost)
	new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, page)
	new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10)}, page)
	pages[name] = page
	return page
end

local function switchTab(name)
	activeTab = name
	for tabName, data in pairs(tabButtons) do
		local on = tabName == name
		tween(data.button, {BackgroundColor3 = on and Color3.fromRGB(64, 64, 64) or Color3.fromRGB(10, 10, 10)}, 0.12)
		data.label.TextColor3 = on and WHITE or Color3.fromRGB(105, 105, 105)
		data.underline.Visible = on
		pages[tabName].Visible = on
	end
end

for i, name in ipairs(tabNames) do
	createPage(name)
	local tabW = MENU_W / #tabNames
	local btn = new("TextButton", {
		Size = UDim2.fromOffset(tabW, TAB_H), Position = UDim2.fromOffset((i - 1) * tabW, 0),
		BackgroundColor3 = Color3.fromRGB(5, 18, 5), BorderSizePixel = 0, Text = "", ZIndex = 31,
	}, tabbar)
	local label = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = name,
		TextColor3 = Color3.fromRGB(70, 150, 70), Font = Enum.Font.GothamBlack,
		TextSize = (name == "Lagger/Bat" or name == "Graphics") and 6.5 or 7.5, ZIndex = 33,
	}, btn)
	local underline = new("Frame", {
		Size = UDim2.fromOffset(14, 2), Position = UDim2.new(0.5, -7, 1, -3),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false, ZIndex = 34,
	}, btn)
	corner(underline, 1)
	tabButtons[name] = {button = btn, label = label, underline = underline}
	btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

local order = 0
local function nextOrder() order += 1; return order end

local function section(page, text)
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = nextOrder(), ZIndex = 8}, page)
	new("TextLabel", {
		Size = UDim2.new(1, -22, 1, 0), Position = UDim2.fromOffset(14, 2),
		BackgroundTransparency = 1, Text = string.upper(text),
		TextColor3 = Color3.fromRGB(60, 160, 60), Font = Enum.Font.GothamBlack, TextSize = 7,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9,
	}, f)
end

local function rowBase(page, labelText, h)
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, h or 34), BackgroundTransparency = 1, LayoutOrder = nextOrder(), ZIndex = 8}, page)
	new("TextLabel", {
		Size = UDim2.new(1, -145, 1, 0), Position = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1, Text = labelText, TextColor3 = WHITE,
		Font = Enum.Font.GothamBlack, TextSize =
