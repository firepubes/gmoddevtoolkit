-- ==========================================================
-- GDT STUDIO - CORE DIAGNOSTICS & TELEMETRY ENGINE
-- Tickrate Math, Memory Tracking, GC Benchmarks & History
-- ==========================================================

GDT = GDT or {}
GDT.Diagnostics = GDT.Diagnostics or {}

local Diag = GDT.Diagnostics

local lastTickTime = SysTime()
local tickSamples = {}
local maxTickSamples = 100

local history = {}
local maxHistory = (GDT.Config and GDT.Config.MaxHistory) or 180

local currentStats = {
    hostname = GetHostName(),
    map = game.GetMap(),
    gamemode = (GAMEMODE and GAMEMODE.Name) or (engine.ActiveGamemode and engine.ActiveGamemode()) or "sandbox",
    os = (system.IsWindows and system.IsWindows() and "Windows") or (system.IsLinux and system.IsLinux() and "Linux") or (system.IsOSX and system.IsOSX() and "macOS") or "Unknown",
    tps = 66.6,
    targetTps = math.Round(1 / engine.TickInterval(), 1),
    frameTimeMs = 15.0,
    luaMemoryKB = 0,
    playerCount = 0,
    maxPlayers = game.MaxPlayers(),
    entityCount = 0,
    awakePhysics = 0,
    uptime = 0,
}

hook.Add("Tick", "GDT:DiagnosticsTick", function()
    local now = SysTime()
    local dt = now - lastTickTime
    lastTickTime = now

    if dt <= 0 then return end

    table.insert(tickSamples, dt)
    if #tickSamples > maxTickSamples then
        table.remove(tickSamples, 1)
    end
end)

timer.Create("GDT:DiagnosticsAggregator", 0.5, 0, function()
    if #tickSamples == 0 then return end

    local sum = 0
    for _, dt in ipairs(tickSamples) do sum = sum + dt end
    local avgDt = sum / #tickSamples

    local awake = 0
    for _, e in ipairs(ents.FindByClass("prop_physics*")) do
        if IsValid(e) then
            local p = e:GetPhysicsObject()
            if IsValid(p) and p:IsMoveable() and not p:IsAsleep() then
                awake = awake + 1
            end
        end
    end

    currentStats.hostname = GetHostName()
    currentStats.map = game.GetMap()
    currentStats.tps = math.Clamp(math.Round(1 / avgDt, 1), 0, currentStats.targetTps)
    currentStats.frameTimeMs = math.Round(avgDt * 1000, 2)
    currentStats.luaMemoryKB = math.Round(collectgarbage("count"), 1)
    currentStats.playerCount = #player.GetAll()
    currentStats.entityCount = ents.GetCount()
    currentStats.awakePhysics = awake
    currentStats.uptime = math.floor(CurTime())
end)

-- Rolling Performance History (15s Window)
timer.Create("GDT:HistoryTracker", 15, 0, function()
    local entry = {
        time = os.time(),
        timeFormatted = os.date("%H:%M:%S", os.time()),
        tps = currentStats.tps,
        frameTimeMs = currentStats.frameTimeMs,
        luaMemoryMB = math.Round(currentStats.luaMemoryKB / 1024, 2),
        entities = currentStats.entityCount,
        players = currentStats.playerCount,
        awakePhysics = currentStats.awakePhysics,
    }

    table.insert(history, entry)
    if #history > maxHistory then
        table.remove(history, 1)
    end
end)

function Diag:GetSummary()
    return currentStats
end

function Diag:GetHistory()
    return history
end

function Diag:ForceGarbageCollection()
    local beforeKB = collectgarbage("count")
    local t0 = SysTime()
    collectgarbage("collect")
    local elapsedMs = math.Round((SysTime() - t0) * 1000, 2)
    local afterKB = collectgarbage("count")
    local reclaimedKB = math.max(0, math.Round(beforeKB - afterKB, 2))

    return {
        elapsedMs = elapsedMs,
        beforeMB = math.Round(beforeKB / 1024, 2),
        afterMB = math.Round(afterKB / 1024, 2),
        reclaimedMB = math.Round(reclaimedKB / 1024, 2),
    }
end
