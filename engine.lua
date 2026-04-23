--//========================
--// ENGINE (FIXED)
--//========================
getgenv().MacroEngine = {}

-- SERVICES
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- WAIT GAME READY
repeat task.wait() until game:IsLoaded()

-- SAFE GETTERS
local function safeWait(parent, name)
    local obj = parent:FindFirstChild(name)
    if obj then return obj end

    local ok
    ok, obj = pcall(function()
        return parent:WaitForChild(name, 10)
    end)

    return ok and obj or nil
end

local Functions = safeWait(RS, "Functions")
if not Functions then
    warn("[ENGINE] Functions missing")
    return
end

local SpawnTower = safeWait(Functions, "SpawnTower")
local RequestTower = safeWait(Functions, "RequestTower")
local SellTower = safeWait(Functions, "SellTower")

local Towers = safeWait(workspace, "Towers")
local Gold = safeWait(LP, "Gold")
local Wave = safeWait(workspace:FindFirstChild("Info") or workspace, "Wave")

if not (SpawnTower and RequestTower and SellTower and Towers and Gold) then
    warn("[ENGINE] Missing critical objects")
    return
end

--//========================
--// HELPERS
--//========================
local function waitGold(amount)
    while Gold.Value < amount do
        task.wait()
    end
end

local function getWave()
    return (Wave and Wave.Value) or 0
end

local function getName(base, level)
    return (level == 1) and base or (base .. level)
end

local function getPrev(base, level)
    return (level <= 2) and base or (base .. (level - 1))
end

--//========================
--// ACTIONS
--//========================
local function place(name, cf)
    print("[ENGINE] Placing:", name)
    RequestTower:InvokeServer(name)
    SpawnTower:InvokeServer(name, cf, Instance.new("Model"))
end

local function upgrade(name, level)
    print("[ENGINE] Upgrading:", name, level)

    local prev = getPrev(name, level)
    local tower = Towers:FindFirstChild(prev)

    if not tower then
        warn("[ENGINE] Upgrade failed, tower not found:", prev)
        return
    end

    SpawnTower:InvokeServer(getName(name, level), tower:GetPivot(), tower)
end

local function sell(name, level)
    print("[ENGINE] Selling:", name)

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

--//========================
--// STEP EXECUTOR
--//========================
local AutoSkip = true

local function runStep(step, file)
    local positions = file.Positions or {}
    local prices = file.Prices or {}

    local pos = positions[step.tower]
    local cost = prices[step.tower]

    if step.action == "fullPlace" then
        if not pos or not cost then
            warn("[ENGINE] Missing data for fullPlace:", step.tower)
            return
        end

        local cf = pos[step.id or 1]
        if not cf then return end

        for _ = 1, (step.count or 1) do
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
        for _ = 1, (step.count or 1) do
            sell(step.tower, step.level)
        end

    elseif step.action == "set" then
        if step.target == "Skip" then
            AutoSkip = step.value
            print("[ENGINE] AutoSkip =", AutoSkip)
        end

    elseif step.action == "repeat" then
        for _ = 1, (step.count or 1) do
            runStep(step.data, file)
        end
    end
end

--//========================
--// RUN
--//========================
getgenv().MacroEngine.run = function(file)
    if not file or not file.Steps then
        warn("[ENGINE] Invalid macro")
        return
    end

    print("[ENGINE] Running macro...")

    task.spawn(function()
        for i, step in ipairs(file.Steps) do
            print("[STEP]", i, step.action, step.tower or "")

            local ok, err = pcall(function()
                runStep(step, file)
            end)

            if not ok then
                warn("[ENGINE] Step error:", err)
                break
            end
        end

        print("[ENGINE] Finished macro")
    end)
end