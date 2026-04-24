--//========================
-- ENGINE (FINAL STABLE)
--//========================
getgenv().MacroEngine = {}

local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()

-- OBJECTS
local Functions = RS:WaitForChild("Functions")
local Towers = workspace:WaitForChild("Towers")
local Gold = LP:WaitForChild("Gold")

local SpawnTower = Functions:WaitForChild("SpawnTower")
local RequestTower = Functions:WaitForChild("RequestTower")
local SellTower = Functions:WaitForChild("SellTower")

-- GLOBALS
getgenv().AutoSkip = getgenv().AutoSkip or false
getgenv().MacroRepeatInfinite = getgenv().MacroRepeatInfinite or false
getgenv().MacroRepeatCount = getgenv().MacroRepeatCount or 1
getgenv().MacroRunsDone = getgenv().MacroRunsDone or 0

--//========================
-- NAME LOGIC
--//========================
local function getModel(base, level)
    if level <= 2 then
        return base
    else
        return base .. (level - 1)
    end
end

local function getPrevious(base, level)
    if level <= 2 then
        return base
    else
        return base .. (level - 2)
    end
end

--//========================
-- HELPERS
--//========================
local function waitGold(v)
    while Gold.Value < v do
        task.wait()
    end
end

--//========================
-- ACTIONS
--//========================
local function place(name, cf)
    RequestTower:InvokeServer(name)
    task.wait()
    SpawnTower:InvokeServer(name, cf, Instance.new("Model"))
end

local function upgrade(name, level)
    local prev = getPrevious(name, level)
    local new = getModel(name, level)

    for _,t in ipairs(Towers:GetChildren()) do
        if t.Name == prev then
            SpawnTower:InvokeServer(new, t:GetPivot(), t)
            return
        end
    end
end

local function sell(name, level)
    local target = getModel(name, level or 1)

    for _,t in ipairs(Towers:GetChildren()) do
        if t.Name == target then
            SellTower:InvokeServer(t)
        end
    end
end

--//========================
-- STEP
--//========================
local function runStep(step, file)
    local pos = file.Positions and file.Positions[step.tower]
    local cost = file.Prices and file.Prices[step.tower]

    if step.action == "place" then
        waitGold(cost[1])
        place(step.tower, pos[step.id or 1])

    elseif step.action == "upgrade" then
        waitGold(cost[step.level])
        upgrade(step.tower, step.level)

    elseif step.action == "sell" then
        sell(step.tower, step.level)

    elseif step.action == "set" then
        if step.target == "Skip" then
            getgenv().AutoSkip = step.value
        end
    end
end

--//========================
-- AUTOSKIP LOOP
--//========================
task.spawn(function()
    while true do
        task.wait(0.3)
        if getgenv().AutoSkip then
            pcall(function()
                RS.Events.VoteSkip:FireServer()
            end)
        end
    end
end)

--//========================
-- END SCREEN LOOP
--//========================
task.spawn(function()
    local GameGui = LP.PlayerGui:WaitForChild("GameGui")

    while true do
        task.wait(0.5)

        local endScreen = GameGui:FindFirstChild("EndScreen")

        if endScreen and endScreen.Visible then
            getgenv().MacroRunsDone += 1

            local inf = getgenv().MacroRepeatInfinite
            local max = tonumber(getgenv().MacroRepeatCount) or 1

            local replay = inf or (getgenv().MacroRunsDone < max)

            RS.Events.ExitGame:FireServer()

            if replay and queue_on_teleport then
                queue_on_teleport('loadstring(game:HttpGet("'..BASE..'loader.lua"))()')
            end

            break
        end
    end
end)

--//========================
-- RUN
--//========================
getgenv().MacroEngine.run = function(file)
    if not file or not file.Steps then return end

    print("[ENGINE] Running:", #file.Steps)

    for _,step in ipairs(file.Steps) do
        local ok,err = pcall(function()
            runStep(step, file)
        end)

        if not ok then
            warn(err)
            break
        end
    end
end