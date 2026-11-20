-- ==========================================================
-- GDT STUDIO - 3D WORLD HALO VISUALIZER
-- In-Game Spatial Outliner for Inspected Entities
-- ==========================================================

GDT = GDT or {}
GDT.Halo = GDT.Halo or {}

local Halo = GDT.Halo
Halo.TargetEntity = nil
Halo.Color = Color(0, 212, 255, 255)

function Halo:SetTarget(entIndex, col)
    if not entIndex or entIndex <= 0 then
        self.TargetEntity = nil
        return
    end
    self.TargetEntity = Entity(entIndex)
    if col then self.Color = col end
end

function Halo:Clear()
    self.TargetEntity = nil
end

hook.Add("PreDrawHalos", "GDT:DrawInspectedHalo", function()
    if IsValid(Halo.TargetEntity) then
        halo.Add({ Halo.TargetEntity }, Halo.Color, 3, 3, 2, true, true)
    end
end)
