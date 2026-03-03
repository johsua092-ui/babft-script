--[[
██████╗ ██╗  ██╗██╗   ██╗██╗  ██╗
██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝╚██╗██╔╝
██║   ██║ ╚███╔╝  ╚████╔╝  ╚███╔╝ 
██║   ██║ ██╔██╗   ╚██╔╝   ██╔██╗ 
╚██████╔╝██╔╝ ██╗   ██║   ██╔╝ ██╗
 ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
 oxyX BABFT Suite v2.5 (Fixed) | Powered by oxyX Market
 Compatible: Xeno / Velocity / Fluxus / Synapse / etc
]]

-- ============================================================
-- EXECUTOR DETECTION
-- ============================================================
local executor = "unknown"
local rawExecutor = "unknown"
if identifyexecutor then
    rawExecutor = identifyexecutor()
    executor = string.lower(rawExecutor)
elseif syn then
    executor = "synapse"
    rawExecutor = "Synapse X"
elseif getexecutorname then
    rawExecutor = getexecutorname()
    executor = string.lower(rawExecutor)
end

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

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Try multiple GUI parents with better detection
local guiParent = nil
local guiSource = "unknown"

-- Method 1: Try CoreGui
local success, CoreGui = pcall(game.GetService, game, "CoreGui")
if success and CoreGui then
    local testGui = Instance.new("ScreenGui")
    testGui.Name = "oxyX_Test_" .. os.time()
    local testOk = pcall(function()
        testGui.Parent = CoreGui
    end)
    if testOk and testGui.Parent then
        guiParent = CoreGui
        guiSource = "CoreGui"
        testGui:Destroy()
    end
end

-- Method 2: Try PlayerGui
if not guiParent then
    local playerGui = player:WaitForChild("PlayerGui", 5)
    if playerGui then
        local testGui = Instance.new("ScreenGui")
        testGui.Name = "oxyX_Test_" .. os.time()
        local testOk = pcall(function()
            testGui.Parent = playerGui
        end)
        if testOk and testGui.Parent then
            guiParent = playerGui
            guiSource = "PlayerGui"
            testGui:Destroy()
        end
    end
end

-- Method 3: Try StarterGui (some executors)
if not guiParent then
    local testGui = Instance.new("ScreenGui")
    testGui.Name = "oxyX_Test_" .. os.time()
    local testOk = pcall(function()
        testGui.Parent = StarterGui
    end)
    if testOk and testGui.Parent then
        guiParent = StarterGui
        guiSource = "StarterGui"
        testGui:Destroy()
    end
end

-- Ultimate fallback: create a ScreenGui and attach to player
if not guiParent then
    warn("[oxyX] Using fallback GUI method")
    local fallbackGui = Instance.new("ScreenGui")
    fallbackGui.Name = "oxyX_Fallback_" .. os.time()
    pcall(function()
        fallbackGui.Parent = player:WaitForChild("PlayerGui", 10)
    end)
    if fallbackGui.Parent then
        guiParent = fallbackGui.Parent
        guiSource = "PlayerGui (fallback)"
    else
        -- Just set to playerGui directly
        guiParent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        guiSource = "PlayerGui (direct)"
    end
end

print("[oxyX] GUI Parent: " .. guiSource)

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function tween(obj, props, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, direction)
    local tweenObj = TweenService:Create(obj, info, props)
    tweenObj:Play()
    return tweenObj
end

local function notify(title, msg, duration)
    duration = duration or 3
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "oxyX_Notif_" .. tostring(os.time())
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try multiple parents
    local parentSuccess, parentErr = pcall(function()
        notifGui.Parent = guiParent
    end)
    if not parentSuccess or not notifGui.Parent then
        notifGui.Parent = player.PlayerGui
    end

    local frame = Instance.new("Frame", notifGui)
    frame.Size = UDim2.new(0, 320, 0, 80)
    frame.Position = UDim2.new(1, -340, 1, -100)
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
    msgLbl.Size = UDim2.new(1, -10, 0, 40)
    msgLbl.Position = UDim2.new(0, 10, 0, 28)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = msg
    msgLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 11
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextWrapped = true

    -- Animate in
    frame.Position = UDim2.new(1, 20, 1, -100)
    local enterTween = tween(frame, {Position = UDim2.new(1, -340, 1, -100)}, 0.4)
    
    task.delay(duration, function()
        local exitTween = tween(frame, {Position = UDim2.new(1, 20, 1, -100)}, 0.4)
        exitTween.Completed:Wait()
        task.delay(0.1, function()
            pcall(function() notifGui:Destroy() end)
        end)
    end)
end

-- ============================================================
-- BABFT INVENTORY INTEGRATION
-- ============================================================
local function getPlayerBlockInventory()
    local inventory = {}
    
    -- Method 1: leaderstats (most common in BABFT)
    pcall(function()
        if player:FindFirstChild("leaderstats") then
            local leaderstats = player.leaderstats
            for _, child in ipairs(leaderstats:GetChildren()) do
                if child:IsA("IntValue") or child:IsA("NumberValue") then
                    local name = child.Name
                    -- Skip common non-block stats
                    if name ~= "Cash" and name ~= "Kills" and name ~= "Gold" and name ~= "Score" then
                        inventory[name] = child.Value
                    end
                end
            end
        end
    end)
    
    -- Method 2: Direct player children
    pcall(function()
        for _, child in ipairs(player:GetChildren()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                local name = child.Name
                if name ~= "leaderstats" and name ~= "Backpack" and name ~= "Character" then
                    inventory[name] = child.Value
                end
            end
        end
    end)
    
    -- Method 3: Check for "Blocks" folder directly
    pcall(function()
        local blocksFolder = player:FindFirstChild("Blocks") 
            or player:FindFirstChild("Inventory") 
            or player:FindFirstChild("BlockInventory")
            or player:FindFirstChild("MyBlocks")
            or player:FindFirstChild("PlayerBlocks")
        
        if blocksFolder and blocksFolder:IsA("Folder") then
            for _, block in ipairs(blocksFolder:GetChildren()) do
                if block:IsA("IntValue") or block:IsA("NumberValue") then
                    inventory[block.Name] = block.Value
                end
            end
        end
    end)
    
    -- Method 4: Try ReplicatedStorage PlayerData
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local playerData = rs:FindFirstChild("PlayerData") 
            or rs:FindFirstChild("Inventories")
            or rs:FindFirstChild("DataStore")
        
        if playerData then
            local thisPlayer = playerData:FindFirstChild(tostring(player.UserId))
                or playerData:FindFirstChild(player.Name)
            
            if thisPlayer then
                local blocks = thisPlayer:FindFirstChild("Blocks")
                    or thisPlayer:FindFirstChild("Inventory")
                    or thisPlayer:FindFirstChild("OwnedBlocks")
                
                if blocks then
                    for _, block in ipairs(blocks:GetChildren()) do
                        if block:IsA("IntValue") or block:IsA("NumberValue") then
                            inventory[block.Name] = block.Value
                        elseif block:IsA("StringValue") then
                            local val = tonumber(block.Value)
                            if val then inventory[block.Name] = val end
                        end
                    end
                end
            end
        end
    end)
    
    -- Debug: Print what we found
    local count = 0
    for k, v in pairs(inventory) do
        count = count + 1
    end
    
    return inventory
end

local function hasBlock(blockName, amount)
    amount = amount or 1
    local inventory = getPlayerBlockInventory()
    local available = inventory[blockName] or 0
    return available >= amount
end

-- ============================================================
-- BABFT BLOCK LIBRARY
-- ============================================================
local blockLibrary = {
    {name = "Smooth Plastic", aliases = {"SmoothPlastic", "Smooth", "Plastic", "smoothplastic", "smooth", "plastic"}},
    {name = "Wood", aliases = {"Wood", "wood", "wooden"}},
    {name = "Wood Plank", aliases = {"WoodPlank", "Wood Plank", "Plank", "woodplank", "plank"}},
    {name = "Metal", aliases = {"Metal", "metal", "metallic", "iron", "steel"}},
    {name = "Concrete", aliases = {"Concrete", "concrete", "slate", "Slate", "stone", "Stone"}},
    {name = "Brick", aliases = {"Brick", "brick", "bricks"}},
    {name = "Ice", aliases = {"Ice", "ice", "frozen"}},
    {name = "Neon", aliases = {"Neon", "neon", "glow"}},
    {name = "Gold", aliases = {"Gold", "gold", "DiamondPlate", "diamondplate", "golden"}},
    {name = "Grass", aliases = {"Grass", "grass", "lawn"}},
    {name = "Sand", aliases = {"Sand", "sand", "beach"}},
    {name = "Stone", aliases = {"Stone", "stone", "Cobblestone", "cobblestone", "rocks"}},
    {name = "Marble", aliases = {"Marble", "marble"}},
    {name = "Granite", aliases = {"Granite", "granite"}},
    {name = "Obsidian", aliases = {"Obsidian", "obsidian", "dark"}},
    {name = "Cinderblock", aliases = {"Cinderblock", "cinderblock", "Cinder Block", "cinder"}},
    {name = "Corrosion", aliases = {"Corrosion", "corrosion", "rusted", "rust"}},
    {name = "Diamond Plate", aliases = {"DiamondPlate", "Diamond Plate", "diamondplate"}},
    {name = "Foil", aliases = {"Foil", "foil", "aluminum", "silver"}},
    {name = "Pearl", aliases = {"Pearl", "pearl", "pearly"}},
    {name = "Plaster", aliases = {"Plaster", "plaster", "drywall"}},
    {name = "Neon Pink", aliases = {"Neon Pink", "NeonPink", "pink", "Pink", "neonpink"}},
    {name = "Neon Green", aliases = {"Neon Green", "NeonGreen", "green", "Green", "neongreen"}},
    {name = "Neon Blue", aliases = {"Neon Blue", "NeonBlue", "blue", "Blue", "neonblue"}},
    {name = "Neon Red", aliases = {"Neon Red", "NeonRed", "red", "Red", "neonred"}},
    {name = "Neon Orange", aliases = {"Neon Orange", "NeonOrange", "orange", "Orange", "neonorange"}},
    {name = "Neon Purple", aliases = {"Neon Purple", "NeonPurple", "purple", "Purple", "neonpurple"}},
    {name = "Brown", aliases = {"Brown", "brown", "tan", "Tan", "woodbrown"}},
    {name = "Tan", aliases = {"Tan", "tan", "beige"}},
    {name = "Light Stone", aliases = {"Light Stone", "LightStone", "lightstone", "lightgray"}},
    {name = "Dark Stone", aliases = {"Dark Stone", "DarkStone", "darkstone", "darkgray"}},
    {name = "Red", aliases = {"Red", "red", "redcolor"}},
    {name = "Blue", aliases = {"Blue", "blue", "bluecolor"}},
    {name = "Yellow", aliases = {"Yellow", "yellow", "yellowcolor"}},
    {name = "Green", aliases = {"Green", "green", "greencolor"}},
    {name = "White", aliases = {"White", "white", "whitecolor"}},
    {name = "Black", aliases = {"Black", "black", "blackcolor"}},
    {name = "Gray", aliases = {"Gray", "gray", "Grey", "grey", "graycolor"}},
    {name = "Light Gray", aliases = {"Light Gray", "LightGray", "lightgray", "LightGrey", "lightgrey"}},
    {name = "Dark Gray", aliases = {"Dark Gray", "DarkGray", "darkgray", "DarkGrey", "darkgrey"}},
}

-- Normalize block name
local function normalizeBlockName(rawName)
    if not rawName then return "Smooth Plastic" end
    
    local lowerName = string.lower(tostring(rawName))
    
    for _, block in ipairs(blockLibrary) do
        if string.lower(block.name) == lowerName then
            return block.name
        end
        if block.aliases then
            for _, alias in ipairs(block.aliases) do
                if alias:lower() == lowerName then
                    return block.name
                end
            end
        end
    end
    
    -- If not found, try to make a reasonable guess
    -- Capitalize first letter
    return rawName:sub(1,1):upper() .. rawName:sub(2):lower()
end

-- ============================================================
-- BUILD FILE PARSING
-- ============================================================
local function parseBuildData(raw)
    if not raw or raw == "" then return {} end
    
    -- Try JSON first
    local ok, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    
    if ok and type(data) == "table" then
        -- Check if it's an array of parts
        if #data > 0 then
            return data
        end
    end
    
    -- Try alternative formats
    local parts = {}
    
    -- Format: {Block = "Wood", Position = {x=0,y=0,z=0}, ...}
    -- or: [{"Block":"Wood","Position":{"x":0,"y":0,"z":0}},...]
    
    -- Try to find JSON array pattern
    local jsonMatch = raw:match("%[%.-%]")
    if jsonMatch then
        ok, data = pcall(function()
            return HttpService:JSONDecode(jsonMatch)
        end)
        if ok and type(data) == "table" and #data > 0 then
            return data
        end
    end
    
    return {}
end

local function analyzeBuildBlocks(buildData)
    local blockCounts = {}
    local totalParts = #buildData
    
    for _, partData in ipairs(buildData) do
        if type(partData) == "table" then
            -- Try all possible field names
            local rawBlock = nil
            local fields = {"Block", "b", "BLOCK", "Material", "mat", "TYPE", "Type", "type", "Name", "name", "m"}
            
            for _, field in ipairs(fields) do
                if partData[field] ~= nil then
                    rawBlock = tostring(partData[field])
                    break
                end
            end
            
            local blockName = normalizeBlockName(rawBlock)
            blockCounts[blockName] = (blockCounts[blockName] or 0) + 1
        end
    end
    
    -- Convert to sorted array
    local requiredBlocks = {}
    for name, count in pairs(blockCounts) do
        table.insert(requiredBlocks, {name = name, count = count})
    end
    table.sort(requiredBlocks, function(a, b) return a.count > b.count end)
    
    return requiredBlocks
end

-- ============================================================
-- WORKSPACE FILE FUNCTIONS
-- ============================================================
local function listWorkspaceFiles(ext)
    local files = {}
    pcall(function()
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
-- GUI CREATION
-- ============================================================
-- Destroy existing GUI
local existingGui = nil
pcall(function() existingGui = guiParent:FindFirstChild("oxyX_BABFT") end)
if existingGui then pcall(function() existingGui:Destroy() end) end

local existingNotif = nil
pcall(function() existingNotif = guiParent:FindFirstChild("oxyX_Notif") end)
if existingNotif then pcall(function() existingNotif:Destroy() end) end

-- Create ScreenGui with error handling
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "oxyX_BABFT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

-- Try to set parent with error handling
local guiCreated = false
local guiError = nil

-- Try current guiParent
if guiParent then
    guiCreated, guiError = pcall(function()
        ScreenGui.Parent = guiParent
    end)
end

-- If failed, try PlayerGui
if not guiCreated or not ScreenGui.Parent then
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        guiCreated, guiError = pcall(function()
            ScreenGui.Parent = playerGui
        end)
        if guiCreated then
            guiParent = playerGui
            guiSource = "PlayerGui (fallback)"
        end
    end
end

-- If still failed, warn user
if not guiCreated or not ScreenGui.Parent then
    warn("[oxyX] Failed to create GUI: " .. tostring(guiError))
    -- Try one more time with StarterGui
    pcall(function()
        ScreenGui.Parent = StarterGui
    end)
end

-- Verify GUI was created
if not ScreenGui.Parent then
    error("[oxyX] CRITICAL: Could not create GUI! Please report this error.")
end

-- ============================================================
-- MAIN FRAME (Fixed sizing)
-- ============================================================
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 520)  -- Fixed to 520
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local mainCorner = Instance.new("UICorner", MainFrame)
mainCorner.CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Color3.fromRGB(100, 50, 220)
mainStroke.Thickness = 1.5

-- ============================================================
-- TITLE BAR
-- ============================================================
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Color3.fromRGB(14, 8, 30)
TitleBar.BorderSizePixel = 0

local titleBarCorner = Instance.new("UICorner", TitleBar)
titleBarCorner.CornerRadius = UDim.new(0, 14)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ oxyX BABFT Suite v2.5"
TitleLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local SubLabel = Instance.new("TextLabel", TitleBar)
SubLabel.Size = UDim2.new(1, -100, 0, 14)
SubLabel.Position = UDim2.new(0, 14, 1, -16)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "Powered by oxyX Market | " .. rawExecutor
SubLabel.TextColor3 = Color3.fromRGB(120, 80, 180)
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 10
SubLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ============================================================
-- CLOSE BUTTON
-- ============================================================
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

CloseBtn.MouseButton1Click:Connect(function()
    tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
    task.delay(0.35, function()
        pcall(function() ScreenGui:Destroy() end)
    end)
end)

CloseBtn.MouseEnter:Connect(function()
    tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220, 50, 80)}, 0.15)
end)
CloseBtn.MouseLeave:Connect(function()
    tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(180, 30, 60)}, 0.15)
end)

-- ============================================================
-- DRAGGABLE
-- ============================================================
local dragging, dragInput, dragStart, startPos
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
-- CONTENT AREA
-- ============================================================
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -20, 1, -60)
ContentFrame.Position = UDim2.new(0, 10, 0, 52)
ContentFrame.BackgroundTransparency = 1

-- ============================================================
-- STATUS BAR
-- ============================================================
local StatusBar = Instance.new("TextLabel", MainFrame)
StatusBar.Size = UDim2.new(1, 0, 0, 20)
StatusBar.Position = UDim2.new(0, 0, 1, -20)
StatusBar.BackgroundColor3 = Color3.fromRGB(12, 8, 20)
StatusBar.BorderSizePixel = 0
StatusBar.Text = "⌨️ RightShift to toggle | Loaded: " .. rawExecutor
StatusBar.TextColor3 = Color3.fromRGB(120, 100, 160)
StatusBar.Font = Enum.Font.Gotham
StatusBar.TextSize = 10

local statusCorner = Instance.new("UICorner", StatusBar)
statusCorner.CornerRadius = UDim.new(0, 0)

-- ============================================================
-- CREATE INPUT FIELD
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

    return box, bg
end

-- ============================================================
-- CREATE BUTTON
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

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(
            math.min(color.R * 255 + 20, 255),
            math.min(color.G * 255 + 20, 255),
            math.min(color.B * 255 + 20, 255)
        )}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = color}, 0.15)
    end)

    return btn
end

-- ============================================================
-- CREATE LABEL
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
-- FILE SELECTOR
-- ============================================================
local function createFileSelector(parent, ext, posY, labelText)
    local selectedPath = {value = nil, name = nil}
    
    local sectionLbl = Instance.new("TextLabel", parent)
    sectionLbl.Size = UDim2.new(1, 0, 0, 18)
    sectionLbl.Position = UDim2.new(0, 0, 0, posY)
    sectionLbl.BackgroundTransparency = 1
    sectionLbl.Text = labelText
    sectionLbl.TextColor3 = Color3.fromRGB(160, 120, 220)
    sectionLbl.Font = Enum.Font.GothamBold
    sectionLbl.TextSize = 12
    sectionLbl.TextXAlignment = Enum.TextXAlignment.Left

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
    selLbl.Text = "📁 Click to select " .. ext .. " file"
    selLbl.TextColor3 = Color3.fromRGB(100, 80, 140)
    selLbl.Font = Enum.Font.Gotham
    selLbl.TextSize = 11
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd

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

    -- File list dropdown
    local dropFrame = Instance.new("Frame", parent)
    dropFrame.Size = UDim2.new(1, 0, 0, 0)
    dropFrame.Position = UDim2.new(0, 0, 0, posY + 60)
    dropFrame.BackgroundColor3 = Color3.fromRGB(16, 12, 30)
    dropFrame.BorderSizePixel = 0
    dropFrame.ClipsDescendants = true
    dropFrame.Visible = false

    local dropCorner = Instance.new("UICorner", dropFrame)
    dropCorner.CornerRadius = UDim.new(0, 8)

    local dropScroll = Instance.new("ScrollingFrame", dropFrame)
    dropScroll.Size = UDim2.new(1, -4, 1, 0)
    dropScroll.Position = UDim2.new(0, 2, 0, 0)
    dropScroll.BackgroundTransparency = 1
    dropScroll.ScrollBarThickness = 3
    dropScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 220)
    dropScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local dropLayout = Instance.new("UIListLayout", dropScroll)
    dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dropLayout.Padding = UDim.new(0, 2)

    local dropOpen = false

    local function populateDropdown()
        for _, child in ipairs(dropScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        local fileList = listWorkspaceFiles(ext)
        
        if #fileList == 0 then
            local noFileLbl = Instance.new("TextButton", dropScroll)
            noFileLbl.Size = UDim2.new(1, 0, 0, 30)
            noFileLbl.BackgroundTransparency = 1
            noFileLbl.Text = "  ⚠️ No " .. ext .. " files found"
            noFileLbl.TextColor3 = Color3.fromRGB(200, 150, 80)
            noFileLbl.Font = Enum.Font.Gotham
            noFileLbl.TextSize = 11
            noFileLbl.TextXAlignment = Enum.TextXAlignment.Left
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
                    
                    dropOpen = false
                    tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    task.delay(0.25, function()
                        dropFrame.Visible = false
                    end)
                end)
            end
        end
    end

    selBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dropOpen = not dropOpen
            if dropOpen then
                populateDropdown()
                dropFrame.Visible = true
                local fileList = listWorkspaceFiles(ext)
                local targetH = math.min(#fileList * 34 + 8, 140)
                if #fileList == 0 then targetH = 38 end
                tween(dropFrame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
                tween(selStroke, {Color = Color3.fromRGB(140, 80, 255)}, 0.2)
            else
                tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                task.delay(0.25, function() dropFrame.Visible = false end)
                tween(selStroke, {Color = Color3.fromRGB(70, 40, 130)}, 0.2)
            end
        end
    end)

    refreshBtn.MouseButton1Click:Connect(function()
        populateDropdown()
        if not dropOpen then
            dropOpen = true
            dropFrame.Visible = true
            local fileList = listWorkspaceFiles(ext)
            local targetH = math.min(#fileList * 34 + 8, 140)
            tween(dropFrame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
        end
        notify("oxyX", "Refreshed " .. ext .. " file list!", 2)
    end)

    return selectedPath, dropFrame
end

-- ============================================================
-- MAIN CONTENT
-- ============================================================
createLabel(ContentFrame, "📂 Select a .build file from workspace:", 0, 18, Color3.fromRGB(160, 120, 220))

-- File selector
local buildFileSelected, buildDropFrame = createFileSelector(
    ContentFrame, ".build", 22,
    "📁 Workspace .build Files:"
)

local buildControlsY = 22 + 22 + 34 + 145

-- Upload Section
createLabel(ContentFrame, "📤 Or upload build data:", buildControlsY, 16, Color3.fromRGB(160, 120, 220))
local uploadInput, uploadBg = createInput(ContentFrame, "Paste JSON build data here...", buildControlsY + 20, 60)
uploadInput.TextXAlignment = Enum.TextXAlignment.Top
uploadInput.TextWrapped = true
uploadInput.ClearTextOnFocus = false

local uploadBtn = createButton(ContentFrame, "💾 Save as .build file", buildControlsY + 88, Color3.fromRGB(80, 60, 140))

local buildDataY = buildControlsY + 134

-- Speed controls
createLabel(ContentFrame, "⚙️ Build Speed (parts/sec):", buildDataY, 16, Color3.fromRGB(160, 120, 220))
local speedInput, _ = createInput(ContentFrame, "e.g. 5", buildDataY + 18, 34)
speedInput.Text = "10"

createLabel(ContentFrame, "📍 Position Offset (X, Y, Z):", buildDataY + 56, 16, Color3.fromRGB(160, 120, 220))
local posInput, _ = createInput(ContentFrame, "e.g. 0, 5, 0", buildDataY + 74, 34)
posInput.Text = "0, 5, 0"

-- Skip inventory check
local skipInvCheck = false
local skipInvBtn = Instance.new("TextButton", ContentFrame)
skipInvBtn.Size = UDim2.new(1, 0, 0, 30)
skipInvBtn.Position = UDim2.new(0, 0, 0, buildDataY + 112)
skipInvBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
skipInvBtn.Text = "✓ Skip Inventory Check (FORCE BUILD)"
skipInvBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
skipInvBtn.Font = Enum.Font.GothamBold
skipInvBtn.TextSize = 11
skipInvBtn.BorderSizePixel = 0
skipInvBtn.AutoButtonColor = false

local skipCorner = Instance.new("UICorner", skipInvBtn)
skipCorner.CornerRadius = UDim.new(0, 6)

skipInvBtn.MouseButton1Click:Connect(function()
    skipInvCheck = not skipInvCheck
    if skipInvCheck then
        skipInvBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        skipInvBtn.Text = "✗ SKIP INVENTORY CHECK ENABLED"
        skipInvBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
    else
        skipInvBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        skipInvBtn.Text = "✓ Skip Inventory Check (FORCE BUILD)"
        skipInvBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
    end
end)

-- Build buttons
local buildBtn = createButton(ContentFrame, "🔨 START BUILD", buildDataY + 156, Color3.fromRGB(80, 40, 180))
local stopBuildBtn = createButton(ContentFrame, "⏹ STOP BUILD", buildDataY + 202, Color3.fromRGB(160, 40, 80))
local checkInvBtn = createButton(ContentFrame, "🎒 CHECK INVENTORY", buildDataY + 248, Color3.fromRGB(40, 120, 160))

local buildStatus = Instance.new("TextLabel", ContentFrame)
buildStatus.Size = UDim2.new(1, 0, 0, 40)
buildStatus.Position = UDim2.new(0, 0, 0, buildDataY + 294)
buildStatus.BackgroundColor3 = Color3.fromRGB(12, 8, 25)
buildStatus.BorderSizePixel = 0
buildStatus.Text = "Status: Ready"
buildStatus.TextColor3 = Color3.fromRGB(120, 200, 120)
buildStatus.Font = Enum.Font.Gotham
buildStatus.TextSize = 11
buildStatus.TextWrapped = true
buildStatus.TextXAlignment = Enum.TextXAlignment.Left

local statusCorner = Instance.new("UICorner", buildStatus)
statusCorner.CornerRadius = UDim.new(0, 8)

local statusStroke = Instance.new("UIStroke", buildStatus)
statusStroke.Color = Color3.fromRGB(50, 30, 90)
statusStroke.Thickness = 1

-- ============================================================
-- UPLOAD BUTTON LOGIC
-- ============================================================
uploadBtn.MouseButton1Click:Connect(function()
    local content = uploadInput.Text
    if not content or content == "" or content == "Paste JSON build data here..." then
        notify("oxyX BABFT", "Please paste build data first!", 3)
        return
    end
    
    local fileName = "uploaded_" .. os.time() .. ".build"
    
    if writeWorkspaceFile(fileName, content) then
        notify("oxyX BABFT", "File saved: " .. fileName, 3)
        uploadInput.Text = ""
        -- Refresh file list
        task.delay(0.5, function()
            if buildDropFrame.Visible then
                -- Trigger refresh somehow
            end
        end)
    else
        notify("oxyX BABFT", "Failed to save file!", 3)
    end
end)

-- ============================================================
-- BUILD LOGIC
-- ============================================================
local buildRunning = false
local buildThread = nil

buildBtn.MouseButton1Click:Connect(function()
    if buildRunning then
        notify("oxyX AutoBuild", "Build already running!", 3)
        return
    end

    if not buildFileSelected.value then
        buildStatus.Text = "Status: ❌ No .build file selected!"
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX AutoBuild", "Please select a .build file first!", 3)
        return
    end

    local raw = readWorkspaceFile(buildFileSelected.value)
    if not raw or raw == "" then
        buildStatus.Text = "Status: ❌ Could not read file!"
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end

    local speed = tonumber(speedInput.Text) or 10
    local px, py, pz = posInput.Text:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
    local offset = Vector3.new(tonumber(px) or 0, tonumber(py) or 5, tonumber(pz) or 0)

    local buildData = parseBuildData(raw)
    if not buildData or #buildData == 0 then
        buildStatus.Text = "Status: ❌ Invalid build data!"
        buildStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX AutoBuild", "Invalid .build data!", 3)
        return
    end

    -- Analyze blocks
    local requiredBlocks = analyzeBuildBlocks(buildData)
    
    local blockInfo = ""
    for i, block in ipairs(requiredBlocks) do
        if i <= 3 then
            blockInfo = blockInfo .. block.name .. "=" .. block.count .. " "
        end
    end
    notify("oxyX", "Building: " .. #buildData .. " parts", 3)

    -- Check inventory
    if not skipInvCheck then
        local inventory = getPlayerBlockInventory()
        local invCount = 0
        for k, v in pairs(inventory) do invCount = invCount + 1 end
        
        if invCount == 0 then
            notify("oxyX Warning", "Could not detect inventory! Enable Skip Inventory Check if needed.", 4)
        end
    end

    buildRunning = true
    buildStatus.Text = "Status: 🔨 Building " .. #buildData .. " parts..."
    buildStatus.TextColor3 = Color3.fromRGB(120, 200, 255)

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

            pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local placeRemote = rs:FindFirstChild("PlacePart")
                    or rs:FindFirstChild("BuildPart")
                    or rs:FindFirstChild("Place")

                if placeRemote and placeRemote:IsA("RemoteEvent") then
                    local partInfo = type(partData) == "table" and partData or {}
                    local partPos = partInfo.Position or partInfo.position or {x=0, y=0, z=0}
                    local partSize = partInfo.Size or partInfo.size or {x=4, y=1.2, z=4}
                    local partColor = partInfo.Color or partInfo.color or {r=163, g=162, b=165}
                    local partMat = partInfo.Material or partInfo.Block or "SmoothPlastic"

                    local pos = Vector3.new(
                        basePos.X + (partPos.x or partPos.X or 0),
                        basePos.Y + (partPos.y or partPos.Y or 0),
                        basePos.Z + (partPos.z or partPos.Z or 0)
                    )
                    local size = Vector3.new(
                        partSize.x or partSize.X or 4,
                        partSize.y or partSize.Y or 1.2,
                        partSize.z or partSize.Z or 4
                    )
                    local color = Color3.fromRGB(
                        partColor.r or partColor.R or 163,
                        partColor.g or partColor.G or 162,
                        partColor.b or partColor.B or 165
                    )
                    
                    placeRemote:FireServer(pos, size, color, tostring(partMat), "Block")
                end
            end)

            buildStatus.Text = "Status: 🔨 Building... (" .. i .. "/" .. #buildData .. ")"
            
            local delay = 1 / math.max(speed, 1)
            task.wait(delay)
        end

        if buildRunning then
            buildRunning = false
            buildStatus.Text = "Status: ✅ Build Complete! (" .. #buildData .. " parts)"
            buildStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX AutoBuild", "Build complete!", 4)
        end
    end)
end)

stopBuildBtn.MouseButton1Click:Connect(function()
    if buildRunning then
        buildRunning = false
        if buildThread then task.cancel(buildThread) end
        buildStatus.Text = "Status: ⏹ Build stopped."
        buildStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
    end
end)

checkInvBtn.MouseButton1Click:Connect(function()
    local inventory = getPlayerBlockInventory()
    local count = 0
    local sample = ""
    for k, v in pairs(inventory) do
        count = count + 1
        if count <= 5 then
            sample = sample .. k .. "=" .. v .. " "
        end
    end
    
    if count > 0 then
        buildStatus.Text = "Status: 🎒 " .. count .. " block types: " .. sample
        buildStatus.TextColor3 = Color3.fromRGB(100, 200, 255)
        notify("oxyX Inventory", count .. " block types found", 3)
    else
        buildStatus.Text = "Status: ⚠️ No inventory found"
        buildStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
        notify("oxyX Inventory", "Could not detect inventory!", 3)
    end
end)

-- ============================================================
-- KEYBINDS
-- ============================================================
local function setupKeybinds()
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.LeftShift then
            if ScreenGui.Parent then
                pcall(function() ScreenGui:Destroy() end)
            end
        end
    end)
end
setupKeybinds()

-- ============================================================
-- CHAT COMMANDS
-- ============================================================
pcall(function()
    player.Chatted:Connect(function(msg)
        if msg:lower() == "/oxyx" or msg:lower() == "/babft" then
            if ScreenGui.Parent then
                pcall(function() ScreenGui:Destroy() end)
            end
        end
    end)
end)

-- ============================================================
-- FORCE SHOW GUI (Critical fix)
-- ============================================================
task.delay(0.1, function()
    -- Force show GUI immediately
    pcall(function()
        ScreenGui.Enabled = true
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 560, 0, 520)
        MainFrame.Position = UDim2.new(0.5, -280, 0.5, -260)
    end)
    notify("oxyX BABFT v2.5", "Loaded! Executor: " .. rawExecutor, 4)
end)

-- ============================================================
-- END
-- ============================================================
-- oxyX BABFT Suite v2.5 (Fixed)
-- Powered by oxyX Market
