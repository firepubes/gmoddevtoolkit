-- ==========================================================
-- GDT STUDIO - MASTER COCKPIT FRAME & TAB CONTROLLER
-- Multi-Tab Developer Cockpit, REPL, Entity & Hook Matrix
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI
local PANEL = {}

GDT.MainFrame = nil

function PANEL:Init()
    GDT.MainFrame = self
    local margin = UI:Scale(8)

    self:SetSize(math.Clamp(UI:Scale(1180), 920, ScrW() - 20), math.Clamp(UI:Scale(720), 560, ScrH() - 20))
    self:Center()
    self:SetTitle("")
    self:MakePopup()
    self:ShowCloseButton(false)

    self.ActiveTab = "dashboard"

    -- Frame Background
    self.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Background"), UI:GetColor("Border"), 8)

        -- Top Navigation Bar
        surface.SetDrawColor(UI:GetColor("BackgroundNav"))
        surface.DrawRect(1, 1, w - 2, UI:Scale(46))
        surface.SetDrawColor(UI:GetColor("Border"))
        surface.DrawLine(0, UI:Scale(46), w, UI:Scale(46))

        -- Brand Emblem & Title
        draw.SimpleText("GDT STUDIO", "GDT:Hero", 16, UI:Scale(23), UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("DEVELOPER TOOLKIT & RUNTIME INSPECTOR", "GDT:Badge", UI:Scale(160), UI:Scale(24), UI:GetColor("TextDim"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Close Button
    local closeBtn = self:Add("DButton")
    closeBtn:SetSize(UI:Scale(32), UI:Scale(32))
    closeBtn:SetPos(self:GetWide() - UI:Scale(38), 7)
    closeBtn:SetText("✕")
    closeBtn:SetFont("GDT:Title")
    closeBtn:SetTextColor(UI:GetColor("TextMuted"))
    closeBtn.Paint = function(s, w, h)
        if s:IsHovered() then s:SetTextColor(UI:GetColor("Danger")) else s:SetTextColor(UI:GetColor("TextMuted")) end
    end
    closeBtn.DoClick = function()
        surface.PlaySound("ui/buttonclickrelease.wav")
        self:Remove()
    end

    -- Tab Navigation
    local tabs = {
        {id = "dashboard", title = "DASHBOARD"},
        {id = "repl",      title = "LUA REPL"},
        {id = "entities",  title = "3D ENTITY INSPECTOR"},
        {id = "hooks",     title = "HOOK MATRIX"},
        {id = "network",   title = "NETWORK SNIFFER"},
        {id = "errors",    title = "ERROR MONITOR"},
        {id = "addons",    title = "ADDON SCANNER"},
    }

    self.TabContainer = self:Add("DPanel")
    self.TabContainer:SetPos(UI:Scale(390), UI:Scale(8))
    self.TabContainer:SetSize(self:GetWide() - UI:Scale(440), UI:Scale(32))
    self.TabContainer.Paint = nil

    self.TabButtons = {}
    local tabW = math.floor((self.TabContainer:GetWide() - (#tabs - 1) * 4) / #tabs)

    for idx, tab in ipairs(tabs) do
        local btn = self.TabContainer:Add("DButton")
        btn:SetPos((idx - 1) * (tabW + 4), 0)
        btn:SetSize(tabW, UI:Scale(32))
        btn:SetText("")
        btn.Paint = function(s, w, h)
            local isActive = (self.ActiveTab == tab.id)
            local isHov = s:IsHovered()
            local bg = isActive and UI:GetColor("Card") or (isHov and UI:GetColor("CardHover") or Color(0, 0, 0, 0))
            draw.RoundedBox(4, 0, 0, w, h, bg)
            if isActive then
                surface.SetDrawColor(UI:GetColor("Primary"))
                surface.DrawRect(4, h - 2, w - 8, 2)
            end

            local col = isActive and UI:GetColor("Primary") or (isHov and UI:GetColor("Text") or UI:GetColor("TextMuted"))
            draw.SimpleText(tab.title, "GDT:Badge", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            surface.PlaySound("ui/buttonclickrelease.wav")
            self:SelectTab(tab.id)
        end
        self.TabButtons[tab.id] = btn
    end

    -- Content Area
    local contentY = UI:Scale(54)
    local contentW = self:GetWide() - margin * 2
    local contentH = self:GetTall() - contentY - margin

    self.ContentArea = self:Add("DPanel")
    self.ContentArea:SetPos(margin, contentY)
    self.ContentArea:SetSize(contentW, contentH)
    self.ContentArea.Paint = nil

    -- 1. Dashboard Tab
    self.TabDashboard = self.ContentArea:Add("GDT:TabDashboard")
    self.TabDashboard:Dock(FILL)

    -- 2. Lua REPL Tab
    self.TabREPL = self.ContentArea:Add("GDT:TabREPL")
    self.TabREPL:Dock(FILL)
    self.TabREPL:SetVisible(false)

    -- 3. 3D Entity Inspector Tab
    self.TabEntities = self.ContentArea:Add("GDT:TabEntityInspector")
    self.TabEntities:Dock(FILL)
    self.TabEntities:SetVisible(false)

    -- 4. Hook Matrix Tab
    self.TabHooks = self.ContentArea:Add("GDT:TabHookMatrix")
    self.TabHooks:Dock(FILL)
    self.TabHooks:SetVisible(false)

    -- 5. Network Sniffer Tab
    self.TabNetwork = self.ContentArea:Add("GDT:TabNetworkSniffer")
    self.TabNetwork:Dock(FILL)
    self.TabNetwork:SetVisible(false)

    -- 6. Error Monitor Tab
    self.TabErrors = self.ContentArea:Add("GDT:TabErrorMonitor")
    self.TabErrors:Dock(FILL)
    self.TabErrors:SetVisible(false)

    -- 7. Addon Scanner Tab
    self.TabAddons = self.ContentArea:Add("GDT:TabAddonScanner")
    self.TabAddons:Dock(FILL)
    self.TabAddons:SetVisible(false)

    -- Subscribe to live telemetry
    net.Start("GDT:Subscribe")
    net.SendToServer()

    self:SelectTab("dashboard")
end

function PANEL:OnRemove()
    GDT.MainFrame = nil
    if GDT.Halo and GDT.Halo.Clear then GDT.Halo:Clear() end
    net.Start("GDT:Unsubscribe")
    net.SendToServer()
end

function PANEL:SelectTab(id)
    self.ActiveTab = id

    self.TabDashboard:SetVisible(id == "dashboard")
    self.TabREPL:SetVisible(id == "repl")
    self.TabEntities:SetVisible(id == "entities")
    self.TabHooks:SetVisible(id == "hooks")
    self.TabNetwork:SetVisible(id == "network")
    self.TabErrors:SetVisible(id == "errors")
    self.TabAddons:SetVisible(id == "addons")

    if id == "dashboard" and self.TabDashboard.RequestData then
        self.TabDashboard:RequestData()
    elseif id == "hooks" and self.TabHooks.RequestRegistry then
        self.TabHooks:RequestRegistry()
    elseif id == "network" and self.TabNetwork.RequestData then
        self.TabNetwork:RequestData()
    elseif id == "errors" and self.TabErrors.RequestErrors then
        self.TabErrors:RequestErrors()
    elseif id == "addons" and self.TabAddons.RequestData then
        self.TabAddons:RequestData()
    end
end

vgui.Register("GDT:Frame", PANEL, "DFrame")

-- ----------------------------------------------------------
-- Global UI Handlers
-- ----------------------------------------------------------
function GDT:OpenStudio()
    if IsValid(GDT.MainFrame) then
        GDT.MainFrame:Remove()
        GDT.MainFrame = nil
        return
    end

    vgui.Create("GDT:Frame")
    surface.PlaySound("buttons/combine_button7.wav")
end

net.Receive("GDT:Open", function()
    GDT:OpenStudio()
end)

net.Receive("GDT:SendTelemetry", function()
    local data = UI:ReadCompressed()
    if IsValid(GDT.MainFrame) and GDT.MainFrame.TabDashboard then
        GDT.MainFrame.TabDashboard:OnTelemetryUpdate(data)
    end
end)

net.Receive("GDT:SendActionFeedback", function()
    local success = net.ReadBool()
    local msg = net.ReadString()

    notification.AddLegacy("[GDT Studio] " .. msg, success and NOTIFY_GENERIC or NOTIFY_ERROR, 4)
    surface.PlaySound(success and "buttons/button14.wav" or "buttons/button10.wav")
end)
