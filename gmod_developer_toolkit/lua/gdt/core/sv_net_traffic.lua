-- ==========================================================
-- GDT STUDIO - NETWORK TRAFFIC SNIFFER & TEST BENCH
-- Net String Registry, Inbound Byte Counting & Packet Dispatcher
-- ==========================================================

GDT = GDT or {}
GDT.NetTraffic = GDT.NetTraffic or {}

local Sniffer = GDT.NetTraffic

local messageStats = {}
local totalInboundBytes = 0
local totalInboundPackets = 0

-- Wrap registered net receivers to passively count metrics
local function InstrumentNetReceiver(name, origFunc)
    if not isfunction(origFunc) then return origFunc end
    local lower = string.lower(name)

    messageStats[lower] = messageStats[lower] or {
        name = name,
        packets = 0,
        bytes = 0,
        lastSender = "None",
        lastTime = 0,
    }

    local ref = messageStats[lower]

    return function(lenBits, client)
        local bytes = math.ceil((lenBits or 0) / 8) + 2
        ref.packets = ref.packets + 1
        ref.bytes = ref.bytes + bytes
        ref.lastSender = IsValid(client) and (client:Nick() .. " (" .. client:SteamID() .. ")") or "Server"
        ref.lastTime = os.time()

        totalInboundBytes = totalInboundBytes + bytes
        totalInboundPackets = totalInboundPackets + 1

        return origFunc(lenBits, client)
    end
end

for name, fn in pairs(net.Receivers or {}) do
    net.Receivers[name] = InstrumentNetReceiver(name, fn)
end

local origNetReceive = net.Receive
net.Receive = function(name, fn)
    local wrapped = InstrumentNetReceiver(name, fn)
    origNetReceive(name, wrapped)
end

function Sniffer:GetRegistry()
    local list = {}
    for lower, stat in pairs(messageStats) do
        table.insert(list, {
            name = stat.name,
            packets = stat.packets,
            bytes = stat.bytes,
            lastSender = stat.lastSender,
            lastTimeFormatted = stat.lastTime > 0 and os.date("%H:%M:%S", stat.lastTime) or "Never",
        })
    end

    table.sort(list, function(a, b) return a.bytes > b.bytes end)

    return {
        totalBytes = totalInboundBytes,
        totalPackets = totalInboundPackets,
        channels = list,
    }
end

function Sniffer:DispatchTestPacket(ply, messageName, stringPayload)
    if not IsValid(ply) or not ply:IsSuperAdmin() then
        return false, "SuperAdmin permission required."
    end

    if not util.NetworkStringToID(messageName) or util.NetworkStringToID(messageName) == 0 then
        return false, "Unpooled network string: " .. tostring(messageName)
    end

    net.Start(messageName)
        if stringPayload and stringPayload ~= "" then
            net.WriteString(stringPayload)
        end
    net.Send(ply)

    return true, "Dispatched test packet on channel: " .. messageName
end
