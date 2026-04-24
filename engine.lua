--//========================
-- ENGINE (FINAL)
--//========================
getgenv().MacroEngine = {}

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()

local Functions = RS:WaitForChild("Functions")
local Towers = workspace:WaitForChild("Towers")
local Gold = LP:WaitForChild("Gold")

local SpawnTower = Functions:WaitForChild("SpawnTower")
local RequestTower = Functions:WaitForChild("RequestTower")
local SellTower = Functions:WaitForChild("SellTower")

-- TRACKING
local placed = {}

local function track(name)
    placed[name] = placed[name] or {}

    for _ = 1,20 do
        for _,t in ipairs(Towers:GetChildren()) do
            if t.Name:find(name) and not table.find(placed[name], t) then
                table.insert(placed[name], t)
                return t
            end
        end
        task.wait(0.2)
    end
end

local function get(name)
    local list = placed[name]
    return list and list[#list]
end

-- ACTIONS
local function place(name,cf)
    RequestTower:InvokeServer(name)
    task.wait()
    SpawnTower:InvokeServer(name,cf,Instance.new("Model"))
    return track(name)
end

local function upgrade(name)
    local t = get(name)
    if t then SpawnTower:InvokeServer(name,t:GetPivot(),t)
    else
SpawnTower:InvokeServer(name,t:GetPivot(),Instance.new("Model"))
    end
end

local function sell(name)
    if placed[name] then
        for _,t in ipairs(placed[name]) do
            SellTower:InvokeServer(t)
        end
        placed[name] = {}
    end
end

-- STEP
local function runStep(step,file)
    local pos = file.Positions and file.Positions[step.tower]
    local cost = file.Prices and file.Prices[step.tower]

    if step.action == "place" then
        while Gold.Value < cost[1] do task.wait() end
        place(step.tower,pos[step.id or 1])

    elseif step.action == "upgrade" then
        while Gold.Value < cost[step.level] do task.wait() end
        upgrade(step.tower)

    elseif step.action == "sell" then
        sell(step.tower)

    elseif step.action == "set" then
        if step.target == "Skip" then
            getgenv().AutoSkip = step.value
        end
    end
end

-- AUTOSKIP LOOP
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

-- END LOOP
task.spawn(function()
    local GameGui = LP.PlayerGui:WaitForChild("GameGui")

    while true do
        task.wait(0.5)

        local endScreen = GameGui:FindFirstChild("EndScreen")

        if endScreen and endScreen.Visible then
            getgenv().MacroRunsDone += 1

            local inf = getgenv().MacroRepeatInfinite
            local max = getgenv().MacroRepeatCount

            local replay = inf or (getgenv().MacroRunsDone < max)

            RS.Events.ExitGame:FireServer()

            if replay then
                if queue_on_teleport then
                    queue_on_teleport('loadstring(game:HttpGet("'..BASE..'loader.lua"))()')
                end
            end

            break
        end
    end
end)

-- RUN
getgenv().MacroEngine.run = function(file)
    for _,step in ipairs(file.Steps) do
        runStep(step,file)
    end
end