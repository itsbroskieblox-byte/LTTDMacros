--//========================
--// CONFIG
--//========================
local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

--//========================
--// QUEUE
--//========================
local queue =
    queue_on_teleport or
    (syn and syn.queue_on_teleport) or
    (fluxus and fluxus.queue_on_teleport) or
    queueonteleport

--//========================
--// HELPERS
--//========================
local function fetch(path)
    return game:HttpGet(BASE..path)
end

local function compile(code)
    local fn = loadstring(code)
    if not fn then return nil end
    local ok,res = pcall(fn)
    return ok and res or nil
end

--//========================
--// GET MACRO PATH (FIXED)
--//========================
local path = getgenv().SelectedMacroPath

if not path then
    warn("No macro path found (lost on teleport)")
    return
end

--//========================
--// LOAD MACRO
--//========================
local macro = compile(fetch(path))
if not macro then
    warn("Failed to load macro")
    return
end

--//========================
--// RE-QUEUE WITH PATH
--//========================
if queue then
    local scriptToQueue = string.format([[
        getgenv().SelectedMacroPath = "%s"
        loadstring(game:HttpGet("%s"))()
    ]], path, BASE.."loader.lua")

    queue(scriptToQueue)
end

--//========================
--// LOBBY
--//========================
if game.PlaceId == LOBBY_PLACE_ID then

    local RS = game:GetService("ReplicatedStorage")
    local LP = game:GetService("Players").LocalPlayer

    local function getChar()
        return LP.Character or LP.CharacterAdded:Wait()
    end

    local function toLookup(list)
        local t = {}
        for _,v in ipairs(list or {}) do
            t[v] = true
        end
        return t
    end

    local valid = toLookup(macro.Settings and macro.Settings.Elevators)

    while true do
        local lobby = workspace:FindFirstChild("NewLobby")

        if lobby and lobby:FindFirstChild("Elevators") then
            for _,e in ipairs(lobby.Elevators:GetChildren()) do

                if next(valid) and not valid[e.Name] then continue end

                local screen = e:FindFirstChild("Screen")
                local gui = screen and screen:FindFirstChild("StatusGui")
                local title = gui and gui:FindFirstChild("Title")

                if title and title.Text == "0/5" then
                    local char = getChar()
                    local target = screen.CFrame * CFrame.new(0,3,0)

                    for i = 1,6 do
                        char:PivotTo(target)
                        task.wait()
                    end

                    RS.Events.StartElevator:FireServer(e.Name)
                    task.wait(6)
                end
            end
        end

        task.wait(1)
    end
end

--//========================
--// GAME
--========================
repeat task.wait() until game:IsLoaded()

local engine = compile(fetch("engine.lua"))
if not engine then
    warn("Engine failed")
    return
end

task.wait(1)

if