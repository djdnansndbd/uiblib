local StardustUI = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rng = Random.new()

StardustUI._closeActiveDropdown = nil
local windowCleanupKey = "__StardustUICleanup"

---------------------------------------------------------------------
-- THEME
---------------------------------------------------------------------
local THEME = {
	Bg        = Color3.fromRGB(45, 45, 52),
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
	AnimFast  = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	WinW      = 700,
	WinH      = 540,
	TabW      = 180,
	TrWindow  = 0.55,
	TrPanel   = 0.65,
	TrSection = 0.85,
	TrElement = 0.90,
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

local function animatedStroke(parent, thickness, baseTransparency)
	local st = stroke(parent, THEME.Stroke, thickness or 1.6, baseTransparency or 0.1)
	local grad = make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.85),
			NumberSequenceKeypoint.new(0.3, 0.8),
			NumberSequenceKeypoint.new(0.45, 0),
			NumberSequenceKeypoint.new(0.55, 0),
			NumberSequenceKeypoint.new(0.7, 0.8),
			NumberSequenceKeypoint.new(1, 0.85),
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
		TextStrokeTransparency = 1,
		ZIndex = 2,
	}
	for k, v in pairs(props) do base[k] = v end
	return make("TextLabel", base, parent)
end

local function addInfoTooltip(window, target, info)
	if type(info) ~= "string" or info == "" then return end

	local tooltip = make("Frame", {
		Size = UDim2.new(0, 230, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 100,
	}, window.Gui)
	corner(tooltip, UDim.new(0, 6))
	stroke(tooltip, WHITE, 1, 0.65)
	label({
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = info,
		TextSize = 11,
		TextWrapped = true,
		ZIndex = 101,
	}, tooltip)

	target.MouseEnter:Connect(function()
		if window.Destroyed then return end
		tooltip.Visible = true
		task.defer(function()
			if not tooltip.Parent or not tooltip.Visible then return end
			local camera = workspace.CurrentCamera
			if not camera then return end
			local viewport = camera.ViewportSize
			local size = tooltip.AbsoluteSize
			local targetPosition = target.AbsolutePosition
			local targetSize = target.AbsoluteSize
			local x = math.clamp(targetPosition.X, 4, math.max(4, viewport.X - size.X - 4))
			local y = targetPosition.Y + targetSize.Y + 4
			if y + size.Y > viewport.Y then
				y = math.max(4, targetPosition.Y - size.Y - 4)
			end
			tooltip.Position = UDim2.fromOffset(x, y)
		end)
	end)
	target.MouseLeave:Connect(function()
		tooltip.Visible = false
	end)
	target.Destroying:Connect(function()
		tooltip:Destroy()
	end)
end

local function tween(inst, props, info)
	TweenService:Create(inst, info or THEME.Anim, props):Play()
end

local function getExecutorName()
	if type(identifyexecutor) == "function" then
		local ok, result = pcall(identifyexecutor)
		if ok and type(result) == "string" and result ~= "" then
			return result
		end
	end
	return "Unknown"
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

local function applyHoverEffect(btn, isSelectedFunc, baseColor, hoverColor, baseTr, hoverTr, strokeObj, baseStrTr, hoverStrTr)
	btn.MouseEnter:Connect(function()
		if isSelectedFunc and isSelectedFunc() then return end
		tween(btn, { BackgroundColor3 = hoverColor, BackgroundTransparency = hoverTr }, THEME.AnimFast)
		if strokeObj then tween(strokeObj, { Transparency = hoverStrTr }, THEME.AnimFast) end
	end)
	btn.MouseLeave:Connect(function()
		if isSelectedFunc and isSelectedFunc() then return end
		tween(btn, { BackgroundColor3 = baseColor, BackgroundTransparency = baseTr }, THEME.AnimFast)
		if strokeObj then tween(strokeObj, { Transparency = baseStrTr }, THEME.AnimFast) end
	end)
end

---------------------------------------------------------------------
-- CONFIG HELPERS
---------------------------------------------------------------------
local function safeWrite(path, data)
	if writefile then
		local ok = pcall(writefile, path, data)
		return ok
	end
	return false
end

local function safeRead(path)
	if readfile and isfile and isfile(path) then
		local ok, content = pcall(readfile, path)
		if ok then return content end
	end
	return nil
end

local function serialize(value)
	local t = typeof(value)
	if t == "EnumItem" then
		return { __type = "Enum", enum = tostring(value.EnumType), name = value.Name }
	elseif t == "Color3" then
		return { __type = "Color3", r = value.R, g = value.G, b = value.B }
	elseif t == "table" then
		local out = {}
		for k, v in pairs(value) do
			out[tostring(k)] = serialize(v)
		end
		return out
	end
	return value
end

local function deserialize(value)
	if type(value) == "table" and value.__type then
		if value.__type == "Enum" then
			local enumTable = Enum[value.enum]
			if enumTable then
				return enumTable[value.name]
			end
		elseif value.__type == "Color3" then
			return Color3.new(value.r, value.g, value.b)
		end
	elseif type(value) == "table" then
		local out = {}
		for k, v in pairs(value) do
			out[k] = deserialize(v)
		end
		return out
	end
	return value
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

	local stars = {}
	local function addStars(count, size, speed, baseTr, z)
		for _ = 1, count do
			local pixelSize = size + 1
			local f = make("TextLabel", {
				Size = UDim2.fromOffset(pixelSize, pixelSize),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = WHITE,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Font = Enum.Font.SourceSansBold,
				Text = "✦",
				TextColor3 = WHITE,
				TextSize = pixelSize,
				TextTransparency = baseTr,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextScaled = true,
				ZIndex = z,
			}, layers[z - 1])
			stars[#stars + 1] = {
				f = f,
				x = rng:NextNumber(), y = rng:NextNumber(),
				speed = speed * rng:NextNumber(0.7, 1.3),
				phase = rng:NextNumber(0, math.pi * 2),
				tw = rng:NextNumber(0.6, 2.4),
				base = baseTr,
			}
		end
	end
	addStars(60, 1, 0.006, 0.35, 2)
	addStars(28, 2, 0.013, 0.15, 3)
	addStars(12, 3, 0.022, 0.05, 4)

	local sparkles = {}
	for _ = 1, 6 do
		local c = make("Frame", {
			Size = UDim2.fromOffset(20, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 4,
		}, layers[3])
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
			BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4,
		}, c)
		make("UIGradient", { Transparency = FADE_ENDS }, h)
		local v = make("Frame", {
			Size = UDim2.new(0, 1, 1, 0), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4,
		}, c)
		make("UIGradient", { Transparency = FADE_ENDS, Rotation = 90 }, v)
		local core = make("Frame", {
			Size = UDim2.fromOffset(4, 4), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5,
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

	local shooters = {}
	local nextShooter = 0.25
	local function spawnShooter()
		local W = sky.AbsoluteSize.X
		local H = sky.AbsoluteSize.Y
		if W < 50 or H < 30 then return end
		local len = rng:NextNumber(55, 110)
		local ang = rng:NextNumber(0, math.pi * 2)
		local dx, dy = math.cos(ang), math.sin(ang)
		local rot = math.deg(math.atan2(dy, dx))
		local tail = make("Frame", {
			Size = UDim2.fromOffset(len, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			Rotation = rot, ZIndex = 4,
		}, layers[3])
		make("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.7, 0.3),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}, tail)
		local head = make("Frame", {
			Size = UDim2.fromOffset(3, 3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0, ZIndex = 4,
		}, layers[3])
		corner(head, UDim.new(1, 0))
		make("UIStroke", { Color = WHITE, Thickness = 4, Transparency = 0.6 }, head)
		shooters[#shooters + 1] = {
			tail = tail, head = head,
			x = rng:NextNumber(0.05, 0.95) * W,
			y = rng:NextNumber(0.05, 0.95) * H,
			dx = dx, dy = dy,
			speed = rng:NextNumber(280, 520),
			age = 0, life = rng:NextNumber(0.7, 1.3),
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
			s.f.TextTransparency = s.base + (1 - s.base) * 0.7 * tw
		end

		for _, sp in ipairs(sparkles) do
			sp.x += sp.vx * dt
			sp.y += sp.vy * dt
			if sp.x < -0.03 then sp.x = 1.03 elseif sp.x > 1.03 then sp.x = -0.03 end
			if sp.y > 1.03 then sp.y = -0.03 end
			sp.c.Position = UDim2.fromScale(sp.x, sp.y)
			local s = math.max(0, math.sin(elapsed * sp.tw + sp.phase))
			local p = s ^ 2
			local boost = 0.35 + 0.65 * p
			sp.c.Size = UDim2.fromOffset(14 + 20 * p, 14 + 20 * p)
			local tr = 1 - (0.55 + 0.45 * boost)
			sp.h.BackgroundTransparency = tr
			sp.v.BackgroundTransparency = tr
			sp.core.BackgroundTransparency = math.max(0, 0.35 * (1 - boost))
			sp.halo.BackgroundTransparency = 0.35 + 0.4 * (1 - p)
			sp.c.Rotation = math.deg(math.atan2(sp.vy, sp.vx)) + elapsed * 6
		end

		if elapsed >= nextShooter and #shooters < 5 then
			spawnShooter()
			nextShooter = elapsed + rng:NextNumber(0.35, 0.9)
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
			if s.y < -120 or s.y > H + 120 or s.x < -120 or s.x > W + 120 or s.age >= s.life then
				s.tail:Destroy(); s.head:Destroy()
				table.remove(shooters, i)
			end
		end
	end

	return sky, update
end

---------------------------------------------------------------------
-- STROKE TICKER
---------------------------------------------------------------------
local activeNotification, showNextNotification, removeNotification
StardustUI._notificationEffects = StardustUI._notificationEffects or {}
if not StardustUI._strokeRunning then
	StardustUI._strokeRunning = true
	StardustUI._strokes = {}
	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for _, entry in ipairs(StardustUI._strokes) do
			if entry.grad and entry.grad.Parent then
				entry.grad.Rotation = (t * 70 + entry.offset) % 360
			end
		end
		for i = #StardustUI._notificationEffects, 1, -1 do
			local effect = StardustUI._notificationEffects[i]
			if not effect.Frame.Parent then
				table.remove(StardustUI._notificationEffects, i)
			else
				effect.Update(dt)
			end
		end
		if activeNotification and activeNotification.Item then
			local item = activeNotification.Item
			if not item.Closed and item.Duration > 0 and not item.Hovered then
				item.Remaining = math.max(0, item.Remaining - dt)
				item.Progress.Size = UDim2.new(item.Remaining / item.Duration, 0, 0, 2)
				if item.Remaining <= 0 then
					removeNotification(item)
				end
			end
		end
	end)
end

---------------------------------------------------------------------
-- NOTIFICATIONS
---------------------------------------------------------------------
local notificationGui = playerGui:FindFirstChild("StardustNotifications")
if notificationGui then notificationGui:Destroy() end
notificationGui = make("ScreenGui", {
	Name = "StardustNotifications",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 2600,
}, playerGui)
local notificationRoot = make("Frame", {
	Name = "Stack",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 18),
	Size = UDim2.new(0, 320, 1, -36),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
}, notificationGui)
make("UIListLayout", {
	Padding = UDim.new(0, 9),
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
}, notificationRoot)

local notificationItems = {}
local notificationQueue = {}
local notificationOrder = 0
local notificationKinds = {
	info = { label = "INFO", color = THEME.TextDim },
	success = { label = "SUCCESS", color = Color3.fromRGB(190, 205, 190) },
	warning = { label = "WARNING", color = Color3.fromRGB(215, 200, 165) },
	error = { label = "ERROR", color = Color3.fromRGB(215, 170, 170) },
}

local function makeNotificationStarfield(parent)
	local sky, update = createNightSky(parent)
	sky.Name = "NotificationNightSky"
	sky.ZIndex = 1
	local effect = { Frame = sky, Update = update }
	table.insert(StardustUI._notificationEffects, effect)
	return effect
end

removeNotification = function(item)
	if item.Closed then return end
	item.Closed = true
	for i, active in ipairs(notificationItems) do
		if active == item then
			table.remove(notificationItems, i)
			break
		end
	end
	for i, effect in ipairs(StardustUI._notificationEffects) do
		if effect == item.Effect then
			table.remove(StardustUI._notificationEffects, i)
			break
		end
	end
	if item.Frame.Parent then item.Frame:Destroy() end
	if activeNotification and activeNotification.Item == item then
		activeNotification.Item = nil
		activeNotification = nil
		if showNextNotification then
			task.defer(showNextNotification)
		end
	end
end

local function createNotification(title, message, duration, kind, request)
	title = tostring(title or "Notification")
	message = tostring(message or "")
	duration = tonumber(duration) or 5
	kind = string.lower(tostring(kind or "info"))
	local style = notificationKinds[kind] or notificationKinds.info
	duration = math.max(0, duration)

	notificationOrder += 1
	local frame = make("Frame", {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 104),
		BackgroundColor3 = THEME.Bg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		LayoutOrder = notificationOrder,
	}, notificationRoot)
	corner(frame, THEME.Corner)
	local frameStroke = animatedStroke(frame, 1.6, 0.12)
	local effect = makeNotificationStarfield(frame)
	local content = make("Frame", {
		Name = "NotificationContent",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, frame)

	local header = make("Frame", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 15),
		BackgroundTransparency = 1,
		ZIndex = 11,
	}, content)
	local kindLabel = label({
		Size = UDim2.new(1, -28, 1, 0),
		Text = style.label,
		TextColor3 = THEME.TextMute,
		TextSize = 9,
		Font = THEME.FontBold,
		TextTransparency = 0,
		ZIndex = 12,
	}, header)
	local closeButton = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(22, 18),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "×",
		TextColor3 = THEME.TextMute,
		TextSize = 17,
		Font = THEME.Font,
		TextTransparency = 0,
		ZIndex = 12,
	}, header)

	local body = make("Frame", {
		Position = UDim2.fromOffset(12, 27),
		Size = UDim2.new(1, -24, 0, 54),
		BackgroundTransparency = 1,
		ZIndex = 11,
	}, content)
	local badgeSurface = make("Frame", {
		Name = "BadgeSurface",
		Size = UDim2.fromOffset(48, 38),
		Position = UDim2.fromOffset(0, 5),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, body)
	corner(badgeSurface, UDim.new(0, 6))
	local badgeGlow = label({
		Size = UDim2.fromOffset(48, 38),
		Position = UDim2.fromOffset(0, 5),
		Text = "✦",
		TextColor3 = WHITE,
		TextSize = 28,
		Font = Enum.Font.SourceSansBold,
		TextTransparency = 0.68,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextStrokeColor3 = WHITE,
		TextStrokeTransparency = 0.55,
		ZIndex = 12,
	}, body)
	local badge = label({
		Size = UDim2.fromOffset(48, 38),
		Position = UDim2.fromOffset(0, 5),
		Text = "✦",
		TextColor3 = WHITE,
		TextSize = 27,
		Font = Enum.Font.SourceSansBold,
		TextTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextStrokeColor3 = WHITE,
		TextStrokeTransparency = 0.45,
		ZIndex = 13,
	}, body)
	local badgeScale = make("UIScale", { Scale = 1 }, badge)
	TweenService:Create(badgeScale, TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Scale = 1.16,
	}):Play()
	TweenService:Create(badge, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Rotation = 12,
		TextStrokeTransparency = 0.12,
	}):Play()
	TweenService:Create(badgeGlow, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		TextTransparency = 0.32,
		TextSize = 34,
	}):Play()
	make("Frame", {
		Size = UDim2.new(0, 1, 0, 34),
		Position = UDim2.fromOffset(58, 7),
		BackgroundColor3 = THEME.Stroke,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, body)
	local titleLabel = label({
		Size = UDim2.new(1, -72, 0, 19),
		Position = UDim2.fromOffset(72, 3),
		Text = title,
		TextColor3 = THEME.Text,
		TextSize = 14,
		Font = THEME.FontBold,
		TextTransparency = 0,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
	}, body)
	local messageLabel = label({
		Size = UDim2.new(1, -72, 0, 27),
		Position = UDim2.fromOffset(72, 24),
		Text = message,
		TextColor3 = THEME.TextDim,
		TextSize = 12,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextTransparency = 0,
		ZIndex = 12,
	}, body)
	local progress = make("Frame", {
		Position = UDim2.new(0, 12, 1, -8),
		Size = UDim2.new(1, -24, 0, 2),
		BackgroundColor3 = THEME.TextDim,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, content)
	corner(progress, UDim.new(1, 0))

	local item = {
		Frame = frame,
		Title = titleLabel,
		Message = messageLabel,
		Kind = kindLabel,
		Close = closeButton,
		Badge = badge,
		Stroke = frameStroke,
		Effect = effect,
		Progress = progress,
		Duration = duration,
		Remaining = duration,
		Hovered = false,
		Closed = false,
	}
	request.Item = item
	request.Handle.Frame = frame
	table.insert(notificationItems, item)
	frame.MouseEnter:Connect(function()
		item.Hovered = true
	end)
	frame.MouseLeave:Connect(function()
		item.Hovered = false
	end)
	closeButton.Activated:Connect(function()
		removeNotification(item)
	end)

	if duration > 0 then
		progress.Size = UDim2.new(1, 0, 0, 2)
	end
end

showNextNotification = function()
	if activeNotification then return end
	while #notificationQueue > 0 do
		local request = table.remove(notificationQueue, 1)
		if not request.Cancelled then
			activeNotification = request
			createNotification(request.Title, request.Message, request.Duration, request.Kind, request)
			return
		end
	end
end

function StardustUI.Notify(title, message, duration, kind)
	local request = {
		Title = tostring(title or "Notification"),
		Message = tostring(message or ""),
		Duration = math.max(0, tonumber(duration) or 5),
		Kind = string.lower(tostring(kind or "info")),
		Cancelled = false,
	}
	request.Handle = {
		Dismiss = function()
			if request.Cancelled then return end
			request.Cancelled = true
			if request.Item then
				removeNotification(request.Item)
			end
		end,
	}
	table.insert(notificationQueue, request)
	showNextNotification()
	return request.Handle
end

function StardustUI.DismissAll()
	table.clear(notificationQueue)
	if activeNotification and activeNotification.Item then
		removeNotification(activeNotification.Item)
	else
		activeNotification = nil
	end
end

---------------------------------------------------------------------
-- WINDOW
---------------------------------------------------------------------
local Window = {}
Window.__index = Window
local buildHomeView

function StardustUI.new(opts)
	opts = opts or {}
	local previousCleanup = _G[windowCleanupKey]
	if type(previousCleanup) == "function" then
		previousCleanup()
	end
	local previousGui = playerGui:FindFirstChild("StardustUI")
	if previousGui then
		previousGui:Destroy()
	end

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
	self._resetters = {}
	self._configElements = {}

	-- Config
	self.ConfigName   = opts.ConfigName or self.Title:gsub("%s+", "")
	self.ConfigFolder = opts.ConfigFolder or "StardustConfigs"
	self.AutoLoad     = opts.AutoLoad ~= false   -- default true
	self.AutoSave     = opts.AutoSave ~= false   -- default true

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

	buildHomeView(self)
	local homeCard = self.HomeCard

	local sessionStartedAt = os.clock()
	local lastSessionSecond = -1
	table.insert(self.Updaters, function()
		if self.Destroyed then
			return
		end
		local elapsed = math.floor(os.clock() - sessionStartedAt)
		if elapsed == lastSessionSecond then
			return
		end
		lastSessionSecond = elapsed
		local hours = math.floor(elapsed / 3600)
		local minutes = math.floor((elapsed % 3600) / 60)
		local seconds = elapsed % 60
		local duration = hours > 0
			and string.format("%d:%02d:%02d", hours, minutes, seconds)
			or string.format("%d:%02d", minutes, seconds)
		homeCard:SetField("Session", duration)
	end)

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
	local cleanup = function()
		self:Destroy()
		if self.Gui and self.Gui.Parent then
			self.Gui:Destroy()
		end
	end
	self._cleanupCallback = cleanup
	_G[windowCleanupKey] = cleanup

	-- Auto-load after elements have a chance to register
	if self.AutoLoad then
		task.defer(function()
			task.wait(0.2)
			self:LoadConfig()
		end)
	end

	return self
end

function Window:_getConfigPath()
	return self.ConfigFolder .. "/" .. self.ConfigName .. ".json"
end

function Window:SaveConfig()
	local data = {}
	for key, entry in pairs(self._configElements) do
		local ok, value = pcall(entry.Get)
		if ok then
			data[key] = serialize(value)
		end
	end

	local encoded = HttpService:JSONEncode(data)
	local path = self:_getConfigPath()

	if makefolder and not (isfolder and isfolder(self.ConfigFolder)) then
		pcall(makefolder, self.ConfigFolder)
	end

	if safeWrite(path, encoded) then
		return true, path
	end
	return false, "writefile not available"
end

function Window:LoadConfig()
	local path = self:_getConfigPath()
	local content = safeRead(path)
	if not content then
		return false, "no config file"
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if not ok or type(data) ~= "table" then
		return false, "invalid config"
	end

	for key, raw in pairs(data) do
		local entry = self._configElements[key]
		if entry then
			local value = deserialize(raw)
			pcall(entry.Set, value)
		end
	end
	return true
end

function Window:DeleteConfig()
	local path = self:_getConfigPath()
	if delfile and isfile and isfile(path) then
		pcall(delfile, path)
		return true
	end
	return false
end

function Window:GetConfigPath()
	return self:_getConfigPath()
end

function Window:Notify(title, message, duration, kind)
	return StardustUI.Notify(title, message, duration, kind)
end

function Window:DismissAll()
	return StardustUI.DismissAll()
end

function Window:_register(key, getFn, setFn)
	if key and key ~= "" then
		self._configElements[key] = { Get = getFn, Set = setFn }
	end
end

function Window:_build()
	local win = make("Frame", {
		Name = "Window_" .. self.Title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(THEME.WinW, THEME.WinH),
		BackgroundColor3 = THEME.Bg,
		BackgroundTransparency = THEME.TrWindow,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		ZIndex = 10,
	}, self.Gui)
	corner(win)
	self.WindowStroke, self.WindowGrad = animatedStroke(win, 2, 0.1)
	self.Frame = win

	local clipFrame = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 11,
	}, win)
	corner(clipFrame)

	local sky, skyUpdate = createNightSky(clipFrame)
	self.Sky = sky
	table.insert(self.Updaters, skyUpdate)

	local veil = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = THEME.Bg,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, clipFrame)
	corner(veil)

	-- TOP BAR
	local top = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = THEME.TrPanel,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 13,
	}, clipFrame)
	corner(top)
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = THEME.TrPanel,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, top)
	local topLine = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0, ZIndex = 14,
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
		Font = THEME.FontBold, TextSize = 15, ZIndex = 14,
	}, top)
	label({
		Size = UDim2.new(1, -110, 0, 14),
		Position = UDim2.fromOffset(16, 24),
		Text = self.Subtitle,
		TextSize = 11, TextColor3 = THEME.TextDim, ZIndex = 14,
	}, top)
	self.Top = top

	local closeBtn = make("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -36, 0, 9),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = 0.4,
		Text = "×",
		TextColor3 = WHITE,
		Font = THEME.FontBold, TextSize = 18,
		BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 15,
	}, top)
	corner(closeBtn, UDim.new(0, 6))
	animatedStroke(closeBtn, 1.4, 0.2)
	applyHoverEffect(closeBtn, nil, THEME.Element, WHITE, 0.4, 0)
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, { TextColor3 = BLACK }) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, { TextColor3 = WHITE }) end)
	closeBtn.MouseButton1Click:Connect(function() self:_showQuitConfirm() end)

	local homeBtn = make("TextButton", {
		Name = "HomeButton",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -68, 0, 9),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = 0.4,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ZIndex = 15,
	}, top)
	corner(homeBtn, UDim.new(0, 6))
	animatedStroke(homeBtn, 1.2, 0.35)
	applyHoverEffect(homeBtn, nil, THEME.Element, WHITE, 0.4, 0)
	local homeIcon = make("Frame", {
		Size = UDim2.fromOffset(13, 13),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 16,
	}, homeBtn)
	corner(homeIcon, UDim.new(0, 2))
	stroke(homeIcon, WHITE, 1.2, 0.05)
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, 3),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 17,
	}, homeIcon)
	homeBtn.Activated:Connect(function() self:ShowHome() end)

	-- TAB SIDEBAR
	local tabListBg = make("Frame", {
		Name = "TabListBg",
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.fromOffset(THEME.TabW, THEME.WinH - 46),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = THEME.TrPanel,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, clipFrame)
	corner(tabListBg)
	make("Frame", {
		Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -14, 0, 0),
		BackgroundColor3 = THEME.Panel, BackgroundTransparency = THEME.TrPanel,
		BorderSizePixel = 0, ZIndex = 13,
	}, tabListBg)
	make("Frame", {
		Size = UDim2.new(0, 1, 1, -80),
		Position = UDim2.new(1, -1, 0, 8),
		BackgroundColor3 = WHITE, BackgroundTransparency = 0.7,
		BorderSizePixel = 0, ZIndex = 13,
	}, tabListBg)

	local tabScroll = make("ScrollingFrame", {
		Name = "TabScroll",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 1, -76),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = WHITE,
		ScrollBarImageTransparency = 0.6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 14,
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

	-- USER PROFILE
	local userProfile = make("Frame", {
		Size = UDim2.new(1, 0, 0, 76),
		Position = UDim2.new(0, 0, 1, -76),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = THEME.TrPanel,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, tabListBg)
	corner(userProfile)
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = THEME.TrPanel,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, userProfile)
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = 14,
	}, userProfile)

	local avatar = make("ImageLabel", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.fromOffset(10, 10),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48",
		ZIndex = 15,
	}, userProfile)
	corner(avatar, UDim.new(1, 0))
	stroke(avatar, WHITE, 1, 0.5)

	local nameLbl = label({
		Size = UDim2.new(1, -50, 0, 14),
		Position = UDim2.fromOffset(46, 10),
		Text = player.Name,
		Font = THEME.FontBold,
		TextSize = 13,
		TextScaled = true,
		TextWrapped = false,
		ZIndex = 15,
	}, userProfile)
	make("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 7 }, nameLbl)

	local usernameUnderline = make("Frame", {
		Size = UDim2.fromOffset(1, 1),
		Position = UDim2.new(0, 46, 0, 25),
		BackgroundColor3 = THEME.TextDim,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, userProfile)
	local function updateUsernameUnderline()
		usernameUnderline.Size = UDim2.fromOffset(
			math.max(1, math.min(nameLbl.TextBounds.X, nameLbl.AbsoluteSize.X)),
			1
		)
	end
	table.insert(self.Connections, nameLbl:GetPropertyChangedSignal("TextBounds"):Connect(updateUsernameUnderline))
	table.insert(self.Connections, nameLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateUsernameUnderline))
	task.defer(updateUsernameUnderline)

	local execName = getExecutorName()

	local statsLbl = label({
		Size = UDim2.new(1, -20, 0, 30),
		Position = UDim2.fromOffset(10, 40),
		Text = "",
		TextSize = 11, TextColor3 = THEME.TextDim,
		TextWrapped = true,
		ZIndex = 15,
	}, userProfile)

	local lastPing = 0
	task.spawn(function()
		while not self.Destroyed do
			local time = os.date("%I:%M%p"):gsub("^0", ""):lower()
			local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 0.001))
			if math.random() < 0.2 then
				local pingVal = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
				if pingVal then lastPing = math.floor(pingVal) end
			end
			statsLbl.Text = string.format("%s | %s\nfps: %d | ping: %dms", time, execName, fps, lastPing)
			task.wait(0.5)
		end
	end)

	-- CONTENT
	local content = make("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(THEME.TabW + 1, 46),
		Size = UDim2.new(1, -(THEME.TabW + 1), 1, -46),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 13,
	}, clipFrame)
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
end

function Window:_showQuitConfirm()
	if self._confirmOpen then return end
	self._confirmOpen = true

	local overlayFrame = make("Frame", {
		Name = "QuitConfirm",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		ZIndex = 200,
	}, self.Gui)
	self._confirmFrame = overlayFrame

	local dlg = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 220),
		BackgroundColor3 = THEME.Bg,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = 201,
	}, overlayFrame)
	corner(dlg, UDim.new(0, 12))
	animatedStroke(dlg, 2.5, 0.1)

	local dlgClip = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 202,
	}, dlg)
	corner(dlgClip, UDim.new(0, 12))

	local dlgSky, dlgSkyUpdate = createNightSky(dlgClip)
	table.insert(self.Updaters, dlgSkyUpdate)

	local dlgVeil = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = THEME.Bg,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 203,
	}, dlgClip)
	corner(dlgVeil, UDim.new(0, 12))

	label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 24),
		Size = UDim2.new(1, 0, 0, 24),
		Text = "⚠",
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = WHITE,
		ZIndex = 204,
	}, dlgClip)
	label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 60),
		Size = UDim2.new(1, -40, 0, 22),
		Text = "Quit StardustUI?",
		Font = THEME.FontBold, TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 204,
	}, dlgClip)
	label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 88),
		Size = UDim2.new(1, -60, 0, 44),
		Text = "This will turn off every toggle and close the menu. Continue?",
		TextSize = 12, TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		ZIndex = 204,
	}, dlgClip)

	local btnRow = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, -64),
		Size = UDim2.fromOffset(330, 42),
		BackgroundTransparency = 1,
		ZIndex = 204,
	}, dlgClip)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, btnRow)

	local function styledConfirmBtn(text, order, isPrimary)
		local b = make("TextButton", {
			Size = UDim2.fromOffset(150, 38),
			BackgroundColor3 = isPrimary and WHITE or THEME.Element,
			BackgroundTransparency = isPrimary and 0 or 0.25,
			Text = text,
			TextColor3 = isPrimary and BLACK or WHITE,
			Font = THEME.FontBold, TextSize = 13,
			BorderSizePixel = 0, AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 205,
		}, btnRow)
		corner(b, UDim.new(0, 8))
		animatedStroke(b, 1.6, isPrimary and 0.35 or 0.5)
		b.MouseEnter:Connect(function()
			if isPrimary then
				tween(b, { BackgroundColor3 = Color3.fromRGB(235, 235, 235) })
			else
				tween(b, { BackgroundColor3 = WHITE, BackgroundTransparency = 0, TextColor3 = BLACK })
			end
		end)
		b.MouseLeave:Connect(function()
			if isPrimary then
				tween(b, { BackgroundColor3 = WHITE })
			else
				tween(b, { BackgroundColor3 = THEME.Element, BackgroundTransparency = 0.25, TextColor3 = WHITE })
			end
		end)
		return b
	end

	local cancelBtn = styledConfirmBtn("Cancel", 1, false)
	local confirmBtn = styledConfirmBtn("Confirm", 2, true)

	local function closeDialog()
		if not self._confirmOpen then return end
		self._confirmOpen = false
		local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(overlayFrame, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(dlg, info, { Size = UDim2.fromOffset(360, 190), BackgroundTransparency = 1 }):Play()
		task.delay(0.22, function()
			if overlayFrame.Parent then overlayFrame:Destroy() end
			local idx = table.find(self.Updaters, dlgSkyUpdate)
			if idx then table.remove(self.Updaters, idx) end
		end)
		self._confirmFrame = nil
	end

	cancelBtn.MouseButton1Click:Connect(closeDialog)
	confirmBtn.MouseButton1Click:Connect(function()
		closeDialog()
		self:_resetToggles()
		task.delay(0.15, function()
			self:Destroy()
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

	overlayFrame.BackgroundTransparency = 1
	dlg.BackgroundTransparency = 1
	TweenService:Create(overlayFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0.6 }):Play()
	TweenService:Create(dlg, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play()
end

function Window:Toggle(v)
	if self.Destroyed then return end
	local targetVisible = v ~= nil and v or not self.Visible
	self.Visible = targetVisible
	self.Frame.Visible = self.Visible
end

function Window:_resetToggles()
	for _, reset in ipairs(self._resetters) do
		local ok, err = pcall(reset)
		if not ok then
			warn("[StardustUI] Could not reset toggle:", err)
		end
	end
end

function Window:Destroy()
	if self.Destroyed then return end
	self:_resetToggles()
	self.Destroyed = true
	if _G[windowCleanupKey] == self._cleanupCallback then
		_G[windowCleanupKey] = nil
	end
	if StardustUI._windows then
		local index = table.find(StardustUI._windows, self)
		if index then
			table.remove(StardustUI._windows, index)
		end
	end
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

function Window:Tab(name, icon)
	local tab = setmetatable({}, Tab)
	tab.Name = name
	tab.Window = self
	tab.Sections = {}
	tab.Icon = icon

	local btn = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = 0.7,
		Text = "",
		BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 15,
	}, self.TabScroll)
	corner(btn, UDim.new(0, 6))
	tab.ButtonStroke, tab.ButtonGrad = animatedStroke(btn, 1.2, 0.85)
	if icon then
		local iconText = tostring(icon)
		local iconSlot = make("Frame", {
			Size = UDim2.fromOffset(28, 32),
			Position = UDim2.fromOffset(3, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 16,
		}, btn)
		if type(icon) == "number" or iconText:match("^rbxassetid://") then
			make("ImageLabel", {
				Size = UDim2.fromOffset(18, 18),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = type(icon) == "number" and ("rbxassetid://" .. iconText) or iconText,
				ImageColor3 = WHITE,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 17,
			}, iconSlot)
		else
			label({
				Size = UDim2.fromScale(1, 1),
				Text = iconText,
				TextColor3 = WHITE,
				Font = Enum.Font.SourceSansBold,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 17,
			}, iconSlot)
		end
		make("Frame", {
			Size = UDim2.new(0, 1, 0, 16),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 34, 0.5, 0),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
			ZIndex = 16,
		}, btn)
	end

	local txt = label({
		Size = UDim2.new(1, icon and -54 or -24, 0, 22),
		Position = UDim2.new(0, icon and 44 or 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = name,
		TextColor3 = THEME.TextDim,
		Font = THEME.FontBold,
		TextSize = 13,
		TextScaled = true,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = 16,
	}, btn)
	make("UITextSizeConstraint", {
		MinTextSize = 8,
		MaxTextSize = 13,
	}, txt)
	tab.Button = btn
	tab.ButtonText = txt

	local holder = make("Frame", {
		Name = "TabContent_" .. name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 14,
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
		ZIndex = 14,
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

	applyHoverEffect(btn, function() return self.CurrentTab == tab end, THEME.Element, Color3.fromRGB(85, 85, 98), 0.7, 0.5, tab.ButtonStroke, 0.85, 0.4)
	btn.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then tween(txt, { TextColor3 = WHITE }, THEME.AnimFast) end
	end)
	btn.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then tween(txt, { TextColor3 = THEME.TextDim }, THEME.AnimFast) end
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 and not self.HomeViewVisible then self:SelectTab(tab) end
	return tab
end

function Window:SelectTab(tab)
	if self.CurrentTab == tab and not self.HomeViewVisible then return end
	self.HomeViewVisible = false
	if self.HomeView then
		self.HomeView.Visible = false
	end
	if self.CurrentTab then
		self.CurrentTab.Holder.Visible = false
		tween(self.CurrentTab.Button, { BackgroundColor3 = THEME.Element, BackgroundTransparency = 0.7 })
		tween(self.CurrentTab.ButtonText, { TextColor3 = THEME.TextDim })
		tween(self.CurrentTab.ButtonStroke, { Transparency = 0.85 })
	end
	self.CurrentTab = tab
	tab.Holder.Visible = true
	tween(tab.Button, { BackgroundColor3 = Color3.fromRGB(100, 100, 115), BackgroundTransparency = 0.4 })
	tween(tab.ButtonText, { TextColor3 = WHITE })
	tween(tab.ButtonStroke, { Transparency = 0.15 })
end

function Window:ShowHome()
	if self.Destroyed or not self.HomeView then return end
	if self.CurrentTab then
		self.CurrentTab.Holder.Visible = false
		tween(self.CurrentTab.Button, { BackgroundColor3 = THEME.Element, BackgroundTransparency = 0.7 })
		tween(self.CurrentTab.ButtonText, { TextColor3 = THEME.TextDim })
		tween(self.CurrentTab.ButtonStroke, { Transparency = 0.85 })
		self.CurrentTab = nil
	end
	self.HomeViewVisible = true
	self.HomeView.Visible = true
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
		BackgroundTransparency = THEME.TrSection,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, self.Scroll)
	corner(frame, UDim.new(0, 8))
	sec.Stroke, sec.Grad = animatedStroke(frame, 1.5, 0.4)
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
		ZIndex = 15,
	}, frame)
	local headerLabel = label({
		Size = UDim2.new(1, -24, 1, 0),
		Text = name:upper(),
		Font = THEME.FontBold, TextSize = 11,
		TextColor3 = THEME.TextDim, ZIndex = 16,
	}, header)
	local collapseIndicator = label({
		Size = UDim2.fromOffset(18, 18),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Text = "−",
		TextColor3 = THEME.TextMute,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 17,
	}, header)
	local collapseButton = make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 18,
	}, header)

	sec.Collapsed = false
	function sec:SetCollapsed(collapsed)
		self.Collapsed = collapsed == true
		for _, child in ipairs(frame:GetChildren()) do
			if child:IsA("GuiObject") and child ~= header then
				child.Visible = not self.Collapsed
			end
		end
		collapseIndicator.Text = self.Collapsed and "+" or "−"
	end
	function sec:ToggleCollapse()
		self:SetCollapsed(not self.Collapsed)
	end
	collapseButton.Activated:Connect(function()
		sec:ToggleCollapse()
	end)

	sec.Frame = frame
	sec.Header = header
	sec.HeaderLabel = headerLabel
	sec.CollapseButton = collapseButton
	table.insert(self.Sections, sec)
	return sec
end

function Section:_nextOrder()
	self.Order += 1
	return self.Order
end

function Section:Card(title, avatarUrl, fields, action)
	fields = fields or {}
	local cardHeight = math.max(86, 24 + (#fields - 1) * 16 + 14 + 8)
	if action then
		cardHeight += 32
	end
	local card = make("Frame", {
		Size = UDim2.new(1, 0, 0, cardHeight),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = THEME.TrElement,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 15,
	}, self.Frame)
	corner(card, UDim.new(0, 6))
	local st = animatedStroke(card, 1.2, 0.55)
	make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, card)

	local img = make("ImageLabel", {
		Size = UDim2.fromOffset(54, 54),
		Position = UDim2.fromOffset(0, 6),
		BackgroundColor3 = THEME.Section,
		BorderSizePixel = 0,
		Image = avatarUrl,
		ZIndex = 16,
	}, card)
	corner(img, UDim.new(0, 6))
	stroke(img, WHITE, 1, 0.5)

	local header = label({
		Size = UDim2.new(1, -70, 0, 16),
		Position = UDim2.fromOffset(64, 4),
		Text = title,
		Font = THEME.FontBold, TextSize = 14,
		TextScaled = true,
		ZIndex = 16,
	}, card)
	make("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 10 }, header)

	local yOffset = 24
	local fieldLabels = {}
	for _, field in ipairs(fields) do
		local row = make("Frame", {
			Size = UDim2.new(1, -70, 0, 14),
			Position = UDim2.fromOffset(64, yOffset),
			BackgroundTransparency = 1,
			ZIndex = 16,
		}, card)

		label({
			Size = UDim2.new(0.35, 0, 1, 0),
			Text = field[1] .. ":",
			TextSize = 11, TextColor3 = THEME.TextDim,
			ZIndex = 16,
		}, row)

		local valueLabel = label({
			Size = UDim2.new(0.65, 0, 1, 0),
			Position = UDim2.new(0.35, 0, 0, 0),
			Text = tostring(field[2]),
			TextSize = 11, TextColor3 = WHITE,
			Font = THEME.FontBold,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 16,
		}, row)
		make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 11 }, valueLabel)
		fieldLabels[tostring(field[1])] = valueLabel

		yOffset += 16
	end

	if action then
		local actionButton = make("TextButton", {
			Size = UDim2.new(1, -70, 0, 26),
			Position = UDim2.fromOffset(64, yOffset + 2),
			BackgroundColor3 = THEME.Section,
			BackgroundTransparency = 0.15,
			Text = action.Text,
			TextColor3 = WHITE,
			Font = THEME.FontBold,
			TextSize = 11,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			ZIndex = 16,
		}, card)
		corner(actionButton, UDim.new(0, 5))
		stroke(actionButton, WHITE, 1, 0.7)
		applyHoverEffect(actionButton, nil, THEME.Section, Color3.fromRGB(100, 100, 115), 0.15, 0)
		actionButton.Activated:Connect(action.Callback)
	end

	applyHoverEffect(card, nil, THEME.Element, Color3.fromRGB(85, 85, 98), THEME.TrElement, 0.6, st, 0.55, 0.2)
	return {
		SetTitle = function(_, value)
			header.Text = tostring(value)
		end,
		SetField = function(_, fieldName, value)
			local valueLabel = fieldLabels[tostring(fieldName)]
			if not valueLabel then
				return false
			end
			valueLabel.Text = tostring(value)
			return true
		end,
		Destroy = function() card:Destroy() end,
	}
end

buildHomeView = function(window)
	local homeView = make("Frame", {
		Name = "WelcomeView",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = true,
		ZIndex = 14,
	}, window.Content)
	local scroll = make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = WHITE,
		ScrollBarImageTransparency = 0.5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 14,
	}, homeView)
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

	local sectionFrame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Section,
		BackgroundTransparency = THEME.TrSection,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		ZIndex = 15,
	}, scroll)
	corner(sectionFrame, UDim.new(0, 8))
	animatedStroke(sectionFrame, 1.5, 0.4)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, sectionFrame)
	make("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sectionFrame)
	local heading = label({
		Size = UDim2.new(1, 0, 0, 18),
		Text = "WELCOME",
		Font = THEME.FontBold,
		TextSize = 11,
		TextColor3 = THEME.TextDim,
		LayoutOrder = 0,
		ZIndex = 16,
	}, sectionFrame)

	local serverType = "Public"
	if game.PrivateServerId ~= "" then
		serverType = game.PrivateServerOwnerId == 0 and "Reserved" or "Private"
	end
	local homeSection = setmetatable({ Frame = sectionFrame, Order = 0 }, Section)
	local homeCard = homeSection:Card(
		"Welcome, " .. player.Name,
		"rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150",
		{
			{ "Account age", string.format("%d days", player.AccountAge) },
			{ "Executor", getExecutorName() },
			{ "Open/close", window.Keybind.Name },
			{ "Session", "0:00" },
		},
		{
			Text = "Copy server join code",
			Callback = function()
				if game.JobId == "" then
					window:Notify("Copy unavailable", "This session does not have a server JobId.", 5, "warning")
					return
				end
				local copyFunction = setclipboard
				if type(copyFunction) ~= "function" then
					window:Notify("Clipboard unavailable", "Your environment does not provide setclipboard.", 5, "warning")
					return
				end
				local code = string.format(
					'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game.Players.LocalPlayer)',
					game.PlaceId,
					game.JobId
				)
				local ok, err = pcall(copyFunction, code)
				if not ok then
					window:Notify("Copy failed", tostring(err), 5, "error")
					return
				end
				window:Notify("Server join code copied", "The code is ready to paste.", 4, "success")
			end,
		}
	)
	local gameCard = homeSection:Card(
		game.Name,
		"rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150",
		{
			{ "Creator", "Loading..." },
			{ "Players here", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers) },
			{ "Place ID", tostring(game.PlaceId) },
			{ "Universe ID", tostring(game.GameId) },
			{ "Server ID", game.JobId ~= "" and game.JobId or "Unavailable" },
			{ "Server type", serverType },
		}
	)
	window.HomeView = homeView
	window.HomeViewVisible = true
	window.HomeCard = homeCard
	window.GameCard = gameCard

	local function updateActivePlayers()
		if not window.Destroyed then
			gameCard:SetField("Players here", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers))
		end
	end
	table.insert(window.Connections, Players.PlayerAdded:Connect(updateActivePlayers))
	table.insert(window.Connections, Players.PlayerRemoving:Connect(function()
		task.defer(updateActivePlayers)
	end))

	task.spawn(function()
		local ok, productInfo = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		end)
		if ok and productInfo then
			if not window.Destroyed then
				if type(productInfo.Name) == "string" and productInfo.Name ~= "" then
					gameCard:SetTitle(productInfo.Name)
				end
				if type(productInfo.Creator) == "table" and type(productInfo.Creator.Name) == "string" then
					gameCard:SetField("Creator", productInfo.Creator.Name)
				else
					gameCard:SetField("Creator", "Unavailable")
				end
			end
		elseif not ok then
			warn("[StardustUI] Could not get the experience name:", productInfo)
			gameCard:SetField("Creator", "Unavailable")
		end
	end)
end

---------------------------------------------------------------------
-- ELEMENTS (ConfigKey support added)
---------------------------------------------------------------------
function Section:Button(text, infoOrCallback, callback)
	local info
	if type(infoOrCallback) == "string" then
		info = infoOrCallback
	else
		callback = infoOrCallback
	end

	local btn = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = THEME.TrElement,
		Text = "",
		BorderSizePixel = 0, AutoButtonColor = false,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 15,
	}, self.Frame)
	corner(btn, UDim.new(0, 6))
	local st = animatedStroke(btn, 1.2, 0.55)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, btn)

	local txt = label({
		Size = UDim2.new(1, 0, 1, 0),
		Text = text, TextColor3 = WHITE,
		Font = THEME.FontBold, TextSize = 13, ZIndex = 16,
	}, btn)
	addInfoTooltip(self.Tab.Window, btn, info)

	applyHoverEffect(btn, nil, THEME.Element, Color3.fromRGB(85, 85, 98), THEME.TrElement, 0.6, st, 0.55, 0.2)
	btn.MouseEnter:Connect(function() tween(txt, { TextColor3 = WHITE }) end)

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

function Section:Toggle(text, infoOrDefault, defaultOrCallback, callbackOrConfigKey, configKey)
	local info, default, callback
	if type(infoOrDefault) == "string" then
		info = infoOrDefault
		default = defaultOrCallback
		callback = callbackOrConfigKey
	else
		default = infoOrDefault
		callback = defaultOrCallback
		configKey = callbackOrConfigKey
	end
	default = default == true
	local state = default

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = THEME.TrElement,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 15,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	local st = animatedStroke(holder, 1.2, 0.55)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)

	label({ Size = UDim2.new(1, -50, 1, 0), Text = text, TextSize = 13, ZIndex = 16 }, holder)

	local btn = make("TextButton", {
		Size = UDim2.fromOffset(36, 18),
		Position = UDim2.new(1, -36, 0.5, -9),
		BackgroundColor3 = state and WHITE or THEME.Section,
		BackgroundTransparency = state and 0 or 0.3,
		Text = "", BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 16,
	}, holder)
	corner(btn, UDim.new(1, 0))
	stroke(btn, WHITE, 1, 0.5)

	local knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = state and UDim2.new(1, -15, 0.5, -7) or UDim2.fromOffset(2, 2),
		BackgroundColor3 = state and BLACK or WHITE,
		BorderSizePixel = 0, ZIndex = 17,
	}, btn)
	corner(knob, UDim.new(1, 0))
	addInfoTooltip(self.Tab.Window, holder, info)

	applyHoverEffect(holder, nil, THEME.Element, Color3.fromRGB(85, 85, 98), THEME.TrElement, 0.6, st, 0.55, 0.2)

	local function apply(v, fire)
		state = v
		tween(btn, { BackgroundColor3 = state and WHITE or THEME.Section, BackgroundTransparency = state and 0 or 0.3 })
		tween(knob, {
			Position = state and UDim2.new(1, -15, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
			BackgroundColor3 = state and BLACK or WHITE,
		})
		if fire and callback then
			local ok, err = pcall(callback, state)
			if not ok then warn("[StardustUI]", err) end
		end
		if fire and self.Tab.Window.AutoSave then
			self.Tab.Window:SaveConfig()
		end
	end

	btn.MouseButton1Click:Connect(function() apply(not state, true) end)

	table.insert(self.Tab.Window._resetters, function()
		if state then apply(false, true) end
	end)

	self.Tab.Window:_register(configKey, function() return state end, function(v) apply(v == true, false) end)

	return {
		Set = function(_, v) apply(v, false) end,
		Get = function() return state end,
		Destroy = function() holder:Destroy() end,
	}
end

function Section:Slider(text, min, max, default, callback, configKey)
	min, max = min or 0, max or 100
	default = math.clamp(default or min, min, max)
	local value = default

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = THEME.TrElement,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 15,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	local st = animatedStroke(holder, 1.2, 0.55)
	make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, holder)

	label({ Size = UDim2.new(1, -60, 0, 16), Text = text, TextSize = 13, ZIndex = 16 }, holder)
	local valLabel = label({
		Size = UDim2.new(0, 60, 0, 16),
		Position = UDim2.new(1, -60, 0, 0),
		Text = tostring(value), TextSize = 12, TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right, Font = THEME.FontBold, ZIndex = 16,
	}, holder)

	local track = make("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = THEME.Section,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0, ZIndex = 16,
	}, holder)
	corner(track, UDim.new(1, 0))

	local fill = make("Frame", {
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 16,
	}, track)
	corner(fill, UDim.new(1, 0))

	local knob = make("Frame", {
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 17,
	}, track)
	corner(knob, UDim.new(1, 0))
	stroke(knob, WHITE, 2, 0.6)

	applyHoverEffect(holder, nil, THEME.Element, Color3.fromRGB(85, 85, 98), THEME.TrElement, 0.6, st, 0.55, 0.2)

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
		if self.Tab.Window.AutoSave then
			self.Tab.Window:SaveConfig()
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

	self.Tab.Window:_register(configKey, function() return value end, function(v)
		v = math.clamp(tonumber(v) or min, min, max)
		local pct = (v - min) / (max - min)
		value = v
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		valLabel.Text = tostring(value)
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

function Section:Textbox(text, default, callback, configKey)
	default = default or ""
	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = THEME.TrElement,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 15,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	local st = animatedStroke(holder, 1.2, 0.55)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)

	label({ Size = UDim2.new(0.5, 0, 1, 0), Text = text, TextSize = 13, ZIndex = 16 }, holder)

	local box = make("TextBox", {
		Size = UDim2.new(0.5, -8, 0, 22),
		Position = UDim2.new(0.5, 4, 0.5, -11),
		BackgroundColor3 = THEME.Section,
		BackgroundTransparency = 0.2,
		Text = default, PlaceholderText = "type...",
		TextColor3 = WHITE, PlaceholderColor3 = THEME.TextMute,
		Font = THEME.Font, TextSize = 12,
		BorderSizePixel = 0, ClearTextOnFocus = false,
		ZIndex = 16,
	}, holder)
	corner(box, UDim.new(0, 5))
	stroke(box, WHITE, 1, 0.7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)

	applyHoverEffect(holder, nil, THEME.Element, Color3.fromRGB(85, 85, 98), THEME.TrElement, 0.6, st, 0.55, 0.2)

	box.Focused:Connect(function() tween(box, { BackgroundColor3 = WHITE, BackgroundTransparency = 0, TextColor3 = BLACK }) end)
	box.FocusLost:Connect(function(enter)
		tween(box, { BackgroundColor3 = THEME.Section, BackgroundTransparency = 0.2, TextColor3 = WHITE })
		if callback then pcall(callback, box.Text, enter) end
		if self.Tab.Window.AutoSave then
			self.Tab.Window:SaveConfig()
		end
	end)

	self.Tab.Window:_register(configKey, function() return box.Text end, function(v) box.Text = tostring(v or "") end)

	return {
		Set = function(_, t) box.Text = t end,
		Get = function() return box.Text end,
		Destroy = function() holder:Destroy() end,
	}
end

function Section:MultiDropdown(text, infoOrOptions, optionsOrDefault, defaultOrCallback, callbackOrConfigKey, configKey)
	local info, options, default, callback
	if type(infoOrOptions) == "string" then
		info = infoOrOptions
		options = optionsOrDefault
		default = defaultOrCallback
		callback = callbackOrConfigKey
	else
		options = infoOrOptions
		default = optionsOrDefault
		callback = defaultOrCallback
		configKey = callbackOrConfigKey
	end
	options = options or {}
	local selected = {}
	local open = false
	local rows = {}
	local keyConn

	local function applyValues(values)
		selected = {}
		if values == nil then
			for _, option in ipairs(options) do
				selected[tostring(option)] = true
			end
		else
			for _, value in ipairs(values) do
				selected[tostring(value)] = true
			end
		end
	end
	applyValues(default)

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = THEME.TrElement,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 15,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, self.Frame)
	corner(container, UDim.new(0, 6))
	local outline = animatedStroke(container, 1.2, 0.55)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, container)

	local header = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
		LayoutOrder = 1,
		ZIndex = 16,
	}, container)
	addInfoTooltip(self.Tab.Window, header, info)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, header)
	label({
		Size = UDim2.new(0.52, 0, 1, 0),
		Text = text,
		TextSize = 13,
		ZIndex = 17,
	}, header)

	local summary = label({
		Size = UDim2.new(0.48, -20, 1, 0),
		Position = UDim2.new(0.52, 0, 0, 0),
		Text = "",
		TextSize = 11,
		TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 17,
	}, header)
	label({
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Text = "+",
		TextSize = 16,
		TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 17,
	}, header)

	local listFrame = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		LayoutOrder = 2,
		ZIndex = 16,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = THEME.TextMute,
	}, container)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 6),
	}, listFrame)
	make("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, listFrame)

	local selectAllButton = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = THEME.Section,
		BackgroundTransparency = 0.25,
		TextColor3 = WHITE,
		Font = THEME.FontBold,
		TextSize = 11,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		LayoutOrder = 0,
		ZIndex = 17,
	}, listFrame)
	corner(selectAllButton, UDim.new(0, 4))

	local function getValues()
		local values = {}
		for _, option in ipairs(options) do
			if selected[tostring(option)] then
				values[#values + 1] = option
			end
		end
		return values
	end

	local function updateRows()
		local count = 0
		for _, option in ipairs(options) do
			if selected[tostring(option)] then
				count += 1
			end
		end
		local allSelected = #options > 0 and count == #options
		summary.Text = allSelected and "All selected" or (count == 0 and "None" or tostring(count) .. " selected")
		selectAllButton.Text = allSelected and "Deselect all" or "Select all"
		for _, row in ipairs(rows) do
			local isSelected = selected[row.Value] == true
			row.Button.Text = (isSelected and "[x]  " or "[ ]  ") .. row.Value
			row.Button.TextColor3 = isSelected and WHITE or THEME.TextDim
		end
	end

	local function notifyChanged()
		local values = getValues()
		if callback then
			local ok, err = pcall(callback, values)
			if not ok then warn("[StardustUI]", err) end
		end
		if self.Tab.Window.AutoSave then
			self.Tab.Window:SaveConfig()
		end
	end

	local function rebuild()
		for _, row in ipairs(rows) do
			row.Button:Destroy()
		end
		rows = {}
		for _, option in ipairs(options) do
			local value = tostring(option)
			local button = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = THEME.Section,
				BackgroundTransparency = 0.5,
				TextColor3 = WHITE,
				Font = THEME.Font,
				TextSize = 12,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = #rows + 1,
				ZIndex = 17,
			}, listFrame)
			corner(button, UDim.new(0, 4))
			make("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}, button)
			local row = { Value = value, Button = button }
			rows[#rows + 1] = row
			button.Activated:Connect(function()
				selected[value] = not selected[value] or nil
				updateRows()
				notifyChanged()
			end)
		end
		local visibleRows = math.min(#rows, 5)
		listFrame.Size = UDim2.new(1, 0, 0, 34 + visibleRows * 28)
		updateRows()
	end
	rebuild()

	local function close()
		if not open then return end
		open = false
		listFrame.Visible = false
		if keyConn then
			keyConn:Disconnect()
			keyConn = nil
		end
		if StardustUI._closeActiveDropdown == close then
			StardustUI._closeActiveDropdown = nil
		end
	end

	local function openDropdown()
		if open then return end
		if StardustUI._closeActiveDropdown then
			StardustUI._closeActiveDropdown()
		end
		open = true
		listFrame.Visible = true
		StardustUI._closeActiveDropdown = close
		keyConn = UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.Escape then
				close()
			end
		end)
	end

	selectAllButton.Activated:Connect(function()
		local allSelected = #options > 0
		for _, option in ipairs(options) do
			if not selected[tostring(option)] then
				allSelected = false
				break
			end
		end
		applyValues(allSelected and {} or nil)
		updateRows()
		notifyChanged()
	end)
	header.Activated:Connect(function()
		if open then close() else openDropdown() end
	end)
	container.MouseEnter:Connect(function()
		if not open then
			tween(outline, { Transparency = 0.2 }, THEME.AnimFast)
		end
	end)
	container.MouseLeave:Connect(function()
		if not open then
			tween(outline, { Transparency = 0.55 }, THEME.AnimFast)
		end
	end)

	self.Tab.Window:_register(configKey, getValues, function(values)
		applyValues(type(values) == "table" and values or {})
		updateRows()
	end)

	return {
		Get = getValues,
		Set = function(_, values)
			applyValues(type(values) == "table" and values or {})
			updateRows()
			notifyChanged()
		end,
		SetOptions = function(_, newOptions)
			options = newOptions or {}
			applyValues(nil)
			rebuild()
		end,
		Destroy = function()
			if open then close() end
			container:Destroy()
		end,
	}
end

function Section:Dropdown(text, infoOrOptions, optionsOrDefault, defaultOrCallback, callbackOrConfigKey, configKey)
	local info, options, default, callback
	if type(infoOrOptions) == "string" then
		info = infoOrOptions
		options = optionsOrDefault
		default = defaultOrCallback
		callback = callbackOrConfigKey
	else
		options = infoOrOptions
		default = optionsOrDefault
		callback = defaultOrCallback
		configKey = callbackOrConfigKey
	end
	options = options or {}
	default = default or (options[1] or "")
	local value = default
	local open = false
	local selectedIdx = 1
	local filterText = ""
	local items = {}
	local searchBox = nil
	local keyConn = nil
	local useSearch = #options >= 8

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = THEME.TrElement,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 15,
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = false,
	}, self.Frame)
	corner(container, UDim.new(0, 6))
	local st = animatedStroke(container, 1.2, 0.55)

	make("UIListLayout", {
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, container)

	local header = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
		LayoutOrder = 1,
		ZIndex = 16,
	}, container)
	addInfoTooltip(self.Tab.Window, header, info)

	make("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, header)

	label({
		Size = UDim2.new(0.55, 0, 1, 0),
		Text = text,
		TextSize = 13,
		ZIndex = 17,
	}, header)

	local current = label({
		Size = UDim2.new(0.45, -20, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		Text = tostring(value),
		TextSize = 12,
		TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 17,
	}, header)

	local indicator = label({
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Text = "+",
		TextSize = 16,
		TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 17,
	}, header)

	local listFrame = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		LayoutOrder = 2,
		ZIndex = 16,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = THEME.TextMute,
	}, container)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 6),
	}, listFrame)
	make("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, listFrame)

	local baseCol, hoverCol = THEME.Element, Color3.fromRGB(85, 85, 98)
	local baseTr, hoverTr = THEME.TrElement, 0.6
	local function setContainerHover(isHover)
		if open then return end
		tween(container, {
			BackgroundColor3 = isHover and hoverCol or baseCol,
			BackgroundTransparency = isHover and hoverTr or baseTr,
		}, THEME.AnimFast)
		tween(st, { Transparency = isHover and 0.2 or 0.55 }, THEME.AnimFast)
	end

	local function getVisibleItems()
		local vis = {}
		for _, it in ipairs(items) do
			if it.Visible then
				vis[#vis + 1] = it
			end
		end
		return vis
	end

	local function updateHighlight()
		local vis = getVisibleItems()
		selectedIdx = math.clamp(selectedIdx, 1, math.max(1, #vis))
		for _, it in ipairs(items) do
			local isSel = false
			for j, v in ipairs(vis) do
				if v == it and j == selectedIdx then
					isSel = true
					break
				end
			end
			if isSel then
				it.BackgroundColor3 = WHITE
				it.BackgroundTransparency = 0
				it.TextColor3 = BLACK
			else
				it.BackgroundColor3 = THEME.Section
				it.BackgroundTransparency = 0.5
				it.TextColor3 = WHITE
			end
		end
	end

	local function applyFilter()
		local q = filterText:lower()
		local visibleCount = 0
		for _, it in ipairs(items) do
			it.Visible = (q == "" or it.Text:lower():find(q, 1, true) ~= nil)
			if it.Visible then
				visibleCount += 1
			end
		end
		local rowsToShow = math.min(visibleCount, 5) + (searchBox and 1 or 0)
		local spacingCount = math.max(0, rowsToShow - 1)
		listFrame.Size = UDim2.new(1, 0, 0, 8 + rowsToShow * 26 + spacingCount * 2)
		selectedIdx = 1
		updateHighlight()
	end

	local function close()
		if not open then return end
		open = false
		listFrame.Visible = false
		indicator.Text = "+"
		tween(indicator, { TextColor3 = THEME.TextDim })
		setContainerHover(false)
		if keyConn then
			keyConn:Disconnect()
			keyConn = nil
		end
		if StardustUI._closeActiveDropdown == close then
			StardustUI._closeActiveDropdown = nil
		end
		if searchBox then
			searchBox.Text = ""
			filterText = ""
			applyFilter()
		end
	end

	local function openDropdown()
		if open then return end
		if StardustUI._closeActiveDropdown and StardustUI._closeActiveDropdown ~= close then
			StardustUI._closeActiveDropdown()
		end
		open = true
		listFrame.Visible = true
		indicator.Text = "-"
		tween(indicator, { TextColor3 = WHITE })
		StardustUI._closeActiveDropdown = close

		selectedIdx = 1
		updateHighlight()
		if keyConn then keyConn:Disconnect() end
		keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed or not open then return end
			if input.KeyCode == Enum.KeyCode.Escape then
				close()
			elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
				local vis = getVisibleItems()
				if vis[selectedIdx] then
					value = vis[selectedIdx].Text
					current.Text = value
					close()
					if callback then pcall(callback, value) end
					if self.Tab.Window.AutoSave then
						self.Tab.Window:SaveConfig()
					end
				end
			elseif input.KeyCode == Enum.KeyCode.Up then
				selectedIdx = math.max(1, selectedIdx - 1)
				updateHighlight()
			elseif input.KeyCode == Enum.KeyCode.Down then
				local vis = getVisibleItems()
				selectedIdx = math.min(#vis, selectedIdx + 1)
				updateHighlight()
			end
		end)
	end

	local function rebuild()
		for _, it in ipairs(items) do
			it:Destroy()
		end
		items = {}

		if useSearch then
			if not searchBox then
				searchBox = make("TextBox", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = THEME.Section,
					BackgroundTransparency = 0.3,
					Text = "",
					PlaceholderText = "Search...",
					TextColor3 = WHITE,
					PlaceholderColor3 = THEME.TextMute,
					Font = THEME.Font,
					TextSize = 12,
					BorderSizePixel = 0,
					ClearTextOnFocus = false,
					LayoutOrder = 0,
					ZIndex = 17,
				}, listFrame)
				corner(searchBox, UDim.new(0, 4))
				stroke(searchBox, WHITE, 1, 0.7)
				make("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}, searchBox)
				searchBox:GetPropertyChangedSignal("Text"):Connect(function()
					filterText = searchBox.Text
					applyFilter()
				end)
			end
		elseif searchBox then
			searchBox:Destroy()
			searchBox = nil
		end

		for i, opt in ipairs(options) do
			local it = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = THEME.Section,
				BackgroundTransparency = 0.5,
				Text = tostring(opt),
				TextColor3 = WHITE,
				Font = THEME.Font,
				TextSize = 12,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = i,
				ZIndex = 17,
			}, listFrame)
			corner(it, UDim.new(0, 4))
			make("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}, it)

			it.MouseEnter:Connect(function()
				if not open then return end
				it.BackgroundColor3 = WHITE
				it.BackgroundTransparency = 0
				it.TextColor3 = BLACK
			end)
			it.MouseLeave:Connect(function()
				if not open then return end
				updateHighlight()
			end)

			it.MouseButton1Click:Connect(function()
				value = opt
				current.Text = tostring(opt)
				close()
				if callback then pcall(callback, value) end
				if self.Tab.Window.AutoSave then
					self.Tab.Window:SaveConfig()
				end
			end)

			items[#items + 1] = it
		end

		applyFilter()
	end

	rebuild()

	header.MouseEnter:Connect(function()
		setContainerHover(true)
		if not open then
			tween(indicator, { TextColor3 = WHITE })
		end
	end)
	header.MouseLeave:Connect(function()
		setContainerHover(false)
		if not open then
			tween(indicator, { TextColor3 = THEME.TextDim })
		end
	end)

	header.MouseButton1Click:Connect(function()
		if open then
			close()
		else
			openDropdown()
		end
	end)

	self.Tab.Window:_register(configKey, function() return value end, function(v)
		value = v
		current.Text = tostring(v)
	end)

	return {
		Set = function(_, v)
			value = v
			current.Text = tostring(v)
		end,
		Get = function()
			return value
		end,
		SetOptions = function(_, o)
			options = o or {}
			useSearch = #options >= 8
			rebuild()
			if open then
				updateHighlight()
			end
		end,
		Destroy = function()
			if open then close() end
			container:Destroy()
		end,
	}
end

function Section:Keybind(text, default, callback, configKey)
	default = default or Enum.KeyCode.Unknown
	local current = default
	local listening = false

	local holder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Element,
		BackgroundTransparency = THEME.TrElement,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		ZIndex = 15,
	}, self.Frame)
	corner(holder, UDim.new(0, 6))
	local st = animatedStroke(holder, 1.2, 0.55)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, holder)

	label({ Size = UDim2.new(0.5, 0, 1, 0), Text = text, TextSize = 13, ZIndex = 16 }, holder)

	local btn = make("TextButton", {
		Size = UDim2.new(0.5, -8, 0, 22),
		Position = UDim2.new(0.5, 4, 0.5, -11),
		BackgroundColor3 = THEME.Section,
		BackgroundTransparency = 0.2,
		Text = current.Name, TextColor3 = WHITE,
		Font = THEME.FontBold, TextSize = 12,
		BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 16,
	}, holder)
	corner(btn, UDim.new(0, 5))
	stroke(btn, WHITE, 1, 0.7)

	applyHoverEffect(holder, nil, THEME.Element, Color3.fromRGB(85, 85, 98), THEME.TrElement, 0.6, st, 0.55, 0.2)

	btn.MouseButton1Click:Connect(function()
		listening = true
		btn.Text = "..."
		tween(btn, { BackgroundColor3 = WHITE, BackgroundTransparency = 0, TextColor3 = BLACK })
	end)

	UserInputService.InputBegan:Connect(function(input)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			current = input.KeyCode
			btn.Text = current.Name
			tween(btn, { BackgroundColor3 = THEME.Section, BackgroundTransparency = 0.2, TextColor3 = WHITE })
			if callback then pcall(callback, current) end
			if self.Tab.Window.AutoSave then
				self.Tab.Window:SaveConfig()
			end
		end
	end)

	self.Tab.Window:_register(configKey, function() return current end, function(v)
		if typeof(v) == "EnumItem" then
			current = v
			btn.Text = current.Name
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
		LayoutOrder = self:_nextOrder(), TextWrapped = true, ZIndex = 15,
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
		ZIndex = 15,
	}, self.Frame)
	return { Destroy = function() d:Destroy() end }
end

return StardustUI
