--[[
	Tap Simulator Reborn - StardustUI
	Auto tap / auto buy / auto potions / egg auto-open / auto rebirth / stats / utility.
	Remote names are read live from ReplicatedStorage.RemoteServices so the script
	survives shop and update changes.
]]

local UI_URL = "https://raw.githubusercontent.com/djdnansndbd/uiblib/refs/heads/main/yes.lua"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

local StardustUI = loadstring(game:HttpGet(UI_URL))()

-- State ---------------------------------------------------------------
local State = {
	AutoTap = false,
	TapCPS = 20,
	TapSequence = 676767,
	TapsSent = 0,

	AutoBuy = false,
	BuyItems = {},

	AutoPotions = false,
	Potions = {},

	AutoEgg = false,
	EggSpot = "30m Visit Egg",
	EggId = "30M Visits",
	EggCount = 8,
	EggSequence = 0,
	EggReach = 6,

	AutoRebirth = false,
	RebirthRemote = "",
	RebirthArgs = "",
	RebirthInterval = 2,

	AutoRunner = false,
	RunnerRemote = "",
	RunnerArgs = "",
	RunnerInterval = 5,

	AntiAfk = true,
	LogRemotes = false,
}

local EggSpots = {
	["30m Visit Egg"] = {
		CFrame = CFrame.new(
			-51.529285,
			-513.471252,
			-1943.992920,
			0.872108,
			0,
			-0.489313,
			0,
			1,
			0,
			0.489313,
			0,
			0.872108
		),
		Egg = "30M Visits",
		Count = 8,
	},
}

-- Helpers -------------------------------------------------------------
local function splitPath(Path)
	local Parts = {}
	for Part in string.gmatch(Path, "[^%.]+") do
		table.insert(Parts, Part)
	end
	return Parts
end

local function resolve(Path)
	local Node = ReplicatedStorage
	for _, Part in ipairs(splitPath(Path)) do
		if not Node then
			return nil
		end
		Node = Node:FindFirstChild(Part)
	end
	return Node
end

local function relativeName(Object)
	return (Object:GetFullName():gsub("^ReplicatedStorage%.", ""))
end

local function collectRemotes(Filter)
	local Results = {}
	local Root = ReplicatedStorage:FindFirstChild("RemoteServices")

	for _, Object in ipairs(Root and Root:GetDescendants() or ReplicatedStorage:GetDescendants()) do
		if Object:IsA("RemoteEvent") or Object:IsA("RemoteFunction") then
			local Name = relativeName(Object)
			if not Filter or string.find(string.lower(Name), Filter, 1, true) then
				table.insert(Results, Name)
			end
		end
	end

	table.sort(Results)
	return Results
end

-- Turns "Luck Potion II" into "LuckPotionII" (the shop's id format)
local function toId(Name)
	return (tostring(Name):gsub("%s+", ""))
end

local function parseArgs(Text)
	Text = tostring(Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if Text == "" then
		return {}
	end

	if type(loadstring) ~= "function" then
		return { Text }
	end

	local Loaded = loadstring("return " .. Text)
	if not Loaded then
		return { Text }
	end

	local Ok, Result = pcall(Loaded)
	if Ok and type(Result) == "table" then
		return Result
	end

	return { Text }
end

local function fireRemote(Remote, ArgText)
	if not Remote then
		return false
	end

	local Args = parseArgs(ArgText)
	local Ok = pcall(function()
		if Remote:IsA("RemoteEvent") then
			Remote:FireServer(table.unpack(Args))
		else
			Remote:InvokeServer(table.unpack(Args))
		end
	end)

	return Ok
end

local function getRoot()
	local Character = player.Character
	return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function activeEggSpot()
	local Spot = EggSpots[State.EggSpot]
	if not Spot then
		return nil
	end
	if Spot.CFrame then
		return Spot
	end
	return { CFrame = Spot, Egg = State.EggId, Count = State.EggCount }
end

local function readStats()
	local Stats = {}

	local Leaderstats = player:FindFirstChild("leaderstats")
	if Leaderstats then
		for _, Value in ipairs(Leaderstats:GetChildren()) do
			if Value:IsA("ValueBase") then
				Stats[Value.Name] = Value.Value
			end
		end
	end

	return Stats
end

local function formatNumber(Value)
	if type(Value) == "number" then
		if Value >= 1e6 then
			return string.format("%.2fM", Value / 1e6)
		end
		if Value >= 1e4 then
			return string.format("%.1fK", Value / 1e4)
		end
		return tostring(math.floor(Value))
	end
	return tostring(Value)
end

-- Remote call log -----------------------------------------------------
local RemoteLog = {}
local LogLabel
local HookInstalled = false

local function pushLog(Line)
	table.insert(RemoteLog, Line)
	while #RemoteLog > 60 do
		table.remove(RemoteLog, 1)
	end
end

local function installHook()
	if HookInstalled then
		return true
	end
	if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
		return false
	end

	local Ok = pcall(function()
		local Original
		Original = hookmetamethod(game, "__namecall", function(Self, ...)
			local Method = getnamecallmethod()

			if
				State.LogRemotes
				and (Method == "FireServer" or Method == "InvokeServer" or Method == "InvokeServerAsync")
				and typeof(Self) == "Instance"
				and (Self:IsA("RemoteEvent") or Self:IsA("RemoteFunction"))
			then
				local Parts = {}
				for Index = 1, select("#", ...) do
					local Value = select(Index, ...)
					Parts[Index] = typeof(Value) == "table" and "{table}" or tostring(Value)
				end
				pushLog(Method .. " " .. relativeName(Self) .. "(" .. table.concat(Parts, ", ") .. ")")
			end

			return Original(Self, ...)
		end)
	end)

	HookInstalled = Ok
	return Ok
end

-- Window --------------------------------------------------------------
local window = StardustUI.new({
	Title = "[👻] Tap Simulator REBORN",
	Subtitle = "[💎] Stardust build",
	Keybind = Enum.KeyCode.LeftControl,
	ConfigName = "TapSimulatorREBORN",
	ConfigFolder = "TapSimulatorREBORN",
	AutoLoad = true,
	AutoSave = true,
})

window:ShowHome()

local function notify(Title, Text, Kind)
	pcall(function()
		window:Notify(Title, Text, 5, Kind or "info")
	end)
end

-- Farming -------------------------------------------------------------
local FarmTab = window:Tab("Farming")
local TapSection = FarmTab:Section("Auto Tap")

TapSection:Toggle(
	"Auto Tap",
	"Sends TapRequested while enabled. Raise CPS carefully - servers can kick for spam.",
	false,
	function(Enabled)
		State.AutoTap = Enabled
	end,
	"autoTapEnabled"
)

TapSection:Slider("Taps per second", 1, 60, 20, function(Value)
	State.TapCPS = math.max(1, math.floor(Value))
end, "autoTapCPS")

local BuySection = FarmTab:Section("Auto Buy")

BuySection:Toggle(
	"Auto Buy",
	"Buys every selected id from the shop remote.",
	false,
	function(Enabled)
		State.AutoBuy = Enabled
	end,
	"autoBuyEnabled"
)

BuySection:MultiDropdown("Items to buy", "Select what Auto Buy should purchase.", {
	"BloodMoonDial",
	"OctoIncubator",
	"TotemOfSecretLuck",
	"TotemOfLuck",
	"TotemOfHatchSpeed",
	"Luck Potion II",
	"SecretFruit",
	"RainbowStrawberry",
	"PetLevels10",
	"GoldenApple",
	"TreatBags",
}, {}, function(Selected)
	State.BuyItems = Selected
end, "autoBuyItems")

local PotionSection = FarmTab:Section("Potions")

PotionSection:Toggle(
	"Auto Use Potions",
	"Uses every selected potion on a loop.",
	false,
	function(Enabled)
		State.AutoPotions = Enabled
	end,
	"autoUsePotionsEnabled"
)

PotionSection:MultiDropdown("Potions to use", "Select which potions to drink.", {
	"Luck Potion I",
	"Luck Potion II",
	"Coins Potion I",
	"Coins Potion II",
	"Gems Potion I",
	"Gems Potion II",
	"Octo Incubator",
	"Level Potion",
	"Shiny Potion",
	"Golden Potion",
}, {}, function(Selected)
	State.Potions = Selected
end, "autoUsePotions")

-- Eggs ----------------------------------------------------------------
local EggTab = window:Tab("Eggs")
local EggSection = EggTab:Section("Auto Open Egg")

local EggDropdown
local EggStatus
local EggIdBox
local EggCountSlider

local function eggStatusText()
	local Spot = activeEggSpot()
	local Egg = Spot and (Spot.Egg or State.EggId) or State.EggId
	local Count = Spot and (Spot.Count or State.EggCount) or State.EggCount
	return string.format(
		"Spot: %s   |   egg: %s   |   count: %d   |   seq: %d",
		State.EggSpot ~= "" and State.EggSpot or "none",
		Egg,
		Count,
		State.EggSequence
	)
end

local function refreshEggStatus()
	if EggStatus then
		EggStatus:Set(eggStatusText())
	end
end

local function refreshEggOptions()
	local Names = {}
	for Name in pairs(EggSpots) do
		table.insert(Names, Name)
	end
	table.sort(Names)

	if EggDropdown then
		EggDropdown:SetOptions(Names)
		if not EggSpots[State.EggSpot] then
			State.EggSpot = Names[1] or ""
		end
		EggDropdown:Set(State.EggSpot)
	end

	refreshEggStatus()
end

EggDropdown = EggSection:Dropdown("Egg spot", "Where to stand while hatching.", { "30m Visit Egg" }, "30m Visit Egg", function(Value)
	State.EggSpot = Value

	local Spot = EggSpots[Value]
	if type(Spot) == "table" then
		State.EggId = Spot.Egg or State.EggId
		State.EggCount = Spot.Count or State.EggCount
		if EggIdBox then
			EggIdBox:Set(State.EggId)
		end
		if EggCountSlider then
			EggCountSlider:Set(State.EggCount)
		end
	end

	refreshEggStatus()
end, "eggSpot")

EggSection:Toggle(
	"Auto Open Egg",
	"Teleports to the egg, then fires EggHatchRequested every 2s with a climbing Seq.",
	false,
	function(Enabled)
		State.AutoEgg = Enabled
		if Enabled then
			local Spot = activeEggSpot()
			if not Spot then
				notify("Eggs", "No spot saved yet - press 'Save current position'.", "error")
				return
			end

			-- Seq deliberately keeps climbing across toggles: off at 1276 -> on fires 1277
			pcall(function()
				if player.Character then
					player.Character:PivotTo(Spot.CFrame)
				end
			end)
			refreshEggStatus()
		end
	end,
	"autoOpen30mEgg"
)

EggIdBox = EggSection:Textbox("Egg id (remote value)", "30M Visits", function(Value)
	State.EggId = Value
	refreshEggStatus()
end, "eggId")

EggCountSlider = EggSection:Slider("Hatch count", 1, 50, 8, function(Value)
	State.EggCount = math.max(1, math.floor(Value))
	refreshEggStatus()
end, "eggCount")

local SpotNameBox = EggSection:Textbox("Spot name", "", function() end, "eggSpotName")

EggSection:Button("Save current position", "Stores your position + egg settings under the name above.", function()
	local Name = SpotNameBox:Get()
	if type(Name) ~= "string" or Name:gsub("%s+", "") == "" then
		notify("Eggs", "Type a spot name first.", "error")
		return
	end

	local Character = player.Character
	if not Character then
		notify("Eggs", "Character not loaded.", "error")
		return
	end

	EggSpots[Name] = {
		CFrame = Character:GetPivot(),
		Egg = State.EggId,
		Count = State.EggCount,
	}
	State.EggSpot = Name
	refreshEggOptions()
	notify("Eggs", "Saved spot: " .. Name, "success")
end)

EggSection:Button("Delete selected spot", "Removes the spot currently selected above.", function()
	if State.EggSpot == "30m Visit Egg" then
		notify("Eggs", "The default spot cannot be removed.", "error")
		return
	end

	if EggSpots[State.EggSpot] then
		EggSpots[State.EggSpot] = nil
		refreshEggOptions()
		notify("Eggs", "Deleted spot: " .. State.EggSpot, "success")
	end
end)

EggStatus = EggSection:Label("Spot: 30m Visit Egg   |   egg: 30M Visits   |   count: 8   |   seq: 0")

-- Rebirth / remote runner ---------------------------------------------
local RebirthTab = window:Tab("Rebirth")
local RebirthSection = RebirthTab:Section("Auto Rebirth")

local RebirthDropdown
local RebirthStatus

local function refreshRebirthOptions()
	local List = collectRemotes("rebirth")

	if RebirthDropdown then
		RebirthDropdown:SetOptions(List)
		if #List > 0 and not table.find(List, State.RebirthRemote) then
			State.RebirthRemote = List[1]
			RebirthDropdown:Set(State.RebirthRemote)
		end
	end

	if RebirthStatus then
		RebirthStatus:Set(
			#List > 0 and ("Found " .. #List .. " rebirth remote(s).")
				or "No rebirth remote found. Use Remote Runner below."
		)
	end
end

RebirthDropdown = RebirthSection:Dropdown("Rebirth remote", "Detected automatically.", { "-" }, "-", function(Value)
	State.RebirthRemote = Value
end, "rebirthRemote")

RebirthSection:Textbox("Arguments (Lua table)", "{}", function(Value)
	State.RebirthArgs = Value
end, "rebirthArgs")

RebirthSection:Slider("Interval (s)", 1, 120, 2, function(Value)
	State.RebirthInterval = math.max(1, math.floor(Value))
end, "rebirthInterval")

RebirthSection:Toggle(
	"Auto Rebirth",
	"Fires the selected rebirth remote on an interval.",
	false,
	function(Enabled)
		State.AutoRebirth = Enabled
	end,
	"autoRebirthEnabled"
)

RebirthSection:Button("Fire once", "Fires the selected remote a single time.", function()
	local Remote = resolve(State.RebirthRemote)
	if fireRemote(Remote, State.RebirthArgs) then
		notify("Rebirth", "Fired " .. State.RebirthRemote, "success")
	else
		notify("Rebirth", "Could not fire " .. State.RebirthRemote, "error")
	end
end)

RebirthSection:Button("Refresh remotes", "Re-scans RemoteServices for rebirth remotes.", function()
	refreshRebirthOptions()
end)

RebirthStatus = RebirthSection:Label("Scanning...")

local RunnerSection = RebirthTab:Section("Remote Runner")
local RunnerDropdown

local function refreshRunnerOptions()
	local List = collectRemotes()
	if RunnerDropdown then
		RunnerDropdown:SetOptions(List)
		if #List > 0 and not table.find(List, State.RunnerRemote) then
			State.RunnerRemote = List[1]
			RunnerDropdown:Set(State.RunnerRemote)
		end
	end
end

RunnerDropdown = RunnerSection:Dropdown("Remote", "Every RemoteEvent / RemoteFunction in RemoteServices.", { "-" }, "-", function(Value)
	State.RunnerRemote = Value
end, "runnerRemote")

RunnerSection:Textbox("Arguments (Lua table)", "{}", function(Value)
	State.RunnerArgs = Value
end, "runnerArgs")

RunnerSection:Slider("Interval (s)", 1, 120, 5, function(Value)
	State.RunnerInterval = math.max(1, math.floor(Value))
end, "runnerInterval")

RunnerSection:Toggle(
	"Auto Fire",
	"Keeps firing the selected remote on the interval.",
	false,
	function(Enabled)
		State.AutoRunner = Enabled
	end,
	"runnerEnabled"
)

RunnerSection:Button("Fire once", "Fires the selected remote a single time.", function()
	local Remote = resolve(State.RunnerRemote)
	if fireRemote(Remote, State.RunnerArgs) then
		notify("Remote", "Fired " .. State.RunnerRemote, "success")
	else
		notify("Remote", "Could not fire " .. State.RunnerRemote, "error")
	end
end)

RunnerSection:Button("Refresh list", "Re-scans RemoteServices.", function()
	refreshRunnerOptions()
end)

-- Stats ---------------------------------------------------------------
local StatsTab = window:Tab("Stats")
local StatsSection = StatsTab:Section("Live")
local StatsLabel = StatsSection:Label("Reading stats...")
local TapLabel = StatsSection:Label("Taps sent: 0")

StatsSection:Button("Copy remote log", "Copies the captured remote calls to your clipboard.", function()
	local Text = table.concat(RemoteLog, "\n")
	if Text == "" then
		notify("Log", "Nothing captured yet.", "error")
		return
	end
	if setclipboard then
		setclipboard(Text)
		notify("Log", "Copied " .. #RemoteLog .. " lines.", "success")
	else
		notify("Log", "Executor has no setclipboard.", "error")
	end
end)

-- Utility -------------------------------------------------------------
local UtilityTab = window:Tab("Utility")
local UtilitySection = UtilityTab:Section("Session")

UtilitySection:Toggle("Anti-AFK", "Blocks the 20 minute idle kick.", true, function(Enabled)
	State.AntiAfk = Enabled
end, "antiAfk")

UtilitySection:Button("Rejoin server", "Reconnects to the same place.", function()
	pcall(function()
		TeleportService:Teleport(game.PlaceId, player)
	end)
end)

local LogSection = UtilityTab:Section("Remote log")
local LoggerStatus = LogSection:Label("Log is off.")

LogSection:Toggle(
	"Capture remote calls",
	"Records every FireServer / InvokeServer with its arguments (last 60).",
	false,
	function(Enabled)
		if Enabled and not installHook() then
			notify("Log", "Hookmetamethod unavailable on this executor.", "error")
			return
		end
		State.LogRemotes = Enabled
		LoggerStatus:Set(Enabled and "Capturing..." or "Log is off.")
	end,
	"logRemotes"
)

local LogOutput = LogSection:Label("")

-- Background loops ----------------------------------------------------
-- Auto tap
task.spawn(function()
	local TapRemote
	while true do
		if State.AutoTap then
			if not (TapRemote and TapRemote.Parent) then
				TapRemote = resolve("RemoteServices.TapService.RE.TapRequested")
			end

			if TapRemote then
				State.TapSequence += 1
				State.TapsSent += 1
				pcall(function()
					TapRemote:FireServer({
						ClientSequence = State.TapSequence,
						Auto = false,
						Source = "button",
					})
				end)
				task.wait(1 / math.max(1, State.TapCPS))
			else
				task.wait(1)
			end
		else
			task.wait(0.1)
		end
	end
end)

-- Auto buy
task.spawn(function()
	while true do
		if State.AutoBuy and #State.BuyItems > 0 then
			local Shop = resolve("RemoteServices.HalloweenShopService.RF.Purchase")
			if not Shop then
				local Root = ReplicatedStorage:FindFirstChild("RemoteServices")
				for _, Object in ipairs(Root and Root:GetDescendants() or {}) do
					if Object:IsA("RemoteFunction") and (Object.Name == "Purchase" or Object.Name == "Buy") then
						Shop = Object
						break
					end
				end
			end

			if Shop then
				for _, Item in ipairs(State.BuyItems) do
					pcall(function()
						Shop:InvokeServer({ Id = toId(Item) })
					end)
					task.wait(0.1)
				end
			else
				task.wait(1)
			end
		else
			task.wait(0.2)
		end
	end
end)

-- Auto potions
task.spawn(function()
	while true do
		if State.AutoPotions and #State.Potions > 0 then
			local Boost = resolve("RemoteServices.BoostService.RF.Use")
			if Boost then
				for _, Potion in ipairs(State.Potions) do
					pcall(function()
						Boost:InvokeServer(Potion)
					end)
					task.wait(0.1)
				end
			else
				task.wait(1)
			end
		else
			task.wait(0.2)
		end
	end
end)

-- Auto egg: fires EggHatchRequested every 2s, Seq climbs like Auto Tap
task.spawn(function()
	local EggRemote

	while true do
		if State.AutoEgg then
			local Spot = activeEggSpot()
			local Root = getRoot()

			if Spot and Root and player.Character then
				if (Root.Position - Spot.CFrame.Position).Magnitude > State.EggReach then
					pcall(function()
						player.Character:PivotTo(Spot.CFrame)
					end)
					task.wait(0.12)
				end

				if not (EggRemote and EggRemote.Parent) then
					EggRemote = resolve("RemoteServices.EggService.RE.EggHatchRequested")
				end

				if EggRemote then
					State.EggSequence += 1
					pcall(function()
						EggRemote:FireServer({
							Egg = Spot.Egg or State.EggId,
							Auto = false,
							Seq = State.EggSequence,
							Count = Spot.Count or State.EggCount,
						})
					end)
				end
			end

			task.wait(2)
		else
			task.wait(0.1)
		end
	end
end)

-- Auto rebirth
task.spawn(function()
	while true do
		if State.AutoRebirth and State.RebirthRemote ~= "" and State.RebirthRemote ~= "-" then
			fireRemote(resolve(State.RebirthRemote), State.RebirthArgs)
			task.wait(math.max(1, State.RebirthInterval))
		else
			task.wait(0.25)
		end
	end
end)

-- Remote runner
task.spawn(function()
	while true do
		if State.AutoRunner and State.RunnerRemote ~= "" and State.RunnerRemote ~= "-" then
			fireRemote(resolve(State.RunnerRemote), State.RunnerArgs)
			task.wait(math.max(1, State.RunnerInterval))
		else
			task.wait(0.25)
		end
	end
end)

-- Stats + log refresh
task.spawn(function()
	while true do
		local Parts = {}
		local Stats = readStats()

		for Name, Value in pairs(Stats) do
			table.insert(Parts, Name .. ": " .. formatNumber(Value))
		end
		table.sort(Parts)

		if #Parts == 0 then
			StatsLabel:Set("No leaderstats found.")
		else
			StatsLabel:Set(table.concat(Parts, "   |   "))
		end

		TapLabel:Set("Taps sent: " .. State.TapsSent .. "   |   CPS: " .. State.TapCPS)
		refreshEggStatus()

		if State.LogRemotes then
			local Tail = {}
			for Index = math.max(1, #RemoteLog - 5), #RemoteLog do
				table.insert(Tail, RemoteLog[Index])
			end
			LogOutput:Set(table.concat(Tail, "\n"))
		end

		task.wait(1)
	end
end)

-- Anti-AFK
player.Idled:Connect(function()
	if State.AntiAfk then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

-- Boot ----------------------------------------------------------------
refreshEggOptions()
refreshRebirthOptions()
refreshRunnerOptions()

notify("Tap Simulator Reborn", "Loaded. Left Ctrl toggles the menu.", "success")
