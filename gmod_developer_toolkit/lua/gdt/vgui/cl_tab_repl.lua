-- ==========================================================
-- GDT STUDIO - INTERACTIVE LUA REPL & CODE SANDBOX
-- Server & Client Code Runner, Output Terminal & Snippets
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI
local PANEL = {}

function PANEL:Init()
    self.SelectedRealm = "server"

    -- Top Controls & Snippets Bar
    self.TopBar = self:Add("DPanel")
    self.TopBar:Dock(TOP)
    self.TopBar:SetTall(UI:Scale(42))
    self.TopBar:DockMargin(0, 0, 0, 8)
    self.TopBar.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
        draw.SimpleText("INTERACTIVE LUA REPL & SANDBOX", "GDT:Title", 14, h / 2, UI:GetColor("Primary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Snippets Combo
    self.SnippetCombo = self.TopBar:Add("DComboBox")
    self.SnippetCombo:Dock(RIGHT)
    self.SnippetCombo:SetWide(UI:Scale(220))
    self.SnippetCombo:DockMargin(0, 6, 8, 6)
    self.SnippetCombo:SetFont("GDT:Mono")
    self.SnippetCombo:SetValue("Quick Dev Snippets...")
    for _, snip in ipairs(GDT.Config.Snippets or {}) do
        self.SnippetCombo:AddChoice(snip.name, snip)
    end
    self.SnippetCombo.OnSelect = function(s, idx, val, data)
        if data and data.code then
            self.CodeEditor:SetText(data.code)
            self.SelectedRealm = data.realm or "server"
        end
    end
    self.SnippetCombo.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Overlay"), UI:GetColor("Border"), 4)
        draw.SimpleText(s:GetText(), "GDT:Mono", 8, h / 2, UI:GetColor("Text"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Realm Selector Toggle
    self.RealmBtn = self.TopBar:Add("DButton")
    self.RealmBtn:Dock(RIGHT)
    self.RealmBtn:SetWide(UI:Scale(130))
    self.RealmBtn:DockMargin(0, 6, 8, 6)
    self.RealmBtn:SetText("")
    self.RealmBtn.Paint = function(s, w, h)
        local isServer = (self.SelectedRealm == "server")
        local bg = isServer and UI:GetColor("SuccessBg") or UI:GetColor("WarningBg")
        local border = isServer and UI:GetColor("Success") or UI:GetColor("Warning")
        UI:DrawStudioBox(0, 0, w, h, bg, border, 4)

        local label = isServer and "REALM: SERVER" or "REALM: CLIENT"
        draw.SimpleText(label, "GDT:Badge", w / 2, h / 2, border, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.RealmBtn.DoClick = function()
        self.SelectedRealm = (self.SelectedRealm == "server") and "client" or "server"
        surface.PlaySound("buttons/lightswitch2.wav")
    end

    -- Split View: Top is Code Editor, Bottom is Output Terminal
    self.Splitter = self:Add("DVerticalDivider")
    self.Splitter:Dock(FILL)
    self.Splitter:SetTopMin(UI:Scale(120))
    self.Splitter:SetBottomMin(UI:Scale(140))
    self.Splitter:SetDividerHeight(6)
    self.Splitter:SetTopHeight(UI:Scale(220))

    -- 1. Code Editor Panel
    self.EditorPanel = self:Add("DPanel")
    self.EditorPanel.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
    end

    self.CodeEditor = self.EditorPanel:Add("DTextEntry")
    self.CodeEditor:Dock(FILL)
    self.CodeEditor:DockMargin(8, 8, 8, 42)
    self.CodeEditor:SetMultiline(true)
    self.CodeEditor:SetFont("GDT:Mono")
    self.CodeEditor:SetTextColor(UI:GetColor("Text"))
    self.CodeEditor:SetText("-- Enter Lua code to execute\nprint('Server Uptime: ' .. CurTime() .. ' seconds')\nprint('Active Entities: ' .. ents.GetCount())")
    self.CodeEditor.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Overlay"), s:HasFocus() and UI:GetColor("BorderFocus") or UI:GetColor("Border"), 4)
        s:DrawTextEntryText(s:GetTextColor(), UI:GetColor("Primary"), s:GetTextColor())
    end

    -- Run Code Button
    self.RunBtn = self.EditorPanel:Add("DButton")
    self.RunBtn:SetSize(UI:Scale(140), UI:Scale(28))
    self.RunBtn:SetText("▶  EXECUTE LUA")
    self.RunBtn:SetFont("GDT:Badge")
    self.RunBtn:SetTextColor(color_white)
    self.RunBtn.Paint = function(s, w, h)
        local bg = s:IsHovered() and UI:GetColor("PrimaryHover") or UI:GetColor("Primary")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Primary"), 4)
    end
    self.RunBtn.DoClick = function()
        self:ExecuteCode()
    end

    -- Clear Editor Button
    self.ClearBtn = self.EditorPanel:Add("DButton")
    self.ClearBtn:SetSize(UI:Scale(80), UI:Scale(28))
    self.ClearBtn:SetText("CLEAR")
    self.ClearBtn:SetFont("GDT:Badge")
    self.ClearBtn:SetTextColor(UI:GetColor("TextMuted"))
    self.ClearBtn.Paint = function(s, w, h)
        local bg = s:IsHovered() and UI:GetColor("CardHover") or UI:GetColor("Overlay")
        UI:DrawStudioBox(0, 0, w, h, bg, UI:GetColor("Border"), 4)
    end
    self.ClearBtn.DoClick = function()
        self.CodeEditor:SetText("")
    end

    self.EditorPanel.PerformLayout = function(s, w, h)
        local btnY = h - UI:Scale(34)
        if IsValid(self.RunBtn) then self.RunBtn:SetPos(UI:Scale(8), btnY) end
        if IsValid(self.ClearBtn) then self.ClearBtn:SetPos(UI:Scale(156), btnY) end
    end

    -- 2. Output Terminal Panel
    self.TerminalPanel = self:Add("DPanel")
    self.TerminalPanel.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Card"), UI:GetColor("Border"), 6)
    end

    self.StatusHeader = self.TerminalPanel:Add("DPanel")
    self.StatusHeader:Dock(TOP)
    self.StatusHeader:SetTall(UI:Scale(32))
    self.StatusHeader:DockMargin(6, 6, 6, 4)
    self.StatusHeader.StatusText = "Console output ready."
    self.StatusHeader.IsSuccess = true
    self.StatusHeader.Paint = function(s, w, h)
        local bg = s.IsSuccess and UI:GetColor("Overlay") or UI:GetColor("DangerBg")
        local border = s.IsSuccess and UI:GetColor("Border") or UI:GetColor("Danger")
        UI:DrawStudioBox(0, 0, w, h, bg, border, 4)

        local col = s.IsSuccess and UI:GetColor("Success") or UI:GetColor("Danger")
        draw.SimpleText(s.StatusText, "GDT:MonoBold", 10, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.TerminalText = self.TerminalPanel:Add("DTextEntry")
    self.TerminalText:Dock(FILL)
    self.TerminalText:DockMargin(6, 0, 6, 6)
    self.TerminalText:SetMultiline(true)
    self.TerminalText:SetEditable(false)
    self.TerminalText:SetFont("GDT:Mono")
    self.TerminalText:SetTextColor(UI:GetColor("Text"))
    self.TerminalText.Paint = function(s, w, h)
        UI:DrawStudioBox(0, 0, w, h, UI:GetColor("Overlay"), UI:GetColor("Border"), 4)
        s:DrawTextEntryText(s:GetTextColor(), UI:GetColor("Primary"), s:GetTextColor())
    end

    self.Splitter:SetTop(self.EditorPanel)
    self.Splitter:SetBottom(self.TerminalPanel)

    net.Receive("GDT:SendRunLuaResult", function()
        local data = UI:ReadCompressed()
        if not IsValid(self) then return end
        self:DisplayServerResult(data)
    end)
end

function PANEL:ExecuteCode()
    local code = string.Trim(self.CodeEditor:GetText())
    if code == "" then return end

    surface.PlaySound("buttons/button14.wav")

    if self.SelectedRealm == "client" then
        self:ExecuteClientCode(code)
    else
        self.StatusHeader.IsSuccess = true
        self.StatusHeader.StatusText = "Executing on server..."

        local codeLen = #code
        net.Start("GDT:RequestRunLua")
            net.WriteUInt(codeLen, 32)
            net.WriteData(code, codeLen)
        net.SendToServer()
    end
end

function PANEL:ExecuteClientCode(code)
    local fn = CompileString(code, "GDT_CLIENT_REPL", false)
    if type(fn) == "string" then
        self.StatusHeader.IsSuccess = false
        self.StatusHeader.StatusText = "✕ Client Syntax Error"
        self.TerminalText:SetText(fn)
        return
    end

    local captured = {}
    local origPrint = print
    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do table.insert(parts, tostring(select(i, ...))) end
        table.insert(captured, table.concat(parts, "\t"))
        origPrint(...)
    end

    local t0 = SysTime()
    local ok, r1, r2, r3 = pcall(fn)
    local dt = math.Round((SysTime() - t0) * 1000, 3)

    print = origPrint

    if not ok then
        self.StatusHeader.IsSuccess = false
        self.StatusHeader.StatusText = string.format("✕ Runtime Error (Client • %.2f ms)", dt)
        self.TerminalText:SetText(tostring(r1) .. "\n\nOutput:\n" .. table.concat(captured, "\n"))
    else
        self.StatusHeader.IsSuccess = true
        self.StatusHeader.StatusText = string.format("✓ Executed on Client (%.2f ms)", dt)
        local out = table.concat(captured, "\n")
        if r1 ~= nil then out = out .. "\n=> Return: " .. tostring(r1) end
        self.TerminalText:SetText(out)
    end
end

function PANEL:DisplayServerResult(data)
    if not data.success then
        self.StatusHeader.IsSuccess = false
        self.StatusHeader.StatusText = string.format("✕ Error (Server • %.2f ms)", data.elapsedMs or 0)
        self.TerminalText:SetText((data.error or "Unknown error") .. "\n\nOutput:\n" .. (data.output or ""))
    else
        self.StatusHeader.IsSuccess = true
        self.StatusHeader.StatusText = string.format("✓ Executed on Server (%.2f ms)", data.elapsedMs or 0)
        local out = data.output or ""
        if data.returnStr and data.returnStr ~= "" then
            out = out .. "\n=> Return: " .. data.returnStr
        end
        self.TerminalText:SetText(out)
    end
end

vgui.Register("GDT:TabREPL", PANEL, "EditablePanel")
