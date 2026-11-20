-- ==========================================================
-- GDT STUDIO - HOOK MATRIX, SOURCE RESOLVER & PROFILER
-- Exact File/Line Debug Info, Opt-in Profiler & Live Suppression
-- ==========================================================

GDT = GDT or {}
GDT.HookMatrix = GDT.HookMatrix or {}

local Matrix = GDT.HookMatrix

local suppressedHooks = {}
local isProfiling = false
local profileEndTime = 0
local wrappedHooks = {}
local profileStats = {}

-- ----------------------------------------------------------
-- 1. Hook Inspection & Source Resolution
-- ----------------------------------------------------------
function Matrix:GetHookRegistry()
    local tbl = hook.GetTable()
    local registry = {}

    for eventName, handlers in pairs(tbl) do
        for id, fn in pairs(handlers) do
            local sourcePath = "C++ Engine / Unknown"
            local lineNum = 0

            if isfunction(fn) then
                local info = debug.getinfo(fn, "S")
                if info then
                    sourcePath = info.short_src or "unknown"
                    lineNum = info.linedefined or 0
                end
            end

            local isSuppressed = (suppressedHooks[eventName] and suppressedHooks[eventName][tostring(id)] ~= nil)

            table.insert(registry, {
                event = tostring(eventName),
                id = tostring(id),
                source = sourcePath,
                line = lineNum,
                suppressed = isSuppressed,
            })
        end
    end

    table.sort(registry, function(a, b)
        if a.event == b.event then return a.id < b.id end
        return a.event < b.event
    end)

    return registry
end

-- ----------------------------------------------------------
-- 2. Hook Suppression (Temporary Runtime Mute)
-- ----------------------------------------------------------
function Matrix:ToggleSuppression(eventName, id)
    local tbl = hook.GetTable()
    local strId = tostring(id)

    suppressedHooks[eventName] = suppressedHooks[eventName] or {}

    if suppressedHooks[eventName][strId] then
        -- Restore original hook
        local orig = suppressedHooks[eventName][strId]
        hook.Add(eventName, id, orig)
        suppressedHooks[eventName][strId] = nil
        return false, "Unsuppressed hook callback: " .. strId
    else
        -- Mute hook callback
        if tbl[eventName] and tbl[eventName][id] then
            local orig = tbl[eventName][id]
            suppressedHooks[eventName][strId] = orig
            hook.Add(eventName, id, function(...)
                -- Suppressed callback: no-op
            end)
            return true, "Suppressed hook callback: " .. strId
        end
    end

    return false, "Hook not found in registry."
end

-- ----------------------------------------------------------
-- 3. Opt-in Profiler Engine
-- ----------------------------------------------------------
function Matrix:StartProfiler(seconds)
    if isProfiling then self:StopProfiler() end

    seconds = math.Clamp(tonumber(seconds) or 15, 3, 60)
    isProfiling = true
    profileEndTime = CurTime() + seconds
    wrappedHooks = {}
    profileStats = {}

    local tbl = hook.GetTable()
    for eventName, handlers in pairs(tbl) do
        wrappedHooks[eventName] = {}
        for id, fn in pairs(handlers) do
            if isfunction(fn) and not string.StartWith(tostring(id), "GDT_") then
                wrappedHooks[eventName][id] = fn
                local key = eventName .. " // " .. tostring(id)
                profileStats[key] = {
                    event = eventName,
                    id = tostring(id),
                    calls = 0,
                    totalMs = 0,
                    maxMs = 0,
                    errors = 0,
                }
                local sRef = profileStats[key]

                handlers[id] = function(...)
                    local t0 = SysTime()
                    local ok, r1, r2, r3, r4, r5 = pcall(fn, ...)
                    local dt = (SysTime() - t0) * 1000

                    sRef.calls = sRef.calls + 1
                    sRef.totalMs = sRef.totalMs + dt
                    if dt > sRef.maxMs then sRef.maxMs = dt end
                    if not ok then sRef.errors = sRef.errors + 1 end

                    if ok then return r1, r2, r3, r4, r5 end
                end
            end
        end
    end

    timer.Create("GDT:ProfilerAutoStop", seconds, 1, function()
        if isProfiling then
            Matrix:StopProfiler()
        end
    end)
end

function Matrix:StopProfiler()
    if not isProfiling then return end
    isProfiling = false
    timer.Remove("GDT:ProfilerAutoStop")

    local tbl = hook.GetTable()
    for eventName, handlers in pairs(wrappedHooks) do
        if tbl[eventName] then
            for id, origFn in pairs(handlers) do
                if tbl[eventName][id] then
                    tbl[eventName][id] = origFn
                end
            end
        end
    end
    wrappedHooks = {}
end

function Matrix:GetProfilerResults()
    local list = {}
    for key, data in pairs(profileStats) do
        if data.calls > 0 then
            table.insert(list, {
                key = key,
                event = data.event,
                id = data.id,
                calls = data.calls,
                totalMs = math.Round(data.totalMs, 2),
                avgMs = math.Round(data.totalMs / data.calls, 4),
                maxMs = math.Round(data.maxMs, 2),
                errors = data.errors,
            })
        end
    end

    table.sort(list, function(a, b) return a.totalMs > b.totalMs end)
    return {
        active = isProfiling,
        remaining = isProfiling and math.max(0, math.Round(profileEndTime - CurTime(), 1)) or 0,
        results = list
    }
end
