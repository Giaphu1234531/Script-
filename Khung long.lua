--[[
    PHÚ ROBLOX HUB
    itipati! Primeval Earth | Dinosaur
    Auto Kill + Auto Ownership + Auto Eat + Speed + Jump + Fly + ESP + Hop + Hitbox + Teleport Player
    Mobile + PC (Potassium / Delta / Xeno / Solara) Support
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlaceId = game.PlaceId

local IS_PC = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
local IS_MOBILE = UserInputService.TouchEnabled

local EXECUTOR_NAME = "Unknown"
pcall(function()
    if type(identifyexecutor) == "function" then
        EXECUTOR_NAME = tostring(identifyexecutor())
    elseif type(getexecutorname) == "function" then
        EXECUTOR_NAME = tostring(getexecutorname())
    end
end)

local function getSafeGuiParent()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local test = pcall(function()
            local t = Instance.new("Folder")
            t.Name = "_phu_test_" .. tick()
            t.Parent = cg
            t:Destroy()
        end)
        if test then return cg end
    end
    return Player:WaitForChild("PlayerGui")
end

local GuiParent = getSafeGuiParent()

for _, parent in ipairs({Player:FindFirstChild("PlayerGui"), (pcall(function() return game:GetService("CoreGui") end)) and game:GetService("CoreGui") or nil}) do
    if parent then
        for _, name in ipairs({"PrimevalEarth_UI", "PhuRobloxHub"}) do
            local old = parent:FindFirstChild(name)
            if old then pcall(function() old:Destroy() end) end
        end
    end
end

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PrimevalEarth_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = GuiParent end)
if not ScreenGui.Parent then
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
end

local Scale = Instance.new("UIScale")
Scale.Scale = 1
Scale.Parent = ScreenGui

local Camera = workspace.CurrentCamera

local function updateScale()
    if not Camera then return end
    local viewport = Camera.ViewportSize
    local minSize = math.min(viewport.X, viewport.Y)
    if minSize < 500 then Scale.Scale = 0.78
    elseif minSize < 700 then Scale.Scale = 0.88
    else Scale.Scale = 1 end
end

updateScale()
if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

--==================================================
-- FLOATING LOGO
--==================================================

local LogoToggle = Instance.new("ImageButton")
LogoToggle.Name = "LogoToggle"
LogoToggle.Size = UDim2.fromOffset(55, 55)
LogoToggle.Position = UDim2.new(0, 18, 0.5, 0)
LogoToggle.AnchorPoint = Vector2.new(0, 0.5)
LogoToggle.BackgroundColor3 = Color3.fromRGB(14, 21, 22)
LogoToggle.BorderSizePixel = 0
LogoToggle.Image = "rbxassetid://114716788016991"
LogoToggle.ImageColor3 = Color3.fromRGB(255, 255, 255)
LogoToggle.ScaleType = Enum.ScaleType.Fit
LogoToggle.AutoButtonColor = false
LogoToggle.Active = true
LogoToggle.Parent = ScreenGui

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(1, 0)
LogoCorner.Parent = LogoToggle

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Color = Color3.fromRGB(40, 210, 130)
LogoStroke.Thickness = 2
LogoStroke.Parent = LogoToggle

local LogoPadding = Instance.new("UIPadding")
LogoPadding.PaddingTop = UDim.new(0, 6)
LogoPadding.PaddingBottom = UDim.new(0, 6)
LogoPadding.PaddingLeft = UDim.new(0, 6)
LogoPadding.PaddingRight = UDim.new(0, 6)
LogoPadding.Parent = LogoToggle

local logoDragging, logoDragStart, logoStartPos = false, nil, nil

LogoToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = true
        logoDragStart = input.Position
        logoStartPos = LogoToggle.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if logoDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - logoDragStart
        LogoToggle.Position = UDim2.new(
            logoStartPos.X.Scale, logoStartPos.X.Offset + delta.X,
            logoStartPos.Y.Scale, logoStartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = false
    end
end)

spawn(function()
    while LogoToggle.Parent do
        LogoStroke.Transparency = 0
        LogoStroke.Thickness = 2
        task.wait(0.8)
        if not LogoToggle.Parent then break end
        LogoStroke.Transparency = 0.5
        LogoStroke.Thickness = 3
        task.wait(0.8)
    end
end)

--==================================================
-- MAIN FRAME
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(700, 500)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(12, 17, 19)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 65, 68)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.3
MainStroke.Parent = Main

--==================================================
-- HEADER
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 75)
Header.BackgroundColor3 = Color3.fromRGB(8, 12, 13)
Header.BorderSizePixel = 0
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = Header

local DinoIcon = Instance.new("TextLabel")
DinoIcon.Size = UDim2.fromOffset(60, 60)
DinoIcon.Position = UDim2.fromOffset(12, 7)
DinoIcon.BackgroundTransparency = 1
DinoIcon.Text = "🦖"
DinoIcon.TextSize = 34
DinoIcon.Font = Enum.Font.GothamBold
DinoIcon.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -170, 0, 30)
Title.Position = UDim2.fromOffset(72, 10)
Title.BackgroundTransparency = 1
Title.Text = "PHÚ ROBLOX HUB"
Title.TextColor3 = Color3.fromRGB(245, 245, 245)
Title.TextSize = 21
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -170, 0, 25)
SubTitle.Position = UDim2.fromOffset(72, 39)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Primeval Earth • " .. (IS_PC and "PC" or "Mobile") .. " [" .. EXECUTOR_NAME .. "]"
SubTitle.TextColor3 = Color3.fromRGB(145, 155, 158)
SubTitle.TextSize = 13
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(45, 45)
Close.Position = UDim2.new(1, -55, 0, 15)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(230, 230, 230)
Close.TextSize = 30
Close.Font = Enum.Font.Gotham
Close.Parent = Header

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    LogoToggle.Visible = true
end)

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(45, 45)
Minimize.Position = UDim2.new(1, -100, 0, 15)
Minimize.BackgroundTransparency = 1
Minimize.Text = "—"
Minimize.TextColor3 = Color3.fromRGB(230, 230, 230)
Minimize.TextSize = 25
Minimize.Font = Enum.Font.Gotham
Minimize.Parent = Header

--==================================================
-- DRAG MENU
--==================================================

local dragging, dragStart, startPos = false, nil, nil

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl
    or input.KeyCode == Enum.KeyCode.K
    or input.KeyCode == Enum.KeyCode.F1 then
        Main.Visible = not Main.Visible
        LogoToggle.Visible = not Main.Visible
    end
end)

--==================================================
-- SIDEBAR + CONTENT
--==================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 215, 1, -75)
Sidebar.Position = UDim2.fromOffset(0, 75)
Sidebar.BackgroundColor3 = Color3.fromRGB(11, 16, 18)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = UDim.new(0, 5)
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 18)
SidebarPadding.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -215, 1, -75)
Content.Position = UDim2.fromOffset(215, 75)
Content.BackgroundColor3 = Color3.fromRGB(14, 19, 21)
Content.BorderSizePixel = 0
Content.Parent = Main

local ContentTitle = Instance.new("TextLabel")
ContentTitle.Size = UDim2.new(1, -45, 0, 45)
ContentTitle.Position = UDim2.fromOffset(25, 18)
ContentTitle.BackgroundTransparency = 1
ContentTitle.Text = "Main"
ContentTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
ContentTitle.TextSize = 25
ContentTitle.Font = Enum.Font.GothamBold
ContentTitle.TextXAlignment = Enum.TextXAlignment.Left
ContentTitle.Parent = Content

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -20, 1, -80)
ContentScroll.Position = UDim2.fromOffset(10, 72)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 3
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(45, 220, 135)
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentScroll

--==================================================
-- PAGES
--==================================================

local Pages = {}
local function createPage(name)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    f.Visible = false
    f.Parent = ContentScroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = f

    Pages[name] = f
    return f
end

local toggleStates = {}

local function createToggleRow(parent, title, description, default, key)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -20, 0, 62)
    Row.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
    Row.BorderSizePixel = 0
    Row.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Row

    local Name = Instance.new("TextLabel")
    Name.Size = UDim2.new(1, -100, 0, 27)
    Name.Position = UDim2.fromOffset(14, 8)
    Name.BackgroundTransparency = 1
    Name.Text = title
    Name.TextColor3 = Color3.fromRGB(240, 240, 240)
    Name.TextSize = 16
    Name.Font = Enum.Font.GothamMedium
    Name.TextXAlignment = Enum.TextXAlignment.Left
    Name.Parent = Row

    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -100, 0, 20)
    Desc.Position = UDim2.fromOffset(14, 32)
    Desc.BackgroundTransparency = 1
    Desc.Text = description or ""
    Desc.TextColor3 = Color3.fromRGB(145, 153, 155)
    Desc.TextSize = 12
    Desc.Font = Enum.Font.Gotham
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Row

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.fromOffset(60, 32)
    Switch.Position = UDim2.new(1, -72, 0.5, -16)
    Switch.BackgroundColor3 = default and Color3.fromRGB(35, 190, 110) or Color3.fromRGB(65, 76, 82)
    Switch.BorderSizePixel = 0
    Switch.Parent = Row

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.fromOffset(24, 24)
    Circle.Position = default and UDim2.new(1, -28, 0.5, -12) or UDim2.fromOffset(4, 4)
    Circle.BackgroundColor3 = Color3.fromRGB(240, 245, 245)
    Circle.BorderSizePixel = 0
    Circle.Parent = Switch

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.Parent = Row

    local enabled = default
    toggleStates[key] = enabled

    ClickBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggleStates[key] = enabled
        if enabled then
            Switch.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
            Circle:TweenPosition(UDim2.new(1, -28, 0.5, -12), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        else
            Switch.BackgroundColor3 = Color3.fromRGB(65, 76, 82)
            Circle:TweenPosition(UDim2.fromOffset(4, 4), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end
    end)

    return Row
end

local function createSlider(parent, title, min, max, default, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -20, 0, 72)
    Holder.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
    Holder.BorderSizePixel = 0
    Holder.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Holder

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 22)
    Label.Position = UDim2.fromOffset(14, 6)
    Label.BackgroundTransparency = 1
    Label.Text = title .. ": " .. tostring(default)
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -28, 0, 10)
    Bar.Position = UDim2.fromOffset(14, 42)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 55, 60)
    Bar.BorderSizePixel = 0
    Bar.Parent = Holder

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(18, 18)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(240, 245, 245)
    Knob.BorderSizePixel = 0
    Knob.Parent = Bar

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local draggingBar = false
    local value = default

    local function setValue(v)
        value = math.clamp(v, min, max)
        local pct = (value - min) / (max - min)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Knob.Position = UDim2.new(pct, 0, 0.5, 0)
        Label.Text = title .. ": " .. string.format("%.1f", value)
        if callback then callback(value) end
    end

    local function handleInput(input)
        local pos = input.Position.X - Bar.AbsolutePosition.X
        local pct = math.clamp(pos / Bar.AbsoluteSize.X, 0, 1)
        setValue(min + pct * (max - min))
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = true
            handleInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingBar and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            handleInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = false
        end
    end)

    setValue(default)
    return Holder
end

--==================================================
-- PAGES BUILD
--==================================================

local mainPage = createPage("Main")
local playerPage = createPage("Player")
local dinoPage = createPage("Dinosaur")
local espPage = createPage("ESP")
local tpPage = createPage("Teleports")
local settingsPage = createPage("Settings")

-- MAIN
createToggleRow(mainPage, "Auto Kill", "Tele sau lưng + đánh liên tục", false, "Auto Kill")
createToggleRow(mainPage, "Auto Ownership Area", "Tele vào zone đỏ, chờ xanh", false, "Auto Ownership Area")
createToggleRow(mainPage, "Auto Eat", "Tele tới Meat + Eat", false, "Auto Eat")
createToggleRow(mainPage, "Auto Protect", "≤ 10% máu → tele lên trời, đứng im, đầy máu → về chỗ cũ", false, "Auto Protect")

-- PLAYER
local speedValue = 50
local jumpValue = 120
local hitboxSize = 5
local flySpeed = 150

createToggleRow(playerPage, "Speed Enabled", "Auto apply WalkSpeed (fix underwater)", false, "Speed Enabled")
createToggleRow(playerPage, "Jump Enabled", "Auto apply JumpPower", false, "Jump Enabled")
createToggleRow(playerPage, "Fly", "Kéo joystick hướng nào bay hướng đó", false, "Fly")
createToggleRow(playerPage, "Hitbox Player", "To hitbox người khác → đánh xa", false, "Hitbox Player")

createSlider(playerPage, "WalkSpeed", 16, 500, 50, function(v) speedValue = v end)
createSlider(playerPage, "JumpPower", 50, 500, 120, function(v) jumpValue = v end)
createSlider(playerPage, "Fly Speed", 10, 800, 150, function(v) flySpeed = v end)
createSlider(playerPage, "Hitbox Size", 1, 100, 5, function(v) hitboxSize = v end)

-- ESP
createToggleRow(espPage, "ESP Player", "Highlight + tên + khoảng cách", false, "ESP Player")

--==================================================
--==================================================
-- TELEPORTS — Player list (clean UI)
--==================================================

local tpPlayerRows = {} -- [player] = row frame
local tpSearchQuery = ""

-- Search box
local tpSearch = Instance.new("TextBox")
tpSearch.Size = UDim2.new(1, -20, 0, 42)
tpSearch.BackgroundColor3 = Color3.fromRGB(22, 29, 32)
tpSearch.BorderSizePixel = 0
tpSearch.PlaceholderText = "🔎  Tìm tên người chơi..."
tpSearch.PlaceholderColor3 = Color3.fromRGB(125, 137, 141)
tpSearch.Text = ""
tpSearch.TextColor3 = Color3.fromRGB(240, 245, 245)
tpSearch.TextSize = 14
tpSearch.Font = Enum.Font.Gotham
tpSearch.TextXAlignment = Enum.TextXAlignment.Left
tpSearch.ClearTextOnFocus = false
tpSearch.Parent = tpPage

local tpSearchPadding = Instance.new("UIPadding")
tpSearchPadding.PaddingLeft = UDim.new(0, 14)
tpSearchPadding.PaddingRight = UDim.new(0, 14)
tpSearchPadding.Parent = tpSearch

local tpSearchCorner = Instance.new("UICorner")
tpSearchCorner.CornerRadius = UDim.new(0, 10)
tpSearchCorner.Parent = tpSearch

local tpSearchStroke = Instance.new("UIStroke")
tpSearchStroke.Color = Color3.fromRGB(48, 60, 64)
tpSearchStroke.Thickness = 1
tpSearchStroke.Transparency = 0.25
tpSearchStroke.Parent = tpSearch

local tpHeader = Instance.new("Frame")
tpHeader.Size = UDim2.new(1, -20, 0, 46)
tpHeader.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
tpHeader.BorderSizePixel = 0
tpHeader.Parent = tpPage

local tpHeaderCorner = Instance.new("UICorner")
tpHeaderCorner.CornerRadius = UDim.new(0, 10)
tpHeaderCorner.Parent = tpHeader

local tpHeaderLabel = Instance.new("TextLabel")
tpHeaderLabel.Size = UDim2.new(1, -28, 1, 0)
tpHeaderLabel.Position = UDim2.fromOffset(14, 0)
tpHeaderLabel.BackgroundTransparency = 1
tpHeaderLabel.Text = "PLAYERS"
tpHeaderLabel.TextColor3 = Color3.fromRGB(45, 220, 135)
tpHeaderLabel.TextSize = 14
tpHeaderLabel.Font = Enum.Font.GothamBold
tpHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
tpHeaderLabel.Parent = tpHeader

local function teleportToPlayer(target)
    if not target then return end
    local localRoot = getLocalRoot and getLocalRoot()
        or (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart"))
    if not localRoot then return end

    local targetChar = target.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    localRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 3, 0))
    localRoot.Velocity = Vector3.zero
    localRoot.AssemblyLinearVelocity = Vector3.zero
end

local function tpMatchesSearch(plr)
    if tpSearchQuery == "" then
        return true
    end

    local q = tpSearchQuery:lower()
    return plr.Name:lower():find(q, 1, true) ~= nil
        or plr.DisplayName:lower():find(q, 1, true) ~= nil
end

local function updateTeleportRowsVisibility()
    for plr, row in pairs(tpPlayerRows) do
        if row and row.Parent then
            row.Visible = tpMatchesSearch(plr)
        end
    end
end

local function createPlayerRow(plr)
    if plr == Player or tpPlayerRows[plr] then return end

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -20, 0, 58)
    Row.BackgroundColor3 = Color3.fromRGB(22, 29, 32)
    Row.BorderSizePixel = 0
    Row.Parent = tpPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Row

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(48, 60, 64)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.45
    Stroke.Parent = Row

    -- Player avatar
    local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.fromOffset(42, 42)
    Avatar.Position = UDim2.fromOffset(9, 8)
    Avatar.BackgroundColor3 = Color3.fromRGB(35, 44, 47)
    Avatar.BorderSizePixel = 0
    Avatar.Parent = Row

    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = Avatar

    pcall(function()
        Avatar.Image = Players:GetUserThumbnailAsync(
            plr.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)

    -- Display name
    local DisplayName = Instance.new("TextLabel")
    DisplayName.Size = UDim2.new(1, -145, 0, 23)
    DisplayName.Position = UDim2.fromOffset(61, 7)
    DisplayName.BackgroundTransparency = 1
    DisplayName.Text = plr.DisplayName
    DisplayName.TextColor3 = Color3.fromRGB(242, 245, 245)
    DisplayName.TextSize = 15
    DisplayName.Font = Enum.Font.GothamMedium
    DisplayName.TextXAlignment = Enum.TextXAlignment.Left
    DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
    DisplayName.Parent = Row

    -- Username
    local Username = Instance.new("TextLabel")
    Username.Size = UDim2.new(1, -145, 0, 18)
    Username.Position = UDim2.fromOffset(61, 31)
    Username.BackgroundTransparency = 1
    Username.Text = "@" .. plr.Name
    Username.TextColor3 = Color3.fromRGB(130, 142, 146)
    Username.TextSize = 11
    Username.Font = Enum.Font.Gotham
    Username.TextXAlignment = Enum.TextXAlignment.Left
    Username.TextTruncate = Enum.TextTruncate.AtEnd
    Username.Parent = Row

    -- Compact teleport button
    local TeleBtn = Instance.new("TextButton")
    TeleBtn.Size = UDim2.fromOffset(72, 36)
    TeleBtn.Position = UDim2.new(1, -82, 0.5, -18)
    TeleBtn.BackgroundColor3 = Color3.fromRGB(30, 155, 100)
    TeleBtn.BorderSizePixel = 0
    TeleBtn.Text = "TP"
    TeleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TeleBtn.TextSize = 14
    TeleBtn.Font = Enum.Font.GothamBold
    TeleBtn.AutoButtonColor = false
    TeleBtn.Parent = Row

    local TeleCorner = Instance.new("UICorner")
    TeleCorner.CornerRadius = UDim.new(0, 9)
    TeleCorner.Parent = TeleBtn

    local TeleStroke = Instance.new("UIStroke")
    TeleStroke.Color = Color3.fromRGB(45, 220, 135)
    TeleStroke.Thickness = 1
    TeleStroke.Transparency = 0.3
    TeleStroke.Parent = TeleBtn

    TeleBtn.MouseButton1Click:Connect(function()
        teleportToPlayer(plr)
    end)

    TeleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            TeleBtn.BackgroundColor3 = Color3.fromRGB(22, 115, 76)
        end
    end)

    TeleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            TeleBtn.BackgroundColor3 = Color3.fromRGB(30, 155, 100)
        end
    end)

    plr:GetPropertyChangedSignal("DisplayName"):Connect(function()
        if Row.Parent then
            DisplayName.Text = plr.DisplayName
        end
    end)

    tpPlayerRows[plr] = Row
end

local function removePlayerRow(plr)
    local row = tpPlayerRows[plr]
    if row then
        row:Destroy()
        tpPlayerRows[plr] = nil
    end
end

tpSearch:GetPropertyChangedSignal("Text"):Connect(function()
    tpSearchQuery = tpSearch.Text:gsub("^%s+", ""):gsub("%s+$", "")
    updateTeleportRowsVisibility()
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= Player then
        createPlayerRow(plr)
    end
end

Players.PlayerAdded:Connect(function(plr)
    createPlayerRow(plr)
    updateTeleportRowsVisibility()
end)

Players.PlayerRemoving:Connect(function(plr)
    removePlayerRow(plr)
end)

--==================================================
-- SETTINGS — HOP SERVER
--==================================================

local HOPPING = false
local MAX_PLAYERS = 2
local MAX_SERVER_PAGES = 10

-- AUTO PROTECT — adjustable HP trigger
local autoProtectPercent = 10
local AUTO_PROTECT_THRESHOLD = autoProtectPercent / 100

createSlider(settingsPage, "Auto Protect HP (%)", 1, 100, autoProtectPercent, function(v)
    autoProtectPercent = math.floor(v + 0.5)
    AUTO_PROTECT_THRESHOLD = autoProtectPercent / 100
end)

local StatusRow = Instance.new("Frame")
StatusRow.Size = UDim2.new(1, -20, 0, 85)
StatusRow.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
StatusRow.BorderSizePixel = 0
StatusRow.Parent = settingsPage

local StatusRowCorner = Instance.new("UICorner")
StatusRowCorner.CornerRadius = UDim.new(0, 9)
StatusRowCorner.Parent = StatusRow

local PlayerCount = Instance.new("TextLabel")
PlayerCount.Size = UDim2.new(0.5, -20, 0, 30)
PlayerCount.Position = UDim2.fromOffset(14, 10)
PlayerCount.BackgroundTransparency = 1
PlayerCount.Text = "0/2"
PlayerCount.TextColor3 = Color3.fromRGB(240, 247, 255)
PlayerCount.TextSize = 22
PlayerCount.Font = Enum.Font.GothamBold
PlayerCount.TextXAlignment = Enum.TextXAlignment.Left
PlayerCount.Parent = StatusRow

local PlayerText = Instance.new("TextLabel")
PlayerText.Size = UDim2.new(0.5, -20, 0, 16)
PlayerText.Position = UDim2.fromOffset(14, 42)
PlayerText.BackgroundTransparency = 1
PlayerText.Text = "NGƯỜI CHƠI HIỆN TẠI"
PlayerText.TextColor3 = Color3.fromRGB(145, 153, 155)
PlayerText.TextSize = 10
PlayerText.Font = Enum.Font.GothamBold
PlayerText.TextXAlignment = Enum.TextXAlignment.Left
PlayerText.Parent = StatusRow

local ServerStatus = Instance.new("TextLabel")
ServerStatus.Size = UDim2.new(0.5, -20, 0, 30)
ServerStatus.Position = UDim2.new(0.5, 0, 0, 10)
ServerStatus.BackgroundTransparency = 1
ServerStatus.Text = "Bình thường"
ServerStatus.TextColor3 = Color3.fromRGB(45, 220, 135)
ServerStatus.TextSize = 16
ServerStatus.Font = Enum.Font.GothamBold
ServerStatus.TextXAlignment = Enum.TextXAlignment.Right
ServerStatus.Parent = StatusRow

local ServerText = Instance.new("TextLabel")
ServerText.Size = UDim2.new(0.5, -20, 0, 16)
ServerText.Position = UDim2.new(0.5, 0, 0, 42)
ServerText.BackgroundTransparency = 1
ServerText.Text = "TRẠNG THÁI SERVER"
ServerText.TextColor3 = Color3.fromRGB(145, 153, 155)
ServerText.TextSize = 10
ServerText.Font = Enum.Font.GothamBold
ServerText.TextXAlignment = Enum.TextXAlignment.Right
ServerText.Parent = StatusRow

local HopRow = Instance.new("Frame")
HopRow.Size = UDim2.new(1, -20, 0, 55)
HopRow.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
HopRow.BorderSizePixel = 0
HopRow.Parent = settingsPage

local HopRowCorner = Instance.new("UICorner")
HopRowCorner.CornerRadius = UDim.new(0, 9)
HopRowCorner.Parent = HopRow

local HopBtn = Instance.new("TextButton")
HopBtn.Size = UDim2.new(1, -20, 1, -16)
HopBtn.Position = UDim2.fromOffset(10, 8)
HopBtn.BackgroundColor3 = Color3.fromRGB(18, 75, 125)
HopBtn.BorderSizePixel = 0
HopBtn.Text = "↻  HOP SERVER  (tìm ≤ 2 người)"
HopBtn.TextColor3 = Color3.fromRGB(245, 250, 255)
HopBtn.TextSize = 15
HopBtn.Font = Enum.Font.GothamBold
HopBtn.AutoButtonColor = false
HopBtn.Parent = HopRow

local HopBtnCorner = Instance.new("UICorner")
HopBtnCorner.CornerRadius = UDim.new(0, 8)
HopBtnCorner.Parent = HopBtn

local HopBtnStroke = Instance.new("UIStroke")
HopBtnStroke.Color = Color3.fromRGB(42, 135, 215)
HopBtnStroke.Thickness = 1
HopBtnStroke.Transparency = 0.2
HopBtnStroke.Parent = HopBtn

local function UpdateCount()
    local amount = #Players:GetPlayers()
    PlayerCount.Text = tostring(amount) .. "/" .. tostring(MAX_PLAYERS)
    if amount <= MAX_PLAYERS then
        ServerStatus.Text = "Bình thường"
        ServerStatus.TextColor3 = Color3.fromRGB(45, 220, 135)
    elseif amount == MAX_PLAYERS + 1 then
        ServerStatus.Text = amount .. " người"
        ServerStatus.TextColor3 = Color3.fromRGB(245, 190, 70)
    else
        ServerStatus.Text = "Server đông"
        ServerStatus.TextColor3 = Color3.fromRGB(245, 80, 80)
    end
end

UpdateCount()
Players.PlayerAdded:Connect(UpdateCount)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    UpdateCount()
end)

local function safeHttpGet(url)
    if type(game.HttpGet) == "function" then
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res then return res end
    end
    if type(httpget) == "function" then
        local ok, res = pcall(httpget, url)
        if ok and res then return res end
    end
    if type(request) == "function" then
        local ok, res = pcall(function()
            return request({Url = url, Method = "GET"}).Body
        end)
        if ok and res then return res end
    end
    return nil
end

local function GetServers()
    local result = {}
    local cursor = ""

    for page = 1, MAX_SERVER_PAGES do
        local url = "https://games.roblox.com/v1/games/"
            .. PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local body = safeHttpGet(url)
        if not body then break end

        local success, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)

        if not success or not data or not data.data then break end

        for _, server in ipairs(data.data) do
            local playing = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 0
            if server.id ~= game.JobId
                and playing <= MAX_PLAYERS
                and playing < maxPlayers then
                table.insert(result, server.id)
            end
        end

        cursor = data.nextPageCursor or ""
        if cursor == "" then break end
        task.wait(0.15)
    end

    return result
end

local function TeleportToServer(serverId)
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, serverId, Player)
    end)
    return success, err
end

local function HopServer()
    if HOPPING then return end
    HOPPING = true

    HopBtn.Text = "Đang tìm server..."
    HopBtn.BackgroundColor3 = Color3.fromRGB(80, 90, 100)
    ServerStatus.Text = "Đang tìm..."
    ServerStatus.TextColor3 = Color3.fromRGB(80, 170, 255)

    local servers = GetServers()

    if #servers == 0 then
        ServerStatus.Text = "Không tìm thấy"
        ServerStatus.TextColor3 = Color3.fromRGB(245, 80, 80)
        HopBtn.Text = "↻  HOP SERVER  (tìm ≤ " .. MAX_PLAYERS .. " người)"
        HopBtn.BackgroundColor3 = Color3.fromRGB(18, 75, 125)
        HOPPING = false
        return
    end

    ServerStatus.Text = "Đang vào server..."
    ServerStatus.TextColor3 = Color3.fromRGB(80, 170, 255)
    HopBtn.Text = "Đang teleport..."

    task.wait(0.3)
    local ok = TeleportToServer(servers[1])

    if not ok then
        for i = 2, math.min(#servers, 5) do
            ok = TeleportToServer(servers[i])
            if ok then break end
            task.wait(0.3)
        end
    end

    if not ok then
        ServerStatus.Text = "Teleport lỗi"
        ServerStatus.TextColor3 = Color3.fromRGB(245, 80, 80)
        HopBtn.Text = "↻  HOP SERVER  (tìm ≤ " .. MAX_PLAYERS .. " người)"
        HopBtn.BackgroundColor3 = Color3.fromRGB(18, 75, 125)
        HOPPING = false
    end
end

HopBtn.MouseButton1Click:Connect(HopServer)

--==================================================
-- TAB BUTTONS
--==================================================

local tabs = {
    {icon = "⌂", text = "Main", page = "Main"},
    {icon = "●", text = "Player", page = "Player"},
    {icon = "🦖", text = "Dinosaur", page = "Dinosaur"},
    {icon = "◉", text = "ESP", page = "ESP"},
    {icon = "●", text = "Teleports", page = "Teleports"},
    {icon = "☷", text = "Settings", page = "Settings"},
}

local tabRefs = {}

local function selectTab(idx)
    for i, btn in ipairs(tabRefs) do
        local selected = (i == idx)
        btn.BackgroundColor3 = selected and Color3.fromRGB(12, 55, 42) or Color3.fromRGB(11, 16, 18)
        for _, obj in ipairs(btn:GetChildren()) do
            if obj:IsA("TextLabel") then
                if obj.Name == "Icon" then
                    obj.TextColor3 = selected and Color3.fromRGB(45, 220, 135) or Color3.fromRGB(190, 198, 200)
                elseif obj.Name == "Label" then
                    obj.TextColor3 = selected and Color3.fromRGB(45, 220, 135) or Color3.fromRGB(220, 225, 226)
                end
            end
        end
    end
end

local function showPage(pageName)
    for name, page in pairs(Pages) do
        page.Visible = (name == pageName)
    end
    ContentTitle.Text = pageName
end

for i, data in ipairs(tabs) do
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -25, 0, 48)
    Button.BackgroundColor3 = i == 1 and Color3.fromRGB(12, 55, 42) or Color3.fromRGB(11, 16, 18)
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Button

    local Icon = Instance.new("TextLabel")
    Icon.Name = "Icon"
    Icon.Size = UDim2.fromOffset(40, 48)
    Icon.Position = UDim2.fromOffset(5, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = data.icon
    Icon.TextSize = 21
    Icon.Font = Enum.Font.Gotham
    Icon.TextColor3 = i == 1 and Color3.fromRGB(45, 220, 135) or Color3.fromRGB(190, 198, 200)
    Icon.Parent = Button

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.fromOffset(48, 0)
    Label.BackgroundTransparency = 1
    Label.Text = data.text
    Label.TextSize = 16
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = i == 1 and Color3.fromRGB(45, 220, 135) or Color3.fromRGB(220, 225, 226)
    Label.Parent = Button

    tabRefs[i] = Button

    Button.MouseButton1Click:Connect(function()
        selectTab(i)
        showPage(data.page)
    end)
end

showPage("Main")

--==================================================
-- LOGO TOGGLE
--==================================================

LogoToggle.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    LogoToggle.Visible = not Main.Visible
end)

LogoToggle.MouseButton1Down:Connect(function()
    Main.Visible = not Main.Visible
    LogoToggle.Visible = not Main.Visible
end)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    LogoToggle.Visible = true
end)

--==================================================
-- HELPERS
--==================================================

function getLocalRoot()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- SPEED + JUMP
--==================================================

local function clearSwimBoost()
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local old = root:FindFirstChild("SwimBoost")
        if old then old:Destroy() end
    end
end

local function applySwimBoost(hum, root)
    local bv = root:FindFirstChild("SwimBoost")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "SwimBoost"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.P = 1250
        bv.Parent = root
    end
    local dir = hum.MoveDirection
    if dir.Magnitude < 0.01 then
        bv.Velocity = Vector3.zero
    else
        bv.Velocity = dir * speedValue
    end
end

RunService.Heartbeat:Connect(function()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    if toggleStates["Speed Enabled"] then
        hum.WalkSpeed = speedValue
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Swimming then
            applySwimBoost(hum, root)
        else
            clearSwimBoost()
        end
    else
        clearSwimBoost()
    end

    if toggleStates["Jump Enabled"] then
        hum.UseJumpPower = true
        hum.JumpPower = jumpValue
        hum.JumpHeight = jumpValue * 0.25
    end
end)

Player.CharacterAdded:Connect(function(char)
    wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if toggleStates["Speed Enabled"] then hum.WalkSpeed = speedValue end
    if toggleStates["Jump Enabled"] then
        hum.UseJumpPower = true
        hum.JumpPower = jumpValue
    end
end)

--==================================================
-- FLY
--==================================================

local flyBV = nil
local flyBG = nil

local function cleanupFly()
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

local function initFly()
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "PhuFlyBV"
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.P = 2000
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "PhuFlyBG"
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 2000
    flyBG.D = 50
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
end

RunService.RenderStepped:Connect(function(dt)
    if not toggleStates["Fly"] then
        if flyBV or flyBG then
            cleanupFly()
        end
        return
    end

    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if not flyBV or flyBV.Parent ~= hrp then
        initFly()
    end

    hum.PlatformStand = true

    local cam = workspace.CurrentCamera
    if not cam then return end

    local camLook = cam.CFrame.LookVector
    local camRight = cam.CFrame.RightVector
    local moveDir = hum.MoveDirection

    local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
    if flatLook.Magnitude < 0.001 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end

    local flatRight = Vector3.new(camRight.X, 0, camRight.Z)
    if flatRight.Magnitude < 0.001 then
        flatRight = Vector3.new(1, 0, 0)
    else
        flatRight = flatRight.Unit
    end

    local fwd = 0
    local rgt = 0
    if moveDir.Magnitude > 0.01 then
        fwd = moveDir:Dot(flatLook)
        rgt = moveDir:Dot(flatRight)
    end

    local vInput = 0
    if IS_PC then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vInput = vInput + 1
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            vInput = vInput - 1
        end
    end

    local dir = Vector3.zero
    dir = dir + flatLook * fwd
    dir = dir + flatRight * rgt

    if math.abs(fwd) > 0.01 then
        dir = dir + Vector3.new(0, camLook.Y * fwd * 1.8, 0)
    end

    if vInput ~= 0 then
        dir = dir + Vector3.new(0, vInput, 0)
    end

    local horiz = Vector3.new(dir.X, 0, dir.Z)
    local vert = dir.Y

    local finalVel = Vector3.zero
    if horiz.Magnitude > 0.001 then
        finalVel = finalVel + horiz.Unit * flySpeed * math.min(horiz.Magnitude, 1)
    end
    if math.abs(vert) > 0.001 then
        finalVel = finalVel + Vector3.new(0, math.clamp(vert, -1.5, 1.5) * flySpeed, 0)
    end

    flyBV.Velocity = finalVel
    flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + camLook)
end)

Player.CharacterAdded:Connect(function()
    cleanupFly()
end)

--==================================================
-- HITBOX PLAYER
--==================================================

local hitboxData = {}

local function removeHitbox(plr)
    local hb = hitboxData[plr]
    if hb and hb.Parent then hb:Destroy() end
    hitboxData[plr] = nil
end

local function createHitbox(plr)
    if plr == Player then return end
    if hitboxData[plr] and hitboxData[plr].Parent then return end

    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hb = Instance.new("Part")
    hb.Name = "PhuHitbox"
    hb.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
    hb.Transparency = 1
    hb.CanCollide = false
    hb.CanQuery = true
    hb.CanTouch = true
    hb.Massless = true
    hb.Anchored = false
    hb.Shape = Enum.PartType.Ball
    hb.CFrame = hrp.CFrame
    hb.Parent = char

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = hb
    weld.Parent = hb

    hitboxData[plr] = hb
end

local function removeAllHitboxes()
    for plr, _ in pairs(hitboxData) do
        removeHitbox(plr)
    end
end

spawn(function()
    while true do
        task.wait(0.2)
        if toggleStates["Hitbox Player"] then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player and not (hitboxData[plr] and hitboxData[plr].Parent) then
                    createHitbox(plr)
                end
            end
            for _, hb in pairs(hitboxData) do
                if hb and hb.Parent then
                    hb.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                end
            end
        else
            removeAllHitboxes()
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        if toggleStates["Hitbox Player"] then
            createHitbox(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    removeHitbox(plr)
end)

--==================================================
-- ESP PLAYER
--==================================================

local espData = {}

local function createESP(plr)
    if plr == Player then return end
    if espData[plr] then return end

    local char = plr.Character
    if not char then return end

    local hl = Instance.new("Highlight")
    hl.Name = "PhuHubHL"
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char
    hl.Parent = char

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PhuHubBB"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    billboard.Parent = char

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 18)
    distLabel.Position = UDim2.new(0, 0, 0, 22)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(45, 220, 135)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.GothamSemibold
    distLabel.Parent = billboard

    espData[plr] = {highlight = hl, billboard = billboard, distLabel = distLabel}
end

local function removeESP(plr)
    local data = espData[plr]
    if not data then return end
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    espData[plr] = nil
end

local function removeAllESP()
    for plr, _ in pairs(espData) do
        removeESP(plr)
    end
end

RunService.RenderStepped:Connect(function()
    if not toggleStates["ESP Player"] then return end
    local localRoot = getLocalRoot()
    if not localRoot then return end
    for plr, data in pairs(espData) do
        local char = plr.Character
        if not char then
            removeESP(plr)
        else
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and data.distLabel then
                local dist = (hrp.Position - localRoot.Position).Magnitude
                data.distLabel.Text = string.format("%dm", math.floor(dist))
            end
            if data.highlight and data.highlight.Adornee ~= char then
                data.highlight.Adornee = char
            end
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if data.billboard and data.billboard.Adornee ~= head then
                data.billboard.Adornee = head
            end
        end
    end
end)

spawn(function()
    while true do
        wait(0.3)
        if toggleStates["ESP Player"] then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player and not espData[plr] then
                    createESP(plr)
                end
            end
        else
            removeAllESP()
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        if toggleStates["ESP Player"] then
            createESP(plr)
        end
    end)
    if plr.Character and toggleStates["ESP Player"] then
        createESP(plr)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

--==================================================
-- AUTO KILL
--==================================================

-- Auto Protect shared state (declared before movement loops so they can yield to protection)
local autoProtecting = false
local autoProtectSavedCFrame = nil
local autoProtectSavedCharacter = nil


local function getNearestPlayer()
    local localRoot = getLocalRoot()
    if not localRoot then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local dist = (localRoot.Position - root.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = plr
                    end
                end
            end
        end
    end
    return nearest
end

local function equipAnyTool()
    local char = Player.Character
    if not char then return false end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") then return true end
    end
    local bp = Player:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local hum = char:FindFirstChild("Humanoid")
                if hum then pcall(function() hum:EquipTool(tool) end) return true end
            end
        end
    end
    return false
end

local function activateCurrentTool()
    local char = Player.Character
    if not char then return false end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") then
            pcall(function() c:Activate() end)
            return true
        end
    end
    return false
end

local autoKillRunning = false

local function startAutoKill()
    if autoKillRunning then return end
    autoKillRunning = true
    spawn(function()
        equipAnyTool()
        while autoKillRunning and toggleStates["Auto Kill"] do
            if autoProtecting then
                wait(0.05)
                continue
            end
            local target = getNearestPlayer()
            if target then
                local targetChar = target.Character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")
                local localRoot = getLocalRoot()
                if targetRoot and targetHum and targetHum.Health > 0 and localRoot then
                    local behind = -targetRoot.CFrame.LookVector * 5
                    localRoot.CFrame = CFrame.new(targetRoot.Position + behind + Vector3.new(0, 2, 0), targetRoot.Position)
                    localRoot.Velocity = Vector3.zero
                    localRoot.AssemblyLinearVelocity = Vector3.zero
                    activateCurrentTool()
                    pcall(function() targetHum:TakeDamage(15) end)
                end
            end
            wait(0.02)
        end
        autoKillRunning = false
    end)
end

--==================================================
-- AUTO OWNERSHIP AREA
--==================================================

local function isRedColor(c)
    return c.R > 0.55 and c.G < 0.35 and c.B < 0.35
end

local function isUnderwater(pos)
    local ok, mats = pcall(function()
        local region = Region3.new(pos - Vector3.new(3,3,3), pos + Vector3.new(3,3,3)):ExpandToGrid(4)
        return workspace.Terrain:ReadVoxels(region, 4)
    end)
    if ok and mats then
        local size = mats.Size
        for x = 1, size.X do
            for y = 1, size.Y do
                for z = 1, size.Z do
                    if mats[x][y][z] == Enum.Material.Water then return true end
                end
            end
        end
    end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {Player.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(pos, Vector3.new(0, 400, 0), params)
    if result and result.Instance then
        local n = result.Instance.Name:lower()
        if n:find("water") or n:find("ocean") or n:find("sea") then return true end
        if result.Instance.Material == Enum.Material.Water then return true end
    end
    return false
end

local function isZonePart(part)
    if not part:IsA("BasePart") then return false end
    if part.Transparency > 0.85 then return false end
    if not isRedColor(part.Color) then return false end
    local size = part.Size
    if math.max(size.X, size.Z) < 8 then return false end
    if isUnderwater(part.Position) then return false end
    return true
end

local function findRedZones()
    local zones = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if isZonePart(d) then table.insert(zones, d) end
    end
    return zones
end

local function findNearestZone(zones)
    local localRoot = getLocalRoot()
    if not localRoot then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, z in ipairs(zones) do
        local dist = (z.Position - localRoot.Position).Magnitude
        if dist < nearestDist then nearestDist = dist; nearest = z end
    end
    return nearest
end

local currentZone = nil
local autoOwnershipRunning = false

local function startAutoOwnership()
    if autoOwnershipRunning then return end
    autoOwnershipRunning = true
    spawn(function()
        while autoOwnershipRunning and toggleStates["Auto Ownership Area"] do
            if currentZone and currentZone.Parent and isRedColor(currentZone.Color)
                and not isUnderwater(currentZone.Position) then
            else
                currentZone = nil
                local zones = findRedZones()
                if #zones > 0 then currentZone = findNearestZone(zones) end
            end
            if currentZone then
                local localRoot = getLocalRoot()
                if localRoot then
                    localRoot.CFrame = CFrame.new(currentZone.Position + Vector3.new(0, 4, 0))
                    localRoot.Velocity = Vector3.zero
                end
            end
            wait(0.02)
        end
        autoOwnershipRunning = false
    end)
end

--==================================================
-- AUTO EAT
--==================================================

local function isMeatPart(part)
    if not part:IsA("BasePart") then return false end
    local n = part.Name:lower()
    if n:find("meat") or n:find("food") or n:find("steak")
        or n:find("carcass") or n:find("prey") or n:find("corpse") then
        return true
    end
    local parent = part.Parent
    if parent then
        local pn = parent.Name:lower()
        if pn:find("meat") or pn:find("food") or pn:find("carcass") then
            return true
        end
    end
    return false
end

local function getAllPrompts()
    local prompts = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            table.insert(prompts, d)
        end
    end
    return prompts
end

local function getNearestPrompt(pos, maxDist)
    maxDist = maxDist or 30
    local nearest, nearestDist = nil, math.huge
    for _, p in ipairs(getAllPrompts()) do
        local parent = p.Parent
        if parent and parent:IsA("BasePart") then
            local dist = (parent.Position - pos).Magnitude
            if dist < nearestDist and dist <= maxDist then
                nearestDist = dist
                nearest = p
            end
        end
    end
    return nearest
end

local function findMeats()
    local meats = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if isMeatPart(d) and d.Parent then
            table.insert(meats, d)
        end
    end
    return meats
end

local function findNearestMeat(meats)
    local localRoot = getLocalRoot()
    if not localRoot then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, m in ipairs(meats) do
        if m.Parent then
            local dist = (m.Position - localRoot.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = m
            end
        end
    end
    return nearest
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    if type(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
    end
    pcall(function() ProximityPromptService.PromptTriggered:Fire(prompt, Player) end)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration or 0.1)
        prompt:InputHoldEnd()
    end)
    pcall(function()
        prompt:InputBegin()
        task.wait(0.05)
        prompt:InputEnd()
    end)
end

local function pressKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
    if type(keypress) == "function" then
        pcall(keypress, 0.05)
    end
end

local currentMeat = nil
local autoEatRunning = false

local function startAutoEat()
    if autoEatRunning then return end
    autoEatRunning = true
    spawn(function()
        while autoEatRunning and toggleStates["Auto Eat"] do
            if autoProtecting then
                wait(0.05)
                continue
            end
            local localRoot = getLocalRoot()
            if not localRoot then
                wait(0.2)
            else
                if not currentMeat or not currentMeat.Parent then
                    currentMeat = nil
                    local meats = findMeats()
                    if #meats > 0 then
                        currentMeat = findNearestMeat(meats)
                    end
                end

                if currentMeat and currentMeat.Parent then
                    localRoot.CFrame = CFrame.new(currentMeat.Position + Vector3.new(0, 2, 0))
                    localRoot.Velocity = Vector3.zero

                    local prompt = getNearestPrompt(currentMeat.Position, 30)
                    if prompt then
                        triggerPrompt(prompt)
                    end

                    local char = Player.Character
                    if char then
                        for _, p in ipairs(char:GetDescendants()) do
                            if p:IsA("BasePart") then
                                if type(firetouchinterest) == "function" then
                                    pcall(firetouchinterest, p, currentMeat, 0)
                                    pcall(firetouchinterest, p, currentMeat, 1)
                                end
                            end
                        end
                    end

                    for _, d in ipairs(currentMeat:GetDescendants()) do
                        if d:IsA("ClickDetector") then
                            if type(fireclickdetector) == "function" then
                                pcall(fireclickdetector, d)
                            end
                        end
                    end

                    pressKey(Enum.KeyCode.E)
                end
            end
            wait(0.05)
        end
        autoEatRunning = false
    end)
end

--==================================================
-- AUTO PROTECT
--==================================================

local AUTO_PROTECT_HEIGHT = 300 -- độ cao an toàn trên vị trí hiện tại
local function stopAutoProtect()
    autoProtecting = false
    autoProtectSavedCFrame = nil
    autoProtectSavedCharacter = nil
end

RunService.Heartbeat:Connect(function()
    if not toggleStates["Auto Protect"] then
        if autoProtecting then
            stopAutoProtect()
        end
        return
    end

    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not root or hum.MaxHealth <= 0 then
        return
    end

    -- Character respawned: discard the old saved position.
    if autoProtectSavedCharacter and autoProtectSavedCharacter ~= char then
        autoProtecting = false
        autoProtectSavedCFrame = nil
        autoProtectSavedCharacter = nil
    end

    local healthRatio = hum.Health / hum.MaxHealth

    -- Trigger exactly when health reaches 10% or lower.
    if not autoProtecting and hum.Health > 0 and healthRatio <= AUTO_PROTECT_THRESHOLD then
        autoProtectSavedCFrame = root.CFrame
        autoProtectSavedCharacter = char
        autoProtecting = true
    end

    if autoProtecting then
        -- Stay completely still in the sky while regenerating.
        local skyCFrame = CFrame.new(
            autoProtectSavedCFrame.Position + Vector3.new(0, AUTO_PROTECT_HEIGHT, 0)
        ) * CFrame.fromMatrix(
            Vector3.zero,
            autoProtectSavedCFrame.XVector,
            autoProtectSavedCFrame.YVector,
            autoProtectSavedCFrame.ZVector
        )
        root.CFrame = skyCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        -- Return only after the health bar is full.
        if hum.Health >= hum.MaxHealth - 0.01 then
            root.CFrame = autoProtectSavedCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            stopAutoProtect()
        end
    end
end)

Player.CharacterAdded:Connect(function()
    stopAutoProtect()
end)

--==================================================
-- TOGGLE MONITOR
--==================================================

spawn(function()
    while true do
        wait(0.3)
        if toggleStates["Auto Kill"] and not autoKillRunning then
            startAutoKill()
        elseif not toggleStates["Auto Kill"] and autoKillRunning then
            autoKillRunning = false
        end
        if toggleStates["Auto Ownership Area"] and not autoOwnershipRunning then
            startAutoOwnership()
        elseif not toggleStates["Auto Ownership Area"] and autoOwnershipRunning then
            autoOwnershipRunning = false
            currentZone = nil
        end
        if toggleStates["Auto Eat"] and not autoEatRunning then
            startAutoEat()
        elseif not toggleStates["Auto Eat"] and autoEatRunning then
            autoEatRunning = false
            currentMeat = nil
        end
        if not toggleStates["Auto Protect"] and autoProtecting then
            stopAutoProtect()
        end
    end
end)

--==================================================
-- AUTO SHOW MENU
--==================================================

--==================================================
-- SUBSCRIBE GATE — hiển thị trước menu
--==================================================

Main.Visible = false
LogoToggle.Visible = false

local Gate = Instance.new("Frame")
Gate.Name = "SubscribeGate"
Gate.Size = UDim2.fromOffset(520, 300)
Gate.Position = UDim2.fromScale(0.5, 0.5)
Gate.AnchorPoint = Vector2.new(0.5, 0.5)
Gate.BackgroundColor3 = Color3.fromRGB(12, 17, 19)
Gate.BorderSizePixel = 0
Gate.Parent = ScreenGui

local GateCorner = Instance.new("UICorner")
GateCorner.CornerRadius = UDim.new(0, 16)
GateCorner.Parent = Gate

local GateStroke = Instance.new("UIStroke")
GateStroke.Color = Color3.fromRGB(45, 220, 135)
GateStroke.Thickness = 1.5
GateStroke.Parent = Gate

local GateTitle = Instance.new("TextLabel")
GateTitle.Size = UDim2.new(1, -30, 0, 45)
GateTitle.Position = UDim2.fromOffset(15, 28)
GateTitle.BackgroundTransparency = 1
GateTitle.Text = "PHÚ ROBLOX HUB"
GateTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
GateTitle.TextSize = 25
GateTitle.Font = Enum.Font.GothamBold
GateTitle.Parent = Gate

local GateQuestion = Instance.new("TextLabel")
GateQuestion.Size = UDim2.new(1, -40, 0, 70)
GateQuestion.Position = UDim2.fromOffset(20, 85)
GateQuestion.BackgroundTransparency = 1
GateQuestion.Text = "Bạn đã đăng ký kênh Phú Roblox chưa?"
GateQuestion.TextColor3 = Color3.fromRGB(225, 230, 232)
GateQuestion.TextSize = 19
GateQuestion.Font = Enum.Font.GothamMedium
GateQuestion.TextWrapped = true
GateQuestion.Parent = Gate

local YesBtn = Instance.new("TextButton")
YesBtn.Size = UDim2.fromOffset(200, 55)
YesBtn.Position = UDim2.new(0, 45, 1, -80)
YesBtn.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
YesBtn.BorderSizePixel = 0
YesBtn.Text = "✓  RỒI"
YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
YesBtn.TextSize = 17
YesBtn.Font = Enum.Font.GothamBold
YesBtn.Parent = Gate

local YesCorner = Instance.new("UICorner")
YesCorner.CornerRadius = UDim.new(0, 10)
YesCorner.Parent = YesBtn

local NoBtn = Instance.new("TextButton")
NoBtn.Size = UDim2.fromOffset(200, 55)
NoBtn.Position = UDim2.new(1, -245, 1, -80)
NoBtn.BackgroundColor3 = Color3.fromRGB(65, 76, 82)
NoBtn.BorderSizePixel = 0
NoBtn.Text = "✕  CHƯA"
NoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NoBtn.TextSize = 17
NoBtn.Font = Enum.Font.GothamBold
NoBtn.Parent = Gate

local NoCorner = Instance.new("UICorner")
NoCorner.CornerRadius = UDim.new(0, 10)
NoCorner.Parent = NoBtn

local function closeGateAndOpenMenu()
    Gate.Visible = false
    Main.Visible = true
    LogoToggle.Visible = false
end

YesBtn.MouseButton1Click:Connect(function()
    closeGateAndOpenMenu()
end)

NoBtn.MouseButton1Click:Connect(function()
    GateQuestion.Text = "Bạn chưa đăng ký kênh Phú Roblox =)))\nKhông đăng ký thì không được chơi!"
    GateQuestion.TextColor3 = Color3.fromRGB(255, 100, 100)
    YesBtn.Visible = false
    NoBtn.Visible = false

    task.wait(1.5)

    pcall(function()
        Player:Kick("Bạn chưa đăng ký kênh Phú Roblox =)))")
    end)
end)

print("[PHÚ ROBLOX HUB] Loaded | Executor: " .. EXECUTOR_NAME .. " | Platform: " .. (IS_PC and "PC" or "Mobile"))
print("[PHÚ ROBLOX HUB] Hotkey PC: RightCtrl / K / F1")
