--==================================================
-- PHÚ ROBLOX : HOP SERVER
-- HORIZONTAL SMALL UI
-- DRAGGABLE + AUTO HOP + SAVE
--==================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--==================================================
-- CONFIG
--==================================================

local CONFIG_FILE = "PhuRoblox_HopServer_Config.txt"

local MAX_PLAYERS = 2
local AUTO_HOP_FROM = 4

local YOUTUBE_ID = "112647080082891"
local DISCORD_ID = "10367063073"
local MENU_ICON_ID = "114716788016991"

local YOUTUBE_LINK =
    "https://youtube.com/@phu_roblox"

local DISCORD_LINK =
    "https://discord.gg/2jusQEux88"

local HOPPING = false

--==================================================
-- LOAD AUTO HOP
--==================================================

local AUTO_HOP = false

pcall(function()

    if isfile and isfile(CONFIG_FILE) then

        local saved = readfile(CONFIG_FILE)

        if saved == "true" then
            AUTO_HOP = true
        else
            AUTO_HOP = false
        end

    end

end)

--==================================================
-- SAVE SETTINGS
--==================================================

local function SaveSettings()

    pcall(function()

        if writefile then

            writefile(
                CONFIG_FILE,
                tostring(AUTO_HOP)
            )

        end

    end)

end

--==================================================
-- REMOVE OLD GUI
--==================================================

pcall(function()

    local old =
        CoreGui:FindFirstChild(
            "PhuRobloxHopServer"
        )

    if old then
        old:Destroy()
    end

end)

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name =
    "PhuRobloxHopServer"

ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

--==================================================
-- MAIN MENU
--==================================================

local Main = Instance.new("Frame")

Main.Name = "Main"

Main.Size =
    UDim2.new(0,520,0,310)

Main.Position =
    UDim2.new(0.5,-260,0.5,-155)

Main.BackgroundColor3 =
    Color3.fromRGB(7,17,29)

Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")

MainCorner.CornerRadius =
    UDim.new(0,22)

MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")

MainStroke.Color =
    Color3.fromRGB(20,150,255)

MainStroke.Thickness = 2
MainStroke.Transparency = 0.15

MainStroke.Parent = Main

--==================================================
-- DRAG AREA
--==================================================

local DragArea = Instance.new("Frame")

DragArea.Name = "DragArea"

DragArea.Size =
    UDim2.new(1,-180,0,70)

DragArea.Position =
    UDim2.new(0,0,0,0)

DragArea.BackgroundTransparency = 1
DragArea.Active = true

DragArea.Parent = Main

--==================================================
-- DRAG SYSTEM
--==================================================

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

local function UpdateDrag(input)

    local delta =
        input.Position - dragStart

    Main.Position =
        UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )

end

DragArea.InputBegan:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = true

        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()

            if input.UserInputState ==
                Enum.UserInputState.End then

                dragging = false

            end

        end)

    end

end)

DragArea.InputChanged:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.MouseMovement
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragInput = input

    end

end)

UserInputService.InputChanged:Connect(function(input)

    if input == dragInput
    and dragging then

        UpdateDrag(input)

    end

end)

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")

Title.Size =
    UDim2.new(1,-190,0,40)

Title.Position =
    UDim2.new(0,18,0,13)

Title.BackgroundTransparency = 1

Title.Text =
    "PHÚ ROBLOX : HOP SERVER"

Title.TextColor3 =
    Color3.fromRGB(255,255,255)

Title.TextSize = 21
Title.Font = Enum.Font.GothamBold

Title.TextXAlignment =
    Enum.TextXAlignment.Left

Title.Parent = Main

--==================================================
-- SUBTITLE
--==================================================

local Subtitle = Instance.new("TextLabel")

Subtitle.Size =
    UDim2.new(1,-190,0,25)

Subtitle.Position =
    UDim2.new(0,18,0,48)

Subtitle.BackgroundTransparency = 1

Subtitle.Text =
    "Tìm server ít người - Chơi game mượt hơn"

Subtitle.TextColor3 =
    Color3.fromRGB(160,180,200)

Subtitle.TextSize = 13
Subtitle.Font = Enum.Font.Gotham

Subtitle.TextXAlignment =
    Enum.TextXAlignment.Left

Subtitle.Parent = Main

--==================================================
-- YOUTUBE
--==================================================

local Youtube = Instance.new("ImageButton")

Youtube.Name = "YouTube"

Youtube.Size =
    UDim2.new(0,38,0,38)

Youtube.Position =
    UDim2.new(1,-135,0,15)

Youtube.BackgroundTransparency = 1

Youtube.Image =
    "rbxassetid://112647080082891"

Youtube.ScaleType =
    Enum.ScaleType.Fit

Youtube.Parent = Main

Youtube.MouseButton1Click:Connect(function()

    pcall(function()

        if setclipboard then
            setclipboard(YOUTUBE_LINK)
        end

    end)

end)

--==================================================
-- DISCORD
--==================================================

local Discord = Instance.new("ImageButton")

Discord.Name = "Discord"

Discord.Size =
    UDim2.new(0,38,0,38)

Discord.Position =
    UDim2.new(1,-88,0,15)

Discord.BackgroundTransparency = 1

Discord.Image =
    "rbxassetid://10367063073"

Discord.ScaleType =
    Enum.ScaleType.Fit

Discord.Parent = Main

Discord.MouseButton1Click:Connect(function()

    pcall(function()

        if setclipboard then
            setclipboard(DISCORD_LINK)
        end

    end)

end)

--==================================================
-- STATUS BOX
--==================================================

local StatusBox = Instance.new("Frame")

StatusBox.Size =
    UDim2.new(1,-36,0,82)

StatusBox.Position =
    UDim2.new(0,18,0,78)

StatusBox.BackgroundColor3 =
    Color3.fromRGB(15,29,45)

StatusBox.BorderSizePixel = 0

StatusBox.Parent = Main

local StatusCorner = Instance.new("UICorner")

StatusCorner.CornerRadius =
    UDim.new(0,16)

StatusCorner.Parent = StatusBox

--==================================================
-- PLAYER
--==================================================

local PlayerIcon = Instance.new("TextLabel")

PlayerIcon.Size =
    UDim2.new(0,45,0,45)

PlayerIcon.Position =
    UDim2.new(0,15,0,18)

PlayerIcon.BackgroundTransparency = 1

PlayerIcon.Text = "👥"
PlayerIcon.TextSize = 32

PlayerIcon.Parent = StatusBox

local PlayerTitle = Instance.new("TextLabel")

PlayerTitle.Size =
    UDim2.new(0,150,0,20)

PlayerTitle.Position =
    UDim2.new(0,65,0,12)

PlayerTitle.BackgroundTransparency = 1

PlayerTitle.Text =
    "Người chơi hiện tại"

PlayerTitle.TextColor3 =
    Color3.fromRGB(175,195,215)

PlayerTitle.TextSize = 13
PlayerTitle.Font = Enum.Font.Gotham

PlayerTitle.TextXAlignment =
    Enum.TextXAlignment.Left

PlayerTitle.Parent = StatusBox

local Count = Instance.new("TextLabel")

Count.Size =
    UDim2.new(0,120,0,35)

Count.Position =
    UDim2.new(0,65,0,30)

Count.BackgroundTransparency = 1

Count.Text = "0/2"

Count.TextColor3 =
    Color3.fromRGB(40,190,255)

Count.TextSize = 25
Count.Font = Enum.Font.GothamBold

Count.TextXAlignment =
    Enum.TextXAlignment.Left

Count.Parent = StatusBox

--==================================================
-- DIVIDER
--==================================================

local Divider = Instance.new("Frame")

Divider.Size =
    UDim2.new(0,2,0,55)

Divider.Position =
    UDim2.new(0.50,0,0.5,-27)

Divider.BackgroundColor3 =
    Color3.fromRGB(40,60,80)

Divider.BorderSizePixel = 0

Divider.Parent = StatusBox

--==================================================
-- SERVER STATUS
--==================================================

local ServerIcon = Instance.new("TextLabel")

ServerIcon.Size =
    UDim2.new(0,45,0,45)

ServerIcon.Position =
    UDim2.new(0.55,0,0,18)

ServerIcon.BackgroundTransparency = 1

ServerIcon.Text = "▂▄▆"

ServerIcon.TextColor3 =
    Color3.fromRGB(60,235,90)

ServerIcon.TextSize = 23
ServerIcon.Font = Enum.Font.GothamBold

ServerIcon.Parent = StatusBox

local ServerTitle = Instance.new("TextLabel")

ServerTitle.Size =
    UDim2.new(0,150,0,20)

ServerTitle.Position =
    UDim2.new(0.65,0,0,12)

ServerTitle.BackgroundTransparency = 1

ServerTitle.Text =
    "Trạng thái server"

ServerTitle.TextColor3 =
    Color3.fromRGB(175,195,215)

ServerTitle.TextSize = 13
ServerTitle.Font = Enum.Font.Gotham

ServerTitle.TextXAlignment =
    Enum.TextXAlignment.Left

ServerTitle.Parent = StatusBox

local ServerStatus = Instance.new("TextLabel")

ServerStatus.Size =
    UDim2.new(0,160,0,30)

ServerStatus.Position =
    UDim2.new(0.65,0,0,32)

ServerStatus.BackgroundTransparency = 1

ServerStatus.Text =
    "Bình thường"

ServerStatus.TextColor3 =
    Color3.fromRGB(40,255,120)

ServerStatus.TextSize = 17
ServerStatus.Font = Enum.Font.GothamBold

ServerStatus.TextXAlignment =
    Enum.TextXAlignment.Left

ServerStatus.Parent = StatusBox

--==================================================
-- BUTTON AREA
--==================================================

local ButtonArea = Instance.new("Frame")

ButtonArea.Size =
    UDim2.new(1,-36,0,78)

ButtonArea.Position =
    UDim2.new(0,18,0,170)

ButtonArea.BackgroundTransparency = 1

ButtonArea.Parent = Main

--==================================================
-- AUTO HOP
--==================================================

local AutoButton = Instance.new("TextButton")

AutoButton.Size =
    UDim2.new(0.48,0,1,0)

AutoButton.Position =
    UDim2.new(0,0,0,0)

AutoButton.BorderSizePixel = 0

AutoButton.TextColor3 =
    Color3.fromRGB(255,255,255)

AutoButton.TextSize = 17
AutoButton.Font = Enum.Font.GothamBold

AutoButton.Parent = ButtonArea

local AutoCorner = Instance.new("UICorner")

AutoCorner.CornerRadius =
    UDim.new(0,16)

AutoCorner.Parent = AutoButton

local AutoDesc = Instance.new("TextLabel")

AutoDesc.Size =
    UDim2.new(1,-10,0,20)

AutoDesc.Position =
    UDim2.new(0,5,0,45)

AutoDesc.BackgroundTransparency = 1

AutoDesc.Text =
    "Tự động hop khi ≥ 4 người"

AutoDesc.TextColor3 =
    Color3.fromRGB(235,235,235)

AutoDesc.TextSize = 11
AutoDesc.Font = Enum.Font.Gotham

AutoDesc.Parent = AutoButton

--==================================================
-- HOP SERVER
--==================================================

local HopButton = Instance.new("TextButton")

HopButton.Size =
    UDim2.new(0.48,0,1,0)

HopButton.Position =
    UDim2.new(0.52,0,0,0)

HopButton.BackgroundColor3 =
    Color3.fromRGB(30,110,235)

HopButton.BorderSizePixel = 0

HopButton.TextColor3 =
    Color3.fromRGB(255,255,255)

HopButton.TextSize = 17
HopButton.Font = Enum.Font.GothamBold

HopButton.Text =
    "↻  HOP SERVER"

HopButton.Parent = ButtonArea

local HopCorner = Instance.new("UICorner")

HopCorner.CornerRadius =
    UDim.new(0,16)

HopCorner.Parent = HopButton

local HopDesc = Instance.new("TextLabel")

HopDesc.Size =
    UDim2.new(1,-10,0,20)

HopDesc.Position =
    UDim2.new(0,5,0,45)

HopDesc.BackgroundTransparency = 1

HopDesc.Text =
    "Tìm server ≤ 2 người"

HopDesc.TextColor3 =
    Color3.fromRGB(225,235,255)

HopDesc.TextSize = 11
HopDesc.Font = Enum.Font.Gotham

HopDesc.Parent = HopButton

--==================================================
-- FOOTER
--==================================================

local Footer = Instance.new("Frame")

Footer.Size =
    UDim2.new(1,-36,0,45)

Footer.Position =
    UDim2.new(0,18,0,253)

Footer.BackgroundColor3 =
    Color3.fromRGB(15,29,45)

Footer.BorderSizePixel = 0

Footer.Parent = Main

local FooterCorner = Instance.new("UICorner")

FooterCorner.CornerRadius =
    UDim.new(0,13)

FooterCorner.Parent = Footer

--==================================================
-- MADE BY
--==================================================

local MadeBy = Instance.new("TextLabel")

MadeBy.Size =
    UDim2.new(1,-24,1,0)

MadeBy.Position =
    UDim2.new(0,12,0,0)

MadeBy.BackgroundTransparency = 1

MadeBy.Text =
    "© Made by Phú Roblox"

MadeBy.TextColor3 =
    Color3.fromRGB(170,195,215)

MadeBy.TextSize = 13
MadeBy.Font = Enum.Font.GothamBold

MadeBy.TextXAlignment =
    Enum.TextXAlignment.Center

MadeBy.Parent = Footer

--==================================================
-- SMALL MENU TOGGLE
--==================================================

local ToggleButton = Instance.new("ImageButton")

ToggleButton.Name =
    "MenuToggle"

ToggleButton.Size =
    UDim2.new(0,48,0,48)

ToggleButton.Position =
    UDim2.new(0,12,0.5,-24)

ToggleButton.BackgroundColor3 =
    Color3.fromRGB(8,20,34)

ToggleButton.BorderSizePixel = 0

ToggleButton.Image =
    "rbxassetid://" .. MENU_ICON_ID

ToggleButton.ScaleType =
    Enum.ScaleType.Fit

ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")

ToggleCorner.CornerRadius =
    UDim.new(1,0)

ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")

ToggleStroke.Color =
    Color3.fromRGB(20,170,255)

ToggleStroke.Thickness = 2

ToggleStroke.Parent = ToggleButton

--==================================================
-- UPDATE AUTO BUTTON
--==================================================

local function UpdateAutoButton()

    if AUTO_HOP then

        AutoButton.BackgroundColor3 =
            Color3.fromRGB(30,180,70)

        AutoButton.Text =
            "⏻  AUTO HOP: ON"

    else

        AutoButton.BackgroundColor3 =
            Color3.fromRGB(190,55,55)

        AutoButton.Text =
            "⏻  AUTO HOP: OFF"

    end

end

--==================================================
-- UPDATE COUNT
--==================================================

local function UpdateCount()

    local amount =
        #Players:GetPlayers()

    Count.Text =
        tostring(amount) .. "/2"

    if amount <= 2 then

        ServerStatus.Text =
            "Bình thường"

        ServerStatus.TextColor3 =
            Color3.fromRGB(40,255,120)

    elseif amount == 3 then

        ServerStatus.Text =
            "3 người"

        ServerStatus.TextColor3 =
            Color3.fromRGB(255,210,50)

    else

        ServerStatus.Text =
            "Server đông"

        ServerStatus.TextColor3 =
            Color3.fromRGB(255,70,70)

    end

end

--==================================================
-- HOP SERVER
--==================================================

local function HopServer()

    if HOPPING then
        return
    end

    HOPPING = true

    ServerStatus.Text =
        "Đang tìm..."

    ServerStatus.TextColor3 =
        Color3.fromRGB(255,210,50)

    local success, data = pcall(function()

        local url =
            "https://games.roblox.com/v1/games/"
            .. PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100"

        return HttpService:JSONDecode(
            game:HttpGet(url)
        )

    end)

    if not success
    or not data
    or not data.data then

        ServerStatus.Text =
            "Lỗi tìm server"

        ServerStatus.TextColor3 =
            Color3.fromRGB(255,70,70)

        HOPPING = false

        return
    end

    local servers = {}

    for _, server in ipairs(data.data) do

        if server.id ~= game.JobId
        and server.playing <= MAX_PLAYERS
        and server.playing < server.maxPlayers then

            table.insert(
                servers,
                server.id
            )

        end

    end

    if #servers > 0 then

        local selected =
            servers[
                math.random(
                    1,
                    #servers
                )
            ]

        SaveSettings()

        TeleportService:TeleportToPlaceInstance(
            PlaceId,
            selected,
            LocalPlayer
        )

    else

        ServerStatus.Text =
            "Không tìm thấy"

        ServerStatus.TextColor3 =
            Color3.fromRGB(255,70,70)

        HOPPING = false

    end

end

--==================================================
-- AUTO HOP TOGGLE
--==================================================

AutoButton.MouseButton1Click:Connect(function()

    AUTO_HOP = not AUTO_HOP

    SaveSettings()
    UpdateAutoButton()

    if AUTO_HOP then

        ServerStatus.Text =
            "Auto Hop ON"

        ServerStatus.TextColor3 =
            Color3.fromRGB(40,255,120)

    else

        ServerStatus.Text =
            "Auto Hop OFF"

        ServerStatus.TextColor3 =
            Color3.fromRGB(255,80,80)

    end

end)

--==================================================
-- MANUAL HOP
--==================================================

HopButton.MouseButton1Click:Connect(function()

    HopServer()

end)

--==================================================
-- TOGGLE MENU
--==================================================

local MenuOpen = true

ToggleButton.MouseButton1Click:Connect(function()

    MenuOpen = not MenuOpen

    Main.Visible = MenuOpen

end)

--==================================================
-- AUTO HOP LOOP
--==================================================

task.spawn(function()

    while task.wait(2) do

        if not ScreenGui.Parent then
            break
        end

        UpdateCount()

        local amount =
            #Players:GetPlayers()

        if AUTO_HOP
        and amount >= AUTO_HOP_FROM
        and not HOPPING then

            HopServer()

        end

    end

end)

--==================================================
-- PLAYER EVENTS
--==================================================

Players.PlayerAdded:Connect(function()

    task.wait(0.2)

    UpdateCount()

end)

Players.PlayerRemoving:Connect(function()

    task.wait(0.2)

    UpdateCount()

end)

--==================================================
-- START
--==================================================

UpdateCount()
UpdateAutoButton()