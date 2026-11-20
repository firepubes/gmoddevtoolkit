-- ==========================================================
-- GDT STUDIO - LUA ERROR MONITOR & STACK DEMANGLER
-- Deduplication, Stack Inspection, Discord Report & Export
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI
local PANEL = {}

function PANEL:Init()
    self.Errors = {}
    self.FilterText = ""

    -- Top Header Bar
    self.TopBar = self:Add("DPanel")
    self.TopBar:Dock(TOP)
    self.TopBar:SetTall(UI:Scale(42))
    self.TopBar:DockMargin(0, 0, 0, 8)
    self.TopBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        draw.SimpleText("LUA ERROR MONITOR & FORENSIC STACK TRACER", "GDT:Title", 14, h / 2, UI:GetColor("Danger"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local pollBtn = self.TopBar:Add("DButton")
    pollBtn:Dock(RIGHT)
    pollBtn:SetWide(UI:Scale(100))
    pollBtn:DockMargin(0, 6, 8, 6)
    pollBtn:SetText("POLL ERRORS")
    pollBtn:SetFont("GDT:Badge")
    pollBtn:SetTextColor(UI:GetColor("Text"))
    pollBtn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Border"), 4)
    end
    pollBtn.DoClick = function()
        self:RequestErrors()
    end

    local clearBtn = self.TopBar:Add("DButton")
    clearBtn:Dock(RIGHT)
    clearBtn:SetWide(UI:Scale(100))
    clearBtn:DockMargin(0, 6, 6, 6)
    clearBtn:SetText("CLEAR")
    clearBtn:SetFont("GDT:Badge")
    clearBtn:SetTextColor(UI:GetColor("Danger"))
    clearBtn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("DangerBg") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Danger"), 4)
    end
    clearBtn.DoClick = function()
        Derma_Query("Clear all captured errors from memory?", "Confirm Clear", "Clear All", function()
            net.Start("GDT:ClearErrors")
            net.SendToServer()
            timer.Simple(0.2, function() self:RequestErrors() end)
        end, "Cancel")
    end

    local copyBtn = self.TopBar:Add("DButton")
    copyBtn:Dock(RIGHT)
    copyBtn:SetWide(UI:Scale(140))
    copyBtn:DockMargin(0, 6, 6, 6)
    copyBtn:SetText("COPY DISCORD REPORT")
    copyBtn:SetFont("GDT:Badge")
    copyBtn:SetTextColor(UI:GetColor("Primary"))
    copyBtn.Paint = function(s, w, h)
        local isHov = s:IsHovered()
        local bg = isHov and UI:GetColor("CardHover") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Border"), 4)
    end
    copyBtn.DoClick = function()
        local lines = {"### 🛠️ GDT Lua Error Report"}
        for _, err in ipairs(self.Errors) do
            table.insert(lines, string.format("- `[%s]` **%s** (%dx) - %s", string.upper(err.realm), err.message, err.count or 1, err.addon or "Unknown"))
        end
        SetClipboardText(table.concat(lines, "\n"))
        notification.AddLegacy("Copied Markdown report to clipboard!", NOTIFY_GENERIC, 4)
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
    self.SearchBox:SetPlaceholderText("Filter errors by message, addon, or realm...")
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

    net.Receive("GDT:SendErrors", function()
        local data = UI:ReadCompressed()
        if not IsValid(self) then return end
        self.Errors = data or {}
        self:Populate()
    end)

    self:RequestErrors()
end

function PANEL:RequestErrors()
    net.Start("GDT:RequestErrors")
    net.SendToServer()
end

function PANEL:Populate()
    self.Scroll:GetCanvas():Clear()

    if #self.Errors == 0 then
        local empty = self.Scroll:Add("DPanel")
        empty:Dock(TOP)
        empty:SetTall(UI:Scale(80))
        empty.Paint = function(s, w, h)
            draw.SimpleText("✓ Zero Lua errors reported! Runtime execution is healthy.", "GDT:Subtitle", w / 2, h / 2, UI:GetColor("Success"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    for idx, err in ipairs(self.Errors) do
        local match = (self.FilterText == "") or
            string.find(string.lower(err.message), self.FilterText, 1, true) or
            string.find(string.lower(err.addon or ""), self.FilterText, 1, true) or
            string.find(string.lower(err.realm or ""), self.FilterText, 1, true)

        if match then
            local card = self.Scroll:Add("DButton")
            card:Dock(TOP)
            card:DockMargin(0, 0, 0, 4)
            card:SetTall(UI:Scale(52))
            card:SetText("")

            local isAlt = (idx % 2 == 0)
            card.Paint = function(s, w, h)
                local isHov = s:IsHovered()
                local bg = isHov and UI:GetColor("CardHover") or (isAlt and UI:GetColor("GridAlt") or UI:GetColor("Card"))
                UI:DrawStudioBox(0, 0, w, h, bg, isHov and UI:GetColor("Danger") or UI:GetColor("Border"), 4)

                -- Realm Badge
                local isServer = (err.realm == "server")
                UI:DrawBadge(string.upper(err.realm), 10, 10, UI:GetColor("Overlay"), isServer and UI:GetColor("Primary") or UI:GetColor("Warning"), "GDT:Badge")

                -- Count Badge
                if (err.count or 1) > 1 then
                    UI:DrawBadge("x" .. err.count, UI:Scale(75), 10, UI:GetColor("DangerBg"), UI:GetColor("Danger"), "GDT:Badge")
                end

                -- Error Message
                local msgText = err.message
                if #msgText > 120 then msgText = string.sub(msgText, 1, 118) .. ".." end
                draw.SimpleText(msgText, "GDT:MonoBold", UI:Scale(125), 18, UI:GetColor("Danger"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                -- Addon / Source Subtitle
                draw.SimpleText("Addon: " .. (err.addon or "Unknown") .. "  •  Source: " .. (err.source or "Engine"), "GDT:Regular", 10, h - 10, UI:GetColor("TextDim"), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

                -- Time
                draw.SimpleText(err.lastTimeFormatted or err.timeFormatted or "", "GDT:Mono", w - 12, h / 2, UI:GetColor("TextDim"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            card.DoClick = function()
                surface.PlaySound("buttons/combine_button7.wav")
                local details = "ERROR MESSAGE:\n" .. err.message .. "\n\nSTACK TRACE:\n" .. (err.stack or "No stack available.") .. "\n\nOCCURRENCES: " .. (err.count or 1) .. "\nREALM: " .. string.upper(err.realm)
                Derma_Message(details, "Lua Error Forensic Inspector", "Close")
            end
        end
    end
end

vgui.Register("GDT:TabErrorMonitor", PANEL, "EditablePanel")
