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

[...817 lines omitted...]

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
