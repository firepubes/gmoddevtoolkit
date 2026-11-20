-- ==========================================================
-- GDT STUDIO - SYSTEM DASHBOARD & ROLLING TELEMETRY
-- Live Performance Gauges, History Graphs & Memory Cleaner
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI
local PANEL = {}

local tpsHistory = {}
local frameTimeHistory = {}
local maxHistory = 45

function PANEL:Init()
    self.Data = {
        summary = {
            hostname = "Garry's Mod Server",
            map = "unknown",
            gamemode = "sandbox",
            os = "Unknown",
            tps = 66.6,
            targetTps = 66.6,
            frameTimeMs = 15.0,
            luaMemoryKB = 0,
            playerCount = 0,
            maxPlayers = 32,
            entityCount = 0,
            awakePhysics = 0,
            uptime = 0,
        },
        history = {}
    }

    -- Top Header Bar
    self.TopBar = self:Add("DPanel")
    self.TopBar:Dock(TOP)
    self.TopBar:SetTall(UI:Scale(42))
    self.TopBar:DockMargin(0, 0, 0, 8)
    self.TopBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        draw.SimpleText("SYSTEM DIAGNOSTICS & ENGINE METRICS", "GDT:Title", 14, h / 2, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local refreshBtn = self.TopBar:Add("DButton")
    refreshBtn:Dock(RIGHT)
    refreshBtn:SetWide(UI:Scale(120))
    refreshBtn:DockMargin(0, 6, 8, 6)
    refreshBtn:SetText("REFRESH")
    refreshBtn:SetFont("GDT:Badge")
    refreshBtn:SetTextColor(UI:GetColor("Primary"))
    refreshBtn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, isHov and UI:GetColor("Primary") or UI:GetColor("Border"), 4)
    end
    refreshBtn.DoClick = function()
        self:RequestData()
    end

    local gcBtn = self.TopBar:Add("DButton")
    gcBtn:Dock(RIGHT)
    gcBtn:SetWide(UI:Scale(150))
    gcBtn:DockMargin(0, 6, 6, 6)
    gcBtn:SetText("🧹  FORCE SERVER GC")
    gcBtn:SetFont("GDT:Badge")
    gcBtn:SetTextColor(UI:GetColor("Warning"))
    gcBtn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("WarningBg") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Warning"), 4)
    end
    gcBtn.DoClick = function()
        surface.PlaySound("buttons/combine_button7.wav")
        net.Start("GDT:RequestGC")
        net.SendToServer()
    end

    -- KPI Cards Row
    self.CardsRow = self:Add("DPanel")
    self.CardsRow:Dock(TOP)
    self.CardsRow:SetTall(UI:Scale(76))
    self.CardsRow:DockMargin(0, 0, 0, 8)
    self.CardsRow.Paint = nil

    local cardsConfig = {
        {key = "tps", title = "SERVER TICKRATE", unit = "TPS", format = "%.1f", col = "Success"},
        {key = "frameTimeMs", title = "AVG FRAME TIME", unit = "ms", format = "%.2f", col = "Primary"},
        {key = "luaMemoryKB", title = "LUA RAM ALLOCATED", unit = "KiB", format = "%.0f", col = "Accent"},
        {key = "entityCount", title = "ACTIVE ENTITIES", unit = "Ents", format = "%d", col = "Warning"},
    }

    self.CardsRow.PerformLayout = function(s, w, h)
        local cw = (w - 3 * UI:Scale(8)) / 4
        for idx, child in ipairs(s:GetChildren()) do
            child:SetPos((idx - 1) * (cw + UI:Scale(8)), 0)
            child:SetSize(cw, h)
        end
    end

    for _, cfg in ipairs(cardsConfig) do
        local c = self.CardsRow:Add("DPanel")
        c.Paint = function(s, w, h)
            UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
            draw.SimpleText(cfg.title, "GDT:Badge", 12, 10, UI:GetColor("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            local sData = self.Data.summary or {}
            local val = sData[cfg.key] or 0
            local valText = string.format(cfg.format, val)
            local col = UI:GetColor(cfg.col)

            if cfg.key == "tps" then
                col = (val >= 55 and UI:GetColor("Success")) or (val >= 40 and UI:GetColor("Warning") or UI:GetColor("Danger"))
            end

            draw.SimpleText(valText, "GDT:MonoLarge", 12, h - 12, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
            draw.SimpleText(cfg.unit, "GDT:Badge", w - 12, h - 16, UI:GetColor("TextDim"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end
    end

    -- Split View: Left is Graphs, Right is System Information Panel
    self.Splitter = self:Add("DPanel")
    self.Splitter:Dock(FILL)
    self.Splitter.Paint = nil

    self.GraphPanel = self.Splitter:Add("DPanel")
    self.InfoPanel = self.Splitter:Add("DPanel")

    self.Splitter.PerformLayout = function(s, w, h)
        local leftW = math.floor(w * 0.65)
        self.GraphPanel:SetPos(0, 0)
        self.GraphPanel:SetSize(leftW, h)

        self.InfoPanel:SetPos(leftW + UI:Scale(8), 0)
        self.InfoPanel:SetSize(w - leftW - UI:Scale(8), h)
    end

    self.GraphPanel.Paint = function(s, w, h)
        local halfH = math.floor((h - UI:Scale(8)) / 2)
        local sData = self.Data.summary or {}

        local tpsCol = (sData.tps >= 55 and UI:GetColor("Success")) or (sData.tps >= 40 and UI:GetColor("Warning") or UI:GetColor("Danger"))
        local tpsBg = Color(tpsCol.r, tpsCol.g, tpsCol.b, 20)

        UI:DrawRollingGraph(
            0, 0, w, halfH,
            tpsHistory,
            0, sData.targetTps or 66.6,
            tpsCol, tpsBg,
            "ROLLING TICKRATE (TPS)",
            string.format("%.1f / %.1f TPS", sData.tps or 0, sData.targetTps or 66.6)
        )

        local ftCol = (sData.frameTimeMs <= 20 and UI:GetColor("Primary")) or (sData.frameTimeMs <= 35 and UI:GetColor("Warning") or UI:GetColor("Danger"))
        local ftBg = Color(ftCol.r, ftCol.g, ftCol.b, 20)

        UI:DrawRollingGraph(
            0, halfH + UI:Scale(8), w, halfH,
            frameTimeHistory,
            0, 40,
            ftCol, ftBg,
            "FRAME EXECUTION TIME (ms)",
            string.format("%.2f ms", sData.frameTimeMs or 0)
        )
    end

    self.InfoPanel.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        draw.SimpleText("ENVIRONMENT & ENGINE RUNTIME", "GDT:Badge", 14, 12, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local sData = self.Data.summary or {}
        local y = UI:Scale(36)
        local items = {
            {"Server Hostname", sData.hostname or "Garry's Mod"},
            {"Active Map", sData.map or "unknown"},
            {"Running Gamemode", sData.gamemode or "sandbox"},
            {"Operating System", sData.os or "Unknown"},
            {"Connected Players", (sData.playerCount or 0) .. " / " .. (sData.maxPlayers or 32)},
            {"Awake Physics Props", tostring(sData.awakePhysics or 0)},
            {"Server Uptime", string.format("%dh %02dm %02ds", math.floor((sData.uptime or 0) / 3600), math.floor(((sData.uptime or 0) % 3600) / 60), (sData.uptime or 0) % 60)},
        }

        for _, it in ipairs(items) do
            draw.SimpleText(it[1], "GDT:Regular", 14, y, UI:GetColor("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local valText = it[2]
            if #valText > 24 then valText = string.sub(valText, 1, 22) .. ".." end
            draw.SimpleText(valText, "GDT:MonoBold", w - 14, y, UI:GetColor("Text"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

            surface.SetDrawColor(UI:GetColor("Border"))
            surface.DrawLine(14, y + UI:Scale(22), w - 14, y + UI:Scale(22))
            y = y + UI:Scale(28)
        end
    end

    net.Receive("GDT:SendDiagnostics", function()
        local data = UI:ReadCompressed()
        if not IsValid(self) then return end
        self.Data = data or {}
        self:OnTelemetryUpdate(self.Data.summary or {})
    end)

    net.Receive("GDT:SendGCFeedback", function()
        local res = UI:ReadCompressed()
        local msg = string.format("✓ Garbage Collection complete in %.2fms. Reclaimed %.2f MB Lua RAM!", res.elapsedMs or 0, res.reclaimedMB or 0)
        notification.AddLegacy(msg, NOTIFY_GENERIC, 4)
        surface.PlaySound("buttons/bell1.wav")
        self:RequestData()
    end)

    self:RequestData()
end

function PANEL:RequestData()
    net.Start("GDT:RequestDiagnostics")
    net.SendToServer()
end

function PANEL:OnTelemetryUpdate(summary)
    self.Data.summary = summary

    table.insert(tpsHistory, summary.tps or 66.6)
    if #tpsHistory > maxHistory then table.remove(tpsHistory, 1) end

    table.insert(frameTimeHistory, summary.frameTimeMs or 15.0)
    if #frameTimeHistory > maxHistory then table.remove(frameTimeHistory, 1) end
end

vgui.Register("GDT:TabDashboard", PANEL, "EditablePanel")
