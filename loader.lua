--//========================
-- LOADER (FINAL)
--//========================
local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

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
if not path then return end

local macro = loadstring(fetch(path))()
queueSelf(path)

-- LOBBY PRIORITY
if game.PlaceId == LOBBY_PLACE_ID then
    local lobby = workspace:WaitForChild("NewLobby")
    local elevators = lobby:WaitForChild("Elevators")

    local pref = {}
    if macro.Settings and macro.Settings.Elevators then
        for i,v in ipairs(macro.Settings.Elevators) do
            pref[v] = i
        end
    end

    local list = elevators:GetChildren()

    table.sort(list,function(a,b)
        return (pref[a.Name] or math.huge) < (pref[b.Name] or math.huge)
    end)

    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    for _,e in ipairs(list) do
        local screen = e:FindFirstChild("Screen")
        local title = screen and screen:FindFirstChildWhichIsA("SurfaceGui")
        title = title and title:FindFirstChild("Title")

        if title and title.Text:find("0/") then
            root.CFrame = CFrame.new(screen.Position + Vector3.new(0,3,0))
            RS.Events.StartElevator:FireServer(e.Name)
            break
        end
    end

    return
end

repeat task.wait() until game:IsLoaded()

loadstring(fetch("engine.lua"))()

if getgenv().MacroEngine then
    getgenv().MacroEngine.run(macro)
end