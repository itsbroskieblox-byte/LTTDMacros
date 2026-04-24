--//========================
-- ENGINE (FIXED + PRINTS)
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
-- NAME LOGIC (CORRECT)
--//========================
local function getModel(base, level)
    if level <= 2 then
        print("[GetModel]", base)
        return base
    else
        local name = base .. (level - 1)
        print("[GetModel]", name)
        return name
    end
end

local function getPrevious(base, level)
    if level <= 2 then
        print("[GetPrevious] ", base)
        return base
    else
        local name = base .. (level - 2)
        print("[GetPrevious] ", name)
        return name
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
    print("[Place] Request:", name)

    RequestTower:InvokeServer(name)
    task.wait()

    SpawnTower:InvokeServer(name, cf, Instance.new("Model"))

    print("[Place] Placed:", name)
end

local function upgrade(name, level)
    local prevName = getPrevious(name, level)
    local newName = getModel(name, level)

    print("[Upgrade] Trying:", prevName, "->", newName)

    for _, t in ipairs(Towers:GetChildren()) do
        if t.Name == prevName then
            SpawnTower:InvokeServer(newName, t:GetPivot(), t)
            print("[Upgrade] Success:", newName)
            return
        end
    end

    warn("[Upgrade] Failed, missing:", prevName)
end

local function sell(name, level)
    local targetName = getModel(name, level or 1)

    print("[Sell] Looking for:", targetName)

    for _, t in ipairs(Towers:GetChildren()) do
        if t.Name == targetName then
            SellTower:InvokeServer(t)
            print("[Sell] Sold:", targetName)
        end
    end
end

--//========================
-- STEP
--//========================
local function runStep(step, file)
    print("[STEP]", step.action, step.tower or "")

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
            print("[SET] AutoSkip:", step.value)
        end
    end
end

--//========================
-- AUTOSKIP LOOP
--//========================
while true do
    if getgenv().AutoSkip then
      Events.VoteSkip:FireServer()
   end
    task.wait(0.1)
end

--//========================
-- END SCREEN LOOP
--//========================
task.spawn(function()
    local GameGui = LP.PlayerGui:WaitForChild("GameGui")

    while true do
        task.wait(0.5)

        local endScreen = GameGui:FindFirstChild("EndScreen")

        if endScreen and endScreen.Visible then
            print("[End] Detected")

            getgenv().MacroRunsDone += 1

            local inf = getgenv().MacroRepeatInfinite
            local max = tonumber(getgenv().MacroRepeatCount) or 1

            local replay = inf or (getgenv().MacroRunsDone < max)

            RS.Events.ExitGame:FireServer()

            if replay and queue_on_teleport then
                print("[Replay] Queueing next run")
                queue_on_teleport('loadstring(game:HttpGet("'..BASE..'loader.lua"))()')
            else
                print("[Replay] Finished all runs")
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

    print("[ENGINE] Running:", #file.Steps, "steps")

    for i, step in ipairs(file.Steps) do
        local ok, err = pcall(function()
            runStep(step, file)
        end)

        if not ok then
            warn("[ENGINE ERROR]", err)
            break
        end
    end

    print("[ENGINE] Done")
end