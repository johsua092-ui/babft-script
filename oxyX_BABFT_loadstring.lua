-- oxyX BABFT - loadstring Version
-- Cara penggunaan:
-- 1. Paste build data JSON kamu di bawah ini (ganti "ISI_BUILD_DATA_DISINI")

local BUILD_DATA_JSON = 'ISI_BUILD_DATA_DISINI'

-- ============================================================
-- SERVICES
-- ============================================================
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ============================================================
-- JSON PARSING (loadstring)
-- ============================================================
local function parseBuildData(jsonString)
    -- Try loadstring to parse JSON
    local success, result = pcall(function()
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
    
    -- Rotation
    if data.rotation or data.Rotation then
        local rot = data.rotation or data.Rotation
        if type(rot) == "table" then
            part.CFrame = CFrame.Angles(
                math.rad(rot.x or 0),
                math.rad(rot.y or 0),
                math.rad(rot.z or 0)
            ) + part.Position
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
    
    part.Anchored = data.anchored ~= false
    part.Parent = parent
    
    return part
end

local function buildFromData(buildData, parent)
    parent = parent or Workspace
    local partCount = 0
    
    if type(buildData) == "table" then
        local parts = buildData.parts or buildData.Parts or buildData.build or buildData.Build or buildData
        for _, partData in ipairs(parts) do
            createPart(partData, parent)
            partCount = partCount + 1
        end
    end
    
    return partCount
end

-- ============================================================
-- MAIN
-- ============================================================
local function main()
    if BUILD_DATA_JSON == 'ISI_BUILD_DATA_DISINI' or BUILD_DATA_JSON == '' then
        warn("[oxyX] ERROR: Please paste your build JSON data in BUILD_DATA_JSON variable!")
        return
    end
    
    print("[oxyX] Parsing build data...")
    local buildData = parseBuildData(BUILD_DATA_JSON)
    
    if not buildData then
        warn("[oxyX] ERROR: Could not parse build data!")
        return
    end
    
    print("[oxyX] Building parts...")
    local partCount = buildFromData(buildData)
    print("[oxyX] SUCCESS! Built " .. partCount .. " parts!")
end

main()
