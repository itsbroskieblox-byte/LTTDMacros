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

local function normalize(str)
    return tostring(str):gsub("%s+", ""):lower()
end

--//========================
--// GET MACRO
--//========================
local path = getgenv().SelectedMacroPath
if not path then
    warn("[LOADER] No macro path")
    return
end

print("[LOADER] Macro:", path)

local macroCode = fetch(path)
if not macroCode then return end

local macro = loadstring(macroCode)()
if not macro then
    warn("[LOADER] Macro compile failed")
    return
end

--//========================
--// BUILD ELEVATOR PRIORITY
--//========================
local priority = {}
for i,v in ipairs((macro.Settings and macro.Settings.Elevators) or {}) do
    priority[normalize(v)] = i
end

local function getPriority(name)
    return priority[normalize(name)] or math.huge
end

--//========================
--// REQUEUE (ONCE)
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
--// LOBBY LOGIC
--//========================
if game.PlaceId == LOBBY_PLACE_ID then
    print("[LOADER] In lobby")

    local RS = game:GetService("ReplicatedStorage")
    local LP = game:GetService("Players").LocalPlayer

    local function getChar()
        return LP.Character or LP.CharacterAdded:Wait()
    end

    -- wait for lobby properly
    local lobby = workspace:WaitForChild("NewLobby", 10)
    local elevatorsFolder = lobby and lobby:WaitForChild("Elevators", 10)

    if not elevatorsFolder then
        warn("[LOADER] Elevators not found")
        return
    end

    local startTime = tick()

    while tick() - startTime < 60 do
        local elevators = elevatorsFolder:GetChildren()

        -- SORT (priority first, fallback numeric)
        table.sort(elevators, function(a, b)
            local pa = getPriority(a.Name)
            local pb = getPriority(b.Name)

            if pa ~= pb then
                return pa < pb
            end

            local na = tonumber(string.match(a.Name, "%d+")) or 0
            local nb = tonumber(string.match(b.Name, "%d+")) or 0
            return na < nb
        end)

        for _,e in ipairs(elevators) do
            print("[DEBUG] Checking:", e.Name)

            local screen = e:FindFirstChild("Screen") or e:FindFirstChildWhichIsA("BasePart")
            local gui = screen and (screen:FindFirstChildWhichIsA("SurfaceGui") or screen:FindFirstChildWhichIsA("BillboardGui"))
            local title = gui and gui:FindFirstChild("Title")

            if title and string.find(title.Text, "0/5") then
                print("[LOADER] Found empty:", e.Name)

                local char = getChar()
                local old = char:GetPivot()
                local target = screen.CFrame * CFrame.new(0,3,0)

                -- move reliably
                for i = 1,10 do
                    char:PivotTo(target)
                    task.wait(0.1)
                end

                RS.Events.StartElevator:FireServer(e.Name)
                print("[LOADER] Attempted:", e.Name)

                char:PivotTo(old)

                task.wait(3)
                break
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