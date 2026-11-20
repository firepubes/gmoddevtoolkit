-- ==========================================================
-- GDT STUDIO - 3D ENTITY INTROSPECTION & MANIPULATOR
-- Crosshair Raytracer, Property Sheet, Physics & Table Dump
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI
local PANEL = {}

function PANEL:Init()
    self.CurrentEntity = nil

    -- Top Controls Bar
    self.TopBar = self:Add("DPanel")
    self.TopBar:Dock(TOP)
    self.TopBar:SetTall(UI:Scale(42))
    self.TopBar:DockMargin(0, 0, 0, 8)
    self.TopBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        draw.SimpleText("3D ENTITY INSPECTOR & MANIPULATOR", "GDT:Title", 14, h / 2, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local rayBtn = self.TopBar:Add("DButton")
    rayBtn:Dock(RIGHT)
    rayBtn:SetWide(UI:Scale(220))
    rayBtn:DockMargin(0, 6, 8, 6)
    rayBtn:SetText("🎯  INSPECT UNDER CROSSHAIR")
    rayBtn:SetFont("GDT:Badge")
    rayBtn:SetTextColor(color_white)
    rayBtn.Paint = function(s, w, h)
        local bg = s:IsHovered() and UI:GetColor("PrimaryHover") or UI:GetColor("Primary")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Primary"), 4)
    end
    rayBtn.DoClick = function()
        surface.PlaySound("buttons/combine_button7.wav")
        net.Start("GDT:RequestRaytrace")
        net.SendToServer()
    end

    -- Manual Index Entry
    local indexBox = self.TopBar:Add("DTextEntry")
    indexBox:Dock(RIGHT)
    indexBox:SetWide(UI:Scale(100))
    indexBox:DockMargin(0, 6, 8, 6)
    indexBox:SetFont("GDT:Mono")
    indexBox:SetPlaceholderText("Ent Index")
    indexBox:SetNumeric(true)
    indexBox.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Overlay"), s:HasFocus() and UI:GetColor("BorderFocus") or UI:GetColor("Border"), 4)
        s:DrawTextEntryText(s:GetTextColor(), UI:GetColor("Primary"), s:GetTextColor())
    end
    indexBox.OnEnter = function(s)
        local idx = tonumber(s:GetText())
        if idx and idx >= 0 then
            net.Start("GDT:RequestInspect")
                net.WriteUInt(idx, 16)
            net.SendToServer()
        end
    end

    -- Action Buttons Card (Freeze, Ignite, Bring, Goto, Remove)
    self.ActionsBar = self:Add("DPanel")
    self.ActionsBar:Dock(TOP)
    self.ActionsBar:SetTall(UI:Scale(36))
    self.ActionsBar:DockMargin(0, 0, 0, 8)
    self.ActionsBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 4)
    end

    local function makeEntAction(title, actionKey, col)
        local btn = self.ActionsBar:Add("DButton")
        btn:Dock(LEFT)
        btn:SetWide(UI:Scale(110))
        btn:DockMargin(6, 4, 0, 4)
        btn:SetText(title)
        btn:SetFont("GDT:Badge")
        btn:SetTextColor(col)
        btn.Paint = function(s, w, h)
            local isHov = s:IsHovered()
            local bg = isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay")
            UI:DrawStudioBox(0, 0, w, h, bg, isHov and col or UI:GetColor("Border"), 3)
        end
        btn.DoClick = function()
            if not self.CurrentEntity or not self.CurrentEntity.index then
                notification.AddLegacy("Select an entity first!", NOTIFY_ERROR, 3)
                return
            end
            net.Start("GDT:RequestEntityAction")
                net.WriteUInt(self.CurrentEntity.index, 16)
                net.WriteString(actionKey)
            net.SendToServer()
        end
    end

    makeEntAction("❄ FREEZE", "freeze", UI:GetColor("Primary"))
    makeEntAction("⚡ UNFREEZE", "unfreeze", UI:GetColor("Success"))
    makeEntAction("🔥 IGNITE", "ignite", UI:GetColor("Warning"))
    makeEntAction("💧 EXTINGUISH", "extinguish", UI:GetColor("TextMuted"))
    makeEntAction("📦 BRING", "bring", UI:GetColor("Accent"))
    makeEntAction("🚀 GOTO", "goto", UI:GetColor("Primary"))
    makeEntAction("🗑 REMOVE", "remove", UI:GetColor("Danger"))

    -- Content Scroll Panel
    self.Scroll = self:Add("DScrollPanel")
    self.Scroll:Dock(FILL)
    UI:ApplyScrollbar(self.Scroll)

    self:DisplayEmpty()

    net.Receive("GDT:SendInspectResult", function()
        local res = UI:ReadCompressed()
        if not IsValid(self) then return end
        if res.success then
            self:DisplayEntity(res)
        else
            notification.AddLegacy("Inspection Failed: " .. (res.error or "Unknown"), NOTIFY_ERROR, 4)
        end
    end)
end

function PANEL:DisplayEmpty()
    self.Scroll:GetCanvas():Clear()
    local empty = self.Scroll:Add("DPanel")
    empty:Dock(TOP)
    empty:SetTall(UI:Scale(100))
    empty.Paint = function(s, w, h)
        draw.SimpleText("No entity currently inspected.", "GDT:Title", w / 2, h / 2 - 10, UI:GetColor("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Look at any prop/player and click 'INSPECT UNDER CROSSHAIR' or enter an entity index.", "GDT:Regular", w / 2, h / 2 + 14, UI:GetColor("TextDim"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function PANEL:DisplayEntity(data)
    self.CurrentEntity = data
    self.Scroll:GetCanvas():Clear()

    -- Attach 3D World Halo
    if GDT.Halo and GDT.Halo.SetTarget then
        GDT.Halo:SetTarget(data.index, UI:GetColor("Primary"))
    end

    -- Header Info Card
    local header = self.Scroll:Add("DPanel")
    header:Dock(TOP)
    header:SetTall(UI:Scale(64))
    header:DockMargin(0, 0, 0, 8)
    header.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        draw.SimpleText(data.class .. "  [#" .. data.index .. "]", "GDT:Title", 14, 12, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Owner: " .. data.owner .. "  •  CreationID: " .. data.creationID, "GDT:Regular", 14, h - 14, UI:GetColor("TextDim"), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end

    local function makeSectionCard(title, items)
        local cardH = UI:Scale(32) + #items * UI:Scale(24)
        local card = self.Scroll:Add("DPanel")
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, 8)
        card:SetTall(cardH)
        card.Paint = function(s, w, h)
            UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
            draw.SimpleText(title, "GDT:Badge", 12, 10, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            local y = UI:Scale(30)
            for _, it in ipairs(items) do
                draw.SimpleText(it[1], "GDT:Regular", 12, y, UI:GetColor("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(tostring(it[2]), "GDT:MonoBold", w - 12, y, UI:GetColor("Text"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                y = y + UI:Scale(24)
            end
        end
    end

    makeSectionCard("SPATIAL & ENGINE PROPERTIES", {
        {"Model Path", data.model},
        {"Position", data.pos},
        {"Angle", data.ang},
        {"Health / MaxHealth", data.health .. " / " .. data.maxHealth},
        {"Material", data.material},
        {"Render Color", data.color},
        {"MoveType", tostring(data.moveType)},
        {"CollisionGroup", tostring(data.collisionGroup)},
        {"Solid Type", tostring(data.solid)},
    })

    if data.physics then
        local p = data.physics
        makeSectionCard("PHYSICS OBJECT METRICS", {
            {"Mass", p.mass .. " kg"},
            {"Velocity", p.velocity .. " units/s"},
            {"Angular Velocity", p.angVelocity .. " deg/s"},
            {"Moveable / Unfrozen", tostring(p.isMoveable)},
            {"Asleep Status", tostring(p.isAsleep)},
            {"Physics Material", tostring(p.material)},
        })
    end

    -- Entity Table Dump
    local tblEntries = {}
    for k, v in pairs(data.tableData or {}) do
        table.insert(tblEntries, {k, v})
    end
    table.sort(tblEntries, function(a, b) return a[1] < b[1] end)

    if #tblEntries > 0 then
        makeSectionCard("ENTITY TABLE VARIABLES (ent:GetTable())", tblEntries)
    end
end

vgui.Register("GDT:TabEntityInspector", PANEL, "EditablePanel")
