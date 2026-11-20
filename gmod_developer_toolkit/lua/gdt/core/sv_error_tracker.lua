-- ==========================================================
-- GDT STUDIO - LUA ERROR CAPTURE & STACK DEMANGLER
-- Deduplication, Stack Formatting & Diagnostics Export
-- ==========================================================

GDT = GDT or {}
GDT.ErrorTracker = GDT.ErrorTracker or {}

local Tracker = GDT.ErrorTracker

local errorsList = {}
local errorIndex = {}
local maxErrors = (GDT.Config and GDT.Config.MaxErrors) or 250

local function RecordError(message, realm, stack, addon, source)
    local msg = string.Trim(tostring(message or "Unknown Lua Error"))
    local key = realm .. "::" .. msg

    if errorIndex[key] then
        local existing = errorIndex[key]
        existing.count = existing.count + 1
        existing.lastTime = os.time()
        existing.lastTimeFormatted = os.date("%H:%M:%S", os.time())
        return
    end

    local entry = {
        id = #errorsList + 1,
        time = os.time(),
        timeFormatted = os.date("%H:%M:%S", os.time()),
        lastTimeFormatted = os.date("%H:%M:%S", os.time()),
        realm = realm or "server",
        message = msg,
        addon = addon or "Unknown Addon",
        source = source or "server",
        stack = tostring(stack or ""),
        count = 1,
    }

    errorIndex[key] = entry
    table.insert(errorsList, 1, entry)

    if #errorsList > maxErrors then
        local removed = table.remove(errorsList)
        if removed then
            errorIndex[removed.realm .. "::" .. removed.message] = nil
        end
    end
end

hook.Add("OnLuaError", "GDT:CaptureServerErrors", function(message, realm, stack, name)
    RecordError(message, realm or "server", util.TableToJSON(stack or {}), name, "server")
end)

hook.Add("OnClientLuaError", "GDT:CaptureClientErrors", function(message, ply, stack, name)
    local clientInfo = IsValid(ply) and (ply:Nick() .. " (" .. ply:SteamID() .. ")") or "Client"
    RecordError(message, "client", util.TableToJSON(stack or {}), name, clientInfo)
end)

function Tracker:GetErrors()
    return errorsList
end

function Tracker:ClearErrors()
    errorsList = {}
    errorIndex = {}
end

function Tracker:ExportReport()
    file.CreateDir("gdt/exports")
    local fileName = "gdt/exports/errors_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
    file.Write(fileName, util.TableToJSON(errorsList, true))
    return fileName
end
