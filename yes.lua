--[[
	StardustUI v3 — grey sky, bright sparkles, frequent shooters, confirm-on-quit
	Load via require() or loadstring(). API is unchanged from v2.
]]

local StardustUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rng = Random.new()

---------------------------------------------------------------------
-- THEME (lighter, greyer)
---------------------------------------------------------------------
local THEME = {
	Bg        = Color3.fromRGB(45, 45, 52),
	BgInner   = Color3.fromRGB(55, 55, 64),
	Panel     = Color3.fromRGB(52, 52, 60),
	Section   = Color3.fromRGB(62, 62, 72),
	Element   = Color3.fromRGB(74, 74, 86),
	Stroke    = Color3.fromRGB(255, 255, 255),
	Text      = Color3.fromRGB(255, 255, 255),
	TextDim   = Color3.fromRGB(200, 200, 210),
	TextMute  = Color3.fromRGB(130, 130, 145),
	Font      = Enum.Font.GothamMedium,
	FontBold  = Enum.Font.GothamBold,
	Corner    = UDim.new(0, 8),
	Anim      = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	WinW      = 580,
	WinH      = 460,
	TabW      = 140,
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local FADE_ENDS = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 1),
})

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

local _origAnimatedStroke
local function animatedStroke(parent, thickness, baseTransparency)
	local st = stroke(parent, THEME.Stroke, thickness or 1.4, baseTransparency or 0.55)
	local grad = make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.4, 0.85),
			NumberSequenceKeypoint.new(0.5, 0.15),
			NumberSequenceKeypoint.new(0.6, 0.85),
			NumberSequenceKeypoint.new(1, 0.9),
		}),
	}, st)
	if StardustUI._strokes then
		table.insert(StardustUI._strokes, { grad = grad, offset = rng:NextNumber(0, 360) })
	end
	return st, grad
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

local function tween(inst, props, info)
	TweenService:Create(inst, info or THEME.Anim, props):Play()
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
		Size = UDim2.fromOffset(220, 220),
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.45, function() r:Destroy() end)
end

---------------------------------------------------------------------
-- NIGHT SKY
---------------------------------------------------------------------
local function createNightSky(parent)
	local sky = make("Frame", {
		Name = "NightSky",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = THEME.Bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	}, parent)
	corner(sky)

	local layers = {}
	for i = 1, 5 do
		layers[i] = make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = i + 1,
			ClipsDescendants = true,
		}, sky)
	end

	-- parallax stars
	local stars = {}
	local function addStars(count, size, speed, baseTr, depth, z)
		for _ = 1, count do
			local f = make("Frame", {
				Size = UDim2.fromOffset(size, size),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = WHITE,
				BorderSizePixel = 0,
				ZIndex = z,
			}, layers[z - 1])
			if size >= 2 then corner(f, UDim.new(1, 0)) end
			stars[#stars + 1] = {
				f = f,
				x = rng:NextNumber(), y = rng:NextNumber(),
				speed = speed * rng:NextNumber(0.7, 1.3),
				phase = rng:NextNumber(0, math.pi * 2),
				tw = rng:NextNumber(0.6, 2.4),
				base = baseTr,
				depth = depth,
			}
		end
	end
	addStars(60, 1, 0.006, 0.35, 0.01, 2)   -- brighter far stars
	addStars(28, 2, 0.013, 0.15, 0.02, 3)   -- brighter mid stars
	addStars(12, 3, 0.022, 0.05, 0.035, 4)  -- brighter near stars

	-- BRIGHTER SPARKLES
	local sparkles = {}
	for _ = 1, 6 do
		local c = make("Frame", {
			Size = UDim2.fromOffset(20, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 4,
		}, layers[3])

		-- soft bloom halo behind the cross
		local halo = make("Frame", {
			Size = UDim2.fromScale(1.6, 1.6),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, c)
		corner(halo, UDim.new(1, 0))
		make("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, halo)

		local h = make("Frame", {
			Size = UDim2.new(1, 0, 0, 1), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = WHITE, BorderSizePixel = 0,
			ZIndex = 4,
		}, c)
		make("UIGradient", { Transparency = FADE_ENDS }, h)
		local v = make("Frame", {
			Size = UDim2.new(0, 1, 1, 0), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = WHITE, BorderSizePixel = 0,
			ZIndex = 4,
		}, c)
		make("UIGradient", { Transparency = FADE_ENDS, Rotation = 90 }, v)
		local core = make("Frame", {
			Size = UDim2.fromOffset(4, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = WHITE, BorderSizePixel = 0,
			ZIndex = 5,
		}, c)
		corner(core, UDim.new(1, 0))
		sparkles[#sparkles + 1] = {
			c = c, h = h, v = v, core = core, halo = halo,
			x = rng:NextNumber(0.05, 0.95), y = rng:NextNumber(0.05, 0.95),
			vx = rng:NextNumber(-0.003, 0.003), vy = rng:NextNumber(0.001, 0.005),
			phase = rng:NextNumber(0, math.pi * 2),
			tw = rng:NextNumber(0.5, 1.4),
		}
	end

	-- constellation dots
	local constNodes = {}
	for _ = 1, 8 do
		local f = make("Frame", {
			Size = UDim2.fromOffset(rng:NextInteger(3, 4), rng:NextInteger(3, 4)),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, layers[2])
		corner(f, UDim.new(1, 0))
		make("UIStroke", { Color = WHITE, Thickness = 2, Transparency = 0.85 }, f)
		constNodes[#constNodes + 1] = {
			f = f,
			x = rng:NextNumber(0.05, 0.95), y = rng:NextNumber(0.05, 0.95),
			phase = rng:NextNumber(0, math.pi * 2),
		}
	end

	-- frequent shooting stars
	local shooters = {}
	local nextShooter = 0.5

	local function spawnShooter()
		local W = sky.AbsoluteSize.X
		if W < 50 then return end
		local len = rng:NextNumber(70, 130)
		local ang = math.rad(rng:NextNumber(18, 40))
		local dirx = rng:NextNumber() < 0.5 and 1 or -1
		local dx, dy = math.cos(ang) * dirx, math.sin(ang)
		local rot = math.deg(math.atan2(dy, dx))
		local tail = make("Frame", {
			Size = UDim2.fromOffset(len, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			Rotation = rot,
			ZIndex = 4,
		}, layers[3])
		make("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.7, 0.3),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}, tail)
		local head = make("Frame", {
			Size = UDim2.fromOffset(4, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, layers[3])
		corner(head, UDim.new(1, 0))
		make("UIStroke", { Color = WHITE, Thickness = 4, Transparency = 0.6 }, head)
		shooters[#shooters + 1] = {
			tail = tail, head = head,
			x = rng:NextNumber(0.1, 0.9) * W, y = -40,
			dx = dx, dy = dy,
			speed = rng:NextNumber(450, 700),
			age = 0, life = rng:NextNumber(1.0, 1.8),
		}
	end

	local elapsed = 0
	local function update(dt)
		elapsed += dt
		local W = sky.AbsoluteSize.X
		local H = sky.AbsoluteSize.Y
		if W <= 0 or H <= 0 then return end

		for _, s in ipairs(stars) do
			s.y += s.speed * dt
			s.x -= s.speed * 0.35 * dt
			if s.y > 1.02 then
				s.y = -0.02; s.x = rng:NextNumber()
				s.phase = rng:NextNumber(0, math.pi * 2)
				s.tw = rng:NextNumber(0.6, 2.4)
			end
			if s.x < -0.02 then s.x = 1.02 end
			s.f.Position = UDim2.fromScale(s.x, s.y)
			local sh = math.sin(elapsed * s.tw + s.phase)
			sh = sh > 0 and (sh ^ 0.5) or (sh * 0.35)
			local tw = 0.5 + 0.5 * sh
			s.f.BackgroundTransparency = s.base + (1 - s.base) * 0.7 * tw
		end

		-- brighter sparkles: bigger pulse, brighter minimum, halo breathes too
		for _, sp in ipairs(sparkles) do
			sp.x += sp.vx * dt
			sp.y += sp.vy * dt
			if sp.x < -0.03 then sp.x = 1.03 elseif sp.x > 1.03 then sp.x = -0.03 end
			if sp.y > 1.03 then sp.y = -0.03 end
			sp.c.Position = UDim2.fromScale(sp.x, sp.y)
			local s = math.max(0, math.sin(elapsed * sp.tw + sp.phase))
			local p = s ^ 2           -- softer falloff so it's bright more of the time
			local boost = 0.35 + 0.65 * p -- never fully dark
			sp.c.Size = UDim2.fromOffset(14 + 20 * p, 14 + 20 * p)
			local tr = 1 - (0.55 + 0.45 * boost) -- arms stay visible
			sp.h.BackgroundTransparency = tr
			sp.v.BackgroundTransparency = tr
			sp.core.BackgroundTransparency = math.max(0, 0.35 * (1 - boost))
			sp.halo.BackgroundTransparency = 0.35 + 0.4 * (1 - p)
			sp.c.Rotation = math.deg(math.atan2(sp.vy, sp.vx)) + elapsed * 6
		end

		for _, nd in ipairs(constNodes) do
			nd.f.Position = UDim2.fromScale(nd.x, nd.y)
			local pulse = 0.5 + 0.5 * math.sin(elapsed * 1.4 + nd.phase)
			nd.f.BackgroundTransparency = 0.4 * (1 - pulse)
		end

		-- frequent shooters: keep up to 3 alive, respawn every 1.2–2.8s
		if elapsed >= nextShooter and #shooters < 3 then
			spawnShooter()
			nextShooter = elapsed + rng:NextNumber(1.2, 2.8)
		end
		for i = #shooters, 1, -1 do
			local s = shooters[i]
			s.age += dt
			s.x += s.dx * s.speed * dt
			s.y += s.dy * s.speed * dt
			s.tail.Position = UDim2.fromOffset(s.x, s.y)
			s.head.Position = UDim2.fromOffset(
				s.x + s.dx * s.tail.AbsoluteSize.X * 0.5,
				s.y + s.dy * s.tail.AbsoluteSize.X * 0.5
			)
			local fade = math.min(1, s.age / 0.15) * math.min(1, (s.life - s.age) / 0.3)
			s.tail.BackgroundTransparency = 1 - fade
			s.head.BackgroundTransparency = 1 - fade
			if s.y > H + 60 or s.x < -120 or s.x > W + 120 or s.age >= s.life then
				s.tail:Destroy(); s.head:Destroy()
				table.remove(shooters, i)
			end
		end
	end

	return sky, update
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
	self.Keybind = opts.Keybind or Enum.KeyCode.RightShift
	self.Visible = true
	self.Tabs = {}
	self.CurrentTab = nil
	self.Connections = {}
	self.Destroyed = false
	self.Updaters = {}
	self._resetters = {} -- toggles register here

	if not StardustUI._strokeRunning then
		StardustUI._strokeRunning = true
		StardustUI._strokes = {}
		RunService.Heartbeat:Connect(function()
			local t = os.clock()
			for _, entry in ipairs(StardustUI._strokes) do
				if entry.grad and entry.grad.Parent then
					entry.grad.Rotation = (t * 80 + entry.offset) % 360
				end
			end
		end)
	end

	local sg = playerGui:FindFirstChild("StardustUI")
	if not sg then
		sg = make("ScreenGui", {
			Name = "StardustUI",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 2500,
		}, playerGui)
	end
	self.Gui = sg

	self:_build()

	if not StardustUI._running then
		StardustUI._running = true
		StardustUI._windows = {}
		RunService.Heartbeat:Connect(function(dt)
			dt = math.min(dt, 0.1)
			for _, w in ipairs(StardustUI._windows) do
				if not w.Destroyed and w.Visible then
					for _, fn in ipairs(w.Updaters) do fn(dt) end
				end
			end
		end)
	end
	table.insert(StardustUI._windows, self)

	return self
end

function Window:_build()
	local win = make("Frame", {
		Name = "Window_" .. self.Title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(THEME.WinW, THEME.WinH),
		BackgroundColor3 = THEME.Bg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		ZIndex = 10,
	}, self.Gui)
	corner(win)
	self.WindowStroke, self.WindowGrad = animatedStroke(win, 1.5, 0.25)
	self.Frame = win

	local sky, skyUpdate = createNightSky(win)
	self.Sky = sky
	table.insert(self.Updaters, skyUpdate)

	-- lighter veil now
	local veil = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = THEME.Bg,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, win)
	corner(veil)

	-- top bar
	local top = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 12,
	}, win)
	corner(top)
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, top)
	local topLine = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, top)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, topLine)

	label({
		Size = UDim2.new(1, -110, 0, 20),
		Position = UDim2.fromOffset(16, 6),
		Text = self.Title,
		Font = THEME.FontBold, TextSize = 15, ZIndex = 13,
	}, top)
	label({
		Size = UDim2.new(1, -110, 0, 14),
		Position = UDim2.fromOffset(16, 24),
		Text = self.Subtitle,
		TextSize = 11, TextColor3 = THEME.TextDim, ZIndex = 13,
	}, top)
	self.Top = top

	local closeBtn = make("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -36, 0, 9),
		BackgroundColor3 = THEME.Element,
		Text = "×",
		TextColor3 = WHITE,
		Font = THEME.FontBold, TextSize = 18,
		BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 14,
	}, top)
	corner(closeBtn, UDim.new(0, 6))
	stroke(closeBtn, WHITE, 1, 0.7)
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, { BackgroundColor3 = WHITE, TextColor3 = BLACK }) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, { BackgroundColor3 = THEME.Element, TextColor3 = WHITE }) end)
	closeBtn.MouseButton1Click:Connect(function()
		self:_showQuitConfirm()
	end)

	-- tab sidebar
	local tabListBg = make("Frame", {
		Name = "TabListBg",
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.fromOffset(THEME.TabW, THEME.WinH - 46),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, win)
	corner(tabListBg)
	make("Frame", {
		Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -14, 0, 0),
		BackgroundColor3 = THEME.Panel, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, ZIndex = 11,
	}, tabListBg)
	make("Frame", {
		Size = UDim2.new(0, 1, 1, -16),
		Position = UDim2.new(1, -1, 0, 8),
		BackgroundColor3 = WHITE, BackgroundTransparency = 0.7,
		BorderSizePixel = 0, ZIndex = 11,
	}, tabListBg)

	local tabScroll = make("ScrollingFrame", {
		Name = "TabScroll",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = WHITE,
		ScrollBarImageTransparency = 0.6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 12,
	}, tabListBg)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 12),
	}, tabScroll)
	make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabScroll)
	self.TabScroll = tabScroll

	local content = make("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(THEME.TabW + 1, 46),
		Size = UDim2.new(1, -(THEME.TabW + 1), 1, -46),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 11,
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
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - dragStart
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == self.Keybind then
			self:Toggle(not self.Visible)
		end
	end))

	tween(win, { BackgroundTransparency = 0 }, TweenInfo.new(0.3))
end

-- QUIT CONFIRM DIALOG
function Window:_showQuitConfirm()
	if self._confirmOpen then return end
	self._confirmOpen = true

	local overlayFrame = make("Frame", {
		Name = "QuitConfirm",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 200,
	}, self.Gui)
	self._confirmFrame = overlayFrame

	local dlg = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 190),
		BackgroundColor3 = THEME.Bg,
		BorderSizePixel = 0,
		ZIndex = 201,
	}, overlayFrame)
	corner(dlg, UDim.new(0, 12))
	local dlgStroke = animatedStroke(dlg, 1.5, 0.15)

	local icon = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 22),
		Size = UDim2.new(1, 0, 0, 24),
		Text = "⚠",
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = WHITE,
		ZIndex = 202,
	}, dlg)

	label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.new(1, -40, 0, 20),
		Text = "Quit StardustUI?",
		Font = THEME.FontBold, TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 202,
	}, dlg)

	label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 82),
		Size = UDim2.new(1, -50, 0, 40),
		Text = "This will turn off everything and close the menu. Continue?",
		TextSize = 12, TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		ZIndex = 202,
	}, dlg)

	local function styledBtn(text, xPos, width, isPrimary)
		local b = make("TextButton", {
			Size = UDim2.fromOffset(width, 34),
			Position = UDim2.new(0.5, xPos, 1, -54),
			BackgroundColor3 = isPrimary and WHITE or THEME.Element,
			Text = text,
			TextColor3 = isPrimary and BLACK or WHITE,
			Font = THEME.FontBold, TextSize = 13,
			BorderSizePixel = 0, AutoButtonColor = false,
			ZIndex = 202,
		}, dlg)
		corner(b, UDim.new(0, 6))
		if not isPrimary then stroke(b, WHITE, 1, 0.6) end
		b.MouseEnter:Connect(function()
			if isPrimary then
				tween(b, { BackgroundColor3 = Color3.fromRGB(230, 230, 230) })
			else
				tween(b, { BackgroundColor3 = WHITE, TextColor3 = BLACK })
			end
		end)
		b.MouseLeave:Connect(function()
			if isPrimary then
				tween(b, { BackgroundColor3 = WHITE })
			else
				tween(b, { BackgroundColor3 = THEME.Element, TextColor3 = WHITE })
			end
		end)
		return b
	end

	local cancelBtn = styledBtn("Cancel", -80, 150, false)
	local confirmBtn = styledBtn("Confirm", 80, 150, true)

	local function closeDialog()
		if not self._confirmOpen then return end
		self._confirmOpen = false
		local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(overlayFrame, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(dlg, info, { Size = UDim2.fromOffset(320, 160), BackgroundTransparency = 1 }):Play()
		task.delay(0.22, function()
			if overlayFrame.Parent then overlayFrame:Destroy() end
		end)
		self._confirmFrame = nil
	end

	cancelBtn.MouseButton1Click:Connect(closeDialog)

	confirmBtn.MouseButton1Click:Connect(function()
		closeDialog()
		-- turn off every toggle
		for _, reset in ipairs(self._resetters) do
			pcall(reset)
		end
		-- destroy
		task.delay(0.15, function()
			self:Destroy()
			-- destroy entire ScreenGui if no other windows live
			local remaining = 0
			if StardustUI._windows then
				for _, w in ipairs(StardustUI._windows) do
					if not w.Destroyed then remaining += 1 end
				end
			end
			if remaining == 0 and self.Gui and self.Gui.Parent then
				self.Gui:Destroy()
			end
		end)
	end)

	-- fade in
	overlayFrame.BackgroundTransparency = 1
	dlg.BackgroundTransparency = 1
	TweenService:Create(overlayFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(dlg, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
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
	if self._confirmFrame and self._confirmFrame.Parent then
		self._confirmFrame:Destroy()
	end
	if self.Frame then self.Frame:Destroy() end
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

	local btn = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = 0.4,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ZIndex = 13,
	}, self.TabScroll)
	corner(btn, UDim.new(0, 6))
	tab.ButtonStroke, tab.ButtonGrad = animatedStroke(btn, 1, 0.8)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, btn)
	local txt = label({
		Size = UDim2.fromScale(1, 1),
		Text = name,
		TextColor3 = WHITE,
		Font = THEME.FontBold, TextSize = 13,
		ZIndex = 14,
	}, btn)
	tab.Button = btn
	tab.ButtonText = txt

	local holder = make("Frame", {
		Name = "TabContent_" .. name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 12,
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
		ZIndex = 12,
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

	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	btn.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then tween(btn, { BackgroundTransparency = 0.15 }) end
	end)
	btn.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then tween(btn, { BackgroundTransparency = 0.4 }) end
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then self:SelectTab(tab) end
	return tab
end

function Window:SelectTab(tab)
	if self.CurrentTab == tab then return end
	if self.CurrentTab then
		self.CurrentTab.Holder.Visible = false
		tween(self.CurrentTab.Button, { BackgroundColor3 = THEME.Element, BackgroundTransparency = 0.4 })
		self.CurrentTab.ButtonText.TextColor3 = WHITE
		self.CurrentTab.ButtonStroke.Transparency = 0.8
	end
	self.CurrentTab = tab
	tab.Holder.Visible = true
	tween(tab.Button, { BackgroundColor3 = WHITE, BackgroundTransparency = 0 })
	tab.ButtonText.TextColor3 = BLACK
	tab.ButtonStroke.Transparency = 0.1
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
	sec.Order = 0
	sec.Elements = {}

	local frame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Section,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, self.Scroll)
	corner(frame, UDim.new(0, 8))
	sec.Stroke, sec.Grad = animatedStroke(frame, 1, 0.6)
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

	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		ZIndex = 13,
	}, frame)
	label({
		Size = UDim2.new(1, 0, 1, 0),
		Text = name:upper(),
		Font = THEME.FontBold, TextSize = 11,
		TextColor3 = THEME.TextDim, ZIndex = 13,
	}, header)

	sec.Frame = frame
	sec.Header = header
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
function Section:Button(text, callback)
	local btn = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		Text = "",
		BorderSizePixel = 0, AutoButtonColor = false,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 13,
	}, self.Frame)
	corner(btn, UDim.new(0, 6))
	stroke(btn, WHITE, 1, 0.7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, btn)
	local txt = label({
		Size = UDim2.new(1, 0, 1, 0),
		Text = text, TextColor3 = WHITE,
		Font = THEME.FontBold, TextSize = 13, ZIndex = 14,
	}, btn)
	btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = WHITE }); txt.TextColor3 = BLACK end)
	btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = THEME.Element }); txt.TextColor3 = WHITE end)
	btn.MouseButton1Click:Connect(function()
		ripple(btn, btn.AbsoluteSize.X / 2, btn.AbsoluteSize.Y / 2)
		if callback then
			local ok, err = pcall(callback)
			if not ok then warn("[StardustUI]", err) end
		end
	end)
	return {
		Button = btn,
		SetText = function(_, t) txt.Text = t end,
		Destroy = function() btn:Destroy() end,
	}
end

function Section:Toggle(text, default, callback)
	default = default == true
	local state = default

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 13,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)
	label({ Size = UDim2.new(1, -50, 1, 0), Text = text, TextSize = 13, ZIndex = 14 }, holder)

	local btn = make("TextButton", {
		Size = UDim2.fromOffset(36, 18),
		Position = UDim2.new(1, -36, 0.5, -9),
		BackgroundColor3 = state and WHITE or THEME.Section,
		Text = "", BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 14,
	}, holder)
	corner(btn, UDim.new(1, 0))
	stroke(btn, WHITE, 1, 0.5)
	local knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = state and UDim2.new(1, -15, 0.5, -7) or UDim2.fromOffset(2, 2),
		BackgroundColor3 = state and BLACK or WHITE,
		BorderSizePixel = 0, ZIndex = 15,
	}, btn)
	corner(knob, UDim.new(1, 0))

	local function apply(v, fire)
		state = v
		tween(btn, { BackgroundColor3 = state and WHITE or THEME.Section })
		tween(knob, {
			Position = state and UDim2.new(1, -15, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
			BackgroundColor3 = state and BLACK or WHITE,
		})
		if fire and callback then
			local ok, err = pcall(callback, state)
			if not ok then warn("[StardustUI]", err) end
		end
	end

	btn.MouseButton1Click:Connect(function() apply(not state, true) end)

	-- register reset for quit confirmation
	table.insert(self.Tab.Window._resetters, function()
		if state then apply(false, true) end
	end)

	return {
		Set = function(_, v) apply(v, false) end,
		Get = function() return state end,
		Destroy = function() holder:Destroy() end,
	}
end

function Section:Slider(text, min, max, default, callback)
	min, max = min or 0, max or 100
	default = math.clamp(default or min, min, max)
	local value = default
	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 13,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.7)
	make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, holder)
	label({ Size = UDim2.new(1, -60, 0, 16), Text = text, TextSize = 13, ZIndex = 14 }, holder)
	local valLabel = label({
		Size = UDim2.new(0, 60, 0, 16),
		Position = UDim2.new(1, -60, 0, 0),
		Text = tostring(value), TextSize = 12, TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right, Font = THEME.FontBold, ZIndex = 14,
	}, holder)
	local track = make("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = THEME.Section,
		BorderSizePixel = 0, ZIndex = 14,
	}, holder)
	corner(track, UDim.new(1, 0))
	local fill = make("Frame", {
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 14,
	}, track)
	corner(fill, UDim.new(1, 0))
	local knob = make("Frame", {
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 15,
	}, track)
	corner(knob, UDim.new(1, 0))
	stroke(knob, WHITE, 2, 0.6)
	local dragging = false
	local function updateFromX(x)
		local abs, sz = track.AbsolutePosition, track.AbsoluteSize
		local pct = math.clamp((x - abs.X) / sz.X, 0, 1)
		value = min + (max - min) * pct
		if max - min >= 10 then value = math.floor(value + 0.5) end
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		valLabel.Text = tostring(value)
		if callback then pcall(callback, value) end
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

function Section:Textbox(text, default, callback)
	default = default or ""
	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 13,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)
	label({ Size = UDim2.new(0.5, 0, 1, 0), Text = text, TextSize = 13, ZIndex = 14 }, holder)
	local box = make("TextBox", {
		Size = UDim2.new(0.5, -8, 0, 22),
		Position = UDim2.new(0.5, 4, 0.5, -11),
		BackgroundColor3 = THEME.Section,
		Text = default, PlaceholderText = "type...",
		TextColor3 = WHITE, PlaceholderColor3 = THEME.TextMute,
		Font = THEME.Font, TextSize = 12,
		BorderSizePixel = 0, ClearTextOnFocus = false,
		ZIndex = 14,
	}, holder)
	corner(box, UDim.new(0, 5))
	stroke(box, WHITE, 1, 0.7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
	box.Focused:Connect(function() tween(box, { BackgroundColor3 = WHITE, TextColor3 = BLACK }) end)
	box.FocusLost:Connect(function(enter)
		tween(box, { BackgroundColor3 = THEME.Section, TextColor3 = WHITE })
		if callback then pcall(callback, box.Text, enter) end
	end)
	return {
		Set = function(_, t) box.Text = t end,
		Get = function() return box.Text end,
		Destroy = function() holder:Destroy() end,
	}
end

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
		ZIndex = 13,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.7)
	make("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)
	label({ Size = UDim2.new(0.5, 0, 0, 22), Text = text, TextSize = 13, ZIndex = 14 }, holder)
	local current = label({
		Size = UDim2.new(0.5, -8, 0, 22),
		Position = UDim2.new(0.5, 4, 0, 0),
		Text = value .. "  ▾",
		TextSize = 12, TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 14,
	}, holder)
	local list = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundTransparency = 1, ZIndex = 14,
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
				Text = opt, TextColor3 = WHITE,
				Font = THEME.Font, TextSize = 12,
				BorderSizePixel = 0, AutoButtonColor = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = i, ZIndex = 15,
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
				if callback then pcall(callback, value) end
			end)
			items[#items + 1] = it
		end
	end
	rebuild()
	holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			open = not open
			tween(holder, { Size = UDim2.new(1, 0, 0, open and (28 + #options * 24) or 32) })
		end
	end)
	return {
		Set = function(_, v) value = v; current.Text = v .. "  ▾" end,
		Get = function() return value end,
		SetOptions = function(_, o) options = o; rebuild() end,
		Destroy = function() holder:Destroy() end,
	}
end

function Section:Keybind(text, default, callback)
	default = default or Enum.KeyCode.Unknown
	local current = default
	local listening = false
	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 13,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	stroke(holder, WHITE, 1, 0.7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)
	label({ Size = UDim2.new(0.5, 0, 1, 0), Text = text, TextSize = 13, ZIndex = 14 }, holder)
	local btn = make("TextButton", {
		Size = UDim2.new(0.5, -8, 0, 22),
		Position = UDim2.new(0.5, 4, 0.5, -11),
		BackgroundColor3 = THEME.Section,
		Text = current.Name, TextColor3 = WHITE,
		Font = THEME.FontBold, TextSize = 12,
		BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 14,
	}, holder)
	corner(btn, UDim.new(0, 5))
	stroke(btn, WHITE, 1, 0.7)
	btn.MouseButton1Click:Connect(function()
		listening = true
		btn.Text = "..."
		tween(btn, { BackgroundColor3 = WHITE, TextColor3 = BLACK })
	end)
	UserInputService.InputBegan:Connect(function(input)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			current = input.KeyCode
			btn.Text = current.Name
			tween(btn, { BackgroundColor3 = THEME.Section, TextColor3 = WHITE })
			if callback then pcall(callback, current) end
		end
	end)
	return {
		Get = function() return current end,
		Set = function(_, k) current = k; btn.Text = k.Name end,
		Destroy = function() holder:Destroy() end,
	}
end

function Section:Label(text)
	local l = label({
		Size = UDim2.new(1, 0, 0, 20),
		Text = text, TextSize = 12, TextColor3 = THEME.TextDim,
		LayoutOrder = self:_nextOrder(), TextWrapped = true, ZIndex = 13,
	}, self.Frame)
	return { Set = function(_, t) l.Text = t end, Destroy = function() l:Destroy() end }
end

function Section:Divider()
	local d = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 13,
	}, self.Frame)
	return { Destroy = function() d:Destroy() end }
end

return StardustUI
