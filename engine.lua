--//========================
-- ENGINE (FINAL - FIXED NAMING + REPLAY + AUTOSKIP)
--//========================
getgenv().MacroEngine = {}

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
-- NAME RESOLVER
--//========================
local function getModelName(base, level)
    if level <= 2 then
        return base
    else
        return base .. (level - 1)
    end
end

local function getPreviousModel(base, level)
    if level <= 2 then
        return base
    else
        return base .. (level - 2)
    end
end

--//========================
-- TRACKING
--//========================
local placed = {} -- [tower] = {instances}

local function track(name)
    placed[name] = placed[name] or {}

    for _ = 1, 25 do
        for _, t in ipairs(Towers:GetChildren()) do
            if t.Name:find(name) and not table.find(placed[name], t) then
                table.insert(placed[name], t)
                return t
            end
        end
        task.wait(0.15)
    end
end

local function getLatest(name)
    local list = placed[name]
    return list and list[#list]
end

--//========================
-- ACTIONS
--//========================
local function waitGold(amount)
    while Gold.Value < amount do
        task.wait()
    end
end

local function place(name, cf)
    print("[ENGINE] Place:", name)

    pcall(function()
        RequestTower:InvokeServer(name)
    end)

    task.wait()

    pcall(function()
        SpawnTower:InvokeServer(name, cf, Instance.new("Model"))
    end)

    return track(name)
end

local function upgrade(name, level)
    print("[ENGINE] Upgrade:", name, level)

    local prevName = getPreviousModel(name, level)
    local newName = getModelName(name, level)

    local tower = nil

    -- find correct previous tower
    for _, t in ipairs(Towers:GetChildren()) do
        if t.Name == prevName then
            tower = t
            break
        end
    end

    if not tower then
        warn("[ENGINE] Upgrade failed, missing:", prevName)
        return
    end

    pcall(function()
        SpawnTower:InvokeServer(newName, tower:GetPivot(), tower)
    end)
end

local function sell(name, level)
    print("[ENGINE] Sell:", name, level)

    local target = getModelName(name, level or 1)

    for _, t in ipairs(Towers:GetChildren()) do
        if t.Name == target then
            pcall(function()
                SellTower:InvokeServer(t)
            end)
        end
    end

    placed[name] = {}
end

--//========================
-- STEP EXECUTION
--//========================
local function runStep(step, file)
    local pos = file.Positions and file.Positions[step.tower]
    local cost = file.Prices and file.Prices[step.tower]

    if step.action == "place" then
        if not pos or not cost then return end

        waitGold(cost[1])
        place(step.tower, pos[step.id or 1])

    elseif step.action == "upgrade" then
        if not cost then return end

        waitGold(cost[step.level])
        upgrade(step.tower, step.level)

    elseif step.action == "sell" then
        sell(step.tower, step.level)

    elseif step.action == "set" then
        if step.target == "Skip" then
            getgenv().AutoSkip = step.value
            print("[ENGINE] AutoSkip:", step.value)
        end
    end
end

--//========================
-- AUTOSKIP LOOP (INFINITE CHECK)
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
-- END SCREEN LOOP (REPLAY SYSTEM)
--//========================
task.spawn(function()
    local GameGui = LP.PlayerGui:WaitForChild("GameGui")

    while true do
        task.wait(0.5)

        local endScreen = GameGui:FindFirstChild("EndScreen")

        if endScreen and endScreen.Visible then
            print("[ENGINE] End detected")

            getgenv().MacroRunsDone += 1

            local infinite = getgenv().MacroRepeatInfinite
            local max = tonumber(getgenv().MacroRepeatCount) or 1

            local shouldReplay = infinite or (getgenv().MacroRunsDone < max)

            RS.Events.ExitGame:FireServer()

            if shouldReplay then
                print("[ENGINE] Replaying macro")

                if queue_on_teleport then
                    queue_on_teleport('loadstring(game:HttpGet("'..BASE..'loader.lua"))()')
                end
            else
                print("[ENGINE] Finished all runs")
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

    print("[ENGINE] Running macro:", #file.Steps, "steps")

    for i, step in ipairs(file.Steps) do
        local ok, err = pcall(function()
            runStep(step, file)
        end)

        if not ok then
            warn("[ENGINE] Step error:", err)
            break
        end
    end

    print("[ENGINE] Macro complete")
end