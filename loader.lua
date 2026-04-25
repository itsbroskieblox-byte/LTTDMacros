--//========================
-- LOADER (FIXED EXECUTION FLOW)
--//========================

local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

print("[LOADER] Start")

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- QUEUE RESOLVE
local queue =
    queue_on_teleport or
    (syn and syn.queue_on_teleport) or
    queueonteleport

getgenv()._LOADER_QUEUED = getgenv()._LOADER_QUEUED or false

local function safeQueue()
    if not queue then
        warn("[LOADER] No queue function")
        return
    end
    if getgenv()._LOADER_QUEUED then return end
    getgenv()._LOADER_QUEUED = true

    print("[LOADER] Queueing self")

    local src = string.format([[
        getgenv().SelectedMacroPath = "%s"
        getgenv().MacroRepeatInfinite = %s
        getgenv().MacroRepeatCount = %s
        getgenv().MacroRunsDone = %s
        loadstring(game:HttpGet("%s"))()
    ]],
        getgenv().SelectedMacroPath,
        tostring(getgenv().MacroRepeatInfinite),
        tostring(getgenv().MacroRepeatCount),
        tostring(getgenv().MacroRunsDone or 0),
        BASE.."loader.lua"
    )

    pcall(function()
        queue(src)
    end)
end

local function fetch(p)
    return game:HttpGet(BASE..p)
end

-- LOAD MACRO
local path = getgenv().SelectedMacroPath
if not path then
    warn("[LOADER] No macro path")
    return
end

print("[LOADER] Path:", path)

local ok, macro = pcall(function()
    return loadstring(fetch(path))()
end)

if not ok or not macro then
    warn("[LOADER] Invalid macro")
    return
end

-- ALWAYS QUEUE EARLY (CRITICAL FIX)
safeQueue()

--========================
-- LOBBY LOGIC
--========================
if game.PlaceId == LOBBY_PLACE_ID then
    local Events = RS:WaitForChild("Events")

    local function getRoot()
        local char = LP.Character or LP.CharacterAdded:Wait()
        return char:WaitForChild("HumanoidRootPart")
    end
    
    local valid = macro.Settings.Elevators

    local function hold(cf, duration)
        local root = getRoot()
        local t0 = tick()
        while tick() - t0 < duration do
            root.CFrame = cf
            task.wait()
        end
    end

    task.spawn(function()
        while true do
            local lobby = workspace:FindFirstChild("NewLobby")

            if lobby and lobby:FindFirstChild("Elevators") then
                for _, e in pairs(lobby.Elevators:GetChildren()) do
                    if not valid[e.Name] then continue end

                    local screen = e:FindFirstChild("Screen")
                    if not screen then continue end

                    local root = getRoot()
                    local targetCF = CFrame.new(screen.Position + Vector3.new(0,3,0))
                    local orginCF = root.CFrame
                    print("[LOADER] Attempt:", e.Name)

                    root.CFrame = targetCF
                    task.wait(0.15)
                    Events:FindFirstChild("StartElevator")
                    root.CFrame = orginCF
                    
                    task.wait(10)
                end
            end

            task.wait()
        end
    end)

    return
end

--========================
-- GAME LOGIC (ENGINE RUN GUARANTEED)
--========================
repeat task.wait() until game:IsLoaded()

print("[LOADER] Loading engine")

loadstring(fetch("engine.lua"))()

if getgenv().MacroEngine then
    print("[LOADER] Running macro")
    getgenv().MacroEngine.run(macro)
else
    warn("[LOADER] Engine failed to load")
end