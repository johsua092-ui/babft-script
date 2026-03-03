--[[
 ████████████████████████████████████████████████████████████████████████████
 █  ██████╗ ██╗  ██╗██╗   ██╗██╗  ██╗    ██████╗ ███████╗███╗   ██╗
 █  ██╔══██╗╚██╗██╔╝╚██╗ ██╔╝╚██╗██╔╝    ██╔══██╗██╔════╝████╗  ██║
 █  ██║  ██║ ╚███╔╝  ╚████╔╝  ╚███╔╝     ██║  ██║█████╗  ██╔██╗ ██║
 █  ██║  ██║ ██╔██╗   ╚██╔╝   ██╔██╗     ██║  ██║██╔══╝  ██║╚██╗██║
 █  ██████╔╝██╔╝ ██╗   ██║   ██╔╝ ██╗    ██████╔╝███████╗██║ ╚████║
 █  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝
 █
 █  oxyX BABFT Suite v1.2 - SELF-CONTAINED (No HTTP Required!)
 █  Compatible: Xeno / Velocity / Fluxus / Synapse / Hydrogen / etc
 █  Features: OBJ Import | Model Import | Wireframe Mode | Block Inventory
 ████████████████████████████████████████████████████████████████████████████
 
 Cara penggunaan:
 1. Copy semua kode ini
 2. Paste ke executor kamu
 3. Execute!
]]

local SCRIPT_VERSION = "1.2.0"
local SCRIPT_NAME = "oxyX BABFT Suite"
local SCRIPT_TAG = "Ultimate Build Tools"

-- ============================================================
-- EXECUTOR DETECTION
-- ============================================================
local executor = "unknown"
local rawExecutor = "unknown"
local executorIcon = "🔧"

if identifyexecutor then
    rawExecutor = identifyexecutor()
    executor = string.lower(rawExecutor)
elseif syn then
    executor = "synapse"
    rawExecutor = "Synapse X"
    executorIcon = "⚡"
elseif getexecutorname then
    rawExecutor = getexecutorname()
    executor = string.lower(rawExecutor)
elseif isfile and readfile then
    executor = "hasfile"
    rawExecutor = "File Executor"
end

if executor:find("xeno") then executorIcon = "🦊"
elseif executor:find("fluxus") then executorIcon = "🔵"
elseif executor:find("velocity") then executorIcon = "🚀"
elseif executor:find("synapse") then executorIcon = "⚡"
elseif executor:find("hydrogen") then executorIcon = "💧"
elseif executor:find("electron") then executorIcon = "⚛️"
end

print("[oxyX] " .. executorIcon .. " Detected executor: " .. rawExecutor)

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ============================================================
-- GUI PARENT DETECTION
-- ============================================================
local guiParent = nil
local guiSource = "unknown"

local function detectGuiParent()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        guiParent = playerGui
        guiSource = "PlayerGui (direct)"
        print("[oxyX] GUI Parent found: PlayerGui (direct)")
        return true
    end
    
    playerGui = player:WaitForChild("PlayerGui", 5)
    if playerGui then
        guiParent = playerGui
        guiSource = "PlayerGui (waited)"
        print("[oxyX] GUI Parent found: PlayerGui (waited)")
        return true
    end
    
    local success, CoreGui = pcall(game.GetService, game, "CoreGui")
    if success and CoreGui then
        guiParent = CoreGui
        guiSource = "CoreGui"
        print("[oxyX] GUI Parent found: CoreGui")
        return true
    end
    
    local success2, StarterGui2 = pcall(game.GetService, game, "StarterGui")
    if success2 and StarterGui2 then
        guiParent = StarterGui2
        guiSource = "StarterGui"
        print("[oxyX] GUI Parent found: StarterGui")
        return true
    end
    
    warn("[oxyX] Could not find GUI parent!")
    return false
end

detectGuiParent()

-- ============================================================
-- GUI CREATION
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "oxyX_BABFT"
ScreenGui.ResetOnSpawn = false

if guiParent then
    ScreenGui.Parent = guiParent
    print("[oxyX] ScreenGui parented to: " .. guiSource)
else
    warn("[oxyX] No GUI parent, using StarterGui as fallback")
    ScreenGui.Parent = StarterGui
end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 620, 0, 680)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -340)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "oxyX BABFT " .. SCRIPT_VERSION .. " | " .. executorIcon .. " " .. rawExecutor
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.Parent = TitleBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -75, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
MinimizeBtn.Text = "_"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.Parent = TitleBar

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(UDim2.new(0, 620, 0, 50), "Out", "Quad", 0.3)
    else
        MainFrame:TweenSize(UDim2.new(0, 620, 0, 680), "Out", "Quad", 0.3)
    end
end)

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(0, 150, 1, -40)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -150, 1, -40)
ContentArea.Position = UDim2.new(0, 150, 0, 40)
ContentArea.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

-- Create ScrollingFrame for tabs
local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size = UDim2.new(1, 0, 1, 0)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 0
TabScroll.Parent = TabContainer

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabScroll

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local Notifications = {}

local function notify(title, message, duration)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 300, 0, 60)
    notif.Position = UDim2.new(1, -320, 1, -80 - (#Notifications * 70))
    notif.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    notif.BorderSizePixel = 0
    notif.Parent = ScreenGui
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -10, 0, 25)
    msgLabel.Position = UDim2.new(0, 10, 0, 30)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 12
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Parent = notif
    
    table.insert(Notifications, notif)
    
    if duration and duration > 0 then
        task.delay(duration, function()
            notif:TweenPosition(UDim2.new(1.5, 0, notif.Position.Y.Scale, notif.Position.Y.Offset), "Out", "Quad", 0.3)
            task.delay(0.3, function()
                notif:Destroy()
                table.remove(Notifications, 1)
                for i, n in ipairs(Notifications) do
                    n:TweenPosition(UDim2.new(1, -320, 1, -80 - (i - 1) * 70), "Out", "Quad", 0.2)
                end
            end)
        end)
    end
end

-- ============================================================
-- TAB CREATION
-- ============================================================
local tabs = {}
local currentTab = nil

local function createTab(name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, -10, 0, 45)
    tabBtn.Position = UDim2.new(0, 5, 0, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    tabBtn.Text = (icon or "📦") .. " " .. name
    tabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 13
    tabBtn.Parent = TabScroll
    
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, -20, 1, -10)
    tabContent.Position = UDim2.new(0, 10, 0, 5)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 3
    tabContent.Visible = false
    tabContent.Parent = ContentArea
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = tabContent
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.Parent = tabContent
    
    tabs[name] = { button = tabBtn, content = tabContent }
    
    tabBtn.MouseButton1Click:Connect(function()
        for tabName, tabData in pairs(tabs) do
            tabData.content.Visible = false
            tabData.button.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        end
        tabContent.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        currentTab = name
    end)
    
    return tabContent
end

-- ============================================================
-- CREATE TABS
-- ============================================================
local HomeTab = createTab("Home", "🏠")
local ToolsTab = createTab("Tools", "🔧")
local ImportTab = createTab("Import", "📥")
local BuildTab = createTab("Builds", "🏗️")
local SettingsTab = createTab("Settings", "⚙️")

-- ============================================================
-- HOME TAB CONTENT
-- ============================================================
local homeTitle = Instance.new("TextLabel")
homeTitle.Size = UDim2.new(1, 0, 0, 40)
homeTitle.BackgroundTransparency = 1
homeTitle.Text = "oxyX BABFT Suite"
homeTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
homeTitle.Font = Enum.Font.GothamBold
homeTitle.TextSize = 24
homeTitle.Parent = HomeTab

local homeDesc = Instance.new("TextLabel")
homeDesc.Size = UDim2.new(1, 0, 0, 60)
homeDesc.BackgroundTransparency = 1
homeDesc.Text = "Ultimate BABFT Tools\nCompatible: Xeno, Velocity, Fluxus, Synapse"
homeDesc.TextColor3 = Color3.fromRGB(150, 150, 160)
homeDesc.Font = Enum.Font.Gotham
homeDesc.TextSize = 14
homeDesc.TextWrapped = true
homeDesc.Parent = HomeTab

local featuresLabel = Instance.new("TextLabel")
featuresLabel.Size = UDim2.new(1, 0, 0, 200)
featuresLabel.BackgroundTransparency = 1
featuresLabel.Text = [[
Features:
📦 Block Inventory Manager
🖼️ OBJ Image Import
📥 Model Import (Asset ID)
🔲 Wireframe Mode
🏗️ Build Loader
✨ And more...
]]
featuresLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
featuresLabel.Font = Enum.Font.Gotham
featuresLabel.TextSize = 13
featuresLabel.TextWrapped = true
featuresLabel.TextXAlignment = Enum.TextXAlignment.Left
featuresLabel.Parent = HomeTab

-- ============================================================
-- TOOLS TAB
-- ============================================================
local toolsTitle = Instance.new("TextLabel")
toolsTitle.Size = UDim2.new(1, 0, 0, 30)
toolsTitle.BackgroundTransparency = 1
toolsTitle.Text = "Build Tools"
toolsTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
toolsTitle.Font = Enum.Font.GothamBold
toolsTitle.TextSize = 16
toolsTitle.Parent = ToolsTab

-- God Mode Toggle
local godModeToggle = Instance.new("TextButton")
godModeToggle.Size = UDim2.new(1, 0, 0, 40)
godModeToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
godModeToggle.Text = "👑 God Mode (Instant Kill)"
godModeToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
godModeToggle.Font = Enum.Font.GothamBold
godModeToggle.TextSize = 14
godModeToggle.Parent = ToolsTab

local godMode = false
godModeToggle.MouseButton1Click:Connect(function()
    godMode = not godMode
    if godMode then
        godModeToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        godModeToggle.Text = "👑 God Mode: ON"
        notify("oxyX", "God Mode enabled!", 3)
    else
        godModeToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        godModeToggle.Text = "👑 God Mode (Instant Kill)"
        notify("oxyX", "God Mode disabled!", 3)
    end
end)

-- Speed Hack
local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(1, 0, 0, 50)
speedSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
speedSlider.Parent = ToolsTab

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 5)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "🏃 Speed: 16"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedSlider

local speedBar = Instance.new("Frame")
speedBar.Size = UDim2.new(0.8, 0, 0, 8)
speedBar.Position = UDim2.new(0.1, 0, 0, 28)
speedBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
speedBar.Parent = speedSlider

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.16, 0, 1, 0)
speedFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
speedFill.Parent = speedBar

local baseSpeed = 16
speedBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local relativeX = (input.Position.X - speedBar.AbsolutePosition.X) / speedBar.AbsoluteSize.X
        relativeX = math.clamp(relativeX, 0.1, 1)
        speedFill.Size = UDim2.new(relativeX, 0, 1, 0)
        local newSpeed = math.floor(16 * relativeX * 5)
        speedLabel.Text = "🏃 Speed: " .. newSpeed
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = newSpeed
        end
    end
end)

-- Jump Power
local jumpSlider = Instance.new("Frame")
jumpSlider.Size = UDim2.new(1, 0, 0, 50)
jumpSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
jumpSlider.Parent = ToolsTab

local jumpLabel = Instance.new("TextLabel")
jumpLabel.Size = UDim2.new(1, -20, 0, 20)
jumpLabel.Position = UDim2.new(0, 10, 0, 5)
jumpLabel.BackgroundTransparency = 1
jumpLabel.Text = "🦘 Jump Power: 50"
jumpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
jumpLabel.Font = Enum.Font.GothamBold
jumpLabel.TextSize = 12
jumpLabel.TextXAlignment = Enum.TextXAlignment.Left
jumpLabel.Parent = jumpSlider

local jumpBar = Instance.new("Frame")
jumpBar.Size = UDim2.new(0.8, 0, 0, 8)
jumpBar.Position = UDim2.new(0.1, 0, 0, 28)
jumpBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
jumpBar.Parent = jumpSlider

local jumpFill = Instance.new("Frame")
jumpFill.Size = UDim2.new(0.3, 0, 1, 0)
jumpFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
jumpFill.Parent = jumpBar

jumpBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local relativeX = (input.Position.X - jumpBar.AbsolutePosition.X) / jumpBar.AbsoluteSize.X
        relativeX = math.clamp(relativeX, 0.1, 1)
        jumpFill.Size = UDim2.new(relativeX, 0, 1, 0)
        local newJump = math.floor(50 * relativeX * 4)
        jumpLabel.Text = "🦘 Jump Power: " .. newJump
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.JumpPower = newJump
        end
    end
end)

-- No Clip Toggle
local noClipToggle = Instance.new("TextButton")
noClipToggle.Size = UDim2.new(1, 0, 0, 40)
noClipToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
noClipToggle.Text = "🔓 No Clip"
noClipToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
noClipToggle.Font = Enum.Font.GothamBold
noClipToggle.TextSize = 14
noClipToggle.Parent = ToolsTab

local noClip = false
noClipToggle.MouseButton1Click:Connect(function()
    noClip = not noClip
    if noClip then
        noClipToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        noClipToggle.Text = "🔓 No Clip: ON"
    else
        noClipToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        noClipToggle.Text = "🔓 No Clip"
    end
end)

-- Fly Toggle
local flyToggle = Instance.new("TextButton")
flyToggle.Size = UDim2.new(1, 0, 0, 40)
flyToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
flyToggle.Text = "🕊️ Fly (E to toggle)"
flyToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
flyToggle.Font = Enum.Font.GothamBold
flyToggle.TextSize = 14
flyToggle.Parent = ToolsTab

local flying = false
local flySpeed = 2
local flyConn

flyToggle.MouseButton1Click:Connect(function()
    flying = not flying
    if flying then
        flyToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        flyToggle.Text = "🕊️ Fly: ON"
        notify("oxyX", "Fly enabled! Press E to toggle", 3)
        
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(4000, 4000, 4000)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = player.Character.HumanoidRootPart
        
        flyConn = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.E then
                flying = not flying
                if not flying then
                    bv:Destroy()
                    flyConn:Disconnect()
                    flyToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
                    flyToggle.Text = "🕊️ Fly (E to toggle)"
                end
            end
        end)
    end
end)

-- ============================================================
-- IMPORT TAB
-- ============================================================
local importTitle = Instance.new("TextLabel")
importTitle.Size = UDim2.new(1, 0, 0, 30)
importTitle.BackgroundTransparency = 1
importTitle.Text = "Import Tools"
importTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
importTitle.Font = Enum.Font.GothamBold
importTitle.TextSize = 16
importTitle.Parent = ImportTab

-- OBJ Import
local objBtn = Instance.new("TextButton")
objBtn.Size = UDim2.new(1, 0, 0, 45)
objBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
objBtn.Text = "🖼️ Import OBJ Image"
objBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
objBtn.Font = Enum.Font.GothamBold
objBtn.TextSize = 14
objBtn.Parent = ImportTab

objBtn.MouseButton1Click:Connect(function()
    notify("oxyX", "OBJ Import: Coming soon!", 3)
end)

-- Model Import
local modelBtn = Instance.new("TextButton")
modelBtn.Size = UDim2.new(1, 0, 0, 45)
modelBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
modelBtn.Text = "📦 Import Model (Asset ID)"
modelBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
modelBtn.Font = Enum.Font.GothamBold
modelBtn.TextSize = 14
modelBtn.Parent = ImportTab

local modelInput = Instance.new("TextBox")
modelInput.Size = UDim2.new(1, 0, 0, 35)
modelInput.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
modelInput.Text = "Enter Asset ID..."
modelInput.TextColor3 = Color3.fromRGB(120, 120, 130)
modelInput.Font = Enum.Font.Gotham
modelInput.TextSize = 13
modelInput.Parent = ImportTab
modelInput.Focused:Connect(function()
    if modelInput.Text == "Enter Asset ID..." then
        modelInput.Text = ""
        modelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

modelBtn.MouseButton1Click:Connect(function()
    local assetId = tonumber(modelInput.Text)
    if assetId then
        notify("oxyX", "Importing model: " .. assetId, 3)
        -- Model import logic here
    else
        notify("oxyX", "Please enter a valid Asset ID!", 3)
    end
end)

-- Wireframe Mode
local wireframeToggle = Instance.new("TextButton")
wireframeToggle.Size = UDim2.new(1, 0, 0, 40)
wireframeToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
wireframeToggle.Text = "🔲 Wireframe Mode"
wireframeToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
wireframeToggle.Font = Enum.Font.GothamBold
wireframeToggle.TextSize = 14
wireframeToggle.Parent = ImportTab

local wireframeMode = false
wireframeToggle.MouseButton1Click:Connect(function()
    wireframeMode = not wireframeMode
    if wireframeMode then
        wireframeToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        wireframeToggle.Text = "🔲 Wireframe: ON"
        notify("oxyX", "Wireframe mode enabled!", 3)
    else
        wireframeToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        wireframeToggle.Text = "🔲 Wireframe Mode"
        notify("oxyX", "Wireframe mode disabled!", 3)
    end
end)

-- ============================================================
-- BUILDS TAB
-- ============================================================
local buildTitle = Instance.new("TextLabel")
buildTitle.Size = UDim2.new(1, 0, 0, 30)
buildTitle.BackgroundTransparency = 1
buildTitle.Text = "Build Manager"
buildTitle.TextColor3 = Color3.fromRGB(100, 255, 150)
buildTitle.Font = Enum.Font.GothamBold
buildTitle.TextSize = 16
buildTitle.Parent = BuildTab

-- Build Loader Info
local buildInfo = Instance.new("TextLabel")
buildInfo.Size = UDim2.new(1, 0, 0, 60)
buildInfo.BackgroundTransparency = 1
buildInfo.Text = "Load builds from file or URL.\nBuilds use your purchased blocks."
buildInfo.TextColor3 = Color3.fromRGB(150, 150, 160)
buildInfo.Font = Enum.Font.Gotham
buildInfo.TextSize = 12
buildInfo.TextWrapped = true
buildInfo.Parent = BuildTab

-- Load Build Button
local loadBuildBtn = Instance.new("TextButton")
loadBuildBtn.Size = UDim2.new(1, 0, 0, 40)
loadBuildBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
loadBuildBtn.Text = "📂 Load Build File"
loadBuildBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBuildBtn.Font = Enum.Font.GothamBold
loadBuildBtn.TextSize = 14
loadBuildBtn.Parent = BuildTab

loadBuildBtn.MouseButton1Click:Connect(function()
    notify("oxyX", "Build Loader: Coming soon!", 3)
end)

-- Save Build Button
local saveBuildBtn = Instance.new("TextButton")
saveBuildBtn.Size = UDim2.new(1, 0, 0, 40)
saveBuildBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
saveBuildBtn.Text = "💾 Save Current Build"
saveBuildBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBuildBtn.Font = Enum.Font.GothamBold
saveBuildBtn.TextSize = 14
saveBuildBtn.Parent = BuildTab

saveBuildBtn.MouseButton1Click:Connect(function()
    notify("oxyX", "Build Saver: Coming soon!", 3)
end)

-- ============================================================
-- SETTINGS TAB
-- ============================================================
local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, 0, 0, 30)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "Settings"
settingsTitle.TextColor3 = Color3.fromRGB(200, 200, 100)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 16
settingsTitle.Parent = SettingsTab

-- UI Theme
local themeLabel = Instance.new("TextLabel")
themeLabel.Size = UDim2.new(1, 0, 0, 25)
themeLabel.BackgroundTransparency = 1
themeLabel.Text = "🎨 Theme: Dark"
themeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
themeLabel.Font = Enum.Font.GothamBold
themeLabel.TextSize = 13
themeLabel.TextXAlignment = Enum.TextXAlignment.Left
themeLabel.Parent = SettingsTab

-- Keybinds Info
local keybindsLabel = Instance.new("TextLabel")
keybindsLabel.Size = UDim2.new(1, 0, 0, 80)
keybindsLabel.BackgroundTransparency = 1
keybindsLabel.Text = [[
⌨️ Keybinds:
E - Toggle Fly
Left Click - Select/Place Block
Right Click - Delete Block
Scroll - Change Block Size
]]
keybindsLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
keybindsLabel.Font = Enum.Font.Gotham
keybindsLabel.TextSize = 12
keybindsLabel.TextWrapped = true
keybindsLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindsLabel.Parent = SettingsTab

-- Credits
local creditsLabel = Instance.new("TextLabel")
creditsLabel.Size = UDim2.new(1, 0, 0, 50)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Text = "Made with ❤️ by oxyX\nVersion " .. SCRIPT_VERSION
creditsLabel.TextColor3 = Color3.fromRGB(100, 100, 110)
creditsLabel.Font = Enum.Font.Gotham
creditsLabel.TextSize = 11
creditsLabel.TextWrapped = true
creditsLabel.Parent = SettingsTab

-- ============================================================
-- INITIALIZE FIRST TAB
-- ============================================================
if tabs["Home"] then
    tabs["Home"].content.Visible = true
    tabs["Home"].button.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    currentTab = "Home"
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
task.spawn(function()
    while wait(0.5) do
        -- Update God Mode
        if godMode and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then
                for _, v in pairs(Workspace:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v ~= player.Character then
                        v.Humanoid.Health = 0
                    end
                end
            end
        end
        
        -- Update No Clip
        if noClip and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        
        -- Update Fly
        if flying and player.Character and player.Character:FindFirstChild("HumanoidRootPart") do
            local rootPart = player.Character.HumanoidRootPart
            local flyVel = rootPart:FindFirstChild("FlyVelocity")
            if flyVel then
                local camera = Workspace.CurrentCamera
                local direction = Vector3.new(
                    (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                    (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
                    (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
                )
                local finalDir = camera.CFrame:VectorToWorldSpace(direction)
                flyVel.Velocity = finalDir * 50
            end
        end
        
        -- Update Wireframe
        if wireframeMode then
            for _, v in pairs(Workspace:GetChildren()) do
                pcall(function()
                    if v:IsA("BasePart") then
                        v.Material = Enum.Material.ForceField
                    end
                end)
            end
        end
    end
end)

-- ============================================================
-- DRAG FUNCTIONALITY
-- ============================================================
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == UserInputService:GetMouseLocation() then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================
-- SHOW GUI
-- ============================================================
task.delay(0.1, function()
    pcall(function()
        if ScreenGui then
            ScreenGui.Enabled = true
            print("[oxyX] GUI Enabled")
        end
        if MainFrame then
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 620, 0, 680)
            MainFrame.Position = UDim2.new(0.5, -310, 0.5, -340)
            print("[oxyX] MainFrame visible")
        end
    end)
end)

-- Show notification
notify("oxyX BABFT v" .. SCRIPT_VERSION, "Loaded! " .. SCRIPT_TAG .. " | " .. rawExecutor, 5)

print("[oxyX] Script loaded successfully!")
