-- ==========================================================
-- GDT STUDIO - ADDON ARCHITECTURE & CONFLICT DETECTOR
-- Workshop Metadata, Local Folder Discovery & File Shadowing
-- ==========================================================

GDT = GDT or {}
GDT.AddonScanner = GDT.AddonScanner or {}

local Scanner = GDT.AddonScanner

function Scanner:GetReport()
    -- 1. Workshop Addons
    local workshop = engine.GetAddons() or {}
    local workshopList = {}
    for _, item in ipairs(workshop) do
        table.insert(workshopList, {
            title = item.title or "Untitled",
            wsid = tostring(item.wsid or "0"),
            mounted = item.mounted == true,
            downloaded = item.downloaded == true,
            size = item.size or 0,
        })
    end

    -- 2. Local Addons Discovery
    local _, localFolders = file.Find("addons/*", "GAME")
    local localAddons = {}
    for _, folder in ipairs(localFolders or {}) do
        table.insert(localAddons, {
            name = folder,
            path = "garrysmod/addons/" .. folder,
            hasLua = file.IsDir("addons/" .. folder .. "/lua", "GAME"),
        })
    end

    -- 3. File Shadowing & Collision Detector
    -- Check common autorun files across addons
    local fileMap = {}
    local collisions = {}

    for _, folder in ipairs(localFolders or {}) do
        local files, _ = file.Find("addons/" .. folder .. "/lua/autorun/*.lua", "GAME")
        for _, f in ipairs(files or {}) do
            local key = "lua/autorun/" .. string.lower(f)
            fileMap[key] = fileMap[key] or {}
            table.insert(fileMap[key], folder)
        end
    end

    for path, folders in pairs(fileMap) do
        if #folders > 1 then
            table.insert(collisions, {
                file = path,
                addons = table.concat(folders, ", "),
                count = #folders,
            })
        end
    end

    return {
        workshop = workshopList,
        localAddons = localAddons,
        collisions = collisions,
    }
end
