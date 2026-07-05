local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Library = {}

-- [[ Theme Configuration ]] --
local Theme = {
    MainBackground = Color3.fromRGB(20, 20, 20),      -- Deep Black/Grey
    TabBackground = Color3.fromRGB(25, 25, 25),       -- Slightly Lighter Grey
    SectionBackground = Color3.fromRGB(30, 30, 30),   -- Dark Grey for elements
    ElementBackground = Color3.fromRGB(40, 40, 40),   -- Lighter grey for interactables
    HoverElement = Color3.fromRGB(50, 50, 50),        -- Hover state
    Accent = Color3.fromRGB(220, 40, 40),             -- Crimson Red
    Text = Color3.fromRGB(240, 240, 240),             -- White/Light Grey
    TextDark = Color3.fromRGB(150, 150, 150)          -- Darker text for unselected tabs
}

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

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            main.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

-- [[ Library Initialization ]] --
function Library:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RedBlackGreyUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Safe execution environment check
    local success, err = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not success then
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Theme.MainBackground
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainFrame.Size = UDim2.new(0, 550, 0, 380)
    MainFrame.ClipsDescendants = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainFrame

    -- Topbar
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Parent = MainFrame
    Topbar.BackgroundColor3 = Theme.TabBackground
    Topbar.Size = UDim2.new(1, 0, 0, 40)
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 6)
    TopbarCorner.Parent = Topbar
    
    -- Hide bottom corners of topbar to merge seamlessly
    local TopbarExtension = Instance.new("Frame")
    TopbarExtension.Name = "Extension"
    TopbarExtension.Parent = Topbar
    TopbarExtension.BackgroundColor3 = Theme.TabBackground
    TopbarExtension.Position = UDim2.new(0, 0, 1, -10)
    TopbarExtension.Size = UDim2.new(1, 0, 0, 10)
    TopbarExtension.BorderSizePixel = 0

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Parent = Topbar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.Text = title or "UI Library"
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    MakeDraggable(Topbar, MainFrame)

    -- Accent Line (The Red Stripe)
    local AccentLine = Instance.new("Frame")
    AccentLine.Name = "AccentLine"
    AccentLine.Parent = MainFrame
    AccentLine.BackgroundColor3 = Theme.Accent
    AccentLine.Position = UDim2.new(0, 0, 0, 40)
    AccentLine.Size = UDim2.new(1, 0, 0, 2)
    AccentLine.BorderSizePixel = 0

    -- Tabs Container (Left Side)
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Parent = MainFrame
    TabsContainer.BackgroundColor3 = Theme.TabBackground
    TabsContainer.Position = UDim2.new(0, 0, 0, 42)
    TabsContainer.Size = UDim2.new(0, 140, 1, -42)
    TabsContainer.BorderSizePixel = 0
    
    local TabContainerSeparator = Instance.new("Frame")
    TabContainerSeparator.Name = "Separator"
    TabContainerSeparator.Parent = MainFrame
    TabContainerSeparator.BackgroundColor3 = Theme.SectionBackground
    TabContainerSeparator.Position = UDim2.new(0, 140, 0, 42)
    TabContainerSeparator.Size = UDim2.new(0, 1, 1, -42)
    TabContainerSeparator.BorderSizePixel = 0

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
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Parent = MainFrame
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 145, 0, 42)
    ContentContainer.Size = UDim2.new(1, -145, 1, -42)

    local Window = {
        CurrentTab = nil
    }

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
        TabButtonCorner.CornerRadius = UDim.new(0, 6)
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
        TabPage.ScrollBarThickness = 3
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
            if Window.CurrentTab then
                Window.CurrentTab.Page.Visible = false
                TweenService:Create(Window.CurrentTab.Button, TweenInfo.new(0.3), {TextColor3 = Theme.TextDark, BackgroundTransparency = 1}):Play()
                TweenService:Create(Window.CurrentTab.Indicator, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            end
            Window.CurrentTab = {Page = TabPage, Button = TabButton, Indicator = TabIndicator}
            TabPage.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {TextColor3 = Theme.Text, BackgroundTransparency = 0}):Play()
            TweenService:Create(TabIndicator, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
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
            ButtonCorner.CornerRadius = UDim.new(0, 4)
            ButtonCorner.Parent = Button
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = Button
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.HoverElement}):Play()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
            end)

            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBackground}):Play()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground}):Play()
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
            ToggleCorner.CornerRadius = UDim.new(0, 4)
            ToggleCorner.Parent = ToggleFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = ToggleFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1

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
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
            end)

            ToggleFrame.MouseLeave:Connect(function()
                TweenService:Create(UIStroke, TweenInfo.new(0.2), {Color = Theme.SectionBackground}):Play()
            end)

            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                if callback then pcall(callback, state) end
                
                TweenService:Create(ToggleIndicator, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.Accent or Theme.SectionBackground}):Play()
                TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(state and 1 or 0, state and -18 or 2, 0.5, -8)}):Play()
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
            BoxCorner.CornerRadius = UDim.new(0, 4)
            BoxCorner.Parent = BoxFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = BoxFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1

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
            TBCorner.CornerRadius = UDim.new(0, 4)
            TBCorner.Parent = TextBox

            TextBox.FocusLost:Connect(function(enterPressed)
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
            SliderCorner.CornerRadius = UDim.new(0, 4)
            SliderCorner.Parent = SliderFrame
            
            local UIStroke = Instance.new("UIStroke")
            UIStroke.Parent = SliderFrame
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Color = Theme.SectionBackground
            UIStroke.Thickness = 1

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
                    Update(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end)
        end

        return TabMethods
    end

    return Window
end

return Library
