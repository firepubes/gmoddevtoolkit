-- ==========================================================
-- GDT STUDIO - NETWORK TRAFFIC SNIFFER & RPC TEST BENCH
-- Net String Registry, Payload Sizes & Packet Dispatcher
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI
local PANEL = {}

function PANEL:Init()
    self.Data = {
        totalBytes = 0,
        totalPackets = 0,
        channels = {}
    }
    self.FilterText = ""

    -- Top Header Bar
    self.TopBar = self:Add("DPanel")
    self.TopBar:Dock(TOP)
    self.TopBar:SetTall(UI:Scale(42))
    self.TopBar:DockMargin(0, 0, 0, 8)
    self.TopBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        draw.SimpleText("NETWORK TRAFFIC & RPC DISPATCH BENCH", "GDT:Title", 14, h / 2, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local traffic = string.format("Inbound: %.2f KB  •  Packets: %d", (self.Data.totalBytes or 0) / 1024, self.Data.totalPackets or 0)
        draw.SimpleText(traffic, "GDT:MonoBold", w - UI:Scale(130), h / 2, UI:GetColor("Success"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local pollBtn = self.TopBar:Add("DButton")
    pollBtn:Dock(RIGHT)
    pollBtn:SetWide(UI:Scale(110))
    pollBtn:DockMargin(0, 6, 8, 6)
    pollBtn:SetText("POLL NET")
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

    -- Packet Dispatcher Card
    self.DispatchBar = self:Add("DPanel")
    self.DispatchBar:Dock(TOP)
    self.DispatchBar:SetTall(UI:Scale(38))
    self.DispatchBar:DockMargin(0, 0, 0, 6)
    self.DispatchBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 4)
        draw.SimpleText("DISPATCH TEST PACKET:", "GDT:Badge", 10, h / 2, UI:GetColor("TextDim"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local dispatchBtn = self.DispatchBar:Add("DButton")
    dispatchBtn:Dock(RIGHT)
    dispatchBtn:SetWide(UI:Scale(140))
    dispatchBtn:DockMargin(0, 4, 8, 4)
    dispatchBtn:SetText("▶  SEND PACKET")
    dispatchBtn:SetFont("GDT:Badge")
    dispatchBtn:SetTextColor(color_white)
    dispatchBtn.Paint = function(s, w, h)
        local bg = s:IsHovered() and UI:GetColor("PrimaryHover") or UI:GetColor("Primary")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Primary"), 3)
    end

    local payloadEntry = self.DispatchBar:Add("DTextEntry")
    payloadEntry:Dock(RIGHT)
    payloadEntry:SetWide(UI:Scale(220))
    payloadEntry:DockMargin(0, 4, 8, 4)
    payloadEntry:SetFont("GDT:Mono")
    payloadEntry:SetPlaceholderText("Optional String Payload...")
    payloadEntry.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Overlay"), UI:GetColor("Border"), 3)
        s:DrawTextEntryText(s:GetTextColor(), UI:GetColor("Primary"), s:GetTextColor())
    end

    local msgNameEntry = self.DispatchBar:Add("DTextEntry")
    msgNameEntry:Dock(FILL)
    msgNameEntry:DockMargin(UI:Scale(145), 4, 8, 4)
    msgNameEntry:SetFont("GDT:Mono")
    msgNameEntry:SetPlaceholderText("Net message name (e.g. MyAddon:TestRPC)...")
    msgNameEntry.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Overlay"), UI:GetColor("Border"), 3)
        s:DrawTextEntryText(s:GetTextColor(), UI:GetColor("Primary"), s:GetTextColor())
    end

    dispatchBtn.DoClick = function()
        local name = string.Trim(msgNameEntry:GetText())
        if name == "" then
            notification.AddLegacy("Enter a network string name first!", NOTIFY_ERROR, 3)
            return
        end
        net.Start("GDT:DispatchTestPacket")
            net.WriteString(name)
            net.WriteString(payloadEntry:GetText())
        net.SendToServer()
    end

    -- Search Bar
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
    self.SearchBox:SetPlaceholderText("Filter network channels by string name...")
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

    net.Receive("GDT:SendNetTraffic", function()
        local data = UI:ReadCompressed()
        if not IsValid(self) then return end
        self.Data = data or {}
        self:Populate()
    end)

    self:RequestData()
end

function PANEL:RequestData()
    net.Start("GDT:RequestNetTraffic")
    net.SendToServer()
end

function PANEL:Populate()
    self.Scroll:GetCanvas():Clear()

    local channels = self.Data.channels or {}
    if #channels == 0 then
        local empty = self.Scroll:Add("DPanel")
        empty:Dock(TOP)
        empty:SetTall(UI:Scale(80))
        empty.Paint = function(s, w, h)
            draw.SimpleText("No network traffic recorded yet.", "GDT:Subtitle", w / 2, h / 2, UI:GetColor("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    for idx, c in ipairs(channels) do
        if self.FilterText == "" or string.find(string.lower(c.name), self.FilterText, 1, true) then
            local row = self.Scroll:Add("DPanel")
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 2)
            row:SetTall(UI:Scale(32))

            local isAlt = (idx % 2 == 0)
            row.Paint = function(s, w, h)
                local bg = isAlt and UI:GetColor("GridAlt") or UI:GetColor("Card")
                draw.RoundedBox(0, 0, 0, w, h, bg)

                draw.SimpleText(c.name, "GDT:MonoBold", 10, h / 2, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                local stats = string.format("Packets: %d  •  %.2f KB  •  Last: %s", c.packets, c.bytes / 1024, c.lastSender)
                draw.SimpleText(stats, "GDT:Mono", w - 10, h / 2, UI:GetColor("Text"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end
    end
end

vgui.Register("GDT:TabNetworkSniffer", PANEL, "EditablePanel")
