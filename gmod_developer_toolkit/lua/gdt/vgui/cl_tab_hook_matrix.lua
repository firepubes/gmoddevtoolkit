-- ==========================================================
-- GDT STUDIO - HOOK MATRIX, SOURCE RESOLVER & PROFILER
-- Exact File/Line Debug Info, Opt-in Profiler & Live Suppression
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI
local PANEL = {}

function PANEL:Init()
    self.Hooks = {}
    self.ProfileResults = {}
    self.IsProfiling = false
    self.FilterText = ""
    self.ViewMode = "matrix" -- "matrix" or "profile"

    -- Top Header Bar
    self.TopBar = self:Add("DPanel")
    self.TopBar:Dock(TOP)
    self.TopBar:SetTall(UI:Scale(42))
    self.TopBar:DockMargin(0, 0, 0, 8)
    self.TopBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        local modeTitle = (self.ViewMode == "matrix") and "LIVE HOOK MATRIX & SOURCE RESOLVER" or "LUA HOOK PROFILER TIMINGS"
        draw.SimpleText(modeTitle, "GDT:Title", 14, h / 2, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local pollBtn = self.TopBar:Add("DButton")
    pollBtn:Dock(RIGHT)
    pollBtn:SetWide(UI:Scale(100))
    pollBtn:DockMargin(0, 6, 8, 6)
    pollBtn:SetText("POLL HOOKS")
    pollBtn:SetFont("GDT:Badge")
    pollBtn:SetTextColor(UI:GetColor("Primary"))
    pollBtn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, isHov and UI:GetColor("Primary") or UI:GetColor("Border"), 4)
    end
    pollBtn.DoClick = function()
        self:RequestRegistry()
    end

    local prof30Btn = self.TopBar:Add("DButton")
    prof30Btn:Dock(RIGHT)
    prof30Btn:SetWide(UI:Scale(125))
    prof30Btn:DockMargin(0, 6, 6, 6)
    prof30Btn:SetText("PROFILE (30s)")
    prof30Btn:SetFont("GDT:Badge")
    prof30Btn:SetTextColor(UI:GetColor("Accent"))
    prof30Btn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Border"), 4)
    end
    prof30Btn.DoClick = function()
        self:StartProfiler(30)
    end

    local prof10Btn = self.TopBar:Add("DButton")
    prof10Btn:Dock(RIGHT)
    prof10Btn:SetWide(UI:Scale(110))
    prof10Btn:DockMargin(0, 6, 6, 6)
    prof10Btn:SetText("PROFILE (10s)")
    prof10Btn:SetFont("GDT:Badge")
    prof10Btn:SetTextColor(UI:GetColor("Warning"))
    prof10Btn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Border"), 4)
    end
    prof10Btn.DoClick = function()
        self:StartProfiler(10)
    end

    -- Filter Bar
    self.FilterBar = self:Add("DPanel")
    self.FilterBar:Dock(TOP)
    self.FilterBar:SetTall(UI:Scale(34))
    self.FilterBar:DockMargin(0, 0, 0, 6)
    self.FilterBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 4)
    end

    self.SearchBox = self.FilterBar:Add("DTextEntry")
    self.SearchBox:Dock(FILL)
    self.SearchBox:DockMargin(8, 4, 8, 4)
    self.SearchBox:SetFont("GDT:Mono")
    self.SearchBox:SetTextColor(UI:GetColor("Text"))
    self.SearchBox:SetPlaceholderText("Filter hooks by event, identifier, or source file path...")
    self.SearchBox.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Overlay"), s:HasFocus() and UI:GetColor("BorderFocus") or UI:GetColor("Border"), 4)
        s:DrawTextEntryText(s:GetTextColor(), UI:GetColor("Primary"), s:GetTextColor())
    end
    self.SearchBox.OnValueChange = function(s, val)
        self.FilterText = string.lower(string.Trim(val or ""))
        self:Populate()
    end

    -- Scroll Area
    self.Scroll = self:Add("DScrollPanel")
    self.Scroll:Dock(FILL)
    UI:ApplyScrollbar(self.Scroll)

    net.Receive("GDT:SendHookRegistry", function()
        local data = UI:ReadCompressed()
        if not IsValid(self) then return end
        self.ViewMode = "matrix"
        self.Hooks = data or {}
        self:Populate()
    end)

    net.Receive("GDT:SendHookProfileResults", function()
        local data = UI:ReadCompressed()
        if not IsValid(self) then return end
        self.ViewMode = "profile"
        self.ProfileResults = data.results or {}
        self:Populate()
    end)

    self:RequestRegistry()
end

function PANEL:RequestRegistry()
    net.Start("GDT:RequestHookRegistry")
    net.SendToServer()
end

function PANEL:StartProfiler(secs)
    surface.PlaySound("buttons/combine_button7.wav")
    notification.AddLegacy("Started " .. secs .. "s hook profiling session...", NOTIFY_GENERIC, 4)
    net.Start("GDT:RequestHookProfile")
        net.WriteUInt(secs, 8)
    net.SendToServer()
end

function PANEL:Populate()
    self.Scroll:GetCanvas():Clear()

    if self.ViewMode == "profile" then
        self:PopulateProfile()
    else
        self:PopulateMatrix()
    end
end

function PANEL:PopulateMatrix()
    if #self.Hooks == 0 then
        local empty = self.Scroll:Add("DPanel")
        empty:Dock(TOP)
        empty:SetTall(UI:Scale(80))
        empty.Paint = function(s, w, h)
            draw.SimpleText("No hook callbacks retrieved.", "GDT:Subtitle", w / 2, h / 2, UI:GetColor("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    for idx, h in ipairs(self.Hooks) do
        local match = (self.FilterText == "") or
            string.find(string.lower(h.event), self.FilterText, 1, true) or
            string.find(string.lower(h.id), self.FilterText, 1, true) or
            string.find(string.lower(h.source), self.FilterText, 1, true)

        if match then
            local row = self.Scroll:Add("DPanel")
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 2)
            row:SetTall(UI:Scale(36))

            local isAlt = (idx % 2 == 0)
            local isSupp = h.suppressed

            row.Paint = function(s, w, h)
                local bg = isSupp and UI:GetColor("DangerBg") or (isAlt and UI:GetColor("GridAlt") or UI:GetColor("Card"))
                draw.RoundedBox(0, 0, 0, w, h, bg)

                -- Event Badge
                UI:DrawBadge(h.event, 8, (h - UI:Scale(18)) / 2, UI:GetColor("Overlay"), isSupp and UI:GetColor("Danger") or UI:GetColor("Primary"), "GDT:Badge")

                -- Identifier
                local idText = h.id
                if #idText > 36 then idText = string.sub(idText, 1, 34) .. ".." end
                draw.SimpleText(idText, "GDT:MonoBold", UI:Scale(160), h / 2, UI:GetColor("Text"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                -- Source File & Line
                local srcText = h.source .. (h.line > 0 and (":" .. h.line) or "")
                if #srcText > 65 then srcText = ".." .. string.sub(srcText, -62) end
                draw.SimpleText(srcText, "GDT:Mono", w - UI:Scale(180), h / 2, UI:GetColor("TextDim"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            local muteBtn = row:Add("DButton")
            muteBtn:Dock(RIGHT)
            muteBtn:SetWide(UI:Scale(80))
            muteBtn:DockMargin(0, 4, 8, 4)
            muteBtn:SetText(isSupp and "UNMUTE" or "MUTE")
            muteBtn:SetFont("GDT:Badge")
            muteBtn:SetTextColor(isSupp and UI:GetColor("Success") or UI:GetColor("Danger"))
            muteBtn.Paint = function(s, w, h)
                local bg = s:IsHovered() and UI:GetColor("CardHover") or UI:GetColor("Overlay")
                UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Border"), 3)
            end
            muteBtn.DoClick = function()
                net.Start("GDT:ToggleHookSuppression")
                    net.WriteString(h.event)
                    net.WriteString(h.id)
                net.SendToServer()
                timer.Simple(0.2, function() self:RequestRegistry() end)
            end
        end
    end
end

function PANEL:PopulateProfile()
    for idx, r in ipairs(self.ProfileResults) do
        local row = self.Scroll:Add("DPanel")
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 2)
        row:SetTall(UI:Scale(32))

        local isAlt = (idx % 2 == 0)
        row.Paint = function(s, w, h)
            local bg = isAlt and UI:GetColor("GridAlt") or UI:GetColor("Card")
            draw.RoundedBox(0, 0, 0, w, h, bg)

            draw.SimpleText(r.event .. " // " .. r.id, "GDT:MonoBold", 10, h / 2, UI:GetColor("Text"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local stats = string.format("Calls: %d  •  Avg: %.3f ms  •  Max: %.2f ms  •  Total: %.2f ms", r.calls, r.avgMs, r.maxMs, r.totalMs)
            draw.SimpleText(stats, "GDT:Mono", w - 10, h / 2, (r.maxMs > 10) and UI:GetColor("Danger") or UI:GetColor("Primary"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

vgui.Register("GDT:TabHookMatrix", PANEL, "EditablePanel")
