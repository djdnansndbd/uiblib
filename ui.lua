local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- Global cleanup for re-execution
if _G.uiHub_Unload then
    pcall(_G.uiHub_Unload)
end

local Connections = {}
_G.uiHub_Unload = function()
    for _, c in pairs(Connections) do
        c:Disconnect()
    end
    table.clear(Connections)
    local success, err = pcall(function()
        if CoreGui:FindFirstChild("uiHub") then
            CoreGui.uiHub:Destroy()
        end
    end)
    if Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("uiHub") then
        Players.LocalPlayer.PlayerGui.uiHub:Destroy()
    end
end

local Library = {}

-- [[ Premium Midnight Blue-Grey Theme ]] --
local Theme = {
    MainBackground = Color3.fromRGB(15, 15, 20),      -- Deep Midnight Blue-Grey
    TabBackground = Color3.fromRGB(20, 20, 26),       -- Slightly Lighter
    SectionBackground = Color3.fromRGB(25, 25, 32),   -- Panels & Base elements
    ElementBackground = Color3.fromRGB(32, 32, 42),   -- Interactables
    HoverElement = Color3.fromRGB(45, 45, 58),        -- Hover state
    Accent = Color3.fromRGB(255, 50, 70),             -- Vibrant Crimson Red
    Text = Color3.fromRGB(245, 245, 250),             -- Crisp White
    TextDark = Color3.fromRGB(160, 160, 170),         -- Muted Grey
    Shadow = Color3.fromRGB(0, 0, 0)
}

local UI_CORNER_RADIUS = UDim.new(0, 6)
local WINDOW_CORNER_RADIUS = UDim.new(0, 8)
local GLASS_TRANSPARENCY = 0.15

-- [[ Utility: Draggable Window ]] --
local function MakeDraggable(topbar, main)
    local dragging = false
    local dragInput, mousePos, framePos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            main.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end))
end

-- [[ Library Initialization ]] --
function Library:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "uiHub"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    -- Safe execution environment check
    local success, err = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not success then
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Wrapper Frame (Holds position and sizing for both shadow and content)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainWrapper"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundTransparency = 1
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
    MainFrame.Size = UDim2.new(0, 550, 0, 380)

    -- Custom Drop Shadow
    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"
    Shadow.Parent = MainFrame
    Shadow.BackgroundColor3 = Theme.Shadow
    Shadow.BackgroundTransparency = 0.5
    Shadow.Position = UDim2.new(0, 0, 0, 10) -- Drop downwards
    Shadow.Size = UDim2.new(1, 0, 1, 0)
    Shadow.ZIndex = 0
    
    local ShadowCorner = Instance.new("UICorner")
    ShadowCorner.CornerRadius = WINDOW_CORNER_RADIUS
    ShadowCorner.Parent = Shadow

    -- Window Content (The actual UI)
    local WindowContent = Instance.new("Frame")
    WindowContent.Name = "WindowContent"
    WindowContent.Parent = MainFrame
    WindowContent.BackgroundColor3 = Theme.MainBackground
    WindowContent.BackgroundTransparency = GLASS_TRANSPARENCY
    WindowContent.Size = UDim2.new(1, 0, 1, 0)
    WindowContent.ClipsDescendants = true
    WindowContent.ZIndex = 1

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = WINDOW_CORNER_RADIUS
    MainCorner.Parent = WindowContent
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Parent = WindowContent
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Theme.SectionBackground
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.3

    -- Topbar
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Parent = WindowContent
    Topbar.BackgroundColor3 = Theme.TabBackground
    Topbar.BackgroundTransparency = GLASS_TRANSPARENCY
    Topbar.Size = UDim2.new(1, 0, 0, 40)
    Topbar.ZIndex = 2
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = WINDOW_CORNER_RADIUS
    TopbarCorner.Parent = Topbar
    
    -- Hide bottom corners of topbar to merge seamlessly
    local TopbarExtension = Instance.new("Frame")
    TopbarExtension.Name = "Extension"
    TopbarExtension.Parent = Topbar
    TopbarExtension.BackgroundColor3 = Theme.TabBackground
    TopbarExtension.BackgroundTransparency = GLASS_TRANSPARENCY
    TopbarExtension.Position = UDim2.new(0, 0, 1, -10)
    TopbarExtension.Size = UDim2.new(1, 0, 0, 10)
    TopbarExtension.BorderSizePixel = 0
    TopbarExtension.ZIndex = 2

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Parent = Topbar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.Text = title or "UI Hub"
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 3

    MakeDraggable(Topbar, MainFrame)

    -- Accent Line (The Crimson Stripe)
    local AccentLine = Instance.new("Frame")
    AccentLine.Name = "AccentLine"
    AccentLine.Parent = WindowContent
    AccentLine.BackgroundColor3 = Theme.Accent
    AccentLine.Position = UDim2.new(0, 0, 0, 40)
    AccentLine.Size = UDim2.new(1, 0, 0, 2)
    AccentLine.BorderSizePixel = 0
    AccentLine.ZIndex = 3

    -- Tabs Container (Left Side)
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Parent = WindowContent
    TabsContainer.BackgroundColor3 = Theme.TabBackground
    TabsContainer.BackgroundTransparency = GLASS_TRANSPARENCY
    TabsContainer.Position = UDim2.new(0, 0, 0, 42)
    TabsContainer.Size = UDim2.new(0, 140, 1, -42)
    TabsContainer.BorderSizePixel = 0
    TabsContainer.ZIndex = 2
    
    local TabContainerSeparator = Instance.new("Frame")
    TabContainerSeparator.Name = "Separator"
    TabContainerSeparator.Parent = WindowContent
    TabContainerSeparator.BackgroundColor3 = Theme.SectionBackground
    TabContainerSeparator.Position = UDim2.new(0, 140, 0, 42)
    TabContainerSeparator.Size = UDim2.new(0, 1, 1, -42)
    TabContainerSeparator.BorderSizePixel = 0
    TabContainerSeparator.ZIndex = 3

    local TabList = Instance.new("UIListLayout")
    TabList.Parent = TabsContainer
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 6)
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.Parent = TabsContainer
    TabPadding.PaddingTop = UDim.new(0, 12)
    TabPadding.PaddingBottom = UDim.new(0, 12)

    -- Content Container (Right Side)
    -- We use a CanvasGroup to allow fading transitions between tabs
    local ContentContainer = Instance.new("CanvasGroup")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Parent = WindowContent
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 145, 0, 42)
    ContentContainer.Size = UDim2.new(1, -145, 1, -42)
    ContentContainer.ZIndex = 2

    -- Notifications Container (Bottom Right)
    local NotifContainer = Instance.new("Frame")
    NotifContainer.Name = "NotifContainer"
    NotifContainer.Parent = ScreenGui
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.Position = UDim2.new(1, -270, 0, 0)
    NotifContainer.Size = UDim2.new(0, 250, 1, -20)
    
    local NotifList = Instance.new("UIListLayout")
    NotifList.Parent = NotifContainer
    NotifList.SortOrder = Enum.SortOrder.LayoutOrder
    NotifList.Padding = UDim.new(0, 10)
    NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifList.HorizontalAlignment = Enum.HorizontalAlignment.Right

    -- [[ Global Notify Function ]] --
    function Library:Notify(options)
        local title = options.Title or "Notification"
        local text = options.Text or "..."
        local duration = options.Duration or 3

        local NotifFrame = Instance.new("Frame")
        NotifFrame.Name = "Notif_" .. title
        NotifFrame.Parent = NotifContainer
        NotifFrame.BackgroundColor3 = Theme.MainBackground
        NotifFrame.BackgroundTransparency = GLASS_TRANSPARENCY
        NotifFrame.Size = UDim2.new(0, 250, 0, 60)
        NotifFrame.Position = UDim2.new(1, 10, 0, 0)

        local NotifCorner = Instance.new("UICorner")
        NotifCorner.CornerRadius = WINDOW_CORNER_RADIUS
        NotifCorner.Parent = NotifFrame
        
        local UIStroke = Instance.new("UIStroke")
        UIStroke.Parent = NotifFrame
        UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        UIStroke.Color = Theme.SectionBackground
        UIStroke.Thickness = 1
        UIStroke.Transparency = 0.3

        local AccentStripe = Instance.new("Frame")
        AccentStripe.Name = "Accent"
        AccentStripe.Parent = NotifFrame
        AccentStripe.BackgroundColor3 = Theme.Accent
        AccentStripe.Size = UDim2.new(0, 3, 1, 0)
        AccentStripe.BorderSizePixel = 0
        
        local AccentCorner = Instance.new("UICorner")
        AccentCorner.CornerRadius = WINDOW_CORNER_RADIUS
        AccentCorner.Parent = AccentStripe
        
        local AccentHide = Instance.new("Frame")
        AccentHide.Parent = AccentStripe
        AccentHide.BackgroundColor3 = Theme.Accent
        AccentHide.Position = UDim2.new(1, -1, 0, 0)
        AccentHide.Size = UDim2.new(0, 1, 1, 0)
        AccentHide.BorderSizePixel = 0

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Parent = NotifFrame
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Position = UDim2.new(0, 15, 0, 5)
        TitleLabel.Size = UDim2.new(1, -20, 0, 20)
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.Text = title
        TitleLabel.TextColor3 = Theme.Text
        TitleLabel.TextSize = 14
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

        local TextLabel = Instance.new("TextLabel")
        TextLabel.Parent = NotifFrame
        TextLabel.BackgroundTransparency = 1
        TextLabel.Position = UDim2.new(0, 15, 0, 25)
        TextLabel.Size = UDim2.new(1, -20, 1, -30)
        TextLabel.Font = Enum.Font.Gotham
        TextLabel.Text = text
        TextLabel.TextColor3 = Theme.TextDark
        TextLabel.TextSize = 12
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextYAlignment = Enum.TextYAlignment.Top
        TextLabel.TextWrapped = true

        local slideIn = TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
        local slideOut = TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 0, 0)})

        slideIn:Play()

        task.spawn(function()
            task.wait(duration)
            slideOut:Play()
            slideOut.Completed:Wait()
            NotifFrame:Destroy()
        end)
    end

    local Window = {
        CurrentTab = nil
    }
    
    local isFading = false

    -- [[ Tab Creation ]] --
    function Window:CreateTab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name .. "Tab"
        TabButton.Parent = TabsContainer
        TabButton.BackgroundColor3 = Theme.ElementBackground
        TabButton.BackgroundTransparency = 1
        TabButton.Size = UDim2.new(1, -20, 0, 32)
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.Text = "   " .. name
        TabButton.TextColor3 = Theme.TextDark
        TabButton.TextSize = 13
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.AutoButtonColor = false
        
        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UI_CORNER_RADIUS
        TabButtonCorner.Parent = TabButton

        local TabIndicator = Instance.new("Frame")
        TabIndicator.Name = "Indicator"
        TabIndicator.Parent = TabButton
        TabIndicator.BackgroundColor3 = Theme.Accent
        TabIndicator.Position = UDim2.new(0, 0, 0.5, -8)
        TabIndicator.Size = UDim2.new(0, 3, 0, 16)
        TabIndicator.BackgroundTransparency = 1
        TabIndicator.BorderSizePixel = 0
        
        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(1, 0)
        IndicatorCorner.Parent = TabIndicator

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = name .. "Page"
        TabPage.Parent = ContentContainer
        TabPage.BackgroundTransparency = 1
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.ScrollBarThickness = 2
        TabPage.ScrollBarImageColor3 = Theme.Accent
        TabPage.Visible = false
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)

        local PageList = Instance.new("UIListLayout")
        PageList.Parent = TabPage
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Padding = UDim.new(0, 10)
        
        local PagePadding = Instance.new("UIPadding")
        PagePadding.Parent = TabPage
        PagePadding.PaddingTop = UDim.new(0, 15)
        PagePadding.PaddingBottom = UDim.new(0, 15)
        PagePadding.PaddingLeft = UDim.new(0, 10)
        PagePadding.PaddingRight = UDim.new(0, 15)

        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 30)
        end)

        TabButton.MouseButton1Click:Connect(function()
            if Window.CurrentTab == TabPage or isFading then return end
            isFading = true
            
            -- Smooth fade out
            local fadeOut = TweenService:Create(ContentContainer, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
            fadeOut:Play()
            fadeOut.Completed:Wait()

            if Window.CurrentTab then
                Window.CurrentTab.Page.Visible = false
                TweenService:Create(Window.CurrentTab.Button, TweenInfo.new(0.3), {TextColor3 = Theme.TextDark, BackgroundTransparency = 1}):Play()
                TweenService:Create(Window.CurrentTab.Indicator, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            end
            
            Window.CurrentTab = {Page = TabPage, Button = TabButton, Indicator = TabIndicator}
            TabPage.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {TextColor3 = Theme.Text, BackgroundTransparency = 0}):Play()
            TweenService:Create(TabIndicator, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            
            -- Smooth fade in
            local fadeIn = TweenService:Create(ContentContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 0})
            fadeIn:Play()
            fadeIn.Completed:Wait()
            
            isFading = false
        end)

        if not Window.CurrentTab then
            Window.CurrentTab = {Page = TabPage, Button = TabButton, Indicator = TabIndicator}
            TabPage.Visible = true
            TabButton.TextColor3 = Theme.Text
            TabButton.BackgroundTransparency = 0
            TabIndicator.BackgroundTransparency = 0
        end

        local TabMethods = {}

        -- [[ Create Section ]] --
        function TabMethods:CreateSection(sectionName)
            local SectionLabel = Instance.new("TextLabel")
            SectionLabel.Name = "Section_" .. sectionName
            SectionLabel.Parent = TabPage
            SectionLabel.BackgroundTransparency = 1
            SectionLabel.Size = UDim2.new(1, 0, 0, 25)
            SectionLabel.Font = Enum.Font.GothamBold
            SectionLabel.Text = sectionName
            SectionLabel.TextColor3 = Theme.Accent
            SectionLabel.TextSize = 14
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
        end

        -- [[ Create Label ]] --
        function TabMethods:CreateLabel(labelText)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Name = "Label_" .. labelText
            LabelFrame.Parent = TabPage
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Size = UDim2.new(1, 0, 0, 20)
            
            local LabelText = Instance.new("TextLabel")
            LabelText.Parent = LabelFrame
            LabelText.BackgroundTransparency = 1
            LabelText.Size = UDim2.new(1, -10, 1, 0)
            LabelText.Position = UDim2.new(0, 10, 0, 0)
            LabelText.Font = Enum.Font.Gotham
            LabelText.Text = labelText
            LabelText.TextColor3 = Theme.TextDark
            LabelText.TextSize = 12
            LabelText.TextXAlignment = Enum.TextXAlignment.Left
        end

        -- [[ Create Keybind ]] --
        function TabMethods:CreateKeybind(keybindText, defaultKey, callback)
            local key = defaultKey or Enum.KeyCode.E
            local binding = false

            local KeybindFrame = Instance.new("Frame")
            KeybindFrame.Name = "Keybind_" .. keybindText
            KeybindFrame.Parent = TabPage
            KeybindFrame.BackgroundColor3 = Theme.ElementBackground
            KeybindFrame.Size = UDim2.new(1, 0, 0, 36)

            local KeybindCorner = Instance.new("UICorner")
            KeybindCorner.CornerRadius = UI_CORNER_RADIUS
            KeybindCorner.Parent = KeybindFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = KeybindFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1
            UIStroke.Transparency = 0.5

            local KeybindLabel = Instance.new("TextLabel")
            KeybindLabel.Parent = KeybindFrame
            KeybindLabel.BackgroundTransparency = 1
            KeybindLabel.Position = UDim2.new(0, 10, 0, 0)
            KeybindLabel.Size = UDim2.new(1, -100, 1, 0)
            KeybindLabel.Font = Enum.Font.GothamSemibold
            KeybindLabel.Text = keybindText
            KeybindLabel.TextColor3 = Theme.Text
            KeybindLabel.TextSize = 13
            KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left

            local KeyButton = Instance.new("TextButton")
            KeyButton.Parent = KeybindFrame
            KeyButton.BackgroundColor3 = Theme.SectionBackground
            KeyButton.Position = UDim2.new(1, -90, 0.5, -12)
            KeyButton.Size = UDim2.new(0, 80, 0, 24)
            KeyButton.Font = Enum.Font.GothamBold
            KeyButton.Text = key.Name
            KeyButton.TextColor3 = Theme.Accent
            KeyButton.TextSize = 12
            KeyButton.AutoButtonColor = false

            local KeyCorner = Instance.new("UICorner")
            KeyCorner.CornerRadius = UI_CORNER_RADIUS
            KeyCorner.Parent = KeyButton
            
            local KeyStroke = Instance.new("UIStroke")
            KeyStroke.Parent = KeyButton
            KeyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            KeyStroke.Color = Theme.SectionBackground
            KeyStroke.Thickness = 1

            KeyButton.MouseEnter:Connect(function()
                if not binding then
                    TweenService:Create(KeyButton, TweenInfo.new(0.2), {BackgroundColor3 = Theme.HoverElement}):Play()
                    TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
                end
            end)
            KeyButton.MouseLeave:Connect(function()
                if not binding then
                    TweenService:Create(KeyButton, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SectionBackground}):Play()
                    TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground}):Play()
                end
            end)

            KeyButton.MouseButton1Click:Connect(function()
                binding = true
                KeyButton.Text = "..."
                TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
            end)

            table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed then
                    if binding then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode
                            KeyButton.Text = key.Name
                            binding = false
                            TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground}):Play()
                            TweenService:Create(KeyButton, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SectionBackground}):Play()
                        end
                    elseif input.KeyCode == key then
                        if callback then pcall(callback, key) end
                    end
                end
            end))
        end

        -- [[ Create Standard Dropdown ]] --
        function TabMethods:CreateDropdown(dropdownText, options, callback)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = "Dropdown_" .. dropdownText
            DropdownFrame.Parent = TabPage
            DropdownFrame.BackgroundColor3 = Theme.ElementBackground
            DropdownFrame.Size = UDim2.new(1, 0, 0, 36)
            DropdownFrame.ClipsDescendants = true

            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UI_CORNER_RADIUS
            DropdownCorner.Parent = DropdownFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = DropdownFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1
            UIStroke.Transparency = 0.5

            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Parent = DropdownFrame
            DropdownButton.BackgroundColor3 = Theme.ElementBackground
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Size = UDim2.new(1, 0, 0, 36)
            DropdownButton.Font = Enum.Font.GothamSemibold
            DropdownButton.Text = ""
            DropdownButton.AutoButtonColor = false

            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Parent = DropdownFrame
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
            DropdownLabel.Size = UDim2.new(1, -40, 0, 36)
            DropdownLabel.Font = Enum.Font.GothamSemibold
            DropdownLabel.Text = dropdownText .. " : None"
            DropdownLabel.TextColor3 = Theme.Text
            DropdownLabel.TextSize = 13
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local ArrowLabel = Instance.new("TextLabel")
            ArrowLabel.Parent = DropdownFrame
            ArrowLabel.BackgroundTransparency = 1
            ArrowLabel.Position = UDim2.new(1, -30, 0, 0)
            ArrowLabel.Size = UDim2.new(0, 20, 0, 36)
            ArrowLabel.Font = Enum.Font.GothamSemibold
            ArrowLabel.Text = "+"
            ArrowLabel.TextColor3 = Theme.Text
            ArrowLabel.TextSize = 16

            local ListContainer = Instance.new("ScrollingFrame")
            ListContainer.Parent = DropdownFrame
            ListContainer.BackgroundTransparency = 1
            ListContainer.Position = UDim2.new(0, 0, 0, 40)
            ListContainer.Size = UDim2.new(1, 0, 1, -40)
            ListContainer.ScrollBarThickness = 2
            ListContainer.ScrollBarImageColor3 = Theme.Accent
            ListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
            
            local ListLayout = Instance.new("UIListLayout")
            ListLayout.Parent = ListContainer
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Padding = UDim.new(0, 4)

            local ListPadding = Instance.new("UIPadding")
            ListPadding.Parent = ListContainer
            ListPadding.PaddingTop = UDim.new(0, 4)
            ListPadding.PaddingBottom = UDim.new(0, 4)
            ListPadding.PaddingLeft = UDim.new(0, 10)
            ListPadding.PaddingRight = UDim.new(0, 10)

            local isOpen = false
            
            DropdownButton.MouseEnter:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Transparency = 0}):Play()
            end)
            DropdownButton.MouseLeave:Connect(function()
                if not isOpen then
                    TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
                end
            end)

            DropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                ArrowLabel.Text = isOpen and "-" or "+"
                local targetSize = isOpen and UDim2.new(1, 0, 0, math.min(150, 40 + ListLayout.AbsoluteContentSize.Y + 8)) or UDim2.new(1, 0, 0, 36)
                TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
                
                if not isOpen then
                    TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
                end
            end)

            for _, opt in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Parent = ListContainer
                OptBtn.BackgroundColor3 = Theme.SectionBackground
                OptBtn.Size = UDim2.new(1, 0, 0, 30)
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.Text = "   " .. opt
                OptBtn.TextColor3 = Theme.Text
                OptBtn.TextSize = 12
                OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptBtn.AutoButtonColor = false
                
                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UI_CORNER_RADIUS
                BtnCorner.Parent = OptBtn

                OptBtn.MouseEnter:Connect(function()
                    TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.HoverElement}):Play()
                end)
                OptBtn.MouseLeave:Connect(function()
                    TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SectionBackground}):Play()
                end)
                
                OptBtn.MouseButton1Click:Connect(function()
                    DropdownLabel.Text = dropdownText .. " : " .. opt
                    isOpen = false
                    ArrowLabel.Text = "+"
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 36)}):Play()
                    TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
                    if callback then pcall(callback, opt) end
                end)
            end

            ListContainer.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
        end

        -- [[ Create Button ]] --
        function TabMethods:CreateButton(buttonText, callback)
            local Button = Instance.new("TextButton")
            Button.Name = "Button_" .. buttonText
            Button.Parent = TabPage
            Button.BackgroundColor3 = Theme.ElementBackground
            Button.Size = UDim2.new(1, 0, 0, 36)
            Button.Font = Enum.Font.GothamSemibold
            Button.Text = buttonText
            Button.TextColor3 = Theme.Text
            Button.TextSize = 13
            Button.AutoButtonColor = false

            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UI_CORNER_RADIUS
            ButtonCorner.Parent = Button
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = Button
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1
            UIStroke.Transparency = 0.5

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.HoverElement}):Play()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Transparency = 0}):Play()
            end)

            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBackground}):Play()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
            end)

            Button.MouseButton1Down:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
            end)

            Button.MouseButton1Up:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Theme.HoverElement}):Play()
            end)

            Button.MouseButton1Click:Connect(function()
                if callback then pcall(callback) end
            end)
        end

        -- [[ Create Toggle ]] --
        function TabMethods:CreateToggle(toggleText, default, callback)
            local state = default or false
            
            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Name = "Toggle_" .. toggleText
            ToggleFrame.Parent = TabPage
            ToggleFrame.BackgroundColor3 = Theme.ElementBackground
            ToggleFrame.Size = UDim2.new(1, 0, 0, 36)
            ToggleFrame.Text = ""
            ToggleFrame.AutoButtonColor = false

            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UI_CORNER_RADIUS
            ToggleCorner.Parent = ToggleFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = ToggleFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1
            UIStroke.Transparency = 0.5

            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Parent = ToggleFrame
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Font = Enum.Font.GothamSemibold
            ToggleLabel.Text = toggleText
            ToggleLabel.TextColor3 = Theme.Text
            ToggleLabel.TextSize = 13
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

            local ToggleIndicator = Instance.new("Frame")
            ToggleIndicator.Parent = ToggleFrame
            ToggleIndicator.BackgroundColor3 = state and Theme.Accent or Theme.SectionBackground
            ToggleIndicator.Position = UDim2.new(1, -45, 0.5, -10)
            ToggleIndicator.Size = UDim2.new(0, 34, 0, 20)
            
            local IndCorner = Instance.new("UICorner")
            IndCorner.CornerRadius = UDim.new(1, 0)
            IndCorner.Parent = ToggleIndicator

            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Parent = ToggleIndicator
            ToggleCircle.BackgroundColor3 = Theme.Text
            ToggleCircle.Position = UDim2.new(state and 1 or 0, state and -18 or 2, 0.5, -8)
            ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
            
            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = ToggleCircle
            
            ToggleFrame.MouseEnter:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Transparency = 0}):Play()
            end)

            ToggleFrame.MouseLeave:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
            end)

            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                if callback then pcall(callback, state) end
                
                TweenService:Create(ToggleIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = state and Theme.Accent or Theme.SectionBackground}):Play()
                TweenService:Create(ToggleCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(state and 1 or 0, state and -18 or 2, 0.5, -8)}):Play()
            end)
        end

        -- [[ Create Textbox ]] --
        function TabMethods:CreateTextbox(boxText, placeholder, callback)
            local BoxFrame = Instance.new("Frame")
            BoxFrame.Name = "Textbox_" .. boxText
            BoxFrame.Parent = TabPage
            BoxFrame.BackgroundColor3 = Theme.ElementBackground
            BoxFrame.Size = UDim2.new(1, 0, 0, 36)

            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UI_CORNER_RADIUS
            BoxCorner.Parent = BoxFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = BoxFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1
            UIStroke.Transparency = 0.5

            local BoxLabel = Instance.new("TextLabel")
            BoxLabel.Parent = BoxFrame
            BoxLabel.BackgroundTransparency = 1
            BoxLabel.Position = UDim2.new(0, 10, 0, 0)
            BoxLabel.Size = UDim2.new(1, -140, 1, 0)
            BoxLabel.Font = Enum.Font.GothamSemibold
            BoxLabel.Text = boxText
            BoxLabel.TextColor3 = Theme.Text
            BoxLabel.TextSize = 13
            BoxLabel.TextXAlignment = Enum.TextXAlignment.Left

            local TextBox = Instance.new("TextBox")
            TextBox.Parent = BoxFrame
            TextBox.BackgroundColor3 = Theme.SectionBackground
            TextBox.Position = UDim2.new(1, -130, 0.5, -12)
            TextBox.Size = UDim2.new(0, 120, 0, 24)
            TextBox.Font = Enum.Font.Gotham
            TextBox.PlaceholderText = placeholder or "Input"
            TextBox.Text = ""
            TextBox.TextColor3 = Theme.Text
            TextBox.TextSize = 12
            TextBox.ClipsDescendants = true
            
            local TBCorner = Instance.new("UICorner")
            TBCorner.CornerRadius = UI_CORNER_RADIUS
            TBCorner.Parent = TextBox

            TextBox.Focused:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Transparency = 0}):Play()
            end)

            TextBox.FocusLost:Connect(function(enterPressed)
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
                if callback then
                    pcall(callback, TextBox.Text)
                end
            end)
        end

        -- [[ Create Slider ]] --
        function TabMethods:CreateSlider(sliderText, min, max, default, callback)
            local value = default or min
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = "Slider_" .. sliderText
            SliderFrame.Parent = TabPage
            SliderFrame.BackgroundColor3 = Theme.ElementBackground
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)

            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UI_CORNER_RADIUS
            SliderCorner.Parent = SliderFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = SliderFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1
            UIStroke.Transparency = 0.5

            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Parent = SliderFrame
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Position = UDim2.new(0, 10, 0, 5)
            SliderLabel.Size = UDim2.new(1, -20, 0, 20)
            SliderLabel.Font = Enum.Font.GothamSemibold
            SliderLabel.Text = sliderText
            SliderLabel.TextColor3 = Theme.Text
            SliderLabel.TextSize = 13
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Parent = SliderFrame
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Position = UDim2.new(0, 10, 0, 5)
            ValueLabel.Size = UDim2.new(1, -20, 0, 20)
            ValueLabel.Font = Enum.Font.Gotham
            ValueLabel.Text = tostring(value)
            ValueLabel.TextColor3 = Theme.TextDark
            ValueLabel.TextSize = 12
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

            local Track = Instance.new("Frame")
            Track.Parent = SliderFrame
            Track.BackgroundColor3 = Theme.SectionBackground
            Track.Position = UDim2.new(0, 10, 0, 32)
            Track.Size = UDim2.new(1, -20, 0, 6)
            
            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = Track

            local Fill = Instance.new("Frame")
            Fill.Parent = Track
            Fill.BackgroundColor3 = Theme.Accent
            Fill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
            
            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            local Dragging = false

            local function Update(input)
                local mathPos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * mathPos)
                TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(mathPos, 0, 1, 0)}):Play()
                ValueLabel.Text = tostring(value)
                if callback then pcall(callback, value) end
            end

            SliderFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Transparency = 0}):Play()
                    Update(input)
                end
            end)

            table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
                if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end))

            table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                    TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
                end
            end))
        end

        -- [[ Create Player Dropdown ]] --
        function TabMethods:CreatePlayerDropdown(dropdownText, callback)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = "Dropdown_" .. dropdownText
            DropdownFrame.Parent = TabPage
            DropdownFrame.BackgroundColor3 = Theme.ElementBackground
            DropdownFrame.Size = UDim2.new(1, 0, 0, 36)
            DropdownFrame.ClipsDescendants = true

            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UI_CORNER_RADIUS
            DropdownCorner.Parent = DropdownFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = DropdownFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1
            UIStroke.Transparency = 0.5

            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Parent = DropdownFrame
            DropdownButton.BackgroundColor3 = Theme.ElementBackground
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Size = UDim2.new(1, 0, 0, 36)
            DropdownButton.Font = Enum.Font.GothamSemibold
            DropdownButton.Text = ""
            DropdownButton.AutoButtonColor = false

            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Parent = DropdownFrame
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
            DropdownLabel.Size = UDim2.new(1, -40, 0, 36)
            DropdownLabel.Font = Enum.Font.GothamSemibold
            DropdownLabel.Text = dropdownText .. " : None"
            DropdownLabel.TextColor3 = Theme.Text
            DropdownLabel.TextSize = 13
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local ArrowLabel = Instance.new("TextLabel")
            ArrowLabel.Parent = DropdownFrame
            ArrowLabel.BackgroundTransparency = 1
            ArrowLabel.Position = UDim2.new(1, -30, 0, 0)
            ArrowLabel.Size = UDim2.new(0, 20, 0, 36)
            ArrowLabel.Font = Enum.Font.GothamSemibold
            ArrowLabel.Text = "+"
            ArrowLabel.TextColor3 = Theme.Text
            ArrowLabel.TextSize = 16

            local ListContainer = Instance.new("ScrollingFrame")
            ListContainer.Parent = DropdownFrame
            ListContainer.BackgroundTransparency = 1
            ListContainer.Position = UDim2.new(0, 0, 0, 40)
            ListContainer.Size = UDim2.new(1, 0, 1, -40)
            ListContainer.ScrollBarThickness = 2
            ListContainer.ScrollBarImageColor3 = Theme.Accent
            ListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
            
            local ListLayout = Instance.new("UIListLayout")
            ListLayout.Parent = ListContainer
            ListLayout.SortOrder = Enum.SortOrder.Name
            ListLayout.Padding = UDim.new(0, 4)

            local ListPadding = Instance.new("UIPadding")
            ListPadding.Parent = ListContainer
            ListPadding.PaddingTop = UDim.new(0, 4)
            ListPadding.PaddingBottom = UDim.new(0, 4)
            ListPadding.PaddingLeft = UDim.new(0, 10)
            ListPadding.PaddingRight = UDim.new(0, 10)

            local isOpen = false

            DropdownButton.MouseEnter:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Transparency = 0}):Play()
            end)
            DropdownButton.MouseLeave:Connect(function()
                if not isOpen then
                    TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
                end
            end)
            
            DropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                ArrowLabel.Text = isOpen and "-" or "+"
                local targetSize = isOpen and UDim2.new(1, 0, 0, math.min(150, 40 + ListLayout.AbsoluteContentSize.Y + 8)) or UDim2.new(1, 0, 0, 36)
                TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
                
                if not isOpen then
                    TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
                end
            end)

            local function UpdateCanvas()
                ListContainer.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
                if isOpen then
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, math.min(150, 40 + ListLayout.AbsoluteContentSize.Y + 8))}):Play()
                end
            end
            ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

            local function AddPlayer(player)
                if ListContainer:FindFirstChild(player.Name) then return end
                
                local PlayerBtn = Instance.new("TextButton")
                PlayerBtn.Name = player.Name
                PlayerBtn.Parent = ListContainer
                PlayerBtn.BackgroundColor3 = Theme.SectionBackground
                PlayerBtn.Size = UDim2.new(1, 0, 0, 30)
                PlayerBtn.Text = ""
                PlayerBtn.AutoButtonColor = false
                
                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UI_CORNER_RADIUS
                BtnCorner.Parent = PlayerBtn

                local AvatarIcon = Instance.new("ImageLabel")
                AvatarIcon.Parent = PlayerBtn
                AvatarIcon.BackgroundTransparency = 1
                AvatarIcon.Position = UDim2.new(0, 5, 0.5, -10)
                AvatarIcon.Size = UDim2.new(0, 20, 0, 20)
                
                local AvatarCorner = Instance.new("UICorner")
                AvatarCorner.CornerRadius = UDim.new(1, 0)
                AvatarCorner.Parent = AvatarIcon
                
                task.spawn(function()
                    local thumbType = Enum.ThumbnailType.HeadShot
                    local thumbSize = Enum.ThumbnailSize.Size48x48
                    local success, content, isReady = pcall(function()
                        return Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
                    end)
                    if success and isReady then
                        AvatarIcon.Image = content
                    end
                end)

                local NameLabel = Instance.new("TextLabel")
                NameLabel.Parent = PlayerBtn
                NameLabel.BackgroundTransparency = 1
                NameLabel.Position = UDim2.new(0, 35, 0, 0)
                NameLabel.Size = UDim2.new(1, -40, 1, 0)
                NameLabel.Font = Enum.Font.Gotham
                NameLabel.Text = player.Name
                NameLabel.TextColor3 = Theme.Text
                NameLabel.TextSize = 12
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                PlayerBtn.MouseEnter:Connect(function()
                    TweenService:Create(PlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.HoverElement}):Play()
                end)
                PlayerBtn.MouseLeave:Connect(function()
                    TweenService:Create(PlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SectionBackground}):Play()
                end)
                
                PlayerBtn.MouseButton1Click:Connect(function()
                    DropdownLabel.Text = dropdownText .. " : " .. player.Name
                    isOpen = false
                    ArrowLabel.Text = "+"
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 36)}):Play()
                    TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground, Transparency = 0.5}):Play()
                    if callback then pcall(callback, player.Name) end
                end)
            end

            local function RemovePlayer(player)
                local btn = ListContainer:FindFirstChild(player.Name)
                if btn then
                    btn:Destroy()
                end
            end

            for _, v in ipairs(Players:GetPlayers()) do
                AddPlayer(v)
            end

            table.insert(Connections, Players.PlayerAdded:Connect(AddPlayer))
            table.insert(Connections, Players.PlayerRemoving:Connect(RemovePlayer))
        end

        return TabMethods
    end

    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end))

    return Window
end

return Library
