-- ==========================================================
-- GDT STUDIO - SECURE HIGH-SPEED RPC NETWORKING (SERVER)
-- Compressed Payload Transport, Access Control & Live Streaming
-- ==========================================================

GDT = GDT or {}
GDT.Network = GDT.Network or {}

local Network = GDT.Network

-- Protocol Message Strings
util.AddNetworkString("GDT:Open")
util.AddNetworkString("GDT:Subscribe")
util.AddNetworkString("GDT:Unsubscribe")
util.AddNetworkString("GDT:SendTelemetry")

util.AddNetworkString("GDT:RequestDiagnostics")
util.AddNetworkString("GDT:SendDiagnostics")

util.AddNetworkString("GDT:RequestRunLua")
util.AddNetworkString("GDT:SendRunLuaResult")

util.AddNetworkString("GDT:RequestInspect")
util.AddNetworkString("GDT:RequestRaytrace")
util.AddNetworkString("GDT:SendInspectResult")
util.AddNetworkString("GDT:RequestEntityAction")
util.AddNetworkString("GDT:SendActionFeedback")

util.AddNetworkString("GDT:RequestHookRegistry")
util.AddNetworkString("GDT:SendHookRegistry")
util.AddNetworkString("GDT:RequestHookProfile")
util.AddNetworkString("GDT:StopHookProfile")
util.AddNetworkString("GDT:SendHookProfileResults")
util.AddNetworkString("GDT:ToggleHookSuppression")

util.AddNetworkString("GDT:RequestNetTraffic")
util.AddNetworkString("GDT:SendNetTraffic")
util.AddNetworkString("GDT:DispatchTestPacket")

util.AddNetworkString("GDT:RequestErrors")
util.AddNetworkString("GDT:SendErrors")
util.AddNetworkString("GDT:ClearErrors")
util.AddNetworkString("GDT:ExportErrors")

util.AddNetworkString("GDT:RequestAddons")
util.AddNetworkString("GDT:SendAddons")

util.AddNetworkString("GDT:RequestGC")
util.AddNetworkString("GDT:SendGCFeedback")

local activeSubscribers = {}

local function SendCompressed(msgName, targetPly, tbl)
    local json = util.TableToJSON(tbl)
    local compressed = util.Compress(json)
    local bytes = #compressed

    net.Start(msgName)
        net.WriteUInt(bytes, 32)
        net.WriteData(compressed, bytes)
    if targetPly then
        net.Send(targetPly)
    else
        net.Broadcast()
    end
end

-- ----------------------------------------------------------
-- 1. Subscriber Stream for Telemetry
-- ----------------------------------------------------------
net.Receive("GDT:Subscribe", function(len, ply)
    if not GDT:CanAccess(ply) then return end
    activeSubscribers[ply] = true
end)

net.Receive("GDT:Unsubscribe", function(len, ply)
    if IsValid(ply) then activeSubscribers[ply] = nil end
end)

hook.Add("PlayerDisconnected", "GDT:CleanSubscribers", function(ply)
    activeSubscribers[ply] = nil
end)

timer.Create("GDT:TelemetryBroadcast", 1.0, 0, function()
    local hasSubscribers = false
    local valid = {}
    for ply, _ in pairs(activeSubscribers) do
        if IsValid(ply) and GDT:CanAccess(ply) then
            hasSubscribers = true
            table.insert(valid, ply)
        else
            activeSubscribers[ply] = nil
        end
    end

    if not hasSubscribers then return end

    local summary = GDT.Diagnostics:GetSummary()
    for _, ply in ipairs(valid) do
        SendCompressed("GDT:SendTelemetry", ply, summary)
    end
end)

-- ----------------------------------------------------------
-- 2. Diagnostics & History RPCs
-- ----------------------------------------------------------
net.Receive("GDT:RequestDiagnostics", function(len, ply)
    if not GDT:CanAccess(ply) then return end
    local summary = GDT.Diagnostics:GetSummary()
    local hist = GDT.Diagnostics:GetHistory()
    SendCompressed("GDT:SendDiagnostics", ply, { summary = summary, history = hist })
end)

net.Receive("GDT:RequestGC", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local res = GDT.Diagnostics:ForceGarbageCollection()
    SendCompressed("GDT:SendGCFeedback", ply, res)
end)

-- ----------------------------------------------------------
-- 3. Lua REPL Sandbox RPC
-- ----------------------------------------------------------
net.Receive("GDT:RequestRunLua", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local codeLen = net.ReadUInt(32)
    local codeStr = net.ReadData(codeLen)
    local result = GDT.LuaRunner:ExecuteCode(ply, codeStr)
    SendCompressed("GDT:SendRunLuaResult", ply, result)
end)

-- ----------------------------------------------------------
-- 4. Entity Inspector & Raytrace RPCs
-- ----------------------------------------------------------
net.Receive("GDT:RequestInspect", function(len, ply)
    if not GDT:CanAccess(ply) then return end
    local entIndex = net.ReadUInt(16)
    local res = GDT.EntityInspector:InspectEntity(entIndex)
    SendCompressed("GDT:SendInspectResult", ply, res)
end)

net.Receive("GDT:RequestRaytrace", function(len, ply)
    if not GDT:CanAccess(ply) then return end
    local res = GDT.EntityInspector:InspectRaytrace(ply)
    SendCompressed("GDT:SendInspectResult", ply, res)
end)

net.Receive("GDT:RequestEntityAction", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local entIndex = net.ReadUInt(16)
    local action = net.ReadString()
    local ok, msg = GDT.EntityInspector:PerformAction(ply, entIndex, action)

    net.Start("GDT:SendActionFeedback")
        net.WriteBool(ok)
        net.WriteString(msg)
    net.Send(ply)
end)

-- ----------------------------------------------------------
-- 5. Hook Matrix & Profiler RPCs
-- ----------------------------------------------------------
net.Receive("GDT:RequestHookRegistry", function(len, ply)
    if not GDT:CanAccess(ply) then return end
    local registry = GDT.HookMatrix:GetHookRegistry()
    SendCompressed("GDT:SendHookRegistry", ply, registry)
end)

net.Receive("GDT:RequestHookProfile", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local secs = net.ReadUInt(8)
    GDT.HookMatrix:StartProfiler(secs)
end)

net.Receive("GDT:StopHookProfile", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    GDT.HookMatrix:StopProfiler()
    local res = GDT.HookMatrix:GetProfilerResults()
    SendCompressed("GDT:SendHookProfileResults", ply, res)
end)

net.Receive("GDT:ToggleHookSuppression", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local eventName = net.ReadString()
    local id = net.ReadString()
    local ok, msg = GDT.HookMatrix:ToggleSuppression(eventName, id)

    net.Start("GDT:SendActionFeedback")
        net.WriteBool(ok)
        net.WriteString(msg)
    net.Send(ply)
end)

-- ----------------------------------------------------------
-- 6. Network Sniffer RPCs
-- ----------------------------------------------------------
net.Receive("GDT:RequestNetTraffic", function(len, ply)
    if not GDT:CanAccess(ply) then return end
    local data = GDT.NetTraffic:GetRegistry()
    SendCompressed("GDT:SendNetTraffic", ply, data)
end)

net.Receive("GDT:DispatchTestPacket", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local msgName = net.ReadString()
    local payload = net.ReadString()
    local ok, msg = GDT.NetTraffic:DispatchTestPacket(ply, msgName, payload)

    net.Start("GDT:SendActionFeedback")
        net.WriteBool(ok)
        net.WriteString(msg)
    net.Send(ply)
end)

-- ----------------------------------------------------------
-- 7. Error Tracker RPCs
-- ----------------------------------------------------------
net.Receive("GDT:RequestErrors", function(len, ply)
    if not GDT:CanAccess(ply) then return end
    local errs = GDT.ErrorTracker:GetErrors()
    SendCompressed("GDT:SendErrors", ply, errs)
end)

net.Receive("GDT:ClearErrors", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    GDT.ErrorTracker:ClearErrors()
    net.Start("GDT:SendActionFeedback")
        net.WriteBool(true)
        net.WriteString("Cleared captured Lua errors from memory.")
    net.Send(ply)
end)

net.Receive("GDT:ExportErrors", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local path = GDT.ErrorTracker:ExportReport()
    net.Start("GDT:SendActionFeedback")
        net.WriteBool(true)
        net.WriteString("Exported error snapshot to server: " .. path)
    net.Send(ply)
end)

-- ----------------------------------------------------------
-- 8. Addon Architecture Scanner RPC
-- ----------------------------------------------------------
net.Receive("GDT:RequestAddons", function(len, ply)
    if not GDT:CanAccess(ply) then return end
    local report = GDT.AddonScanner:GetReport()
    SendCompressed("GDT:SendAddons", ply, report)
end)

-- ----------------------------------------------------------
-- 9. Chat & Console Dispatchers
-- ----------------------------------------------------------
hook.Add("PlayerSay", "GDT:ChatTriggers", function(ply, text)
    if not IsValid(ply) then return end
    local lower = string.lower(string.Trim(text or ""))

    for _, cmd in ipairs(GDT.Config.ChatCommands or {}) do
        if lower == string.lower(cmd) then
            if GDT:CanAccess(ply) then
                net.Start("GDT:Open")
                net.Send(ply)
            else
                ply:ChatPrint("[GDT Studio] Access denied: SuperAdmin permission required.")
            end
            return ""
        end
    end
end)

for _, cmd in ipairs(GDT.Config.ConsoleCommands or { "gdt_menu", "gdt" }) do
    concommand.Add(cmd, function(ply)
        if not IsValid(ply) then return end
        if GDT:CanAccess(ply) then
            net.Start("GDT:Open")
            net.Send(ply)
        else
            ply:ChatPrint("[GDT Studio] Access denied: SuperAdmin permission required.")
        end
    end)
end
