local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

local queue = queue_on_teleport

-- helpers
local function fetch(p)
    return game:HttpGet(BASE..p)
end

local function compile(code)
    return loadstring(code)()
end

-- load macro
local path = getgenv().SelectedMacroPath
if not path then return end

local macro = compile(fetch(path))
if not macro then return end

-- ========================
-- LOBBY
-- ========================
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

                    -- queue itself
                    if queue then
                        queue('loadstring(game:HttpGet("'..BASE..'loader.lua"))()')
                    end

                    task.wait(5)
                end
            end
        end

        task.wait(1)
    end
end

-- ========================
-- GAME
-- ========================

-- load engine ONLY when in game
local engine = compile(fetch("engine.lua"))

if getgenv().MacroEngine then
    getgenv().MacroEngine.run(macro)
end