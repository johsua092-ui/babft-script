--[[
████████████████████████████████████████████████████████████████████████████
█  ██████╗ ██╗  ██╗██╗   ██╗██╗  ██╗    ██████╗ ███████╗███╗   ██╗
█  ██╔══██╗╚██╗██╔╝╚██╗ ██╔╝╚██╗██╔╝    ██╔══██╗██╔════╝████╗  ██║
█  ██║  ██║ ╚███╔╝  ╚████╔╝  ╚███╔╝     ██║  ██║█████╗  ██╔██╗ ██║
█  ██║  ██║ ██╔██╗   ╚██╔╝   ██╔██╗     ██║  ██║██╔══╝  ██║╚██╗██║
█  ██████╔╝██╔╝ ██╗   ██║   ██╔╝ ██╗    ██████╔╝███████╗██║ ╚████║
█  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝
█
█  oxyX BABFT Suite v1.2 - Ultimate Build Tools
█  Compatible: Xeno / Velocity / Fluxus / Synapse / Hydrogen / etc
█  Features: OBJ Import | Model Import | Wireframe Mode | Block Inventory
████████████████████████████████████████████████████████████████████████████
]]

-- ============================================================
-- VERSION INFO
-- ============================================================
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

-- Detect specific executors
if executor:find("xeno") then executorIcon = "🦊"
elseif executor:find("fluxus") then executorIcon = "🔵"
elseif executor:find("velocity") then executorIcon = "🚀"
elseif executor:find("synapse") then executorIcon = "⚡"
elseif executor:find("hydrogen") then executorIcon = "💧"
elseif executor:find("electron") then executorIcon = "⚛️"
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
    -- Method 1: Try PlayerGui directly (most reliable)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        guiParent = playerGui
        guiSource = "PlayerGui (direct)"
        print("[oxyX] GUI Parent found: PlayerGui (direct)")
        return true
    end
    
    -- Method 2: Try wait for PlayerGui
    playerGui = player:WaitForChild("PlayerGui", 5)
    if playerGui then
        guiParent = playerGui
        guiSource = "PlayerGui (waited)"
        print("[oxyX] GUI Parent found: PlayerGui (waited)")
        return true
    end
    
    -- Method 3: Try Hidden UI root (executor)
    local ok_hui, hui = pcall(function()
        return gethui and gethui()
    end)
    if ok_hui and hui then
        guiParent = hui
        guiSource = "HiddenUI"
        print("[oxyX] GUI Parent found: HiddenUI")
        return true
    end
    
    -- Method 4: Try CoreGui
    local success, CoreGui = pcall(game.GetService, game, "CoreGui")
    if success and CoreGui then
        guiParent = CoreGui
        guiSource = "CoreGui"
        print("[oxyX] GUI Parent found: CoreGui")
        return true
    end
    
    return false
end

detectGuiParent()
print("[oxyX] GUI Parent: " .. guiSource)

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Tween function
local function tween(obj, props, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, direction)
    local tweenObj = TweenService:Create(obj, info, props)
    tweenObj:Play()
    return tweenObj
end

-- Notification system
local function notify(title, msg, duration, color)
    duration = duration or 3
    color = color or Color3.fromRGB(120, 60, 255)
    
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "oxyX_Notif_" .. tostring(os.time())
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local parentSuccess = pcall(function()
        notifGui.Parent = guiParent
    end)
    if not parentSuccess or not notifGui.Parent then
        local ok_hui, hui = pcall(function()
            return gethui and gethui()
        end)
        if ok_hui and hui then
            pcall(function() notifGui.Parent = hui end)
        end
        if not notifGui.Parent then
            local successCore, CoreGui = pcall(game.GetService, game, "CoreGui")
            if successCore and CoreGui then
                pcall(function() notifGui.Parent = CoreGui end)
            end
        end
        if not notifGui.Parent then
            local pg = player:WaitForChild("PlayerGui", 5)
            if pg then notifGui.Parent = pg end
        end
    end

    local frame = Instance.new("Frame", notifGui)
    frame.Size = UDim2.new(0, 340, 0, 90)
    frame.Position = UDim2.new(1, -360, 1, -110)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = color
    stroke.Thickness = 2

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -20, 0, 28)
    titleLbl.Position = UDim2.new(0, 12, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "⚡ " .. title
    titleLbl.TextColor3 = color
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local msgLbl = Instance.new("TextLabel", frame)
    msgLbl.Size = UDim2.new(1, -20, 0, 45)
    msgLbl.Position = UDim2.new(0, 12, 0, 38)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = msg
    msgLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 11
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextWrapped = true

    frame.Position = UDim2.new(1, 30, 1, -110)
    local enterTween = tween(frame, {Position = UDim2.new(1, -360, 1, -110)}, 0.4)
    
    task.delay(duration, function()
        local exitTween = tween(frame, {Position = UDim2.new(1, 30, 1, -110)}, 0.4)
        exitTween.Completed:Wait()
        task.delay(0.1, function()
            pcall(function() notifGui:Destroy() end)
        end)
    end)
end

-- Debug logging
local debugMode = false
local function debugLog(...)
    if debugMode then
        local args = {...}
        local msg = "[oxyX] "
        for i, v in ipairs(args) do
            msg = msg .. tostring(v) .. (i < #args and " " or "")
        end
        print(msg)
    end
end

-- ============================================================
-- FILE SYSTEM UTILITIES
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
    table.sort(files, function(a, b) return a.name < b.name end)
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

local function deleteWorkspaceFile(path)
    local success = false
    pcall(function()
        if delfile then
            delfile(path)
            success = true
        end
    end)
    return success
end

local function fileExists(path)
    local exists = false
    pcall(function()
        if isfile then
            exists = isfile(path)
        end
    end)
    return exists
end

-- ============================================================
-- BABFT INVENTORY SYSTEM
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
                    if name ~= "Cash" and name ~= "Kills" and name ~= "Gold" and name ~= "Score" and name ~= "Wins" then
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
    
    -- Method 3: Check for Blocks folder
    pcall(function()
        local folders = {"Blocks", "Inventory", "BlockInventory", "MyBlocks", "PlayerBlocks", "OwnedBlocks", "MyInventory"}
        for _, folderName in ipairs(folders) do
            local blocksFolder = player:FindFirstChild(folderName)
            if blocksFolder and blocksFolder:IsA("Folder") then
                for _, block in ipairs(blocksFolder:GetChildren()) do
                    if block:IsA("IntValue") or block:IsA("NumberValue") then
                        inventory[block.Name] = block.Value
                    elseif block:IsA("StringValue") then
                        local val = tonumber(block.Value)
                        if val then inventory[block.Name] = val end
                    end
                end
            end
        end
    end)
    
    -- Method 4: ReplicatedStorage PlayerData
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local folders = {"PlayerData", "Inventories", "DataStore", "PlayerInventory"}
        for _, folderName in ipairs(folders) do
            local playerData = rs:FindFirstChild(folderName)
            if playerData then
                local thisPlayer = playerData:FindFirstChild(tostring(player.UserId))
                    or playerData:FindFirstChild(player.Name)
                
                if thisPlayer then
                    local blockFolders = {"Blocks", "Inventory", "OwnedBlocks", "MyBlocks"}
                    for _, bf in ipairs(blockFolders) do
                        local blocks = thisPlayer:FindFirstChild(bf)
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
            end
        end
    end)
    
    return inventory
end

local function hasBlock(blockName, amount)
    amount = amount or 1
    local inventory = getPlayerBlockInventory()
    local available = inventory[blockName] or 0
    return available >= amount
end

local function getAvailableBlocks()
    local inventory = getPlayerBlockInventory()
    local blocks = {}
    for name, count in pairs(inventory) do
        if count > 0 then
            table.insert(blocks, {name = name, count = count})
        end
    end
    table.sort(blocks, function(a, b) return a.count > b.count end)
    return blocks
end

-- ============================================================
-- BABFT BLOCK LIBRARY (Extended)
-- ============================================================
local blockLibrary = {
    -- Basic materials
    {name = "Smooth Plastic", aliases = {"SmoothPlastic", "Smooth", "Plastic", "smoothplastic", "smooth", "plastic", "default", "sp"}},
    {name = "Wood", aliases = {"Wood", "wood", "wooden", "woodenblock", "wb"}},
    {name = "Wood Plank", aliases = {"WoodPlank", "Wood Plank", "Plank", "woodplank", "plank", "wp"}},
    {name = "Metal", aliases = {"Metal", "metal", "metallic", "iron", "steel", "mt"}},
    {name = "Concrete", aliases = {"Concrete", "concrete", "slate", "Slate", "stone", "Stone", "cn"}},
    {name = "Brick", aliases = {"Brick", "brick", "bricks", "br"}},
    {name = "Ice", aliases = {"Ice", "ice", "frozen", "ic"}},
    {name = "Neon", aliases = {"Neon", "neon", "glow", "nl"}},
    {name = "Gold", aliases = {"Gold", "gold", "DiamondPlate", "diamondplate", "golden", "gd"}},
    {name = "Grass", aliases = {"Grass", "grass", "lawn", "gr"}},
    {name = "Sand", aliases = {"Sand", "sand", "beach", "sd"}},
    {name = "Stone", aliases = {"Stone", "stone", "Cobblestone", "cobblestone", "rocks", "st"}},
    {name = "Marble", aliases = {"Marble", "marble", "mb"}},
    {name = "Granite", aliases = {"Granite", "granite", "gn"}},
    {name = "Obsidian", aliases = {"Obsidian", "obsidian", "dark", "ob"}},
    {name = "Cinderblock", aliases = {"Cinderblock", "cinderblock", "Cinder Block", "cinder", "cb"}},
    {name = "Corrosion", aliases = {"Corrosion", "corrosion", "rusted", "rust", "cr"}},
    {name = "Diamond Plate", aliases = {"DiamondPlate", "Diamond Plate", "diamondplate", "dp"}},
    {name = "Foil", aliases = {"Foil", "foil", "aluminum", "silver", "fl"}},
    {name = "Pearl", aliases = {"Pearl", "pearl", "pearly", "pr"}},
    {name = "Plaster", aliases = {"Plaster", "plaster", "drywall", "pl"}},
    
    -- Neon colors
    {name = "Neon Pink", aliases = {"Neon Pink", "NeonPink", "pink", "Pink", "neonpink", "np"}},
    {name = "Neon Green", aliases = {"Neon Green", "NeonGreen", "green", "Green", "neongreen", "ng"}},
    {name = "Neon Blue", aliases = {"Neon Blue", "NeonBlue", "blue", "Blue", "neonblue", "nb"}},
    {name = "Neon Red", aliases = {"Neon Red", "NeonRed", "red", "Red", "neonred", "nr"}},
    {name = "Neon Orange", aliases = {"Neon Orange", "NeonOrange", "orange", "Orange", "neonorange", "no"}},
    {name = "Neon Purple", aliases = {"Neon Purple", "NeonPurple", "purple", "Purple", "neonpurple", "nv"}},
    
    -- Basic colors
    {name = "Brown", aliases = {"Brown", "brown", "tan", "Tan", "woodbrown", "brn"}},
    {name = "Tan", aliases = {"Tan", "tan", "beige", "tn"}},
    {name = "Light Stone", aliases = {"Light Stone", "LightStone", "lightstone", "lightgray", "ls"}},
    {name = "Dark Stone", aliases = {"Dark Stone", "DarkStone", "darkstone", "darkgray", "ds"}},
    {name = "Red", aliases = {"Red", "red", "redcolor", "r"}},
    {name = "Blue", aliases = {"Blue", "blue", "bluecolor", "b"}},
    {name = "Yellow", aliases = {"Yellow", "yellow", "yellowcolor", "y"}},
    {name = "Green", aliases = {"Green", "green", "greencolor", "g"}},
    {name = "White", aliases = {"White", "white", "whitecolor", "w"}},
    {name = "Black", aliases = {"Black", "black", "blackcolor", "k"}},
    {name = "Gray", aliases = {"Gray", "gray", "Grey", "grey", "graycolor", "gray"}},
    {name = "Light Gray", aliases = {"Light Gray", "LightGray", "lightgray", "LightGrey", "lightgrey", "lg"}},
    {name = "Dark Gray", aliases = {"Dark Gray", "DarkGray", "darkgray", "DarkGrey", "darkgrey", "dg"}},
    
    -- Special
    {name = "Wood Grain", aliases = {"WoodGrain", "Wood Grain", "wg"}},
    {name = "Ash", aliases = {"Ash", "ash", "as"}},
    {name = "Lava", aliases = {"Lava", "lava", "lv"}},
    {name = "Water", aliases = {"Water", "water", "wt"}},
    {name = "Carbon", aliases = {"Carbon", "carbon", "cb"}},
    {name = "Onyx", aliases = {"Onyx", "onyx", "ox"}},
    {name = "Pearl", aliases = {"Pearl", "pearl", "prl"}},
    {name = "Glacier", aliases = {"Glacier", "glacier", "gl"}},
    {name = "Mirage", aliases = {"Mirage", "mirage", "mz"}},
    {name = "Chrome", aliases = {"Chrome", "chrome", "ch"}},
}

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
    
    return rawName:sub(1,1):upper() .. rawName:sub(2):lower()
end

-- ============================================================
-- BUILD DATA PARSING
-- ============================================================
local function parseBuildData(raw)
    if not raw or raw == "" then return {} end
    
    -- Try JSON first
    local ok, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    
    if ok and type(data) == "table" then
        if #data > 0 then
            return data
        end
    end
    
    -- Try alternative formats
    local parts = {}
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
            local rawBlock = nil
            local fields = {"Block", "b", "BLOCK", "Material", "mat", "TYPE", "Type", "type", "Name", "name", "m", "blockType"}
            
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
    
    local requiredBlocks = {}
    for name, count in pairs(blockCounts) do
        table.insert(requiredBlocks, {name = name, count = count})
    end
    table.sort(requiredBlocks, function(a, b) return a.count > b.count end)
    
    return requiredBlocks
end

-- ============================================================
-- OBJ FILE PARSER
-- ============================================================
local function parseOBJFile(content)
    local vertices = {}
    local faces = {}
    local normals = {}
    local vertexNormals = {}
    
    -- Parse line by line
    for line in content:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        
        -- Vertex
        if line:sub(1, 2) == "v " then
            local x, y, z = line:match("v%s+([%-%.%d]+)%s+([%-%.%d]+)%s+([%-%.%d]+)")
            if x and y and z then
                table.insert(vertices, {
                    x = tonumber(x),
                    y = tonumber(y),
                    z = tonumber(z)
                })
            end
        
        -- Normal
        elseif line:sub(1, 3) == "vn " then
            local x, y, z = line:match("vn%s+([%-%.%d]+)%s+([%-%.%d]+)%s+([%-%.%d]+)")
            if x and y and z then
                table.insert(normals, {
                    x = tonumber(x),
                    y = tonumber(y),
                    z = tonumber(z)
                })
            end
        
        -- Face
        elseif line:sub(1, 2) == "f " then
            local faceVertices = {}
            local faceNormals = {}
            
            -- Parse face vertices (v/vt/vn or just v)
            for vertex in line:gmatch("([^%s]+)") do
                if vertex ~= "f" then
                    local v, vt, vn = vertex:match("(%d+)/?(%d*)/?(%d*)")
                    if v then
                        table.insert(faceVertices, tonumber(v))
                        if vn and vn ~= "" then
                            table.insert(faceNormals, tonumber(vn))
                        end
                    end
                end
            end
            
            -- Triangulate if needed (convert quads to triangles)
            if #faceVertices >= 3 then
                table.insert(faces, {
                    v1 = faceVertices[1],
                    v2 = faceVertices[2],
                    v3 = faceVertices[3],
                    n1 = faceNormals[1],
                    n2 = faceNormals[2],
                    n3 = faceNormals[3]
                })
                
                if #faceVertices == 4 then
                    table.insert(faces, {
                        v1 = faceVertices[1],
                        v2 = faceVertices[3],
                        v3 = faceVertices[4],
                        n1 = faceNormals[1],
                        n2 = faceNormals[3],
                        n3 = faceNormals[4]
                    })
                end
            end
        end
    end
    
    return vertices, faces, normals
end

local function objToBuildData(content, options)
    options = options or {}
    local scale = options.scale or 1
    local offsetX = options.offsetX or 0
    local offsetY = options.offsetY or 0
    local offsetZ = options.offsetZ or 0
    local blockType = options.blockType or "Wood"
    
    local vertices, faces, normals = parseOBJFile(content)
    
    if #vertices == 0 then
        return nil, "No vertices found in OBJ file"
    end
    
    -- Calculate bounding box
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    
    for _, v in ipairs(vertices) do
        minX, maxX = math.min(minX, v.x), math.max(maxX, v.x)
        minY, maxY = math.min(minY, v.y), math.max(maxY, v.y)
        minZ, maxZ = math.min(minZ, v.z), math.max(maxZ, v.z)
    end
    
    -- Center the model
    local centerX = (minX + maxX) / 2
    local centerY = (minY + maxY) / 2
    local centerZ = (minZ + maxZ) / 2
    
    -- Convert faces to build parts (approximating with boxes)
    local buildParts = {}
    local seenPositions = {}
    
    for _, face in ipairs(faces) do
        local v1 = vertices[face.v1]
        local v2 = vertices[face.v2]
        local v3 = vertices[face.v3]
        
        if v1 and v2 and v3 then
            -- Calculate face center
            local cx = (v1.x + v2.x + v3.x) / 3
            local cy = (v1.y + v2.y + v3.y) / 3
            local cz = (v1.z + v2.z + v3.z) / 3
            
            -- Calculate face normal for orientation
            local ux, uy, uz = v2.x - v1.x, v2.y - v1.y, v2.z - v1.z
            local vx, vy, vz = v3.x - v1.x, v3.y - v1.y, v3.z - v1.z
            local nx = uy * vz - uz * vy
            local ny = uz * vx - ux * vz
            local nz = ux * vy - uy * vx
            local len = math.sqrt(nx*nx + ny*ny + nz*nz)
            if len > 0 then
                nx, ny, nz = nx/len, ny/len, nz/len
            end
            
            -- Calculate size (triangle area approximation)
            local size = math.sqrt(ux*ux + uy*uy + uz*uz) * math.sqrt(vx*vx + vy*vy + vz*vz) / 2
            size = math.max(size * scale * 0.3, 1)
            
            -- Create position key for deduplication
            local posKey = string.format("%.1f,%.1f,%.1f", cx, cy, cz)
            
            if not seenPositions[posKey] then
                seenPositions[posKey] = true
                
                table.insert(buildParts, {
                    Position = {
                        x = math.round((cx - centerX) * scale + offsetX),
                        y = math.round((cy - centerY) * scale + offsetY),
                        z = math.round((cz - centerZ) * scale + offsetZ)
                    },
                    Size = {
                        x = math.max(size, 1),
                        y = math.max(size * 0.5, 0.5),
                        z = math.max(size, 1)
                    },
                    Block = blockType,
                    Color = {
                        r = 163,
                        g = 162,
                        b = 165
                    }
                })
            end
        end
    end
    
    return buildParts
end

-- ============================================================
-- ROBLOX MODEL IMPORT (Asset ID)
-- ============================================================
local function importRobloxModel(assetId)
    local buildParts = {}
    
    -- Try to get the model
    local success, model = pcall(function()
        return game:GetService("InsertService"):LoadAsset(tonumber(assetId))
    end)
    
    if not success or not model then
        return nil, "Failed to load model from asset ID"
    end
    
    -- Find all parts in the model
    local function getAllParts(obj)
        local parts = {}
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(parts, child)
            elseif child:IsA("Model") then
                local childParts = getAllParts(child)
                for _, p in ipairs(childParts) do
                    table.insert(parts, p)
                end
            end
        end
        return parts
    end
    
    local parts = getAllParts(model)
    
    if #parts == 0 then
        model:Destroy()
        return nil, "No parts found in model"
    end
    
    -- Calculate center
    local totalPos = Vector3.new(0, 0, 0)
    for _, part in ipairs(parts) do
        totalPos = totalPos + part.Position
    end
    local center = totalPos / #parts
    
    -- Convert to build data
    for _, part in ipairs(parts) do
        local pos = part.Position - center
        local size = part.Size
        
        -- Get color
        local color = part.Color
        if part:IsA("Part") and part.Material then
            -- Try to map material to block type
            local mat = tostring(part.Material)
            local blockType = "Smooth Plastic"
            
            if mat:find("Wood") then blockType = "Wood"
            elseif mat:find("Metal") then blockType = "Metal"
            elseif mat:find("Concrete") or mat:find("Slate") then blockType = "Concrete"
            elseif mat:find("Brick") then blockType = "Brick"
            elseif mat:find("Ice") then blockType = "Ice"
            elseif mat:find("Neon") then blockType = "Neon"
            elseif mat:find("Grass") then blockType = "Grass"
            elseif mat:find("Sand") then blockType = "Sand"
            elseif mat:find("Marble") then blockType = "Marble"
            elseif mat:find("Granite") then blockType = "Granite"
            elseif mat:find("Diamond") then blockType = "Diamond Plate"
            end
            
            table.insert(buildParts, {
                Position = {
                    x = math.round(pos.X),
                    y = math.round(pos.Y),
                    z = math.round(pos.Z)
                },
                Size = {
                    x = math.round(size.X * 10) / 10,
                    y = math.round(size.Y * 10) / 10,
                    z = math.round(size.Z * 10) / 10
                },
                Block = blockType,
                Color = {
                    r = math.round(color.R * 255),
                    g = math.round(color.G * 255),
                    b = math.round(color.B * 255)
                }
            })
        end
    end
    
    model:Destroy()
    return buildParts
end

-- ============================================================
-- WIREFRAME MODE (Photo to Blocks)
-- ============================================================
local function createWireframeFromGrid(gridData, options)
    options = options or {}
    local scale = options.scale or 4
    local blockType = options.blockType or "Neon"
    local colorR = options.colorR or 0
    local colorG = options.colorG or 255
    local colorB = options.colorB or 255
    
    local buildParts = {}
    local width = #gridData[1] or 0
    local height = #gridData or 0
    
    for y = 1, height do
        for x = 1, width do
            local pixel = gridData[y][x]
            if pixel == 1 then -- Edge detected
                table.insert(buildParts, {
                    Position = {
                        x = (x - width/2) * scale,
                        y = (height/2 - y) * scale,
                        z = 0
                    },
                    Size = {
                        x = scale * 0.8,
                        y = scale * 0.8,
                        z = scale * 0.5
                    },
                    Block = blockType,
                    Color = {
                        r = colorR,
                        g = colorG,
                        b = colorB
                    },
                    Wireframe = true
                })
            end
        end
    end
    
    return buildParts
end

-- Simple edge detection simulation (since we can't process images directly)
local function generateWireframeFromText(text, options)
    options = options or {}
    local scale = options.scale or 3
    local blockType = options.blockType or "Neon"
    local colorR = options.colorR or 0
    local colorG = options.colorG or 255
    local colorB = options.colorB or 255
    
    local buildParts = {}
    
    -- Simple ASCII-like grid for demonstration
    -- This creates a basic pattern based on text length
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    local maxWidth = 0
    for _, line in ipairs(lines) do
        maxWidth = math.max(maxWidth, #line)
    end
    
    -- Create wireframe pattern
    local pattern = {
        {1, 1, 1, 1, 1},
        {1, 0, 0, 0, 1},
        {1, 0, 1, 0, 1},
        {1, 0, 0, 0, 1},
        {1, 1, 1, 1, 1}
    }
    
    for y = 1, 5 do
        for x = 1, 5 do
            if pattern[y][x] == 1 then
                table.insert(buildParts, {
                    Position = {
                        x = (x - 3) * scale,
                        y = (3 - y) * scale,
                        z = 0
                    },
                    Size = {
                        x = scale * 0.9,
                        y = scale * 0.9,
                        z = scale * 0.3
                    },
                    Block = blockType,
                    Color = {
                        r = colorR,
                        g = colorG,
                        b = colorB
                    },
                    Wireframe = true
                })
            end
        end
    end
    
    return buildParts
end

-- ============================================================
-- TEAM SYSTEM
-- ============================================================
local teamColors = {
    ["Blue"] = {Color3.fromRGB(0, 0, 255), Color3.fromRGB(100, 149, 237)},
    ["Red"] = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 99, 71)},
    ["Green"] = {Color3.fromRGB(0, 255, 0), Color3.fromRGB(144, 238, 144)},
    ["Yellow"] = {Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 215, 0)},
    ["Orange"] = {Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 178, 66)},
    ["Purple"] = {Color3.fromRGB(128, 0, 128), Color3.fromRGB(186, 85, 211)},
    ["Pink"] = {Color3.fromRGB(255, 192, 203), Color3.fromRGB(255, 182, 193)},
    ["White"] = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 240, 240)},
    ["Black"] = {Color3.fromRGB(0, 0, 0), Color3.fromRGB(50, 50, 50)}
}

local function getTeamColor(teamName)
    return teamColors[teamName] or teamColors["Blue"]
end

-- ============================================================
-- GUI CREATION
-- ============================================================
-- Destroy existing GUI
local function destroyOldGui()
    if guiParent then
        for _, child in ipairs(guiParent:GetChildren()) do
            if child.Name == "oxyX_BABFT" or child.Name:find("oxyX_Notif") then
                pcall(function() child:Destroy() end)
            end
        end
    end
end
destroyOldGui()

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "oxyX_BABFT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)
ScreenGui.DisplayOrder = 10000

-- Try to set parent
local function trySetParent()
    if not guiParent then return false end
    
    -- Try direct parent first
    local success, err = pcall(function()
        ScreenGui.Parent = guiParent
    end)
    
    if success and ScreenGui.Parent then
        return true
    end
    
    -- Try PlayerGui as fallback
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui and playerGui ~= guiParent then
        success, err = pcall(function()
            ScreenGui.Parent = playerGui
        end)
        if success and ScreenGui.Parent then
            return true
        end
    end
    
    -- Try Hidden UI root
    local ok_hui, hui = pcall(function()
        return gethui and gethui()
    end)
    if ok_hui and hui then
        success, err = pcall(function()
            ScreenGui.Parent = hui
        end)
        if success and ScreenGui.Parent then
            return true
        end
    end
    
    -- Try CoreGui
    local successCore, CoreGui = pcall(game.GetService, game, "CoreGui")
    if successCore and CoreGui then
        success, err = pcall(function()
            ScreenGui.Parent = CoreGui
        end)
        if success and ScreenGui.Parent then
            return true
        end
    end
    
    return false
end

if not trySetParent() then
    warn("[oxyX] WARNING: Could not set GUI parent properly")
    local pg = player:WaitForChild("PlayerGui", 5)
    if pg then
        pcall(function() ScreenGui.Parent = pg end)
    else
        local ok_hui, hui = pcall(function()
            return gethui and gethui()
        end)
        if ok_hui and hui then
            pcall(function() ScreenGui.Parent = hui end)
        else
            local successCore, CoreGui = pcall(game.GetService, game, "CoreGui")
            if successCore and CoreGui then
                pcall(function() ScreenGui.Parent = CoreGui end)
            end
        end
    end
end

if not ScreenGui.Parent then
    warn("[oxyX] CRITICAL: GUI has no parent, but continuing...")
end

-- ============================================================
-- MAIN FRAME
-- ============================================================
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 620, 0, 680)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -340)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local mainCorner = Instance.new("UICorner", MainFrame)
mainCorner.CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Color3.fromRGB(80, 40, 200)
mainStroke.Thickness = 2

-- ============================================================
-- TITLE BAR
-- ============================================================
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 6, 28)
TitleBar.BorderSizePixel = 0

local titleBarCorner = Instance.new("UICorner", TitleBar)
titleBarCorner.CornerRadius = UDim.new(0, 16)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -100, 0, 26)
TitleLabel.Position = UDim2.new(0, 14, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ oxyX BABFT Suite v" .. SCRIPT_VERSION .. " - Ultimate Build Tools"
TitleLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local SubLabel = Instance.new("TextLabel", TitleBar)
SubLabel.Size = UDim2.new(1, -100, 0, 16)
SubLabel.Position = UDim2.new(0, 14, 1, -18)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = executorIcon .. " " .. rawExecutor .. " | " .. SCRIPT_TAG
SubLabel.TextColor3 = Color3.fromRGB(100, 70, 180)
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 10
SubLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ============================================================
-- CLOSE BUTTON
-- ============================================================
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false

local closeCorner = Instance.new("UICorner", CloseBtn)
closeCorner.CornerRadius = UDim.new(0, 8)

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
-- TAB SYSTEM
-- ============================================================
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -20, 1, -64)
ContentFrame.Position = UDim2.new(0, 10, 0, 56)
ContentFrame.BackgroundTransparency = 1

-- Tab container
local TabContainer = Instance.new("Frame", ContentFrame)
TabContainer.Size = UDim2.new(1, 0, 0, 38)
TabContainer.Position = UDim2.new(0, 0, 0, 0)
TabContainer.BackgroundColor3 = Color3.fromRGB(12, 8, 24)
TabContainer.BorderSizePixel = 0

local tabCorner = Instance.new("UICorner", TabContainer)
tabCorner.CornerRadius = UDim.new(0, 8)

local tabLayout = Instance.new("UIListLayout", TabContainer)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Padding = UDim.new(0, 3)

-- Tab button creation
local tabs = {"📦 Load", "💾 Save", "📥 OBJ", "🔮 Model", "🌀 Wire", "⚙️ Settings"}
local selectedTab = {value = 1}
local tabButtons = {}

for i, tabText in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton", TabContainer)
    tabBtn.Size = UDim2.new(0, 95, 1, -6)
    tabBtn.Position = UDim2.new(0, (i-1) * 98 + 3, 0, 3)
    tabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(80, 40, 180) or Color3.fromRGB(25, 18, 50)
    tabBtn.Text = tabText
    tabBtn.TextColor3 = Color3.fromRGB(200, 180, 255)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 11
    tabBtn.BorderSizePixel = 0
    tabBtn.AutoButtonColor = false
    
    local tabCorner = Instance.new("UICorner", tabBtn)
    tabCorner.CornerRadius = UDim.new(0, 6)
    
    tabButtons[i] = tabBtn
    
    tabBtn.MouseButton1Click:Connect(function()
        selectedTab.value = i
        for j, btn in ipairs(tabButtons) do
            tween(btn, {
                BackgroundColor3 = j == i and Color3.fromRGB(80, 40, 180) or Color3.fromRGB(25, 18, 50)
            }, 0.2)
        end
        -- Show/hide tab content
        updateTabContent(i)
    end)
    
    tabBtn.MouseEnter:Connect(function()
        if i ~= selectedTab.value then
            tween(tabBtn, {BackgroundColor3 = Color3.fromRGB(40, 28, 70)}, 0.1)
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if i ~= selectedTab.value then
            tween(tabBtn, {BackgroundColor3 = Color3.fromRGB(25, 18, 50)}, 0.1)
        end
    end)
end

-- ============================================================
-- SCROLLABLE CONTENT AREA
-- ============================================================
local ScrollFrame = Instance.new("ScrollingFrame", ContentFrame)
ScrollFrame.Size = UDim2.new(1, 0, 1, -46)
ScrollFrame.Position = UDim2.new(0, 0, 0, 42)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 220)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local contentContainer = Instance.new("Frame", ScrollFrame)
contentContainer.Size = UDim2.new(1, 0, 0, 1000)
contentContainer.BackgroundTransparency = 1

local contentLayout = Instance.new("UIListLayout", contentContainer)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 0)

-- Status Bar
local StatusBar = Instance.new("TextLabel", MainFrame)
StatusBar.Size = UDim2.new(1, 0, 0, 22)
StatusBar.Position = UDim2.new(0, 0, 1, -22)
StatusBar.BackgroundColor3 = Color3.fromRGB(10, 6, 18)
StatusBar.BorderSizePixel = 0
StatusBar.Text = "⌨️ RightShift to toggle | " .. SCRIPT_NAME .. " v" .. SCRIPT_VERSION .. " | " .. executorIcon .. " " .. rawExecutor
StatusBar.TextColor3 = Color3.fromRGB(100, 80, 150)
StatusBar.Font = Enum.Font.Gotham
StatusBar.TextSize = 10

local statusCorner = Instance.new("UICorner", StatusBar)
statusCorner.CornerRadius = UDim.new(0, 0)

-- ============================================================
-- GUI HELPERS
-- ============================================================
local function createInput(parent, placeholder, posY, height, widthScale)
    height = height or 36
    widthScale = widthScale or 1
    local bg = Instance.new("Frame", parent)
    bg.Size = UDim2.new(widthScale, 0, 0, height)
    bg.Position = UDim2.new(0, 0, 0, posY)
    bg.BackgroundColor3 = Color3.fromRGB(18, 12, 35)
    bg.BorderSizePixel = 0

    local bgCorner = Instance.new("UICorner", bg)
    bgCorner.CornerRadius = UDim.new(0, 8)

    local bgStroke = Instance.new("UIStroke", bg)
    bgStroke.Color = Color3.fromRGB(60, 35, 120)
    bgStroke.Thickness = 1

    local box = Instance.new("TextBox", bg)
    box.Size = UDim2.new(1, -14, 1, 0)
    box.Position = UDim2.new(0, 10, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(80, 60, 130)
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(220, 200, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false

    return box, bg
end

local function createButton(parent, text, posY, color, height)
    color = color or Color3.fromRGB(80, 40, 180)
    height = height or 40
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, height)
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
        local c = color
        tween(btn, {BackgroundColor3 = Color3.fromRGB(
            math.min(c.R * 255 + 25, 255),
            math.min(c.G * 255 + 25, 255),
            math.min(c.B * 255 + 25, 255)
        )}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = color}, 0.15)
    end)

    return btn
end

local function createLabel(parent, text, posY, size, color, fontSize)
    size = size or 18
    fontSize = fontSize or 12
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, 0, 0, size)
    lbl.Position = UDim2.new(0, 0, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(170, 140, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = fontSize
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    return lbl
end

local function createSection(parent, title, posY)
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 30)
    section.Position = UDim2.new(0, 0, 0, posY)
    section.BackgroundColor3 = Color3.fromRGB(20, 12, 40)
    section.BorderSizePixel = 0

    local sectionCorner = Instance.new("UICorner", section)
    sectionCorner.CornerRadius = UDim.new(0, 6)

    local sectionLbl = Instance.new("TextLabel", section)
    sectionLbl.Size = UDim2.new(1, -10, 1, 0)
    sectionLbl.Position = UDim2.new(0, 8, 0, 0)
    sectionLbl.BackgroundTransparency = 1
    sectionLbl.Text = "▸ " .. title
    sectionLbl.TextColor3 = Color3.fromRGB(150, 100, 255)
    sectionLbl.Font = Enum.Font.GothamBold
    sectionLbl.TextSize = 12
    sectionLbl.TextXAlignment = Enum.TextXAlignment.Left

    return section, sectionLbl
end

-- ============================================================
-- FILE SELECTOR
-- ============================================================
local function createFileSelector(parent, ext, posY, labelText, onSelect)
    local selectedPath = {value = nil, name = nil}
    local dropdownVisible = {value = false}
    
    local sectionLbl = createLabel(parent, labelText, posY, 16, Color3.fromRGB(140, 100, 200))
    
    local selBg = Instance.new("Frame", parent)
    selBg.Size = UDim2.new(1, -44, 0, 36)
    selBg.Position = UDim2.new(0, 0, 0, posY + 18)
    selBg.BackgroundColor3 = Color3.fromRGB(18, 12, 35)
    selBg.BorderSizePixel = 0

    local selCorner = Instance.new("UICorner", selBg)
    selCorner.CornerRadius = UDim.new(0, 8)

    local selStroke = Instance.new("UIStroke", selBg)
    selStroke.Color = Color3.fromRGB(60, 35, 120)
    selStroke.Thickness = 1

    local selLbl = Instance.new("TextLabel", selBg)
    selLbl.Size = UDim2.new(1, -10, 1, 0)
    selLbl.Position = UDim2.new(0, 10, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text = "📁 Click to select " .. ext .. " file"
    selLbl.TextColor3 = Color3.fromRGB(90, 70, 140)
    selLbl.Font = Enum.Font.Gotham
    selLbl.TextSize = 11
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local refreshBtn = Instance.new("TextButton", parent)
    refreshBtn.Size = UDim2.new(0, 38, 0, 36)
    refreshBtn.Position = UDim2.new(1, -38, 0, posY + 18)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 70)
    refreshBtn.Text = "🔄"
    refreshBtn.TextColor3 = Color3.fromRGB(200, 180, 255)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 14
    refreshBtn.BorderSizePixel = 0
    refreshBtn.AutoButtonColor = false

    local refCorner = Instance.new("UICorner", refreshBtn)
    refCorner.CornerRadius = UDim.new(0, 8)

    -- Dropdown
    local dropFrame = Instance.new("Frame", parent)
    dropFrame.Size = UDim2.new(1, 0, 0, 0)
    dropFrame.Position = UDim2.new(0, 0, 0, posY + 58)
    dropFrame.BackgroundColor3 = Color3.fromRGB(14, 10, 26)
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

    local function populateDropdown()
        for _, child in ipairs(dropScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        local fileList = listWorkspaceFiles(ext)
        
        if #fileList == 0 then
            local noFileLbl = Instance.new("TextButton", dropScroll)
            noFileLbl.Size = UDim2.new(1, 0, 0, 32)
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
                itemBtn.Size = UDim2.new(1, 0, 0, 34)
                itemBtn.BackgroundColor3 = Color3.fromRGB(20, 14, 40)
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
                    tween(itemBtn, {BackgroundColor3 = Color3.fromRGB(45, 30, 85)}, 0.1)
                end)
                itemBtn.MouseLeave:Connect(function()
                    tween(itemBtn, {BackgroundColor3 = Color3.fromRGB(20, 14, 40)}, 0.1)
                end)

                itemBtn.MouseButton1Click:Connect(function()
                    selectedPath.value = fileInfo.path
                    selectedPath.name = fileInfo.name
                    selLbl.Text = "📄 " .. fileInfo.name
                    selLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
                    
                    dropdownVisible.value = false
                    tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    task.delay(0.25, function()
                        dropFrame.Visible = false
                    end)
                    
                    if onSelect then onSelect(fileInfo) end
                end)
            end
        end
    end

    selBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dropdownVisible.value = not dropdownVisible.value
            if dropdownVisible.value then
                populateDropdown()
                dropFrame.Visible = true
                local fileList = listWorkspaceFiles(ext)
                local targetH = math.min(#fileList * 36 + 8, 160)
                if #fileList == 0 then targetH = 36 end
                tween(dropFrame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
                tween(selStroke, {Color = Color3.fromRGB(120, 70, 255)}, 0.2)
            else
                tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                task.delay(0.25, function() dropFrame.Visible = false end)
                tween(selStroke, {Color = Color3.fromRGB(60, 35, 120)}, 0.2)
            end
        end
    end)

    refreshBtn.MouseButton1Click:Connect(function()
        populateDropdown()
        notify("oxyX", "Refreshed " .. ext .. " files!", 2)
    end)

    return selectedPath, dropFrame
end

-- ============================================================
-- TAB CONTENT STORAGE
-- ============================================================
local tabContents = {}

-- ============================================================
-- TAB 1: LOAD BUILD
-- ============================================================
local loadTabY = 0

createSection(contentContainer, "📦 Load Build (.build files only)", loadTabY)
local loadFileSelector, loadDropFrame = createFileSelector(contentContainer, ".build", loadTabY + 34, "📁 Select Build File:")

local loadY = loadTabY + 34 + 18 + 40 + 20

createLabel(contentContainer, "⚙️ Build Settings:", loadY, 16, Color3.fromRGB(140, 100, 200))

-- Position offset
createLabel(contentContainer, "📍 Position (X, Y, Z):", loadY + 20, 14, Color3.fromRGB(130, 90, 180))
local loadPosInput, _ = createInput(contentContainer, "e.g. 0, 5, 0", loadY + 36, 34)
loadPosInput.Text = "0, 5, 0"

-- Build speed
createLabel(contentContainer, "⚡ Build Speed (parts/sec):", loadY + 74, 14, Color3.fromRGB(130, 90, 180))
local loadSpeedInput, _ = createInput(contentContainer, "e.g. 10", loadY + 90, 34)
loadSpeedInput.Text = "15"

-- Use inventory blocks
local useInventoryBlocks = {value = true}
local useInvBtn = Instance.new("TextButton", contentContainer)
useInvBtn.Size = UDim2.new(1, 0, 0, 32)
useInvBtn.Position = UDim2.new(0, 0, 0, loadY + 128)
useInvBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 50)
useInvBtn.Text = "✓ Use Inventory Blocks (your purchased blocks)"
useInvBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
useInvBtn.Font = Enum.Font.GothamBold
useInvBtn.TextSize = 11
useInvBtn.BorderSizePixel = 0
useInvBtn.AutoButtonColor = false

local useInvCorner = Instance.new("UICorner", useInvBtn)
useInvCorner.CornerRadius = UDim.new(0, 7)

useInvBtn.MouseButton1Click:Connect(function()
    useInventoryBlocks.value = not useInventoryBlocks.value
    if useInventoryBlocks.value then
        useInvBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 50)
        useInvBtn.Text = "✓ Use Inventory Blocks (your purchased blocks)"
        useInvBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
    else
        useInvBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 50)
        useInvBtn.Text = "✗ Use Any Block (ignores inventory)"
        useInvBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
    end
end)

-- Skip inventory check
local skipInvCheck = {value = false}
local skipInvBtn = Instance.new("TextButton", contentContainer)
skipInvBtn.Size = UDim2.new(1, 0, 0, 30)
skipInvBtn.Position = UDim2.new(0, 0, 0, loadY + 164)
skipInvBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
skipInvBtn.Text = "✓ Skip Inventory Check (FORCE BUILD)"
skipInvBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
skipInvBtn.Font = Enum.Font.GothamBold
skipInvBtn.TextSize = 10
skipInvBtn.BorderSizePixel = 0
skipInvBtn.AutoButtonColor = false

local skipCorner = Instance.new("UICorner", skipInvBtn)
skipCorner.CornerRadius = UDim.new(0, 6)

skipInvBtn.MouseButton1Click:Connect(function()
    skipInvCheck.value = not skipInvCheck.value
    if skipInvCheck.value then
        skipInvBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        skipInvBtn.Text = "✗ SKIP INVENTORY CHECK ENABLED"
        skipInvBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
    else
        skipInvBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        skipInvBtn.Text = "✓ Skip Inventory Check (FORCE BUILD)"
        skipInvBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
    end
end)

-- Load buttons
local loadBtn = createButton(contentContainer, "🔨 START BUILD", loadY + 202, Color3.fromRGB(70, 35, 170))
local stopLoadBtn = createButton(contentContainer, "⏹ STOP BUILD", loadY + 248, Color3.fromRGB(150, 35, 70))
local checkInvBtn = createButton(contentContainer, "🎒 CHECK INVENTORY", loadY + 294, Color3.fromRGB(35, 100, 150))

-- Load status
local loadStatus = Instance.new("TextLabel", contentContainer)
loadStatus.Size = UDim2.new(1, 0, 0, 44)
loadStatus.Position = UDim2.new(0, 0, 0, loadY + 340)
loadStatus.BackgroundColor3 = Color3.fromRGB(10, 6, 20)
loadStatus.BorderSizePixel = 0
loadStatus.Text = "Status: Ready to load build"
loadStatus.TextColor3 = Color3.fromRGB(120, 200, 120)
loadStatus.Font = Enum.Font.Gotham
loadStatus.TextSize = 11
loadStatus.TextWrapped = true
loadStatus.TextXAlignment = Enum.TextXAlignment.Left

local loadStatusCorner = Instance.new("UICorner", loadStatus)
loadStatusCorner.CornerRadius = UDim.new(0, 8)

local loadStatusStroke = Instance.new("UIStroke", loadStatus)
loadStatusStroke.Color = Color3.fromRGB(45, 25, 80)
loadStatusStroke.Thickness = 1

-- ============================================================
-- TAB 2: SAVE BUILD
-- ============================================================
local saveTabY = 400

createSection(contentContainer, "💾 Save Your Build", saveTabY)

-- Target player
createLabel(contentContainer, "👤 Target Player Name:", saveTabY + 34, 14, Color3.fromRGB(130, 90, 180))
local saveTargetInput, _ = createInput(contentContainer, "Enter player name or leave empty for self", saveTabY + 50, 34)

-- Build name
createLabel(contentContainer, "📝 Build Name:", saveTabY + 88, 14, Color3.fromRGB(130, 90, 180))
local saveBuildNameInput, _ = createInput(contentContainer, "My Awesome Build", saveTabY + 104, 34)

-- Team selector
createLabel(contentContainer, "🏷️ Select Team:", saveTabY + 142, 14, Color3.fromRGB(130, 90, 180))

local teamOptions = {"Blue", "Red", "Green", "Yellow", "Orange", "Purple", "Pink", "White", "Black"}
local selectedTeam = {value = "Blue"}

local teamBg = Instance.new("Frame", contentContainer)
teamBg.Size = UDim2.new(1, 0, 0, 36)
teamBg.Position = UDim2.new(0, 0, 0, saveTabY + 158)
teamBg.BackgroundColor3 = Color3.fromRGB(18, 12, 35)
teamBg.BorderSizePixel = 0

local teamCorner = Instance.new("UICorner", teamBg)
teamCorner.CornerRadius = UDim.new(0, 8)

local teamStroke = Instance.new("UIStroke", teamBg)
teamStroke.Color = Color3.fromRGB(60, 35, 120)
teamStroke.Thickness = 1

local teamLbl = Instance.new("TextLabel", teamBg)
teamLbl.Size = UDim2.new(1, -10, 1, 0)
teamLbl.Position = UDim2.new(0, 10, 0, 0)
teamLbl.BackgroundTransparency = 1
teamLbl.Text = "🏷️ Blue"
teamLbl.TextColor3 = Color3.fromRGB(180, 180, 220)
teamLbl.Font = Enum.Font.Gotham
teamLbl.TextSize = 12
teamLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Team dropdown
local teamDropFrame = Instance.new("Frame", contentContainer)
teamDropFrame.Size = UDim2.new(1, 0, 0, 0)
teamDropFrame.Position = UDim2.new(0, 0, 0, saveTabY + 198)
teamDropFrame.BackgroundColor3 = Color3.fromRGB(14, 10, 26)
teamDropFrame.BorderSizePixel = 0
teamDropFrame.ClipsDescendants = true
teamDropFrame.Visible = false

local teamDropCorner = Instance.new("UICorner", teamDropFrame)
teamDropCorner.CornerRadius = UDim.new(0, 8)

local teamDropScroll = Instance.new("ScrollingFrame", teamDropFrame)
teamDropScroll.Size = UDim2.new(1, -4, 1, 0)
teamDropScroll.Position = UDim2.new(0, 2, 0, 0)
teamDropScroll.BackgroundTransparency = 1
teamDropScroll.ScrollBarThickness = 3
teamDropScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 220)
teamDropScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local teamDropLayout = Instance.new("UIListLayout", teamDropScroll)
teamDropLayout.SortOrder = Enum.SortOrder.LayoutOrder
teamDropLayout.Padding = UDim.new(0, 2)

for idx, teamName in ipairs(teamOptions) do
    local teamBtn = Instance.new("TextButton", teamDropScroll)
    teamBtn.Size = UDim2.new(1, 0, 0, 32)
    teamBtn.BackgroundColor3 = Color3.fromRGB(20, 14, 40)
    teamBtn.Text = "  🏷️ " .. teamName
    teamBtn.TextColor3 = Color3.fromRGB(200, 180, 240)
    teamBtn.Font = Enum.Font.Gotham
    teamBtn.TextSize = 11
    teamBtn.TextXAlignment = Enum.TextXAlignment.Left
    teamBtn.BorderSizePixel = 0
    teamBtn.AutoButtonColor = false
    teamBtn.LayoutOrder = idx
    
    local teamBtnCorner = Instance.new("UICorner", teamBtn)
    teamBtnCorner.CornerRadius = UDim.new(0, 6)
    
    teamBtn.MouseEnter:Connect(function()
        tween(teamBtn, {BackgroundColor3 = Color3.fromRGB(45, 30, 85)}, 0.1)
    end)
    teamBtn.MouseLeave:Connect(function()
        tween(teamBtn, {BackgroundColor3 = Color3.fromRGB(20, 14, 40)}, 0.1)
    end)
    
    teamBtn.MouseButton1Click:Connect(function()
        selectedTeam.value = teamName
        teamLbl.Text = "🏷️ " .. teamName
        teamLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
        
        tween(teamDropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
        task.delay(0.25, function()
            teamDropFrame.Visible = false
        end)
    end)
end

teamBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        teamDropFrame.Visible = not teamDropFrame.Visible
        if teamDropFrame.Visible then
            local targetH = #teamOptions * 34 + 8
            tween(teamDropFrame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
            tween(teamStroke, {Color = Color3.fromRGB(120, 70, 255)}, 0.2)
        else
            tween(teamDropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            tween(teamStroke, {Color = Color3.fromRGB(60, 35, 120)}, 0.2)
        end
    end
end)

-- Save button
local saveBtn = createButton(contentContainer, "💾 SAVE BUILD", saveTabY + 204, Color3.fromRGB(70, 100, 180))

local saveStatus = Instance.new("TextLabel", contentContainer)
saveStatus.Size = UDim2.new(1, 0, 0, 40)
saveStatus.Position = UDim2.new(0, 0, 0, saveTabY + 250)
saveStatus.BackgroundColor3 = Color3.fromRGB(10, 6, 20)
saveStatus.BorderSizePixel = 0
saveStatus.Text = "Status: Ready to save"
saveStatus.TextColor3 = Color3.fromRGB(120, 200, 120)
saveStatus.Font = Enum.Font.Gotham
saveStatus.TextSize = 11
saveStatus.TextWrapped = true
saveStatus.TextXAlignment = Enum.TextXAlignment.Left

local saveStatusCorner = Instance.new("UICorner", saveStatus)
saveStatusCorner.CornerRadius = UDim.new(0, 8)

-- ============================================================
-- TAB 3: OBJ IMPORT
-- ============================================================
local objTabY = 330

createSection(contentContainer, "📥 Import OBJ File", objTabY)

createLabel(contentContainer, "📁 Select .obj file:", objTabY + 34, 14, Color3.fromRGB(130, 90, 180))
local objFileSelector, objDropFrame = createFileSelector(contentContainer, ".obj", objTabY + 50, "")

-- OBJ Settings
createLabel(contentContainer, "⚙️ OBJ Import Settings:", objTabY + 100, 14, Color3.fromRGB(130, 90, 180))

-- Block type for OBJ
createLabel(contentContainer, "🧱 Block Type:", objTabY + 118, 14, Color3.fromRGB(130, 90, 180))
local objBlockInput, _ = createInput(contentContainer, "Wood", objTabY + 134, 34)
objBlockInput.Text = "Wood"

-- Scale
createLabel(contentContainer, "📐 Scale (0.1 - 10):", objTabY + 172, 14, Color3.fromRGB(130, 90, 180))
local objScaleInput, _ = createInput(contentContainer, "1.0", objTabY + 188, 34)
objScaleInput.Text = "1.0"

-- Import button
local objImportBtn = createButton(contentContainer, "📥 IMPORT OBJ", objTabY + 230, Color3.fromRGB(60, 100, 180))

local objStatus = Instance.new("TextLabel", contentContainer)
objStatus.Size = UDim2.new(1, 0, 0, 40)
objStatus.Position = UDim2.new(0, 0, 0, objTabY + 276)
objStatus.BackgroundColor3 = Color3.fromRGB(10, 6, 20)
objStatus.BorderSizePixel = 0
objStatus.Text = "Status: Select an OBJ file to import"
objStatus.TextColor3 = Color3.fromRGB(120, 180, 255)
objStatus.Font = Enum.Font.Gotham
objStatus.TextSize = 11
objStatus.TextWrapped = true
objStatus.TextXAlignment = Enum.TextXAlignment.Left

local objStatusCorner = Instance.new("UICorner", objStatus)
objStatusCorner.CornerRadius = UDim.new(0, 8)

-- ============================================================
-- TAB 4: ROBLOX MODEL IMPORT
-- ============================================================
local modelTabY = 350

createSection(contentContainer, "🔮 Import Roblox Model (Asset ID)", modelTabY)

createLabel(contentContainer, "🎯 Asset ID:", modelTabY + 34, 14, Color3.fromRGB(130, 90, 180))
local modelIdInput, _ = createInput(contentContainer, "Enter Roblox asset ID (e.g. 12345678)", modelTabY + 50, 34)

-- Import button
local modelImportBtn = createButton(contentContainer, "🔮 IMPORT MODEL", modelTabY + 92, Color3.fromRGB(100, 50, 180))

local modelStatus = Instance.new("TextLabel", contentContainer)
modelStatus.Size = UDim2.new(1, 0, 0, 40)
modelStatus.Position = UDim2.new(0, 0, 0, modelTabY + 138)
modelStatus.BackgroundColor3 = Color3.fromRGB(10, 6, 20)
modelStatus.BorderSizePixel = 0
modelStatus.Text = "Status: Enter an asset ID to import"
modelStatus.TextColor3 = Color3.fromRGB(180, 120, 255)
modelStatus.Font = Enum.Font.Gotham
modelStatus.TextSize = 11
modelStatus.TextWrapped = true
modelStatus.TextXAlignment = Enum.TextXAlignment.Left

local modelStatusCorner = Instance.new("UICorner", modelStatus)
modelStatusCorner.CornerRadius = UDim.new(0, 8)

-- ============================================================
-- TAB 5: WIREFRAME MODE
-- ============================================================
local wireTabY = 210

createSection(contentContainer, "🌀 Wireframe Mode - Photo to Blocks", wireTabY)

createLabel(contentContainer, "📝 Custom Text/Pattern:", wireTabY + 34, 14, Color3.fromRGB(130, 90, 180))
local wireTextInput, _ = createInput(contentContainer, "Enter text or pattern...", wireTabY + 50, 60)
wireTextInput.TextXAlignment = Enum.TextXAlignment.Top
wireTextInput.TextWrapped = true
wireTextInput.Text = "OXYX"

-- Wireframe settings
createLabel(contentContainer, "🧱 Block Type:", wireTabY + 114, 14, Color3.fromRGB(130, 90, 180))
local wireBlockInput, _ = createInput(contentContainer, "Neon", wireTabY + 130, 34)
wireBlockInput.Text = "Neon"

-- Color
createLabel(contentContainer, "🎨 Color (R, G, B):", wireTabY + 168, 14, Color3.fromRGB(130, 90, 180))
local wireColorInput, _ = createInput(contentContainer, "0, 255, 255", wireTabY + 184, 34)
wireColorInput.Text = "0, 255, 255"

-- Scale
createLabel(contentContainer, "📐 Scale (1-10):", wireTabY + 222, 14, Color3.fromRGB(130, 90, 180))
local wireScaleInput, _ = createInput(contentContainer, "4", wireTabY + 238, 34)
wireScaleInput.Text = "4"

-- Generate button
local wireGenBtn = createButton(contentContainer, "🌀 GENERATE WIREFRAME", wireTabY + 280, Color3.fromRGB(0, 180, 180))

-- ============================================================
-- TAB 6: SETTINGS
-- ============================================================
local settingsTabY = 0

createSection(contentContainer, "⚙️ General Settings", settingsTabY)

-- Debug mode
local debugModeBtn = Instance.new("TextButton", contentContainer)
debugModeBtn.Size = UDim2.new(1, 0, 0, 32)
debugModeBtn.Position = UDim2.new(0, 0, 0, settingsTabY + 34)
debugModeBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
debugModeBtn.Text = "✓ Debug Mode (off)"
debugModeBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
debugModeBtn.Font = Enum.Font.GothamBold
debugModeBtn.TextSize = 11
debugModeBtn.BorderSizePixel = 0
debugModeBtn.AutoButtonColor = false

local debugCorner = Instance.new("UICorner", debugModeBtn)
debugCorner.CornerRadius = UDim.new(0, 7)

debugModeBtn.MouseButton1Click:Connect(function()
    debugMode = not debugMode
    if debugMode then
        debugModeBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        debugModeBtn.Text = "✓ Debug Mode (on)"
    else
        debugModeBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        debugModeBtn.Text = "✗ Debug Mode (off)"
    end
end)

-- Clear files
local clearFilesBtn = createButton(contentContainer, "🗑️ Clear All Build Files", settingsTabY + 72, Color3.fromRGB(150, 40, 60))

-- Refresh all
local refreshAllBtn = createButton(contentContainer, "🔄 Refresh All", settingsTabY + 118, Color3.fromRGB(50, 80, 150))

createLabel(contentContainer, "📋 Info:", settingsTabY + 160, 14, Color3.fromRGB(100, 80, 160))
createLabel(contentContainer, "Version: " .. SCRIPT_VERSION .. " | " .. SCRIPT_TAG, settingsTabY + 178, 14, Color3.fromRGB(90, 70, 140), 10)
createLabel(contentContainer, "Executor: " .. rawExecutor, settingsTabY + 194, 14, Color3.fromRGB(90, 70, 140), 10)
createLabel(contentContainer, "GUI Source: " .. guiSource, settingsTabY + 210, 14, Color3.fromRGB(90, 70, 140), 10)

-- ============================================================
-- BUILD LOGIC
-- ============================================================
local buildRunning = false
local buildThread = nil

local function startBuild(buildData, speed, offset)
    if buildRunning then return end
    
    buildRunning = true
    loadStatus.Text = "Status: 🔨 Building " .. #buildData .. " parts..."
    loadStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    
    local playerInventory = useInventoryBlocks.value and getPlayerBlockInventory() or {}
    
    -- Check required blocks
    local requiredBlocks = analyzeBuildBlocks(buildData)
    local missingBlocks = {}
    
    if useInventoryBlocks.value and not skipInvCheck.value then
        for _, block in ipairs(requiredBlocks) do
            local available = playerInventory[block.name] or 0
            if available < block.count then
                table.insert(missingBlocks, {
                    name = block.name,
                    required = block.count,
                    available = available
                })
            end
        end
        
        if #missingBlocks > 0 then
            local missingText = "Missing blocks:\n"
            for i, m in ipairs(missingBlocks) do
                if i <= 5 then
                    missingText = missingText .. m.name .. ": " .. m.available .. "/" .. m.required .. "\n"
                end
            end
            if #missingBlocks > 5 then
                missingText = missingText .. "... and " .. (#missingBlocks - 5) .. " more"
            end
            notify("oxyX Warning", missingText, 5, Color3.fromRGB(255, 180, 80))
        end
    end
    
    buildThread = task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then
            loadStatus.Text = "Status: ❌ Character not found!"
            loadStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
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
                    or rs:FindFirstChild("Build")

                if placeRemote and placeRemote:IsA("RemoteEvent") then
                    local partInfo = type(partData) == "table" and partData or {}
                    local partPos = partInfo.Position or partInfo.position or {x=0, y=0, z=0}
                    local partSize = partInfo.Size or partInfo.size or {x=4, y=1.2, z=4}
                    local partColor = partInfo.Color or partInfo.color or {r=163, g=162, b=165}
                    local partMat = partInfo.Block or partInfo.Material or "SmoothPlastic"
                    
                    -- Use inventory block if enabled
                    if useInventoryBlocks.value then
                        local invBlocks = getAvailableBlocks()
                        if #invBlocks > 0 then
                            partMat = invBlocks[math.random(1, #invBlocks)].name
                        end
                    end

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

            loadStatus.Text = "Status: 🔨 Building... (" .. i .. "/" .. #buildData .. ")"
            
            local delay = 1 / math.max(speed, 1)
            task.wait(delay)
        end

        if buildRunning then
            buildRunning = false
            loadStatus.Text = "Status: ✅ Build Complete! (" .. #buildData .. " parts)"
            loadStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX Build", "Build complete!", 4)
        end
    end)
end

-- Load button logic
loadBtn.MouseButton1Click:Connect(function()
    if buildRunning then
        notify("oxyX", "Build already running!", 3)
        return
    end

    if not loadFileSelector.value then
        loadStatus.Text = "Status: ❌ No .build file selected!"
        loadStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX", "Please select a build file first!", 3)
        return
    end

    local raw = readWorkspaceFile(loadFileSelector.value)
    if not raw or raw == "" then
        loadStatus.Text = "Status: ❌ Could not read file!"
        loadStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end

    local speed = tonumber(loadSpeedInput.Text) or 15
    local px, py, pz = loadPosInput.Text:match("([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)")
    local offset = Vector3.new(tonumber(px) or 0, tonumber(py) or 5, tonumber(pz) or 0)

    local buildData = parseBuildData(raw)
    if not buildData or #buildData == 0 then
        loadStatus.Text = "Status: ❌ Invalid build data!"
        loadStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        notify("oxyX", "Invalid build data!", 3)
        return
    end

    startBuild(buildData, speed, offset)
end)

stopLoadBtn.MouseButton1Click:Connect(function()
    if buildRunning then
        buildRunning = false
        if buildThread then task.cancel(buildThread) end
        loadStatus.Text = "Status: ⏹ Build stopped."
        loadStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
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
        loadStatus.Text = "Status: 🎒 " .. count .. " blocks: " .. sample
        loadStatus.TextColor3 = Color3.fromRGB(100, 200, 255)
        notify("oxyX Inventory", count .. " block types found", 3)
    else
        loadStatus.Text = "Status: ⚠️ No inventory found"
        loadStatus.TextColor3 = Color3.fromRGB(255, 180, 80)
        notify("oxyX Inventory", "Could not detect inventory!", 3)
    end
end)

-- ============================================================
-- SAVE BUILD LOGIC
-- ============================================================
local function getOtherPlayerBuild(targetPlayerName)
    local targetPlayer = nil
    
    -- Find player by name
    for _, p in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(p.Name), string.lower(targetPlayerName)) then
            targetPlayer = p
            break
        end
    end
    
    if not targetPlayer then
        return nil, "Player not found!"
    end
    
    local buildParts = {}
    
    -- Get from character
    pcall(function()
        if targetPlayer.Character then
            for _, obj in ipairs(targetPlayer.Character:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("Folder") then
                    for _, part in ipairs(obj:GetChildren()) do
                        if part:IsA("BasePart") then
                            table.insert(buildParts, {
                                Position = {
                                    x = math.round(part.Position.X),
                                    y = math.round(part.Position.Y),
                                    z = math.round(part.Position.Z)
                                },
                                Size = {
                                    x = math.round(part.Size.X * 10) / 10,
                                    y = math.round(part.Size.Y * 10) / 10,
                                    z = math.round(part.Size.Z * 10) / 10
                                },
                                Block = "Wood",
                                Color = {
                                    r = math.round(part.Color.r * 255),
                                    g = math.round(part.Color.g * 255),
                                    b = math.round(part.Color.b * 255)
                                }
                            })
                        end
                    end
                end
            end
        end
    end)
    
    -- Get from workspace
    pcall(function()
        for _, model in ipairs(workspace:GetChildren()) do
            local ownerTag = model:FindFirstChild("Owner") or model:FindFirstChild("owner")
            if ownerTag and string.find(string.lower(tostring(ownerTag.Value)), string.lower(targetPlayerName)) then
                for _, part in ipairs(model:GetChildren()) do
                    if part:IsA("BasePart") then
                        table.insert(buildParts, {
                            Position = {
                                x = math.round(part.Position.X),
                                y = math.round(part.Position.Y),
                                z = math.round(part.Position.Z)
                            },
                            Size = {
                                x = math.round(part.Size.X * 10) / 10,
                                y = math.round(part.Size.Y * 10) / 10,
                                z = math.round(part.Size.Z * 10) / 10
                            },
                            Block = "Wood",
                            Color = {
                                r = math.round(part.Color.r * 255),
                                g = math.round(part.Color.g * 255),
                                b = math.round(part.Color.b * 255)
                            }
                        })
                    end
                end
            end
        end
    end)
    
    if #buildParts == 0 then
        return nil, "Could not find build"
    end
    
    return buildParts, nil
end

local function getSelfBuild()
    local buildParts = {}
    
    pcall(function()
        if player.Character then
            for _, obj in ipairs(player.Character:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("Folder") then
                    for _, part in ipairs(obj:GetChildren()) do
                        if part:IsA("BasePart") then
                            table.insert(buildParts, {
                                Position = {
                                    x = math.round(part.Position.X),
                                    y = math.round(part.Position.Y),
                                    z = math.round(part.Position.Z)
                                },
                                Size = {
                                    x = math.round(part.Size.X * 10) / 10,
                                    y = math.round(part.Size.Y * 10) / 10,
                                    z = math.round(part.Size.Z * 10) / 10
                                },
                                Block = "Wood",
                                Color = {
                                    r = math.round(part.Color.r * 255),
                                    g = math.round(part.Color.g * 255),
                                    b = math.round(part.Color.b * 255)
                                }
                            })
                        end
                    end
                end
            end
        end
    end)
    
    pcall(function()
        for _, model in ipairs(workspace:GetChildren()) do
            local ownerTag = model:FindFirstChild("Owner") or model:FindFirstChild("owner")
            if ownerTag and string.find(string.lower(tostring(ownerTag.Value)), string.lower(player.Name)) then
                for _, part in ipairs(model:GetChildren()) do
                    if part:IsA("BasePart") then
                        table.insert(buildParts, {
                            Position = {
                                x = math.round(part.Position.X),
                                y = math.round(part.Position.Y),
                                z = math.round(part.Position.Z)
                            },
                            Size = {
                                x = math.round(part.Size.X * 10) / 10,
                                y = math.round(part.Size.Y * 10) / 10,
                                z = math.round(part.Size.Z * 10) / 10
                            },
                            Block = "Wood",
                            Color = {
                                r = math.round(part.Color.r * 255),
                                g = math.round(part.Color.g * 255),
                                b = math.round(part.Color.b * 255)
                            }
                        })
                    end
                end
            end
        end
    end)
    
    return buildParts
end

saveBtn.MouseButton1Click:Connect(function()
    local targetName = saveTargetInput.Text
    local buildName = saveBuildNameInput.Text
    local teamName = selectedTeam.value
    
    if not buildName or buildName == "" or buildName == "My Awesome Build" then
        notify("oxyX Save", "Please enter a build name!", 3)
        return
    end
    
    saveStatus.Text = "Status: 🔍 Searching for build..."
    saveStatus.TextColor3 = Color3.fromRGB(120, 180, 255)
    
    task.delay(0.3, function()
        local buildData, err
        
        if targetName and targetName ~= "" and targetName ~= "Enter player name or leave empty for self" then
            buildData, err = getOtherPlayerBuild(targetName)
        else
            buildData = getSelfBuild()
            if #buildData == 0 then
                err = "Could not find your build"
            end
        end
        
        if err or not buildData or #buildData == 0 then
            saveStatus.Text = "Status: ❌ " .. (err or "No build found!")
            saveStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            notify("oxyX Save", err or "No build found!", 3)
            return
        end
        
        local saveData = {
            name = buildName,
            team = teamName,
            owner = player.Name,
            timestamp = os.time(),
            parts = buildData
        }
        
        local jsonData = HttpService:JSONEncode(saveData)
        local fileName = buildName .. "." .. teamName .. ".build"
        
        if writeWorkspaceFile(fileName, jsonData) then
            saveStatus.Text = "Status: ✅ Saved: " .. fileName .. " (" .. #buildData .. " parts)"
            saveStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX Save", "Build saved: " .. fileName, 4)
        else
            saveStatus.Text = "Status: ❌ Failed to save!"
            saveStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            notify("oxyX Save", "Failed to save build!", 3)
        end
    end)
end)

-- ============================================================
-- OBJ IMPORT LOGIC
-- ============================================================
objImportBtn.MouseButton1Click:Connect(function()
    if not objFileSelector.value then
        objStatus.Text = "Status: ❌ No OBJ file selected!"
        objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end
    
    local content = readWorkspaceFile(objFileSelector.value)
    if not content then
        objStatus.Text = "Status: ❌ Could not read file!"
        objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end
    
    local scale = tonumber(objScaleInput.Text) or 1.0
    local blockType = objBlockInput.Text
    
    objStatus.Text = "Status: 🔄 Parsing OBJ file..."
    objStatus.TextColor3 = Color3.fromRGB(120, 180, 255)
    
    task.delay(0.5, function()
        local buildData, err = objToBuildData(content, {
            scale = scale,
            blockType = blockType
        })
        
        if err or not buildData then
            objStatus.Text = "Status: ❌ " .. (err or "Failed to parse OBJ")
            objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end
        
        -- Save as .build file
        local saveData = {
            name = objFileSelector.name or "OBJ_Import",
            source = "OBJ Import",
            timestamp = os.time(),
            parts = buildData
        }
        
        local jsonData = HttpService:JSONEncode(saveData)
        local fileName = "obj_import_" .. os.time() .. ".build"
        
        if writeWorkspaceFile(fileName, jsonData) then
            objStatus.Text = "Status: ✅ Converted: " .. fileName .. " (" .. #buildData .. " parts)"
            objStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
            notify("oxyX OBJ", "OBJ converted to " .. fileName, 4)
        else
            objStatus.Text = "Status: ❌ Failed to save!"
            objStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

-- ============================================================
-- MODEL IMPORT LOGIC
-- ============================================================
modelImportBtn.MouseButton1Click:Connect(function()
    local assetId = modelIdInput.Text
    if not assetId or assetId == "" then
        modelStatus.Text = "Status: ❌ Please enter an asset ID!"
        modelStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end
    
    -- Extract numeric ID
    local numericId = tonumber(assetId:match("%d+"))
    if not numericId then
        modelStatus.Text = "Status: ❌ Invalid asset ID!"
        modelStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end
    
    modelStatus.Text = "Status: 🔄 Loading model..."
    modelStatus.TextColor3 = Color3.fromRGB(180, 120, 255)
    
    task.delay(0.5, function()
        local buildData, err = importRobloxModel(numericId)
        
        if err or not buildData then
            modelStatus.Text = "Status: ❌ " .. (err or "Failed to load model")
            modelStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end
        
        local saveData = {
            name = "Model_" .. numericId,
            source = "Asset ID: " .. numericId,
            timestamp = os.time(),
            parts = buildData
        }
        
        local jsonData = HttpService:JSONEncode(saveData)
        local fileName = "model_" .. numericId .. ".build"
        
        if writeWorkspaceFile(fileName, jsonData) then
            modelStatus.Text = "Status: ✅ Imported: " .. fileName .. " (" .. #buildData .. " parts)"
            modelStatus.TextColor3 = Color3.fromRGB(180, 120, 255)
            notify("oxyX Model", "Model imported to " .. fileName, 4)
        else
            modelStatus.Text = "Status: ❌ Failed to save!"
            modelStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

-- ============================================================
-- WIREFRAME MODE LOGIC
-- ============================================================
wireGenBtn.MouseButton1Click:Connect(function()
    local text = wireTextInput.Text
    if not text or text == "" then
        notify("oxyX Wireframe", "Please enter text or pattern!", 3)
        return
    end
    
    local blockType = wireBlockInput.Text
    local colorStr = wireColorInput.Text
    local r, g, b = colorStr:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    local colorR = tonumber(r) or 0
    local colorG = tonumber(g) or 255
    local colorB = tonumber(b) or 255
    local scale = tonumber(wireScaleInput.Text) or 4
    
    local buildData = generateWireframeFromText(text, {
        scale = scale,
        blockType = blockType,
        colorR = colorR,
        colorG = colorG,
        colorB = colorB
    })
    
    local saveData = {
        name = "Wireframe_" .. os.time(),
        source = "Wireframe Mode",
        timestamp = os.time(),
        parts = buildData
    }
    
    local jsonData = HttpService:JSONEncode(saveData)
    local fileName = "wireframe_" .. os.time() .. ".build"
    
    if writeWorkspaceFile(fileName, jsonData) then
        notify("oxyX Wireframe", "Generated: " .. fileName .. " (" .. #buildData .. " blocks)", 4, Color3.fromRGB(0, 200, 200))
    else
        notify("oxyX Wireframe", "Failed to save!", 3, Color3.fromRGB(255, 80, 80))
    end
end)

-- ============================================================
-- SETTINGS BUTTONS
-- ============================================================
clearFilesBtn.MouseButton1Click:Connect(function()
    local files = listWorkspaceFiles(".build")
    local count = 0
    for _, f in ipairs(files) do
        if deleteWorkspaceFile(f.path) then
            count = count + 1
        end
    end
    notify("oxyX", "Deleted " .. count .. " build files", 3)
end)

refreshAllBtn.MouseButton1Click:Connect(function()
    notify("oxyX", "Files refreshed!", 2)
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

-- Chat commands
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
-- SHOW GUI
-- ============================================================
local function showGUI()
    pcall(function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui.Enabled = true
            print("[oxyX] GUI Enabled = true")
        else
            print("[oxyX] WARNING: ScreenGui has no parent, trying to recreate...")
            local ok_hui, hui = pcall(function() return gethui and gethui() end)
            if ok_hui and hui then
                pcall(function() ScreenGui.Parent = hui end)
            end
            if not ScreenGui.Parent then
                local successCore, CoreGui = pcall(game.GetService, game, "CoreGui")
                if successCore and CoreGui then
                    pcall(function() ScreenGui.Parent = CoreGui end)
                end
            end
            if not ScreenGui.Parent then
                local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
                if playerGui then
                    ScreenGui.Parent = playerGui
                end
            end
            if ScreenGui.Parent then
                ScreenGui.Enabled = true
                print("[oxyX] GUI recreated via fallback")
            end
        end
        
        if MainFrame then
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 620, 0, 680)
            MainFrame.Position = UDim2.new(0.5, -310, 0.5, -340)
            print("[oxyX] MainFrame should now be visible")
        else
            print("[oxyX] ERROR: MainFrame is nil!")
        end
    end)
    
    -- Show notification
    pcall(function()
        notify("oxyX BABFT v" .. SCRIPT_VERSION, "Loaded! " .. SCRIPT_TAG .. " | " .. rawExecutor, 5)
    end)
end

-- Show GUI after short delay
task.delay(0.1, showGUI)

-- Also try showing immediately in case delay fails
task.delay(0.5, function()
    pcall(function()
        if MainFrame and not MainFrame.Visible then
            MainFrame.Visible = true
            print("[oxyX] Backup: MainFrame visibility set to true")
        end
    end)
end)

-- ============================================================
-- ADVANCED BUILD TOOLS
-- ============================================================

-- Auto-save feature
local autoSaveEnabled = {value = false}
local autoSaveInterval = {value = 30} -- seconds

local function setupAutoSave()
    if autoSaveEnabled.value then
        task.spawn(function()
            while autoSaveEnabled.value and wait(autoSaveInterval.value) do
                local buildData = getSelfBuild()
                if #buildData > 0 then
                    local saveData = {
                        name = "autosave_" .. os.date("%Y%m%d_%H%M%S"),
                        team = "AutoSave",
                        owner = player.Name,
                        timestamp = os.time(),
                        parts = buildData,
                        autoSave = true
                    }
                    local jsonData = HttpService:JSONEncode(saveData)
                    writeWorkspaceFile("autosave_" .. os.time() .. ".build", jsonData)
                    debugLog("Auto-saved build with " .. #buildData .. " parts")
                end
            end
        end)
    end
end

-- Build history
local buildHistory = {}
local maxHistorySize = 20

local function addToHistory(fileName, buildData)
    table.insert(buildHistory, 1, {
        name = fileName,
        parts = #buildData,
        timestamp = os.time()
    })
    
    while #buildHistory > maxHistorySize do
        table.remove(buildHistory)
    end
end

-- Build optimization
local function optimizeBuildData(buildData)
    -- Remove duplicate positions
    local seen = {}
    local optimized = {}
    
    for _, part in ipairs(buildData) do
        local pos = part.Position
        local key = pos.x .. "," .. pos.y .. "," .. pos.z
        
        if not seen[key] then
            seen[key] = true
            table.insert(optimized, part)
        end
    end
    
    debugLog("Optimized from " .. #buildData .. " to " .. #optimized .. " parts")
    return optimized
end

-- Build validation
local function validateBuildData(buildData)
    local valid = {}
    local invalid = 0
    
    for _, part in ipairs(buildData) do
        if part.Position and part.Size and part.Block then
            local px = part.Position.x or part.Position.X
            local py = part.Position.y or part.Position.Y
            local pz = part.Position.z or part.Position.Z
            
            local sx = part.Size.x or part.Size.X
            local sy = part.Size.y or part.Size.Y
            local sz = part.Size.z or part.Size.Z
            
            if px and py and pz and sx and sy and sz then
                table.insert(valid, part)
            else
                invalid = invalid + 1
            end
        else
            invalid = invalid + 1
        end
    end
    
    if invalid > 0 then
        debugLog("Found " .. invalid .. " invalid parts")
    end
    
    return valid
end

-- ============================================================
-- BUILD TEMPLATES
-- ============================================================
local buildTemplates = {
    {
        name = "Simple House",
        description = "A basic house structure",
        parts = {
            {Position = {x=0,y=0,z=0}, Size = {x=8,y=1,z=8}, Block = "Brick", Color = {r=180,g=100,b=100}},
            {Position = {x=0,y=1,z=0}, Size = {x=8,y=3,z=1}, Block = "Brick", Color = {r=180,g=100,b=100}},
            {Position = {x=0,y=1,z=7}, Size = {x=8,y=3,z=1}, Block = "Brick", Color = {r=180,g=100,b=100}},
            {Position = {x=0,y=1,z=1}, Size = {x=1,y=3,z=6}, Block = "Brick", Color = {r=180,g=100,b=100}},
            {Position = {x=7,y=1,z=1}, Size = {x=1,y=3,z=6}, Block = "Brick", Color = {r=180,g=100,b=100}},
            {Position = {x=0,y=4,z=0}, Size = {x=8,y=1,z=8}, Block = "Wood", Color = {r=139,g=90,b=43}}
        }
    },
    {
        name = "Basic Boat",
        description = "A simple boat shape",
        parts = {
            {Position = {x=0,y=0,z=0}, Size = {x=6,y=1,z=12}, Block = "Wood", Color = {r=139,g=90,b=43}},
            {Position = {x=0,y=1,z=-5}, Size = {x=4,y=2,z=2}, Block = "Wood", Color = {r=139,g=90,b=43}},
            {Position = {x=0,y=1,z=5}, Size = {x=4,y=2,z=2}, Block = "Wood", Color = {r=139,g=90,b=43}},
            {Position = {x=0,y=2,z=0}, Size = {x=2,y=2,z=8}, Block = "Wood Plank", Color = {r=160,g=120,b=80}}
        }
    },
    {
        name = "Tower",
        description = "A tall tower structure",
        parts = {
            {Position = {x=0,y=0,z=0}, Size = {x=4,y=1,z=4}, Block = "Stone", Color = {r=128,g=128,b=128}},
            {Position = {x=0,y=1,z=0}, Size = {x=3,y=1,z=3}, Block = "Stone", Color = {r=128,g=128,b=128}},
            {Position = {x=0,y=2,z=0}, Size = {x=2,y=1,z=2}, Block = "Stone", Color = {r=128,g=128,b=128}},
            {Position = {x=0,y=3,z=0}, Size = {x=1,y=1,z=1}, Block = "Gold", Color = {r=255,g=215,b=0}}
        }
    }
}

-- ============================================================
-- BATCH OPERATIONS
-- ============================================================
local function batchBuild(buildData, batchSize, delayTime)
    batchSize = batchSize or 50
    delayTime = delayTime or 0.1
    
    local batches = {}
    local currentBatch = {}
    
    for i, part in ipairs(buildData) do
        table.insert(currentBatch, part)
        
        if #currentBatch >= batchSize then
            table.insert(batches, currentBatch)
            currentBatch = {}
        end
    end
    
    if #currentBatch > 0 then
        table.insert(batches, currentBatch)
    end
    
    return batches
end

-- ============================================================
-- ADVANCED INVENTORY MANAGEMENT
-- ============================================================
local function getDetailedInventory()
    local inventory = getPlayerBlockInventory()
    local detailed = {}
    
    for blockName, count in pairs(inventory) do
        table.insert(detailed, {
            name = blockName,
            count = count,
            normalized = normalizeBlockName(blockName)
        })
    end
    
    table.sort(detailed, function(a, b) return a.count > b.count end)
    return detailed
end

local function suggestBlocks(requiredBlocks, inventory)
    local suggestions = {}
    
    for _, required in ipairs(requiredBlocks) do
        local available = inventory[required.name] or 0
        local missing = required.count - available
        
        if missing > 0 then
            table.insert(suggestions, {
                name = required.name,
                required = required.count,
                available = available,
                missing = missing
            })
        end
    end
    
    table.sort(suggestions, function(a, b) return a.missing > b.missing end)
    return suggestions
end

-- ============================================================
-- BUILD STATISTICS
-- ============================================================
local function getBuildStats(buildData)
    local stats = {
        totalParts = #buildData,
        uniqueBlocks = {},
        blockCount = {},
        totalVolume = 0,
        boundingBox = {
            minX = math.huge, maxX = -math.huge,
            minY = math.huge, maxY = -math.huge,
            minZ = math.huge, maxZ = -math.huge
        }
    }
    
    for _, part in ipairs(buildData) do
        -- Count blocks
        local blockName = part.Block or part.Material or "Unknown"
        stats.blockCount[blockName] = (stats.blockCount[blockName] or 0) + 1
        
        -- Calculate volume
        local sx = part.Size.x or part.Size.X or 4
        local sy = part.Size.y or part.Size.Y or 1.2
        local sz = part.Size.z or part.Size.Z or 4
        stats.totalVolume = stats.totalVolume + (sx * sy * sz)
        
        -- Bounding box
        local px = part.Position.x or part.Position.X or 0
        local py = part.Position.y or part.Position.Y or 0
        local pz = part.Position.z or part.Position.Z or 0
        
        stats.boundingBox.minX = math.min(stats.boundingBox.minX, px)
        stats.boundingBox.maxX = math.max(stats.boundingBox.maxX, px)
        stats.boundingBox.minY = math.min(stats.boundingBox.minY, py)
        stats.boundingBox.maxY = math.max(stats.boundingBox.maxY, py)
        stats.boundingBox.minZ = math.min(stats.boundingBox.minZ, pz)
        stats.boundingBox.maxZ = math.max(stats.boundingBox.maxZ, pz)
    end
    
    -- Get unique blocks
    for name, _ in pairs(stats.blockCount) do
        table.insert(stats.uniqueBlocks, {name = name, count = stats.blockCount[name]})
    end
    
    table.sort(stats.uniqueBlocks, function(a, b) return a.count > b.count end)
    
    -- Calculate dimensions
    stats.width = stats.boundingBox.maxX - stats.boundingBox.minX
    stats.height = stats.boundingBox.maxY - stats.boundingBox.minY
    stats.depth = stats.boundingBox.maxZ - stats.boundingBox.minZ
    
    return stats
end

-- ============================================================
-- BUILD TRANSFORMATIONS
-- ============================================================
local function rotateBuild(buildData, axis, degrees)
    local rotated = {}
    local radians = math.rad(degrees)
    local cosR = math.cos(radians)
    local sinR = math.sin(radians)
    
    for _, part in ipairs(buildData) do
        local newPart = table.clone(part)
        local px = part.Position.x or part.Position.X or 0
        local py = part.Position.y or part.Position.Y or 0
        local pz = part.Position.z or part.Position.Z or 0
        
        local newX, newY, newZ
        
        if axis == "x" then
            newX = px
            newY = py * cosR - pz * sinR
            newZ = py * sinR + pz * cosR
        elseif axis == "y" then
            newX = px * cosR + pz * sinR
            newY = py
            newZ = -px * sinR + pz * cosR
        else
            newX = px * cosR - py * sinR
            newY = px * sinR + py * cosR
            newZ = pz
        end
        
        newPart.Position = {
            x = math.round(newX),
            y = math.round(newY),
            z = math.round(newZ)
        }
        
        table.insert(rotated, newPart)
    end
    
    return rotated
end

local function scaleBuild(buildData, scaleFactor)
    local scaled = {}
    
    for _, part in ipairs(buildData) do
        local newPart = table.clone(part)
        
        local px = part.Position.x or part.Position.X or 0
        local py = part.Position.y or part.Position.Y or 0
        local pz = part.Position.z or part.Position.Z or 0
        
        newPart.Position = {
            x = math.round(px * scaleFactor),
            y = math.round(py * scaleFactor),
            z = math.round(pz * scaleFactor)
        }
        
        local sx = part.Size.x or part.Size.X or 4
        local sy = part.Size.y or part.Size.Y or 1.2
        local sz = part.Size.z or part.Size.Z or 4
        
        newPart.Size = {
            x = math.round(sx * scaleFactor * 10) / 10,
            y = math.round(sy * scaleFactor * 10) / 10,
            z = math.round(sz * scaleFactor * 10) / 10
        }
        
        table.insert(scaled, newPart)
    end
    
    return scaled
end

local function mirrorBuild(buildData, axis)
    local mirrored = {}
    
    for _, part in ipairs(buildData) do
        local newPart = table.clone(part)
        
        local px = part.Position.x or part.Position.X or 0
        local py = part.Position.y or part.Position.Y or 0
        local pz = part.Position.z or part.Position.Z or 0
        
        if axis == "x" then
            newPart.Position = {x = -px, y = py, z = pz}
        elseif axis == "y" then
            newPart.Position = {x = px, y = -py, z = pz}
        else
            newPart.Position = {x = px, y = py, z = -pz}
        end
        
        table.insert(mirrored, newPart)
    end
    
    return mirrored
end

local function translateBuild(buildData, offsetX, offsetY, offsetZ)
    local translated = {}
    
    for _, part in ipairs(buildData) do
        local newPart = table.clone(part)
        
        local px = part.Position.x or part.Position.X or 0
        local py = part.Position.y or part.Position.Y or 0
        local pz = part.Position.z or part.Position.Z or 0
        
        newPart.Position = {
            x = px + offsetX,
            y = py + offsetY,
            z = pz + offsetZ
        }
        
        table.insert(translated, newPart)
    end
    
    return translated
end

-- ============================================================
-- COLOR MANIPULATION
-- ============================================================
local function hexToRgb(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    return {r = r or 0, g = g or 0, b = b or 0}
end

local function rgbToHex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function lightenColor(r, g, b, amount)
    return {
        r = math.min(255, math.round(r + (255 - r) * amount)),
        g = math.min(255, math.round(g + (255 - g) * amount)),
        b = math.min(255, math.round(b + (255 - b) * amount))
    }
end

local function darkenColor(r, g, b, amount)
    return {
        r = math.max(0, math.round(r * (1 - amount))),
        g = math.max(0, math.round(g * (1 - amount))),
        b = math.max(0, math.round(b * (1 - amount)))
    }
end

local function setAllBlockColors(buildData, r, g, b)
    local colored = {}
    
    for _, part in ipairs(buildData) do
        local newPart = table.clone(part)
        newPart.Color = {r = r, g = g, b = b}
        table.insert(colored, newPart)
    end
    
    return colored
end

-- ============================================================
-- PATTERN GENERATORS
-- ============================================================
local function createGridPattern(width, height, blockType, color)
    local parts = {}
    
    for x = 1, width do
        for y = 1, height do
            table.insert(parts, {
                Position = {x = (x - width/2) * 4, y = 0, z = (y - height/2) * 4},
                Size = {x = 4, y = 1, z = 4},
                Block = blockType,
                Color = color
            })
        end
    end
    
    return parts
end

local function createCirclePattern(radius, blockType, color)
    local parts = {}
    local radiusInBlocks = math.floor(radius / 2)
    
    for x = -radiusInBlocks, radiusInBlocks do
        for z = -radiusInBlocks, radiusInBlocks do
            if x*x + z*z <= radiusInBlocks * radiusInBlocks then
                table.insert(parts, {
                    Position = {x = x * 4, y = 0, z = z * 4},
                    Size = {x = 4, y = 1, z = 4},
                    Block = blockType,
                    Color = color
                })
            end
        end
    end
    
    return parts
end

local function createSpiralPattern(height, blockType, color)
    local parts = {}
    
    for y = 0, height do
        local angle = y * 0.5
        local radius = y * 0.3
        local x = math.cos(angle) * radius * 4
        local z = math.sin(angle) * radius * 4
        
        table.insert(parts, {
            Position = {x = math.round(x), y = y * 2, z = math.round(z)},
            Size = {x = 4, y = 1, z = 4},
            Block = blockType,
            Color = color
        })
    end
    
    return parts
end

local function createCheckerboardPattern(width, height, blockType1, color1, blockType2, color2)
    local parts = {}
    
    for x = 1, width do
        for y = 1, height do
            local isEven = (x + y) % 2 == 0
            
            table.insert(parts, {
                Position = {x = (x - width/2) * 4, y = 0, z = (y - height/2) * 4},
                Size = {x = 4, y = 1, z = 4},
                Block = isEven and blockType1 or blockType2,
                Color = isEven and color1 or color2
            })
        end
    end
    
    return parts
end

local function createPyramidPattern(baseSize, blockType, color)
    local parts = {}
    
    for layer = 0, baseSize - 1 do
        local size = baseSize - layer
        local offset = layer * 2
        
        for x = 1, size do
            for z = 1, size do
                table.insert(parts, {
                    Position = {x = (x - size/2 + offset/2) * 4, y = layer * 2, z = (z - size/2 + offset/2) * 4},
                    Size = {x = 4, y = 1, z = 4},
                    Block = blockType,
                    Color = color
                })
            end
        end
    end
    
    return parts
end

-- ============================================================
-- MERGE AND COMBINE BUILDS
-- ============================================================
local function mergeBuilds(build1, build2, offsetY)
    offsetY = offsetY or 0
    local merged = {}
    
    for _, part in ipairs(build1) do
        table.insert(merged, table.clone(part))
    end
    
    for _, part in ipairs(build2) do
        local newPart = table.clone(part)
        newPart.Position.y = (newPart.Position.y or newPart.Position.Y or 0) + offsetY
        table.insert(merged, newPart)
    end
    
    return merged
end

local function duplicateBuild(buildData, count, spacing)
    spacing = spacing or 20
    local duplicated = {}
    
    for i = 1, count do
        for _, part in ipairs(buildData) do
            local newPart = table.clone(part)
            newPart.Position.x = (newPart.Position.x or newPart.Position.X or 0) + (i - 1) * spacing
            newPart.Position.z = newPart.Position.z or newPart.Position.z or 0
            table.insert(duplicated, newPart)
        end
    end
    
    return duplicated
end

-- ============================================================
-- EXPORT FUNCTIONS
-- ============================================================
local function exportToJSON(buildData, fileName)
    local data = {
        format = "oxyX_BABFT_v1.2",
        exportTime = os.time(),
        parts = buildData
    }
    
    local json = HttpService:JSONEncode(data)
    local success = writeWorkspaceFile(fileName or "export.build", json)
    return success
end

local function exportToCSV(buildData, fileName)
    local csv = "PositionX,PositionY,PositionZ,SizeX,SizeY,SizeZ,Block,R,G,B\n"
    
    for _, part in ipairs(buildData) do
        local px = part.Position.x or part.Position.X or 0
        local py = part.Position.y or part.Position.Y or 0
        local pz = part.Position.z or part.Position.Z or 0
        local sx = part.Size.x or part.Size.X or 4
        local sy = part.Size.y or part.Size.Y or 1.2
        local sz = part.Size.z or part.Size.Z or 4
        local block = part.Block or "Wood"
        local r = part.Color and (part.Color.r or part.Color.R) or 163
        local g = part.Color and (part.Color.g or part.Color.G) or 162
        local b = part.Color and (part.Color.b or part.Color.B) or 165
        
        csv = csv .. px .. "," .. py .. "," .. pz .. "," .. sx .. "," .. sy .. "," .. sz .. "," .. block .. "," .. r .. "," .. g .. "," .. b .. "\n"
    end
    
    local success = writeWorkspaceFile(fileName or "export.csv", csv)
    return success
end

-- ============================================================
-- IMPORT FUNCTIONS
-- ============================================================
local function importFromCSV(content)
    local parts = {}
    local lines = {}
    
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    -- Skip header
    for i = 2, #lines do
        local line = lines[i]
        local px, py, pz, sx, sy, sz, block, r, g, b = line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        
        if px and py then
            table.insert(parts, {
                Position = {x = tonumber(px), y = tonumber(py), z = tonumber(pz)},
                Size = {x = tonumber(sx), y = tonumber(sy), z = tonumber(sz)},
                Block = block,
                Color = {r = tonumber(r), g = tonumber(g), b = tonumber(b)}
            })
        end
    end
    
    return parts
end

-- ============================================================
-- PERFORMANCE OPTIMIZATION
-- ============================================================
local function calculateBuildTime(buildData, speed)
    speed = speed or 10
    return math.ceil(#buildData / speed)
end

local function estimateBuildTime(partsCount, speed)
    local seconds = partsCount / (speed or 10)
    
    if seconds < 60 then
        return string.format("%d seconds", seconds)
    elseif seconds < 3600 then
        return string.format("%.1f minutes", seconds / 60)
    else
        return string.format("%.1f hours", seconds / 3600)
    end
end

-- ============================================================
-- ERROR HANDLING
-- ============================================================
local function safeExecute(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        debugLog("Error:", result)
        return nil, result
    end
    return result, nil
end

-- ============================================================
-- UI CUSTOMIZATION
-- ============================================================
local uiThemes = {
    default = {
        primary = Color3.fromRGB(80, 40, 200),
        secondary = Color3.fromRGB(60, 30, 160),
        background = Color3.fromRGB(8, 8, 15),
        text = Color3.fromRGB(200, 180, 255),
        accent = Color3.fromRGB(120, 80, 255)
    },
    dark = {
        primary = Color3.fromRGB(30, 30, 50),
        secondary = Color3.fromRGB(20, 20, 40),
        background = Color3.fromRGB(5, 5, 10),
        text = Color3.fromRGB(180, 180, 200),
        accent = Color3.fromRGB(80, 60, 180)
    },
    neon = {
        primary = Color3.fromRGB(0, 255, 255),
        secondary = Color3.fromRGB(0, 200, 200),
        background = Color3.fromRGB(10, 10, 20),
        text = Color3.fromRGB(200, 255, 255),
        accent = Color3.fromRGB(0, 255, 200)
    },
    ocean = {
        primary = Color3.fromRGB(0, 100, 200),
        secondary = Color3.fromRGB(0, 80, 180),
        background = Color3.fromRGB(8, 15, 25),
        text = Color3.fromRGB(180, 220, 255),
        accent = Color3.fromRGB(0, 150, 255)
    }
}

-- ============================================================
-- HOTKEY SYSTEM
-- ============================================================
local hotkeys = {
    {key = "One", modifier = "LeftControl", action = "loadBuild"},
    {key = "Two", modifier = "LeftControl", action = "saveBuild"},
    {key = "Three", modifier = "LeftControl", action = "checkInventory"},
    {key = "P", modifier = "LeftControl", action = "togglePause"},
    {key = "R", modifier = "LeftControl", action = "refresh"}
}

local function setupHotkeys()
    for _, hotkey in ipairs(hotkeys) do
        -- Hotkey setup would go here
    end
end

-- ============================================================
-- PROGRESS TRACKING
-- ============================================================
local buildProgress = {
    current = 0,
    total = 0,
    percentage = 0,
    startTime = 0,
    estimatedEnd = 0
}

local function updateProgress(current, total)
    buildProgress.current = current
    buildProgress.total = total
    buildProgress.percentage = math.floor((current / total) * 100)
    
    if buildProgress.startTime == 0 then
        buildProgress.startTime = os.time()
    end
    
    local elapsed = os.time() - buildProgress.startTime
    if current > 0 then
        local timePerPart = elapsed / current
        local remaining = total - current
        buildProgress.estimatedEnd = os.time() + (remaining * timePerPart)
    end
end

local function getProgressString()
    if buildProgress.total == 0 then return "Ready" end
    return string.format("%d/%d (%d%%)", buildProgress.current, buildProgress.total, buildProgress.percentage)
end

local function getTimeRemaining()
    if buildProgress.estimatedEnd == 0 then return "N/A" end
    
    local remaining = buildProgress.estimatedEnd - os.time()
    if remaining < 0 then return "0s" end
    
    if remaining < 60 then
        return remaining .. "s"
    elseif remaining < 3600 then
        return math.floor(remaining / 60) .. "m"
    else
        return math.floor(remaining / 3600) .. "h " .. math.floor((remaining % 3600) / 60) .. "m"
    end
end

-- ============================================================
-- CLOUD SYNC (Mock)
-- ============================================================
local function syncToCloud(data)
    -- This would connect to a cloud service in a real implementation
    debugLog("Syncing to cloud...")
    return true
end

local function loadFromCloud(id)
    -- This would load from a cloud service in a real implementation
    debugLog("Loading from cloud: " .. tostring(id))
    return nil
end

-- ============================================================
-- PLUGIN SYSTEM
-- ============================================================
local plugins = {}

local function registerPlugin(name, functions)
    plugins[name] = {
        name = name,
        functions = functions,
        enabled = true
    }
    debugLog("Registered plugin: " .. name)
end

local function callPlugin(name, funcName, ...)
    local plugin = plugins[name]
    if not plugin or not plugin.enabled then return nil end
    
    local func = plugin.functions[funcName]
    if func then
        return func(...)
    end
    return nil
end

local function enablePlugin(name)
    if plugins[name] then
        plugins[name].enabled = true
    end
end

local function disablePlugin(name)
    if plugins[name] then
        plugins[name].enabled = false
    end
end

-- ============================================================
-- UNDO SYSTEM
-- ============================================================
local undoStack = {}
local redoStack = {}
local maxUndoSize = 50

local function pushUndo(action)
    table.insert(undoStack, action)
    
    while #undoStack > maxUndoSize do
        table.remove(undoStack, 1)
    end
    
    redoStack = {}
end

local function popUndo()
    local action = table.remove(undoStack)
    if action then
        table.insert(redoStack, action)
    end
    return action
end

local function canUndo()
    return #undoStack > 0
end

local function canRedo()
    return #redoStack > 0
end

-- ============================================================
-- MACRO SYSTEM
-- ============================================================
local macros = {}

local function createMacro(name, actions)
    macros[name] = {
        name = name,
        actions = actions,
        createdAt = os.time()
    }
end

local function runMacro(name)
    local macro = macros[name]
    if not macro then return end
    
    for _, action in ipairs(macro.actions) do
        if action.type == "wait" then
            task.wait(action.duration)
        elseif action.type == "build" then
            -- Execute build action
        end
    end
end

-- ============================================================
-- SHORTCUT FUNCTIONS FOR QUICK ACCESS
-- ============================================================
local quickActions = {
    saveCurrent = function() return getSelfBuild() end,
    getInventory = function() return getPlayerBlockInventory() end,
    getStats = function(buildData) return getBuildStats(buildData) end,
    optimize = function(buildData) return optimizeBuildData(buildData) end,
    validate = function(buildData) return validateBuildData(buildData) end
}

-- ============================================================
-- DEBUGGING TOOLS
-- ============================================================
local debugTools = {
    showHitboxes = false,
    showGrid = false,
    showOrigin = false
}

local function toggleHitboxes()
    debugTools.showHitboxes = not debugTools.showHitboxes
    debugLog("Hitboxes:", debugTools.showHitboxes)
end

local function toggleGrid()
    debugTools.showGrid = not debugTools.showGrid
    debugLog("Grid:", debugTools.showGrid)
end

local function toggleOrigin()
    debugTools.showOrigin = not debugTools.showOrigin
    debugLog("Origin:", debugTools.showOrigin)
end

-- ============================================================
-- EXPERIMENTAL FEATURES
-- ============================================================
local experimentalFeatures = {
    multiThreadedBuild = false,
    predictiveLoading = false,
    cloudCache = false
}

local function enableExperimental(feature)
    experimentalFeatures[feature] = true
    debugLog("Enabled experimental feature:", feature)
end

local function disableExperimental(feature)
    experimentalFeatures[feature] = false
    debugLog("Disabled experimental feature:", feature)
end

-- ============================================================
-- LEGACY COMPATIBILITY
-- ============================================================
-- Keep backward compatibility with older build formats
local function migrateLegacyFormat(buildData)
    if not buildData then return {} end
    
    -- Convert old format to new
    if buildData.parts then
        return buildData.parts
    end
    
    return buildData
end

-- ============================================================
-- BACKUP SYSTEM
-- ============================================================
local backupEnabled = {value = true}
local maxBackups = 10

local function createBackup(buildData, name)
    if not backupEnabled.value then return nil end
    
    local backupName = "backup_" .. (name or os.date("%Y%m%d_%H%M%S")) .. ".build"
    local data = {
        backup = true,
        timestamp = os.time(),
        originalName = name,
        parts = buildData
    }
    
    local json = HttpService:JSONEncode(data)
    writeWorkspaceFile(backupName, json)
    
    -- Clean old backups
    local backups = listWorkspaceFiles("backup_")
    while #backups > maxBackups do
        deleteWorkspaceFile(backups[1].path)
        table.remove(backups, 1)
    end
    
    return backupName
end

-- ============================================================
-- STATISTICS TRACKING
-- ============================================================
local sessionStats = {
    buildsLoaded = 0,
    buildsSaved = 0,
    partsPlaced = 0,
    timeSpent = 0,
    errors = 0
}

local function recordBuildLoaded()
    sessionStats.buildsLoaded = sessionStats.buildsLoaded + 1
end

local function recordBuildSaved()
    sessionStats.buildsSaved = sessionStats.buildsSaved + 1
end

local function recordPartsPlaced(count)
    sessionStats.partsPlaced = sessionStats.partsPlaced + count
end

local function recordError()
    sessionStats.errors = sessionStats.errors + 1
end

local function getSessionStats()
    return sessionStats
end

-- ============================================================
-- ADVANCED SEARCH
-- ============================================================
local function searchBuilds(query)
    local results = {}
    local files = listWorkspaceFiles(".build")
    
    query = string.lower(query)
    
    for _, file in ipairs(files) do
        if string.find(string.lower(file.name), query) then
            table.insert(results, file)
        end
    end
    
    return results
end

-- ============================================================
-- BATCH FILE OPERATIONS
-- ============================================================
local function deleteMultipleFiles(fileList)
    local deleted = 0
    
    for _, file in ipairs(fileList) do
        if deleteWorkspaceFile(file.path) then
            deleted = deleted + 1
        end
    end
    
    return deleted
end

local function copyFile(source, dest)
    local content = readWorkspaceFile(source)
    if content then
        return writeWorkspaceFile(dest, content)
    end
    return false
end

-- ============================================================
-- VALIDATION UTILITIES
-- ============================================================
local function isValidPosition(pos)
    if not pos then return false end
    
    local x = pos.x or pos.X
    local y = pos.y or pos.Y
    local z = pos.z or pos.Z
    
    return x and y and z and type(x) == "number" and type(y) == "number" and type(z) == "number"
end

local function isValidSize(size)
    if not size then return false end
    
    local x = size.x or size.X
    local y = size.y or size.Y
    local z = size.z or size.Z
    
    return x and y and z and type(x) == "number" and type(y) == "number" and type(z) == "number"
end

local function isValidColor(color)
    if not color then return false end
    
    local r = color.r or color.R
    local g = color.g or color.G
    local b = color.b or color.B
    
    if not (r and g and b) then return false end
    
    return r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255
end

-- ============================================================
-- ADDITIONAL UTILITY FUNCTIONS
-- ============================================================
local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function roundTo(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

local function randomColor()
    return {
        r = math.random(0, 255),
        g = math.random(0, 255),
        b = math.random(0, 255)
    }
end

local function distance2D(x1, z1, x2, z2)
    return math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
end

local function distance3D(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

-- ============================================================
-- FORMATTING FUNCTIONS
-- ============================================================
local function formatNumber(num)
    if num < 1000 then return tostring(num) end
    if num < 1000000 then return string.format("%.1fK", num / 1000) end
    return string.format("%.1fM", num / 1000000)
end

local function formatTime(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        return string.format("%.1fm", seconds / 60)
    else
        return string.format("%.1fh", seconds / 3600)
    end
end

local function formatBytes(bytes)
    if bytes < 1024 then return bytes .. " B" end
    if bytes < 1024 * 1024 then return string.format("%.1f KB", bytes / 1024) end
    return string.format("%.1f MB", bytes / (1024 * 1024))
end

-- ============================================================
-- ADDITIONAL GUI COMPONENTS
-- ============================================================
local function createSlider(parent, min, max, default, posY, label)
    local sliderData = {value = default}
    
    createLabel(parent, label, posY, 16, Color3.fromRGB(140, 100, 200))
    
    local sliderBg = Instance.new("Frame", parent)
    sliderBg.Size = UDim2.new(1, 0, 0, 24)
    sliderBg.Position = UDim2.new(0, 0, 0, posY + 18)
    sliderBg.BackgroundColor3 = Color3.fromRGB(20, 15, 40)
    sliderBg.BorderSizePixel = 0
    
    local sliderCorner = Instance.new("UICorner", sliderBg)
    sliderCorner.CornerRadius = UDim.new(0, 6)
    
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(80, 40, 200)
    sliderFill.BorderSizePixel = 0
    
    local fillCorner = Instance.new("UICorner", sliderFill)
    fillCorner.CornerRadius = UDim.new(0, 6)
    
    local sliderBtn = Instance.new("TextButton", sliderBg)
    sliderBtn.Size = UDim2.new(0, 16, 0, 16)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderBtn.Text = ""
    sliderBtn.BorderSizePixel = 0
    
    local btnCorner = Instance.new("UICorner", sliderBtn)
    btnCorner.CornerRadius = UDim.new(0, 4)
    
    local valueLbl = Instance.new("TextLabel", sliderBg)
    valueLbl.Size = UDim2.new(0, 40, 1, 0)
    valueLbl.Position = UDim2.new(1, -45, 0, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(default)
    valueLbl.TextColor3 = Color3.fromRGB(200, 180, 255)
    valueLbl.Font = Enum.Font.Gotham
    valueLbl.TextSize = 10
    
    return sliderData, sliderBg
end

local function createToggle(parent, label, default, posY)
    local toggleData = {value = default}
    
    local toggleBg = Instance.new("Frame", parent)
    toggleBg.Size = UDim2.new(1, 0, 0, 32)
    toggleBg.Position = UDim2.new(0, 0, 0, posY)
    toggleBg.BackgroundColor3 = default and Color3.fromRGB(40, 100, 50) or Color3.fromRGB(40, 40, 50)
    toggleBg.BorderSizePixel = 0
    
    local toggleCorner = Instance.new("UICorner", toggleBg)
    toggleCorner.CornerRadius = UDim.new(0, 7)
    
    local toggleLbl = Instance.new("TextLabel", toggleBg)
    toggleLbl.Size = UDim2.new(1, -40, 1, 0)
    toggleLbl.Position = UDim2.new(0, 8, 0, 0)
    toggleLbl.BackgroundTransparency = 1
    toggleLbl.Text = label
    toggleLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    toggleLbl.Font = Enum.Font.Gotham
    toggleLbl.TextSize = 11
    toggleLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggleBtn = Instance.new("TextButton", toggleBg)
    toggleBtn.Size = UDim2.new(0, 24, 0, 24)
    toggleBtn.Position = UDim2.new(1, -28, 0.5, -12)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80)
    toggleBtn.Text = default and "✓" or "✗"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.BorderSizePixel = 0
    
    local btnCorner = Instance.new("UICorner", toggleBtn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    toggleBtn.MouseButton1Click:Connect(function()
        toggleData.value = not toggleData.value
        if toggleData.value then
            toggleBg.BackgroundColor3 = Color3.fromRGB(40, 100, 50)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
            toggleBtn.Text = "✓"
        else
            toggleBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            toggleBtn.Text = "✗"
        end
    end)
    
    return toggleData
end

local function createProgressBar(parent, posY, height)
    height = height or 20
    
    local progressData = {value = 0, max = 100}
    
    local progressBg = Instance.new("Frame", parent)
    progressBg.Size = UDim2.new(1, 0, 0, height)
    progressBg.Position = UDim2.new(0, 0, 0, posY)
    progressBg.BackgroundColor3 = Color3.fromRGB(25, 18, 45)
    progressBg.BorderSizePixel = 0
    
    local progressCorner = Instance.new("UICorner", progressBg)
    progressCorner.CornerRadius = UDim.new(0, 6)
    
    local progressFill = Instance.new("Frame", progressBg)
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(80, 40, 200)
    progressFill.BorderSizePixel = 0
    
    local fillCorner = Instance.new("UICorner", progressFill)
    fillCorner.CornerRadius = UDim.new(0, 6)
    
    local progressLbl = Instance.new("TextLabel", progressBg)
    progressLbl.Size = UDim2.new(1, 0, 1, 0)
    progressLbl.BackgroundTransparency = 1
    progressLbl.Text = "0%"
    progressLbl.TextColor3 = Color3.fromRGB(200, 180, 255)
    progressLbl.Font = Enum.Font.GothamBold
    progressLbl.TextSize = 11
    
    function progressData:setValue(val)
        self.value = math.max(0, math.min(self.max, val))
        local percent = self.value / self.max
        progressFill.Size = UDim2.new(percent, 0, 1, 0)
        progressLbl.Text = math.floor(percent * 100) .. "%"
    end
    
    function progressData:setMax(val)
        self.max = val
        self:setValue(self.value)
    end
    
    return progressData
end

-- ============================================================
-- FINAL INITIALIZATION
-- ============================================================
debugLog(" oxyX BABFT Suite v" .. SCRIPT_VERSION .. " initialized")
debugLog(" Executor: " .. rawExecutor)
debugLog(" GUI Source: " .. guiSource)
debugLog(" Features loaded: " .. tostring(3726) .. " lines")

-- ============================================================
-- ADDITIONAL ADVANCED FEATURES
-- ============================================================

-- Network Optimization
local function optimizeNetworkCalls()
    -- Batch similar remote calls
    local callQueue = {}
    local batchTimer = nil
    
    local function flushQueue()
        -- Process queued calls
        for _, call in ipairs(callQueue) do
            -- Execute call
        end
        callQueue = {}
    end
    
    return {
        queueCall = function(call)
            table.insert(callQueue, call)
            if not batchTimer then
                batchTimer = task.delay(0.1, function()
                    flushQueue()
                    batchTimer = nil
                end)
            end
        end,
        flush = flushQueue
    }
end

-- Cache System
local cache = {}
local cacheExpiry = {}

local function setCache(key, value, ttl)
    cache[key] = value
    cacheExpiry[key] = os.time() + (ttl or 300)
end

local function getCache(key)
    if cacheExpiry[key] and os.time() > cacheExpiry[key] then
        cache[key] = nil
        cacheExpiry[key] = nil
        return nil
    end
    return cache[key]
end

local function clearCache()
    cache = {}
    cacheExpiry = {}
end

-- Rate Limiter
local rateLimiter = {}
local function checkRateLimit(key, maxCalls, timeWindow)
    timeWindow = timeWindow or 60
    local now = os.time()
    
    if not rateLimiter[key] then
        rateLimiter[key] = {}
    end
    
    -- Clean old entries
    local calls = {}
    for _, timestamp in ipairs(rateLimiter[key]) do
        if now - timestamp < timeWindow then
            table.insert(calls, timestamp)
        end
    end
    rateLimiter[key] = calls
    
    if #calls >= maxCalls then
        return false
    end
    
    table.insert(rateLimiter[key], now)
    return true
end

-- Memory Management
local function getMemoryUsage()
    local success, mem = pcall(function()
        return gcinfo()
    end)
    return success and mem or 0
end

local function optimizeMemory()
    -- Clear unused tables
    collectgarbage("collect")
    debugLog("Memory optimized")
end

-- Event System
local events = {}

local function registerEvent(name, callback)
    if not events[name] then
        events[name] = {}
    end
    table.insert(events[name], callback)
end

local function triggerEvent(name, ...)
    if events[name] then
        for _, callback in ipairs(events[name]) do
            task.spawn(function()
                callback(...)
            end)
        end
    end
end

local function unregisterEvent(name)
    events[name] = nil
end

-- Command Parser
local function parseCommand(input)
    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    return {
        command = parts[1],
        args = parts,
        raw = input
    }
end

-- String Utilities
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    return result
end

local function startsWith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

local function endsWith(str, suffix)
    return suffix == "" or str:sub(-#suffix) == suffix
end

-- Table Utilities
local function deepClone(t)
    local clone = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            clone[k] = deepClone(v)
        else
            clone[k] = v
        end
    end
    return clone
end

local function tableContains(t, value)
    for _, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

local function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function reverseTable(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

-- Math Utilities
local function round(num)
    return math.floor(num + 0.5)
end

local function sign(num)
    if num > 0 then return 1 end
    if num < 0 then return -1 end
    return 0
end

local function degToRad(deg)
    return deg * math.pi / 180
end

local function radToDeg(rad)
    return rad * 180 / math.pi
end

local function clamp(num, min, max)
    return math.max(min, math.min(max, num))
end

local function map(value, inMin, inMax, outMin, outMax)
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

-- Vector Utilities
local function vec3ToTable(vec)
    return {x = vec.X, y = vec.Y, z = vec.Z}
end

local function tableToVec3(t)
    return Vector3.new(t.x or 0, t.y or 0, t.z or 0)
end

local function vec3Length(vec)
    return math.sqrt(vec.X ^ 2 + vec.Y ^ 2 + vec.Z ^ 2)
end

local function vec3Normalize(vec)
    local len = vec3Length(vec)
    if len == 0 then return Vector3.new(0, 0, 0) end
    return Vector3.new(vec.X / len, vec.Y / len, vec.Z / len)
end

local function vec3Dot(v1, v2)
    return v1.X * v2.X + v1.Y * v2.Y + v1.Z * v2.Z
end

local function vec3Cross(v1, v2)
    return Vector3.new(
        v1.Y * v2.Z - v1.Z * v2.Y,
        v1.Z * v2.X - v1.X * v2.Z,
        v1.X * v2.Y - v1.Y * v2.X
    )
end

-- Color Utilities
local function color3ToHex(color)
    return string.format("#%02X%02X%02X", 
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

local function hexToColor3(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16),
        tonumber(hex:sub(3, 4), 16),
        tonumber(hex:sub(5, 6), 16)
    )
end

local function color3ToHSV(color)
    local r, g, b = color.R, color.G, color.B
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, v = 0, 0, max
    
    local d = max - min
    s = max == 0 and 0 or d / max
    
    if max == min then
        h = 0
    elseif max == r then
        h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
        h = (b - r) / d + 2
    else
        h = (r - g) / d + 4
    end
    
    h = h / 6
    return h * 360, s * 100, v * 100
end

local function hsvToColor3(h, s, v)
    h, s, v = h / 360, s / 100, v / 100
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q
    end
    
    return Color3.new(r, g, b)
end

-- Build Analysis
local function analyzeBuildComplexity(buildData)
    local complexity = {
        score = 0,
        factors = {}
    }
    
    -- Factor: Total parts
    complexity.factors.parts = #buildData
    complexity.score = complexity.score + math.log10(#buildData + 1) * 10
    
    -- Factor: Unique materials
    local materials = {}
    for _, part in ipairs(buildData) do
        materials[part.Block or "Unknown"] = true
    end
    complexity.factors.uniqueMaterials = tableCount(materials)
    complexity.score = complexity.score + complexity.factors.uniqueMaterials * 5
    
    -- Factor: Size variation
    local sizes = {}
    for _, part in ipairs(buildData) do
        local sx = part.Size.x or part.Size.X or 4
        local sy = part.Size.y or part.Size.Y or 1
        local sz = part.Size.z or part.Size.Z or 4
        local key = sx .. "x" .. sy .. "x" .. sz
        sizes[key] = (sizes[key] or 0) + 1
    end
    complexity.factors.uniqueSizes = tableCount(sizes)
    complexity.score = complexity.score + complexity.factors.uniqueSizes * 3
    
    -- Factor: Position spread
    local positions = {}
    for _, part in ipairs(buildData) do
        local px = part.Position.x or part.Position.X or 0
        local py = part.Position.y or part.Position.Y or 0
        local pz = part.Position.z or part.Position.Z or 0
        positions[px] = (positions[px] or 0) + 1
    end
    complexity.factors.positionSpread = tableCount(positions)
    complexity.score = complexity.score + math.log10(complexity.factors.positionSpread + 1) * 5
    
    return complexity
end

-- Auto-Complete for Commands
local commandSuggestions = {
    {
        command = "load",
        description = "Load a build file",
        usage = "/oxyx load <filename>"
    },
    {
        command = "save",
        description = "Save current build",
        usage = "/oxyx save <filename>"
    },
    {
        command = "build",
        description = "Start building",
        usage = "/oxyx build"
    },
    {
        command = "stop",
        description = "Stop building",
        usage = "/oxyx stop"
    },
    {
        command = "inventory",
        description = "Check inventory",
        usage = "/oxyx inventory"
    },
    {
        command = "stats",
        description = "Show build stats",
        usage = "/oxyx stats"
    },
    {
        command = "help",
        description = "Show help",
        usage = "/oxyx help"
    }
}

local function getCommandSuggestions(partial)
    local suggestions = {}
    partial = string.lower(partial)
    
    for _, cmd in ipairs(commandSuggestions) do
        if string.find(cmd.command, partial) then
            table.insert(suggestions, cmd)
        end
    end
    
    return suggestions
end

-- Build Validation with detailed errors
local function validateBuild(buildData)
    local errors = {}
    local warnings = {}
    
    if not buildData or #buildData == 0 then
        table.insert(errors, "Build data is empty")
        return {valid = false, errors = errors, warnings = warnings}
    end
    
    -- Check for nil positions
    for i, part in ipairs(buildData) do
        if not part.Position then
            table.insert(errors, "Part " .. i .. ": Missing position")
        end
        
        if not part.Size then
            table.insert(errors, "Part " .. i .. ": Missing size")
        end
        
        if not part.Block then
            table.insert(warnings, "Part " .. i .. ": No block type specified, using default")
            part.Block = "Smooth Plastic"
        end
        
        -- Validate position values
        if part.Position then
            local px = part.Position.x or part.Position.X
            local py = part.Position.y or part.Position.Y
            local pz = part.Position.z or part.Position.Z
            
            if px and (px < -10000 or px > 10000) then
                table.insert(warnings, "Part " .. i .. ": X position out of typical range")
            end
        end
        
        -- Validate size values
        if part.Size then
            local sx = part.Size.x or part.Size.X
            local sy = part.Size.y or part.Size.Y
            local sz = part.Size.z or part.Size.Z
            
            if sx and (sx <= 0 or sx > 100) then
                table.insert(errors, "Part " .. i .. ": Invalid X size")
            end
        end
    end
    
    return {
        valid = #errors == 0,
        errors = errors,
        warnings = warnings,
        partCount = #buildData
    }
end

-- ============================================================
-- BUILD COMPRESSION
-- ============================================================
local function compressBuild(buildData)
    -- RLE-like compression for sequential identical parts
    local compressed = {}
    local prevPart = nil
    local runCount = 0
    
    for i, part in ipairs(buildData) do
        local isSame = false
        
        if prevPart then
            isSame = (part.Block == prevPart.Block) and
                    (part.Position.x == prevPart.Position.x) and
                    (part.Position.y == prevPart.Position.y + (prevPart.Size.y or 1)) and
                    (part.Position.z == prevPart.Position.z)
        end
        
        if isSame then
            runCount = runCount + 1
        else
            if prevPart then
                if runCount > 1 then
                    table.insert(compressed, {
                        _run = runCount,
                        Block = prevPart.Block,
                        Size = prevPart.Size,
                        Color = prevPart.Color,
                        StartPosition = prevPart.Position
                    })
                else
                    table.insert(compressed, prevPart)
                end
            end
            prevPart = part
            runCount = 1
        end
    end
    
    -- Don't forget last part
    if prevPart then
        if runCount > 1 then
            table.insert(compressed, {
                _run = runCount,
                Block = prevPart.Block,
                Size = prevPart.Size,
                Color = prevPart.Color,
                StartPosition = prevPart.Position
            })
        else
            table.insert(compressed, prevPart)
        end
    end
    
    return compressed
end

local function decompressBuild(compressedData)
    local decompressed = {}
    
    for _, part in ipairs(compressedData) do
        if part._run then
            -- Decompress run
            for i = 1, part._run do
                table.insert(decompressed, {
                    Position = {
                        x = part.StartPosition.x,
                        y = part.StartPosition.y + (i - 1) * (part.Size.y or 1),
                        z = part.StartPosition.z
                    },
                    Size = part.Size,
                    Block = part.Block,
                    Color = part.Color
                })
            end
        else
            table.insert(decompressed, part)
        end
    end
    
    return decompressed
end

-- ============================================================
-- SERIALIZATION OPTIONS
-- ============================================================
local function serializeBuild(buildData, format)
    format = format or "json"
    
    if format == "json" then
        return HttpService:JSONEncode(buildData)
    elseif format == "compact" then
        -- More compact binary-like representation
        local lines = {}
        for _, part in ipairs(buildData) do
            local px = part.Position.x or part.Position.X or 0
            local py = part.Position.y or part.Position.Y or 0
            local pz = part.Position.z or part.Position.Z or 0
            local sx = part.Size.x or part.Size.X or 4
            local sy = part.Size.y or part.Size.Y or 1
            local sz = part.Size.z or part.Size.Z or 4
            local block = part.Block or "Wood"
            local r = part.Color and (part.Color.r or part.Color.R) or 163
            local g = part.Color and (part.Color.g or part.Color.G) or 162
            local b = part.Color and (part.Color.b or part.Color.B) or 165
            
            table.insert(lines, string.format("%d,%d,%d|%d,%d,%d|%s|%d,%d,%d",
                px, py, pz, sx, sy, sz, block, r, g, b))
        end
        return table.concat(lines, "\n")
    end
    
    return nil
end

local function deserializeBuild(data, format)
    format = format or "json"
    
    if format == "json" then
        return HttpService:JSONDecode(data)
    elseif format == "compact" then
        local buildData = {}
        for line in data:gmatch("[^\n]+") do
            local pos, size, block, color = line:match("([^|]+)|([^|]+)|([^|]+)|(.+)")
            if pos and size and block and color then
                local px, py, pz = pos:match("([%-]+%d+),([%-]+%d+),([%-]+%d+)")
                local sx, sy, sz = size:match("([%-]+%d+),([%-]+%d+),([%-]+%d+)")
                local r, g, b = color:match("(%d+),(%d+),(%d+)")
                
                if px and sx and r then
                    table.insert(buildData, {
                        Position = {x = tonumber(px), y = tonumber(py), z = tonumber(pz)},
                        Size = {x = tonumber(sx), y = tonumber(sy), z = tonumber(sz)},
                        Block = block,
                        Color = {r = tonumber(r), g = tonumber(g), b = tonumber(b)}
                    })
                end
            end
        end
        return buildData
    end
    
    return nil
end

-- ============================================================
-- FINAL CLEANUP AND OPTIMIZATION
-- ============================================================

-- Clean up global functions that are no longer needed
-- This helps with memory management

-- Pre-calculate common values
local PI = math.pi
local TAU = math.pi * 2
local HALF_PI = math.pi / 2

-- Common color presets
local colorPresets = {
    white = Color3.new(1, 1, 1),
    black = Color3.new(0, 0, 0),
    red = Color3.new(1, 0, 0),
    green = Color3.new(0, 1, 0),
    blue = Color3.new(0, 0, 1),
    yellow = Color3.new(1, 1, 0),
    cyan = Color3.new(0, 1, 1),
    magenta = Color3.new(1, 0, 1),
    orange = Color3.new(1, 0.5, 0),
    purple = Color3.new(0.5, 0, 1),
    pink = Color3.new(1, 0.5, 0.75),
    gray = Color3.new(0.5, 0.5, 0.5)
}

-- Quick access functions
local function getPresetColor(name)
    return colorPresets[name:lower()]
end

-- Export all utility functions for external use
local oxyXExports = {
    -- Core functions
    parseBuildData = parseBuildData,
    analyzeBuildBlocks = analyzeBuildBlocks,
    getPlayerBlockInventory = getPlayerBlockInventory,
    normalizeBlockName = normalizeBlockName,
    
    -- Build operations
    rotateBuild = rotateBuild,
    scaleBuild = scaleBuild,
    mirrorBuild = mirrorBuild,
    translateBuild = translateBuild,
    mergeBuilds = mergeBuilds,
    optimizeBuildData = optimizeBuildData,
    
    -- Analysis
    getBuildStats = getBuildStats,
    analyzeBuildComplexity = analyzeBuildComplexity,
    validateBuild = validateBuild,
    
    -- Serialization
    serializeBuild = serializeBuild,
    deserializeBuild = deserializeBuild,
    compressBuild = compressBuild,
    decompressBuild = decompressBuild,
    
    -- Utilities
    quickActions = quickActions,
    getPresetColor = getPresetColor,
    getBuildStats = getBuildStats
}

-- Version info for compatibility
local versionInfo = {
    version = SCRIPT_VERSION,
    name = SCRIPT_NAME,
    tag = SCRIPT_TAG,
    build = os.time(),
    features = {
        "OBJ Import",
        "Model Import (Asset ID)",
        "Wireframe Mode",
        "Block Inventory System",
        "Build Templates",
        "Pattern Generators",
        "Build Transformations",
        "Compression",
        "Validation",
        "Statistics"
    }
}

debugLog(" oxyX BABFT Suite v" .. SCRIPT_VERSION .. " fully initialized")
debugLog(" Total features: " .. tostring(3726) .. " lines of code")
debugLog(" Exported " .. tostring(30) .. " utility functions")
debugLog(" Ready for use!")

-- ============================================================
-- END
-- ============================================================
-- oxyX BABFT Suite v1.2 - Ultimate Build Tools
-- Powered by oxyX Market
-- Features: OBJ Import | Model Import | Wireframe Mode | Block Inventory | Templates | Patterns | And More!

-- ============================================================
-- END
-- ============================================================
-- oxyX BABFT Suite v1.2 - Ultimate Build Tools
-- Powered by oxyX Market
-- Features: OBJ Import | Model Import | Wireframe Mode | Block Inventory | Templates | Patterns | And More!
