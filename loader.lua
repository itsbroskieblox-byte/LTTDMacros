--//========================
-- LOADER (CLEAN + SAFE)
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

getgenv()._LOADER_QUEUED = false

local function safeQueue()
    if not queue then
        warn("[LOADER] No queue function")
        return
    end

    if getgenv()._LOADER_QUEUED then return end
    getgenv()._LOADER_QUEUED = true

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

-- FAST WAIT (you referenced this)
local function fastWait()
    task.wait()
end

-- FETCH
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

--========================
-- LOBBY LOGIC (YOUR VERSION, FIXED ONLY WHERE NEEDED)
--========================
if game.PlaceId == LOBBY_PLACE_ID then
    local Events = RS:WaitForChild("Events")

    local function getRoot()
        local char = LP.Character or LP.CharacterAdded:Wait()
        return char:WaitForChild("HumanoidRootPart")
    end

    local valid = {
        Elevator13 = true,
        Elevator14 = true,
        Elevator15 = true,
        Elevator16 = true
    }

    while true do
        local lobby = workspace:FindFirstChild("NewLobby")

        if lobby and lobby:FindFirstChild("Elevators") then
            for _, e in pairs(lobby.Elevators:GetChildren()) do
                if not valid[e.Name] then continue end

                local root = getRoot()
                local originCFrame = root.CFrame

                local screen = e:FindFirstChild("Screen")
                if not screen or not screen:IsA("BasePart") then continue end

                local gui = screen:FindFirstChild("StatusGui")
                if not gui then continue end

                local title = gui:FindFirstChild("Title")
                if not title then continue end

                if title.Text == "0/5" then
                    print("[LOADER] Entering:", e.Name)

                    root.CFrame = CFrame.new(screen.Position + Vector3.new(0, 3, 0))

                    local remote = Events:FindFirstChild("StartElevator")
                    if remote then
                        remote:FireServer(e.Name)
                        print("[LOADER] Fired:", e.Name)
                    else
                        warn("[LOADER] StartElevator missing")
                    end

                    root.CFrame = originCFrame

                    safeQueue()

                    task.wait(5)
                end
            end
        end

        fastWait()
    end

    return
end

--========================
-- GAME LOGIC
--========================
repeat task.wait() until game:IsLoaded()

loadstring(fetch("engine.lua"))()

if getgenv().MacroEngine then
    getgenv().MacroEngine.run(macro)
end