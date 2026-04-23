--//========================
-- LOADER (FULL REWRITE)
--//========================

local BASE = "https://raw.githubusercontent.com/itsbroskieblox-byte/LTTDMacros/main/"
local LOBBY_PLACE_ID = 113704021665503

print("[LOADER] Booting...")

--//========================
-- SERVICES
--//========================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

--//========================
-- QUEUE SYSTEM
--//========================
local queue =
    queue_on_teleport or
    (syn and syn.queue_on_teleport) or
    queueonteleport

getgenv()._LOADER_QUEUED = getgenv()._LOADER_QUEUED or false

local function queueSelf(path)
    if not queue or getgenv()._LOADER_QUEUED then return end
    getgenv()._LOADER_QUEUED = true

    local scriptToQueue = string.format([[
        getgenv().SelectedMacroPath = "%s"
        loadstring(game:HttpGet("%s"))()
    ]], path, BASE.."loader.lua")

    pcall(function()
        queue(scriptToQueue)
        print("[LOADER] Queued on teleport")
    end)
end

--//========================
-- FETCH SYSTEM
--//========================
local function fetch(path)
    local urls = {
        BASE .. path,
        BASE:gsub("raw.githubusercontent.com","cdn.jsdelivr.net/gh")
            :gsub("/main/","@main/") .. path
    }

    for _, url in ipairs(urls) do
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and res and #res > 0 then
            return res
        end
    end

    warn("[LOADER] Failed to fetch:", path)
    return nil
end

--//========================
-- EXECUTOR
--//========================
local function exec(code)
    local fn = loadstring(code)
    if not fn then
        warn("[LOADER] Compile failed")
        return false
    end

    local ok, err = pcall(fn)
    if not ok then
        warn("[LOADER] Runtime error:", err)
        return false
    end

    return true
end

--//========================
-- GET MACRO
--//========================
local macroPath = getgenv().SelectedMacroPath
if not macroPath then
    warn("[LOADER] No macro selected")
    return
end

print("[LOADER] Loading macro:", macroPath)

local macroCode = fetch(macroPath)
if not macroCode then return end

local macro = nil
do
    local ok, result = pcall(function()
        return loadstring(macroCode)()
    end)

    if ok then
        macro = result
    else
        warn("[LOADER] Macro load failed:", result)
        return
    end
end

-- queue script for teleport reuse
queueSelf(macroPath)

--//========================
-- LOBBY HANDLER
--//========================
if game.PlaceId == LOBBY_PLACE_ID then
    print("[LOADER] In lobby")

    local lobby = workspace:WaitForChild("NewLobby", 10)
    local elevators = lobby and lobby:WaitForChild("Elevators", 10)

    if not elevators then
        warn("[LOADER] Elevators not found")
        return
    end

    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    for _, e in ipairs(elevators:GetChildren()) do
        local screen = e:FindFirstChild("Screen")
        local gui = screen and screen:FindFirstChildWhichIsA("SurfaceGui")
        local title = gui and gui:FindFirstChild("Title")

        if title and title.Text:find("0/") then
            print("[LOADER] Found empty elevator:", e.Name)

            -- find valid teleport part
            local tpPart =
                e:FindFirstChild("TouchPart") or
                e:FindFirstChild("Hitbox") or
                e:FindFirstChild("JoinPart") or
                e:FindFirstChildWhichIsA("BasePart")

            if tpPart then
                root.CFrame = tpPart.CFrame + Vector3.new(0, 3, 0)
                print("[LOADER] Teleported into elevator")

                task.wait(0.4)
            else
                warn("[LOADER] No teleport part found")
            end

            -- fire remote
            local events = RS:FindFirstChild("Events")
            local remote = events and events:FindFirstChild("StartElevator")

            if remote then
                pcall(function()
                    remote:FireServer(e.Name)
                end)
                print("[LOADER] Fired elevator remote")
            else
                warn("[LOADER] Remote not found")
            end

            break
        end
    end

    return
end

--//========================
-- GAME HANDLER
--//========================
repeat task.wait() until game:IsLoaded()
print("[LOADER] In game")

local engineCode = fetch("engine.lua")
if not engineCode then return end

if not exec(engineCode) then return end

task.wait(0.3)

if getgenv().MacroEngine and macro then
    print("[LOADER] Running macro")
    pcall(function()
        getgenv().MacroEngine.run(macro)
    end)
else
    warn("[LOADER] MacroEngine missing")
end