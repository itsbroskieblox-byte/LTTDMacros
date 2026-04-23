--//========================
-- LOADER (REWRITE - STABLE)
--//========================
local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

print("[LOADER] Started")

--//========================
-- QUEUE
--//========================
local queue =
    queue_on_teleport or
    (syn and syn.queue_on_teleport) or
    queueonteleport

getgenv()._LOADER_QUEUED = getgenv()._LOADER_QUEUED or false

--//========================
-- FETCH
--//========================
local function fetch(path)
    local urls = {
        BASE..path,
        BASE:gsub("raw.githubusercontent.com","cdn.jsdelivr.net/gh"):gsub("/main/","@main/")..path
    }

    for _,url in ipairs(urls) do
        local ok,res = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and res then return res end
    end

    warn("[LOADER] Fetch failed:", path)
    return nil
end

local function exec(code)
    local fn = loadstring(code)
    if not fn then return false end

    local ok,err = pcall(fn)
    if not ok then warn(err) end

    return ok
end

--//========================
-- GET MACRO
--//========================
local path = getgenv().SelectedMacroPath
if not path then
    warn("[LOADER] No macro path")
    return
end

print("[LOADER] Macro:", path)

local code = fetch(path)
if not code then return end

local macro = loadstring(code)()
if not macro then
    warn("[LOADER] Macro failed")
    return
end

--//========================
-- REQUEUE
--//========================
if queue and not getgenv()._LOADER_QUEUED then
    getgenv()._LOADER_QUEUED = true

    local q = string.format([[
        getgenv().SelectedMacroPath = "%s"
        loadstring(game:HttpGet("%s"))()
    ]], path, BASE.."loader.lua")

    pcall(function()
        queue(q)
        print("[LOADER] Queued")
    end)
end

--//========================
-- LOBBY
--//========================
if game.PlaceId == LOBBY_PLACE_ID then
    print("[LOADER] Lobby")

    local RS = game:GetService("ReplicatedStorage")
    local LP = game:GetService("Players").LocalPlayer

    local lobby = workspace:WaitForChild("NewLobby", 10)
    local elevators = lobby and lobby:WaitForChild("Elevators", 10)

    if not elevators then return end

    for _,e in ipairs(elevators:GetChildren()) do
        local screen = e:FindFirstChild("Screen")
        local gui = screen and screen:FindFirstChildWhichIsA("SurfaceGui")
        local title = gui and gui:FindFirstChild("Title")

        if title and title.Text:find("0/") then
            RS.Events.StartElevator:FireServer(e.Name)
            print("[LOADER] Entered:", e.Name)
            break
        end
    end

    return
end

--//========================
-- GAME
--//========================
repeat task.wait() until game:IsLoaded()

local engineCode = fetch("engine.lua")
if not engineCode then return end

if not exec(engineCode) then return end

task.wait(0.3)

if getgenv().MacroEngine then
    getgenv().MacroEngine.run(macro)
end