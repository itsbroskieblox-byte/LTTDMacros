local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"

local function fetch(p)
    return game:HttpGet(BASE..p)
end

local fn = loadstring(fetch(getgenv().SelectedMacroPath))
local macro = fn()

if getgenv().MacroEngine then
    getgenv().MacroEngine.run(macro)
end