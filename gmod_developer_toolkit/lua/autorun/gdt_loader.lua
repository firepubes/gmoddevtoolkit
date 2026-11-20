-- ==========================================================
-- GDT STUDIO - MASTER AUTOLOADER & REALM INITIALIZER
-- ==========================================================

GDT = GDT or {}
GDT.Version = "3.0.0"

local C = {
    Brand     = Color(0, 212, 255),     -- Cyan
    BrandDark = Color(18, 30, 48),      -- Dark Steel
    Shared    = Color(0, 210, 255),     -- Cyber Teal
    Server    = Color(63, 185, 80),     -- Green
    Client    = Color(210, 153, 34),    -- Amber
    Text      = Color(240, 246, 252),   -- Light Text
    Muted     = Color(139, 148, 158),   -- Gray
    Success   = Color(63, 185, 80),     -- Green
    Error     = Color(248, 81, 73),     -- Red
}

local stats = { total = 0, errors = 0 }

local function SafeLoad(realm, path, tag)
    local ok = true
    local err = nil
    stats.total = stats.total + 1

    if realm == "shared" then
        if SERVER then AddCSLuaFile(path) end
        ok, err = pcall(include, path)
    elseif realm == "client" then
        if SERVER then
            AddCSLuaFile(path)
        else
            ok, err = pcall(include, path)
        end
    elseif realm == "server" then
        if SERVER then
            ok, err = pcall(include, path)
        end
    end

    local realmCol = (realm == "shared" and C.Shared) or (realm == "client" and C.Client) or C.Server
    local realmTag = tag or string.upper(realm)
    local fileName = string.GetFileFromFilename(path)

    if ok then
        local dots = string.rep(".", math.max(28 - #fileName, 2))
        MsgC(
            C.BrandDark, "  │ ",
            realmCol, "[" .. realmTag .. "] ",
            C.Text, fileName, " ",
            C.Muted, dots, " ",
            C.Success, "[OK]\n"
        )
    else
        stats.errors = stats.errors + 1
        MsgC(
            C.BrandDark, "  │ ",
            C.Error, "[" .. realmTag .. " FAIL] ",
            C.Text, fileName, " -> " .. tostring(err) .. "\n"
        )
    end
end

local function LoadGDT()
    local t0 = SysTime()
    stats = { total = 0, errors = 0 }

    local realmStr = SERVER and "S E R V E R" or "C L I E N T"
    local realmCol = SERVER and C.Server or C.Client

    MsgC(C.BrandDark, "\n  ┌────────────────────────────────────────────────────────────────┐\n")
    MsgC(C.BrandDark, "  │  ", C.Brand, "██████╗ ██████╗ ████████╗    ███████╗████████╗██╗   ██╗██████╗ ", C.BrandDark, " │\n")
    MsgC(C.BrandDark, "  │  ", C.Brand, "██╔════╝ ██╔══██╗╚══██╔══╝    ██╔════╝╚══██╔══╝██║   ██║██╔══██╗", C.BrandDark, " │\n")
    MsgC(C.BrandDark, "  │  ", C.Brand, "██║  ███╗██║  ██║   ██║       ███████╗   ██║   ██║   ██║██║  ██║", C.BrandDark, " │\n")
    MsgC(C.BrandDark, "  │  ", C.Brand, "██║   ██║██║  ██║   ██║       ╚════██║   ██║   ██║   ██║██║  ██║", C.BrandDark, " │\n")
    MsgC(C.BrandDark, "  │  ", C.Brand, "╚██████╔╝██████╔╝   ██║       ███████║   ██║   ╚██████╔╝██████╔╝", C.BrandDark, " │\n")
    MsgC(C.BrandDark, "  │  ", C.Brand, " ╚═════╝ ╚═════╝    ╚═╝       ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ", C.BrandDark, " │\n")
    MsgC(C.BrandDark, "  ├────────────────────────────────────────────────────────────────┤\n")
    MsgC(C.BrandDark, "  │  ", C.Text, "GDT Studio Developer Runtime", C.Muted, " • ", realmCol, "[ " .. realmStr .. " ]", C.BrandDark, "               │\n")
    MsgC(C.BrandDark, "  ├────────────────────────────────────────────────────────────────┤\n")

    -- Shared Config & CAMI
    SafeLoad("shared", "gdt/sh_config.lua", "CONFIG")
    SafeLoad("shared", "gdt/sh_cami.lua", "CAMI")

    -- Core Engines & RPCs
    SafeLoad("server", "gdt/core/sv_diagnostics.lua", "DIAGNOSTICS")
    SafeLoad("server", "gdt/core/sv_lua_runner.lua", "REPL-RUNNER")
    SafeLoad("server", "gdt/core/sv_entity_inspector.lua", "ENTITY-CORE")
    SafeLoad("server", "gdt/core/sv_hook_matrix.lua", "HOOK-MATRIX")
    SafeLoad("server", "gdt/core/sv_net_traffic.lua", "NET-SNIFFER")
    SafeLoad("server", "gdt/core/sv_error_tracker.lua", "ERROR-CORE")
    SafeLoad("server", "gdt/core/sv_addon_scanner.lua", "ADDON-CORE")
    SafeLoad("server", "gdt/core/sv_network.lua", "NETWORK")

    -- Client UI Theme & Visualizers
    SafeLoad("client", "gdt/ui_lib/cl_theme.lua", "UI-THEME")
    SafeLoad("client", "gdt/ui_lib/cl_world_halo.lua", "UI-HALO")

    -- Client VGUI Subpanels & Cockpit Frame
    SafeLoad("client", "gdt/vgui/cl_tab_dashboard.lua", "VGUI-DASHBOARD")
    SafeLoad("client", "gdt/vgui/cl_tab_repl.lua", "VGUI-REPL")
    SafeLoad("client", "gdt/vgui/cl_tab_entity_inspector.lua", "VGUI-ENTITIES")
    SafeLoad("client", "gdt/vgui/cl_tab_hook_matrix.lua", "VGUI-HOOKS")
    SafeLoad("client", "gdt/vgui/cl_tab_network_sniffer.lua", "VGUI-NETWORK")
    SafeLoad("client", "gdt/vgui/cl_tab_error_monitor.lua", "VGUI-ERRORS")
    SafeLoad("client", "gdt/vgui/cl_tab_addon_scanner.lua", "VGUI-ADDONS")
    SafeLoad("client", "gdt/vgui/cl_frame.lua", "VGUI-STUDIO")

    local elapsed = (SysTime() - t0) * 1000
    MsgC(C.BrandDark, "  ├────────────────────────────────────────────────────────────────┤\n")
    MsgC(
        C.BrandDark, "  │ ",
        stats.errors == 0 and C.Success or C.Error,
        stats.errors == 0 and "✓ ALL COMPONENTS OPERATIONAL" or ("⚠ " .. stats.errors .. " ERRORS ENCOUNTERED"),
        C.Muted, " • ",
        C.Text, string.format("Mounted %d files in %.2fms", stats.total, elapsed),
        "\n"
    )
    MsgC(C.BrandDark, "  └────────────────────────────────────────────────────────────────┘\n\n")
end

LoadGDT()

concommand.Add("gdt_reload", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    LoadGDT()
    if IsValid(ply) then
        ply:ChatPrint("[GDT Studio] Successfully reloaded all components.")
    end
end)
