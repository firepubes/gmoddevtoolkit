-- ==========================================================
-- GDT STUDIO - DEVELOPER TOOLKIT CONFIGURATION & PRESETS
-- ==========================================================

GDT = GDT or {}
GDT.Config = GDT.Config or {}

-- Access Permissions
GDT.Config.MinUsergroup = "superadmin"
GDT.Config.CAMIPrivilege = "GDT:Access"

-- Chat & Console Triggers
GDT.Config.ChatCommands = { "!gdt", "/gdt", "!dev", "/dev", "!toolkit", "/toolkit", "!developer", "/developer" }
GDT.Config.ConsoleCommands = { "gdt_menu", "gdt", "gdt_studio" }

-- Performance & Sampling Limits
GDT.Config.MaxErrors = 250
GDT.Config.MaxHistory = 180
GDT.Config.TelemetryInterval = 1.0

-- DevStudio Cyber Dark Palette
GDT.Config.Theme = {
    Background       = Color(11, 15, 23, 255),    -- Deep Obsidian
    BackgroundNav    = Color(8, 11, 17, 255),     -- Darkest Charcoal
    Card             = Color(18, 24, 35, 255),    -- Slate Card
    CardHover        = Color(26, 35, 50, 255),    -- Hover Glow
    Overlay          = Color(13, 18, 27, 255),    -- Recessed Grid Inset
    Border           = Color(38, 52, 74, 200),    -- Subtle Steel Border
    BorderFocus      = Color(0, 212, 255, 255),   -- Active Input Glow
    
    Primary          = Color(0, 212, 255, 255),   -- Electric Cyan
    PrimaryHover     = Color(70, 230, 255, 255),
    Accent           = Color(140, 85, 255, 255),  -- Plasma Violet
    
    Success          = Color(50, 225, 120, 255),  -- Neon Green
    SuccessBg        = Color(50, 225, 120, 30),
    Warning          = Color(255, 185, 35, 255),  -- Amber Gold
    WarningBg        = Color(255, 185, 35, 30),
    Danger           = Color(255, 65, 85, 255),   -- Crimson Red
    DangerBg         = Color(255, 65, 85, 30),
    
    Text             = Color(240, 246, 255, 255), -- High Vis White
    TextMuted        = Color(135, 152, 175, 255), -- Steel Muted
    TextDim          = Color(85, 102, 125, 255),  -- Dim Code/Labels
    GridAlt          = Color(15, 20, 30, 255),    -- Alternating Rows
}

-- Built-in Lua REPL Snippets Library
GDT.Config.Snippets = {
    {
        name = "Player Roster & Network Stats",
        realm = "server",
        code = [[local plys = player.GetAll()
print(string.format("=== TOTAL CONNECTED PLAYERS: %d ===", #plys))
for _, ply in ipairs(plys) do
    local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or "None"
    print(string.format("[%s] %s | Ping: %dms | IP: %s | Active Weapon: %s",
        ply:SteamID(), ply:Nick(), ply:Ping(), ply:IPAddress(), wep))
end]]
    },
    {
        name = "Clean Server Ragdolls & Decals",
        realm = "server",
        code = [[local count = 0
for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
    if IsValid(ent) then ent:Remove() count = count + 1 end
end
for _, ply in ipairs(player.GetAll()) do
    ply:ConCommand("r_cleardecals")
end
print(string.format("✓ Cleaned %d ragdolls and dispatched decal wipe to all clients.", count))]]
    },
    {
        name = "Scan Entity Under Crosshair",
        realm = "server",
        code = [[local tr = player.GetByID(1):GetEyeTrace()
local ent = tr.Entity
if IsValid(ent) then
    print("=== TARGET ENTITY DUMP ===")
    print("Index: " .. ent:EntIndex())
    print("Class: " .. ent:GetClass())
    print("Model: " .. tostring(ent:GetModel()))
    print("Pos:   " .. tostring(ent:GetPos()))
    print("Solid: " .. ent:GetSolid())
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        print("Mass:  " .. phys:GetMass() .. " kg")
        print("Move:  " .. tostring(phys:IsMoveable()))
    end
else
    print("No valid entity under player 1 crosshair.")
end]]
    },
    {
        name = "Garbage Collection Benchmark",
        realm = "server",
        code = [[local before = collectgarbage("count")
local t0 = SysTime()
collectgarbage("collect")
local elapsed = (SysTime() - t0) * 1000
local after = collectgarbage("count")
local freed = before - after
print(string.format("GC Pass complete in %.2f ms.", elapsed))
print(string.format("Initial RAM: %.2f KiB | Post RAM: %.2f KiB | Reclaimed: %.2f KiB", before, after, freed))]]
    },
    {
        name = "Top 10 Entity Classes Census",
        realm = "server",
        code = [[local counts = {}
for _, e in ipairs(ents.GetAll()) do
    if IsValid(e) then
        local cls = e:GetClass()
        counts[cls] = (counts[cls] or 0) + 1
    end
end
local sorted = {}
for cls, num in pairs(counts) do table.insert(sorted, {cls = cls, num = num}) end
table.sort(sorted, function(a, b) return a.num > b.num end)
print("=== TOP ENTITY CLASSES ===")
for i = 1, math.min(10, #sorted) do
    print(string.format("%2d. %-30s : %d instances", i, sorted[i].cls, sorted[i].num))
end]]
    }
}
