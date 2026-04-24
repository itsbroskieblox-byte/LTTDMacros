--//========================
-- LOADER (FINAL STABLE)
--//========================
local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

print("[LOADER] Start")

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

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
        getgenv().MacroRepeatInfinite = %s
        getgenv().MacroRepeatCount = %s
        getgenv().MacroRunsDone = %s
        loadstring(game:HttpGet("%s"))()
    ]],
        path,
        tostring(getgenv().MacroRepeatInfinite),
        tostring(getgenv().MacroRepeatCount),
        tostring(getgenv().MacroRunsDone or 0),
        BASE.."loader.lua"
    )

    pcall(function() queue(src) end)
end

local function fetch(p)
    return game:HttpGet(BASE..p)
end

local path = getgenv().SelectedMacroPath
if not path then
    warn("[LOADER] No macro path")
    return
end

print("[LOADER] Path:", path)

local macro = loadstring(fetch(path))()
if not macro then
    warn("[LOADER] Invalid macro")
    return
end

queueSelf(path)

-- LOBBY
if game.PlaceId == LOBBY_PLACE_ID then
    print("[LOADER] In lobby")

    local lobby = workspace:WaitForChild("NewLobby", 10)
    local elevators = lobby and lobby:WaitForChild("Elevators", 10)

    if not elevators then
        warn("[LOADER] Elevators missing")
        return
    end

    -- PRIORITY BUILD
    local pref = {}
    if macro.Settings and macro.Settings.Elevators then
        for i, v in ipairs(macro.Settings.Elevators) do
            pref[tostring(v):lower()] = i
        end
    end

    local function getPriority(name)
        return pref[tostring(name):lower()] or math.huge
    end

    local list = elevators:GetChildren()

    table.sort(list, function(a, b)
        return getPriority(a.Name) < getPriority(b.Name)
    end)

    -- CHARACTER SAFE LOAD
    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)

    if not root then
        warn("[LOADER] Root missing")
        return
    end

    -- TELEPORT LOOP
    for _, e in ipairs(list) do
        print("[LOADER] Checking:", e.Name)

        local screen = e:FindFirstChild("Screen") or e:FindFirstChildWhichIsA("BasePart")

        local gui = screen and (
            screen:FindFirstChildWhichIsA("SurfaceGui") or
            screen:FindFirstChildWhichIsA("BillboardGui")
        )

        local title = gui and gui:FindFirstChild("Title")

        if title and title.Text:find("0/") then
            print("[LOADER] Found empty:", e.Name)

            local targetCF = screen.CFrame + Vector3.new(0, 3, 0)

            -- HARD TELEPORT (REPEATED)
            for i = 1, 8 do
                char:PivotTo(targetCF)
                root.CFrame = targetCF
                task.wait(0.1)
            end

            -- FIRE REMOTE
            local remote = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("StartElevator")

            if remote then
                remote:FireServer(e.Name)
                print("[LOADER] Fired:", e.Name)
            else
                warn("[LOADER] StartElevator missing")
            end

            -- HOLD POSITION briefly
            task.wait(2)

            break
        end
    end

    return
end

-- GAME
repeat task.wait() until game:IsLoaded()

loadstring(fetch("engine.lua"))()

if getgenv().MacroEngine then
    getgenv().MacroEngine.run(macro)
end