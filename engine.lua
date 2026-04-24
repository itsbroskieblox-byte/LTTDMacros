--//========================
-- ENGINE (FINAL FIXED + AUTOSKIP PRINT)
--//========================
getgenv().MacroEngine = {}

local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

repeat task.wait() until game:IsLoaded()

-- OBJECTS
local Functions = RS:WaitForChild("Functions")
local Towers = workspace:WaitForChild("Towers")
local Gold = LP:WaitForChild("Gold")
local Events = RS:WaitForChild("Events")

local SpawnTower = Functions:WaitForChild("SpawnTower")
local RequestTower = Functions:WaitForChild("RequestTower")
local SellTower = Functions:WaitForChild("SellTower")

local GameGui = PlayerGui:WaitForChild("GameGui")
local TextInfo = GameGui:WaitForChild("GameController"):WaitForChild("TextInfo")
local Folder = GameGui:WaitForChild("Texts"):WaitForChild("Folder")

-- GLOBALS
getgenv().AutoSkip = getgenv().AutoSkip or false
getgenv().MacroRepeatInfinite = getgenv().MacroRepeatInfinite or false
getgenv().MacroRepeatCount = getgenv().MacroRepeatCount or 1
getgenv().MacroRunsDone = getgenv().MacroRunsDone or 0

--//========================
-- NOTIFY
--//========================
local function notify(msg, color)
    color = color or Color3.fromRGB(255,255,255)

    local t = TextInfo:Clone()
    t.Parent = Folder
    t.Text = msg

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = color
    stroke.Parent = t

    task.delay(3,function()
        if t then t:Destroy() end
    end)
end

--//========================
-- NAME LOGIC
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
        print("[GetPrevious]", base)
        return base
    else
        local name = base .. (level - 2)
        print("[GetPrevious]", name)
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
    local prev = getPrevious(name, level)
    local new = getModel(name, level)

    print("[Upgrade] Trying:", prev, "->", new)

    for _,t in ipairs(Towers:GetChildren()) do
        if t.Name == prev then
            SpawnTower:InvokeServer(new, t:GetPivot(), t)
            print("[Upgrade] Success:", new)
            return
        end
    end

    warn("[Upgrade] Failed:", prev)
end

local function sell(name, level)
    local target = getModel(name, level or 1)

    print("[Sell] Looking for:", target)

    for _,t in ipairs(Towers:GetChildren()) do
        if t.Name == target then
            SellTower:InvokeServer(t)
            print("[Sell] Sold:", target)
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
-- AUTOSKIP LOOP (FIXED THREAD)
--//========================
task.spawn(function()
    while true do
        if getgenv().AutoSkip then
            pcall(function()
                Events.VoteSkip:FireServer()
            end)
        end
        task.wait(0.2)
    end
end)

--//========================
-- END SCREEN LOOP
--//========================
task.spawn(function()
    while true do
        task.wait(0.5)

        local endScreen = GameGui:FindFirstChild("EndScreen")

        if endScreen and endScreen.Visible then
            print("[End] Detected")

            getgenv().MacroRunsDone += 1

            local inf = getgenv().MacroRepeatInfinite
            local max = tonumber(getgenv().MacroRepeatCount) or 1
            local replay = inf or (getgenv().MacroRunsDone < max)

            Events.ExitGame:FireServer()

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

    notify("[ENGINE] RUNNING", Color3.fromRGB(0,255,0))
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