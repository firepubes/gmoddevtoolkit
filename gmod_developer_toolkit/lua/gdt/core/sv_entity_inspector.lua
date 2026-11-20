-- ==========================================================
-- GDT STUDIO - DEEP 3D ENTITY INTROSPECTION & MANIPULATOR
-- Property Sheets, NetVars, Table Tree Dump & Physics Actions
-- ==========================================================

GDT = GDT or {}
GDT.EntityInspector = GDT.EntityInspector or {}

local Inspector = GDT.EntityInspector

local function GetOwnerDetails(ent)
    if not IsValid(ent) then return "World", "WORLD" end
    if ent.CPPIGetOwner then
        local o = ent:CPPIGetOwner()
        if IsValid(o) and o:IsPlayer() then return o:Nick(), o:SteamID() end
    end
    if ent.FPPOwner and IsValid(ent.FPPOwner) and ent.FPPOwner:IsPlayer() then
        return ent.FPPOwner:Nick(), ent.FPPOwner:SteamID()
    end
    if IsValid(ent.Owner) and ent.Owner:IsPlayer() then
        return ent.Owner:Nick(), ent.Owner:SteamID()
    end
    return "Server / Map", "WORLD"
end

local function SerializeEntityTable(ent)
    local raw = ent:GetTable() or {}
    local safe = {}
    for k, v in pairs(raw) do
        local keyStr = tostring(k)
        local t = type(v)
        if t == "string" or t == "number" or t == "boolean" then
            safe[keyStr] = tostring(v)
        elseif t == "Vector" then
            safe[keyStr] = string.format("Vector(%.1f, %.1f, %.1f)", v.x, v.y, v.z)
        elseif t == "Angle" then
            safe[keyStr] = string.format("Angle(%.1f, %.1f, %.1f)", v.p, v.y, v.r)
        elseif t == "table" then
            safe[keyStr] = "{ ... table [" .. table.Count(v) .. " items] }"
        else
            safe[keyStr] = "<" .. t .. ">"
        end
    end
    return safe
end

function Inspector:InspectEntity(entIndex)
    local ent = Entity(entIndex)
    if not IsValid(ent) then
        return { success = false, error = "Entity #" .. tostring(entIndex) .. " is no longer valid." }
    end

    local ownerNick, ownerSteamID = GetOwnerDetails(ent)
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local col = ent:GetColor()

    local phys = ent:GetPhysicsObject()
    local physData = nil
    if IsValid(phys) then
        physData = {
            mass = math.Round(phys:GetMass(), 1),
            velocity = math.Round(phys:GetVelocity():Length(), 1),
            angVelocity = math.Round(phys:GetAngleVelocity():Length(), 1),
            isMoveable = phys:IsMoveable(),
            isAsleep = phys:IsAsleep(),
            isGravityEnabled = phys:IsGravityEnabled(),
            material = phys:GetMaterial(),
        }
    end

    return {
        success = true,
        index = ent:EntIndex(),
        creationID = ent:GetCreationID(),
        class = ent:GetClass(),
        model = ent:GetModel() or "none",
        pos = string.format("Vector(%.1f, %.1f, %.1f)", pos.x, pos.y, pos.z),
        ang = string.format("Angle(%.1f, %.1f, %.1f)", ang.p, ang.y, ang.r),
        health = ent:Health(),
        maxHealth = ent:GetMaxHealth(),
        moveType = ent:GetMoveType(),
        collisionGroup = ent:GetCollisionGroup(),
        solid = ent:GetSolid(),
        material = ent:GetMaterial() ~= "" and ent:GetMaterial() or "Default",
        color = string.format("RGBA(%d, %d, %d, %d)", col.r, col.g, col.b, col.a),
        skin = ent:GetSkin(),
        owner = ownerNick .. " (" .. ownerSteamID .. ")",
        isPlayer = ent:IsPlayer(),
        isNPC = ent:IsNPC(),
        isWeapon = ent:IsWeapon(),
        physics = physData,
        tableData = SerializeEntityTable(ent),
    }
end

function Inspector:InspectRaytrace(ply)
    if not IsValid(ply) then return { success = false, error = "Invalid player." } end
    local tr = ply:GetEyeTrace()
    if not IsValid(tr.Entity) then
        return { success = false, error = "No entity found under your crosshair." }
    end
    return self:InspectEntity(tr.Entity:EntIndex())
end

function Inspector:PerformAction(ply, entIndex, action)
    if not IsValid(ply) or not ply:IsSuperAdmin() then
        return false, "SuperAdmin permission required."
    end

    local ent = Entity(entIndex)
    if not IsValid(ent) then return false, "Entity no longer valid." end

    if action == "freeze" then
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) return true, "Froze entity physics." end
        return false, "Entity has no physics object."
    elseif action == "unfreeze" then
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(true) phys:Wake() return true, "Unfroze entity physics." end
        return false, "Entity has no physics object."
    elseif action == "remove" then
        local cls = ent:GetClass()
        ent:Remove()
        return true, "Removed entity " .. cls .. " #" .. entIndex
    elseif action == "ignite" then
        ent:Ignite(15)
        return true, "Ignited entity for 15 seconds."
    elseif action == "extinguish" then
        ent:Extinguish()
        return true, "Extinguished entity."
    elseif action == "bring" then
        ent:SetPos(ply:GetPos() + ply:GetForward() * 75 + Vector(0, 0, 10))
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
        return true, "Brought entity in front of you."
    elseif action == "goto" then
        local pos = ent:GetPos() + Vector(0, 0, 40) - ply:GetForward() * 60
        ply:SetPos(pos)
        ply:SetEyeAngles((ent:GetPos() - pos):Angle())
        return true, "Teleported to entity #" .. entIndex
    end

    return false, "Unknown action."
end
