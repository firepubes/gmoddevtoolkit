-- ==========================================================
-- GDT STUDIO - DEVELOPER THEME, GRAPH RENDERER & UI CORE
-- Cyber Dev Dark Design System & High-Precision Primitives
-- ==========================================================

GDT = GDT or {}
GDT.UI = GDT.UI or {}

local UI = GDT.UI

-- ----------------------------------------------------------
-- 1. Responsive Scaling & Resolution Normalization
-- ----------------------------------------------------------
function UI:Scale(px)
    local baseH = 1080
    local curH = ScrH()
    local scaleFactor = math.Clamp(curH / baseH, 0.75, 1.35)
    return math.Round(px * scaleFactor)
end

function UI:GetColor(key)
    local theme = (GDT.Config and GDT.Config.Theme) or {}
    return theme[key] or Color(255, 255, 255)
end

-- ----------------------------------------------------------
-- 2. Font System Initialization
-- ----------------------------------------------------------
local function InitFonts()
    surface.CreateFont("GDT:Hero", {
        font = "Roboto",
        size = UI:Scale(22),
        weight = 900,
        antialias = true,
    })

    surface.CreateFont("GDT:Title", {
        font = "Roboto",
        size = UI:Scale(16),
        weight = 800,
        antialias = true,
    })

    surface.CreateFont("GDT:Subtitle", {
        font = "Roboto",
        size = UI:Scale(13),
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("GDT:Regular", {
        font = "Roboto",
        size = UI:Scale(12),
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("GDT:Mono", {
        font = "Consolas",
        size = UI:Scale(12),
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("GDT:MonoLarge", {
        font = "Consolas",
        size = UI:Scale(26),
        weight = 900,
        antialias = true,
    })

    surface.CreateFont("GDT:MonoBold", {
        font = "Consolas",
        size = UI:Scale(13),
        weight = 800,
        antialias = true,
    })

    surface.CreateFont("GDT:Badge", {
        font = "Roboto",
        size = UI:Scale(10),
        weight = 800,
        antialias = true,
    })
end

InitFonts()
hook.Add("OnScreenSizeChanged", "GDT:ReloadFonts", InitFonts)

-- ----------------------------------------------------------
-- 3. Visual Primitives & Scrollbars
-- ----------------------------------------------------------
function UI:DrawStudioBox(x, y, w, h, bgCol, borderCol, radius)
    radius = radius or 4
    draw.RoundedBox(radius, x, y, w, h, bgCol)

    if borderCol then
        surface.SetDrawColor(borderCol)
        surface.DrawOutlinedRect(x, y, w, h)
    end
end

function UI:DrawBadge(text, x, y, bgCol, textCol, font)
    surface.SetFont(font or "GDT:Badge")
    local tw, th = surface.GetTextSize(text)
    local padX, padY = UI:Scale(6), UI:Scale(2)
    local bw, bh = tw + padX * 2, th + padY * 2

    draw.RoundedBox(3, x, y, bw, bh, bgCol)
    draw.SimpleText(text, font or "GDT:Badge", x + padX, y + padY, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    return bw
end

function UI:ApplyScrollbar(scrollPanel)
    local sbar = scrollPanel:GetVBar()
    if not IsValid(sbar) then return end

    sbar:SetWide(UI:Scale(6))
    sbar.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, UI:GetColor("BackgroundNav"))
    end
    sbar.btnUp.Paint = nil
    sbar.btnDown.Paint = nil
    sbar.btnGrip.Paint = function(s, w, h)
        local col = s:IsHovered() and UI:GetColor("Primary") or UI:GetColor("Border")
        draw.RoundedBox(3, 1, 0, w - 2, h, col)
    end
end

-- ----------------------------------------------------------
-- 4. High-Performance Rolling Canvas Graph Plotter
-- ----------------------------------------------------------
function UI:DrawRollingGraph(x, y, w, h, points, minVal, maxVal, lineCol, bgCol, title, currentValStr)
    self:DrawStudioBox(x, y, w, h, UI:GetColor("Overlay"), UI:GetColor("Border"), 4)

    draw.SimpleText(title or "TELEMETRY", "GDT:Badge", x + 8, y + 6, UI:GetColor("TextDim"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    if currentValStr then
        draw.SimpleText(currentValStr, "GDT:MonoBold", x + w - 8, y + 6, lineCol or UI:GetColor("Primary"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    local graphY = y + UI:Scale(22)
    local graphH = h - UI:Scale(28)
    surface.SetDrawColor(Color(255, 255, 255, 12))
    surface.DrawLine(x, graphY + graphH * 0.5, x + w, graphY + graphH * 0.5)

    if not points or #points < 2 then return end

    local range = math.max(maxVal - minVal, 0.001)
    local stepX = w / (math.max(#points - 1, 1))

    for i = 1, #points - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]

        local normY1 = math.Clamp((p1 - minVal) / range, 0, 1)
        local normY2 = math.Clamp((p2 - minVal) / range, 0, 1)

        local px1 = x + (i - 1) * stepX
        local py1 = graphY + graphH * (1 - normY1)
        local px2 = x + i * stepX
        local py2 = graphY + graphH * (1 - normY2)

        if bgCol then
            surface.SetDrawColor(bgCol)
            surface.DrawRect(px1, math.min(py1, py2), stepX + 1, graphY + graphH - math.min(py1, py2))
        end

        surface.SetDrawColor(lineCol)
        surface.DrawLine(px1, py1, px2, py2)
    end
end

-- ----------------------------------------------------------
-- 5. Network Decompression Helper
-- ----------------------------------------------------------
function UI:ReadCompressed()
    local bytes = net.ReadUInt(32)
    local compressed = net.ReadData(bytes)
    local json = util.Decompress(compressed)
    return util.JSONToTable(json) or {}
end
