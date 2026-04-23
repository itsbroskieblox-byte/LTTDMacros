--//========================
--// CONFIG
--//========================
local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

--//========================
--// QUEUE (FIXED)
--//========================
local queue =
    queue_on_teleport or
    (syn and syn.queue_on_teleport) or
    (fluxus and fluxus.queue_on_teleport) or
    queueonteleport

getgenv().AlreadyQueued = getgenv().AlreadyQueued or false

-- always queue itself ONCE per session
if queue and not getgenv().AlreadyQueued then
    getgenv().AlreadyQueued = true
    queue('loadstring(game:HttpGet("'..BASE..'loader.lua"))()')
end

--//========================
--// HELPERS
--//========================
local function fetch(path)
    local ok,res = pcall(function()
        return game:HttpGet(BASE..path)
    end)
    return ok and res or nil
end

local function compile(code)
    if not code then return nil end
    local fn = loadstring(code)
    if not fn then return nil end
    local ok,res = pcall(fn)
    return ok and res or nil
end

--//========================
--// LOAD MACRO
--//========================
local path = getgenv().SelectedMacroPath
if not path then
    warn("No macro path set")
    return
end

local macro = compile(fetch(path))
if not macro then
    warn("Failed to load macro")
    return
end

--//========================
--// LOBBY SYSTEM
--//========================
if game.PlaceId == LOBBY_PLACE_ID then

    local RS = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer

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

                    -- move player in
                    for i = 1,6 do
                        char:PivotTo(target)
                        task.wait()
                    end

                    -- start elevator (teleport)
                    RS.Events.StartElevator:FireServer(e.Name)

                    -- ensure queue persists BEFORE teleport
                    if queue then
                        queue('loadstring(game:HttpGet("'..BASE..'loader.lua"))()')
                    end

                    task.wait(6)
                end
            end
        end

        task.wait(1)
    end
end

--//========================
--// GAME SYSTEM
--//========================

-- wait for game to fully load
repeat task.wait() until game:IsLoaded()

-- load engine
local engine = compile(fetch("engine.lua"))

if not engine then
    warn("Failed to load engine")
    return
end

-- wait for engine to register
task.wait(1)

if getgenv().MacroEngine and getgenv().MacroEngine.run then
    getgenv().MacroEngine.run(macro)
else
    warn("MacroEngine not found")
end