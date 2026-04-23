-- ENGINE
getgenv().MacroEngine = {}

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local Functions = RS:WaitForChild("Functions")
local SpawnTower = Functions:WaitForChild("SpawnTower")
local RequestTower = Functions:WaitForChild("RequestTower")
local SellTower = Functions:WaitForChild("SellTower")

local Towers = workspace:WaitForChild("Towers")
local Gold = LP:WaitForChild("Gold")
local Wave = workspace:WaitForChild("Info"):WaitForChild("Wave")

local function waitGold(amount)
    while Gold.Value < amount do task.wait() end
end

local function getName(base, level)
    return (level == 1) and base or (base .. level)
end

local function getPrev(base, level)
    return (level <= 2) and base or (base .. (level - 1))
end

local function place(name, cf)
    RequestTower:InvokeServer(name)
    SpawnTower:InvokeServer(name, cf, Instance.new("Model"))
end

local function upgrade(name, level)
    local prev = getPrev(name, level)
    local tower = Towers:FindFirstChild(prev)
    if not tower then return end
    SpawnTower:InvokeServer(getName(name, level), tower:GetPivot(), tower)
end

local function sell(name, level)
    local target = getName(name, level or 1)
    for _ = 1, 10 do
        local t = Towers:FindFirstChild(target)
        if not t then break end
        SellTower:InvokeServer(t)
        task.wait()
    end
end

local function fullPlace(costs, tower, cf)
    for level, price in ipairs(costs) do
        waitGold(price)
        if level == 1 then
            place(tower, cf)
        else
            upgrade(tower, level)
        end
    end
end

local function runStep(step, file)
    local positions = file.Positions or {}
    local prices = file.Prices or {}

    local pos = positions[step.tower]
    local cost = prices[step.tower]

    if step.action == "fullPlace" then
        if not pos or not cost then return end
        local cf = pos[step.id or 1]
        if not cf then return end

        for i = 1, (step.count or 1) do
            fullPlace(cost, step.tower, cf)
        end

    elseif step.action == "place" then
        if not pos or not cost then return end
        local cf = pos[step.id or 1]
        waitGold(cost[1])
        place(step.tower, cf)

    elseif step.action == "upgrade" then
        if not cost then return end
        waitGold(cost[step.level])
        upgrade(step.tower, step.level)

    elseif step.action == "sell" then
        for i = 1, (step.count or 1) do
            sell(step.tower, step.level)
        end
    end
end

getgenv().MacroEngine.run = function(file)
    if not file or not file.Steps then
        warn("Invalid macro")
        return
    end

    task.spawn(function()
        for i, step in ipairs(file.Steps) do
            print("[STEP]", i, step.action)

            local ok, err = pcall(function()
                runStep(step, file)
            end)

            if not ok then
                warn("Step error:", err)
                break
            end
        end
    end)
end