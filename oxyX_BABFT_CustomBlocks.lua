-- ============================================================
-- oxyX BABFT Custom Blocks Extension
-- Allows using custom blocks/materials when loading builds
-- Compatible with oxyX BABFT Suite v2.0
-- ============================================================

-- Custom Block Library - Add your unlocked blocks here
local customBlockLibrary = {
    -- Example blocks (user can customize these)
    {name = "Default Block", material = "SmoothPlastic", shape = "Block", color = {r=163, g=162, b=165}},
    {name = "Wood", material = "Wood", shape = "Block", color = {r=163, g=162, b=165}},
    {name = "Wood Plank", material = "Wood", shape = "Block", color = {r=143, g=130, b=100}},
    {name = "Metal", material = "Metal", shape = "Block", color = {r=192, g=192, b=192}},
    {name = "Concrete", material = "Slate", shape = "Block", color = {r=100, g=100, b=100}},
    {name = "Brick", material = "Brick", shape = "Block", color = {r=196, g=40, b=28}},
    {name = "Ice", material = "Ice", shape = "Block", color = {r=133, g=133, b=163}},
    {name = "Neon", material = "Neon", shape = "Block", color = {r=0, g=255, b=255}},
    {name = "Gold", material = "DiamondPlate", shape = "Block", color = {r=212, g=175, b=55}},
    {name = "Grass", material = "Grass", shape = "Block", color = {r=67, g=205, b=128}},
    {name = "Sand", material = "Sand", shape = "Block", color = {r=237, g=201, b=175}},
    {name = "Stone", material = "Cobblestone", shape = "Block", color = {r=128, g=128, b=128}},
}

-- Current selected custom block
local selectedCustomBlock = nil
local useCustomBlock = false

-- Function to create custom block selector UI
local function createCustomBlockSelector(parent, yPosition)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -20, 0, 80)
    container.Position = UDim2.new(0, 10, 0, yPosition)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    container.BorderSizePixel = 0

    local corner = Instance.new("UICorner", container)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(80, 60, 140)
    stroke.Thickness = 1

    -- Title
    local title = Instance.new("TextLabel", container)
    title.Size = UDim2.new(1, -20, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🎨 Custom Block Override:"
    title.TextColor3 = Color3.fromRGB(160, 120, 220)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Enable checkbox
    local enableCheck = Instance.new("TextButton", container)
    enableCheck.Size = UDim2.new(0, 20, 0, 20)
    enableCheck.Position = UDim2.new(0, 10, 0, 28)
    enableCheck.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
    enableCheck.Text = "☐"
    enableCheck.TextColor3 = Color3.fromRGB(200, 200, 220)
    enableCheck.Font = Enum.Font.GothamBold
    enableCheck.TextSize = 14
    enableCheck.AutoButtonColor = false

    local enableLabel = Instance.new("TextLabel", container)
    enableLabel.Size = UDim2.new(0, 150, 0, 20)
    enableLabel.Position = UDim2.new(0, 35, 0, 28)
    enableLabel.BackgroundTransparency = 1
    enableLabel.Text = "Use Custom Block"
    enableLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    enableLabel.Font = Enum.Font.Gotham
    enableLabel.TextSize = 11
    enableLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Block selector dropdown
    local dropdownBtn = Instance.new("TextButton", container)
    dropdownBtn.Size = UDim2.new(0, 180, 0, 25)
    dropdownBtn.Position = UDim2.new(0, 10, 0, 52)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    dropdownBtn.Text = "Select Block..."
    dropdownBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 11
    dropdownBtn.AutoButtonColor = false
    dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left

    local dropdownCorner = Instance.new("UICorner", dropdownBtn)
    dropdownCorner.CornerRadius = UDim.new(0, 6)

    local dropdownStroke = Instance.new("UIStroke", dropdownBtn)
    dropdownStroke.Color = Color3.fromRGB(100, 60, 180)
    dropdownStroke.Thickness = 1

    -- Selected block color preview
    local colorPreview = Instance.new("Frame", container)
    colorPreview.Size = UDim2.new(0, 25, 0, 25)
    colorPreview.Position = UDim2.new(0, 195, 0, 52)
    colorPreview.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
    colorPreview.BorderSizePixel = 0

    local previewCorner = Instance.new("UICorner", colorPreview)
    previewCorner.CornerRadius = UDim.new(0, 4)

    -- Enable/Disable custom blocks
    enableCheck.MouseButton1Click:Connect(function()
        useCustomBlock = not useCustomBlock
        if useCustomBlock then
            enableCheck.Text = "☑"
            enableCheck.BackgroundColor3 = Color3.fromRGB(80, 60, 140)
        else
            enableCheck.Text = "☐"
            enableCheck.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
        end
    end)

    -- Dropdown functionality
    local dropdownOpen = false
    local dropdownFrame = nil

    dropdownBtn.MouseButton1Click:Connect(function()
        if dropdownOpen and dropdownFrame then
            dropdownFrame:Destroy()
            dropdownOpen = false
            return
        end

        dropdownOpen = true
        dropdownFrame = Instance.new("Frame", container)
        dropdownFrame.Size = UDim2.new(0, 180, 0, math.min(#customBlockLibrary * 25, 150))
        dropdownFrame.Position = UDim2.new(0, 10, 0, 77)
        dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
        dropdownFrame.BorderSizePixel = 0
        dropdownFrame.ZIndex = 100

        local scroll = Instance.new("ScrollingFrame", dropdownFrame)
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 4
        scroll.ZIndex = 100

        local layout = Instance.new("UIListLayout", scroll)
        layout.Padding = UDim.new(0, 2)
        layout.ZIndex = 100

        for i, block in ipairs(customBlockLibrary) do
            local option = Instance.new("TextButton", scroll)
            option.Size = UDim2.new(1, 0, 0, 23)
            option.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
            option.Text = "  " .. block.name
            option.TextColor3 = Color3.fromRGB(180, 180, 200)
            option.Font = Enum.Font.Gotham
            option.TextSize = 11
            option.TextXAlignment = Enum.TextXAlignment.Left
            option.AutoButtonColor = false
            option.ZIndex = 100

            local optCorner = Instance.new("UICorner", option)
            optCorner.CornerRadius = UDim.new(0, 4)
            optCorner.ZIndex = 100

            option.MouseButton1Click:Connect(function()
                selectedCustomBlock = block
                dropdownBtn.Text = "  " .. block.name
                colorPreview.BackgroundColor3 = Color3.fromRGB(block.color.r, block.color.g, block.color.b)
                dropdownFrame:Destroy()
                dropdownOpen = false
            end)

            option.MouseEnter:Connect(function()
                option.BackgroundColor3 = Color3.fromRGB(60, 45, 90)
            end)

            option.MouseLeave:Connect(function()
                option.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
            end
        end)

        scroll.CanvasSize = UDim2.new(0, 0, 0, #customBlockLibrary * 25)
    end)

    -- Return control functions
    return {
        getCustomBlock = function()
            if useCustomBlock and selectedCustomBlock then
                return selectedCustomBlock
            end
            return nil
        end,
        isEnabled = function()
            return useCustomBlock
        end,
        addBlock = function(blockData)
            table.insert(customBlockLibrary, blockData)
        end,
        getContainer = function()
            return container
        end
    }
end

-- Function to override build data with custom block
local function applyCustomBlockToBuild(buildData)
    if not useCustomBlock or not selectedCustomBlock then
        return buildData
    end

    local modifiedData = {}
    for i, part in ipairs(buildData) do
        local modified = type(part) == "table" and part or {}
        
        -- Override with custom block properties
        modified.material = selectedCustomBlock.material
        modified.Material = selectedCustomBlock.material
        modified.shape = selectedCustomBlock.shape
        modified.Shape = selectedCustomBlock.shape
        modified.color = selectedCustomBlock.color
        modified.Color = selectedCustomBlock.color
        
        table.insert(modifiedData, modified)
    end

    return modifiedData
end

-- Function to add custom block selector to existing AutoBuild
-- Call this after the main script loads to add the custom block feature
local function integrateWithAutoBuild(mainScript)
    -- This function is meant to be called from the main script
    -- It will add the custom block controls to the AutoBuild page
    return {
        createSelector = createCustomBlockSelector,
        applyCustomBlock = applyCustomBlockToBuild,
        library = customBlockLibrary
    }
end

-- Export functions
return {
    createCustomBlockSelector = createCustomBlockSelector,
    applyCustomBlockToBuild = applyCustomBlockToBuild,
    integrateWithAutoBuild = integrateWithAutoBuild,
    customBlockLibrary = customBlockLibrary,
    
    -- Helper to add new blocks to library
    addCustomBlock = function(name, material, shape, r, g, b)
        table.insert(customBlockLibrary, {
            name = name,
            material = material,
            shape = shape,
            color = {r = r, g = g, b = b}
        })
    end,
    
    -- Get/Set selected block
    setSelectedBlock = function(block)
        selectedCustomBlock = block
    end,
    
    getSelectedBlock = function()
        return selectedCustomBlock
    end,
    
    -- Enable/Disable custom blocks
    enableCustomBlocks = function(enabled)
        useCustomBlock = enabled
    end,
    
    isCustomBlocksEnabled = function()
        return useCustomBlock
    end
}
