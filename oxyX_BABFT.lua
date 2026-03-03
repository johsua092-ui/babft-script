-- ██████╗ ██╗  ██╗██╗   ██╗██╗  ██╗
-- ██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝╚██╗██╔╝
-- ██║   ██║ ╚███╔╝  ╚████╔╝  ╚███╔╝ 
-- ██║   ██║ ██╔██╗   ╚██╔╝   ██╔██╗ 
-- ╚██████╔╝██╔╝ ██╗   ██║   ██╔╝ ██╗
--  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
-- oxyX BABFT Suite v2.1 | Powered by oxyX Market
-- Compatible: Xeno / Velocity / Fluxus

-- ============================================================
-- BABFT INVENTORY INTEGRATION
-- ============================================================
-- Build A Boat For Treasure block inventory system

local HttpService = game:GetService("HttpService")

-- Try to get BABFT block inventory from various possible locations
local function getPlayerBlockInventory()
    local inventory = {}
    
    pcall(function()
        -- Method 1: leaderstats (common in many games)
        if player:FindFirstChild("leaderstats") then
            local leaderstats = player.leaderstats
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    inventory[stat.Name] = stat.Value
                elseif stat:IsA("StringValue") then
                    -- Might be JSON encoded inventory
                    local ok, decoded = pcall(function()
                        return HttpService:JSONDecode(stat.Value)
                    end)
                    if ok and type(decoded) == "table" then
                        for blockName, count in pairs(decoded) do
                            inventory[blockName] = count
                        end
                    end
                end
            end
        end
    end)
    
    pcall(function()
        -- Method 2: Direct child named "Blocks" or "Inventory"
        local inventoryObj = player:FindFirstChild("Blocks") or player:FindFirstChild("Inventory") or player:FindFirstChild("BlockInventory")
        if inventoryObj then
            for _, block in ipairs(inventoryObj:GetChildren()) do
                if block:IsA("IntValue") or block:IsA("NumberValue") then
                    inventory[block.Name] = block.Value
                elseif block:IsA("StringValue") then
                    local ok, count = pcall(tonumber, block.Value)
                    if ok then
                        inventory[block.Name] = count
                    end
                end
            end
        end
    end)
    
    pcall(function()
        -- Method 3: Player data in ReplicatedStorage (some games)
        local rs = game:GetService("ReplicatedStorage")
        local playerData = rs:FindFirstChild("PlayerData") or rs:FindFirstChild("Inventories")
        if playerData then
            local thisPlayerData = playerData:FindFirstChild(tostring(player.UserId))
            if thisPlayerData then
                local blocks = thisPlayerData:FindFirstChild("Blocks") or thisPlayerData:FindFirstChild("Inventory")
                if blocks then
                    for _, block in ipairs(blocks:GetChildren()) do
                        if block:IsA("IntValue") or block:IsA("NumberValue") then
                            inventory[block.Name] = block.Value
                        end
                    end
                end
            end
        end
    end)
    
    return inventory
end

-- Check if player has enough of a specific block
local function hasBlock(blockName, amount)
    amount = amount or 1
    local inventory = getPlayerBlockInventory()
    
    -- Debug: Show inventory on first check
    if not hasBlock._debugged then
        hasBlock._debugged = true
        local debugMsg = "Inventory detected:"
        local count = 0
        for name, amt in pairs(inventory) do
            debugMsg = debugMsg .. " " .. name .. "=" .. amt
            count = count + 1
            if count >= 10 then break end
        end
        if count == 0 then
            debugMsg = "Inventory: NONE FOUND (check leaderstats)"
        end
        notify("oxyX Debug", debugMsg, 5)
    end
    
    local available = inventory[blockName] or 0
    return available >= amount
end

-- Try to use/deduct block from inventory (returns true if successful)
local function useBlock(blockName, amount)
    amount = amount or 1
    
    -- Method 1: Try RemoteEvent
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local useBlockRemote = rs:FindFirstChild("UseBlock") 
            or rs:FindFirstChild("UseItem")
            or rs:FindFirstChild("RemoveBlock")
            or rs:FindFirstChild("SpendBlock")
            or rs:FindFirstChild("TakeBlock")
        
        if useBlockRemote and useBlockRemote:IsA("RemoteFunction") then
            local result = useBlockRemote:InvokeServer(blockName, amount)
            if result == true or result == "success" then
                return true
            end
        elseif useBlockRemote and useBlockRemote:IsA("RemoteEvent") then
            useBlockRemote:FireServer(blockName, amount)
            return true
        end
    end)
    
    -- Method 2: Direct modification (for local testing / bypass)
    -- Note: This rarely works in online games due to anti-cheat
    pcall(function()
        -- Try leaderstats
        if player:FindFirstChild("leaderstats") then
            local blockStat = player.leaderstats:FindFirstChild(blockName)
            if blockStat and blockStat:IsA("IntValue") then
                blockStat.Value = math.max(0, blockStat.Value - amount)
                return true
            end
        end
        
        -- Try player children
        local blockObj = player:FindFirstChild(blockName)
        if blockObj and blockObj:IsA("IntValue") then
            blockObj.Value = math.max(0, blockObj.Value - amount)
            return true
        end
    end)
    
    return false
end

-- Get inventory display string
local function getInventoryDisplay()
    local inventory = getPlayerBlockInventory()
    local count = 0
    local totalBlocks = 0
    for _, v in pairs(inventory) do
        count = count + 1
        totalBlocks = totalBlocks + (tonumber(v) or 0)
    end
    if count == 0 then
        return "No inventory data found"
    end
    return count .. " types, " .. totalBlocks .. " total blocks"
end

-- Show inventory warning before build
local function checkInventoryAndWarn(requiredBlocks)
    local inventory = getPlayerBlockInventory()
    local missing = {}
    local hasEnough = true
    
    for _, blockInfo in ipairs(requiredBlocks) do
        local blockName = blockInfo.name
        local amount = blockInfo.count
        local available = inventory[blockName] or 0
        
        -- Debug: Show what's being checked
        if not checkInventoryAndWarn._debugShow then
            checkInventoryAndWarn._debugShow = true
            notify("oxyX Debug", "Checking: " .. blockName .. " need=" .. amount .. " have=" .. available, 5)
        end
        
        if available < amount then
            table.insert(missing, {name = blockName, needed = amount, have = available})
            hasEnough = false
        end
    end
    
    if not hasEnough then
        local missingStr = ""
        for _, m in ipairs(missing) do
            missingStr = missingStr .. "\n  • " .. m.name .. ": need " .. m.needed .. ", have " .. m.have
        end
        notify("oxyX Inventory", "Missing blocks:" .. missingStr, 6)
        return false
    end
    
    return true
end

-- ============================================================
-- BABFT INVENTORY INTEGRATION END
-- ============================================================

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
-- WORKSPACE FILE BROWSER HELPER
-- ============================================================
-- ============================================================
-- WORKSPACE FILE WRITER (for uploading files)
-- ============================================================
local function writeWorkspaceFile(path, content)
    local success = false
    pcall(function()
        if writefile then
            writefile(path, content)
            success = true
        end
    end)
    return success
end

-- ============================================================
-- BLOCK LIBRARY SYSTEM
-- ============================================================
-- Define available blocks in Roblox (material -> color info)
local blockLibrary = {
    -- Basic blocks
    {name = "SmoothPlastic", material = "SmoothPlastic", color = {r=163, g=162, b=165}, unlocked = true},
    {name = "Wood", material = "Wood", color = {r=163, g=162, b=165}, unlocked = true},
    {name = "Wood Plank", material = "Wood", color = {r=143, g=130, b=100}, unlocked = true},
    {name = "Metal", material = "Metal", color = {r=192, g=192, b=192}, unlocked = true},
    {name = "Concrete", material = "Slate", color = {r=100, g=100, b=100}, unlocked = true},
    {name = "Brick", material = "Brick", color = {r=196, g=40, b=28}, unlocked = true},
    {name = "Ice", material = "Ice", color = {r=133, g=133, b=163}, unlocked = true},
    {name = "Neon", material = "Neon", color = {r=0, g=255, b=255}, unlocked = true},
    {name = "Gold", material = "DiamondPlate", color = {r=212, g=175, b=55}, unlocked = true},
    {name = "Grass", material = "Grass", color = {r=67, g=205, b=128}, unlocked = true},
    {name = "Sand", material = "Sand", color = {r=237, g=201, b=175}, unlocked = true},
    {name = "Stone", material = "Cobblestone", color = {r=128, g=128, b=128}, unlocked = true},
    {name = "Marble", material = "Marble", color = {r=230, g=225, b=220}, unlocked = false},
    {name = "Granite", material = "Granite", color = {r=140, g=140, b=140}, unlocked = false},
    {name = "Obsidian", material = "Obsidian", color = {r=30, g=30, b=35}, unlocked = false},
    {name = "Cinderblock", material = "Cinderblock", color = {r=90, g=90, b=90}, unlocked = false},
    {name = "Corrosion", material = "Corrosion", color = {r=100, g=120, b=80}, unlocked = false},
    {name = "DiamondPlate", material = "DiamondPlate", color = {r=180, g=180, b=190}, unlocked = false},
    {name = "Foil", material = "Foil", color = {r=200, g=200, b=210}, unlocked = false},
    {name = "Pearl", material = "Pearl", color = {r=230, g=230, b=235}, unlocked = false},
    {name = "Plaster", material = "Plaster", color = {r=220, g=215, b=205}, unlocked = false},
    {name = "Neon Pink", material = "Neon", color = {r=255, g=0, b=127}, unlocked = false},
    {name = "Neon Green", material = "Neon", color = {r=50, g=255, b=50}, unlocked = false},
    {name = "Neon Blue", material = "Neon", color = {r=0, g=150, b=255}, unlocked = false},
    {name = "Neon Red", material = "Neon", color = {r=255, g=50, b=50}, unlocked = false},
    {name = "Neon Orange", material = "Neon", color = {r=255, g=150, b=0}, unlocked = false},
    {name = "Neon Purple", material = "Neon", color = {r=180, g=50, b=255}, unlocked = false},
}

-- Function to analyze build and find required blocks
local function analyzeBuildBlocks(buildData)
    local requiredBlocks = {}
    local blockCounts = {}
    
    -- DEBUG: Show how many parts we're analyzing
    notify("oxyX Debug", "Analyzing " .. #buildData .. " parts...", 3)
    
    for _, partData in ipairs(buildData) do
        if type(partData) == "table" then
            -- Support multiple field names
            local mat = partData.material or partData.Material or partData.Block or "SmoothPlastic"
            local color = partData.color or partData.Color or partData.Colour or {r=163, g=162, b=165}
            
            -- Find matching block from library
            local blockName = mat
            local found = false
            
            for _, block in ipairs(blockLibrary) do
                if block.material:lower() == mat:lower() then
                    local colorR = color.r or color.R or 163
                    local colorG = color.g or color.G or 162
                    local colorB = color.b or color.B or 165
                    
                    local colorMatch = math.abs(block.color.r - colorR) < 20
                        and math.abs(block.color.g - colorG) < 20
                        and math.abs(block.color.b - colorB) < 20
                    if colorMatch then
                        blockName = block.name
                        found = true
                        break
                    end
                end
            end
            
            -- If no match found, use the material name directly
            if not found then
                blockName = mat
            end
            
            blockCounts[blockName] = (blockCounts[blockName] or 0) + 1
        end
    end
    
    -- DEBUG: Show what blocks we found
    local debugBlocks = ""
    local count = 0
    for name, cnt in pairs(blockCounts) do
        debugBlocks = debugBlocks .. name .. "=" .. cnt .. " "
        count = count + 1
    end
    notify("oxyX Debug", "Found " .. count .. " block types: " .. debugBlocks, 5)
    
    -- Convert to sorted list
    for name, count in pairs(blockCounts) do
        table.insert(requiredBlocks, {name = name, count = count})
    end
    table.sort(requiredBlocks, function(a, b) return a.count > b.count end)
    
    return requiredBlocks
end

-- Function to find missing (locked) blocks
local function findMissingBlocks(requiredBlocks)
    local missing = {}
    for _, req in ipairs(requiredBlocks) do
        local found = false
        for _, block in ipairs(blockLibrary) do
            if block.name:lower() == req.name:lower() and block.unlocked then
                found = true
                break
            end
        end
        if not found then
            table.insert(missing, req)
        end
    end
    return missing
end

-- ============================================================
-- WORKSPACE FILE BROWSER HELPER
-- ============================================================
-- Lists files in executor workspace filtered by extension
local function listWorkspaceFiles(ext)
    local files = {}
    local ok, result = pcall(function()
        -- Try listfiles (Synapse/Xeno/most executors)
        if listfiles then
            local all = listfiles("")
            for _, path in ipairs(all) do
                local name = path:match("([^/\\]+)$") or path
                if ext == nil or name:lower():sub(-#ext) == ext:lower() then
                    table.insert(files, {path = path, name = name})
                end
            end
        end
    end)
    if not ok or #files == 0 then
        -- Fallback: try readdir if available
        pcall(function()
            if readdir then
                local all = readdir("")
                for _, entry in ipairs(all) do
                    local name = type(entry) == "string" and entry or entry.name or ""
                    if ext == nil or name:lower():sub(-#ext) == ext:lower() then
                        table.insert(files, {path = name, name = name})
                    end
                end
            end
        end)
    end
    return files
end

local function readWorkspaceFile(path)
    local content = nil
    pcall(function()
        if readfile then
            content = readfile(path)
        end
    end)
    return content
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
MainFrame.Size = UDim2.new(0, 560, 0, 680)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -340)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local mainCorner = Instance.new("UICorner", MainFrame)
mainCorner.CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Color3.fromRGB(100, 50, 220)
mainStroke.Thickness = 1.5

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

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ oxyX BABFT Suite v2.1"
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
local ContentFrame

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
tabLayout.Padding = UDim.new(0, 5)

-- 5 tabs now: AutoBuild, OBJ→Studio, OBJ→Sketchfab, Image, Info
local tabNames = {"🔨 AutoBuild", "🎮 OBJ Studio", "📦 OBJ External", "🖼️ Image", "ℹ️ Info"}
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

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tween(MainFrame, {Size = UDim2.new(0, 560, 0, 52)}, 0.3)
        ContentFrame.Visible = false
        TabBar.Visible = false
    else
        ContentFrame.Visible = true
        TabBar.Visible = true
        tween(MainFrame, {Size = UDim2.new(0, 560, 0, 520)}, 0.3)
    end
end)

-- ============================================================
-- HELPER: CREATE PAGE
-- ============================================================
local function createPage()
    local page = Instance.new("ScrollingFrame", ContentFrame)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 220)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.BorderSizePixel = 0
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
-- HELPER: FILE SELECTOR DROPDOWN
-- ============================================================
-- Creates a file selector UI that lists workspace files with given extension
-- Returns: selectedPathLabel (TextLabel), refreshBtn (TextButton), selectedPath (table ref)
local function createFileSelector(parent, ext, posY, labelText, accentColor)
    accentColor = accentColor or Color3.fromRGB(100, 50, 220)
    local selectedPath = {value = nil, name = nil}

    -- Section label
    local sectionLbl = Instance.new("TextLabel", parent)
    sectionLbl.Size = UDim2.new(1, 0, 0, 18)
    sectionLbl.Position = UDim2.new(0, 0, 0, posY)
    sectionLbl.BackgroundTransparency = 1
    sectionLbl.Text = labelText
    sectionLbl.TextColor3 = Color3.fromRGB(160, 120, 220)
    sectionLbl.Font = Enum.Font.GothamBold
    sectionLbl.TextSize = 12
    sectionLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Selected file display
    local selBg = Instance.new("Frame", parent)
    selBg.Size = UDim2.new(1, -44, 0, 34)
    selBg.Position = UDim2.new(0, 0, 0, posY + 22)
    selBg.BackgroundColor3 = Color3.fromRGB(20, 15, 38)
    selBg.BorderSizePixel = 0

    local selCorner = Instance.new("UICorner", selBg)
    selCorner.CornerRadius = UDim.new(0, 8)

    local selStroke = Instance.new("UIStroke", selBg)
    selStroke.Color = Color3.fromRGB(70, 40, 130)
    selStroke.Thickness = 1

    local selLbl = Instance.new("TextLabel", selBg)
    selLbl.Size = UDim2.new(1, -10, 1, 0)
    selLbl.Position = UDim2.new(0, 8, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text = "No file selected"
    selLbl.TextColor3 = Color3.fromRGB(100, 80, 140)
    selLbl.Font = Enum.Font.Gotham
    selLbl.TextSize = 11
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Refresh button
    local refreshBtn = Instance.new("TextButton", parent)
    refreshBtn.Size = UDim2.new(0, 38, 0, 34)
    refreshBtn.Position = UDim2.new(1, -38, 0, posY + 22)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 80)
    refreshBtn.Text = "🔄"
    refreshBtn.TextColor3 = Color3.fromRGB(200, 180, 255)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 14
    refreshBtn.BorderSizePixel = 0
    refreshBtn.AutoButtonColor = false

    local refCorner = Instance.new("UICorner", refreshBtn)
    refCorner.CornerRadius = UDim.new(0, 8)

    -- File list dropdown frame
    local dropFrame = Instance.new("Frame", parent)
    dropFrame.Size = UDim2.new(1, 0, 0, 0)
    dropFrame.Position = UDim2.new(0, 0, 0, posY + 60)
    dropFrame.BackgroundColor3 = Color3.fromRGB(16, 12, 30)
    dropFrame.BorderSizePixel = 0
    dropFrame.ClipsDescendants = true
    dropFrame.Visible = false

    local dropCorner = Instance.new("UICorner", dropFrame)
    dropCorner.CornerRadius = UDim.new(0, 8)

    local dropStroke = Instance.new("UIStroke", dropFrame)
    dropStroke.Color = Color3.fromRGB(70, 40, 130)
    dropStroke.Thickness = 1

    local dropScroll = Instance.new("ScrollingFrame", dropFrame)
    dropScroll.Size = UDim2.new(1, -4, 1, 0)
    dropScroll.Position = UDim2.new(0, 2, 0, 0)
    dropScroll.BackgroundTransparency = 1
    dropScroll.ScrollBarThickness = 3
    dropScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 220)
    dropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    dropScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dropScroll.BorderSizePixel = 0

    local dropLayout = Instance.new("UIListLayout", dropScroll)
    dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dropLayout.Padding = UDim.new(0, 2)

    local dropOpen = false
    local fileList = {}

    local function populateDropdown()
        -- Clear existing items
        for _, child in ipairs(dropScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        fileList = listWorkspaceFiles(ext)

        if #fileList == 0 then
            local noFileLbl = Instance.new("TextButton", dropScroll)
            noFileLbl.Size = UDim2.new(1, 0, 0, 30)
            noFileLbl.BackgroundTransparency = 1
            noFileLbl.Text = "  ⚠️ No " .. ext .. " files found in workspace"
            noFileLbl.TextColor3 = Color3.fromRGB(200, 150, 80)
            noFileLbl.Font = Enum.Font.Gotham
            noFileLbl.TextSize = 11
            noFileLbl.TextXAlignment = Enum.TextXAlignment.Left
            noFileLbl.BorderSizePixel = 0
            noFileLbl.AutoButtonColor = false
        else
            for idx, fileInfo in ipairs(fileList) do
                local itemBtn = Instance.new("TextButton", dropScroll)
                itemBtn.Size = UDim2.new(1, 0, 0, 32)
                itemBtn.BackgroundColor3 = Color3.fromRGB(22, 16, 42)
                itemBtn.Text = "  📄 " .. fileInfo.name
                itemBtn.TextColor3 = Color3.fromRGB(200, 180, 240)
                itemBtn.Font = Enum.Font.Gotham
                itemBtn.TextSize = 11
                itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                itemBtn.BorderSizePixel = 0
                itemBtn.AutoButtonColor = false
                itemBtn.LayoutOrder = idx

                local itemCorner = Instance.new("UICorner", itemBtn)
                itemCorner.CornerRadius = UDim.new(0, 6)

                itemBtn.MouseEnter:Connect(function()
                    tween(itemBtn, {BackgroundColor3 = Color3.fromRGB(50, 35, 90)}, 0.1)
                end)
                itemBtn.MouseLeave:Connect(function()
                    tween(itemBtn, {BackgroundColor3 = Color3.fromRGB(22, 16, 42)}, 0.1)
                end)

                itemBtn.MouseButton1Click:Connect(function()
                    selectedPath.value = fileInfo.path
                    selectedPath.name = fileInfo.name
                    selLbl.Text = "📄 " .. fileInfo.name
                    selLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
                    tween(selStroke, {Color = accentColor}, 0.2)
                    -- Close dropdown
                    dropOpen = false
                    tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    task.delay(0.25, function()
                        dropFrame.Visible = false
                    end)
                end)
            end
        end
    end

    -- Toggle dropdown on click of selBg
    selBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dropOpen = not dropOpen
            if dropOpen then
                populateDropdown()
                dropFrame.Visible = true
                local targetH = math.min(#fileList * 34 + 8, 140)
                if #fileList == 0 then targetH = 38 end
                tween(dropFrame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
                tween(selStroke, {Color = Color3.fromRGB(140, 80, 255)}, 0.2)
            else
                tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                task.delay(0.25, function()
                    dropFrame.Visible = false
                end)
                tween(selStroke, {Color = Color3.fromRGB(70, 40, 130)}, 0.2)
            end
        end
    end)

    refreshBtn.MouseButton1Click:Connect(function()
        if dropOpen then
            populateDropdown()
        else
            dropOpen = true
            populateDropdown()
            dropFrame.Visible = true
            local targetH = math.min(#fileList * 34 + 8, 140)
            if #fileList == 0 then targetH = 38 end
            tween(dropFrame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
        end
        notify("oxyX", "Refreshed " .. ext .. " file list!", 2)
    end)

    -- Returns: selectedPath table, dropFrame (so caller can offset below it), selLbl, refreshBtn
    return selectedPath, dropFrame, selLbl, refreshBtn
end

-- ============================================================
-- TAB CREATION
-- ============================================================
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 96, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 15, 38)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(140, 110, 190)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
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
-- PAGE 1: AUTOBUILD (File Selector — .build files only)
-- ============================================================
local p1 = tabPages[1]

createLabel(p1, "📂 Select a .build file from your workspace:", 0, 18, Color3.fromRGB(160, 120, 220))
createLabel(p1, "Only .build files are shown (e.g. ocd.build)", 18, 14, Color3.fromRGB(100, 80, 150))

-- File Upload Section
local uploadY = 36
createLabel(p1, "📤 Upload a .build file to workspace:", uploadY, 18, Color3.fromRGB(160, 120, 220))

-- Upload input
local uploadInput = Instance.new("TextBox", p1)
uploadInput.Size = UDim2.new(1, -100, 0, 30)
uploadInput.Position = UDim2.new(0, 0, 0, uploadY + 22)
uploadInput.BackgroundColor3 = Color3.fromRGB(20, 15, 38)
uploadInput.BorderSizePixel = 0

uploadInput.Text = "Paste file content here..."
uploadInput.TextColor3 = Color3.fromRGB(100, 80, 140)
uploadInput.Font = Enum.Font.Gotham
uploadInput.TextSize = 11

local uploadCorner = Instance.new("UICorner", uploadInput)
uploadCorner.CornerRadius = UDim.new(0, 6)

local uploadStroke = Instance.new("UIStroke", uploadInput)
uploadStroke.Color = Color3.fromRGB(70, 40, 130)
uploadStroke.Thickness = 1

-- Filename input
local fileNameInput = Instance.new("TextBox", p1)
fileNameInput.Size = UDim2.new(0, 150, 0, 30)
fileNameInput.Position = UDim2.new(1, -155, 0, uploadY + 22)
fileNameInput.BackgroundColor3 = Color3.fromRGB(20, 15, 38)
fileNameInput.BorderSizePixel = 0
fileNameInput.Text = "mybuild.build"
fileNameInput.TextColor3 = Color3.fromRGB(160, 160, 180)
fileNameInput.Font = Enum.Font.Gotham
fileNameInput.TextSize = 11

local fnCorner = Instance.new("UICorner", fileNameInput)
fnCorner.CornerRadius = UDim.new(0, 6)

local fnStroke = Instance.new("UIStroke", fileNameInput)
fnStroke.Color = Color3.fromRGB(70, 40, 130)
fnStroke.Thickness = 1

-- Upload button
local uploadBtn = Instance.new("TextButton", p1)
uploadBtn.Size = UDim2.new(0, 100, 0, 30)
uploadBtn.Position = UDim2.new(0, 0, 0, uploadY + 58)
uploadBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 140)
uploadBtn.Text = "💾 Upload"
uploadBtn.TextColor3 = Color3.fromRGB(220, 200, 255)
uploadBtn.Font = Enum.Font.GothamBold
uploadBtn.TextSize = 12
uploadBtn.BorderSizePixel = 0

uploadBtn.MouseButton1Click:Connect(function()
    local content = uploadInput.Text
    local fileName = fileNameInput.Text
    
    if not content or content == "" or content == "Paste file content here..." then
        notify("oxyX BABFT", "Please paste file content first!", 3)
        return
    end
    
    if not fileName or fileName == "" then
        notify("oxyX BABFT", "Please enter a filename!", 3)
        return
    end
    
    if not fileName:lower():match("%.build$") then
        fileName = fileName .. ".build"
    end
    
    if writeWorkspaceFile(fileName, content) then
        notify("oxyX BABFT", "File uploaded: " .. fileName, 3)
        -- Refresh file list
        if refreshFileList then refreshFileList() end
    else
        notify("oxyX BABFT", "Failed to upload file!", 3)
    end
end)

local upCorner = Instance.new("UICorner", uploadBtn)
upCorner.CornerRadius = UDim.new(0, 6)

-- File selector for .build
local buildFileSelected, buildDropFrame, buildSelLbl, buildRefreshBtn = createFileSelector(
    p1, ".build", uploadY + 100,
    "📁 Workspace .build Files:",
    Color3.fromRGB(100, 50, 220)
)

-- Refresh file list when clicking refresh button
if buildRefreshBtn then
    buildRefreshBtn.MouseButton1Click:Connect(function()
        task.delay(0.2, updatePreviewAndBlockList)
    end)
end

-- Dynamic Y offset after dropdown (dropdown max height ~140)
local buildControlsY = uploadY + 100 + 22 + 34 + 145  -- label + selBg + dropdown max + padding

-- ============================================================
-- BUILD PREVIEW SECTION
-- ============================================================
createLabel(p1, "🔍 Build Preview:", buildControlsY, 18, Color3.fromRGB(160, 120, 220))

-- Preview container
local previewContainer = Instance.new("Frame", p1)
previewContainer.Size = UDim2.new(1, -10, 0, 120)
previewContainer.Position = UDim2.new(0, 5, 0, buildControlsY + 22)
previewContainer.BackgroundColor3 = Color3.fromRGB(15, 12, 28)
previewContainer.BorderSizePixel = 0

local previewCorner = Instance.new("UICorner", previewContainer)
previewCorner.CornerRadius = UDim.new(0, 8)

local previewStroke = Instance.new("UIStroke", previewContainer)
previewStroke.Color = Color3.fromRGB(70, 40, 130)
previewStroke.Thickness = 1

-- Preview info label
local previewInfo = Instance.new("TextLabel", previewContainer)
previewInfo.Size = UDim2.new(1, -10, 0, 20)
previewInfo.Position = UDim2.new(0, 5, 0, 5)
previewInfo.BackgroundTransparency = 1
previewInfo.Text = "Select a .build file to see preview"
previewInfo.TextColor3 = Color3.fromRGB(100, 80, 140)
previewInfo.Font = Enum.Font.Gotham
previewInfo.TextSize = 11
previewInfo.TextXAlignment = Enum.TextXAlignment.Left

-- Preview scroll for parts
local previewScroll = Instance.new("ScrollingFrame", previewContainer)
previewScroll.Size = UDim2.new(1, -10, 0, 70)
previewScroll.Position = UDim2.new(0, 5, 0, 30)
previewScroll.BackgroundTransparency = 1
previewScroll.ScrollBarThickness = 3
previewScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 220)
previewScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local previewLayout = Instance.new("UIListLayout", previewScroll)
previewLayout.SortOrder = Enum.SortOrder.LayoutOrder
previewLayout.Padding = UDim.new(0, 2)

-- Preview canvas for simple visualization
local previewCanvas = Instance.new("Frame", previewContainer)
previewCanvas.Size = UDim2.new(0, 60, 0, 60)
previewCanvas.Position = UDim2.new(1, -70, 0.5, -30)
previewCanvas.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
previewCanvas.BorderSizePixel = 0

local canvasCorner = Instance.new("UICorner", previewCanvas)
canvasCorner.CornerRadius = UDim.new(0, 8)

local canvasLabel = Instance.new("TextLabel", previewCanvas)
canvasLabel.Size = UDim2.new(1, 0, 1, 0)
canvasLabel.BackgroundTransparency = 1
canvasLabel.Text = "📦"
canvasLabel.TextColor3 = Color3.fromRGB(160, 120, 220)
canvasLabel.Font = Enum.Font.GothamBold
canvasLabel.TextSize = 24

local previewPartCount = Instance.new("TextLabel", previewCanvas)
previewPartCount.Size = UDim2.new(1, 0, 0, 15)
previewPartCount.Position = UDim2.new(0, 0, 1, -15)
previewPartCount.BackgroundTransparency = 1
previewPartCount.Text = "0 parts"
previewPartCount.TextColor3 = Color3.fromRGB(180, 180, 200)
previewPartCount.Font = Enum.Font.Gotham
previewPartCount.TextSize = 9

-- ============================================================
-- BLOCK LIST SECTION
-- ============================================================
local blockListY = buildControlsY + 150
createLabel(p1, "🧱 Required Blocks:", blockListY, 18, Color3.fromRGB(160, 120, 220))

-- Block list container
local blockListContainer = Instance.new("Frame", p1)
blockListContainer.Size = UDim2.new(1, -10, 0, 100)
blockListContainer.Position = UDim2.new(0, 5, 0, blockListY + 22)
blockListContainer.BackgroundColor3 = Color3.fromRGB(15, 12, 28)
blockListContainer.BorderSizePixel = 0

local blCorner = Instance.new("UICorner", blockListContainer)
blCorner.CornerRadius = UDim.new(0, 8)

local blStroke = Instance.new("UIStroke", blockListContainer)
blStroke.Color = Color3.fromRGB(70, 40, 130)
blStroke.Thickness = 1

-- Block list scroll
local blockListScroll = Instance.new("ScrollingFrame", blockListContainer)
blockListScroll.Size = UDim2.new(1, -10, 1, -10)
blockListScroll.Position = UDim2.new(0, 5, 0, 5)
blockListScroll.BackgroundTransparency = 1
blockListScroll.ScrollBarThickness = 3
blockListScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 220)
blockListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local blockListLayout = Instance.new("UIListLayout", blockListScroll)
blockListLayout.SortOrder = Enum.SortOrder.LayoutOrder
blockListLayout.Padding = UDim.new(0, 2)

-- Function to update preview and block list
local currentBuildData = nil

local function updatePreviewAndBlockList()
    -- Clear preview
    for _, child in ipairs(previewScroll:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Clear block list
    for _, child in ipairs(blockListScroll:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if not buildFileSelected.value then
        previewInfo.Text = "Select a .build file to see preview"
        previewPartCount.Text = "0 parts"
        return
    end
    
    -- Read file
    local raw = readWorkspaceFile(buildFileSelected.value)
    if not raw or raw == "" then
        previewInfo.Text = "Could not read file!"
        previewPartCount.Text = "Error"
        return
    end
    
    -- Parse build data
    currentBuildData = parseBuildData(raw)
    if not currentBuildData or #currentBuildData == 0 then
        previewInfo.Text = "Invalid build data!"
        previewPartCount.Text = "Error"
        return
    end
    
    -- Update preview info
    previewInfo.Text = "📄 " .. buildFileSelected.name .. " - " .. #currentBuildData .. " parts"
    previewPartCount.Text = #currentBuildData .. " parts"
    
    -- Show first few parts in preview
    local maxPreview = 5
    for i = 1, math.min(#currentBuildData, maxPreview) do
        local partData = currentBuildData[i]
        if type(partData) == "table" then
            local pos = partData.position or partData.Position or {x=0, y=0, z=0}
            local mat = partData.material or partData.Material or "SmoothPlastic"
            
            local partLbl = Instance.new("TextLabel", previewScroll)
            partLbl.Size = UDim2.new(1, 0, 0, 18)
            partLbl.BackgroundTransparency = 1
            partLbl.Text = "  Part " .. i .. ": " .. mat .. " at (" .. (pos.x or pos.X or 0) .. ", " .. (pos.y or pos.Y or 0) .. ", " .. (pos.z or pos.Z or 0) .. ")"
            partLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
            partLbl.Font = Enum.Font.Gotham
            partLbl.TextSize = 10
            partLbl.TextXAlignment = Enum.TextXAlignment.Left
        end
    end
    
    if #currentBuildData > maxPreview then
        local moreLbl = Instance.new("TextLabel", previewScroll)
        moreLbl.Size = UDim2.new(1, 0, 0, 18)
        moreLbl.BackgroundTransparency = 1
        moreLbl.Text = "  ... and " .. (#currentBuildData - maxPreview) .. " more parts"
        moreLbl.TextColor3 = Color3.fromRGB(100, 80, 140)
        moreLbl.Font = Enum.Font.Gotham
        moreLbl.TextSize = 10
        moreLbl.TextXAlignment = Enum.TextXAlignment.Left
    end
    
    -- Analyze blocks
    local requiredBlocks = analyzeBuildBlocks(currentBuildData)
    local missingBlocks = findMissingBlocks(requiredBlocks)
    
    -- Show required blocks
    for _, block in ipairs(requiredBlocks) do
        local isMissing = false
        for _, missing in ipairs(missingBlocks) do
            if missing.name == block.name then
                isMissing = true
                break
            end
        end
        
        local blockFrame = Instance.new("Frame", blockListScroll)
        blockFrame.Size = UDim2.new(1, 0, 0, 22)
        blockFrame.BackgroundColor3 = isMissing and Color3.fromRGB(60, 20, 30) or Color3.fromRGB(25, 20, 40)
        blockFrame.BorderSizePixel = 0
        
        local bfCorner = Instance.new("UICorner", blockFrame)
        bfCorner.CornerRadius = UDim.new(0, 4)
        
        local blockLbl = Instance.new("TextLabel", blockFrame)
        blockLbl.Size = UDim2.new(1, -50, 1, 0)
        blockLbl.Position = UDim2.new(0, 5, 0, 0)
        blockLbl.BackgroundTransparency = 1
        blockLbl.Text = (isMissing and "🔴" or "🟢") .. " " .. block.name .. " (x" .. block.count .. ")"
        blockLbl.TextColor3 = isMissing and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(180, 220, 180)
        blockLbl.Font = Enum.Font.Gotham
        blockLbl.TextSize = 10
        blockLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local countLbl = Instance.new("TextLabel", blockFrame)
        countLbl.Size = UDim2.new(0, 40, 1, 0)
        countLbl.Position = UDim2.new(1, -45, 0, 0)
        countLbl.BackgroundTransparency = 1
        countLbl.Text = block.count
        countLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
        countLbl.Font = Enum.Font.GothamBold
        countLbl.TextSize = 10
    end
    
    -- Show missing blocks warning
    if #missingBlocks > 0 then
        local warnLbl = Instance.new("TextLabel", blockListScroll)
        warnLbl.Size = UDim2.new(1, 0, 0, 20)
        warnLbl.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
        warnLbl.Text = "⚠️ Missing " .. #missingBlocks .. " block(s)! Purchase to load build."
        warnLbl.TextColor3 = Color3.fromRGB(255, 150, 100)
        warnLbl.Font = Enum.Font.GothamBold
        warnLbl.TextSize = 10
        
        local warnCorner = Instance.new("UICorner", warnLbl)
        warnCorner.CornerRadius = UDim.new(0, 4)
    end
end

-- Update preview when file selection changes
task.spawn(function()
    while true do
        task.wait(0.3)
        if buildFileSelected and buildFileSelected.value then
            updatePreviewAndBlockList()
            task.wait(2) -- Don't update too frequently
        end
    end
end)

-- Updated Y position for build controls after block list
local finalBuildControlsY = blockListY + 130

createLabel(p1, "⚙️ Build Speed (studs/sec):", finalBuildControlsY, 16, Color3.fromRGB(160, 120, 220))
local speedInput, _ = createInput(p1, "e.g. 5", buildControlsY + 18, 34)
speedInput.Text = "5"

createLabel(p1, "📍 Build Position Offset (X, Y, Z):", finalBuildControlsY + 60, 16, Color3.fromRGB(160, 120, 220))
local posInput, _ = createInput(p1, "e.g. 0, 5, 0", finalBuildControlsY + 78, 34)
posInput.Text = "0, 5, 0"

local buildBtn = createButton(p1, "🔨 START AUTOBUILD", finalBuildControlsY + 120, Color3.fromRGB(80, 40, 180))
local stopBuildBtn = createButton(p1, "⏹ STOP BUILD", finalBuildControlsY + 166, Color3.fromRGB(160, 40, 80))

-- Inventory check button
local checkInvBtn = createButton(p1, "🎒 CHECK INVENTORY", finalBuildControlsY + 212, Color3.fromRGB(40, 120, 160))

local buildStatus, _ = createStatusBox(p1, finalBuildControlsY + 212)

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
    local parts = {}
    for line in raw:gmatch("[^\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(parts, trimmed)
        end
    end
    return parts
end

buildBtn.MouseButton1Click:Connect(function()
    if buildRunning then
        notify("oxyX AutoBuild", "Build already running! Stop it first.", 3)
        return
    end

    -- Validate file selection
    if not buildFileSelected.value then
        buildStatus.Text = "Status: ❌ No .build file selected!"
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX AutoBuild", "Please select a .build file first!", 3)
        return
    end

    -- Validate extension
    if not buildFileSelected.name:lower():match("%.build$") then
        buildStatus.Text = "Status: ❌ Invalid file! Only .build files allowed."
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX AutoBuild", "Only .build files are supported!", 3)
        return
    end

    buildStatus.Text = "Status: 📂 Reading " .. buildFileSelected.name .. "..."
    buildStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    local raw = readWorkspaceFile(buildFileSelected.value)
    if not raw or raw == "" then
        buildStatus.Text = "Status: ❌ Could not read file: " .. buildFileSelected.name
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX AutoBuild", "Failed to read file! Check executor permissions.", 3)
        return
    end

    local speed = tonumber(speedInput.Text) or 5
    local px, py, pz = posInput.Text:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
    local offset = Vector3.new(tonumber(px) or 0, tonumber(py) or 5, tonumber(pz) or 0)

    local buildData = parseBuildData(raw)
    if not buildData or #buildData == 0 then
        buildStatus.Text = "Status: ❌ Invalid .build data in file!"
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX AutoBuild", "Invalid .build data! File must contain JSON.", 3)
        return
    end
    
    -- DEBUG: Show parsed data count
    buildStatus.Text = "Status: 📊 Parsed " .. #buildData .. " parts..."
    buildStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    task.wait(0.5)

    -- Analyze required blocks
    local requiredBlocks = analyzeBuildBlocks(buildData)
    
    -- DEBUG: Show block analysis
    buildStatus.Text = "Status: 📊 Found " .. #requiredBlocks .. " block types..."
    buildStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    
    -- Check if all blocks are SmoothPlastic (might indicate parsing issue)
    local allSmoothPlastic = true
    for _, block in ipairs(requiredBlocks) do
        if block.name ~= "SmoothPlastic" then
            allSmoothPlastic = false
            break
        end
    end
    if allSmoothPlastic and #requiredBlocks == 1 then
        notify("oxyX Warning", "Only SmoothPlastic detected - file format might be incorrect! Check .build file structure.", 5)
    end
    task.wait(0.5)
    
    local hasRequired = true
    local missingList = {}
    
    -- Fix: requiredBlocks is array {name, count}, not dictionary
    for _, blockInfo in ipairs(requiredBlocks) do
        local blockName = blockInfo.name
        local amount = blockInfo.count
        
        -- DEBUG: Show checking inventory
        buildStatus.Text = "Status: 📊 Checking " .. blockName .. " (" .. amount .. ")..."
        buildStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
        task.wait(0.1)
        
        if not hasBlock(blockName, amount) then
            hasRequired = false
            table.insert(missingList, blockName .. " (" .. amount .. ")")
        end
    end
    
    if not hasRequired then
        buildStatus.Text = "Status: ⚠️ Missing blocks! Build cancelled."
        buildStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
        notify("oxyX Inventory", "Missing: " .. table.concat(missingList, ", "), 5)
        return
    end
    
    buildStatus.Text = "Status: ✅ Inventory OK! Starting build..."
    buildStatus.TextColor3 = Color3.fromRGB(120, 255, 120)

    buildRunning = true
    buildStatus.Text = "Status: 🔨 Building... (0/" .. #buildData .. ") from " .. buildFileSelected.name
    buildStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    notify("oxyX AutoBuild", "Starting build of " .. #buildData .. " parts from " .. buildFileSelected.name, 3)

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

            local partInfo = type(partData) == "table" and partData or {}
            local partPos = partInfo.position or partInfo.Position or {x=0, y=0, z=0}
            local partSize = partInfo.size or partInfo.Size or {x=4, y=1.2, z=4}
            local partColor = partInfo.color or partInfo.Color or {r=163, g=162, b=165}
            local partMat = partInfo.material or partInfo.Material or "SmoothPlastic"
            local partShape = partInfo.shape or partInfo.Shape or "Block"

            pcall(function()
                local remotes = game:GetService("ReplicatedStorage")
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
            
            -- Deduct blocks from inventory after successful build
            local deducted = {}
            local failedDeduct = {}
            -- Fix: requiredBlocks is array {name, count}, not dictionary
            for _, blockInfo in ipairs(requiredBlocks) do
                local blockName = blockInfo.name
                local amount = blockInfo.count
                if useBlock(blockName, amount) then
                    deducted[blockName] = amount
                else
                    table.insert(failedDeduct, blockName)
                end
            end
            
            local deductMsg = ""
            if next(deducted) then
                for blk, amt in pairs(deducted) do
                    deductMsg = deductMsg .. " -" .. amt .. " " .. blk
                end
            end
            
            if #failedDeduct > 0 then
                notify("oxyX Inventory", "Could not deduct: " .. table.concat(failedDeduct, ", "), 4)
            else
                notify("oxyX Inventory", "Blocks deducted:" .. deductMsg, 4)
            end
            
            buildStatus.Text = "Status: ✅ Build Complete! (" .. #buildData .. " parts) — " .. buildFileSelected.name
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

-- Check inventory button
checkInvBtn.MouseButton1Click:Connect(function()
    local inventory = getPlayerBlockInventory()
    local display = getInventoryDisplay()
    notify("oxyX Inventory", display, 4)
    
    -- Also show in status
    if next(inventory) then
        buildStatus.Text = "Status: 🎒 " .. display
        buildStatus.TextColor3 = Color3.fromRGB(100, 200, 255)
    else
        buildStatus.Text = "Status: ⚠️ No inventory found"
        buildStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
    end
end)

-- ============================================================
-- OBJ PARSER (shared)
-- ============================================================
local function parseOBJ(content)
    local vertices = {}
    local faces = {}
    local normals = {}
    local uvs = {}

    for line in content:gmatch("[^\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed:sub(1, 2) == "v " then
            local x, y, z = trimmed:match("v%s+([%-%.%deE+]+)%s+([%-%.%deE+]+)%s+([%-%.%deE+]+)")
            if x then
                table.insert(vertices, {x = tonumber(x), y = tonumber(y), z = tonumber(z)})
            end
        elseif trimmed:sub(1, 3) == "vn " then
            local x, y, z = trimmed:match("vn%s+([%-%.%deE+]+)%s+([%-%.%deE+]+)%s+([%-%.%deE+]+)")
            if x then
                table.insert(normals, {x = tonumber(x), y = tonumber(y), z = tonumber(z)})
            end
        elseif trimmed:sub(1, 3) == "vt " then
            local u, v = trimmed:match("vt%s+([%-%.%deE+]+)%s+([%-%.%deE+]+)")
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

-- ============================================================
-- PAGE 2: OBJ → ROBLOX STUDIO (Roblox Studio OBJ format)
-- ============================================================
-- This tab is for OBJ files exported FROM Roblox Studio or
-- intended to be imported back into Roblox Studio.
-- It generates a Studio script that uses game:GetService("InsertService")
-- or creates Parts with proper CFrame/Size, and also supports
-- converting to .build format for BABFT.
-- ============================================================
local p2 = tabPages[2]

createLabel(p2, "🎮 OBJ → Roblox Studio Import", 0, 18, Color3.fromRGB(160, 120, 220))
createLabel(p2, "Select a .obj file from workspace to convert for Roblox Studio.", 18, 14, Color3.fromRGB(100, 80, 150))

local studioObjSelected, studioDropFrame, studioSelLbl = createFileSelector(
    p2, ".obj", 36,
    "📁 Workspace .obj Files (Roblox Studio):",
    Color3.fromRGB(20, 140, 80)
)

local studioControlsY = 36 + 22 + 34 + 145

createLabel(p2, "📐 Scale Factor:", studioControlsY, 16, Color3.fromRGB(160, 120, 220))
local studioScaleInput, _ = createInput(p2, "e.g. 1.0", studioControlsY + 18, 34)
studioScaleInput.Text = "1.0"

createLabel(p2, "🏷️ Model Name:", studioControlsY + 60, 16, Color3.fromRGB(160, 120, 220))
local studioNameInput, _ = createInput(p2, "e.g. MyModel", studioControlsY + 78, 34)
studioNameInput.Text = "OBJ_Import"

-- Generate Roblox Studio script button
local genStudioBtn = createButton(p2, "🎮 GENERATE ROBLOX STUDIO SCRIPT", studioControlsY + 120, Color3.fromRGB(20, 140, 80))
-- Convert to .build and load into AutoBuild
local studioToBuildBtn = createButton(p2, "🔨 CONVERT → .BUILD (Load to AutoBuild)", studioControlsY + 166, Color3.fromRGB(80, 40, 180))
-- Save .build file to workspace
local studioSaveBuildBtn = createButton(p2, "💾 SAVE AS .BUILD FILE", studioControlsY + 212, Color3.fromRGB(40, 100, 60))

local studioStatus, _ = createStatusBox(p2, studioControlsY + 258)

local lastStudioScript = nil
local lastStudioBuildData = nil
local lastStudioBuildJson = nil

local function objToRobloxStudioScript(vertices, faces, scale, objName)
    scale = scale or 1.0
    objName = objName or "OBJ_Import"
    local lines = {}
    table.insert(lines, "-- oxyX OBJ → Roblox Studio Import Script")
    table.insert(lines, "-- Generated by oxyX BABFT Suite v2.1 | Powered by oxyX Market")
    table.insert(lines, "-- Paste this into Roblox Studio Command Bar or a Script")
    table.insert(lines, "-- Source: Roblox Studio OBJ format")
    table.insert(lines, "")
    table.insert(lines, 'local model = Instance.new("Model")')
    table.insert(lines, 'model.Name = "' .. objName .. '"')
    table.insert(lines, 'model.Parent = workspace')
    table.insert(lines, "")

    local partCount = 0
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
            table.insert(lines, '  p.Name = "' .. objName .. '_Face_' .. i .. '"')
            table.insert(lines, "  p.Size = Vector3.new(" .. string.format("%.4f", sx) .. ", " .. string.format("%.4f", sy) .. ", " .. string.format("%.4f", sz) .. ")")
            table.insert(lines, "  p.CFrame = CFrame.new(" .. string.format("%.4f", cx) .. ", " .. string.format("%.4f", cy) .. ", " .. string.format("%.4f", cz) .. ")")
            table.insert(lines, "  p.Anchored = true")
            table.insert(lines, "  p.CanCollide = true")
            table.insert(lines, "  p.Material = Enum.Material.SmoothPlastic")
            table.insert(lines, "  p.BrickColor = BrickColor.new('Medium stone grey')")
            table.insert(lines, "  p.Parent = model")
            table.insert(lines, "end")
            partCount = partCount + 1
        end
    end

    table.insert(lines, "")
    table.insert(lines, "-- Set PrimaryPart")
    table.insert(lines, 'local primary = model:FindFirstChildWhichIsA("Part")')
    table.insert(lines, 'if primary then model.PrimaryPart = primary end')
    table.insert(lines, "")
    table.insert(lines, 'print("oxyX Studio: Imported ' .. partCount .. ' parts from OBJ [' .. objName .. ']")')

    return table.concat(lines, "\n"), partCount
end

genStudioBtn.MouseButton1Click:Connect(function()
    if not studioObjSelected.value then
        studioStatus.Text = "Status: ❌ No .obj file selected!"
        studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ Studio", "Please select a .obj file first!", 3)
        return
    end

    if not studioObjSelected.name:lower():match("%.obj$") then
        studioStatus.Text = "Status: ❌ Only .obj files are accepted!"
        studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ Studio", "Only .obj format is supported!", 3)
        return
    end

    studioStatus.Text = "Status: 📂 Reading " .. studioObjSelected.name .. "..."
    studioStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    task.spawn(function()
        local raw = readWorkspaceFile(studioObjSelected.value)
        if not raw or raw == "" then
            studioStatus.Text = "Status: ❌ Could not read file!"
            studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            notify("oxyX OBJ Studio", "Failed to read file!", 3)
            return
        end

        local ok, err = pcall(function()
            local scale = tonumber(studioScaleInput.Text) or 1.0
            local modelName = studioNameInput.Text ~= "" and studioNameInput.Text or "OBJ_Import"
            local verts, faces, normals, uvs = parseOBJ(raw)

            if #verts == 0 then
                studioStatus.Text = "Status: ❌ No vertices found in OBJ!"
                studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                notify("oxyX OBJ Studio", "No vertices found! Check your .obj file.", 3)
                return
            end

            local script, partCount = objToRobloxStudioScript(verts, faces, scale, modelName)
            lastStudioScript = script

            pcall(function() setclipboard(script) end)

            studioStatus.Text = "Status: ✅ Studio script generated!\n" .. #verts .. " verts, " .. #faces .. " faces → " .. partCount .. " parts\nCopied to clipboard!"
            studioStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ Studio", "Studio script copied! Paste in Studio Command Bar.", 5)
        end)
        if not ok then
            studioStatus.Text = "Status: ❌ Error: " .. tostring(err)
            studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

studioToBuildBtn.MouseButton1Click:Connect(function()
    if not studioObjSelected.value then
        studioStatus.Text = "Status: ❌ No .obj file selected!"
        studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ Studio", "Please select a .obj file first!", 3)
        return
    end

    if not studioObjSelected.name:lower():match("%.obj$") then
        studioStatus.Text = "Status: ❌ Only .obj files are accepted!"
        studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end

    studioStatus.Text = "Status: 🔄 Converting OBJ → .build..."
    studioStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    task.spawn(function()
        local raw = readWorkspaceFile(studioObjSelected.value)
        if not raw or raw == "" then
            studioStatus.Text = "Status: ❌ Could not read file!"
            studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end

        local ok, err = pcall(function()
            local scale = tonumber(studioScaleInput.Text) or 1.0
            local verts, faces, normals, uvs = parseOBJ(raw)

            if #verts == 0 then
                studioStatus.Text = "Status: ❌ No vertices found!"
                studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                return
            end

            local buildParts = objToBuildFormat(verts, faces, scale)
            lastStudioBuildData = buildParts
            lastStudioBuildJson = HttpService:JSONEncode(buildParts)

            studioStatus.Text = "Status: ✅ Converted! " .. #buildParts .. " parts → loaded into AutoBuild tab!"
            studioStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ Studio", "Converted! Switch to AutoBuild tab and select the .build file.", 4)
        end)
        if not ok then
            studioStatus.Text = "Status: ❌ Error: " .. tostring(err)
            studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

studioSaveBuildBtn.MouseButton1Click:Connect(function()
    if not lastStudioBuildJson then
        studioStatus.Text = "Status: ❌ Convert OBJ first before saving!"
        studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ Studio", "Convert OBJ to .build first!", 3)
        return
    end

    local baseName = studioObjSelected.name and studioObjSelected.name:gsub("%.obj$", "") or "studio_import"
    local saveName = baseName .. ".build"

    local ok, err = pcall(function()
        if writefile then
            writefile(saveName, lastStudioBuildJson)
            studioStatus.Text = "Status: ✅ Saved as " .. saveName .. " in workspace!"
            studioStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ Studio", "Saved as " .. saveName .. "! Select it in AutoBuild tab.", 4)
        else
            error("writefile not available")
        end
    end)
    if not ok then
        studioStatus.Text = "Status: ❌ Cannot save file: " .. tostring(err)
        studioStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ Studio", "Cannot save file. Executor may not support writefile.", 4)
    end
end)

-- ============================================================
-- PAGE 3: OBJ → EXTERNAL (Sketchfab / standard .obj only)
-- ============================================================
-- This tab is ONLY for standard .obj files from external sources
-- like Sketchfab, Blender, etc. Only .obj format accepted.
-- ============================================================
local p3 = tabPages[3]

createLabel(p3, "📦 OBJ → External (Sketchfab / Blender)", 0, 18, Color3.fromRGB(160, 120, 220))
createLabel(p3, "Only standard .obj format accepted (Sketchfab, Blender, etc.)", 18, 14, Color3.fromRGB(100, 80, 150))

local extObjSelected, extDropFrame, extSelLbl = createFileSelector(
    p3, ".obj", 36,
    "📁 Workspace .obj Files (External/Sketchfab):",
    Color3.fromRGB(40, 120, 200)
)

local extControlsY = 36 + 22 + 34 + 145

createLabel(p3, "📐 Scale Factor:", extControlsY, 16, Color3.fromRGB(160, 120, 220))
local extScaleInput, _ = createInput(p3, "e.g. 1.0", extControlsY + 18, 34)
extScaleInput.Text = "1.0"

-- Convert OBJ → .build format
local extConvertBtn = createButton(p3, "🔄 CONVERT OBJ → .BUILD FORMAT", extControlsY + 60, Color3.fromRGB(40, 120, 200))
-- Save .build to workspace
local extSaveBuildBtn = createButton(p3, "💾 SAVE AS .BUILD FILE", extControlsY + 106, Color3.fromRGB(40, 100, 60))
-- Build in BABFT directly
local extBuildNowBtn = createButton(p3, "🔨 BUILD IN BABFT NOW", extControlsY + 152, Color3.fromRGB(80, 40, 180))

local extStatus, _ = createStatusBox(p3, extControlsY + 198)

local lastExtBuildJson = nil
local lastExtBuildData = nil
local lastExtObjName = nil

extConvertBtn.MouseButton1Click:Connect(function()
    if not extObjSelected.value then
        extStatus.Text = "Status: ❌ No .obj file selected!"
        extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ External", "Please select a .obj file first!", 3)
        return
    end

    -- Strict: only .obj allowed
    if not extObjSelected.name:lower():match("%.obj$") then
        extStatus.Text = "Status: ❌ Only .obj format is accepted!\nThis tab does not support other formats."
        extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ External", "Only .obj format is supported here!", 3)
        return
    end

    extStatus.Text = "Status: 📂 Reading " .. extObjSelected.name .. "..."
    extStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    task.spawn(function()
        local raw = readWorkspaceFile(extObjSelected.value)
        if not raw or raw == "" then
            extStatus.Text = "Status: ❌ Could not read file!"
            extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            notify("oxyX OBJ External", "Failed to read file!", 3)
            return
        end

        local ok, err = pcall(function()
            local scale = tonumber(extScaleInput.Text) or 1.0
            local verts, faces, normals, uvs = parseOBJ(raw)

            if #verts == 0 then
                extStatus.Text = "Status: ❌ No vertices found in OBJ!\nMake sure this is a valid .obj file."
                extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                notify("oxyX OBJ External", "No vertices found! Check your .obj file.", 3)
                return
            end

            local buildParts = objToBuildFormat(verts, faces, scale)
            lastExtBuildData = buildParts
            lastExtBuildJson = HttpService:JSONEncode(buildParts)
            lastExtObjName = extObjSelected.name:gsub("%.obj$", "")

            pcall(function() setclipboard(lastExtBuildJson) end)

            extStatus.Text = "Status: ✅ Converted!\n" .. #verts .. " verts, " .. #faces .. " faces → " .. #buildParts .. " parts\n.build data copied to clipboard!"
            extStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ External", "Converted! " .. #buildParts .. " parts. .build copied to clipboard!", 4)
        end)
        if not ok then
            extStatus.Text = "Status: ❌ Error: " .. tostring(err)
            extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

extSaveBuildBtn.MouseButton1Click:Connect(function()
    if not lastExtBuildJson then
        extStatus.Text = "Status: ❌ Convert OBJ first before saving!"
        extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ External", "Convert OBJ to .build first!", 3)
        return
    end

    local saveName = (lastExtObjName or "ext_import") .. ".build"

    local ok, err = pcall(function()
        if writefile then
            writefile(saveName, lastExtBuildJson)
            extStatus.Text = "Status: ✅ Saved as " .. saveName .. " in workspace!\nSelect it in AutoBuild tab."
            extStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ External", "Saved as " .. saveName .. "! Select it in AutoBuild tab.", 4)
        else
            error("writefile not available")
        end
    end)
    if not ok then
        extStatus.Text = "Status: ❌ Cannot save: " .. tostring(err)
        extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ External", "Cannot save file. Executor may not support writefile.", 4)
    end
end)

extBuildNowBtn.MouseButton1Click:Connect(function()
    if not extObjSelected.value then
        extStatus.Text = "Status: ❌ No .obj file selected!"
        extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX OBJ External", "Please select a .obj file first!", 3)
        return
    end

    if not extObjSelected.name:lower():match("%.obj$") then
        extStatus.Text = "Status: ❌ Only .obj format is accepted!"
        extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end

    extStatus.Text = "Status: 🔄 Converting OBJ → .build for BABFT..."
    extStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

    task.spawn(function()
        local raw = readWorkspaceFile(extObjSelected.value)
        if not raw or raw == "" then
            extStatus.Text = "Status: ❌ Could not read file!"
            extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end

        local ok, err = pcall(function()
            local scale = tonumber(extScaleInput.Text) or 1.0
            local verts, faces, normals, uvs = parseOBJ(raw)

            if #verts == 0 then
                extStatus.Text = "Status: ❌ No vertices found!"
                extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                return
            end

            local buildParts = objToBuildFormat(verts, faces, scale)
            lastExtBuildData = buildParts
            lastExtBuildJson = HttpService:JSONEncode(buildParts)
            lastExtObjName = extObjSelected.name:gsub("%.obj$", "")

            -- Save to workspace so AutoBuild can pick it up
            local saveName = (lastExtObjName or "ext_import") .. ".build"
            local saved = false
            pcall(function()
                if writefile then
                    writefile(saveName, lastExtBuildJson)
                    saved = true
                end
            end)

            extStatus.Text = "Status: ✅ " .. #buildParts .. " parts ready!\n" .. (saved and ("Saved as " .. saveName .. " → switch to AutoBuild tab!") or "Switch to AutoBuild tab and use clipboard data.")
            extStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ External", "OBJ converted! " .. (saved and ("Saved as " .. saveName .. ". ") or "") .. "Switch to AutoBuild tab.", 4)
            switchTab(1)
        end)
        if not ok then
            extStatus.Text = "Status: ❌ Error: " .. tostring(err)
            extStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

-- ============================================================
-- PAGE 4: IMAGE LOADER
-- ============================================================
local p4 = tabPages[4]

createLabel(p4, "🖼️ Discord Image URL:", 0, 18, Color3.fromRGB(160, 120, 220))
createLabel(p4, "Only Discord CDN links supported (cdn.discordapp.com / media.discordapp.net)", 18, 16, Color3.fromRGB(120, 100, 160))

local imgInput, _ = createInput(p4, "https://cdn.discordapp.com/attachments/...", 38, 34)

createLabel(p4, "📐 Display Size (Width x Height in studs):", 80, 16, Color3.fromRGB(160, 120, 220))
local imgSizeInput, _ = createInput(p4, "e.g. 10, 10", 100, 34)
imgSizeInput.Text = "10, 10"

createLabel(p4, "📍 Position Offset (X, Y, Z):", 142, 16, Color3.fromRGB(160, 120, 220))
local imgPosInput, _ = createInput(p4, "e.g. 0, 5, 0", 162, 34)
imgPosInput.Text = "0, 5, 0"

local loadImgBtn = createButton(p4, "🖼️ LOAD IMAGE IN GAME", 204, Color3.fromRGB(40, 100, 180))
local previewImgBtn = createButton(p4, "👁️ PREVIEW IMAGE (GUI)", 250, Color3.fromRGB(80, 60, 160))
local removeImgBtn = createButton(p4, "🗑️ REMOVE LOADED IMAGE", 296, Color3.fromRGB(140, 40, 60))

local imgStatus, _ = createStatusBox(p4, 342)

-- ============================================================
-- IMAGE LOADER LOGIC
-- ============================================================
local loadedImagePart = nil
local previewGui = nil

local function isDiscordUrl(url)
    return url:find("cdn%.discordapp%.com") or url:find("media%.discordapp%.net")
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

            if loadedImagePart and loadedImagePart.Parent then
                loadedImagePart:Destroy()
            end

            local part = Instance.new("Part")
            part.Name = "oxyX_ImagePart"
            part.Size = Vector3.new(width, height, 0.1)
            part.CFrame = CFrame.new(hrp.Position + offset)
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
-- PAGE 5: INFO
-- ============================================================
local p5 = tabPages[5]

local infoLines = {
    {"⚡ oxyX BABFT Suite v2.1", Color3.fromRGB(200, 150, 255), 16},
    {"Powered by oxyX Market", Color3.fromRGB(120, 80, 180), 12},
    {"", Color3.fromRGB(255,255,255), 8},
    {"🔨 AutoBuild", Color3.fromRGB(160, 120, 220), 13},
    {"  • Select .build files from executor workspace", Color3.fromRGB(160, 160, 200), 11},
    {"  • Only .build format accepted (e.g. ocd.build)", Color3.fromRGB(160, 160, 200), 11},
    {"  • Supports position, size, color, material (JSON)", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"🎮 OBJ Studio (Tab 2)", Color3.fromRGB(160, 120, 220), 13},
    {"  • For OBJ files from/for Roblox Studio", Color3.fromRGB(160, 160, 200), 11},
    {"  • Select .obj from workspace", Color3.fromRGB(160, 160, 200), 11},
    {"  • Generates Roblox Studio import script", Color3.fromRGB(160, 160, 200), 11},
    {"  • Can save result as .build file", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"📦 OBJ External (Tab 3)", Color3.fromRGB(160, 120, 220), 13},
    {"  • For .obj files from Sketchfab, Blender, etc.", Color3.fromRGB(160, 160, 200), 11},
    {"  • ONLY .obj format accepted (no other formats)", Color3.fromRGB(160, 160, 200), 11},
    {"  • Select .obj from workspace", Color3.fromRGB(160, 160, 200), 11},
    {"  • Convert to .build and save to workspace", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"🖼️ Image Loader", Color3.fromRGB(160, 120, 220), 13},
    {"  • Only Discord CDN links supported", Color3.fromRGB(160, 160, 200), 11},
    {"  • cdn.discordapp.com / media.discordapp.net", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"🖥️ Executor Support", Color3.fromRGB(160, 120, 220), 13},
    {"  • Xeno / Velocity / Fluxus", Color3.fromRGB(160, 160, 200), 11},
    {"  • Requires: readfile, writefile, listfiles", Color3.fromRGB(160, 160, 200), 11},
    {"", Color3.fromRGB(255,255,255), 8},
    {"Detected: " .. executor, Color3.fromRGB(120, 200, 120), 11},
}

local yOff = 0
for _, info in ipairs(infoLines) do
    local lbl = Instance.new("TextLabel", p5)
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
    Size = UDim2.new(0, 560, 0, 520),
    Position = UDim2.new(0.5, -280, 0.5, -260)
}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ============================================================
-- INITIALIZE FIRST TAB
-- ============================================================
switchTab(1)

-- ============================================================
-- STARTUP NOTIFICATION
-- ============================================================
task.delay(0.6, function()
    notify("oxyX BABFT Suite v2.1", "Loaded! Executor: " .. executor, 4)
end)

-- ============================================================
-- END OF SCRIPT
-- ============================================================
-- oxyX BABFT Suite v2.1
-- Powered by oxyX Market
-- Compatible: Xeno / Velocity / Fluxus
-- New in v2.0:
--   • AutoBuild: File selector for .build files (workspace)
--   • OBJ Studio tab: .obj → Roblox Studio script + .build
--   • OBJ External tab: Sketchfab/.obj only → .build
--   • All OBJ tabs: select file from workspace
