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

-- Debug function
local function debugPrint(...)
    local msg = ""
    for i, v in ipairs({...}) do
        msg = msg .. tostring(v) .. " "
    end
    print("[oxyX DEBUG] " .. msg)
end

debugPrint("Starting loadstring v" .. SCRIPT_VERSION)

-- Check if already loaded
if _G.oxyX_BABFT_Loaded then
    warn("[oxyX BABFT] Script already loaded! Re-executing...")
end

-- Main loadstring
local function loadBabft()
    debugPrint("Fetching script from GitHub...")
    
    local success, result = pcall(function()
        -- Try HTTP GET first
        if game.HttpGet then
            local scriptContent = game:HttpGet(RAW_URL)
            debugPrint("Got content, length: " .. #scriptContent)
            
            if scriptContent and #scriptContent > 1000 then
                debugPrint("Executing loadstring...")
                local loadFn, err = loadstring(scriptContent)
                
                if loadFn then
                    debugPrint("Running script...")
                    loadFn()
                    _G.oxyX_BABFT_Loaded = true
                    debugPrint("Script loaded successfully!")
                    return true
                else
                    error("loadstring error: " .. tostring(err))
                end
            else
                error("Script content too short: " .. tostring(#scriptContent))
            end
        end
        error("HTTP Get not available")
    end)
    
    if success then
        debugPrint("Done!")
    else
        warn("[oxyX BABFT] Error: " .. tostring(result))
    end
end

loadBabft()
