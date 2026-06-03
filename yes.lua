if getgenv().SlimeRNG_Unload then
    pcall(getgenv().SlimeRNG_Unload)
end

local isUnloaded = false
local numRollsConnection = nil
local charAddedConn = nil

getgenv().SlimeRNG_Unload = function()
    isUnloaded = true
    if numRollsConnection then
        pcall(function() numRollsConnection:Disconnect() end)
    end
    if charAddedConn then
        pcall(function() charAddedConn:Disconnect() end)
    end
    if getgenv().SlimeRNG_StatsOverlay then getgenv().SlimeRNG_StatsOverlay:Destroy() end
    if getgenv().SlimeRNG_Window and getgenv().SlimeRNG_Window.ScreenGui then
        pcall(function() getgenv().SlimeRNG_Window.ScreenGui:Destroy() end)
    end
end

repeat task.wait() until game:IsLoaded()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/djdnansndbd/uiblib/refs/heads/main/je7p%20uilib"))()
Library.ConfigFolder = "SlimeRNG"
local players = game:GetService("Players")
local Options = Library.Options
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local localPlayer = players.LocalPlayer
local client = workspace:FindFirstChild(localPlayer.Name)
local clientHRP = client.HumanoidRootPart

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameRequire = (getrenv and getrenv().require) or require
local playerDataClient, UpgradeTree, UpgradeUtils
pcall(function()
    playerDataClient = gameRequire(ReplicatedStorage.Packages.DataService).client
    UpgradeTree = gameRequire(ReplicatedStorage.Source.Features.Upgrades.UpgradeTree)
    UpgradeUtils = gameRequire(ReplicatedStorage.Source.Features.Upgrades.UpgradeServiceUtils)
end)
local BuyUpgrade = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("UpgradeService"):WaitForChild("RemoteFunction")

local Stats = {
    SessionRolls = 0,
    StartTime = tick()
}

local function setupNumRollsListener(character)
    if numRollsConnection then
        pcall(function() numRollsConnection:Disconnect() end)
        numRollsConnection = nil
    end

    if not character then return end
    
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    if not hrp then return end
    
    local titleGui = hrp:WaitForChild("TitleGui", 10)
    if not titleGui then return end
    
    local numRolls = titleGui:WaitForChild("NumRolls", 10)
    if not numRolls then return end
    
    local lastText = numRolls.Text
    numRollsConnection = numRolls:GetPropertyChangedSignal("Text"):Connect(function()
        local currentText = numRolls.Text
        if currentText ~= lastText then
            Stats.SessionRolls = Stats.SessionRolls + 1
            lastText = currentText
        end
    end)
end

if localPlayer.Character then
    task.spawn(setupNumRollsListener, localPlayer.Character)
end

charAddedConn = localPlayer.CharacterAdded:Connect(function(char)
    setupNumRollsListener(char)
end)

local function getTotalRolls()
    local ls = localPlayer:FindFirstChild("leaderstats")
    if ls then
        local rolls = ls:FindFirstChild("Rolls")
        if rolls then return rolls.Value end
    end
    return nil
end

local function getRollSpeed()
    local ok, spd = pcall(function()
        return localPlayer.PlayerGui.Root.BottomBarStats.StatsList.RollSpeedStat.Content.Value.TextLabel.Text
    end)
    if ok and spd then
        local v = tonumber(string.match(spd, "[%d%.]+"))
        if v and v > 0 then return v end
    end
    return nil
end

local zoneNavMode = "Teleport"

local Window = Library:CreateWindow({
    Title = "Slime RNG",
    Size = UDim2.fromOffset(580, 460),
    ToggleKey = Enum.KeyCode.RightControl
})
getgenv().SlimeRNG_Window = Window

local Tabs = {
    Automation = Window:AddTab("Automation", "🤖"),
    Items = Window:AddTab("Items", "📦"),
    Combat = Window:AddTab("Combat", "⚔️"),
    Misc = Window:AddTab("Misc", "📜"),
    Stats = Window:AddTab("Stats", "📊"),
    Upgrades = Window:AddTab("Upgrades", "⬆️"),
    Settings = Window:AddTab("Settings", "⚙️")
}

function Notify(title, description)
    Window:Notify({
        Title = title,
        Message = description,
        Duration = 5
    })
end

function Roll()
    local args = { "requestRoll" }
    local result = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("RollService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
    return result
end

local TotalRollsLabel = Tabs.Stats:AddParagraph({ Title = "🏆 Total Rolls", Content = "--" })
local SessionRollsLabel = Tabs.Stats:AddParagraph({ Title = "🎲 Session Rolls", Content = "0" })
local TimeLabel = Tabs.Stats:AddParagraph({ Title = "⏱️ Session Time", Content = "0s" })
local RPMLabel = Tabs.Stats:AddParagraph({ Title = "⚡ Rolls/Min", Content = "--" })
local RPHLabel = Tabs.Stats:AddParagraph({ Title = "📈 Rolls/Hour", Content = "--" })
local RPDLabel = Tabs.Stats:AddParagraph({ Title = "📊 Rolls/Day", Content = "--" })

local coreGui = game:GetService("CoreGui")
local uiParent = (gethui and gethui()) or localPlayer:FindFirstChild("PlayerGui") or coreGui

local statsScreenGui = Instance.new("ScreenGui")
statsScreenGui.Name = "SlimeRNGStatsOverlay"
statsScreenGui.ResetOnSpawn = false
statsScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
statsScreenGui.Enabled = false
statsScreenGui.Parent = uiParent
getgenv().SlimeRNG_StatsOverlay = statsScreenGui

local overlayFrame = Instance.new("Frame")
overlayFrame.Name = "OverlayFrame"
overlayFrame.Size = UDim2.new(0, 230, 0, 150)
overlayFrame.Position = UDim2.new(0.5, -100, 0, 10)
overlayFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
overlayFrame.BackgroundTransparency = 0.3
overlayFrame.BorderSizePixel = 0
overlayFrame.Parent = statsScreenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = overlayFrame

local function createOverlayLabel(name, yOffset)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, yOffset)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.Parent = overlayFrame
    return label
end

local overlayFPS     = createOverlayLabel("FPSLabel",          10)
local overlayPing    = createOverlayLabel("PingLabel",         32)
local overlayTotal   = createOverlayLabel("TotalRollsLabel",   54)
local overlaySession = createOverlayLabel("SessionRollsLabel", 76)
local overlayTime    = createOverlayLabel("TimeLabel",         98)
local overlayRPM     = createOverlayLabel("RPMLabel",         120)
local overlayRPH     = createOverlayLabel("RPHLabel",         142)
local overlayRPD     = createOverlayLabel("RPDLabel",         164)

overlayFrame.Size = UDim2.new(0, 230, 0, 194)

local dragging, dragInput, dragStart, startPos
overlayFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = overlayFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
overlayFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        overlayFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

Tabs.Stats:AddToggle({
    Title = "Show Live Overlay",
    Default = false,
    Flag = "ShowLiveOverlay",
    Callback = function(value)
        if statsScreenGui then statsScreenGui.Enabled = value end
    end
})

local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

local lastTick = tick()
local frameCount = 0
local currentFPS = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    if tick() - lastTick >= 1 then
        currentFPS = frameCount
        frameCount = 0
        lastTick = tick()
    end
end)

task.spawn(function()
    while task.wait(1) and not isUnloaded do
        local elapsed = tick() - Stats.StartTime

        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = math.floor(elapsed % 60)
        local timeStr
        if h > 0 then
            timeStr = string.format("⏱️ Session Time: %dh %dm %ds", h, m, s)
        elseif m > 0 then
            timeStr = string.format("⏱️ Session Time: %dm %ds", m, s)
        else
            timeStr = string.format("⏱️ Session Time: %ds", s)
        end

        local totalRolls = getTotalRolls()
        local totalStr = "🏆 Total Rolls: " .. (totalRolls and tostring(totalRolls) or "--")

        local sessionStr = "🎲 Session Rolls: " .. tostring(Stats.SessionRolls)

        local rpmStr, rphStr, rpdStr
        if elapsed > 0 then
            local rpm  = math.round((Stats.SessionRolls / elapsed) * 60 * 10) / 10
            local rph  = math.round((Stats.SessionRolls / elapsed) * 3600 * 10) / 10
            local rpd  = math.round((Stats.SessionRolls / elapsed) * 86400)
            rpmStr = "⚡ Rolls/Min: " .. tostring(rpm)
            rphStr = "📈 Rolls/Hour: " .. tostring(rph)
            rpdStr = "📊 Rolls/Day: " .. tostring(rpd)
        else
            rpmStr = "⚡ Rolls/Min: 0"
            rphStr = "📈 Rolls/Hour: 0"
            rpdStr = "📊 Rolls/Day: 0"
        end
        
        local fpsStr = "🖥️ FPS: " .. tostring(currentFPS)
        local ping = 0
        pcall(function() ping = math.round(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local pingStr = "📶 Ping: " .. tostring(ping) .. "ms"

        TotalRollsLabel:SetDesc(totalStr)
        SessionRollsLabel:SetDesc(sessionStr)
        TimeLabel:SetDesc(timeStr)
        RPMLabel:SetDesc(rpmStr)
        RPHLabel:SetDesc(rphStr)
        RPDLabel:SetDesc(rpdStr)

        if overlayTotal   then overlayTotal.Text   = totalStr   end
        if overlaySession  then overlaySession.Text = sessionStr end
        if overlayTime     then overlayTime.Text    = timeStr    end
        if overlayRPM      then overlayRPM.Text     = rpmStr     end
        if overlayRPH      then overlayRPH.Text     = rphStr     end
        if overlayRPD      then overlayRPD.Text     = rpdStr     end
        if overlayFPS      then overlayFPS.Text     = fpsStr     end
        if overlayPing     then overlayPing.Text    = pingStr    end
    end
end)

local ActiveCodes = {
    "sliming",
    "goingBananas",
    "test",
    "gullible",
    "AAisComing",
    "beammeup"
}

Tabs.Items:AddButton({
    Title = "Redeem All Active Codes",
    Description = "Redeems all currently active codes",
    Callback = function()
        Notify("🎁 Rewards", "Starting code redemption...")
        local CodeRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):FindFirstChild("CodeService") or 
                          ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):FindFirstChild("RedeemService")
        
        if CodeRemote then
            for _, code in ipairs(ActiveCodes) do
                pcall(function()
                    CodeRemote.RemoteFunction:InvokeServer("redeem", code)
                end)
                task.wait(0.5)
            end
            Notify("✅ Rewards", "Redemption process finished!")
        else
            Notify("❌ Error", "Code service not found. Try redeeming manually.")
        end
    end
})

local SectionAutomation = Tabs.Automation:AddSection("Automation")

SectionAutomation:AddToggle({
    Title = "Auto Roll",
    Default = false,
    Flag = "AutoRoll",
    Callback = function(value)
        Notify("🎲 Auto Roll", value and "Enabled" or "Disabled")
        task.spawn(function()
            while Options.AutoRoll.Value and not isUnloaded do
                task.spawn(Roll)
                task.wait(0.08)
            end
        end)
    end
})

SectionAutomation:AddToggle({
    Title = "Auto Index",
    Default = false,
    Flag = "AutoIndex",
    Callback = function(value)
        Notify("📚 Auto Index", value and "Enabled" or "Disabled")
        task.spawn(function()
            while Options.AutoIndex.Value and not isUnloaded do
                task.wait(30)
                ClaimIndex()
            end
        end)
    end
})

local LootRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("LootService"):WaitForChild("RemoteFunction")
local autoCollectFruitConn = nil

SectionAutomation:AddToggle({
    Title = "Auto Collect Drops",
    Default = false,
    Flag = "AutoCollectFruit",
    Callback = function(value)
        Notify("🎁 Auto Collect Drops", value and "Enabled" or "Disabled")
    if value then
        local function collectLoot(loot)
            task.spawn(function()
                local root = loot:FindFirstChild("Root") or loot:WaitForChild("Root", 2)
                local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") or clientHRP
                
                if root and hrp then
                    pcall(function()
                        root.Anchored = true
                        root.CanCollide = false
                    end)
                    local magnetConn
                    magnetConn = game:GetService("RunService").RenderStepped:Connect(function()
                        if not loot.Parent or not Options.AutoCollectFruit.Value or isUnloaded then
                            if magnetConn then magnetConn:Disconnect() end
                            return
                        end
                        pcall(function()
                            root.CFrame = hrp.CFrame
                        end)
                    end)
                end
                
                pcall(function() LootRemote:InvokeServer("requestCollect", loot.Name) end)
            end)
        end

        for _, loot in pairs(workspace.Loot:GetChildren()) do
            collectLoot(loot)
        end
        autoCollectFruitConn = workspace.Loot.ChildAdded:Connect(collectLoot)
    else
        if autoCollectFruitConn then
            autoCollectFruitConn:Disconnect()
            autoCollectFruitConn = nil
        end
    end
end)

SectionAutomation:AddToggle({
    Title = "Auto Best Zone",
    Default = false,
    Flag = "AutoTeleportBestZone",
    Callback = function(value)
        Notify("🗺️ Auto Best Zone", value and "Enabled" or "Disabled")
    if value then
        autoBestZoneThread = task.spawn(function()
            while Options.AutoTeleportBestZone.Value and not isUnloaded do
                TeleportBestZone()
                task.wait(1)
            end
        end)
    else
        if autoBestZoneThread then
            task.cancel(autoBestZoneThread)
            autoBestZoneThread = nil
        end
        if walkingThread then
            task.cancel(walkingThread)
            walkingThread = nil
            pcall(function()
                local hum = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid")
                if hum and hum.RootPart then
                    hum:MoveTo(hum.RootPart.Position)
                end
            end)
        end
    end
end)

SectionAutomation:AddDropdown({
    Title = "Best Zone Mode",
    Values = { "Teleport", "Walk" },
    Multi = false,
    Default = "Teleport",
    Flag = "BestZoneMode",
    Callback = function(value)
        zoneNavMode = value
    end
})

local SectionPlayer = Tabs.Misc:AddSection("Local Player")

SectionPlayer:AddToggle({
    Title = "Enable Walk Speed",
    Default = false,
    Flag = "EnableWalkSpeed",
    Callback = function(value)
        Notify("🏃 Walk Speed", value and "Enabled" or "Disabled")
    end
})

SectionPlayer:AddToggle({
    Title = "Enable Jump Power",
    Default = false,
    Flag = "EnableJumpPower",
    Callback = function(value)
        Notify("🚀 Jump Power", value and "Enabled" or "Disabled")
    end
})

SectionPlayer:AddSlider({
    Title = "Walk Speed",
    Description = "Adjust WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 1,
    Flag = "PlayerWalkSpeed",
    Callback = function(Value) end
})

SectionPlayer:AddSlider({
    Title = "Jump Power",
    Description = "Adjust Jump power",
    Default = 50,
    Min = 50,
    Max = 300,
    Rounding = 1,
    Flag = "PlayerJumpPower",
    Callback = function(Value) end
})

SectionPlayer:AddSlider({
    Title = "Sprint Speed",
    Description = "Speed when holding the sprint key",
    Default = 50,
    Min = 16,
    Max = 300,
    Rounding = 1,
    Flag = "SprintSpeed",
    Callback = function(Value) end
})

local isSprinting = false
SectionPlayer:AddKeybind({
    Title = "Sprint Keybind",
    Mode = "Hold",
    Default = "LeftShift",
    Flag = "SprintKey",
    Callback = function(Value)
        isSprinting = Value
    end
})

task.spawn(function()
    while task.wait(0.1) and not isUnloaded do
        pcall(function()
            if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
                local hum = localPlayer.Character.Humanoid
                
                if Options.EnableWalkSpeed.Value then
                    local ws = isSprinting and Options.SprintSpeed.Value or Options.PlayerWalkSpeed.Value
                    if hum.WalkSpeed ~= ws then
                        hum.WalkSpeed = ws
                    end
                end
                
                if Options.EnableJumpPower.Value then
                    hum.UseJumpPower = true
                    local jp = Options.PlayerJumpPower.Value
                    if hum.JumpPower ~= jp then
                        hum.JumpPower = jp
                    end
                end
            end
        end)
    end
end)

local SectionMisc = Tabs.Misc:AddSection("Miscellaneous")

local antiAfkConn = nil
SectionMisc:AddToggle({
    Title = "Anti AFK",
    Default = false,
    Flag = "AntiAFK",
    Callback = function(value)
        Notify("🛡️ Anti AFK", value and "Enabled" or "Disabled")
    if value then
        antiAfkConn = localPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new())
        end)

        task.spawn(function()
            while Options.AntiAFK.Value and not isUnloaded do
                task.wait(math.random(25, 45))
                if isUnloaded or not Options.AntiAFK.Value then break end

                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new())
                end)
            end
        end)
    else
        if antiAfkConn then
            antiAfkConn:Disconnect()
            antiAfkConn = nil
        end
    end
end)

local ufoEventConn = nil

SectionMisc:AddToggle({
    Title = "Auto UFO Event",
    Default = false,
    Flag = "AutoUFO",
    Callback = function(value)
        Notify("🛸 Auto UFO", value and "Enabled" or "Disabled")
        if value then
            local function onUFOSpawned(child)
                if not Options.AutoUFO.Value or isUnloaded then return end
                if not child or not child.Parent then return end
                task.spawn(function()
                    pcall(function()
                        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end

                        local originalCFrame = hrp.CFrame
                        local heartbeatConn = nil
                        local destroyConn = nil

                        local function stopFollow()
                            if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
                            if destroyConn then destroyConn:Disconnect() destroyConn = nil end
                            pcall(function()
                                hrp.CFrame = originalCFrame
                            end)
                        end

                        if child and child.Parent then
                            destroyConn = child.AncestryChanged:Connect(function()
                                if not child.Parent then
                                    stopFollow()
                                    Notify("🛸 Auto UFO", "UFO gone, returning to original position.")
                                end
                            end)
                        end

                        heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
                            if not Options.AutoUFO.Value or isUnloaded then
                                stopFollow()
                                return
                            end
                            if not child or not child.Parent then
                                stopFollow()
                                return
                            end
                            
                            pcall(function()
                                local ufoPos = child:IsA("Model") and child:GetBoundingBox().Position
                                    or (child.PrimaryPart and child.PrimaryPart.Position)
                                    or (child:FindFirstChildWhichIsA("BasePart") and child:FindFirstChildWhichIsA("BasePart").Position)
                                    
                                if ufoPos then
                                    hrp.CFrame = CFrame.new(ufoPos - Vector3.new(0, 15, 0))
                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                end
                            end)
                        end)
                        Notify("🛸 Auto UFO", "UFO spotted! Following under it.")
                    end)
                end)
            end

            local ufoEvent = workspace:FindFirstChild("UfoEvent")
            if ufoEvent then
                for _, child in pairs(ufoEvent:GetChildren()) do
                    task.spawn(onUFOSpawned, child)
                end
                ufoEventConn = ufoEvent.ChildAdded:Connect(onUFOSpawned)
            else
                local ufoWatcher = workspace.ChildAdded:Connect(function(child)
                    if child.Name == "UfoEvent" then
                        for _, c in pairs(child:GetChildren()) do
                            task.spawn(onUFOSpawned, c)
                        end
                        ufoEventConn = child.ChildAdded:Connect(onUFOSpawned)
                    end
                end)
                getgenv()._ufoWatcher = ufoWatcher
            end
        else
            if ufoEventConn then
                ufoEventConn:Disconnect()
                ufoEventConn = nil
            end
            if getgenv()._ufoWatcher then
                getgenv()._ufoWatcher:Disconnect()
                getgenv()._ufoWatcher = nil
            end
        end
    end
})

SectionMisc:AddToggle({
    Title = "Hide Join Event Notifs",
    Default = false,
    Flag = "HideEventNotifs",
    Callback = function(value)
        Notify("🔕 Hide Event Notifs", value and "Enabled" or "Disabled")
    if value then
        task.spawn(function()
            while Options.HideEventNotifs.Value and not isUnloaded do
                pcall(function()
                    local searchRoots = {
                        game:GetService("CoreGui"):FindFirstChild("RobloxGui"),
                        localPlayer:FindFirstChild("PlayerGui")
                    }
                    for _, root in pairs(searchRoots) do
                        if not root then continue end
                        for _, v in pairs(root:GetDescendants()) do
                            if v:IsA("TextLabel") then
                                local text = string.lower(v.Text or "")
                                if string.find(text, "join event") then
                                    local current = v
                                    local topFrame = nil
                                    while current and current.Parent do
                                        local parent = current.Parent
                                        if parent:IsA("ScreenGui") or parent:IsA("CoreGui") or parent == root then
                                            topFrame = current
                                            break
                                        end
                                        current = parent
                                    end
                                    if topFrame then
                                        topFrame.Visible = false
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.25)
            end
        end)
    end
end)

local autoFriendConn = nil

local function sendFriendRequest(player)
    if player ~= localPlayer and not localPlayer:IsFriendsWith(player.UserId) then
        local success, errorMessage = pcall(function()
            localPlayer:RequestFriendship(player)
        end)
        
        if success then
            Notify("✅ Friend Request", "Sent to " .. player.Name)
        else
            Notify("❌ Error", "Failed to send request to " .. player.Name)
        end
        
        task.wait(0.5)
    end
end

SectionMisc:AddToggle({
    Title = "Auto Friend Request",
    Default = false,
    Flag = "AutoFriendRequest",
    Callback = function(value)
        Notify("🤝 Auto Friend Request", value and "Enabled" or "Disabled")
    if value then
        task.spawn(function()
            for _, player in pairs(players:GetPlayers()) do
                if not Options.AutoFriendRequest.Value then break end
                sendFriendRequest(player)
            end
        end)
        autoFriendConn = players.PlayerAdded:Connect(function(player)
            task.wait(5)
            if Options.AutoFriendRequest.Value then
                sendFriendRequest(player)
            end
        end)
    else
        if autoFriendConn then
            autoFriendConn:Disconnect()
            autoFriendConn = nil
        end
    end
end)

local PotionKeyMap = {
    ["Luck"]       = "luck",
    ["Ultra Luck"] = "ultraLuck",
    ["Coins"]      = "currency",
    ["Roll Speed"] = "rollSpeed",
}

local DiceKeyMap = {
    ["Shiny Dice"] = "shinyDice",
    ["Big Dice"] = "bigDice",
    ["Huge Dice"] = "hugeDice",
    ["Inverted Dice"] = "invertedDice",
    ["Jackpot Spin"] = "jackpotSpin"
}

local selectedItems = {
    luck = false, ultraLuck = false, currency = false, rollSpeed = false,
    shinyDice = false, bigDice = false, hugeDice = false, invertedDice = false, jackpotSpin = false
}

function ConsumePotions()
    for label, key in pairs(PotionKeyMap) do
        if selectedItems[key] then
            task.spawn(function()
                pcall(function()
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("BoostService"):WaitForChild("RemoteFunction"):InvokeServer("requestUseBoost", key)
                end)
            end)
        end
    end
end

function ConsumeDice()
    for label, key in pairs(DiceKeyMap) do
        if selectedItems[key] then
            task.spawn(function()
                pcall(function()
                    InventoryRemote:InvokeServer("requestUseItem", key)
                end)
            end)
        end
    end
end

local InventoryRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("InventoryService"):WaitForChild("RemoteFunction")

local SectionPotions = Tabs.Items:AddSection("Potions")

SectionPotions:AddToggle({
    Title = "Auto Use Potions",
    Default = false,
    Flag = "AutoUsePotions",
    Callback = function(value)
        Notify("🧪 Auto Use Potions", value and "Enabled" or "Disabled")
        if value then
            task.spawn(function()
                while Options.AutoUsePotions.Value and not isUnloaded do
                    ConsumePotions()
                    task.wait(180)
                end
            end)
        end
    end
})

SectionPotions:AddDropdown({
    Title = "Potions to Use",
    Values = { "Luck", "Ultra Luck", "Coins", "Roll Speed" },
    Multi = true,
    Default = {},
    Flag = "PotionsDropdown",
    Callback = function(value)
        for label, key in pairs(PotionKeyMap) do
            selectedItems[key] = value[label] == true
        end
    end
})

local SectionDice = Tabs.Items:AddSection("Dice")

SectionDice:AddToggle({
    Title = "Auto Use Dice",
    Default = false,
    Flag = "AutoUseDice",
    Callback = function(value)
        Notify("🎲 Auto Use Dice", value and "Enabled" or "Disabled")
        if value then
            task.spawn(function()
                while Options.AutoUseDice.Value and not isUnloaded do
                    ConsumeDice()
                    local ok, spd = pcall(function()
                    return game:GetService("Players").LocalPlayer.PlayerGui.Root.BottomBarStats.StatsList.RollSpeedStat.Content.Value.TextLabel.Text
                end)
                local speed = 1
                if ok and spd then
                    local v = tonumber(string.match(spd, "[%d%.]+"))
                    if v and v > 0 then speed = v end
                end
                task.wait(speed)
            end
        end)
    end
end)

SectionDice:AddDropdown({
    Title = "Dice to Use",
    Values = { "Shiny Dice", "Big Dice", "Huge Dice", "Inverted Dice", "Jackpot Spin" },
    Multi = true,
    Default = {},
    Flag = "DiceDropdown",
    Callback = function(value)
        for label, key in pairs(DiceKeyMap) do
            selectedItems[key] = value[label] == true
        end
    end
})

local SlimeGunRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("SlimeGunService"):WaitForChild("RemoteFunction")

local function clearSlimeGunNotifications()
    pcall(function()
        local uiParent = (gethui and gethui()) or game:GetService("CoreGui")
        for _, v in pairs(uiParent:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "🎯 Slime Gun" then
                local current = v
                local targetToDestroy = nil
                while current and current.Parent do
                    if current.Parent.Name == "Notifications" or current.Parent:IsA("ScreenGui") then
                        targetToDestroy = current
                        break
                    end
                    current = current.Parent
                end
                if targetToDestroy and targetToDestroy:IsA("Frame") then
                    targetToDestroy:Destroy()
                end
            end
        end
    end)
end

local currentSlimeTarget = nil

local SectionCombat = Tabs.Combat:AddSection("Combat")

SectionCombat:AddToggle({
    Title = "Auto Slime Gun",
    Default = false,
    Flag = "AutoSlimeGun",
    Callback = function(value)
        Notify("🔫 Auto Slime Gun", value and "Enabled" or "Disabled")
        if value then
            task.spawn(function()
                local lastTarget = nil
                while Options.AutoSlimeGun.Value and not isUnloaded do
                    pcall(function()
                    local enemiesFolder = nil
                    for _, child in ipairs(workspace:GetChildren()) do
                        if string.match(child.Name, "^Gameplay%d+") then
                            local e = child:FindFirstChild("Enemies")
                            if e then
                                enemiesFolder = e
                                break
                            end
                        end
                    end
                    
                    if enemiesFolder then
                        local enemiesList = enemiesFolder:GetChildren()
                        if #enemiesList > 0 then
                            local playerHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local targetEnemy = nil
                            if lastTarget and lastTarget.Parent == enemiesFolder then
                                targetEnemy = lastTarget
                            else
                                local closestDist = math.huge
                                for _, enemy in ipairs(enemiesList) do
                                    local enemyHRP = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
                                    if enemyHRP and playerHRP then
                                        local dist = (playerHRP.Position - enemyHRP.Position).Magnitude
                                        if dist < closestDist then
                                            closestDist = dist
                                            targetEnemy = enemy
                                        end
                                    end
                                end
                                if not targetEnemy then targetEnemy = enemiesList[1] end
                            end
                            currentSlimeTarget = targetEnemy
                            SlimeGunRemote:InvokeServer("tryFireSlimeGun", tonumber(targetEnemy.Name))
                            if lastTarget ~= targetEnemy then
                                clearSlimeGunNotifications()
                                
                                local details = "🔫 Target: " .. targetEnemy.Name
                                pcall(function()
                                    local hum = targetEnemy:FindFirstChildWhichIsA("Humanoid")
                                    if hum then
                                        details = details .. string.format("\n❤️ Health: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
                                    end
                                    
                                    local playerHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    local enemyHRP = targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy.PrimaryPart
                                    if playerHRP and enemyHRP then
                                        local dist = (playerHRP.Position - enemyHRP.Position).Magnitude
                                        details = details .. string.format("\n📏 Distance: %d studs", math.floor(dist))
                                    end
                                end)
                                
                                if Options.AutoSlimeGunNotifs.Value then
                                    Notify("🎯 Slime Gun", details)
                                end
                                lastTarget = targetEnemy
                            end
                        else
                            lastTarget = nil
                            currentSlimeTarget = nil
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

SectionCombat:AddToggle({
    Title = "Auto Slime Gun Notifications",
    Default = true,
    Flag = "AutoSlimeGunNotifs",
    Callback = function(value)
        Notify("🔔 Slime Gun Notifications", value and "Enabled" or "Disabled")
    end
})

SectionCombat:AddToggle({
    Title = "Slime ESP",
    Default = false,
    Flag = "SlimeESP",
    Callback = function(value)
        Notify("👁️ Slime ESP", value and "Enabled" or "Disabled")
        if value then
            task.spawn(function()
            while Options.SlimeESP.Value and not isUnloaded do
                pcall(function()
                    local enemiesFolder = nil
                    for _, child in ipairs(workspace:GetChildren()) do
                        if string.match(child.Name, "^Gameplay%d+") then
                            local e = child:FindFirstChild("Enemies")
                            if e then
                                enemiesFolder = e
                                break
                            end
                        end
                    end
                    
                    if enemiesFolder then
                        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                            local hl = enemy:FindFirstChild("SlimeESP_Highlight")
                            if not hl then
                                hl = Instance.new("Highlight")
                                hl.Name = "SlimeESP_Highlight"
                                hl.FillColor = Color3.fromRGB(0, 255, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.5
                                hl.OutlineTransparency = 0
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Adornee = enemy
                                hl.Parent = enemy
                            end
                            
                            if enemy == currentSlimeTarget then
                                hl.FillColor = Color3.fromRGB(255, 0, 0)
                            else
                                hl.FillColor = Color3.fromRGB(0, 255, 0)
                            end
                            
                            if not enemy:FindFirstChild("SlimeESP_Text") then
                                local bgui = Instance.new("BillboardGui")
                                bgui.Name = "SlimeESP_Text"
                                bgui.AlwaysOnTop = true
                                bgui.Size = UDim2.new(0, 100, 0, 30)
                                bgui.StudsOffset = Vector3.new(0, 3, 0)
                                
                                local label = Instance.new("TextLabel")
                                label.Size = UDim2.new(1, 0, 1, 0)
                                label.BackgroundTransparency = 1
                                label.Text = enemy.Name
                                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                label.TextStrokeTransparency = 0
                                label.Font = Enum.Font.GothamBold
                                label.TextSize = 14
                                label.Parent = bgui
                                
                                bgui.Adornee = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("Part") or enemy
                                bgui.Parent = enemy
                            end
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    else
        pcall(function()
            local enemiesFolder = nil
            for _, child in ipairs(workspace:GetChildren()) do
                if string.match(child.Name, "^Gameplay%d+") then
                    local e = child:FindFirstChild("Enemies")
                    if e then
                        enemiesFolder = e
                        break
                    end
                end
            end
            if enemiesFolder then
                for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                    local hl = enemy:FindFirstChild("SlimeESP_Highlight")
                    if hl then hl:Destroy() end
                    
                    local txt = enemy:FindFirstChild("SlimeESP_Text")
                    if txt then txt:Destroy() end
                end
            end
        end)
    end
end)

local SectionUpgrades = Tabs.Upgrades:AddSection("Upgrades Automation")

SectionUpgrades:AddToggle({
    Title = "Auto Buy Upgrades",
    Default = false,
    Flag = "AutoBuyUpgrades",
    Callback = function(value)
        Notify("⬆️ Auto Buy Upgrades", value and "Enabled" or "Disabled")
        if value then
            task.spawn(function()
                while Options.AutoBuyUpgrades.Value and not isUnloaded do
                    pcall(function()
                        local data = playerDataClient:get()
                        local ownedUpgrades = data.upgrades or {}
                        
                        for _, Upgrades in next, UpgradeTree do
                            for _, Tiles in next, Upgrades do
                                if Tiles.cost and not UpgradeUtils.ownsUpgrade(Tiles.id, ownedUpgrades) and (data[Tiles.cost.currency] or 0) >= Tiles.cost.amount then
                                    task.spawn(function()
                                        pcall(function() BuyUpgrade:InvokeServer("requestUnlock", Tiles.id) end)
                                    end)
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})

SectionUpgrades:AddToggle({
    Title = "Auto Buy Zone",
    Default = false,
    Flag = "AutoBuyZone",
    Callback = function(value)
        Notify("🔓 Auto Buy Zone", value and "Enabled" or "Disabled")
        if value then
            task.spawn(function()
                while Options.AutoBuyZone.Value and not isUnloaded do
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("ZonesService"):WaitForChild("RemoteFunction"):InvokeServer("requestPurchaseZone")
                    task.wait(5)
                end
            end)
        end
    end
})

local SectionRebirth = Tabs.Upgrades:AddSection("Rebirth & Inventory")

SectionRebirth:AddToggle({
    Title = "Auto Rebirth",
    Default = false,
    Flag = "AutoRebirth",
    Callback = function(value)
        Notify("♻️ Auto Rebirth", value and "Enabled" or "Disabled")
        if value then
            task.spawn(function()
                while Options.AutoRebirth.Value and not isUnloaded do
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("RebirthService"):WaitForChild("RemoteFunction"):InvokeServer("requestRebirth")
                    task.wait(5)
                end
            end)
        end
    end
})

SectionRebirth:AddToggle({
    Title = "Auto Equip Best",
    Default = false,
    Flag = "AutoEquipBest",
    Callback = function(value)
        Notify("⚔️ Auto Equip Best", value and "Enabled" or "Disabled")
        if value then
            task.spawn(function()
                while Options.AutoEquipBest.Value and not isUnloaded do
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("InventoryService"):WaitForChild("RemoteFunction"):InvokeServer("requestEquipBest")
                    task.wait(10)
                end
            end)
        end
    end
})

local SectionInfo = Tabs.Settings:AddSection("Information")

SectionInfo:AddButton({
    Title = "Copy Discord Link",
    Description = "Copies the Discord invite link to your clipboard",
    Callback = function()
        setclipboard("https://discord.gg/cuz")
        Notify("📋 Discord", "Link copied to clipboard!")
    end
})

local autoBestZoneThread = nil
local walkingThread = nil

local function getBestZoneInfo()
    local zones = workspace.Zones and workspace.Zones:GetChildren() or {}
    local counter = 0
    for _, zone in pairs(zones) do
        local blockerName = "ClientGateBlocker_" .. zone.Name
        local gate = zone:FindFirstChild("Gate") and zone.Gate:FindFirstChild(blockerName)
        if gate and gate.CanCollide ~= true then
            local n = tonumber(zone.Name)
            if n and n > counter then counter = n end
        end
    end
    local bestNum = counter + 1
    local bestModel = workspace.Zones:FindFirstChild(tostring(bestNum))
    local bestPos = nil
    if bestModel then
        local spawn = bestModel:FindFirstChild("Spawn")
            or bestModel:FindFirstChild("SpawnLocation")
            or bestModel:FindFirstChild("Teleport")
        bestPos = spawn and spawn.Position or bestModel:GetBoundingBox().Position
    end
    return bestNum, bestPos, bestModel
end

local ZONE_RADIUS = 120
local function isInBestZone(charPos)
    local _, bestPos, _ = getBestZoneInfo()
    if not bestPos or not charPos then return true end
    return (charPos - bestPos).Magnitude <= ZONE_RADIUS
end

local function doTeleportBestZone(bestZone)
    local args = { "requestTeleportZone", bestZone }
    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("ZonesService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
end

function TeleportBestZone()
    local zones = workspace.Zones:GetChildren()
    local returnZones = {}
    for _, zone in pairs(zones) do
        local blockerName = "ClientGateBlocker_" .. zone.Name
        local gate = zone.Gate:FindFirstChild(blockerName)
        if gate then table.insert(returnZones, gate) end
    end
    local counter = 0
    for _, gateBlocker in pairs(returnZones) do
        if gateBlocker.CanCollide ~= true then
            if tonumber(gateBlocker.Parent.Parent.Name) > counter then
                counter = tonumber(gateBlocker.Parent.Parent.Name)
            end
        end
    end
    local bestZone = counter + 1
    
    local inBestZone = false
    local charPos = nil
    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        charPos = localPlayer.Character.HumanoidRootPart.Position
    elseif clientHRP then
        charPos = clientHRP.Position
    end

    if charPos then
        local closestZone = nil
        local closestDist = math.huge
        
        for _, zone in pairs(zones) do
            if tonumber(zone.Name) then
                local cf = zone:GetBoundingBox()
                local dist = (cf.Position - charPos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestZone = tonumber(zone.Name)
                end
            end
        end
        
        if closestZone == bestZone then
            inBestZone = true
        end
    end
    
    if not inBestZone then
        if zoneNavMode == "Walk" then
            local bestZoneModel = workspace.Zones:FindFirstChild(tostring(bestZone))
            local hum = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid")
            if bestZoneModel and hum then
                local targetPos = bestZoneModel:GetBoundingBox().Position
                local spawnPart = bestZoneModel:FindFirstChild("Spawn") or bestZoneModel:FindFirstChild("SpawnLocation") or bestZoneModel:FindFirstChild("Teleport")
                if spawnPart then targetPos = spawnPart.Position end
                
                if walkingThread then task.cancel(walkingThread) end
                walkingThread = task.spawn(function()
                    local lastPos = hum.RootPart and hum.RootPart.Position
                    local stuckTimer = 0
                    while not isUnloaded and Options.AutoTeleportBestZone.Value and zoneNavMode == "Walk" do
                        local currentPos = hum.RootPart and hum.RootPart.Position
                        if not currentPos then break end
                        if (currentPos - targetPos).Magnitude < 15 then break end
                        
                        if lastPos and (currentPos - lastPos).Magnitude < 1 then
                            stuckTimer = stuckTimer + 1
                            if stuckTimer >= 5 then
                                doTeleportBestZone(bestZone)
                                break
                            end
                        else
                            stuckTimer = 0
                        end
                        lastPos = currentPos
                        hum:MoveTo(targetPos)
                        task.wait(1)
                    end
                end)
            end
        else
            if walkingThread then task.cancel(walkingThread); walkingThread = nil end
            doTeleportBestZone(bestZone)
        end
    else
        if walkingThread then task.cancel(walkingThread); walkingThread = nil end
    end
end

function ClaimIndex()
    local rewards = { "basic", "big", "huge", "shiny", "inverted" }
    for _, reward in ipairs(rewards) do
        local args = { "requestClaimReward", reward }
        task.spawn(function()
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("IndexService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
            end)
        end)
    end
end

Window:SelectTab(1)

Window:Notify({
    Title = "Plink Slime RNG",
    Message = "Script successfully loaded! Press Right Control to toggle.",
    Duration = 8
})

task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    local promptOverlay = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
    if promptOverlay then
        promptOverlay = promptOverlay:FindFirstChild("promptOverlay")
    end

    local function onDisconnect()
        if isUnloaded then return end
        task.wait(5)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, localPlayer)
        end)
    end

    GuiService.ErrorMessageChanged:Connect(function()
        onDisconnect()
    end)
    
    if promptOverlay then
        promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                onDisconnect()
            end
        end)
    end
end)
