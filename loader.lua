--//========================
--// CONFIG
--//========================
local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

print("[LOADER] Started")

--//========================
--// QUEUE SAFE
--//========================
local queue =
    (type(queue_on_teleport) == "function" and queue_on_teleport) or
    (syn and type(syn.queue_on_teleport) == "function" and syn.queue_on_teleport) or
    (type(queueonteleport) == "function" and queueonteleport)

-- prevent infinite requeue spam
getgenv()._LOADER_QUEUED = getgenv()._LOADER_QUEUED or false

--//========================
--// HELPERS
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
    if not ok then
        warn("[LOADER] Exec error:", err)
    end

    return ok
end

--//========================
--// GET MACRO PATH
--//========================
local path = getgenv().SelectedMacroPath
if not path then
    warn("[LOADER] No macro path")
    return
end

print("[LOADER] Macro:", path)

--//========================
--// LOAD MACRO
--//========================
local macroCode = fetch(path)
if not macroCode then return end

local macro = loadstring(macroCode)()
if not macro then
    warn("[LOADER] Macro compile failed")
    return
end

--//========================
--// REQUEUE (ONLY ONCE)
--//========================
if queue and not getgenv()._LOADER_QUEUED then
    getgenv()._LOADER_QUEUED = true

    local q = string.format([[
        getgenv().SelectedMacroPath = "%s"
        loadstring(game:HttpGet("%s"))()
    ]], path, BASE.."loader.lua")

    pcall(function()
        queue(q)
        print("[LOADER] Queued for teleport")
    end)
end

print("[LOADER] PlaceId:", game.PlaceId)

--//========================
--// LOBBY LOGIC (FILTERED)
--//========================
if game.PlaceId == LOBBY_PLACE_ID then
    print("[LOADER] In lobby")

    local RS = game:GetService("ReplicatedStorage")
    local LP = game:GetService("Players").LocalPlayer

    local function getChar()
        return LP.Character or LP.CharacterAdded:Wait()
    end

    -- build lookup table from macro settings
    local function toLookup(list)
        local t = {}
        for _,v in ipairs(list or {}) do
            t[v] = true
        end
        return t
    end

    local validElevators = toLookup(macro.Settings and macro.Settings.Elevators)

    local startTime = tick()

    while tick() - startTime < 60 do
        local lobby = workspace:FindFirstChild("NewLobby")

        if lobby and lobby:FindFirstChild("Elevators") then
            for _,e in ipairs(lobby.Elevators:GetChildren()) do

                -- ✅ FILTER HERE
                if next(validElevators) and not validElevators[e.Name] then
                    continue
                end

                local screen = e:FindFirstChild("Screen")
                local gui = screen and screen:FindFirstChild("StatusGui")
                local title = gui and gui:FindFirstChild("Title")

                if title and title.Text == "0/5" then
                    local char = getChar()

                    local old = char:GetPivot()
                    local target = screen.CFrame * CFrame.new(0,3,0)

                    -- move in
                    for i = 1,6 do
                        char:PivotTo(target)
                        task.wait()
                    end

                    RS.Events.StartElevator:FireServer(e.Name)
                    print("[LOADER] Entered elevator:", e.Name)

                    -- return instantly
                    char:PivotTo(old)

                    task.wait(8)
                    break
                end
            end
        end

        task.wait(1)
    end

    print("[LOADER] Lobby loop ended")
    return
end

--//========================
--// GAME LOGIC
--//========================
repeat task.wait() until game:IsLoaded()

print("[LOADER] Loading engine")

local engineCode = fetch("engine.lua")
if not engineCode then
    warn("[LOADER] Engine fetch failed")
    return
end

local ok = exec(engineCode)
if not ok then
    warn("[LOADER] Engine execution failed")
    return
end

task.wait(0.5)

if getgenv().MacroEngine and getgenv().MacroEngine.run then
    print("[LOADER] Running macro")
    getgenv().MacroEngine.run(macro)
else
    warn("[LOADER] MacroEngine missing")
end