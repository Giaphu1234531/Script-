--[[
    PHÚ ROBLOX HUB — v4
    AUTO REBUILD UI khi game clear PlayerGui
    Auto Teleport Behind + Ownership + Eat + Protect + Speed + Jump + Fly
    + ESP Player + ESP Health + Hop + Teleport Player + Config Save/Load
    Teleport Distance: 1 → 30
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGuiService = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer
local PlaceId = game.PlaceId
local IS_PC = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled

local EXECUTOR_NAME = "Unknown"
pcall(function()
    if type(identifyexecutor) == "function" then EXECUTOR_NAME = tostring(identifyexecutor())
    elseif type(getexecutorname) == "function" then EXECUTOR_NAME = tostring(getexecutorname()) end
end)

--==================================================
-- CONFIG
--==================================================
local CONFIG_FILE = "PhuRobloxHub_Config.json"
local CONFIG_FILE_ALT = "PhuRobloxHub_Config.txt"

local function readFile(n)
    if type(readfile) == "function" then
        local ok, r = pcall(readfile, n); if ok and r then return r end
    end
    return nil
end
local function writeFile(n, c)
    if type(writefile) == "function" then return pcall(writefile, n, c) end
    return false
end
local function loadConfig()
    local d = readFile(CONFIG_FILE) or readFile(CONFIG_FILE_ALT)
    if not d then return nil end
    local ok, dec = pcall(function() return HttpService:JSONDecode(d) end)
    if ok and type(dec) == "table" then return dec end
    return nil
end
local function saveConfig(t)
    local ok, e = pcall(function() return HttpService:JSONEncode(t) end)
    if not ok or not e then return end
    if not writeFile(CONFIG_FILE, e) then writeFile(CONFIG_FILE_ALT, e) end
end

local SavedConfig = loadConfig() or {}
local function getSaved(k, d)
    if SavedConfig[k] ~= nil then return SavedConfig[k] end
    return d
end

--==================================================
-- STATE
--==================================================
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

local speedValue = getSaved("s_WalkSpeed", 50)
local jumpValue = getSaved("s_JumpPower", 120)
local flySpeed = getSaved("s_Fly Speed", 150)

-- Teleport Distance — clamp 1..30
local killDistance = tonumber(getSaved("s_Kill Distance", 5)) or 5
if killDistance < 1 then killDistance = 1 end
if killDistance > 30 then killDistance = 30 end

local autoProtectPercent = getSaved("s_Auto Protect HP", 10)
local AUTO_PROTECT_THRESHOLD = autoProtectPercent / 100
local selectedKillTargetId = nil

--==================================================
-- PARENT CHOOSER
--==================================================
local PlayerGui = Player:WaitForChild("PlayerGui", 10)

local function testParent(p)
    if not p then return false end
    local ok = pcall(function()
        local t = Instance.new("Folder")
        t.Name = "_phutest_" .. tick()
        t.Parent = p
        t:Destroy()
    end)
    return ok
end

local function getBestParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui and testParent(hui) then return hui, "gethui" end
    end
    if CoreGuiService and testParent(CoreGuiService) then return CoreGuiService, "CoreGui" end
    return PlayerGui, "PlayerGui"
end

local function cleanupOld()
    local parents = {PlayerGui, CoreGuiService}
    if type(gethui) == "function" then
        local ok, h = pcall(gethui); if ok and h then table.insert(parents, h) end
    end
    for _, p in ipairs(parents) do
        if p then
            for _, n in ipairs({"PrimevalEarth_UI", "PhuRobloxHub"}) do
                local o = p:FindFirstChild(n)
                if o then pcall(function() o:Destroy() end) end
            end
        end
    end
end
cleanupOld()

--==================================================
-- REFS
--==================================================
local Refs = {
    ScreenGui = nil, LogoToggle = nil, Main = nil, ContentScroll = nil,
    Pages = {}, targetButtons = {}, tpPlayerRows = {}, nearestBtn = nil,
    MainStroke = nil, MainPopScale = nil, LogoStroke = nil,
}

local MenuAnimating = false
local dragging = false
local dragStart, startPos = nil, nil
local logoDragging, logoDragStart, logoStartPos = false, nil, nil

--==================================================
-- SOUND
--==================================================
local function playMenuSound(id, vol, pitch)
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id; s.Volume = vol or 0.5; s.PlaybackSpeed = pitch or 1
        s.Parent = SoundService; s:Play()
        task.delay(2, function() pcall(function() s:Destroy() end) end)
    end)
end

--==================================================
-- EXECUTE MENU
--==================================================
local function executeOpenMenu()
    if MenuAnimating then return end
    if not Refs.Main then return end
    if Refs.Main.Visible and Refs.Main.GroupTransparency < 0.05 then return end
    MenuAnimating = true
    Refs.Main.Visible = true
    Refs.Main.GroupTransparency = 1
    Refs.MainPopScale.Scale = 0.6
    playMenuSound("rbxassetid://6042053626", 0.5, 1.15)
    Refs.MainStroke.Color = Color3.fromRGB(45, 220, 135)
    Refs.MainStroke.Thickness = 3
    Refs.MainStroke.Transparency = 0
    TweenService:Create(Refs.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
    TweenService:Create(Refs.MainPopScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    task.delay(0.35, function()
        if Refs.MainStroke then
            TweenService:Create(Refs.MainStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(55, 65, 68), Thickness = 1, Transparency = 0.3,
            }):Play()
        end
    end)
    task.delay(0.45, function() MenuAnimating = false end)
end

local function executeCloseMenu()
    if MenuAnimating then return end
    if not Refs.Main or not Refs.Main.Visible then return end
    MenuAnimating = true
    playMenuSound("rbxassetid://6042053626", 0.35, 0.75)
    Refs.MainStroke.Color = Color3.fromRGB(255, 80, 80)
    Refs.MainStroke.Thickness = 3
    Refs.MainStroke.Transparency = 0
    TweenService:Create(Refs.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 }):Play()
    TweenService:Create(Refs.MainPopScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.75 }):Play()
    task.delay(0.22, function()
        if Refs.Main then
            Refs.Main.Visible = false
            Refs.Main.GroupTransparency = 0
            Refs.MainPopScale.Scale = 1
            Refs.MainStroke.Color = Color3.fromRGB(55, 65, 68)
            Refs.MainStroke.Thickness = 1
            Refs.MainStroke.Transparency = 0.3
        end
        MenuAnimating = false
    end)
end

--==================================================
-- CREATORS
--==================================================
local function createToggleRow(parent, title, desc, default, key)
    local saved = getSaved("t_" .. key, default)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -20, 0, 62)
    Row.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
    Row.BorderSizePixel = 0; Row.ZIndex = 404; Row.Parent = parent

    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 9); Corner.Parent = Row

    local Name = Instance.new("TextLabel")
    Name.Size = UDim2.new(1, -100, 0, 27); Name.Position = UDim2.fromOffset(14, 8)
    Name.BackgroundTransparency = 1; Name.Text = title
    Name.TextColor3 = Color3.fromRGB(240, 240, 240); Name.TextSize = 16
    Name.Font = Enum.Font.GothamMedium; Name.TextXAlignment = Enum.TextXAlignment.Left
    Name.ZIndex = 405; Name.Parent = Row

    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -100, 0, 20); Desc.Position = UDim2.fromOffset(14, 32)
    Desc.BackgroundTransparency = 1; Desc.Text = desc or ""
    Desc.TextColor3 = Color3.fromRGB(145, 153, 155); Desc.TextSize = 12
    Desc.Font = Enum.Font.Gotham; Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.ZIndex = 405; Desc.Parent = Row

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.fromOffset(60, 32); Switch.Position = UDim2.new(1, -72, 0.5, -16)
    Switch.BackgroundColor3 = saved and Color3.fromRGB(35, 190, 110) or Color3.fromRGB(65, 76, 82)
    Switch.BorderSizePixel = 0; Switch.ZIndex = 405; Switch.Parent = Row

    local SC = Instance.new("UICorner"); SC.CornerRadius = UDim.new(1, 0); SC.Parent = Switch

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.fromOffset(24, 24)
    Circle.Position = saved and UDim2.new(1, -28, 0.5, -12) or UDim2.fromOffset(4, 4)
    Circle.BackgroundColor3 = Color3.fromRGB(240, 245, 245); Circle.BorderSizePixel = 0
    Circle.ZIndex = 406; Circle.Parent = Switch

    local CC = Instance.new("UICorner"); CC.CornerRadius = UDim.new(1, 0); CC.Parent = Circle

    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0); ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""; ClickBtn.Active = true; ClickBtn.ZIndex = 407; ClickBtn.Parent = Row

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

local function createSlider(parent, title, min, max, default, cb)
    local saved = getSaved("s_" .. title, default)
    saved = math.clamp(tonumber(saved) or default, min, max)

    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -20, 0, 72)
    Holder.BackgroundColor3 = Color3.fromRGB(26, 34, 37)
    Holder.BorderSizePixel = 0; Holder.ZIndex = 404; Holder.Parent = parent

    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 9); Corner.Parent = Holder

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 22); Label.Position = UDim2.fromOffset(14, 6)
    Label.BackgroundTransparency = 1; Label.Text = title .. ": " .. string.format("%.1f", saved)
    Label.TextColor3 = Color3.fromRGB(240, 240, 240); Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium; Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 405; Label.Parent = Holder

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -28, 0, 10); Bar.Position = UDim2.fromOffset(14, 42)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 55, 60); Bar.BorderSizePixel = 0
    Bar.ZIndex = 405; Bar.Parent = Holder

    local BC = Instance.new("UICorner"); BC.CornerRadius = UDim.new(1, 0); BC.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((saved - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(35, 190, 110); Fill.BorderSizePixel = 0
    Fill.ZIndex = 406; Fill.Parent = Bar

    local FC = Instance.new("UICorner"); FC.CornerRadius = UDim.new(1, 0); FC.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(18, 18); Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new((saved - min) / (max - min), 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(240, 245, 245); Knob.BorderSizePixel = 0
    Knob.ZIndex = 407; Knob.Parent = Bar

    local KC = Instance.new("UICorner"); KC.CornerRadius = UDim.new(1, 0); KC.Parent = Knob

    local draggingBar = false
    local value = saved

    local function setVal(v, save)
        value = math.clamp(v, min, max)
        local pct = (value - min) / (max - min)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Knob.Position = UDim2.new(pct, 0, 0.5, 0)
        Label.Text = title .. ": " .. string.format("%.1f", value)
        sliderStates[title] = value
        if cb then cb(value) end
        if save then queueSave() end
    end
    local function handleInput(input)
        local pos = input.Position.X - Bar.AbsolutePosition.X
        local pct = math.clamp(pos / Bar.AbsoluteSize.X, 0, 1)
        setVal(min + pct * (max - min), false)
    end

    Bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingBar = true; handleInput(i)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingBar and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            handleInput(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if draggingBar then draggingBar = false; queueSave() end
        end
    end)
    setVal(saved, false)
    return Holder
end

--==================================================
-- BUILD UI
--==================================================
local buildUI

buildUI = function()
    cleanupOld()

    Refs.ScreenGui = nil
    Refs.LogoToggle = nil
    Refs.Main = nil
    Refs.ContentScroll = nil
    Refs.Pages = {}
    Refs.targetButtons = {}
    Refs.tpPlayerRows = {}
    Refs.nearestBtn = nil
    Refs.MainStroke = nil
    Refs.MainPopScale = nil
    Refs.LogoStroke = nil

    local parent, pname = getBestParent()

    local sg = Instance.new("ScreenGui")
    sg.Name = "PrimevalEarth_UI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 2147483647
    sg.Enabled = true
    local ok = pcall(function() sg.Parent = parent end)
    if not ok or not sg.Parent then sg.Parent = PlayerGui; pname = "PlayerGui" end
    Refs.ScreenGui = sg

    local Scale = Instance.new("UIScale"); Scale.Scale = 1; Scale.Parent = sg
    local Camera = workspace.CurrentCamera
    local function updateScale()
        if not Camera then return end
        local vp = Camera.ViewportSize; local m = math.min(vp.X, vp.Y)
        if m < 500 then Scale.Scale = 0.78 elseif m < 700 then Scale.Scale = 0.88 else Scale.Scale = 1 end
    end
    updateScale()
    if Camera then Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end

    -- Logo
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
    LogoToggle.Active = true; LogoToggle.ZIndex = 500; LogoToggle.Parent = sg
    Refs.LogoToggle = LogoToggle

    local LC = Instance.new("UICorner"); LC.CornerRadius = UDim.new(1, 0); LC.Parent = LogoToggle
    local LS = Instance.new("UIStroke"); LS.Color = Color3.fromRGB(40, 210, 130); LS.Thickness = 2; LS.Parent = LogoToggle
    Refs.LogoStroke = LS
    local LP = Instance.new("UIPadding")
    LP.PaddingTop = UDim.new(0, 6); LP.PaddingBottom = UDim.new(0, 6)
    LP.PaddingLeft = UDim.new(0, 6); LP.PaddingRight = UDim.new(0, 6); LP.Parent = LogoToggle

    LogoToggle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            logoDragging = true; logoDragStart = i.Position; logoStartPos = LogoToggle.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if logoDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - logoDragStart
            LogoToggle.Position = UDim2.new(logoStartPos.X.Scale, logoStartPos.X.Offset + d.X, logoStartPos.Y.Scale, logoStartPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            logoDragging = false
        end
    end)

    -- Main
    local Main = Instance.new("CanvasGroup")
    Main.Name = "Main"
    Main.Size = UDim2.fromOffset(700, 500)
    Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Color3.fromRGB(12, 17, 19); Main.BorderSizePixel = 0
    Main.Visible = false; Main.GroupTransparency = 0; Main.ZIndex = 400; Main.Parent = sg
    Refs.Main = Main

    local MC = Instance.new("UICorner"); MC.CornerRadius = UDim.new(0, 16); MC.Parent = Main
    local MS = Instance.new("UIStroke"); MS.Color = Color3.fromRGB(55, 65, 68); MS.Thickness = 1; MS.Transparency = 0.3; MS.Parent = Main
    Refs.MainStroke = MS
    local MPS = Instance.new("UIScale"); MPS.Scale = 1; MPS.Parent = Main
    Refs.MainPopScale = MPS

    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 75); Header.BackgroundColor3 = Color3.fromRGB(8, 12, 13)
    Header.BorderSizePixel = 0; Header.ZIndex = 401; Header.Parent = Main

    local HC = Instance.new("UICorner"); HC.CornerRadius = UDim.new(0, 16); HC.Parent = Header

    local DI = Instance.new("TextLabel")
    DI.Size = UDim2.fromOffset(60, 60); DI.Position = UDim2.fromOffset(12, 7)
    DI.BackgroundTransparency = 1; DI.Text = "🦖"; DI.TextSize = 34
    DI.Font = Enum.Font.GothamBold; DI.ZIndex = 402; DI.Parent = Header

    local T = Instance.new("TextLabel")
    T.Size = UDim2.new(1, -170, 0, 30); T.Position = UDim2.fromOffset(72, 10)
    T.BackgroundTransparency = 1; T.Text = "PHÚ ROBLOX HUB"
    T.TextColor3 = Color3.fromRGB(245, 245, 245); T.TextSize = 21
    T.Font = Enum.Font.GothamBold; T.TextXAlignment = Enum.TextXAlignment.Left
    T.ZIndex = 402; T.Parent = Header

    local ST = Instance.new("TextLabel")
    ST.Size = UDim2.new(1, -170, 0, 25); ST.Position = UDim2.fromOffset(72, 39)
    ST.BackgroundTransparency = 1
    ST.Text = "Primeval Earth • " .. (IS_PC and "PC" or "Mobile") .. " [" .. EXECUTOR_NAME .. "] • " .. pname
    ST.TextColor3 = Color3.fromRGB(145, 155, 158); ST.TextSize = 12
    ST.Font = Enum.Font.Gotham; ST.TextXAlignment = Enum.TextXAlignment.Left
    ST.ZIndex = 402; ST.Parent = Header

    local Cl = Instance.new("TextButton")
    Cl.Size = UDim2.fromOffset(45, 45); Cl.Position = UDim2.new(1, -55, 0, 15)
    Cl.BackgroundTransparency = 1; Cl.Text = "×"
    Cl.TextColor3 = Color3.fromRGB(230, 230, 230); Cl.TextSize = 30
    Cl.Font = Enum.Font.Gotham; Cl.ZIndex = 402; Cl.Active = true; Cl.Parent = Header
    Cl.MouseButton1Click:Connect(function()
        executeCloseMenu(); task.wait(0.2); if Refs.LogoToggle then Refs.LogoToggle.Visible = true end
    end)

    local Mn = Instance.new("TextButton")
    Mn.Size = UDim2.fromOffset(45, 45); Mn.Position = UDim2.new(1, -100, 0, 15)
    Mn.BackgroundTransparency = 1; Mn.Text = "—"
    Mn.TextColor3 = Color3.fromRGB(230, 230, 230); Mn.TextSize = 25
    Mn.Font = Enum.Font.Gotham; Mn.ZIndex = 402; Mn.Active = true; Mn.Parent = Header

    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 215, 1, -75); Sidebar.Position = UDim2.fromOffset(0, 75)
    Sidebar.BackgroundColor3 = Color3.fromRGB(11, 16, 18); Sidebar.BorderSizePixel = 0
    Sidebar.ZIndex = 401; Sidebar.Parent = Main

    local SL = Instance.new("UIListLayout")
    SL.Padding = UDim.new(0, 5); SL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SL.SortOrder = Enum.SortOrder.LayoutOrder; SL.Parent = Sidebar
    local SP = Instance.new("UIPadding"); SP.PaddingTop = UDim.new(0, 18); SP.Parent = Sidebar

    -- Content
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -215, 1, -75); Content.Position = UDim2.fromOffset(215, 75)
    Content.BackgroundColor3 = Color3.fromRGB(14, 19, 21); Content.BorderSizePixel = 0
    Content.ZIndex = 401; Content.Parent = Main

    local CT = Instance.new("TextLabel")
    CT.Size = UDim2.new(1, -45, 0, 45); CT.Position = UDim2.fromOffset(25, 18)
    CT.BackgroundTransparency = 1; CT.Text = "Main"
    CT.TextColor3 = Color3.fromRGB(245, 245, 245); CT.TextSize = 25
    CT.Font = Enum.Font.GothamBold; CT.TextXAlignment = Enum.TextXAlignment.Left
    CT.ZIndex = 402; CT.Parent = Content

    local CS = Instance.new("ScrollingFrame")
    CS.Size = UDim2.new(1, -20, 1, -80); CS.Position = UDim2.fromOffset(10, 72)
    CS.BackgroundTransparency = 1; CS.BorderSizePixel = 0
    CS.ScrollBarThickness = 3; CS.ScrollBarImageColor3 = Color3.fromRGB(45, 220, 135)
    CS.CanvasSize = UDim2.new(0, 0, 0, 0); CS.AutomaticCanvasSize = Enum.AutomaticSize.Y
    CS.ScrollingDirection = Enum.ScrollingDirection.Y
    CS.ElasticBehavior = Enum.ElasticBehavior.Never
    CS.Active = true; CS.ZIndex = 402; CS.Parent = Content
    Refs.ContentScroll = CS

    local CL = Instance.new("UIListLayout")
    CL.Padding = UDim.new(0, 6); CL.SortOrder = Enum.SortOrder.LayoutOrder; CL.Parent = CS

    local function createPage(name)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 0); f.AutomaticSize = Enum.AutomaticSize.Y
        f.BackgroundTransparency = 1; f.Visible = false; f.ZIndex = 403; f.Parent = CS
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 6); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = f
        Refs.Pages[name] = f
        return f
    end

    local mainPage = createPage("Main")
    local playerPage = createPage("Player")
    local dinoPage = createPage("Dinosaur")
    local espPage = createPage("ESP")
    local tpPage = createPage("Teleports")
    local settingsPage = createPage("Settings")

    createToggleRow(mainPage, "Auto Teleport Behind", "Tele sau lưng target (lock, không đánh)", false, "Auto Kill")

    -- Kill target selector
    local tsf = Instance.new("Frame")
    tsf.Size = UDim2.new(1, -20, 0, 128)
    tsf.BackgroundColor3 = Color3.fromRGB(26, 34, 37); tsf.BorderSizePixel = 0
    tsf.ZIndex = 404; tsf.Parent = mainPage

    local tsfc = Instance.new("UICorner"); tsfc.CornerRadius = UDim.new(0, 9); tsfc.Parent = tsf

    local tsft = Instance.new("TextLabel")
    tsft.Size = UDim2.new(1, -20, 0, 22); tsft.Position = UDim2.fromOffset(10, 4)
    tsft.BackgroundTransparency = 1
    tsft.Text = "KILL TARGET (chọn tay hoặc auto nearest)"
    tsft.TextColor3 = Color3.fromRGB(45, 220, 135); tsft.TextSize = 11
    tsft.Font = Enum.Font.GothamBold; tsft.TextXAlignment = Enum.TextXAlignment.Left
    tsft.ZIndex = 405; tsft.Parent = tsf

    local tsl = Instance.new("ScrollingFrame")
    tsl.Size = UDim2.new(1, -16, 1, -32); tsl.Position = UDim2.fromOffset(8, 28)
    tsl.BackgroundTransparency = 1; tsl.BorderSizePixel = 0
    tsl.ScrollBarThickness = 2; tsl.ScrollBarImageColor3 = Color3.fromRGB(45, 220, 135)
    tsl.CanvasSize = UDim2.new(0, 0, 0, 0); tsl.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tsl.ScrollingDirection = Enum.ScrollingDirection.Y
    tsl.Active = true; tsl.ZIndex = 405; tsl.Parent = tsf

    local tsll = Instance.new("UIListLayout")
    tsll.Padding = UDim.new(0, 3); tsll.SortOrder = Enum.SortOrder.LayoutOrder; tsll.Parent = tsl

    local function refreshTargetColors()
        for plr, btn in pairs(Refs.targetButtons) do
            pcall(function()
                if plr.UserId == selectedKillTargetId then
                    btn.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(40, 50, 55)
                end
            end)
        end
        if Refs.nearestBtn then
            Refs.nearestBtn.BackgroundColor3 = selectedKillTargetId == nil and Color3.fromRGB(35, 190, 110) or Color3.fromRGB(40, 50, 55)
        end
    end
    _G.__refreshTargetColors = refreshTargetColors

    local nb = Instance.new("TextButton")
    nb.Size = UDim2.new(1, 0, 0, 26); nb.BackgroundColor3 = Color3.fromRGB(35, 190, 110)
    nb.BorderSizePixel = 0; nb.Text = "★ AUTO NEAREST"
    nb.TextColor3 = Color3.fromRGB(255, 255, 255); nb.TextSize = 12
    nb.Font = Enum.Font.GothamBold; nb.AutoButtonColor = false
    nb.Active = true; nb.ZIndex = 406; nb.LayoutOrder = 1; nb.Parent = tsl
    Refs.nearestBtn = nb

    local nbc = Instance.new("UICorner"); nbc.CornerRadius = UDim.new(0, 6); nbc.Parent = nb
    nb.MouseButton1Click:Connect(function()
        selectedKillTargetId = nil
        refreshTargetColors()
    end)

    local function createTargetButton(plr)
        if plr == Player or Refs.targetButtons[plr] then return end
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 26); b.BackgroundColor3 = Color3.fromRGB(40, 50, 55)
        b.BorderSizePixel = 0; b.Text = plr.DisplayName .. "  (@" .. plr.Name .. ")"
        b.TextColor3 = Color3.fromRGB(240, 245, 245); b.TextSize = 12
        b.Font = Enum.Font.GothamMedium; b.TextTruncate = Enum.TextTruncate.AtEnd
        b.AutoButtonColor = false; b.Active = true; b.ZIndex = 406
        b.LayoutOrder = 100; b.Parent = tsl
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
        b.MouseButton1Click:Connect(function()
            selectedKillTargetId = plr.UserId
            refreshTargetColors()
        end)
        Refs.targetButtons[plr] = b
    end
    _G.__createTargetButton = createTargetButton

    for _, plr in ipairs(Players:GetPlayers()) do if plr ~= Player then createTargetButton(plr) end end

    createToggleRow(mainPage, "Auto Ownership Area", "Tele vào zone đỏ, chờ xanh", false, "Auto Ownership Area")
    createToggleRow(mainPage, "Auto Eat", "Tele tới Meat + Eat", false, "Auto Eat")
    createToggleRow(mainPage, "Auto Protect", "≤ HP ngưỡng → tele lên trời", false, "Auto Protect")

    -- PLAYER
    createToggleRow(playerPage, "Speed Enabled", "Auto apply WalkSpeed", false, "Speed Enabled")
    createToggleRow(playerPage, "Jump Enabled", "Auto apply JumpPower", false, "Jump Enabled")
    createToggleRow(playerPage, "Fly", "Kéo joystick hướng nào bay hướng đó", false, "Fly")

    createSlider(playerPage, "WalkSpeed", 16, 500, 50, function(v) speedValue = v end)
    createSlider(playerPage, "JumpPower", 50, 500, 120, function(v) jumpValue = v end)
    createSlider(playerPage, "Fly Speed", 10, 800, 150, function(v) flySpeed = v end)

    -- ESP
    createToggleRow(espPage, "ESP Player", "Highlight + tên + @user", false, "ESP Player")
    createToggleRow(espPage, "ESP Health", "Thanh máu nhỏ", false, "ESP Health")

    -- TELEPORTS
    local tpS = Instance.new("TextBox")
    tpS.Size = UDim2.new(1, -20, 0, 42)
    tpS.BackgroundColor3 = Color3.fromRGB(22, 29, 32); tpS.BorderSizePixel = 0
    tpS.PlaceholderText = "🔎  Tìm tên người chơi..."
    tpS.PlaceholderColor3 = Color3.fromRGB(125, 137, 141); tpS.Text = ""
    tpS.TextColor3 = Color3.fromRGB(240, 245, 245); tpS.TextSize = 14
    tpS.Font = Enum.Font.Gotham; tpS.TextXAlignment = Enum.TextXAlignment.Left
    tpS.ClearTextOnFocus = false; tpS.Active = true; tpS.ZIndex = 404; tpS.Parent = tpPage
    local tpSp = Instance.new("UIPadding"); tpSp.PaddingLeft = UDim.new(0, 14); tpSp.PaddingRight = UDim.new(0, 14); tpSp.Parent = tpS
    local tpSc = Instance.new("UICorner"); tpSc.CornerRadius = UDim.new(0, 10); tpSc.Parent = tpS

    local tpQ = ""
    local function tpMatches(plr)
        if tpQ == "" then return true end
        local q = tpQ:lower()
        return plr.Name:lower():find(q, 1, true) ~= nil or plr.DisplayName:lower():find(q, 1, true) ~= nil
    end
    local function updateTPVis()
        for plr, row in pairs(Refs.tpPlayerRows) do
            if row and row.Parent then row.Visible = tpMatches(plr) end
        end
    end

    local function createTPRow(plr)
        if plr == Player or Refs.tpPlayerRows[plr] then return end
        local R = Instance.new("Frame")
        R.Size = UDim2.new(1, -20, 0, 58); R.BackgroundColor3 = Color3.fromRGB(22, 29, 32)
        R.BorderSizePixel = 0; R.ZIndex = 404; R.Parent = tpPage
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = R

        local Av = Instance.new("ImageLabel")
        Av.Size = UDim2.fromOffset(42, 42); Av.Position = UDim2.fromOffset(9, 8)
        Av.BackgroundColor3 = Color3.fromRGB(35, 44, 47); Av.BorderSizePixel = 0
        Av.ZIndex = 405; Av.Parent = R
        local avc = Instance.new("UICorner"); avc.CornerRadius = UDim.new(1, 0); avc.Parent = Av
        pcall(function()
            Av.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)

        local DN = Instance.new("TextLabel")
        DN.Size = UDim2.new(1, -145, 0, 23); DN.Position = UDim2.fromOffset(61, 7)
        DN.BackgroundTransparency = 1; DN.Text = plr.DisplayName
        DN.TextColor3 = Color3.fromRGB(242, 245, 245); DN.TextSize = 15
        DN.Font = Enum.Font.GothamMedium; DN.TextXAlignment = Enum.TextXAlignment.Left
        DN.ZIndex = 405; DN.Parent = R

        local UN = Instance.new("TextLabel")
        UN.Size = UDim2.new(1, -145, 0, 18); UN.Position = UDim2.fromOffset(61, 31)
        UN.BackgroundTransparency = 1; UN.Text = "@" .. plr.Name
        UN.TextColor3 = Color3.fromRGB(130, 142, 146); UN.TextSize = 11
        UN.Font = Enum.Font.Gotham; UN.TextXAlignment = Enum.TextXAlignment.Left
        UN.ZIndex = 405; UN.Parent = R

        local TB = Instance.new("TextButton")
        TB.Size = UDim2.fromOffset(72, 36); TB.Position = UDim2.new(1, -82, 0.5, -18)
        TB.BackgroundColor3 = Color3.fromRGB(30, 155, 100); TB.BorderSizePixel = 0
        TB.Text = "TP"; TB.TextColor3 = Color3.fromRGB(255, 255, 255)
        TB.TextSize = 14; TB.Font = Enum.Font.GothamBold
        TB.AutoButtonColor = false; TB.Active = true; TB.ZIndex = 406; TB.Parent = R
        local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 9); tbc.Parent = TB

        TB.MouseButton1Click:Connect(function()
            local lr = getLocalRoot()
            if not lr then return end
            local tc = plr.Character
            local tr = tc and tc:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            lr.CFrame = CFrame.new(tr.Position + Vector3.new(0, 3, 0))
            lr.Velocity = Vector3.zero
            if lr.AssemblyLinearVelocity then lr.AssemblyLinearVelocity = Vector3.zero end
        end)

        plr:GetPropertyChangedSignal("DisplayName"):Connect(function()
            if R.Parent then DN.Text = plr.DisplayName end
        end)
        Refs.tpPlayerRows[plr] = R
    end
    _G.__createTPRow = createTPRow

    tpS:GetPropertyChangedSignal("Text"):Connect(function()
        tpQ = tpS.Text:gsub("^%s+", ""):gsub("%s+$", "")
        updateTPVis()
    end)

    for _, plr in ipairs(Players:GetPlayers()) do if plr ~= Player then createTPRow(plr) end end

    -- SETTINGS — Teleport Distance max 30
    createSlider(settingsPage, "Teleport Distance", 1, 30, killDistance, function(v) killDistance = v end)
    createSlider(settingsPage, "Auto Protect HP", 1, 100, autoProtectPercent, function(v)
        autoProtectPercent = math.floor(v + 0.5)
        AUTO_PROTECT_THRESHOLD = autoProtectPercent / 100
    end)

    -- Tabs
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
        for i, b in ipairs(tabRefs) do
            local sel = (i == idx)
            b.BackgroundColor3 = sel and Color3.fromRGB(12, 55, 42) or Color3.fromRGB(11, 16, 18)
            for _, obj in ipairs(b:GetChildren()) do
                if obj:IsA("TextLabel") then
                    if obj.Name == "Icon" then
                        obj.TextColor3 = sel and Color3.fromRGB(45, 220, 135) or Color3.fromRGB(190, 198, 200)
                    elseif obj.Name == "Label" then
                        obj.TextColor3 = sel and Color3.fromRGB(45, 220, 135) or Color3.fromRGB(220, 225, 226)
                    end
                end
            end
        end
    end

    local function refreshCanvas()
        task.defer(function()
            local total = 0
            for _, page in pairs(Refs.Pages) do
                if page.Visible then
                    local l = page:FindFirstChildOfClass("UIListLayout")
                    if l then total = l.AbsoluteContentSize.Y end
                end
            end
            if total <= 0 then total = CL.AbsoluteContentSize.Y end
            if total < 500 then total = 500 end
            CS.CanvasSize = UDim2.new(0, 0, 0, total + 30)
        end)
    end
    _G.__refreshCanvas = refreshCanvas

    local function showPage(n)
        for name, page in pairs(Refs.Pages) do page.Visible = (name == n) end
        CT.Text = n
        CS.CanvasPosition = Vector2.new(0, 0)
        refreshCanvas()
    end
    _G.__showPage = showPage

    for i, d in ipairs(tabs) do
        local B = Instance.new("TextButton")
        B.Size = UDim2.new(1, -25, 0, 48)
        B.BackgroundColor3 = i == 1 and Color3.fromRGB(12, 55, 42) or Color3.fromRGB(11, 16, 18)
        B.BorderSizePixel = 0; B.Text = ""; B.AutoButtonColor = false
        B.Active = true; B.ZIndex = 402; B.Parent = Sidebar
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 9); c.Parent = B

        local Ic = Instance.new("TextLabel")
        Ic.Name = "Icon"; Ic.Size = UDim2.fromOffset(40, 48); Ic.Position = UDim2.fromOffset(5, 0)
        Ic.BackgroundTransparency = 1; Ic.Text = d.icon; Ic.TextSize = 21
        Ic.Font = Enum.Font.Gotham; Ic.TextColor3 = i == 1 and Color3.fromRGB(45, 220, 135) or Color3.fromRGB(190, 198, 200)
        Ic.ZIndex = 403; Ic.Parent = B

        local Lb = Instance.new("TextLabel")
        Lb.Name = "Label"; Lb.Size = UDim2.new(1, -50, 1, 0); Lb.Position = UDim2.fromOffset(48, 0)
        Lb.BackgroundTransparency = 1; Lb.Text = d.text; Lb.TextSize = 16
        Lb.Font = Enum.Font.GothamMedium; Lb.TextXAlignment = Enum.TextXAlignment.Left
        Lb.TextColor3 = i == 1 and Color3.fromRGB(45, 220, 135) or Color3.fromRGB(220, 225, 226)
        Lb.ZIndex = 403; Lb.Parent = B

        tabRefs[i] = B
        B.MouseButton1Click:Connect(function() selectTab(i); showPage(d.page) end)
    end

    showPage("Main")

    LogoToggle.MouseButton1Click:Connect(function()
        if Main.Visible then
            executeCloseMenu(); task.wait(0.2); LogoToggle.Visible = true
        else
            executeOpenMenu(); LogoToggle.Visible = false
        end
    end)
    LogoToggle.MouseButton1Down:Connect(function()
        if Main.Visible then
            executeCloseMenu(); task.wait(0.2); LogoToggle.Visible = true
        else
            executeOpenMenu(); LogoToggle.Visible = false
        end
    end)
    Mn.MouseButton1Click:Connect(function()
        executeCloseMenu(); task.wait(0.2); LogoToggle.Visible = true
    end)

    print("[PHÚ HUB] UI built | Parent: " .. pname)
end

buildUI()

--==================================================
-- LOGO STROKE ANIMATION
--==================================================
spawn(function()
    while true do
        if Refs.LogoStroke and Refs.LogoStroke.Parent then
            pcall(function() Refs.LogoStroke.Transparency = 0; Refs.LogoStroke.Thickness = 2 end)
        end
        task.wait(0.8)
        if Refs.LogoStroke and Refs.LogoStroke.Parent then
            pcall(function() Refs.LogoStroke.Transparency = 0.5; Refs.LogoStroke.Thickness = 3 end)
        end
        task.wait(0.8)
    end
end)

--==================================================
-- WATCHDOG
--==================================================
spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            if not Refs.ScreenGui or not Refs.ScreenGui.Parent then
                warn("[PHÚ HUB] UI destroyed → rebuilding...")
                buildUI()
            else
                if Refs.ScreenGui.Enabled ~= true then Refs.ScreenGui.Enabled = true end
                if Refs.ScreenGui.DisplayOrder ~= 2147483647 then Refs.ScreenGui.DisplayOrder = 2147483647 end
                if Refs.ScreenGui.ResetOnSpawn ~= false then Refs.ScreenGui.ResetOnSpawn = false end
            end
        end)
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(function()
        if not Refs.ScreenGui or not Refs.ScreenGui.Parent then
            buildUI()
        else
            Refs.ScreenGui.Enabled = true
            Refs.ScreenGui.DisplayOrder = 2147483647
        end
    end)
end)

Players.PlayerAdded:Connect(function(plr)
    if _G.__createTargetButton then _G.__createTargetButton(plr) end
    if _G.__createTPRow then _G.__createTPRow(plr) end
end)

Players.PlayerRemoving:Connect(function(plr)
    local tb = Refs.targetButtons[plr]
    if tb then pcall(function() tb:Destroy() end); Refs.targetButtons[plr] = nil end
    if selectedKillTargetId == plr.UserId then
        selectedKillTargetId = nil
        if _G.__refreshTargetColors then _G.__refreshTargetColors() end
    end
    local tr = Refs.tpPlayerRows[plr]
    if tr then pcall(function() tr:Destroy() end); Refs.tpPlayerRows[plr] = nil end
end)

--==================================================
-- HELPERS
--==================================================
local function getLocalRoot()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
_G.getLocalRoot = getLocalRoot

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
        bv = Instance.new("BodyVelocity"); bv.Name = "SwimBoost"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5); bv.P = 1250; bv.Parent = root
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
        if hum:GetState() == Enum.HumanoidStateType.Swimming then
            applySwimBoost(hum, root)
        else clearSwimBoost() end
    else clearSwimBoost() end
    if toggleStates["Jump Enabled"] then
        hum.UseJumpPower = true; hum.JumpPower = jumpValue; hum.JumpHeight = jumpValue * 0.25
    end
end)

Player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if toggleStates["Speed Enabled"] then hum.WalkSpeed = speedValue end
    if toggleStates["Jump Enabled"] then hum.UseJumpPower = true; hum.JumpPower = jumpValue end
end)

--==================================================
-- FLY
--==================================================
local flyBV, flyBG = nil, nil
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
    flyBV = Instance.new("BodyVelocity"); flyBV.Name = "PhuFlyBV"
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9); flyBV.Velocity = Vector3.zero
    flyBV.P = 5000; flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro"); flyBG.Name = "PhuFlyBG"
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9); flyBG.P = 4000; flyBG.D = 100
    flyBG.CFrame = hrp.CFrame; flyBG.Parent = hrp
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
    if moveDir.Magnitude > 0.01 then fwd = moveDir:Dot(flatLook); rgt = moveDir:Dot(flatRight) end
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
-- ESP
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
    hl.Name = "PhuHubHL"; hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char; hl.Parent = char; hl.Enabled = toggleStates["ESP Player"]

    local bb = Instance.new("BillboardGui")
    bb.Name = "PhuHubBB"; bb.Size = UDim2.fromOffset(180, 78)
    bb.StudsOffset = Vector3.new(0, 3.8, 0); bb.AlwaysOnTop = true
    bb.LightInfluence = 0; bb.Adornee = head; bb.Parent = char

    local nL = Instance.new("TextLabel")
    nL.Size = UDim2.new(1, 0, 0, 18); nL.BackgroundTransparency = 1
    nL.Text = plr.DisplayName; nL.TextColor3 = Color3.fromRGB(255, 255, 255)
    nL.TextStrokeTransparency = 0; nL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nL.TextSize = 13; nL.Font = Enum.Font.GothamBold
    nL.Visible = toggleStates["ESP Player"]; nL.Parent = bb

    local uL = Instance.new("TextLabel")
    uL.Size = UDim2.new(1, 0, 0, 13); uL.Position = UDim2.fromOffset(0, 18)
    uL.BackgroundTransparency = 1; uL.Text = "@" .. plr.Name
    uL.TextColor3 = Color3.fromRGB(190, 198, 200); uL.TextStrokeTransparency = 0.2
    uL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); uL.TextSize = 10; uL.Font = Enum.Font.Gotham
    uL.Visible = toggleStates["ESP Player"]; uL.Parent = bb

    local dL = Instance.new("TextLabel")
    dL.Size = UDim2.new(1, 0, 0, 13); dL.Position = UDim2.fromOffset(0, 31)
    dL.BackgroundTransparency = 1; dL.Text = "0m"
    dL.TextColor3 = Color3.fromRGB(45, 220, 135); dL.TextStrokeTransparency = 0.3
    dL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); dL.TextSize = 10
    dL.Font = Enum.Font.GothamSemibold; dL.Visible = toggleStates["ESP Player"]; dL.Parent = bb

    local hb = Instance.new("Frame")
    hb.Size = UDim2.new(1, -40, 0, 6); hb.Position = UDim2.new(0, 20, 0, 46)
    hb.BackgroundColor3 = Color3.fromRGB(30, 30, 30); hb.BorderSizePixel = 0
    hb.Visible = toggleStates["ESP Health"]; hb.Parent = bb

    local hbc = Instance.new("UICorner"); hbc.CornerRadius = UDim.new(1, 0); hbc.Parent = hb
    local hbs = Instance.new("UIStroke"); hbs.Color = Color3.fromRGB(0, 0, 0); hbs.Thickness = 1; hbs.Transparency = 0.3; hbs.Parent = hb

    local hf = Instance.new("Frame")
    hf.Size = UDim2.new(1, 0, 1, 0); hf.BackgroundColor3 = Color3.fromRGB(45, 220, 135)
    hf.BorderSizePixel = 0; hf.Parent = hb
    local hfc = Instance.new("UICorner"); hfc.CornerRadius = UDim.new(1, 0); hfc.Parent = hf

    local hT = Instance.new("TextLabel")
    hT.Size = UDim2.new(1, 0, 0, 13); hT.Position = UDim2.fromOffset(0, 54)
    hT.BackgroundTransparency = 1; hT.Text = "100%"
    hT.TextColor3 = Color3.fromRGB(240, 245, 245); hT.TextStrokeTransparency = 0
    hT.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); hT.TextSize = 10
    hT.Font = Enum.Font.GothamBold; hT.Visible = toggleStates["ESP Health"]; hT.Parent = bb

    bb.Enabled = toggleStates["ESP Player"] or toggleStates["ESP Health"]

    espData[plr] = {character = char, humanoid = hum, highlight = hl, billboard = bb,
        hpFill = hf, hpText = hT, nameLabel = nL, userLabel = uL, distLabel = dL, hpBack = hb}
end

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
        local lr = getLocalRoot()
        if lr then data.distLabel.Text = string.format("%dm", math.floor((hrp.Position - lr.Position).Magnitude)) end
    end
    if hum and hum.Parent then
        local mH = math.max(hum.MaxHealth, 1)
        local h = math.clamp(hum.Health, 0, mH)
        local p = h / mH
        if data.hpFill then
            data.hpFill.Size = UDim2.new(p, 0, 1, 0)
            if p <= 0.25 then data.hpFill.BackgroundColor3 = Color3.fromRGB(235, 65, 65)
            elseif p <= 0.5 then data.hpFill.BackgroundColor3 = Color3.fromRGB(240, 185, 55)
            else data.hpFill.BackgroundColor3 = Color3.fromRGB(45, 220, 135) end
        end
        if data.hpText then
            data.hpText.Text = string.format("%d/%d  •  %d%%", math.floor(h + 0.5), math.floor(mH + 0.5), math.floor(p * 100 + 0.5))
        end
    end
end

RunService.RenderStepped:Connect(function()
    local eP = toggleStates["ESP Player"]
    local eH = toggleStates["ESP Health"]
    if not eP and not eH then
        for plr in pairs(espData) do clearESPRecord(plr) end
        return
    end
    for plr, data in pairs(espData) do
        local char = plr.Character
        if not char or char ~= data.character then
            clearESPRecord(plr)
            if char then buildESP(plr) end
        else
            if data.highlight then data.highlight.Enabled = eP end
            if data.billboard then data.billboard.Enabled = eP or eH end
            if data.nameLabel then data.nameLabel.Visible = eP end
            if data.userLabel then data.userLabel.Visible = eP end
            if data.distLabel then data.distLabel.Visible = eP end
            if data.hpBack then data.hpBack.Visible = eH end
            if data.hpText then data.hpText.Visible = eH end
            if eP or eH then refreshESP(plr, data) end
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
                        local d = espData[plr]
                        if not d or d.character ~= plr.Character then buildESP(plr) end
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
-- AUTO TELEPORT BEHIND
--==================================================
local autoProtecting = false
local autoProtectSavedCFrame = nil
local autoProtectSavedCharacter = nil
local autoKillTarget = nil
local autoKillTargetId = nil
local autoKillNewTargetAt = 0
local autoKillRunning = false
local pendingCamShift = Vector3.zero

RunService:BindToRenderStep("PhuTeleCamShift", Enum.RenderPriority.Camera.Value + 1, function()
    if pendingCamShift.Magnitude > 0.001 then
        local cam = workspace.CurrentCamera
        if cam then cam.CFrame = cam.CFrame + pendingCamShift end
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
    if not autoKillTargetId then autoKillTarget = nil; return false end
    local plr = getPlayerByUserId(autoKillTargetId)
    if not plr then autoKillTarget = nil; autoKillTargetId = nil; return false end
    autoKillTarget = plr
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

local function pickNewTarget()
    local lr = getLocalRoot()
    if not lr then return nil end
    local n, nd = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local d = (lr.Position - root.Position).Magnitude
                    if d < nd then nd = d; n = plr end
                end
            end
        end
    end
    return n
end

local function teleportBehind(localRoot, targetRoot)
    local behind = -targetRoot.CFrame.LookVector * killDistance
    local newPos = targetRoot.Position + behind + Vector3.new(0, 2, 0)
    local newCF = CFrame.new(newPos, targetRoot.Position)
    local oldPos = localRoot.Position
    localRoot.CFrame = newCF
    localRoot.Velocity = Vector3.zero
    if localRoot.AssemblyLinearVelocity then localRoot.AssemblyLinearVelocity = Vector3.zero end
    if localRoot.AssemblyAngularVelocity then localRoot.AssemblyAngularVelocity = Vector3.zero end
    pendingCamShift = newPos - oldPos
end

local function startAutoKill()
    if autoKillRunning then return end
    autoKillRunning = true
    autoKillTarget = nil; autoKillTargetId = nil; autoKillNewTargetAt = 0
    spawn(function()
        while autoKillRunning and toggleStates["Auto Kill"] do
            pcall(function()
                if autoProtecting then wait(0.05) else
                    if selectedKillTargetId then
                        local mp = getPlayerByUserId(selectedKillTargetId)
                        if mp then autoKillTarget = mp; autoKillTargetId = mp.UserId
                        else
                            selectedKillTargetId = nil
                            if _G.__refreshTargetColors then _G.__refreshTargetColors() end
                            autoKillTarget = nil; autoKillTargetId = nil
                        end
                    else
                        local ta = refreshTarget()
                        if not ta then
                            if autoKillTargetId ~= nil then
                                autoKillTargetId = nil; autoKillTarget = nil
                                autoKillNewTargetAt = tick() + 0.5
                            end
                            if tick() >= autoKillNewTargetAt then
                                local nt = pickNewTarget()
                                if nt then autoKillTarget = nt; autoKillTargetId = nt.UserId end
                            end
                        end
                    end
                    if autoKillTarget and autoKillTargetId then
                        local char = autoKillTarget.Character
                        local tR = char and char:FindFirstChild("HumanoidRootPart")
                        local tH = char and char:FindFirstChild("Humanoid")
                        local lr = getLocalRoot()
                        if tR and tH and tH.Health > 0 and lr then teleportBehind(lr, tR) end
                    end
                    wait(0.02)
                end
            end)
        end
        autoKillRunning = false; autoKillTarget = nil; autoKillTargetId = nil
    end)
end

--==================================================
-- AUTO OWNERSHIP
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
    local r = workspace:Raycast(pos, Vector3.new(0, 400, 0), params)
    if r and r.Instance then
        local n = r.Instance.Name:lower()
        if n:find("water") or n:find("ocean") or n:find("sea") then return true end
        if r.Instance.Material == Enum.Material.Water then return true end
    end
    return false
end

local function isZonePart(p)
    if not p:IsA("BasePart") then return false end
    if p.Transparency > 0.85 then return false end
    if not isRedColor(p.Color) then return false end
    if math.max(p.Size.X, p.Size.Z) < 8 then return false end
    if isUnderwater(p.Position) then return false end
    return true
end

local function findRedZones()
    local z = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if isZonePart(d) then table.insert(z, d) end
    end
    return z
end

local function findNearestZone(z)
    local lr = getLocalRoot(); if not lr then return nil end
    local n, nd = nil, math.huge
    for _, zone in ipairs(z) do
        local d = (zone.Position - lr.Position).Magnitude
        if d < nd then nd = d; n = zone end
    end
    return n
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
                else
                    currentZone = nil
                    local z = findRedZones()
                    if #z > 0 then currentZone = findNearestZone(z) end
                end
                if currentZone then
                    local lr = getLocalRoot()
                    if lr then
                        lr.CFrame = CFrame.new(currentZone.Position + Vector3.new(0, 4, 0))
                        lr.Velocity = Vector3.zero
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
local function isMeat(p)
    if not p:IsA("BasePart") then return false end
    local n = p.Name:lower()
    if n:find("meat") or n:find("food") or n:find("steak") or n:find("carcass") or n:find("prey") or n:find("corpse") then return true end
    local par = p.Parent
    if par then
        local pn = par.Name:lower()
        if pn:find("meat") or pn:find("food") or pn:find("carcass") then return true end
    end
    return false
end

local function getPrompts()
    local p = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then table.insert(p, d) end
    end
    return p
end

local function getNearPrompt(pos, maxD)
    maxD = maxD or 30
    local n, nd = nil, math.huge
    for _, p in ipairs(getPrompts()) do
        local par = p.Parent
        if par and par:IsA("BasePart") then
            local d = (par.Position - pos).Magnitude
            if d < nd and d <= maxD then nd = d; n = p end
        end
    end
    return n
end

local function findMeats()
    local m = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if isMeat(d) and d.Parent then table.insert(m, d) end
    end
    return m
end

local function findNearMeat(m)
    local lr = getLocalRoot(); if not lr then return nil end
    local n, nd = nil, math.huge
    for _, mm in ipairs(m) do
        if mm.Parent then
            local d = (mm.Position - lr.Position).Magnitude
            if d < nd then nd = d; n = mm end
        end
    end
    return n
end

local function trigPrompt(p)
    if not p or not p.Parent then return end
    if type(fireproximityprompt) == "function" then pcall(fireproximityprompt, p) end
    pcall(function() ProximityPromptService.PromptTriggered:Fire(p, Player) end)
    pcall(function()
        p:InputHoldBegin(); task.wait(p.HoldDuration or 0.1); p:InputHoldEnd()
    end)
    pcall(function()
        p:InputBegin(); task.wait(0.05); p:InputEnd()
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
                    local lr = getLocalRoot()
                    if not lr then wait(0.2) else
                        if not currentMeat or not currentMeat.Parent then
                            currentMeat = nil
                            local m = findMeats()
                            if #m > 0 then currentMeat = findNearMeat(m) end
                        end
                        if currentMeat and currentMeat.Parent then
                            lr.CFrame = CFrame.new(currentMeat.Position + Vector3.new(0, 2, 0))
                            lr.Velocity = Vector3.zero
                            local p = getNearPrompt(currentMeat.Position, 30)
                            if p then trigPrompt(p) end
                            local c = Player.Character
                            if c then
                                for _, bp in ipairs(c:GetDescendants()) do
                                    if bp:IsA("BasePart") and type(firetouchinterest) == "function" then
                                        pcall(firetouchinterest, bp, currentMeat, 0)
                                        pcall(firetouchinterest, bp, currentMeat, 1)
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
    autoProtecting = false; autoProtectSavedCFrame = nil; autoProtectSavedCharacter = nil
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
        autoProtecting = false; autoProtectSavedCFrame = nil; autoProtectSavedCharacter = nil
    end
    local hr = hum.Health / hum.MaxHealth
    if not autoProtecting and hum.Health > 0 and hr <= AUTO_PROTECT_THRESHOLD then
        autoProtectSavedCFrame = root.CFrame
        autoProtectSavedCharacter = char
        autoProtecting = true
    end
    if autoProtecting then
        local sky = CFrame.new(autoProtectSavedCFrame.Position + Vector3.new(0, AUTO_PROTECT_HEIGHT, 0))
            * CFrame.fromMatrix(Vector3.zero, autoProtectSavedCFrame.XVector, autoProtectSavedCFrame.YVector, autoProtectSavedCFrame.ZVector)
        root.CFrame = sky
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
    autoKillTarget = nil; autoKillTargetId = nil; autoKillNewTargetAt = 0
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
                autoKillRunning = false; autoKillTarget = nil; autoKillTargetId = nil
            end
            if toggleStates["Auto Ownership Area"] and not autoOwnershipRunning then startAutoOwnership()
            elseif not toggleStates["Auto Ownership Area"] and autoOwnershipRunning then
                autoOwnershipRunning = false; currentZone = nil
            end
            if toggleStates["Auto Eat"] and not autoEatRunning then startAutoEat()
            elseif not toggleStates["Auto Eat"] and autoEatRunning then
                autoEatRunning = false; currentMeat = nil
            end
            if not toggleStates["Auto Protect"] and autoProtecting then stopAutoProtect() end
        end)
    end
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

print("[PHÚ ROBLOX HUB] Loaded | Executor: " .. EXECUTOR_NAME)
print("[PHÚ HUB] Teleport Distance: " .. tostring(killDistance) .. " (max 30)")
