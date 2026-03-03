-- oxyX BABFT - Direct Loader (No GUI)
-- Edit FILE_NAME di bawah ini dengan nama file .build kamu
-- Contoh: local FILE_NAME = "house.build"

local FILE_NAME = " UNTUK NAMA FILE DI SINI"

-- ============================================================
-- SERVICES
-- ============================================================
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ============================================================
-- FILE READING
-- ============================================================
local function readBuildFile(filename)
    local content = nil
    pcall(function()
        if readfile then
            content = readfile(filename)
        end
    end)
    return content
end

local function parseBuildData(jsonString)
    local success, result = pcall(function()
        -- Try HttpService JSON decode first
        if HttpService and HttpService.JSONDecode then
            return HttpService:JSONDecode(jsonString)
        end
    end)
    
    if success and result then
        return result
    end
    
    -- Fallback: try loadstring for older executors
    success, result = pcall(function()
        return loadstring("return " .. jsonString)()
    end)
    
    if success then
        return result
    end
    
    return nil
end

-- ============================================================
-- BUILD FUNCTIONS
-- ============================================================
local function createPart(data, parent)
    local part = Instance.new("Part")
    part.Name = data.name or "Part"
    
    -- Position
    if data.position or data.pos or data.cframe then
        local pos = data.position or data.pos or data.cframe
        if type(pos) == "table" then
            part.Position = Vector3.new(pos.x or pos[1] or 0, pos.y or pos[2] or 0, pos.z or pos[3] or 0)
        elseif type(pos) == "string" then
            -- CFrame string format
            local x, y, z = pos:match("(%S+),%s*(%S+),%s*(%S+)")
            part.Position = Vector3.new(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
        end
    else
        part.Position = Vector3.new(0, 0, 0)
    end
    
    -- Size
    if data.size or data.Size then
        local sz = data.size or data.Size
        if type(sz) == "table" then
            part.Size = Vector3.new(sz.x or sz[1] or 4, sz.y or sz[2] or 1, sz.z or sz[3] or 4)
        end
    else
        part.Size = Vector3.new(4, 1, 4)
    end
    
    -- Rotation (CFrame)
    if data.rotation or data.Rotation or data.cframe then
        local rot = data.rotation or data.Rotation or data.cframe
        if type(rot) == "table" then
            if rot[0] then -- CFrame angles format
                part.CFrame = CFrame.new(part.Position) * CFrame.Angles(rot[0] or 0, rot[1] or 0, rot[2] or 0)
            elseif rot.x and rot.y and rot.z then
                part.CFrame = CFrame.Angles(
                    math.rad(rot.x or 0),
                    math.rad(rot.y or 0),
                    math.rad(rot.z or 0)
                ) + part.Position
            end
        end
    end
    
    -- Material
    if data.material or data.Material then
        local mat = data.material or data.Material
        if MaterialService and pcall(function() return Enum.Material[mat] end) then
            part.Material = Enum.Material[mat]
        end
    end
    
    -- Color
    if data.color or data.Color then
        local col = data.color or data.Color
        if type(col) == "table" then
            part.Color = Color3.new(
                (col.r or col.R or 163) / 255,
                (col.g or col.G or 162) / 255,
                (col.b or col.B or 165) / 255
            )
        end
    end
    
    -- Anchored
    part.Anchored = data.anchored ~= false
    
    -- Parent
    part.Parent = parent
    
    return part
end

local function buildFromData(buildData, parent)
    parent = parent or Workspace
    
    local partCount = 0
    
    if type(buildData) == "table" then
        -- Check if it's a wrapped format
        if buildData.parts or buildData.Parts or buildData.build or buildData.Build then
            local parts = buildData.parts or buildData.Parts or buildData.build or buildData.Build
            for _, partData in ipairs(parts) do
                createPart(partData, parent)
                partCount = partCount + 1
            end
        else
            -- Direct array of parts
            for _, partData in ipairs(buildData) do
                createPart(partData, parent)
                partCount = partCount + 1
            end
        end
    end
    
    return partCount
end

-- ============================================================
-- MAIN EXECUTION
-- ============================================================
local function main()
    -- Check if filename is set
    local filename = FILE_NAME
    if filename == " UNTUK NAMA FILE DI SINI" or filename == "" then
        warn("[oxyX] ERROR: Please set FILE_NAME at the top of the script!")
        return
    end
    
    print("[oxyX] Loading build from: " .. filename)
    
    -- Read file
    local content = readBuildFile(filename)
    if not content then
        warn("[oxyX] ERROR: Could not read file: " .. filename)
        return
    end
    
    print("[oxyX] Parsing build data...")
    
    -- Parse data
    local buildData = parseBuildData(content)
    if not buildData then
        warn("[oxyX] ERROR: Could not parse build file!")
        return
    end
    
    print("[oxyX] Building parts...")
    
    -- Build
    local partCount = buildFromData(buildData)
    
    print("[oxyX] SUCCESS! Built " .. partCount .. " parts!")
end

-- Run
main()
