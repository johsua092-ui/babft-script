--[[
 oxyX BABFT Suite v1.2 - LOADSTRING VERSION
 Compatible: Xeno / Velocity / Fluxus / Synapse / Hydrogen / etc

 Cara penggunaan:
 1. Copy semua kode ini
 2. Paste ke executor kamu (Xeno/Velocity)
 3. Execute!
]]

local SCRIPT_VERSION = "1.2.0"
local RAW_URL = "https://raw.githubusercontent.com/johsua092-ui/babft-script/main/oxyX_BABFT.lua"

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
    debugPrint("Starting main load function...")
    
    -- Test if game:HttpGet works
    debugPrint("Testing game.HttpGet availability...")
    if not game.HttpGet then
        warn("[oxyX] game.HttpGet is nil - checking alternatives...")
    else
        debugPrint("game.HttpGet is available")
    end
    
    local success, result = pcall(function()
        debugPrint("Attempting HTTP GET to: " .. RAW_URL)
        local scriptContent = game:HttpGet(RAW_URL)
        debugPrint("HTTP GET completed!")
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
        debugPrint("Load function completed!")
    else
        warn("[oxyX BABFT] Error: " .. tostring(result))
        warn("[oxyX] If you see no debug output above, HTTP may be blocked or failing.")
    end
end

-- Try to load with delay in case game hasn't fully loaded
task.delay(0.5, function()
    debugPrint("Executing loadBabft() after delay...")
    loadBabft()
end)
