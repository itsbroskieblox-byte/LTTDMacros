--//========================
-- ENGINE (QUEUE TRACKING)
--//========================
getgenv().MacroEngine = {}

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()

-- SAFE WAIT
local function safeWait(parent, name)
    if not parent then return nil end
    return parent:FindFirstChild(name) or parent:WaitForChild(name, 10)
end

-- OBJECTS
local Functions = safeWait(RS, "Functions")
local Towers = safeWait(workspace, "Towers")
local Gold = safeWait(LP, "Gold")

local Info = safeWait(workspace, "Info")
local Wave = Info and safeWait(Info, "Wave")

local Events = safeWait(RS, "Events")

if not Functions then return warn("[ENGINE] No Functions") end

local SpawnTower = safeWait(Functions, "SpawnTower")
local RequestTower = safeWait(Functions, "RequestTower")
local SellTower = safeWait(Functions, "SellTower")

--//========================
-- UI NOTIFY (YOUR SYSTEM)
--//========================
local PlayerGui = LP:WaitForChild("PlayerGui")
local GameGui = PlayerGui:WaitForChild("GameGui")

local TextInfo = GameGui:WaitForChild("GameController"):WaitForChild("TextInfo")
local Folder = GameGui:WaitForChild("Texts"):WaitForChild("Folder")

local function notify(msg, color)
    color = color or Color3.fromRGB(255,255,255)

    local t = TextInfo:Clone()
    t.Parent = Folder
    t.Text = msg

    t.Font = Enum.Font.FredokaOne
    t.TextColor3 = Color3.fromRGB(255,255,255)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2.5
    stroke.Color = color
    stroke.Parent = t

    task.spawn(function()
        for i=0,1,0.1 do
            t.TextTransparency = 1-i
            stroke.Transparency = 1-i
            task.wait(0.02)
        end
    end)

    task.delay(3,function()
        if t then
            for i=0,1,0.1 do
                t.TextTransparency = i
                stroke.Transparency = i
                task.wait(0.02)
            end
            t:Destroy()
        end
    end)
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
    return (Wave and Wave.Value) or 0
end

--//========================
-- TRACKING (QUEUE)
--//========================
local placed = {} -- [name] = {queue = {}}

local function trackTower(name)
    placed[name] = placed[name] or {queue = {}}

    for _ = 1,20 do
        for _,t in ipairs(Towers:GetChildren()) do
            if t.Name:find(name) then
                if not table.find(placed[name].queue, t) then
                    table.insert(placed[name].queue, t)
                    return t
                end
            end
        end
        task.wait(0.2)
    end
end

local function getLatest(name)
    local data = placed[name]
    if not data then return nil end
    return data.queue[#data.queue]
end

--//========================
-- ACTIONS
--//========================
local function place(name, cf)
    notify("Placing "..name)

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
    local tower = getLatest(name)
    if not tower then
        warn("[ENGINE] No tower to upgrade:", name)
        return
    end

    notify("Upgrading "..name)

    pcall(function()
        SpawnTower:InvokeServer(name, tower:GetPivot(), tower)
    end)
end

local function sell(name, level)
    notify("Selling "..name)

    local list = placed[name] and placed[name].queue
    if not list then return end

    for _,t in ipairs(list) do
        if t.Name:find(name) then
            pcall(function()
                SellTower:InvokeServer(t)
            end)
        end
    end

    placed[name] = {queue = {}}
end

local function fullPlace(costs, name, cf)
    local tower

    for i,price in ipairs(costs) do
        waitGold(price)

        if i == 1 then
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
        notify("Waiting wave "..cond.value)

        repeat task.wait()
        until getWave() >= cond.value
    end
end

--//========================
-- AUTOSKIP + END
--//========================
local AutoSkip = true
local EndHandled = false

GameGui.SkipButton.Skip:GetPropertyChangedSignal("Visible"):Connect(function()
    if GameGui.SkipButton.Skip.Visible and AutoSkip then
        Events.VoteSkip:FireServer()
    end
end)

GameGui.EndScreen:GetPropertyChangedSignal("Visible"):Connect(function()
    if GameGui.EndScreen.Visible and not EndHandled then
        EndHandled = true
        Events.ExitGame:FireServer()
    end
end)

--//========================
-- STEP EXECUTION
--//========================
local function runStep(step, file)
    handleCondition(step.condition)

    local pos = file.Positions and file.Positions[step.tower]
    local cost = file.Prices and file.Prices[step.tower]

    if step.action == "fullPlace" then
        local cf = pos[step.id or 1]
        for _=1,(step.count or 1) do
            fullPlace(cost, step.tower, cf)
        end

    elseif step.action == "place" then
        waitGold(cost[1])
        place(step.tower, pos[step.id or 1])

    elseif step.action == "upgrade" then
        waitGold(cost[step.level])
        upgrade(step.tower)

    elseif step.action == "sell" then
        sell(step.tower, step.level)

    elseif step.action == "set" then
        if step.target == "Skip" then
            AutoSkip = step.value
            notify("AutoSkip: "..tostring(step.value))
        end
    end
end

--//========================
-- RUN
--//========================
getgenv().MacroEngine.run = function(file)
    if not file or not file.Steps then return end

    notify("Macro started")

    task.spawn(function()
        for _,step in ipairs(file.Steps) do
            local ok,err = pcall(function()
                runStep(step, file)
            end)

            if not ok then
                warn(err)
                notify("Error", Color3.fromRGB(255,80,80))
                break
            end
        end

        notify("Macro finished", Color3.fromRGB(100,255,100))
    end)
end