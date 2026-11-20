-- ==========================================================
-- GDT STUDIO - CAMI PRIVILEGES & PERMISSION DISPATCHER
-- ==========================================================

GDT = GDT or {}

if CAMI then
    CAMI.RegisterPrivilege({
        Name = (GDT.Config and GDT.Config.CAMIPrivilege) or "GDT:Access",
        MinAccess = "superadmin",
        Description = "Grants access to GDT Developer Studio & Runtime Inspector.",
    })
end

function GDT:CanAccess(ply)
    if not IsValid(ply) then return false end

    -- CAMI check
    if CAMI and CAMI.PlayerHasAccess then
        local allowed = CAMI.PlayerHasAccess(ply, (GDT.Config and GDT.Config.CAMIPrivilege) or "GDT:Access")
        if allowed then return true end
    end

    -- Usergroup fallback
    local minGroup = (GDT.Config and GDT.Config.MinUsergroup) or "superadmin"
    if minGroup == "admin" and (ply:IsAdmin() or ply:IsSuperAdmin()) then return true end
    if ply:IsSuperAdmin() then return true end

    local userGroup = ply:GetUserGroup()
    return userGroup == minGroup or userGroup == "owner" or userGroup == "developer" or userGroup == "superadmin"
end
