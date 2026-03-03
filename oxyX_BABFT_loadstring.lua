--[[
 oxyX BABFT Suite v1.2 - LOADSTRING VERSION
 Compatible: Xeno / Velocity / Fluxus / Synapse / Hydrogen / etc

 Cara penggunaan:
 1. Copy semua kode ini
 2. Paste ke executor kamu (Xeno/Velocity)
 3. Execute!
]]

local SCRIPT_VERSION = "1.2.0"
local RAW_URL = "https://raw.githubusercontent.com/johsua092-ui/babft-script/refs/heads/main/oxyX_BABFT.lua"

-- Check if already loaded
if _G.oxyX_BABFT_Loaded then
    warn("[oxyX BABFT] Script already loaded! Re-executing...")
end

-- Main loadstring
local function loadBabft()
    local success, result = pcall(function()
        -- Try HTTP GET first
        if game.HttpGet then
            local scriptContent = game:HttpGet(RAW_URL)
            if scriptContent and #scriptContent > 1000 then
                local loadFn = loadstring(scriptContent)
                if loadFn then
                    loadFn()
                    _G.oxyX_BABFT_Loaded = true
                    return true
                end
            end
        end
        -- Fallback: Try regular loadstring with embedded code
        error("HTTP Get not available")
    end)
    
    if not success then
        warn("[oxyX BABFT] Error: " .. tostring(result))
    end
end

loadBabft()
