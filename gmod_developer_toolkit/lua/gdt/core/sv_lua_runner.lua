-- ==========================================================
-- GDT STUDIO - SERVER-SIDE LUA REPL & SANDBOX RUNNER
-- Safe pcall Execution, Stdout Redirection & Return Inspection
-- ==========================================================

GDT = GDT or {}
GDT.LuaRunner = GDT.LuaRunner or {}

local Runner = GDT.LuaRunner

function Runner:ExecuteCode(ply, codeStr)
    if not IsValid(ply) or not ply:IsSuperAdmin() then
        return {
            success = false,
            error = "Access denied: SuperAdmin permission required to execute server-side Lua.",
            output = "",
            elapsedMs = 0
        }
    end

    codeStr = string.Trim(codeStr or "")
    if codeStr == "" then
        return { success = false, error = "Code snippet cannot be empty.", output = "", elapsedMs = 0 }
    end

    -- Syntax check first
    local compiled = CompileString(codeStr, "GDT_REPL_" .. ply:Nick(), false)
    if type(compiled) == "string" then
        return {
            success = false,
            error = "Syntax Error: " .. compiled,
            output = "",
            elapsedMs = 0
        }
    end

    -- Capture stdout prints during execution
    local capturedOutputs = {}
    local origPrint = print
    local origMsgN = MsgN

    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            local val = select(i, ...)
            table.insert(parts, tostring(val))
        end
        table.insert(capturedOutputs, table.concat(parts, "\t"))
        origPrint(...)
    end

    MsgN = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            local val = select(i, ...)
            table.insert(parts, tostring(val))
        end
        table.insert(capturedOutputs, table.concat(parts, "\t"))
        origMsgN(...)
    end

    local t0 = SysTime()
    local ok, r1, r2, r3, r4 = pcall(compiled)
    local elapsed = math.Round((SysTime() - t0) * 1000, 3)

    -- Restore stdout immediately
    print = origPrint
    MsgN = origMsgN

    local returnParts = {}
    if r1 ~= nil then table.insert(returnParts, type(r1) == "table" and util.TableToJSON(r1, true) or tostring(r1)) end
    if r2 ~= nil then table.insert(returnParts, type(r2) == "table" and util.TableToJSON(r2, true) or tostring(r2)) end
    if r3 ~= nil then table.insert(returnParts, type(r3) == "table" and util.TableToJSON(r3, true) or tostring(r3)) end

    if not ok then
        return {
            success = false,
            error = "Runtime Error: " .. tostring(r1),
            output = table.concat(capturedOutputs, "\n"),
            elapsedMs = elapsed,
        }
    end

    return {
        success = true,
        output = table.concat(capturedOutputs, "\n"),
        returnStr = table.concat(returnParts, ", "),
        elapsedMs = elapsed,
    }
end
