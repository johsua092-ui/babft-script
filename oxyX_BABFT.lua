-- ██████╗ ██╗  ██╗██╗   ██╗██╗  ██╗
-- ██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝╚██╗██╔╝
-- ██║   ██║ ╚███╔╝  ╚████╔╝  ╚███╔╝ 
-- ██║   ██║ ██╔██╗   ╚██╔╝   ██╔██╗ 
-- ╚██████╔╝██╔╝ ██╗   ██║   ██╔╝ ██╗
--  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
-- oxyX BABFT Suite | Powered by oxyX Market
-- Compatible: Xeno / Velocity / Fluxus

-- ============================================================
-- EXECUTOR DETECTION
-- ============================================================
local executor = "unknown"
if identifyexecutor then
    executor = identifyexecutor()
elseif XENO_LOADED then
    executor = "xeno"
elseif FLUXUS_LOADED then
    executor = "fluxus"
end

local allowedExecutors = {"xeno", "velocity", "fluxus", "unknown"}
local allowed = false
for _, v in ipairs(allowedExecutors) do
    if string.lower(executor):find(v) then
        allowed = true
        break
    end
end

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function tween(obj, props, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, direction)
    TweenService:Create(obj, info, props):Play()
end

local function notify(title, msg, duration)
    duration = duration or 3
    if syn and syn.protect_gui then
        -- handled below
    end
    -- Simple notification via GUI
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "oxyX_Notif"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() notifGui.Parent = CoreGui end)
    if not notifGui.Parent then notifGui.Parent = player.PlayerGui end

    local frame = Instance.new("Frame", notifGui)
    frame.Size = UDim2.new(0, 300, 0, 70)
    frame.Position = UDim2.new(1, -320, 1, -90)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.1

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(120, 60, 255)
    stroke.Thickness = 1.5

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -10, 0, 25)
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "⚡ " .. title
    titleLbl.TextColor3 = Color3.fromRGB(160, 100, 255)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local msgLbl = Instance.new("TextLabel", frame)
    msgLbl.Size = UDim2.new(1, -10, 0, 30)
    msgLbl.Position = UDim2.new(0, 10, 0, 28)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = msg
    msgLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 11
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextWrapped = true

    frame.Position = UDim2.new(1, 10, 1, -90)
    tween(frame, {Position = UDim2.new(1, -320, 1, -90)}, 0.4)

    task.delay(duration, function()
        tween(frame, {Position = UDim2.new(1, 10, 1, -90)}, 0.4)
        task.delay(0.5, function()
            notifGui:Destroy()
        end)
    end)
end

-- ============================================================
-- MAIN GUI CREATION
-- ============================================================
local existingGui = CoreGui:FindFirstChild("oxyX_BABFT")
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "oxyX_BABFT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = player.PlayerGui end

-- ============================================================
-- MAIN FRAME
-- ============================================================
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 480)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local mainCorner = Instance.new("UICorner", MainFrame)
mainCorner.CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Color3.fromRGB(100, 50, 220)
mainStroke.Thickness = 1.5

-- Gradient background
local gradient = Instance.new("UIGradient", MainFrame)
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 22)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 8, 35))
})
gradient.Rotation = 135

-- ============================================================
-- TITLE BAR
-- ============================================================
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(14, 8, 30)
TitleBar.BorderSizePixel = 0

local titleBarCorner = Instance.new("UICorner", TitleBar)
titleBarCorner.CornerRadius = UDim.new(0, 14)

local titleBarGrad = Instance.new("UIGradient", TitleBar)
titleBarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 30, 180)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 8, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 8, 30))
})
titleBarGrad.Rotation = 90

-- Logo / Title
local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ oxyX BABFT Suite"
TitleLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local SubLabel = Instance.new("TextLabel", TitleBar)
SubLabel.Size = UDim2.new(1, -100, 0, 14)
SubLabel.Position = UDim2.new(0, 14, 1, -16)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "Powered by oxyX Market"
SubLabel.TextColor3 = Color3.fromRGB(120, 80, 180)
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 10
SubLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button (-)
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -66, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.BorderSizePixel = 0
MinBtn.AutoButtonColor = false

local minCorner = Instance.new("UICorner", MinBtn)
minCorner.CornerRadius = UDim.new(0, 6)

-- Close Button (X)
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false

local closeCorner = Instance.new("UICorner", CloseBtn)
closeCorner.CornerRadius = UDim.new(0, 6)

-- ============================================================
-- DRAGGABLE TITLE BAR
-- ============================================================
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
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
-- MINIMIZE / CLOSE LOGIC
-- ============================================================
local minimized = false
local ContentFrame -- defined below

CloseBtn.MouseButton1Click:Connect(function()
    tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
    task.delay(0.35, function()
        ScreenGui:Destroy()
    end)
end)

CloseBtn.MouseEnter:Connect(function()
    tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220, 50, 80)}, 0.15)
end)
CloseBtn.MouseLeave:Connect(function()
    tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(180, 30, 60)}, 0.15)
end)

MinBtn.MouseEnter:Connect(function()
    tween(MinBtn, {BackgroundColor3 = Color3.fromRGB(70, 60, 100)}, 0.15)
end)
MinBtn.MouseLeave:Connect(function()
    tween(MinBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 60)}, 0.15)
end)

-- ============================================================
-- TAB BAR
-- ============================================================
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -20, 0, 36)
TabBar.Position = UDim2.new(0, 10, 0, 54)
TabBar.BackgroundTransparency = 1

local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 6)

local tabNames = {"🔨 AutoBuild", "📦 OBJ Loader", "🖼️ Image Loader", "ℹ️ Info"}
local tabButtons = {}
local tabPages = {}
local activeTab = 1

-- ============================================================
-- CONTENT AREA
-- ============================================================
ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -20, 1, -106)
ContentFrame.Position = UDim2.new(0, 10, 0, 96)
ContentFrame.BackgroundTransparency = 1

-- Minimize logic (needs ContentFrame)
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tween(MainFrame, {Size = UDim2.new(0, 520, 0, 52)}, 0.3)
        ContentFrame.Visible = false
        TabBar.Visible = false
    else
        ContentFrame.Visible = true
        TabBar.Visible = true
        tween(MainFrame, {Size = UDim2.new(0, 520, 0, 480)}, 0.3)
    end
end)

-- ============================================================
-- HELPER: CREATE PAGE
-- ============================================================
local function createPage()
    local page = Instance.new("Frame", ContentFrame)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    return page
end

-- ============================================================
-- HELPER: STYLED INPUT
-- ============================================================
local function createInput(parent, placeholder, posY, height)
    height = height or 34
    local bg = Instance.new("Frame", parent)
    bg.Size = UDim2.new(1, 0, 0, height)
    bg.Position = UDim2.new(0, 0, 0, posY)
    bg.BackgroundColor3 = Color3.fromRGB(20, 15, 38)
    bg.BorderSizePixel = 0

    local bgCorner = Instance.new("UICorner", bg)
    bgCorner.CornerRadius = UDim.new(0, 8)

    local bgStroke = Instance.new("UIStroke", bg)
    bgStroke.Color = Color3.fromRGB(70, 40, 130)
    bgStroke.Thickness = 1

    local box = Instance.new("TextBox", bg)
    box.Size = UDim2.new(1, -12, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(100, 80, 140)
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(220, 200, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false

    box.Focused:Connect(function()
        tween(bgStroke, {Color = Color3.fromRGB(140, 80, 255)}, 0.2)
    end)
    box.FocusLost:Connect(function()
        tween(bgStroke, {Color = Color3.fromRGB(70, 40, 130)}, 0.2)
    end)

    return box, bg
end

-- ============================================================
-- HELPER: STYLED BUTTON
-- ============================================================
local function createButton(parent, text, posY, color)
    color = color or Color3.fromRGB(100, 50, 220)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 9)

    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(
            math.min(color.R * 255 + 30, 255),
            math.min(color.G * 255 + 10, 255),
            math.min(color.B * 255 + 40, 255)
        )),
        ColorSequenceKeypoint.new(1, color)
    })
    btnGrad.Rotation = 90

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(
            math.min(color.R * 255 + 20, 255),
            math.min(color.G * 255 + 5, 255),
            math.min(color.B * 255 + 30, 255)
        )}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = color}, 0.15)
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, {Size = UDim2.new(0.98, 0, 0, 36)}, 0.08)
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, {Size = UDim2.new(1, 0, 0, 38)}, 0.1)
    end)

    return btn
end

-- ============================================================
-- HELPER: LABEL
-- ============================================================
local function createLabel(parent, text, posY, size, color)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, 0, 0, size or 18)
    lbl.Position = UDim2.new(0, 0, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(180, 150, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    return lbl
end

-- ============================================================
-- HELPER: STATUS BOX
-- ============================================================
local function createStatusBox(parent, posY)
    local bg = Instance.new("Frame", parent)
    bg.Size = UDim2.new(1, 0, 0, 60)
    bg.Position = UDim2.new(0, 0, 0, posY)
    bg.BackgroundColor3 = Color3.fromRGB(12, 8, 25)
    bg.BorderSizePixel = 0

    local bgCorner = Instance.new("UICorner", bg)
    bgCorner.CornerRadius = UDim.new(0, 8)

    local bgStroke = Instance.new("UIStroke", bg)
    bgStroke.Color = Color3.fromRGB(50, 30, 90)
    bgStroke.Thickness = 1

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(1, -10, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Status: Ready"
    lbl.TextColor3 = Color3.fromRGB(120, 200, 120)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true

    return lbl, bg
end

-- ============================================================
-- TAB CREATION
-- ============================================================
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 15, 38)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(140, 110, 190)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = i

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)

    tabButtons[i] = btn
    tabPages[i] = createPage()
end

local function switchTab(idx)
    activeTab = idx
    for i, btn in ipairs(tabButtons) do
        if i == idx then
            tween(btn, {BackgroundColor3 = Color3.fromRGB(90, 40, 200), TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
        else
            tween(btn, {BackgroundColor3 = Color3.fromRGB(20, 15, 38), TextColor3 = Color3.fromRGB(140, 110, 190)}, 0.2)
        end
        tabPages[i].Visible = (i == idx)
    end
end

for i, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        switchTab(i)
    end)
end

-- ============================================================
-- PAGE 1: AUTOBUILD
-- ============================================================
local p1 = tabPages[1]

createLabel(p1, "📂 Paste your .build script data below:", 0, 18, Color3.fromRGB(160, 120, 220))

local buildInput, buildInputBg = createInput(p1, "Paste .build data here (JSON format)...", 22, 80)
buildInput.MultiLine = true
buildInput.TextYAlignment = Enum.TextYAlignment.Top
buildInputBg.Size = UDim2.new(1, 0, 0, 80)

createLabel(p1, "⚙️ Build Speed (studs/sec):", 110, 16, Color3.fromRGB(160, 120, 220))
local speedInput, _ = createInput(p1, "e.g. 5", 130, 34)
speedInput.Text = "5"

createLabel(p1, "📍 Build Position Offset (X, Y, Z):", 172, 16, Color3.fromRGB(160, 120, 220))
local posInput, _ = createInput(p1, "e.g. 0, 5, 0", 192, 34)
posInput.Text = "0, 5, 0"

local buildBtn = createButton(p1, "🔨 START AUTOBUILD", 234, Color3.fromRGB(80, 40, 180))
local stopBuildBtn = createButton(p1, "⏹ STOP BUILD", 280, Color3.fromRGB(160, 40, 80))

local buildStatus, _ = createStatusBox(p1, 326)

-- ============================================================
-- AUTOBUILD LOGIC
-- ============================================================
local buildRunning = false
local buildThread = nil

local function parseBuildData(raw)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if ok and type(data) == "table" then
        return data
    end
    -- Try simple line-by-line format
    local parts = {}
    for line in raw:gmatch("[^\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(parts, trimmed)
        end
    end
    return parts
end

local function getBABFTBuildTool()
    local char = player.Character
    if not char then return nil end
    -- Try to find build tool in backpack or character
    local backpack = player.Backpack
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("build") or tool.Name:lower():find("block")) then
            return tool
        end
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("build") or tool.Name:lower():find("block")) then
            return tool
        end
    end
    return nil
end

buildBtn.MouseButton1Click:Connect(function()
    if buildRunning then
        notify("oxyX AutoBuild", "Build already running! Stop it first.", 3)
        return
    end

    local raw = buildInput.Text
    if raw == "" or raw == nil then
        buildStatus.Text = "Status: ❌ No .build data provided!"
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX AutoBuild", "Please paste .build data first!", 3)
        return
    end

    local speed = tonumber(speedInput.Text) or 5
    local px, py, pz = posInput.Text:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
    local offset = Vector3.new(tonumber(px) or 0, tonumber(py) or 5, tonumber(pz) or 0)

    local buildData = parseBuildData(raw)
    if not buildData or #buildData == 0 then
        buildStatus.Text = "Status: ❌ Invalid .build data format!"
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX AutoBuild", "Invalid .build data! Use JSON format.", 3)
        return
    end

    buildRunning = true
    buildStatus.Text = "Status: 🔨 Building... (0/" .. #buildData .. ")"
    buildStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    notify("oxyX AutoBuild", "Starting build of " .. #buildData .. " parts...", 3)

    buildThread = task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then
            buildStatus.Text = "Status: ❌ Character not found!"
            buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            buildRunning = false
            return
        end

        local basePos = hrp.Position + offset

        for i, partData in ipairs(buildData) do
            if not buildRunning then break end

            -- Handle both table and string formats
            local partInfo = type(partData) == "table" and partData or {}
            local partName = partInfo.name or partInfo.Name or "Part"
            local partSize = partInfo.size or partInfo.Size or {x=4, y=1.2, z=4}
            local partPos = partInfo.position or partInfo.Position or {x=0, y=0, z=0}
            local partColor = partInfo.color or partInfo.Color or {r=163, g=162, b=165}
            local partMat = partInfo.material or partInfo.Material or "SmoothPlastic"
            local partShape = partInfo.shape or partInfo.Shape or "Block"

            -- Attempt to place via BABFT remote
            local success = pcall(function()
                -- Try to find BABFT placement remote
                local workspace = game.Workspace
                local remotes = game:GetService("ReplicatedStorage")

                -- Common BABFT remote names
                local placeRemote = remotes:FindFirstChild("PlacePart")
                    or remotes:FindFirstChild("BuildPart")
                    or remotes:FindFirstChild("Place")

                if placeRemote and placeRemote:IsA("RemoteEvent") then
                    local pos = Vector3.new(
                        basePos.X + (type(partPos) == "table" and (partPos.x or partPos.X or 0) or 0),
                        basePos.Y + (type(partPos) == "table" and (partPos.y or partPos.Y or 0) or 0),
                        basePos.Z + (type(partPos) == "table" and (partPos.z or partPos.Z or 0) or 0)
                    )
                    local size = Vector3.new(
                        type(partSize) == "table" and (partSize.x or partSize.X or 4) or 4,
                        type(partSize) == "table" and (partSize.y or partSize.Y or 1.2) or 1.2,
                        type(partSize) == "table" and (partSize.z or partSize.Z or 4) or 4
                    )
                    local color = Color3.fromRGB(
                        type(partColor) == "table" and (partColor.r or partColor.R or 163) or 163,
                        type(partColor) == "table" and (partColor.g or partColor.G or 162) or 162,
                        type(partColor) == "table" and (partColor.b or partColor.B or 165) or 165
                    )
                    placeRemote:FireServer(pos, size, color, partMat, partShape)
                end
            end)

            buildStatus.Text = "Status: 🔨 Building... (" .. i .. "/" .. #buildData .. ")"

            local delay = 1 / math.max(speed, 0.1)
            task.wait(delay)
        end

        if buildRunning then
            buildRunning = false
            buildStatus.Text = "Status: ✅ Build Complete! (" .. #buildData .. " parts)"
            buildStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX AutoBuild", "Build complete! " .. #buildData .. " parts placed.", 4)
        end
    end)
end)

stopBuildBtn.MouseButton1Click:Connect(function()
    if buildRunning then
        buildRunning = false
        if buildThread then
            task.cancel(buildThread)
            buildThread = nil
        end
        buildStatus.Text = "Status: ⏹ Build stopped by user."
        buildStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
        notify("oxyX AutoBuild", "Build stopped.", 2)
    else
        notify("oxyX AutoBuild", "No build is running.", 2)
    end
end)

-- ============================================================
-- PAGE 2: OBJ LOADER
-- ============================================================
local p2 = tabPages[2]

createLabel(p2, "📦 Paste .obj file content below:", 0, 18, Color3.fromRGB(160, 120, 220))

local objInput, objInputBg = createInput(p2, "Paste .obj content here (v, f lines)...", 22, 80)
objInput.MultiLine = true
objInput.TextYAlignment = Enum.TextYAlignment.Top
objInputBg.Size = UDim2.new(1, 0, 0, 80)

createLabel(p2, "📐 Scale Factor:", 110, 16, Color3.fromRGB(160, 120, 220))
local scaleInput, _ = createInput(p2, "e.g. 1.0", 130, 34)
scaleInput.Text = "1.0"

local convertBtn = createButton(p2, "🔄 CONVERT OBJ → .BUILD", 172, Color3.fromRGB(40, 120, 200))
local importRobloxBtn = createButton(p2, "🎮 IMPORT TO ROBLOX STUDIO FORMAT", 218, Color3.fromRGB(20, 140, 80))
local buildFromObjBtn = createButton(p2, "🔨 BUILD IN BABFT FROM OBJ", 264, Color3.fromRGB(80, 40, 180))

local objStatus, _ = createStatusBox(p2, 310)

-- ============================================================
-- OBJ PARSER
-- ============================================================
local function parseOBJ(content)
    local vertices = {}
    local faces = {}
    local normals = {}
    local uvs = {}

    for line in content:gmatch("[^\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed:sub(1, 2) == "v " then
            local x, y, z = trimmed:match("v%s+([%-%.%d]+)%s+([%-%.%d]+)%s+([%-%.%d]+)")
            if x then
                table.insert(vertices, {x = tonumber(x), y = tonumber(y), z = tonumber(z)})
            end
        elseif trimmed:sub(1, 3) == "vn " then
            local x, y, z = trimmed:match("vn%s+([%-%.%d]+)%s+([%-%.%d]+)%s+([%-%.%d]+)")
            if x then
                table.insert(normals, {x = tonumber(x), y = tonumber(y), z = tonumber(z)})
            end
        elseif trimmed:sub(1, 3) == "vt " then
            local u, v = trimmed:match("vt%s+([%-%.%d]+)%s+([%-%.%d]+)")
            if u then
                table.insert(uvs, {u = tonumber(u), v = tonumber(v)})
            end
        elseif trimmed:sub(1, 2) == "f " then
            local faceVerts = {}
            for vert in trimmed:sub(3):gmatch("%S+") do
                local vi = vert:match("^(%d+)")
                if vi then
                    table.insert(faceVerts, tonumber(vi))
                end
            end
            if #faceVerts >= 3 then
                table.insert(faces, faceVerts)
            end
        end
    end

    return vertices, faces, normals, uvs
end

local function objToBuildFormat(vertices, faces, scale)
    scale = scale or 1.0
    local parts = {}

    -- Convert each face to a part (simplified: use face centroid + bounding box)
    for i, face in ipairs(faces) do
        if #face >= 3 then
            local minX, minY, minZ = math.huge, math.huge, math.huge
            local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

            for _, vi in ipairs(face) do
                local v = vertices[vi]
                if v then
                    minX = math.min(minX, v.x * scale)
                    minY = math.min(minY, v.y * scale)
                    minZ = math.min(minZ, v.z * scale)
                    maxX = math.max(maxX, v.x * scale)
                    maxY = math.max(maxY, v.y * scale)
                    maxZ = math.max(maxZ, v.z * scale)
                end
            end

            local cx = (minX + maxX) / 2
            local cy = (minY + maxY) / 2
            local cz = (minZ + maxZ) / 2
            local sx = math.max(math.abs(maxX - minX), 0.1)
            local sy = math.max(math.abs(maxY - minY), 0.1)
            local sz = math.max(math.abs(maxZ - minZ), 0.1)

            table.insert(parts, {
                name = "OBJ_Part_" .. i,
                position = {x = cx, y = cy, z = cz},
                size = {x = sx, y = sy, z = sz},
                color = {r = 163, g = 162, b = 165},
                material = "SmoothPlastic",
                shape = "Block"
            })
        end
    end

    return parts
end

local function objToRobloxStudioScript(vertices, faces, scale, objName)
    scale = scale or 1.0
    objName = objName or "OBJ_Import"
    local lines = {}
    table.insert(lines, "-- oxyX OBJ Import Script for Roblox Studio")
    table.insert(lines, "-- Generated by oxyX BABFT Suite | Powered by oxyX Market")
    table.insert(lines, "-- Paste this into Roblox Studio Command Bar or a Script")
    table.insert(lines, "")
    table.insert(lines, 'local model = Instance.new("Model")')
    table.insert(lines, 'model.Name = "' .. objName .. '"')
    table.insert(lines, 'model.Parent = workspace')
    table.insert(lines, "")

    for i, face in ipairs(faces) do
        if #face >= 3 then
            local minX, minY, minZ = math.huge, math.huge, math.huge
            local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

            for _, vi in ipairs(face) do
                local v = vertices[vi]
                if v then
                    minX = math.min(minX, v.x * scale)
                    minY = math.min(minY, v.y * scale)
                    minZ = math.min(minZ, v.z * scale)
                    maxX = math.max(maxX, v.x * scale)
                    maxY = math.max(maxY, v.y * scale)
                    maxZ = math.max(maxZ, v.z * scale)
                end
            end

            local cx = (minX + maxX) / 2
            local cy = (minY + maxY) / 2
            local cz = (minZ + maxZ) / 2
            local sx = math.max(math.abs(maxX - minX), 0.1)
            local sy = math.max(math.abs(maxY - minY), 0.1)
            local sz = math.max(math.abs(maxZ - minZ), 0.1)

            table.insert(lines, "do")
            table.insert(lines, '  local p = Instance.new("Part")')
            table.insert(lines, '  p.Name = "Face_' .. i .. '"')
            table.insert(lines, "  p.Size = Vector3.new(" .. string.format("%.3f", sx) .. ", " .. string.format("%.3f", sy) .. ", " .. string.format("%.3f", sz) .. ")")
            table.insert(lines, "  p.CFrame = CFrame.new(" .. string.format("%.3f", cx) .. ", " .. string.format("%.3f", cy) .. ", " .. string.format("%.3f", cz) .. ")")
            table.insert(lines, "  p.Anchored = true")
            table.insert(lines, "  p.Material = Enum.Material.SmoothPlastic")
            table.insert(lines, "  p.BrickColor = BrickColor.new('Medium stone grey')")
            table.insert(lines, "  p.Parent = model")
            table.insert(lines, "end")
        end
    end

    table.insert(lines, "")
    table.insert(lines, 'print("oxyX: Imported ' .. #faces .. ' faces from OBJ")')

    return table.concat(lines, "\n")
end

local lastConvertedBuild = nil
local lastRobloxScript = nil

convertBtn.MouseButton1Click:Connect(function()
    local raw = objInput.Text
    if raw == "" then
        objStatus.Text = "Status: ❌ No OBJ data provided!"
        objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ", "Please paste .obj content first!", 3)
        return
    end

    local scale = tonumber(scaleInput.Text) or 1.0
    objStatus.Text = "Status: 🔄 Parsing OBJ..."
    objStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    task.spawn(function()
        local ok, err = pcall(function()
            local verts, faces, normals, uvs = parseOBJ(raw)
            if #verts == 0 then
                objStatus.Text = "Status: ❌ No vertices found in OBJ!"
                objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                notify("oxyX OBJ", "No vertices found! Check your OBJ format.", 3)
                return
            end

            local buildParts = objToBuildFormat(verts, faces, scale)
            lastConvertedBuild = HttpService:JSONEncode(buildParts)
            lastRobloxScript = objToRobloxStudioScript(verts, faces, scale, "OBJ_Import")

            objStatus.Text = "Status: ✅ Converted! " .. #verts .. " verts, " .. #faces .. " faces → " .. #buildParts .. " parts\n.build data ready in clipboard!"
            objStatus.TextColor3 = Color3.fromRGB(120, 255, 120)

            -- Copy to clipboard if available
            pcall(function()
                setclipboard(lastConvertedBuild)
            end)

            notify("oxyX OBJ", "Converted! " .. #buildParts .. " parts. .build data copied to clipboard!", 4)
        end)
        if not ok then
            objStatus.Text = "Status: ❌ Parse error: " .. tostring(err)
            objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

importRobloxBtn.MouseButton1Click:Connect(function()
    local raw = objInput.Text
    if raw == "" then
        objStatus.Text = "Status: ❌ No OBJ data provided!"
        objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ", "Please paste .obj content first!", 3)
        return
    end

    local scale = tonumber(scaleInput.Text) or 1.0
    objStatus.Text = "Status: 🎮 Generating Roblox Studio script..."
    objStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    task.spawn(function()
        local ok, err = pcall(function()
            local verts, faces, normals, uvs = parseOBJ(raw)
            if #verts == 0 then
                objStatus.Text = "Status: ❌ No vertices found!"
                objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                return
            end

            local script = objToRobloxStudioScript(verts, faces, scale, "OBJ_Import")
            lastRobloxScript = script

            pcall(function()
                setclipboard(script)
            end)

            objStatus.Text = "Status: ✅ Roblox Studio script generated!\nCopied to clipboard. Paste in Studio Command Bar."
            objStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ", "Roblox Studio script copied! Paste in Studio Command Bar.", 5)
        end)
        if not ok then
            objStatus.Text = "Status: ❌ Error: " .. tostring(err)
            objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

buildFromObjBtn.MouseButton1Click:Connect(function()
    local raw = objInput.Text
    if raw == "" then
        objStatus.Text = "Status: ❌ No OBJ data provided!"
        objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ", "Please paste .obj content first!", 3)
        return
    end

    local scale = tonumber(scaleInput.Text) or 1.0
    objStatus.Text = "Status: 🔄 Converting OBJ → .build..."
    objStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    task.spawn(function()
        local ok, err = pcall(function()
            local verts, faces, normals, uvs = parseOBJ(raw)
            if #verts == 0 then
                objStatus.Text = "Status: ❌ No vertices found!"
                objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                return
            end

            local buildParts = objToBuildFormat(verts, faces, scale)
            local buildJson = HttpService:JSONEncode(buildParts)

            -- Auto-paste into AutoBuild tab
            buildInput.Text = buildJson
            objStatus.Text = "Status: ✅ OBJ converted and loaded into AutoBuild tab!\n" .. #buildParts .. " parts ready."
            objStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ", "OBJ loaded into AutoBuild! Switch to AutoBuild tab and press Start.", 4)
            switchTab(1)
        end)
        if not ok then
            objStatus.Text = "Status: ❌ Error: " .. tostring(err)
            objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

-- ============================================================
-- PAGE 3: IMAGE LOADER
-- ============================================================
local p3 = tabPages[3]

createLabel(p3, "🖼️ Discord Image URL:", 0, 18, Color3.fromRGB(160, 120, 220))
createLabel(p3, "Only Discord CDN links supported (cdn.discordapp.com / media.discordapp.net)", 18, 16, Color3.fromRGB(120, 100, 160))

local imgInput, _ = createInput(p3, "https://cdn.discordapp.com/attachments/...", 38, 34)

createLabel(p3, "📐 Display Size (Width x Height in studs):", 80, 16, Color3.fromRGB(160, 120, 220))
local imgSizeInput, _ = createInput(p3, "e.g. 10, 10", 100, 34)
imgSizeInput.Text = "10, 10"

createLabel(p3, "📍 Position Offset (X, Y, Z):", 142, 16, Color3.fromRGB(160, 120, 220))
local imgPosInput, _ = createInput(p3, "e.g. 0, 5, 0", 162, 34)
imgPosInput.Text = "0, 5, 0"

local loadImgBtn = createButton(p3, "🖼️ LOAD IMAGE IN GAME", 204, Color3.fromRGB(40, 100, 180))
local previewImgBtn = createButton(p3, "👁️ PREVIEW IMAGE (GUI)", 250, Color3.fromRGB(80, 60, 160))
local removeImgBtn = createButton(p3, "🗑️ REMOVE LOADED IMAGE", 296, Color3.fromRGB(140, 40, 60))

local imgStatus, _ = createStatusBox(p3, 342)

-- ============================================================
-- IMAGE LOADER LOGIC
-- ============================================================
local loadedImagePart = nil
local previewGui = nil

local function isDiscordUrl(url)
    return url:find("cdn%.discordapp%.com") or url:find("media%.discordapp%.net")
end

local function discordUrlToRoblox(url)
    -- Discord CDN images can be used as decals in Roblox
    -- We need to use the URL directly as a decal texture
    return url
end

loadImgBtn.MouseButton1Click:Connect(function()
    local url = imgInput.Text:match("^%s*(.-)%s*$")
    if url == "" then
        imgStatus.Text = "Status: ❌ No URL provided!"
        imgStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX Image", "Please enter a Discord image URL!", 3)
        return
    end

    if not isDiscordUrl(url) then
        imgStatus.Text = "Status: ❌ Only Discord CDN links are supported!\n(cdn.discordapp.com or media.discordapp.net)"
        imgStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX Image", "Only Discord CDN links supported!", 3)
        return
    end

    local w, h = imgSizeInput.Text:match("([%-%.%d]+),%s*([%-%.%d]+)")
    local width = tonumber(w) or 10
    local height = tonumber(h) or 10

    local px, py, pz = imgPosInput.Text:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
    local offset = Vector3.new(tonumber(px) or 0, tonumber(py) or 5, tonumber(pz) or 0)

    imgStatus.Text = "Status: 🔄 Loading image..."
    imgStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    task.spawn(function()
        local ok, err = pcall(function()
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if not hrp then error("Character not found") end

            -- Remove previous image part
            if loadedImagePart and loadedImagePart.Parent then
                loadedImagePart:Destroy()
            end

            -- Create a part with a decal
            local part = Instance.new("Part")
            part.Name = "oxyX_ImagePart"
            part.Size = Vector3.new(width, height, 0.1)
            part.CFrame = CFrame.new(hrp.Position + offset) * CFrame.Angles(0, 0, 0)
            part.Anchored = true
            part.CanCollide = false
            part.Material = Enum.Material.SmoothPlastic
            part.BrickColor = BrickColor.new("White")
            part.CastShadow = false

            local decal = Instance.new("Decal", part)
            decal.Face = Enum.NormalId.Front
            decal.Texture = url

            local decalBack = Instance.new("Decal", part)
            decalBack.Face = Enum.NormalId.Back
            decalBack.Texture = url

            part.Parent = workspace
            loadedImagePart = part

            imgStatus.Text = "Status: ✅ Image loaded in world!\nURL: " .. url:sub(1, 50) .. "..."
            imgStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX Image", "Image loaded in game world!", 3)
        end)
        if not ok then
            imgStatus.Text = "Status: ❌ Error: " .. tostring(err)
            imgStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            notify("oxyX Image", "Failed to load image: " .. tostring(err), 4)
        end
    end)
end)

previewImgBtn.MouseButton1Click:Connect(function()
    local url = imgInput.Text:match("^%s*(.-)%s*$")
    if url == "" then
        imgStatus.Text = "Status: ❌ No URL provided!"
        imgStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX Image", "Please enter a Discord image URL!", 3)
        return
    end

    if not isDiscordUrl(url) then
        imgStatus.Text = "Status: ❌ Only Discord CDN links are supported!"
        imgStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX Image", "Only Discord CDN links supported!", 3)
        return
    end

    -- Remove old preview
    if previewGui and previewGui.Parent then
        previewGui:Destroy()
    end

    local pGui = Instance.new("ScreenGui")
    pGui.Name = "oxyX_ImagePreview"
    pGui.ResetOnSpawn = false
    pGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() pGui.Parent = CoreGui end)
    if not pGui.Parent then pGui.Parent = player.PlayerGui end
    previewGui = pGui

    local bg = Instance.new("Frame", pGui)
    bg.Size = UDim2.new(0, 420, 0, 380)
    bg.Position = UDim2.new(0.5, -210, 0.5, -190)
    bg.BackgroundColor3 = Color3.fromRGB(10, 8, 20)
    bg.BorderSizePixel = 0

    local bgCorner = Instance.new("UICorner", bg)
    bgCorner.CornerRadius = UDim.new(0, 12)

    local bgStroke = Instance.new("UIStroke", bg)
    bgStroke.Color = Color3.fromRGB(100, 50, 220)
    bgStroke.Thickness = 1.5

    local titleBar2 = Instance.new("Frame", bg)
    titleBar2.Size = UDim2.new(1, 0, 0, 36)
    titleBar2.BackgroundColor3 = Color3.fromRGB(14, 8, 30)
    titleBar2.BorderSizePixel = 0

    local tb2Corner = Instance.new("UICorner", titleBar2)
    tb2Corner.CornerRadius = UDim.new(0, 12)

    local tb2Title = Instance.new("TextLabel", titleBar2)
    tb2Title.Size = UDim2.new(1, -50, 1, 0)
    tb2Title.Position = UDim2.new(0, 12, 0, 0)
    tb2Title.BackgroundTransparency = 1
    tb2Title.Text = "🖼️ Image Preview — oxyX"
    tb2Title.TextColor3 = Color3.fromRGB(200, 150, 255)
    tb2Title.Font = Enum.Font.GothamBold
    tb2Title.TextSize = 13
    tb2Title.TextXAlignment = Enum.TextXAlignment.Left

    local closePreview = Instance.new("TextButton", titleBar2)
    closePreview.Size = UDim2.new(0, 26, 0, 26)
    closePreview.Position = UDim2.new(1, -32, 0.5, -13)
    closePreview.BackgroundColor3 = Color3.fromRGB(180, 30, 60)
    closePreview.Text = "✕"
    closePreview.TextColor3 = Color3.fromRGB(255, 255, 255)
    closePreview.Font = Enum.Font.GothamBold
    closePreview.TextSize = 12
    closePreview.BorderSizePixel = 0

    local cpCorner = Instance.new("UICorner", closePreview)
    cpCorner.CornerRadius = UDim.new(0, 6)

    closePreview.MouseButton1Click:Connect(function()
        pGui:Destroy()
    end)

    local imgLabel = Instance.new("ImageLabel", bg)
    imgLabel.Size = UDim2.new(1, -20, 1, -56)
    imgLabel.Position = UDim2.new(0, 10, 0, 46)
    imgLabel.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    imgLabel.Image = url
    imgLabel.ScaleType = Enum.ScaleType.Fit
    imgLabel.BorderSizePixel = 0

    local imgCorner = Instance.new("UICorner", imgLabel)
    imgCorner.CornerRadius = UDim.new(0, 8)

    local urlLbl = Instance.new("TextLabel", bg)
    urlLbl.Size = UDim2.new(1, -20, 0, 16)
    urlLbl.Position = UDim2.new(0, 10, 1, -20)
    urlLbl.BackgroundTransparency = 1
    urlLbl.Text = url:sub(1, 60) .. (url:len() > 60 and "..." or "")
    urlLbl.TextColor3 = Color3.fromRGB(100, 80, 140)
    urlLbl.Font = Enum.Font.Gotham
    urlLbl.TextSize = 10
    urlLbl.TextXAlignment = Enum.TextXAlignment.Left

    imgStatus.Text = "Status: 👁️ Preview opened!"
    imgStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    notify("oxyX Image", "Preview window opened!", 2)
end)

removeImgBtn.MouseButton1Click:Connect(function()
    if loadedImagePart and loadedImagePart.Parent then
        loadedImagePart:Destroy()
        loadedImagePart = nil
        imgStatus.Text = "Status: 🗑️ Image removed from world."
        imgStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
        notify("oxyX Image", "Image removed from game world.", 2)
    else
        imgStatus.Text = "Status: ℹ️ No image currently loaded."
        imgStatus.TextColor3 = Color3.fromRGB(180, 150, 220)
        notify("oxyX Image", "No image is currently loaded.", 2)
    end
end)

-- ============================================================
-- PAGE 4: INFO
-- ============================================================
local p4 = tabPages[4]

local infoLines = {
    {"⚡ oxyX BABFT Suite", Color3.fromRGB(200, 150, 255), 16},
    {"Powered by oxyX Market", Color3.fromRGB(120, 80, 180), 12},
    {"", Color3.fromRGB(255,255,255), 8},
    {"🔨 AutoBuild", Color3.fromRGB(160, 120, 220), 13},
    {"  • Only works with .build format (JSON)", Color3.fromRGB(160, 160, 200), 11},
    {"  • Supports position, size, color, material", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"📦 OBJ Loader", Color3.fromRGB(160, 120, 220), 13},
    {"  • Parses .obj files (v, vn, vt, f lines)", Color3.fromRGB(160, 160, 200), 11},
    {"  • Convert OBJ → .build format", Color3.fromRGB(160, 160, 200), 11},
    {"  • Export Roblox Studio import script", Color3.fromRGB(160, 160, 200), 11},
    {"  • Compatible with Sketchfab exports", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"🖼️ Image Loader", Color3.fromRGB(160, 120, 220), 13},
    {"  • Only Discord CDN links supported", Color3.fromRGB(160, 160, 200), 11},
    {"  • cdn.discordapp.com / media.discordapp.net", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"🖥️ Executor Support", Color3.fromRGB(160, 120, 220), 13},
    {"  • Xeno / Velocity / Fluxus", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"Detected: " .. executor, Color3.fromRGB(120, 200, 120), 11},
}

local yOff = 0
for _, info in ipairs(infoLines) do
    local lbl = Instance.new("TextLabel", p4)
    lbl.Size = UDim2.new(1, 0, 0, info[3] + 4)
    lbl.Position = UDim2.new(0, 0, 0, yOff)
    lbl.BackgroundTransparency = 1
    lbl.Text = info[1]
    lbl.TextColor3 = info[2]
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = info[3]
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    yOff = yOff + info[3] + 5
end

-- ============================================================
-- ANIMATED ACCENT LINE
-- ============================================================
local accentLine = Instance.new("Frame", MainFrame)
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 0, 48)
accentLine.BackgroundColor3 = Color3.fromRGB(100, 50, 220)
accentLine.BorderSizePixel = 0

local accentGrad = Instance.new("UIGradient", accentLine)
accentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 30, 180)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 30, 180))
})

-- Animate accent line
task.spawn(function()
    local t = 0
    while ScreenGui and ScreenGui.Parent do
        t = t + 0.02
        accentGrad.Offset = Vector2.new(math.sin(t) * 0.5, 0)
        task.wait(0.03)
    end
end)

-- ============================================================
-- STARTUP ANIMATION
-- ============================================================
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
tween(MainFrame, {
    Size = UDim2.new(0, 520, 0, 480),
    Position = UDim2.new(0.5, -260, 0.5, -240)
}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ============================================================
-- INITIALIZE FIRST TAB
-- ============================================================
switchTab(1)

-- ============================================================
-- STARTUP NOTIFICATION
-- ============================================================
task.delay(0.6, function()
    notify("oxyX BABFT Suite", "Loaded! Executor: " .. executor, 4)
end)

-- ============================================================
-- END OF SCRIPT
-- ============================================================
-- oxyX BABFT Suite v1.0
-- Powered by oxyX Market
-- Compatible: Xeno / Velocity / Fluxus
