--//========================
--// CONFIG
--//========================
local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

print("[LOADER] Started")

--// QUEUE SAFE
local queue =
    (type(queue_on_teleport) == "function" and queue_on_teleport) or
    (syn and type(syn.queue_on_teleport) == "function" and syn.queue_on_teleport) or
    (type(queueonteleport) == "function" and queueonteleport)

--// HELPERS
local function fetch(path)
    local ok,res = pcall(function()
        return game:HttpGet(BASE..path)
    end)
    return ok and res or nil
end

local function compile(code)
    local fn = loadstring(code)
    if not fn then return nil end
    local ok,res = pcall(fn)
    return ok and res or nil
end

--// GET PATH
local path = getgenv().SelectedMacroPath
if not path then
    warn("[LOADER] No macro path")
    return
end

print("[LOADER] Macro:", path)

--// LOAD MACRO
local macro = compile(fetch(path))
if not macro then
    warn("[LOADER] Macro failed")
    return
end

--// REQUEUE
if queue then
    pcall(function()
        queue(string.format([[
            getgenv().SelectedMacroPath = "%s"
            loadstring(game:HttpGet("%s"))()
        ]], path, BASE.."loader.lua"))
    end)
end

print("[LOADER] PlaceId:", game.PlaceId)

--//========================
--// LOBBY
--//========================
if game.PlaceId == LOBBY_PLACE_ID then
    print("[LOADER] Lobby logic")

    local RS = game:GetService("ReplicatedStorage")
    local LP = game:GetService("Players").LocalPlayer

    local function getChar()
        return LP.Character or LP.CharacterAdded:Wait()
    end

    while true do
        local lobby = workspace:FindFirstChild("NewLobby")

        if lobby and lobby:FindFirstChild("Elevators") then
            for _,e in ipairs(lobby.Elevators:GetChildren()) do

                local screen = e:FindFirstChild("Screen")
                local gui = screen and screen:FindFirstChild("StatusGui")
                local title = gui and gui:FindFirstChild("Title")

                if title and title.Text == "0/5" then
                    local char = getChar()

                    -- SAVE ORIGINAL POSITION
                    local old = char:GetPivot()

                    local target = screen.CFrame * CFrame.new(0,3,0)

                    for i = 1,6 do
                        char:PivotTo(target)
                        task.wait()
                    end

                    -- FIRE
                    RS.Events.StartElevator:FireServer(e.Name)
                    print("[LOADER] Fired elevator:", e.Name)

                    -- 🔥 RETURN IMMEDIATELY
                    char:PivotTo(old)
                    print("[LOADER] Returned to original position")

                    task.wait(5)
                end
            end
        end

        task.wait(1)
    end
end

--//========================
--// GAME
--//========================
repeat task.wait() until game:IsLoaded()

print("[LOADER] Loading engine")

local engine = compile(fetch("engine.lua"))
if not engine then
    warn("[LOADER] Engine failed")
    return
end

task.wait(1)

if getgenv().MacroEngine then
    print("[LOADER] Running macro")
    getgenv().MacroEngine.run(macro)
else
    warn("[LOADER] No MacroEngine")
end