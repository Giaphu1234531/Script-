--[[
    PHÚ ROBLOX HUB
    Auto Teleport Behind (kill target selector) + Auto Ownership + Auto Eat + Auto Protect
    + Speed + Jump + Fly + ESP Player + ESP Health + Hop + Teleport Player
    + SAVE/LOAD CONFIG + EXECUTE MENU EFFECT + CAMERA STABLE
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlaceId = game.PlaceId

local IS_PC = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled

local EXECUTOR_NAME = "Unknown"
pcall(function()
    if type(identifyexecutor) == "function" then
        EXECUTOR_NAME = tostring(identifyexecutor())
    elseif type(getexecutorname) == "function" then
        EXECUTOR_NAME = tostring(getexecutorname())
    end
end)

--==================================================
-- SAVE/LOAD CONFIG
--==================================================

local CONFIG_FILE = "PhuRobloxHub_Config.json"
local CONFIG_FILE_ALT = "PhuRobloxHub_Config.txt"

local function readFile(name)
    if type(readfile) == "function" then
        local ok, res = pcall(readfile, name)
        if ok and res then return res end
    end
    return nil
end

local function writeFile(name, content)
    if type(writefile) == "function" then
        return pcall(writefile, name, content)
    end
    return false
end

local function loadConfig()
    local data = readFile(CONFIG_FILE) or readFile(CONFIG_FILE_ALT)
    if not data then return nil end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(data) end)
    if ok and type(decoded) == "table" then return decoded end
    return nil
end

local function saveConfig(tbl)
    local ok, encoded = pcall(function() return HttpService:JSONEncode(tbl) end)
    if not ok or not encoded then return end
    if not writeFile(CONFIG_FILE, encoded) then writeFile(CONFIG_FILE_ALT, encoded) end
end

local SavedConfig = loadConfig() or {}
local function getSaved(key, default)
    if SavedConfig[key] ~= nil then return SavedConfig[key] end
    return default
end

--==================================================
-- SCREEN GUI
--==================================================

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

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PrimevalEarth_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.DisplayOrder = 999 end)
pcall(function() ScreenGui.Parent = GuiParent end)
if not ScreenGui.Parent then ScreenGui.Parent = Player:WaitForChild("PlayerGui") end

local Scale = Instance.new("UIScale")
Scale.Scale = 1
Scale.Parent = ScreenGui

local Camera = workspace.CurrentCamera

local function updateScale()
    if not Camera then return end
    local vp = Camera.ViewportSize
    local minSize = math.min(vp.X, vp.Y)
    if minSize < 500 then Scale.Scale = 0.78
    elseif minSize < 700 then Scale.Scale = 0.88
    else Scale.Scale = 1 end
end
updateScale()
if Camera then Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end

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
LogoToggle.ZIndex = 500
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = true
        logoDragStart = input.Position
        logoStartPos = LogoToggle.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if logoDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - logoDragStart
        LogoToggle.Position = UDim2.new(logoStartPos.X.Scale, logoStartPos.X.Offset + delta.X, logoStartPos.Y.Scale, logoStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

local Main = Instance.new("CanvasGroup")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(700, 500)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(12, 17, 19)
Main.BorderSizePixel = 0
Main.Visible = false
Main.GroupTransparency = 0
Main.ZIndex = 400
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 65, 68)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.3
MainStroke.Parent = Main

local MainPopScale = Instance.new("UIScale")
MainPopScale.Scale = 1
MainPopScale.Parent = Main

--==================================================
-- EXECUTE MENU EFFECT
--==================================================

local MenuAnimating = false
local SoundService = game:GetService("SoundService")

local function playMenuSound(id, volume, pitch)
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = volume or 0.5
        s.PlaybackSpeed = pitch or 1
        s.Parent = SoundService
        s:Play()
        task.delay(2, function() pcall(function() s:Destroy() end) end)
    end)
end

local function executeOpenMenu()
    if MenuAnimating then return end
    if Main.Visible and Main.GroupTransparency < 0.05 then return end
    MenuAnimating = true
    Main.Visible = true
    Main.GroupTransparency = 1
    MainPopScale.Scale = 0.6
    playMenuSound("rbxassetid://6042053626", 0.5, 1.15)
    MainStroke.Color = Color3.fromRGB(45, 220, 135)
    MainStroke.Thickness = 3
    MainStroke.Transparency = 0
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
    TweenService:Create(MainPopScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    task.delay(0.35, function()
        TweenService:Create(MainStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(55, 65, 68), Thickness = 1, Transparency = 0.3,
        }):Play()
    end)
    task.delay(0.45, function() MenuAnimating = false end)
end

local function executeCloseMenu()
    if MenuAnimating then return end
    if not Main.Visible then return end
    MenuAnimating = true
    playMenuSound("rbxassetid://6042053626", 0.35, 0.75)
    MainStroke.Color = Color3.fromRGB(255, 80, 80)
    MainStroke.Thickness = 3
    MainStroke.Transparency = 0
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 }):Play()
    TweenService:Create(MainPopScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.75 }):Play()
    task.delay(0.22, function()
        Main.Visible = false
        Main.GroupTransparency = 0
        MainPopScale.Scale = 1
        MainStroke.Color = Color3.fromRGB(55, 65, 68)
        MainStroke.Thickness = 1
        MainStroke.Transparency = 0.3
        MenuAnimating = false
    end)
end

--==================================================
-- HEADER
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 75)
Header.BackgroundColor3 = Color3.fromRGB(8, 12, 13)
Header.BorderSizePixel = 0
Header.ZIndex = 401
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
DinoIcon.ZIndex = 402
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
Title.ZIndex = 402
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
SubTitle.ZIndex = 402
SubTitle.Parent = Header

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(45, 45)
Close.Position = UDim2.new(1, -55, 0, 15)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(230, 230, 230)
Close.TextSize = 30
Close.Font = Enum.Font.Gotham
Close.ZIndex = 402
Close.Parent = Header
Close.MouseButton1Click:Connect(function()
    executeCloseMenu()
    task.wait(0.2)
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
Minimize.ZIndex = 402
Minimize.Parent = Header

--==================================================
-- DRAG MENU
--==================================================

local dragging, dragStart, startPos = false, nil, nil
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.K or input.KeyCode == Enum.KeyCode.F1 then
        if Main.Visible then
            executeCloseMenu()
            task.wait(0.2)
            LogoToggle.Visible = true
        else
            executeOpenMenu()
            LogoToggle.Visible = false
        end
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
Sidebar.ZIndex = 401
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
Content.ZIndex = 401
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
ContentTitle.ZIndex = 402
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
ContentScroll.ZIndex = 402
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
    f.ZIndex = 403
    f.Parent = ContentScroll
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = f
    Pages[name] = f
    return f
end

local toggleStates = {}
local sliderStates = {}
local SaveQueued = false

local function queueSave()
    if SaveQueued then return end
    SaveQueued = true
    task.delay(0.5, function()
        SaveQueued = false
        local data = {}
        for k, v in pairs(toggleStates) do data["t_" .. k] = v end
        for k, v in pairs(sliderStates) do data["s_" .. k] = v end
        saveConfig(data)
    end)
end

local function createToggleRow(parent, title, description, default, key)
    local saved = getSaved("t_" .. key, default)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -20, 0, 62)
    Row.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
    Row.BorderSizePixel = 0
    Row.ZIndex = 404
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
    Name.ZIndex = 405
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
    Desc.ZIndex = 405
    Desc.Parent = Row

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.fromOffset(60, 32)
    Switch.Position = UDim2.new(1, -72, 0.5, -16)
    Switch.BackgroundColor3 = saved and Color3.fromRGB(35, 190, 110) or Color3.fromRGB(65, 76, 82)
    Switch.BorderSizePixel = 0
    Switch.ZIndex = 405
    Switch.Parent = Row

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.fromOffset(24, 24)
    Circle.Position = saved and UDim2.new(1, -28, 0.5, -12) or UDim2.fromOffset(4, 4)
    Circle.BackgroundColor3 = Color3.fromRGB(240, 245, 245)
    Circle.BorderSizePixel = 0
    Circle.ZIndex = 406
    Circle.Parent = Switch

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.ZIndex = 407
    ClickBtn.Parent = Row

    local enabled = saved
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
        queueSave()
    end)

    return Row
end

local function createSlider(parent, title, min, max, default, callback)
    local saved = getSaved("s_" .. title, default)
    saved = math.clamp(tonumber(saved) or default, min, max)

    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -20, 0, 72)
    Holder.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
    Holder.BorderSizePixel = 0
    Holder.ZIndex = 404
    Holder.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Holder

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 22)
    Label.Position = UDim2.fromOffset(14, 6)
    Label.BackgroundTransparency = 1
    Label.Text = title .. ": " .. string.format("%.1f", saved)
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 405
    Label.Parent = Holder

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -28, 0, 10)
    Bar.Position = UDim2.fromOffset(14, 42)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 55, 60)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 405
    Bar.Parent = Holder

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((saved - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 406
    Fill.Parent = Bar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(18, 18)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new((saved - min) / (max - min), 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(240, 245, 245)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 407
    Knob.Parent = Bar

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local draggingBar = false
    local value = saved

    local function setValue(v, save)
        value = math.clamp(v, min, max)
        local pct = (value - min) / (max - min)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Knob.Position = UDim2.new(pct, 0, 0.5, 0)
        Label.Text = title .. ": " .. string.format("%.1f", value)
        sliderStates[title] = value
        if callback then callback(value) end
        if save then queueSave() end
    end

    local function handleInput(input)
        local pos = input.Position.X - Bar.AbsolutePosition.X
        local pct = math.clamp(pos / Bar.AbsoluteSize.X, 0, 1)
        setValue(min + pct * (max - min), false)
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = true
            handleInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingBar and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            handleInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if draggingBar then draggingBar = false; queueSave() end
        end
    end)

    setValue(saved, false)
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
createToggleRow(mainPage, "Auto Teleport Behind", "Tele sau lưng target (lock, không đánh)", false, "Auto Kill")

--==================================================
-- KILL TARGET SELECTOR (small, auto-updates)
--==================================================

local selectedKillTargetId = nil  -- UserId của target được chọn tay

local targetSelectorFrame = Instance.new("Frame")
targetSelectorFrame.Size = UDim2.new(1, -20, 0, 128)
targetSelectorFrame.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
targetSelectorFrame.BorderSizePixel = 0
targetSelectorFrame.ZIndex = 404
targetSelectorFrame.Parent = mainPage

local tselCorner = Instance.new("UICorner")
tselCorner.CornerRadius = UDim.new(0, 9)
tselCorner.Parent = targetSelectorFrame

local tselTitle = Instance.new("TextLabel")
tselTitle.Size = UDim2.new(1, -20, 0, 22)
tselTitle.Position = UDim2.fromOffset(10, 4)
tselTitle.BackgroundTransparency = 1
tselTitle.Text = "KILL TARGET (chọn tay hoặc auto nearest)"
tselTitle.TextColor3 = Color3.fromRGB(45, 220, 135)
tselTitle.TextSize = 11
tselTitle.Font = Enum.Font.GothamBold
tselTitle.TextXAlignment = Enum.TextXAlignment.Left
tselTitle.ZIndex = 405
tselTitle.Parent = targetSelectorFrame

local tselList = Instance.new("ScrollingFrame")
tselList.Size = UDim2.new(1, -16, 1, -32)
tselList.Position = UDim2.fromOffset(8, 28)
tselList.BackgroundTransparency = 1
tselList.BorderSizePixel = 0
tselList.ScrollBarThickness = 2
tselList.ScrollBarImageColor3 = Color3.fromRGB(45, 220, 135)
tselList.CanvasSize = UDim2.new(0, 0, 0, 0)
tselList.AutomaticCanvasSize = Enum.AutomaticSize.Y
tselList.ScrollingDirection = Enum.ScrollingDirection.Y
tselList.ZIndex = 405
tselList.Parent = tselList.Parent == nil and targetSelectorFrame

local tselLayout = Instance.new("UIListLayout")
tselLayout.Padding = UDim.new(0, 3)
tselLayout.SortOrder = Enum.SortOrder.LayoutOrder
tselLayout.Parent = tselList

local targetButtons = {}  -- [player] = button
local nearestBtn = nil

-- Hàm refresh màu các nút
local function refreshTargetButtonsColor()
    for plr, btn in pairs(targetButtons) do
        if plr.UserId == selectedKillTargetId then
            btn.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 50, 55)
        end
    end
    if nearestBtn then
        if selectedKillTargetId == nil then
            nearestBtn.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
        else
            nearestBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 55)
        end
    end
end

-- Tạo nút "Nearest" (auto)
nearestBtn = Instance.new("TextButton")
nearestBtn.Size = UDim2.new(1, 0, 0, 26)
nearestBtn.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
nearestBtn.BorderSizePixel = 0
nearestBtn.Text = "★ AUTO NEAREST"
nearestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nearestBtn.TextSize = 12
nearestBtn.Font = Enum.Font.GothamBold
nearestBtn.AutoButtonColor = false
nearestBtn.ZIndex = 406
nearestBtn.LayoutOrder = 1
nearestBtn.Parent = tselList

local nbCorner = Instance.new("UICorner")
nbCorner.CornerRadius = UDim.new(0, 6)
nbCorner.Parent = nearestBtn

nearestBtn.MouseButton1Click:Connect(function()
    selectedKillTargetId = nil
    refreshTargetButtonsColor()
end)

-- Tạo nút cho 1 player
local function createTargetButton(plr)
    if plr == Player or targetButtons[plr] then return end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(40, 50, 55)
    btn.BorderSizePixel = 0
    btn.Text = plr.DisplayName .. "  (@" .. plr.Name .. ")"
    btn.TextColor3 = Color3.fromRGB(240, 245, 245)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.AutoButtonColor = false
    btn.ZIndex = 406
    btn.LayoutOrder = 100
    btn.Parent = tselList

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        selectedKillTargetId = plr.UserId
        refreshTargetButtonsColor()
    end)

    plr:GetPropertyChangedSignal("DisplayName"):Connect(function()
        if btn.Parent then
            btn.Text = plr.DisplayName .. "  (@" .. plr.Name .. ")"
        end
    end)

    targetButtons[plr] = btn
end

local function removeTargetButton(plr)
    local btn = targetButtons[plr]
    if btn then btn:Destroy(); targetButtons[plr] = nil end
    if selectedKillTargetId == plr.UserId then
        selectedKillTargetId = nil
        refreshTargetButtonsColor()
    end
end

-- Populate ban đầu
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= Player then createTargetButton(plr) end
end

-- Người mới vào → tự hiện
Players.PlayerAdded:Connect(function(plr)
    createTargetButton(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    removeTargetButton(plr)
end)

--==================================================
-- MAIN page tiếp
--==================================================

createToggleRow(mainPage, "Auto Ownership Area", "Tele vào zone đỏ, chờ xanh", false, "Auto Ownership Area")
createToggleRow(mainPage, "Auto Eat", "Tele tới Meat + Eat", false, "Auto Eat")
createToggleRow(mainPage, "Auto Protect", "≤ HP ngưỡng → tele lên trời, đứng im, đầy máu → về chỗ cũ", false, "Auto Protect")

-- PLAYER
local speedValue = getSaved("s_WalkSpeed", 50)
local jumpValue = getSaved("s_JumpPower", 120)
local flySpeed = getSaved("s_Fly Speed", 150)

createToggleRow(playerPage, "Speed Enabled", "Auto apply WalkSpeed (fix underwater)", false, "Speed Enabled")
createToggleRow(playerPage, "Jump Enabled", "Auto apply JumpPower", false, "Jump Enabled")
createToggleRow(playerPage, "Fly", "Kéo joystick hướng nào bay hướng đó", false, "Fly")

createSlider(playerPage, "WalkSpeed", 16, 500, 50, function(v) speedValue = v end)
createSlider(playerPage, "JumpPower", 50, 500, 120, function(v) jumpValue = v end)
createSlider(playerPage, "Fly Speed", 10, 800, 150, function(v) flySpeed = v end)

-- ESP
createToggleRow(espPage, "ESP Player", "Highlight + tên + @user + khoảng cách", false, "ESP Player")
createToggleRow(espPage, "ESP Health", "Thanh máu nhỏ + số HP trên đầu", false, "ESP Health")

--==================================================
-- TELEPORTS
--==================================================

local tpPlayerRows = {}
local tpSearchQuery = ""

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
tpSearch.ZIndex = 404
tpSearch.Parent = tpPage

local tsp = Instance.new("UIPadding")
tsp.PaddingLeft = UDim.new(0, 14)
tsp.PaddingRight = UDim.new(0, 14)
tsp.Parent = tpSearch

local tsc = Instance.new("UICorner")
tsc.CornerRadius = UDim.new(0, 10)
tsc.Parent = tpSearch

local tss = Instance.new("UIStroke")
tss.Color = Color3.fromRGB(48, 60, 64)
tss.Thickness = 1
tss.Transparency = 0.25
tss.Parent = tpSearch

local tpHeader = Instance.new("Frame")
tpHeader.Size = UDim2.new(1, -20, 0, 46)
tpHeader.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
tpHeader.BorderSizePixel = 0
tpHeader.ZIndex = 404
tpHeader.Parent = tpPage

local tpc = Instance.new("UICorner")
tpc.CornerRadius = UDim.new(0, 10)
tpc.Parent = tpHeader

local tpt = Instance.new("TextLabel")
tpt.Size = UDim2.new(1, -28, 1, 0)
tpt.Position = UDim2.fromOffset(14, 0)
tpt.BackgroundTransparency = 1
tpt.Text = "PLAYERS"
tpt.TextColor3 = Color3.fromRGB(45, 220, 135)
tpt.TextSize = 14
tpt.Font = Enum.Font.GothamBold
tpt.TextXAlignment = Enum.TextXAlignment.Left
tpt.ZIndex = 405
tpt.Parent = tpHeader

local function teleportToPlayer(target)
    if not target then return end
    local localRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    local targetChar = target.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    localRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 3, 0))
    localRoot.Velocity = Vector3.zero
    localRoot.AssemblyLinearVelocity = Vector3.zero
end

local function tpMatchesSearch(plr)
    if tpSearchQuery == "" then return true end
    local q = tpSearchQuery:lower()
    return plr.Name:lower():find(q, 1, true) ~= nil or plr.DisplayName:lower():find(q, 1, true) ~= nil
end

local function updateTeleportRowsVisibility()
    for plr, row in pairs(tpPlayerRows) do
        if row and row.Parent then row.Visible = tpMatchesSearch(plr) end
    end
end

local function createPlayerRow(plr)
    if plr == Player or tpPlayerRows[plr] then return end
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -20, 0, 58)
    Row.BackgroundColor3 = Color3.fromRGB(22, 29, 32)
    Row.BorderSizePixel = 0
    Row.ZIndex = 404
    Row.Parent = tpPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Row

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(48, 60, 64)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.45
    Stroke.Parent = Row

    local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.fromOffset(42, 42)
    Avatar.Position = UDim2.fromOffset(9, 8)
    Avatar.BackgroundColor3 = Color3.fromRGB(35, 44, 47)
    Avatar.BorderSizePixel = 0
    Avatar.ZIndex = 405
    Avatar.Parent = Row
    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = Avatar
    pcall(function()
        Avatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)

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
    DisplayName.ZIndex = 405
    DisplayName.Parent = Row

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
    Username.ZIndex = 405
    Username.Parent = Row

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
    TeleBtn.ZIndex = 406
    TeleBtn.Parent = Row

    local TeleCorner = Instance.new("UICorner")
    TeleCorner.CornerRadius = UDim.new(0, 9)
    TeleCorner.Parent = TeleBtn

    local TeleStroke = Instance.new("UIStroke")
    TeleStroke.Color = Color3.fromRGB(45, 220, 135)
    TeleStroke.Thickness = 1
    TeleStroke.Transparency = 0.3
    TeleStroke.Parent = TeleBtn

    TeleBtn.MouseButton1Click:Connect(function() teleportToPlayer(plr) end)
    TeleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TeleBtn.BackgroundColor3 = Color3.fromRGB(22, 115, 76)
        end
    end)
    TeleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TeleBtn.BackgroundColor3 = Color3.fromRGB(30, 155, 100)
        end
    end)

    plr:GetPropertyChangedSignal("DisplayName"):Connect(function()
        if Row.Parent then DisplayName.Text = plr.DisplayName end
    end)

    tpPlayerRows[plr] = Row
end

local function removePlayerRow(plr)
    local row = tpPlayerRows[plr]
    if row then row:Destroy(); tpPlayerRows[plr] = nil end
end

tpSearch:GetPropertyChangedSignal("Text"):Connect(function()
    tpSearchQuery = tpSearch.Text:gsub("^%s+", ""):gsub("%s+$", "")
    updateTeleportRowsVisibility()
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= Player then createPlayerRow(plr) end
end
Players.PlayerAdded:Connect(function(plr) createPlayerRow(plr); updateTeleportRowsVisibility() end)
Players.PlayerRemoving:Connect(function(plr) removePlayerRow(plr) end)

--==================================================
-- SETTINGS
--==================================================

local HOPPING = false
local MAX_PLAYERS = 2
local MAX_SERVER_PAGES = 10

local autoProtectPercent = getSaved("s_Auto Protect HP", 10)
local AUTO_PROTECT_THRESHOLD = autoProtectPercent / 100
local killDistance = getSaved("s_Kill Distance", 5)

createSlider(settingsPage, "Teleport Distance", 1, 500, killDistance, function(v) killDistance = v end)
createSlider(settingsPage, "Auto Protect HP", 1, 100, autoProtectPercent, function(v)
    autoProtectPercent = math.floor(v + 0.5)
    AUTO_PROTECT_THRESHOLD = autoProtectPercent / 100
end)

local StatusRow = Instance.new("Frame")
StatusRow.Size = UDim2.new(1, -20, 0, 85)
StatusRow.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
StatusRow.BorderSizePixel = 0
StatusRow.ZIndex = 404
StatusRow.Parent = settingsPage

local src = Instance.new("UICorner")
src.CornerRadius = UDim.new(0, 9)
src.Parent = StatusRow

local PlayerCount = Instance.new("TextLabel")
PlayerCount.Size = UDim2.new(0.5, -20, 0, 30)
PlayerCount.Position = UDim2.fromOffset(14, 10)
PlayerCount.BackgroundTransparency = 1
PlayerCount.Text = "0/2"
PlayerCount.TextColor3 = Color3.fromRGB(240, 247, 255)
PlayerCount.TextSize = 22
PlayerCount.Font = Enum.Font.GothamBold
PlayerCount.TextXAlignment = Enum.TextXAlignment.Left
PlayerCount.ZIndex = 405
PlayerCount.Parent = StatusRow

local PTxt = Instance.new("TextLabel")
PTxt.Size = UDim2.new(0.5, -20, 0, 16)
PTxt.Position = UDim2.fromOffset(14, 42)
PTxt.BackgroundTransparency = 1
PTxt.Text = "NGƯỜI CHƠI HIỆN TẠI"
PTxt.TextColor3 = Color3.fromRGB(145, 153, 155)
PTxt.TextSize = 10
PTxt.Font = Enum.Font.GothamBold
PTxt.TextXAlignment = Enum.TextXAlignment.Left
PTxt.ZIndex = 405
PTxt.Parent = StatusRow

local ServerStatus = Instance.new("TextLabel")
ServerStatus.Size = UDim2.new(0.5, -20, 0, 30)
ServerStatus.Position = UDim2.new(0.5, 0, 0, 10)
ServerStatus.BackgroundTransparency = 1
ServerStatus.Text = "Bình thường"
ServerStatus.TextColor3 = Color3.fromRGB(45, 220, 135)
ServerStatus.TextSize = 16
ServerStatus.Font = Enum.Font.GothamBold
ServerStatus.TextXAlignment = Enum.TextXAlignment.Right
ServerStatus.ZIndex = 405
ServerStatus.Parent = StatusRow

local STxt = Instance.new("TextLabel")
STxt.Size = UDim2.new(0.5, -20, 0, 16)
STxt.Position = UDim2.new(0.5, 0, 0, 42)
STxt.BackgroundTransparency = 1
STxt.Text = "TRẠNG THÁI SERVER"
STxt.TextColor3 = Color3.fromRGB(145, 153, 155)
STxt.TextSize = 10
STxt.Font = Enum.Font.GothamBold
STxt.TextXAlignment = Enum.TextXAlignment.Right
STxt.ZIndex = 405
STxt.Parent = StatusRow

local HopRow = Instance.new("Frame")
HopRow.Size = UDim2.new(1, -20, 0, 55)
HopRow.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
HopRow.BorderSizePixel = 0
HopRow.ZIndex = 404
HopRow.Parent = settingsPage

local hrc = Instance.new("UICorner")
hrc.CornerRadius = UDim.new(0, 9)
hrc.Parent = HopRow

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
HopBtn.ZIndex = 405
HopBtn.Parent = HopRow

local hbc = Instance.new("UICorner")
hbc.CornerRadius = UDim.new(0, 8)
hbc.Parent = HopBtn

local hbs = Instance.new("UIStroke")
hbs.Color = Color3.fromRGB(42, 135, 215)
hbs.Thickness = 1
hbs.Transparency = 0.2
hbs.Parent = HopBtn

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
Players.PlayerRemoving:Connect(function() task.wait(0.1); UpdateCount() end)

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
        local ok, res = pcall(function() return request({Url = url, Method = "GET"}).Body end)
        if ok and res then return res end
    end
    return nil
end

local function GetServers()
    local result = {}
    local cursor = ""
    for page = 1, MAX_SERVER_PAGES do
        local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
        local body = safeHttpGet(url)
        if not body then break end
        local success, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not success or not data or not data.data then break end
        for _, server in ipairs(data.data) do
            local playing = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 0
            if server.id ~= game.JobId and playing <= MAX_PLAYERS and playing < maxPlayers then
                table.insert(result, server.id)
            end
        end
        cursor = data.nextPageCursor or ""
        if cursor == "" then break end
        task.wait(0.15)
    end
    return result
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
        HopBtn.Text = "↻  HOP SERVER"
        HopBtn.BackgroundColor3 = Color3.fromRGB(18, 75, 125)
        HOPPING = false
        return
    end
    ServerStatus.Text = "Đang vào server..."
    ServerStatus.TextColor3 = Color3.fromRGB(80, 170, 255)
    HopBtn.Text = "Đang teleport..."
    task.wait(0.3)
    local ok = pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, servers[1], Player) end)
    if not ok then
        for i = 2, math.min(#servers, 5) do
            ok = pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, servers[i], Player) end)
            if ok then break end
            task.wait(0.3)
        end
    end
    if not ok then
        ServerStatus.Text = "Teleport lỗi"
        ServerStatus.TextColor3 = Color3.fromRGB(245, 80, 80)
        HopBtn.Text = "↻  HOP SERVER"
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

local function refreshCanvas()
    task.defer(function()
        local total = 0
        for _, page in pairs(Pages) do
            if page.Visible then
                local layout = page:FindFirstChildOfClass("UIListLayout")
                if layout then total = layout.AbsoluteContentSize.Y end
            end
        end
        if total <= 0 then total = ContentLayout.AbsoluteContentSize.Y end
        ContentScroll.CanvasSize = UDim2.new(0, 0, 0, total + 20)
    end)
end

local function showPage(pageName)
    for name, page in pairs(Pages) do page.Visible = (name == pageName) end
    ContentTitle.Text = pageName
    refreshCanvas()
end

for i, data in ipairs(tabs) do
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -25, 0, 48)
    Button.BackgroundColor3 = i == 1 and Color3.fromRGB(12, 55, 42) or Color3.fromRGB(11, 16, 18)
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.ZIndex = 402
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
    Icon.ZIndex = 403
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
    Label.ZIndex = 403
    Label.Parent = Button

    tabRefs[i] = Button
    Button.MouseButton1Click:Connect(function() selectTab(i); showPage(data.page) end)
end

showPage("Main")

--==================================================
-- LOGO TOGGLE
--==================================================

LogoToggle.MouseButton1Click:Connect(function()
    if Main.Visible then
        executeCloseMenu()
        task.wait(0.2)
        LogoToggle.Visible = true
    else
        executeOpenMenu()
        LogoToggle.Visible = false
    end
end)
LogoToggle.MouseButton1Down:Connect(function()
    if Main.Visible then
        executeCloseMenu()
        task.wait(0.2)
        LogoToggle.Visible = true
    else
        executeOpenMenu()
        LogoToggle.Visible = false
    end
end)
Minimize.MouseButton1Click:Connect(function()
    executeCloseMenu()
    task.wait(0.2)
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
    if dir.Magnitude < 0.01 then bv.Velocity = Vector3.zero else bv.Velocity = dir * speedValue end
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
        if state == Enum.HumanoidStateType.Swimming then applySwimBoost(hum, root) else clearSwimBoost() end
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
    if toggleStates["Jump Enabled"] then hum.UseJumpPower = true; hum.JumpPower = jumpValue end
end)

--==================================================
-- FLY
--==================================================

local flyBV = nil
local flyBG = nil
local swimStateDisabled = false

local function disableSwimState()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end)
    swimStateDisabled = true
end

local function restoreSwimState()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    end)
    swimStateDisabled = false
end

local function cleanupFly()
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
    if swimStateDisabled then restoreSwimState() end
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
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
    flyBV.P = 5000
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "PhuFlyBG"
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 4000
    flyBG.D = 100
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
    disableSwimState()
end

RunService.RenderStepped:Connect(function(dt)
    if not toggleStates["Fly"] then
        if flyBV or flyBG then cleanupFly() end
        return
    end
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if not flyBV or flyBV.Parent ~= hrp then initFly() end
    hum.PlatformStand = true
    if not swimStateDisabled then disableSwimState() end
    pcall(function()
        local s = hum:GetState()
        if s == Enum.HumanoidStateType.Swimming or s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end)

    local cam = workspace.CurrentCamera
    if not cam then return end
    local camLook = cam.CFrame.LookVector
    local camRight = cam.CFrame.RightVector
    local moveDir = hum.MoveDirection
    local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
    if flatLook.Magnitude < 0.001 then flatLook = Vector3.new(0,0,-1) else flatLook = flatLook.Unit end
    local flatRight = Vector3.new(camRight.X, 0, camRight.Z)
    if flatRight.Magnitude < 0.001 then flatRight = Vector3.new(1,0,0) else flatRight = flatRight.Unit end

    local fwd, rgt = 0, 0
    if moveDir.Magnitude > 0.01 then
        fwd = moveDir:Dot(flatLook)
        rgt = moveDir:Dot(flatRight)
    end

    local vInput = 0
    if IS_PC then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vInput = vInput + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vInput = vInput - 1 end
    end

    local dir = Vector3.zero + flatLook * fwd + flatRight * rgt
    if math.abs(fwd) > 0.01 then dir = dir + Vector3.new(0, camLook.Y * fwd * 1.8, 0) end
    if vInput ~= 0 then dir = dir + Vector3.new(0, vInput, 0) end

    local horiz = Vector3.new(dir.X, 0, dir.Z)
    local vert = dir.Y
    local finalVel = Vector3.zero
    if horiz.Magnitude > 0.001 then finalVel = finalVel + horiz.Unit * flySpeed * math.min(horiz.Magnitude, 1) end
    if math.abs(vert) > 0.001 then finalVel = finalVel + Vector3.new(0, math.clamp(vert, -1.5, 1.5) * flySpeed, 0) end
    flyBV.Velocity = finalVel
    flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + camLook)
end)

Player.CharacterAdded:Connect(function() cleanupFly() end)

--==================================================
-- ESP PLAYER + ESP HEALTH
--==================================================

local espData = {}

local function clearESPRecord(plr)
    local data = espData[plr]
    if not data then return end
    if data.highlight then pcall(function() data.highlight:Destroy() end) end
    if data.billboard then pcall(function() data.billboard:Destroy() end) end
    espData[plr] = nil
end

local function buildESP(plr)
    if plr == Player then return end
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head") or root
    if not hum or not root or not head then return end
    if espData[plr] and espData[plr].character ~= char then clearESPRecord(plr) end
    if espData[plr] then return end

    local hl = Instance.new("Highlight")
    hl.Name = "PhuHubHL"
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char
    hl.Parent = char
    hl.Enabled = toggleStates["ESP Player"]

    local bb = Instance.new("BillboardGui")
    bb.Name = "PhuHubBB"
    bb.Size = UDim2.fromOffset(180, 78)
    bb.StudsOffset = Vector3.new(0, 3.8, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Adornee = head
    bb.Parent = char

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Visible = toggleStates["ESP Player"]
    nameLabel.Parent = bb

    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(1, 0, 0, 13)
    userLabel.Position = UDim2.fromOffset(0, 18)
    userLabel.BackgroundTransparency = 1
    userLabel.Text = "@" .. plr.Name
    userLabel.TextColor3 = Color3.fromRGB(190, 198, 200)
    userLabel.TextStrokeTransparency = 0.2
    userLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    userLabel.TextSize = 10
    userLabel.Font = Enum.Font.Gotham
    userLabel.Visible = toggleStates["ESP Player"]
    userLabel.Parent = bb

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 13)
    distLabel.Position = UDim2.fromOffset(0, 31)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(45, 220, 135)
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.TextSize = 10
    distLabel.Font = Enum.Font.GothamSemibold
    distLabel.Visible = toggleStates["ESP Player"]
    distLabel.Parent = bb

    local hpBack = Instance.new("Frame")
    hpBack.Size = UDim2.new(1, -40, 0, 6)
    hpBack.Position = UDim2.new(0, 20, 0, 46)
    hpBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    hpBack.BorderSizePixel = 0
    hpBack.Visible = toggleStates["ESP Health"]
    hpBack.Parent = bb

    local hbc = Instance.new("UICorner")
    hbc.CornerRadius = UDim.new(1, 0)
    hbc.Parent = hpBack

    local hbs = Instance.new("UIStroke")
    hbs.Color = Color3.fromRGB(0, 0, 0)
    hbs.Thickness = 1
    hbs.Transparency = 0.3
    hbs.Parent = hpBack

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(45, 220, 135)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBack

    local hfc = Instance.new("UICorner")
    hfc.CornerRadius = UDim.new(1, 0)
    hfc.Parent = hpFill

    local hpText = Instance.new("TextLabel")
    hpText.Size = UDim2.new(1, 0, 0, 13)
    hpText.Position = UDim2.fromOffset(0, 54)
    hpText.BackgroundTransparency = 1
    hpText.Text = "100%"
    hpText.TextColor3 = Color3.fromRGB(240, 245, 245)
    hpText.TextStrokeTransparency = 0
    hpText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    hpText.TextSize = 10
    hpText.Font = Enum.Font.GothamBold
    hpText.Visible = toggleStates["ESP Health"]
    hpText.Parent = bb

    bb.Enabled = toggleStates["ESP Player"] or toggleStates["ESP Health"]

    espData[plr] = {
        character = char, humanoid = hum, highlight = hl, billboard = bb,
        hpFill = hpFill, hpText = hpText, nameLabel = nameLabel,
        userLabel = userLabel, distLabel = distLabel, hpBack = hpBack,
    }
end

local function removeESP(plr) clearESPRecord(plr) end
local function removeAllESP() for plr in pairs(espData) do clearESPRecord(plr) end end

local function refreshESP(plr, data)
    local char = plr.Character
    if not char or char ~= data.character then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head") or hrp
    local hum = data.humanoid
    if data.highlight then data.highlight.Adornee = char end
    if data.billboard and data.billboard.Adornee ~= head then data.billboard.Adornee = head end
    if data.nameLabel then data.nameLabel.Text = plr.DisplayName end
    if data.userLabel then data.userLabel.Text = "@" .. plr.Name end
    if data.distLabel and hrp then
        local localRoot = getLocalRoot()
        if localRoot then data.distLabel.Text = string.format("%dm", math.floor((hrp.Position - localRoot.Position).Magnitude)) end
    end
    if hum and hum.Parent then
        local maxHealth = math.max(hum.MaxHealth, 1)
        local health = math.clamp(hum.Health, 0, maxHealth)
        local percent = health / maxHealth
        if data.hpFill then
            data.hpFill.Size = UDim2.new(percent, 0, 1, 0)
            if percent <= 0.25 then data.hpFill.BackgroundColor3 = Color3.fromRGB(235, 65, 65)
            elseif percent <= 0.5 then data.hpFill.BackgroundColor3 = Color3.fromRGB(240, 185, 55)
            else data.hpFill.BackgroundColor3 = Color3.fromRGB(45, 220, 135) end
        end
        if data.hpText then
            data.hpText.Text = string.format("%d/%d  •  %d%%", math.floor(health + 0.5), math.floor(maxHealth + 0.5), math.floor(percent * 100 + 0.5))
        end
    end
end

RunService.RenderStepped:Connect(function()
    local espPlayerOn = toggleStates["ESP Player"]
    local espHealthOn = toggleStates["ESP Health"]
    if not espPlayerOn and not espHealthOn then
        if next(espData) then removeAllESP() end
        return
    end
    for plr, data in pairs(espData) do
        local char = plr.Character
        if not char or char ~= data.character then
            clearESPRecord(plr)
            if char then buildESP(plr) end
        else
            if data.highlight then data.highlight.Enabled = espPlayerOn end
            if data.billboard then data.billboard.Enabled = espPlayerOn or espHealthOn end
            if data.nameLabel then data.nameLabel.Visible = espPlayerOn end
            if data.userLabel then data.userLabel.Visible = espPlayerOn end
            if data.distLabel then data.distLabel.Visible = espPlayerOn end
            if data.hpBack then data.hpBack.Visible = espHealthOn end
            if data.hpText then data.hpText.Visible = espHealthOn end
            if espPlayerOn or espHealthOn then refreshESP(plr, data) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            if toggleStates["ESP Player"] or toggleStates["ESP Health"] then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= Player then
                        local data = espData[plr]
                        if not data or data.character ~= plr.Character then buildESP(plr) end
                    end
                end
            end
        end)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        clearESPRecord(plr)
        char:WaitForChild("HumanoidRootPart", 10)
        char:WaitForChild("Humanoid", 10)
        task.wait(0.1)
        if toggleStates["ESP Player"] or toggleStates["ESP Health"] then buildESP(plr) end
    end)
    if plr.Character and (toggleStates["ESP Player"] or toggleStates["ESP Health"]) then
        task.defer(buildESP, plr)
    end
end)
Players.PlayerRemoving:Connect(function(plr) clearESPRecord(plr) end)

--==================================================
-- AUTO TELEPORT BEHIND — CAMERA STABLE + SELECTOR
--==================================================

local autoProtecting = false
local autoProtectSavedCFrame = nil
local autoProtectSavedCharacter = nil

local autoKillTarget = nil
local autoKillTargetId = nil
local autoKillNewTargetAt = 0
local autoKillRunning = false

-- Camera shift queue (dùng BindToRenderStep Camera priority)
local pendingCamShift = Vector3.zero

-- BindToRenderStep SAU default camera để shift camera
RunService:BindToRenderStep("PhuTeleCamShift", Enum.RenderPriority.Camera.Value + 1, function()
    if pendingCamShift.Magnitude > 0.001 then
        local cam = workspace.CurrentCamera
        if cam then
            cam.CFrame = cam.CFrame + pendingCamShift
        end
        pendingCamShift = Vector3.zero
    end
end)

local function getPlayerByUserId(uid)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.UserId == uid then return plr end
    end
    return nil
end

local function refreshTarget()
    if not autoKillTargetId then
        autoKillTarget = nil
        return false
    end
    local plr = getPlayerByUserId(autoKillTargetId)
    if not plr then
        autoKillTarget = nil
        autoKillTargetId = nil
        return false
    end
    autoKillTarget = plr
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    return true
end

local function pickNewTarget()
    local localRoot = getLocalRoot()
    if not localRoot then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local d = (localRoot.Position - root.Position).Magnitude
                    if d < nearestDist then nearestDist = d; nearest = plr end
                end
            end
        end
    end
    return nearest
end

-- Tele sau lưng không giật camera (queue shift qua BindToRenderStep)
local function teleportBehindTarget(localRoot, targetRoot)
    local behind = -targetRoot.CFrame.LookVector * killDistance
    local newPos = targetRoot.Position + behind + Vector3.new(0, 2, 0)
    local newCF = CFrame.new(newPos, targetRoot.Position)

    local oldPos = localRoot.Position
    localRoot.CFrame = newCF
    localRoot.Velocity = Vector3.zero
    if localRoot.AssemblyLinearVelocity then localRoot.AssemblyLinearVelocity = Vector3.zero end
    if localRoot.AssemblyAngularVelocity then localRoot.AssemblyAngularVelocity = Vector3.zero end

    -- Queue camera shift để shift sau khi default camera update
    pendingCamShift = newPos - oldPos
end

local function startAutoKill()
    if autoKillRunning then return end
    autoKillRunning = true
    autoKillTarget = nil
    autoKillTargetId = nil
    autoKillNewTargetAt = 0

    spawn(function()
        while autoKillRunning and toggleStates["Auto Kill"] do
            local ok, err = pcall(function()
                if autoProtecting then
                    wait(0.05)
                else
                    -- Nếu có player chọn tay → dùng target đó
                    if selectedKillTargetId then
                        -- Nếu target chọn tay chết → giữ target, không pick mới
                        local manualPlr = getPlayerByUserId(selectedKillTargetId)
                        if manualPlr then
                            autoKillTarget = manualPlr
                            autoKillTargetId = manualPlr.UserId
                        else
                            -- Target đã rời server → bỏ chọn
                            selectedKillTargetId = nil
                            refreshTargetButtonsColor()
                            autoKillTarget = nil
                            autoKillTargetId = nil
                        end
                    else
                        -- Chế độ auto nearest
                        local targetAlive = refreshTarget()
                        if not targetAlive then
                            if autoKillTargetId ~= nil then
                                autoKillTargetId = nil
                                autoKillTarget = nil
                                autoKillNewTargetAt = tick() + 0.5
                            end
                            if tick() >= autoKillNewTargetAt then
                                local newT = pickNewTarget()
                                if newT then
                                    autoKillTarget = newT
                                    autoKillTargetId = newT.UserId
                                end
                            end
                        end
                    end

                    if autoKillTarget and autoKillTargetId then
                        local char = autoKillTarget.Character
                        local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
                        local targetHum = char and char:FindFirstChild("Humanoid")
                        local localRoot = getLocalRoot()

                        if targetRoot and targetHum and targetHum.Health > 0 and localRoot then
                            -- CHỈ TELE SAU LƯNG, KHÔNG ĐÁNH
                            teleportBehindTarget(localRoot, targetRoot)
                        end
                    end

                    wait(0.02)
                end
            end)
            if not ok then
                warn("[PHÚ HUB] Auto Teleport error: " .. tostring(err))
                wait(0.2)
            end
        end
        autoKillRunning = false
        autoKillTarget = nil
        autoKillTargetId = nil
    end)
end

--==================================================
-- AUTO OWNERSHIP AREA
--==================================================

local function isRedColor(c) return c.R > 0.55 and c.G < 0.35 and c.B < 0.35 end

local function isUnderwater(pos)
    local ok, mats = pcall(function()
        local region = Region3.new(pos - Vector3.new(3,3,3), pos + Vector3.new(3,3,3)):ExpandToGrid(4)
        return workspace.Terrain:ReadVoxels(region, 4)
    end)
    if ok and mats then
        local size = mats.Size
        for x = 1, size.X do for y = 1, size.Y do for z = 1, size.Z do
            if mats[x][y][z] == Enum.Material.Water then return true end
        end end end
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
            pcall(function()
                if currentZone and currentZone.Parent and isRedColor(currentZone.Color) and not isUnderwater(currentZone.Position) then
                    -- keep
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
            end)
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
    if n:find("meat") or n:find("food") or n:find("steak") or n:find("carcass") or n:find("prey") or n:find("corpse") then return true end
    local parent = part.Parent
    if parent then
        local pn = parent.Name:lower()
        if pn:find("meat") or pn:find("food") or pn:find("carcass") then return true end
    end
    return false
end

local function getAllPrompts()
    local prompts = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
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
            if dist < nearestDist and dist <= maxDist then nearestDist = dist; nearest = p end
        end
    end
    return nearest
end

local function findMeats()
    local meats = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if isMeatPart(d) and d.Parent then table.insert(meats, d) end
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
            if dist < nearestDist then nearestDist = dist; nearest = m end
        end
    end
    return nearest
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    if type(fireproximityprompt) == "function" then pcall(fireproximityprompt, prompt) end
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
end

local currentMeat = nil
local autoEatRunning = false

local function startAutoEat()
    if autoEatRunning then return end
    autoEatRunning = true
    spawn(function()
        while autoEatRunning and toggleStates["Auto Eat"] do
            pcall(function()
                if autoProtecting then wait(0.05) else
                    local localRoot = getLocalRoot()
                    if not localRoot then wait(0.2) else
                        if not currentMeat or not currentMeat.Parent then
                            currentMeat = nil
                            local meats = findMeats()
                            if #meats > 0 then currentMeat = findNearestMeat(meats) end
                        end
                        if currentMeat and currentMeat.Parent then
                            localRoot.CFrame = CFrame.new(currentMeat.Position + Vector3.new(0, 2, 0))
                            localRoot.Velocity = Vector3.zero
                            local prompt = getNearestPrompt(currentMeat.Position, 30)
                            if prompt then triggerPrompt(prompt) end
                            local char = Player.Character
                            if char then
                                for _, p in ipairs(char:GetDescendants()) do
                                    if p:IsA("BasePart") and type(firetouchinterest) == "function" then
                                        pcall(firetouchinterest, p, currentMeat, 0)
                                        pcall(firetouchinterest, p, currentMeat, 1)
                                    end
                                end
                            end
                            for _, d in ipairs(currentMeat:GetDescendants()) do
                                if d:IsA("ClickDetector") and type(fireclickdetector) == "function" then
                                    pcall(fireclickdetector, d)
                                end
                            end
                            pressKey(Enum.KeyCode.E)
                        end
                    end
                    wait(0.05)
                end
            end)
        end
        autoEatRunning = false
    end)
end

--==================================================
-- AUTO PROTECT
--==================================================

local AUTO_PROTECT_HEIGHT = 300

local function stopAutoProtect()
    autoProtecting = false
    autoProtectSavedCFrame = nil
    autoProtectSavedCharacter = nil
end

RunService.Heartbeat:Connect(function()
    if not toggleStates["Auto Protect"] then
        if autoProtecting then stopAutoProtect() end
        return
    end
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not root or hum.MaxHealth <= 0 then return end
    if autoProtectSavedCharacter and autoProtectSavedCharacter ~= char then
        autoProtecting = false
        autoProtectSavedCFrame = nil
        autoProtectSavedCharacter = nil
    end
    local healthRatio = hum.Health / hum.MaxHealth
    if not autoProtecting and hum.Health > 0 and healthRatio <= AUTO_PROTECT_THRESHOLD then
        autoProtectSavedCFrame = root.CFrame
        autoProtectSavedCharacter = char
        autoProtecting = true
    end
    if autoProtecting then
        local skyCFrame = CFrame.new(autoProtectSavedCFrame.Position + Vector3.new(0, AUTO_PROTECT_HEIGHT, 0))
            * CFrame.fromMatrix(Vector3.zero, autoProtectSavedCFrame.XVector, autoProtectSavedCFrame.YVector, autoProtectSavedCFrame.ZVector)
        root.CFrame = skyCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
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
    autoKillTarget = nil
    autoKillTargetId = nil
    autoKillNewTargetAt = 0
end)

--==================================================
-- TOGGLE MONITOR
--==================================================

spawn(function()
    while true do
        wait(0.3)
        pcall(function()
            if toggleStates["Auto Kill"] and not autoKillRunning then startAutoKill()
            elseif not toggleStates["Auto Kill"] and autoKillRunning then
                autoKillRunning = false
                autoKillTarget = nil
                autoKillTargetId = nil
            end
            if toggleStates["Auto Ownership Area"] and not autoOwnershipRunning then startAutoOwnership()
            elseif not toggleStates["Auto Ownership Area"] and autoOwnershipRunning then
                autoOwnershipRunning = false
                currentZone = nil
            end
            if toggleStates["Auto Eat"] and not autoEatRunning then startAutoEat()
            elseif not toggleStates["Auto Eat"] and autoEatRunning then
                autoEatRunning = false
                currentMeat = nil
            end
            if not toggleStates["Auto Protect"] and autoProtecting then stopAutoProtect() end
        end)
    end
end)

--==================================================
-- SUBSCRIBE GATE
--==================================================

Main.Visible = false
LogoToggle.Visible = false

local Gate = Instance.new("Frame")
Gate.Size = UDim2.fromOffset(520, 300)
Gate.Position = UDim2.fromScale(0.5, 0.5)
Gate.AnchorPoint = Vector2.new(0.5, 0.5)
Gate.BackgroundColor3 = Color3.fromRGB(12, 17, 19)
Gate.BorderSizePixel = 0
Gate.ZIndex = 500
Gate.Parent = ScreenGui

local gc = Instance.new("UICorner")
gc.CornerRadius = UDim.new(0, 16)
gc.Parent = Gate

local gs = Instance.new("UIStroke")
gs.Color = Color3.fromRGB(45, 220, 135)
gs.Thickness = 1.5
gs.Parent = Gate

local gt = Instance.new("TextLabel")
gt.Size = UDim2.new(1, -30, 0, 45)
gt.Position = UDim2.fromOffset(15, 28)
gt.BackgroundTransparency = 1
gt.Text = "PHÚ ROBLOX HUB"
gt.TextColor3 = Color3.fromRGB(245, 245, 245)
gt.TextSize = 25
gt.Font = Enum.Font.GothamBold
gt.ZIndex = 501
gt.Parent = Gate

local gq = Instance.new("TextLabel")
gq.Size = UDim2.new(1, -40, 0, 70)
gq.Position = UDim2.fromOffset(20, 85)
gq.BackgroundTransparency = 1
gq.Text = "Bạn đã đăng ký kênh Phú Roblox chưa?"
gq.TextColor3 = Color3.fromRGB(225, 230, 232)
gq.TextSize = 19
gq.Font = Enum.Font.GothamMedium
gq.TextWrapped = true
gq.ZIndex = 501
gq.Parent = Gate

local YesBtn = Instance.new("TextButton")
YesBtn.Size = UDim2.fromOffset(200, 55)
YesBtn.Position = UDim2.new(0, 45, 1, -80)
YesBtn.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
YesBtn.BorderSizePixel = 0
YesBtn.Text = "✓  RỒI"
YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
YesBtn.TextSize = 17
YesBtn.Font = Enum.Font.GothamBold
YesBtn.ZIndex = 501
YesBtn.Parent = Gate

local yc = Instance.new("UICorner")
yc.CornerRadius = UDim.new(0, 10)
yc.Parent = YesBtn

local NoBtn = Instance.new("TextButton")
NoBtn.Size = UDim2.fromOffset(200, 55)
NoBtn.Position = UDim2.new(1, -245, 1, -80)
NoBtn.BackgroundColor3 = Color3.fromRGB(65, 76, 82)
NoBtn.BorderSizePixel = 0
NoBtn.Text = "✕  CHƯA"
NoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NoBtn.TextSize = 17
NoBtn.Font = Enum.Font.GothamBold
NoBtn.ZIndex = 501
NoBtn.Parent = Gate

local nc = Instance.new("UICorner")
nc.CornerRadius = UDim.new(0, 10)
nc.Parent = NoBtn

YesBtn.MouseButton1Click:Connect(function()
    Gate.Visible = false
    executeOpenMenu()
    LogoToggle.Visible = false
end)

NoBtn.MouseButton1Click:Connect(function()
    gq.Text = "Bạn chưa đăng ký kênh Phú Roblox =)))\nKhông đăng ký thì không được chơi!"
    gq.TextColor3 = Color3.fromRGB(255, 100, 100)
    YesBtn.Visible = false
    NoBtn.Visible = false
    task.wait(1.5)
    pcall(function() Player:Kick("Bạn chưa đăng ký kênh Phú Roblox =)))") end)
end)

--==================================================
-- SAVE CONFIG LẦN ĐẦU
--==================================================

task.defer(function()
    task.wait(1)
    local data = {}
    for k, v in pairs(toggleStates) do data["t_" .. k] = v end
    for k, v in pairs(sliderStates) do data["s_" .. k] = v end
    saveConfig(data)
end)

print("[PHÚ ROBLOX HUB] Loaded | Executor: " .. EXECUTOR_NAME .. " | Platform: " .. (IS_PC and "PC" or "Mobile"))
