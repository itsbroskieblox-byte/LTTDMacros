--//========================
-- LOADER (CLEAN REWRITE)
--//========================

local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

print("[LOADER] Booting")

--//========================
-- SERVICES
--//========================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

--//========================
-- QUEUE
--//========================
local queue =
    queue_on_teleport or
    (syn and syn.queue_on_teleport) or
    queueonteleport

getgenv()._LOADER_QUEUED = getgenv()._LOADER_QUEUED or false

local function queueSelf(path)
    if not queue or getgenv()._LOADER_QUEUED then return end
    getgenv()._LOADER_QUEUED = true

    local src = string.format([[
        getgenv().SelectedMacroPath = "%s"
        loadstring(game:HttpGet("%s"))()
    ]], path, BASE .. "loader.lua")

    pcall(function()
        queue(src)
        print("[LOADER] Queued")
    end)
end

--//========================
-- FETCH
--//========================
local function fetch(path)
    local urls = {
        BASE .. path,
        BASE:gsub("raw.githubusercontent.com","cdn.jsdelivr.net/gh")
            :gsub("/main/","@main/") .. path
    }

    for _, url in ipairs(urls) do
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and res and #res > 0 then
            return res
        end
    end

    warn("[LOADER] Fetch failed:", path)
    return nil
end

--//========================
-- EXEC
--//========================
local function exec(code)
    local fn = loadstring(code)
    if not fn then
        warn("[LOADER] Compile failed")
        return false
    end

    local ok, err = pcall(fn)
    if not ok then
        warn("[LOADER] Runtime error:", err)
        return false
    end

    return true
end

--//========================
-- MACRO LOAD
--//========================
local macroPath = getgenv().SelectedMacroPath
if not macroPath then
    warn("[LOADER] No macro path")
    return
end

print("[LOADER] Macro:", macroPath)

local macroCode = fetch(macroPath)
if not macroCode then return end

local macro
do
    local ok, res = pcall(function()
        return loadstring(macroCode)()
    end)

    if not ok or not res then
        warn("[LOADER] Macro failed")
        return
    end

    macro = res
end

queueSelf(macroPath)

--//========================
-- LOBBY
--//========================
if game.PlaceId == LOBBY_PLACE_ID then
    print("[LOADER] Lobby")

    local lobby = workspace:WaitForChild("NewLobby", 10)
    local elevators = lobby and lobby:WaitForChild("Elevators", 10)

    if not elevators then
        warn("[LOADER] No elevators")
        return
    end

    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    for _, e in ipairs(elevators:GetChildren()) do
        local screen = e:FindFirstChild("Screen")
        local gui = screen and screen:FindFirstChildWhichIsA("SurfaceGui")
        local title = gui and gui:FindFirstChild("Title")

        if screen and title and title.Text:find("0/") then
            print("[LOADER] Using elevator:", e.Name)

            -- use Screen as center
            root.CFrame = screen.CFrame + Vector3.new(0, 3, 0)

            local events = RS:FindFirstChild("Events")
            local remote = events and events:FindFirstChild("StartElevator")

            if remote then
                remote:FireServer(e.Name)
                print("[LOADER] Fired:", e.Name)
            else
                warn("[LOADER] Remote missing")
            end

            break
        end
    end

    return
end

--//========================
-- GAME
--//========================
repeat task.wait() until game:IsLoaded()

print("[LOADER] In-game")

local engineCode = fetch("engine.lua")
if not engineCode then return end

if not exec(engineCode) then return end

if getgenv().MacroEngine and macro then
    print("[LOADER] Running macro")
    pcall(function()
        getgenv().MacroEngine.run(macro)
    end)
else
    warn("[LOADER] MacroEngine missing")
end