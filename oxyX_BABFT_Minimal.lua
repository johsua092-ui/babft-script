--[[
    oxyX BABFT - MINIMAL VERSION (v3.0)
    Fixed for all executors
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- Simple executor detection
local executorName = "Unknown"
if identifyexecutor then
    executorName = identifyexecutor()
elseif getexecutorname then
    executorName = getexecutorname()
end

-- ============================================================
-- GUI PARENT (Simple approach)
-- ============================================================
local guiParent = player:WaitForChild("PlayerGui", 5)
if not guiParent then
    guiParent = game:GetService("CoreGui")
end

-- ============================================================
-- UTILITIES
-- ============================================================
local function tween(obj, props, duration)
    duration = duration or 0.3
    local tweenObj = TweenService:Create(obj, TweenInfo.new(duration), props)
    tweenObj:Play()
    return tweenObj
end

local function notify(msg)
    local gui = Instance.new("ScreenGui", guiParent)
    gui.Name = "oxyX_Notif"
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(1, -320, 1, -80)
    frame.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    frame.BorderSizePixel = 0
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "⚡ " .. msg
    label.TextColor3 = Color3.fromRGB(180, 140, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    
    -- Animate
    frame.Position = UDim2.new(1, 20, 1, -80)
    tween(frame, {Position = UDim2.new(1, -320, 1, -80)}, 0.4)
    
    task.delay(3, function()
        tween(frame, {Position = UDim2.new(1, 20, 1, -80)}, 0.4)
        task.delay(0.5, function() gui:Destroy() end)
    end)
end

-- ============================================================
-- BLOCK LIBRARY
-- ============================================================
local blockLibrary = {
    "Smooth Plastic", "Wood", "Wood Plank", "Metal", "Concrete", "Brick",
    "Ice", "Neon", "Gold", "Grass", "Sand", "Stone", "Marble", "Granite",
    "Obsidian", "Cinderblock", "Corrosion", "Diamond Plate", "Foil", "Pearl",
    "Plaster", "Neon Pink", "Neon Green", "Neon Blue", "Neon Red", "Neon Orange",
    "Neon Purple", "Brown", "Tan", "Light Stone", "Dark Stone", "Red", "Blue",
    "Yellow", "Green", "White", "Black", "Gray", "Light Gray", "Dark Gray"
}

local function normalizeBlockName(raw)
    if not raw then return "Smooth Plastic" end
    raw = tostring(raw):lower()
    for _, block in ipairs(blockLibrary) do
        if block:lower() == raw then return block end
    end
    return "Smooth Plastic"
end

-- ============================================================
-- INVENTORY
-- ============================================================
local function getInventory()
    local inv = {}
    
    pcall(function()
        -- Method 1: leaderstats
        if player:FindFirstChild("leaderstats") then
            for _, child in ipairs(player.leaderstats:GetChildren()) do
                if child:IsA("IntValue") then
                    local name = child.Name
                    if name ~= "Cash" and name ~= "Kills" and name ~= "Gold" then
                        inv[name] = child.Value
                    end
                end
            end
        end
    end)
    
    pcall(function()
        -- Method 2: Direct children
        for _, child in ipairs(player:GetChildren()) do
            if child:IsA("IntValue") then
                inv[child.Name] = child.Value
            end
        end
    end)
    
    return inv
end

-- ============================================================
-- FILE FUNCTIONS
-- ============================================================
local function listFiles(ext)
    local files = {}
    pcall(function()
        if listfiles then
            local all = listfiles("")
            for _, path in ipairs(all) do
                local name = path:match("([^/\\]+)$") or path
                if not ext or name:lower():sub(-#ext) == ext:lower() then
                    table.insert(files, {path = path, name = name})
                end
            end
        end
    end)
    return files
end

local function readFile(path)
    local content = nil
    pcall(function()
        if readfile then
            content = readfile(path)
        end
    end)
    return content
end

-- ============================================================
-- BUILD DATA PARSING
-- ============================================================
local function parseBuild(raw)
    if not raw or raw == "" then return {} end
    
    -- Try JSON
    local ok, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    
    if ok and type(data) == "table" and #data > 0 then
        return data
    end
    
    return {}
end

local function analyzeBlocks(buildData)
    local counts = {}
    for _, part in ipairs(buildData) do
        if type(part) == "table" then
            local block = part.Block or part.Material or part.Type or part.type or "Smooth Plastic"
            local name = normalizeBlockName(block)
            counts[name] = (counts[name] or 0) + 1
        end
    end
    
    local result = {}
    for name, count in pairs(counts) do
        table.insert(result, {name = name, count = count})
    end
    table.sort(result, function(a, b) return a.count > b.count end)
    return result
end

-- ============================================================
-- MAIN GUI
-- ============================================================
-- Destroy old
for _, v in ipairs(guiParent:GetChildren()) do
    if v.Name == "oxyX_BABFT" then pcall(function() v:Destroy() end) end
end

local ScreenGui = Instance.new("ScreenGui", guiParent)
ScreenGui.Name = "oxyX_BABFT"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Main Frame
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 480)
Main.Position = UDim2.new(0.5, -260, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
Main.BorderSizePixel = 0

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(100, 50, 200)
stroke.Thickness = 1.5

-- Title
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -60, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "⚡ oxyX BABFT v3.0"
Title.TextColor3 = Color3.fromRGB(200, 160, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Main)
SubTitle.Size = UDim2.new(1, -60, 0, 16)
SubTitle.Position = UDim2.new(0, 12, 0, 36)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Executor: " .. executorName
SubTitle.TextColor3 = Color3.fromRGB(120, 80, 180)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Close
local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.BorderSizePixel = 0

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    tween(Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    task.delay(0.35, function() ScreenGui:Destroy() end)
end)

-- Content
local Content = Instance.new("ScrollingFrame", Main)
Content.Size = UDim2.new(1, -20, 1, -60)
Content.Position = UDim2.new(0, 10, 0, 50)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 220)

local Layout = Instance.new("UIListLayout", Content)
