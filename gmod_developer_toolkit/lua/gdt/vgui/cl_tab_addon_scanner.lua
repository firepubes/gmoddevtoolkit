-- ==========================================================
-- GDT STUDIO - ADDON ARCHITECTURE & CONFLICT DETECTOR
-- Workshop Metadata, Local Discovery & File Shadowing Scanner
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI
local PANEL = {}

function PANEL:Init()
    self.Data = {
        workshop = {},
        localAddons = {},
        collisions = {},
    }
    self.CurrentSub = "local" -- "local", "collisions", "workshop"

    -- Top Header Bar
    self.TopBar = self:Add("DPanel")
    self.TopBar:Dock(TOP)
    self.TopBar:SetTall(UI:Scale(42))
    self.TopBar:DockMargin(0, 0, 0, 8)
    self.TopBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        draw.SimpleText("ADDON ARCHITECTURE & CONFLICT SCANNER", "GDT:Title", 14, h / 2, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local pollBtn = self.TopBar:Add("DButton")
    pollBtn:Dock(RIGHT)
    pollBtn:SetWide(UI:Scale(110))
    pollBtn:DockMargin(0, 6, 8, 6)
    pollBtn:SetText("POLL ADDONS")
    pollBtn:SetFont("GDT:Badge")
    pollBtn:SetTextColor(UI:GetColor("Primary"))
    pollBtn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, isHov and UI:GetColor("Primary") or UI:GetColor("Border"), 4)
    end
    pollBtn.DoClick = function()
        self:RequestData()
    end

    -- Sub Navigation
    self.SubNav = self:Add("DPanel")
    self.SubNav:Dock(TOP)
    self.SubNav:SetTall(UI:Scale(32))
    self.SubNav:DockMargin(0, 0, 0, 6)
    self.SubNav.Paint = nil

    local subTabs = {
        {id = "local",      label = "LOCAL ADDON FOLDERS"},
        {id = "collisions", label = "FILE SHADOWING COLLISIONS"},
        {id = "workshop",   label = "MOUNTED WORKSHOP ITEMS"},
    }

    local subW = UI:Scale(220)
    for idx, st in ipairs(subTabs) do
        local btn = self.SubNav:Add("DButton")
        btn:SetPos((idx - 1) * (subW + UI:Scale(6)), 0)
        btn:SetSize(subW, UI:Scale(32))
        btn:SetText("")
        btn.Paint = function(s, w, h)
            local isAct = (self.CurrentSub == st.id)
            local isHov = s:IsHovered()
            local bg = isAct and UI:GetColor("Card") or (isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay"))
            UI:DrawStudioBox(0, 0, w, h, bg, isAct and UI:GetColor("Primary") or UI:GetColor("Border"), 4)

            local col = isAct and UI:GetColor("Primary") or (isHov and UI:GetColor("Text") or UI:GetColor("TextMuted"))
            draw.SimpleText(st.label, "GDT:Badge", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            self.CurrentSub = st.id
            self:Populate()
        end
    end

    -- Scroll Area
    self.Scroll = self:Add("DScrollPanel")
    self.Scroll:Dock(FILL)
    UI:ApplyScrollbar(self.Scroll)

    net.Receive("GDT:SendAddons", function()
        local data = UI:ReadCompressed()
        if not IsValid(self) then return end
        self.Data = data or {}
        self:Populate()
    end)

    self:RequestData()
end

function PANEL:RequestData()
    net.Start("GDT:RequestAddons")
    net.SendToServer()
end

function PANEL:Populate()
    self.Scroll:GetCanvas():Clear()

    if self.CurrentSub == "collisions" then
        self:PopulateCollisions()
    elseif self.CurrentSub == "workshop" then
        self:PopulateWorkshop()
    else
        self:PopulateLocal()
    end
end

function PANEL:PopulateLocal()
    local addons = self.Data.localAddons or {}
    if #addons == 0 then
        local empty = self.Scroll:Add("DPanel")
        empty:Dock(TOP)
        empty:SetTall(UI:Scale(80))
        empty.Paint = function(s, w, h)
            draw.SimpleText("No local addons discovered in garrysmod/addons/.", "GDT:Subtitle", w / 2, h / 2, UI:GetColor("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    for idx, a in ipairs(addons) do
        local row = self.Scroll:Add("DPanel")
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 2)
        row:SetTall(UI:Scale(32))

        local isAlt = (idx % 2 == 0)
        row.Paint = function(s, w, h)
            local bg = isAlt and UI:GetColor("GridAlt") or UI:GetColor("Card")
            draw.RoundedBox(0, 0, 0, w, h, bg)

            draw.SimpleText(a.name, "GDT:MonoBold", 10, h / 2, UI:GetColor("Text"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(a.path, "GDT:Mono", UI:Scale(240), h / 2, UI:GetColor("TextDim"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local statusText = a.hasLua and "LUA SCRIPTS FOUND" or "CONTENT ONLY"
            local statusCol = a.hasLua and UI:GetColor("Success") or UI:GetColor("TextMuted")
            draw.SimpleText(statusText, "GDT:Badge", w - 12, h / 2, statusCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

function PANEL:PopulateCollisions()
    local colls = self.Data.collisions or {}
    if #colls == 0 then
        local empty = self.Scroll:Add("DPanel")
        empty:Dock(TOP)
        empty:SetTall(UI:Scale(80))
        empty.Paint = function(s, w, h)
            draw.SimpleText("✓ No file shadowing or namespace collisions detected across addons!", "GDT:Subtitle", w / 2, h / 2, UI:GetColor("Success"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    for idx, c in ipairs(colls) do
        local row = self.Scroll:Add("DPanel")
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 4)
        row:SetTall(UI:Scale(46))

        row.Paint = function(s, w, h)
            UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Warning"), 4)

            draw.SimpleText("DUPLICATE FILE: " .. c.file, "GDT:MonoBold", 10, 10, UI:GetColor("Warning"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Provided by addons: " .. c.addons, "GDT:Regular", 10, h - 10, UI:GetColor("Text"), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            draw.SimpleText(c.count .. " CONFLICTING ADDONS", "GDT:Badge", w - 12, h / 2, UI:GetColor("Danger"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

function PANEL:PopulateWorkshop()
    local ws = self.Data.workshop or {}
    if #ws == 0 then
        local empty = self.Scroll:Add("DPanel")
        empty:Dock(TOP)
        empty:SetTall(UI:Scale(80))
        empty.Paint = function(s, w, h)
            draw.SimpleText("No mounted Workshop addons reported by engine.", "GDT:Subtitle", w / 2, h / 2, UI:GetColor("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    for idx, item in ipairs(ws) do
        local row = self.Scroll:Add("DPanel")
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 2)
        row:SetTall(UI:Scale(32))

        local isAlt = (idx % 2 == 0)
        row.Paint = function(s, w, h)
            local bg = isAlt and UI:GetColor("GridAlt") or UI:GetColor("Card")
            draw.RoundedBox(0, 0, 0, w, h, bg)

            draw.SimpleText(item.title, "GDT:Subtitle", 10, h / 2, UI:GetColor("Text"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("WSID: " .. item.wsid, "GDT:Mono", w - UI:Scale(140), h / 2, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local status = item.mounted and "MOUNTED" or "DOWNLOADED"
            draw.SimpleText(status, "GDT:Badge", w - 12, h / 2, item.mounted and UI:GetColor("Success") or UI:GetColor("TextMuted"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

vgui.Register("GDT:TabAddonScanner", PANEL, "EditablePanel")
