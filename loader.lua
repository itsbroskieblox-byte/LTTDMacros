--//========================
-- LOADER (FINAL)
--//========================

local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

print("[LOADER] Boot")

-- SERVICES
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- QUEUE
local queue =
    queue_on_teleport or
    (syn and syn.queue_on_teleport) or
    queueonteleport

getgenv()._LOADER_QUEUED = getgenv()._LOADER_QUEUED or false

local function queueSelf(path)
    if not queue or getgenv()._LOADER_QUEUED then return end
    getgenv()._LOADER_QUEUED = true

    local src = string.format([[
        getgenv().SelectedMacroPath = "%s"
        loadstring(game:HttpGet("%s"))()
    ]], path, BASE.."loader.lua")

    pcall(function()
        queue(src)
        print("[LOADER] Queued")
    end)
end

-- FETCH
local function fetch(path)
    local urls = {
        BASE..path,
        BASE:gsub("raw.githubusercontent.com","cdn.jsdelivr.net/gh")
            :gsub("/main/","@main/")..path
    }

    for _,url in ipairs(urls) do
        local ok,res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and res and #res > 0 then return res end
    end

    warn("[LOADER] Fetch failed:", path)
    return nil
end

-- EXEC
local function exec(code)
    local fn = loadstring(code)
    if not fn then return false end
    local ok,err = pcall(fn)
    if not ok then warn(err) end
    return ok
end

-- MACRO LOAD
local path = getgenv().SelectedMacroPath
if not path then return end

local code = fetch(path)
if not code then return end

local macro
do
    local ok,res = pcall(function()
        return loadstring(code)()
    end)
    if not ok or not res then return end
    macro = res
end

queueSelf(path)

--//========================
-- LOBBY
--//========================
if game.PlaceId == LOBBY_PLACE_ID then
    print("[LOADER] Lobby")

    local lobby = workspace:WaitForChild("NewLobby", 10)
    local elevators = lobby and lobby:WaitForChild("Elevators", 10)
    if not elevators then return end

    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    for _,e in ipairs(elevators:GetChildren()) do
        local screen = e:FindFirstChild("Screen")
        local gui = screen and (screen:FindFirstChildWhichIsA("SurfaceGui") or screen:FindFirstChildWhichIsA("BillboardGui"))
        local title = gui and gui:FindFirstChild("Title")

        if screen and title and title.Text:find("0/") then
            print("[LOADER] Entering:", e.Name)

            for i = 1,5 do
                root.CFrame = CFrame.new(screen.Position + Vector3.new(0,3,0))
                task.wait()
            end

            local remote = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("StartElevator")
            if remote then
                remote:FireServer(e.Name)
            end

            break
        end
    end

    return
end

--//========================
-- GAME
--//========================
repeat task.wait() until game:IsLoaded()

local engineCode = fetch("engine.lua")
if not engineCode then return end

if not exec(engineCode) then return end

if getgenv().MacroEngine and macro then
    getgenv().MacroEngine.run(macro)
end