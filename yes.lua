--[[
	StardustUI — Standalone GUI Framework
	Aesthetic: black background, white text, thin white strokes, Gotham fonts
	API: Win = StardustUI.new({Title = "...", Subtitle = "..."})
	     Tab = Win:Tab("Main")
	     Sec = Tab:Section("Combat")
	     Sec:Button("Click me", function() end)
	     Sec:Toggle("Enabled", false, function(state) end)
	     Sec:Slider("Speed", 1, 100, 50, function(v) end)
	     Sec:Textbox("Name", "default", function(txt) end)
	     Sec:Dropdown("Mode", {"A","B","C"}, "A", function(v) end)
	     Sec:Keybind("Menu key", Enum.KeyCode.RightShift, function() end)
	     Sec:Label("Some text")
	     Win:Destroy()
]]

local StardustUI = {}

-- services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- THEME
---------------------------------------------------------------------
local THEME = {
	Bg = Color3.fromRGB(10, 10, 12),
	Panel = Color3.fromRGB(16, 16, 20),
	Section = Color3.fromRGB(20, 20, 26),
	Element = Color3.fromRGB(28, 28, 36),
	Stroke = Color3.fromRGB(255, 255, 255),
	Accent = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(150, 150, 160),
	TextMute = Color3.fromRGB(90, 90, 100),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	Corner = UDim.new(0, 8),
	Pad = 8,
	WinW = 560,
	WinH = 420,
	TabW = 130,
	Anim = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------
local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function corner(parent, r)
	return make("UICorner", { CornerRadius = r or THEME.Corner }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return make("UIStroke", {
		Color = color or THEME.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	}, parent)
end

local function label(props, parent)
	local base = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = THEME.Font,
		TextColor3 = THEME.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in pairs(props) do base[k] = v end
	return make("TextLabel", base, parent)
end

local function tween(inst, props)
	TweenService:Create(inst, THEME.Anim, props):Play()
end

local function ripple(parent, x, y)
	local r = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = parent.ZIndex + 1,
	}, parent)
	corner(r, UDim.new(1, 0))
	TweenService:Create(r, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(200, 200),
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.45, function() r:Destroy() end)
end

---------------------------------------------------------------------
-- ROOT SCREEN GUI
---------------------------------------------------------------------
local function getGui()
	local existing = playerGui:FindFirstChild("StardustUI")
	if existing then existing:Destroy() end
	local sg = make("ScreenGui", {
		Name = "StardustUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 2000,
	}, playerGui)
	return sg
end

---------------------------------------------------------------------
-- WINDOW CLASS
---------------------------------------------------------------------
local Window = {}
Window.__index = Window

function StardustUI.new(opts)
	opts = opts or {}
	local self = setmetatable({}, Window)
	self.Title = opts.Title or "StardustUI"
	self.Subtitle = opts.Subtitle or ""
	self.Tabs = {}
	self.CurrentTab = nil
	self.Keybind = opts.Keybind or Enum.KeyCode.RightShift
	self.Visible = true
	self.Connections = {}
	self.Destroyed = false

	self:_build()
	return self
end

function Window:_build()
	local sg = getGui()
	self.Gui = sg

	-- main window
	local win = make("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(THEME.WinW, THEME.WinH),
		BackgroundColor3 = THEME.Bg,
		BorderSizePixel = 0,
		Active = true,
	}, sg)
	corner(win)
	stroke(win, WHITE, 1.5, 0.4)
	self.Frame = win

	-- top bar (draggable)
	local top = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
		Active = true,
	}, win)
	corner(top)
	-- clip the bottom corners of the top bar (cover with square)
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
	}, top)
	self.Top = top

	-- title
	label({
		Size = UDim2.new(1, -100, 0, 22),
		Position = UDim2.fromOffset(16, 6),
		Text = self.Title,
		Font = THEME.FontBold,
		TextSize = 15,
	}, top)
	label({
		Size = UDim2.new(1, -100, 0, 14),
		Position = UDim2.fromOffset(16, 24),
		Text = self.Subtitle,
		TextSize = 11,
		TextColor3 = THEME.TextDim,
	}, top)

	-- close button
	local closeBtn = make("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -36, 0, 8),
		BackgroundColor3 = THEME.Element,
		Text = "×",
		TextColor3 = WHITE,
		Font = THEME.FontBold,
		TextSize = 18,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, top)
	corner(closeBtn, UDim.new(0, 6))
	stroke(closeBtn, WHITE, 1, 0.7)
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, { BackgroundColor3 = WHITE, TextColor3 = BLACK }) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, { BackgroundColor3 = THEME.Element, TextColor3 = WHITE }) end)
	closeBtn.MouseButton1Click:Connect(function() self:Toggle(false) end)

	-- minimize button
	local minBtn = make("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -72, 0, 8),
		BackgroundColor3 = THEME.Element,
		Text = "–",
		TextColor3 = WHITE,
		Font = THEME.FontBold,
		TextSize = 18,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, top)
	corner(minBtn, UDim.new(0, 6))
	stroke(minBtn, WHITE, 1, 0.7)
	minBtn.MouseEnter:Connect(function() tween(minBtn, { BackgroundColor3 = WHITE, TextColor3 = BLACK }) end)
	minBtn.MouseLeave:Connect(function() tween(minBtn, { BackgroundColor3 = THEME.Element, TextColor3 = WHITE }) end)
	minBtn.MouseButton1Click:Connect(function() self:Toggle(false) end)

	-- tab list
	local tabList = make("Frame", {
		Name = "TabList",
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.fromOffset(THEME.TabW, THEME.WinH - 44),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
	}, win)
	corner(tabList)
	make("Frame", { -- cover right corners
		Size = UDim2.new(0, 12, 1, 0), Position = UDim2.new(1, -12, 0, 0),
		BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
	}, tabList)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}, tabList)
	make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabList)
	self.TabList = tabList

	-- content area
	local content = make("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(THEME.TabW, 44),
		Size = UDim2.new(1, -THEME.TabW, 1, -44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, win)
	self.Content = content

	-- drag
	local dragging, dragStart, startPos = false, nil, nil
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = win.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			win.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	-- keybind toggle
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == self.Keybind then
			self:Toggle(not self.Visible)
		end
	end))

	-- fade in
	win.BackgroundTransparency = 1
	tween(win, { BackgroundTransparency = 0 })
end

function Window:Toggle(v)
	if self.Destroyed then return end
	self.Visible = v ~= nil and v or not self.Visible
	self.Frame.Visible = self.Visible
end

function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, c in ipairs(self.Connections) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	if self.Gui then self.Gui:Destroy() end
end

---------------------------------------------------------------------
-- TAB
---------------------------------------------------------------------
local Tab = {}
Tab.__index = Tab

function Window:Tab(name)
	local tab = setmetatable({}, Tab)
	tab.Name = name
	tab.Window = self
	tab.Sections = {}
	tab.Elements = {}

	local btn = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = 0.4,
		Text = name,
		TextColor3 = WHITE,
		Font = THEME.FontBold,
		TextSize = 13,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, self.TabList)
	corner(btn, UDim.new(0, 6))
	local btnStroke = stroke(btn, WHITE, 1, 0.85)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, btn)
	tab.Button = btn
	tab.ButtonStroke = btnStroke

	-- content holder for this tab
	local holder = make("Frame", {
		Name = "Tab_" .. name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	}, self.Content)
	tab.Holder = holder

	local scroll = make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = WHITE,
		ScrollBarImageTransparency = 0.5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, holder)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 16),
	}, scroll)
	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroll)
	tab.Scroll = scroll

	btn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	btn.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then
			tween(btn, { BackgroundTransparency = 0.15 })
		end
	end)
	btn.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then
			tween(btn, { BackgroundTransparency = 0.4 })
		end
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then self:SelectTab(tab) end
	return tab
end

function Window:SelectTab(tab)
	if self.CurrentTab == tab then return end
	if self.CurrentTab then
		self.CurrentTab.Holder.Visible = false
		tween(self.CurrentTab.Button, { BackgroundTransparency = 0.4, TextColor3 = WHITE })
		self.CurrentTab.ButtonStroke.Transparency = 0.85
	end
	self.CurrentTab = tab
	tab.Holder.Visible = true
	tween(tab.Button, { BackgroundTransparency = 0, TextColor3 = BLACK })
	tab.ButtonStroke.Transparency = 1
end

---------------------------------------------------------------------
-- SECTION
---------------------------------------------------------------------
local Section = {}
Section.__index = Section

function Tab:Section(name)
	local sec = setmetatable({}, Section)
	sec.Name = name
	sec.Tab = self

	local frame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Section,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	}, self.Scroll)
	corner(frame, UDim.new(0, 8))
	stroke(frame, WHITE, 1, 0.85)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, frame)
	make("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)

	-- section header
	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
	}, frame)
	label({
		Size = UDim2.new(1, 0, 1, 0),
		Text = name:upper(),
		Font = THEME.FontBold,
		TextSize = 11,
		TextColor3 = THEME.TextDim,
	}, header)

	sec.Frame = frame
	sec.Header = header
	sec.Order = 0
	sec.Elements = {}

	table.insert(self.Sections, sec)
	return sec
end

function Section:_nextOrder()
	self.Order += 1
	return self.Order
end

---------------------------------------------------------------------
-- ELEMENTS
---------------------------------------------------------------------

-- Button
function Section:Button(text, callback)
	local btn = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
		LayoutOrder = self:_nextOrder(),
	}, self.Frame)
	corner(btn, UDim.new(0, 6))
	stroke(btn, WHITE, 1, 0.85)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, btn)

	local txt = label({
		Size = UDim2.new(1, 0, 1, 0),
		Text = text,
		TextColor3 = WHITE,
		Font = THEME.FontBold,
		TextSize = 13,
	}, btn)

	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = WHITE })
		txt.TextColor3 = BLACK
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = THEME.Element })
		txt.TextColor3 = WHITE
	end)
	btn.MouseButton1Click:Connect(function()
		local abs = btn.AbsolutePosition
		local sz = btn.AbsoluteSize
		ripple(btn, sz.X / 2, sz.Y / 2)
		if callback then
			local ok, err = pcall(callback)
			if not ok then warn("[StardustUI] Button callback error:", err) end
		end
	end)

	table.insert(self.Elements, btn)
	return {
		Button = btn,
		SetText = function(_, t) txt.Text = t end,
		Destroy = function() btn:Destroy() end,
	}
end

-- Toggle
function Section:Toggle(text, default, callback)
	default = default == true
	local state = default

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.85)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)

	label({
		Size = UDim2.new(1, -50, 1, 0),
		Text = text,
		TextSize = 13,
	}, holder)

	local btn = make("TextButton", {
		Size = UDim2.fromOffset(36, 18),
		Position = UDim2.new(1, -36, 0.5, -9),
		BackgroundColor3 = state and WHITE or THEME.Section,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, holder)
	corner(btn, UDim.new(1, 0))
	stroke(btn, WHITE, 1, 0.5)

	local knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = state and UDim2.new(1, -15, 0.5, -7) or UDim2.fromOffset(2, 2),
		BackgroundColor3 = state and BLACK or WHITE,
		BorderSizePixel = 0,
	}, btn)
	corner(knob, UDim.new(1, 0))

	local function apply(v)
		state = v
		tween(btn, { BackgroundColor3 = state and WHITE or THEME.Section })
		tween(knob, {
			Position = state and UDim2.new(1, -15, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
			BackgroundColor3 = state and BLACK or WHITE,
		})
	end

	btn.MouseButton1Click:Connect(function()
		apply(not state)
		if callback then
			local ok, err = pcall(callback, state)
			if not ok then warn("[StardustUI] Toggle callback error:", err) end
		end
	end)

	table.insert(self.Elements, holder)
	return {
		Set = function(_, v) apply(v) end,
		Get = function() return state end,
		Destroy = function() holder:Destroy() end,
	}
end

-- Slider
function Section:Slider(text, min, max, default, callback)
	min = min or 0
	max = max or 100
	default = math.clamp(default or min, min, max)
	local value = default

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.85)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, holder)

	label({ Size = UDim2.new(1, -60, 0, 16), Text = text, TextSize = 13 }, holder)
	local valLabel = label({
		Size = UDim2.new(0, 60, 0, 16),
		Position = UDim2.new(1, -60, 0, 0),
		Text = tostring(value),
		TextSize = 12,
		TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = THEME.FontBold,
	}, holder)

	local track = make("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = THEME.Section,
		BorderSizePixel = 0,
	}, holder)
	corner(track, UDim.new(1, 0))

	local fill = make("Frame", {
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, track)
	corner(fill, UDim.new(1, 0))

	local knob = make("Frame", {
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, track)
	corner(knob, UDim.new(1, 0))
	stroke(knob, WHITE, 2, 0.6)

	local dragging = false
	local function updateFromX(x)
		local abs = track.AbsolutePosition
		local sz = track.AbsoluteSize
		local pct = math.clamp((x - abs.X) / sz.X, 0, 1)
		value = min + (max - min) * pct
		if max - min >= 10 then value = math.floor(value + 0.5) end
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		valLabel.Text = tostring(value)
		if callback then
			local ok, err = pcall(callback, value)
			if not ok then warn("[StardustUI] Slider callback error:", err) end
		end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	table.insert(self.Elements, holder)
	return {
		Set = function(_, v)
			v = math.clamp(v, min, max)
			local pct = (v - min) / (max - min)
			value = v
			fill.Size = UDim2.new(pct, 0, 1, 0)
			knob.Position = UDim2.new(pct, 0, 0.5, 0)
			valLabel.Text = tostring(value)
		end,
		Get = function() return value end,
		Destroy = function() holder:Destroy() end,
	}
end

-- Textbox
function Section:Textbox(text, default, callback)
	default = default or ""

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.85)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)

	label({
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = text,
		TextSize = 13,
	}, holder)

	local box = make("TextBox", {
		Size = UDim2.new(0.5, -8, 0, 22),
		Position = UDim2.new(0.5, 4, 0.5, -11),
		BackgroundColor3 = THEME.Section,
		Text = default,
		PlaceholderText = "type...",
		TextColor3 = WHITE,
		PlaceholderColor3 = THEME.TextMute,
		Font = THEME.Font,
		TextSize = 12,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
	}, holder)
	corner(box, UDim.new(0, 5))
	stroke(box, WHITE, 1, 0.7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)

	box.Focused:Connect(function()
		tween(box, { BackgroundColor3 = WHITE, TextColor3 = BLACK })
	end)
	box.FocusLost:Connect(function(enter)
		tween(box, { BackgroundColor3 = THEME.Section, TextColor3 = WHITE })
		if callback then
			local ok, err = pcall(callback, box.Text, enter)
			if not ok then warn("[StardustUI] Textbox callback error:", err) end
		end
	end)

	table.insert(self.Elements, holder)
	return {
		Set = function(_, t) box.Text = t end,
		Get = function() return box.Text end,
		Destroy = function() holder:Destroy() end,
	}
end

-- Dropdown
function Section:Dropdown(text, options, default, callback)
	options = options or {}
	default = default or (options[1] or "")
	local value = default
	local open = false

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ClipsDescendants = true,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.85)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 8),
	}, holder)

	label({
		Size = UDim2.new(0.5, 0, 0, 22),
		Text = text,
		TextSize = 13,
	}, holder)

	local current = label({
		Size = UDim2.new(0.5, -8, 0, 22),
		Position = UDim2.new(0.5, 4, 0, 0),
		Text = value .. "  ▾",
		TextSize = 12,
		TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, holder)

	local list = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, holder)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local items = {}
	local function rebuild()
		for _, it in ipairs(items) do it:Destroy() end
		items = {}
		for i, opt in ipairs(options) do
			local it = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundColor3 = THEME.Section,
				Text = opt,
				TextColor3 = WHITE,
				Font = THEME.Font,
				TextSize = 12,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = i,
			}, list)
			corner(it, UDim.new(0, 4))
			make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, it)
			it.MouseEnter:Connect(function() tween(it, { BackgroundColor3 = WHITE, TextColor3 = BLACK }) end)
			it.MouseLeave:Connect(function() tween(it, { BackgroundColor3 = THEME.Section, TextColor3 = WHITE }) end)
			it.MouseButton1Click:Connect(function()
				value = opt
				current.Text = opt .. "  ▾"
				open = false
				tween(holder, { Size = UDim2.new(1, 0, 0, 32) })
				if callback then
					local ok, err = pcall(callback, value)
					if not ok then warn("[StardustUI] Dropdown callback error:", err) end
				end
			end)
			items[#items + 1] = it
		end
	end
	rebuild()

	holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			open = not open
			if open then
				tween(holder, { Size = UDim2.new(1, 0, 0, 28 + #options * 24) })
			else
				tween(holder, { Size = UDim2.new(1, 0, 0, 32) })
			end
		end
	end)

	table.insert(self.Elements, holder)
	return {
		Set = function(_, v) value = v; current.Text = v .. "  ▾" end,
		Get = function() return value end,
		SetOptions = function(_, newOpts) options = newOpts; rebuild() end,
		Destroy = function() holder:Destroy() end,
	}
end

-- Keybind
function Section:Keybind(text, default, callback)
	default = default or Enum.KeyCode.Unknown
	local current = default
	local listening = false

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.85)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)

	label({ Size = UDim2.new(0.5, 0, 1, 0), Text = text, TextSize = 13 }, holder)

	local btn = make("TextButton", {
		Size = UDim2.new(0.5, -8, 0, 22),
		Position = UDim2.new(0.5, 4, 0.5, -11),
		BackgroundColor3 = THEME.Section,
		Text = current.Name,
		TextColor3 = WHITE,
		Font = THEME.FontBold,
		TextSize = 12,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, holder)
	corner(btn, UDim.new(0, 5))
	stroke(btn, WHITE, 1, 0.7)

	btn.MouseButton1Click:Connect(function()
		listening = true
		btn.Text = "..."
		tween(btn, { BackgroundColor3 = WHITE, TextColor3 = BLACK })
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			current = input.KeyCode
			btn.Text = current.Name
			tween(btn, { BackgroundColor3 = THEME.Section, TextColor3 = WHITE })
			if callback then
				local ok, err = pcall(callback, current)
				if not ok then warn("[StardustUI] Keybind callback error:", err) end
			end
		end
	end)

	table.insert(self.Elements, holder)
	return {
		Get = function() return current end,
		Set = function(_, k) current = k; btn.Text = k.Name end,
		Destroy = function() holder:Destroy() end,
	}
end

-- Label
function Section:Label(text)
	local l = label({
		Size = UDim2.new(1, 0, 0, 20),
		Text = text,
		TextSize = 12,
		TextColor3 = THEME.TextDim,
		LayoutOrder = self:_nextOrder(),
		TextWrapped = true,
	}, self.Frame)
	table.insert(self.Elements, l)
	return {
		Set = function(_, t) l.Text = t end,
		Destroy = function() l:Destroy() end,
	}
end

-- Divider
function Section:Divider()
	local d = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
	}, self.Frame)
	table.insert(self.Elements, d)
	return { Destroy = function() d:Destroy() end }
end

---------------------------------------------------------------------
-- DONE
---------------------------------------------------------------------
return StardustUI
