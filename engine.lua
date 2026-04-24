--//========================
-- ENGINE (FINAL - TRACKED)
--//========================
getgenv().MacroEngine = {}

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()

-- SAFE WAIT
local function safeWait(parent, name)
    if not parent then return nil end
    local obj = parent:FindFirstChild(name)
    if obj then return obj end

    local ok,res = pcall(function()
        return parent:WaitForChild(name, 10)
    end)

    return ok and res or nil
end

-- OBJECTS
local Functions = safeWait(RS, "Functions")
local Towers = safeWait(workspace, "Towers")
local Gold = safeWait(LP, "Gold")

local Info = safeWait(workspace, "Info")
local Wave = Info and safeWait(Info, "Wave")

if not Functions then warn("[ENGINE] Missing Functions") return end

local SpawnTower = safeWait(Functions, "SpawnTower")
local RequestTower = safeWait(Functions, "RequestTower")
local SellTower = safeWait(Functions, "SellTower")

if not (SpawnTower and RequestTower and SellTower and Towers and Gold) then
    warn("[ENGINE] Missing remotes")
    return
end

--//========================
-- HELPERS
--//========================
local function waitGold(amount)
    while Gold.Value < amount do
        task.wait()
    end
end

local function getWave()
    if Wave then return Wave.Value end
    local alt = workspace:FindFirstChild("Wave")
    return alt and alt.Value or 0
end

--//========================
-- TOWER TRACKING
--//========================
local placed = {} -- [towerName] = {instances}

local function trackTower(name)
    placed[name] = placed[name] or {}

    -- wait for new tower instance
    for _ = 1,20 do
        for _,t in ipairs(Towers:GetChildren()) do
            if t.Name:find(name) then
                if not table.find(placed[name], t) then
                    table.insert(placed[name], t)
                    return t
                end
            end
        end
        task.wait(0.2)
    end

    return nil
end

local function getTracked(name)
    local list = placed[name]
    if not list or #list == 0 then return nil end
    return list[#list] -- latest
end

--//========================
-- ACTIONS
--//========================
local function place(name, cf)
    print("[ENGINE] Place:", name)

    pcall(function()
        RequestTower:InvokeServer(name)
    end)

    task.wait(0.1)

    pcall(function()
        SpawnTower:InvokeServer(name, cf, Instance.new("Model"))
    end)

    return trackTower(name)
end

local function upgrade(name)
    print("[ENGINE] Upgrade:", name)

    local tower = getTracked(name)
    if not tower then
        warn("[ENGINE] No tracked tower:", name)
        return
    end

    pcall(function()
        SpawnTower:InvokeServer(name, tower:GetPivot(), tower)
    end)
end

local function sell(name)
    print("[ENGINE] Sell:", name)

    local list = placed[name]
    if not list then return end

    for _,t in ipairs(list) do
        pcall(function()
            SellTower:InvokeServer(t)
        end)
        task.wait()
    end

    placed[name] = {}
end

local function fullPlace(costs, name, cf)
    local tower = nil

    for level, price in ipairs(costs) do
        waitGold(price)

        if level == 1 then
            tower = place(name, cf)
        else
            upgrade(name)
        end
    end

    return tower
end

--//========================
-- CONDITION
--//========================
local function handleCondition(cond)
    if not cond then return end

    if cond.type == "wave" then
        print("[ENGINE] Wait wave:", cond.value)

        repeat task.wait()
        until getWave() >= cond.value
    end
end

--//========================
-- AUTOSKIP
--//========================
local AutoSkip = true

task.spawn(function()
    while true do
        if AutoSkip then
            local skip = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("SkipWave")
            if skip then
                pcall(function()
                    skip:FireServer()
                end)
            end
        end
        task.wait(1)
    end
end)

--//========================
-- STEP EXECUTOR
--//========================
local function runStep(step, file)
    print("[ENGINE] Step:", step.action, step.tower or "")

    handleCondition(step.condition)

    local pos = file.Positions and file.Positions[step.tower]
    local cost = file.Prices and file.Prices[step.tower]

    if step.action == "fullPlace" then
        if not pos or not cost then return end
        local cf = pos[step.id or 1]

        for _ = 1,(step.count or 1) do
            fullPlace(cost, step.tower, cf)
        end

    elseif step.action == "place" then
        if not pos or not cost then return end
        waitGold(cost[1])
        place(step.tower, pos[step.id or 1])

    elseif step.action == "upgrade" then
        if not cost then return end
        waitGold(cost[step.level])
        upgrade(step.tower)

    elseif step.action == "sell" then
        sell(step.tower)

    elseif step.action == "set" then
        if step.target == "Skip" then
            AutoSkip = step.value
            print("[ENGINE] AutoSkip:", AutoSkip)
        end
    end
end

--//========================
-- RUN
--//========================
getgenv().MacroEngine.run = function(file)
    if not file or not file.Steps then return end

    print("[ENGINE] Running...")

    task.spawn(function()
        for _,step in ipairs(file.Steps) do
            local ok,err = pcall(function()
                runStep(step, file)
            end)

            if not ok then
                warn("[ENGINE] Error:", err)
                break
            end
        end

        print("[ENGINE] Done")
    end)
end