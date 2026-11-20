# GDT Studio - Advanced Garry's Mod Developer Toolkit & Runtime Inspector v3.0.0

A standalone, gamemode-independent **Garry's Mod Developer Studio & Runtime Diagnostics Cockpit**. Built for server owners, developers, scripters, and administrators running Sandbox, DarkRP, TTT, Helix, NutScript, or custom gamemodes.

---

## Features Overview

### 1. **Interactive Lua REPL & Code Sandbox**
* **Server & Client Execution**: Run arbitrary Lua code directly in-game on the Server (SuperAdmin) or Client realm.
* **Stdout Capture & Return Inspector**: Real-time stdout capture (`print`, `MsgN`) and return value serialization with execution timing.
* **Snippet Library**: Pre-built diagnostic scripts for player roster audits, decal/ragdoll wipes, memory benchmarks, and entity class census.

### 2. **3D Entity Inspector & Raytracer**
* **Crosshair Target Picker**: One-click `INSPECT UNDER CROSSHAIR` uses player raytracing to instantly inspect whatever you're looking at.
* **Deep Introspection**: Inspects Model, Position, Angle, Health, Material, Color, MoveType, CollisionGroup, Solid, and Owner (via CPPI, FPP, or Owner).
* **Physics Object Metrics**: Mass, Linear Velocity, Angular Velocity, Moveable/Frozen status, and Asleep state.
* **Variable Table Dump**: Inspects `ent:GetTable()` variables and keys in real-time.
* **3D World Halo Visualizer**: Outlines the selected entity with a glowing spatial halo in the 3D world.
* **Action Controls**: Freeze, Unfreeze, Ignite, Extinguish, Bring to Player, Teleport to Entity, and Remove.

### 3. **Hook Matrix & Exact Source Resolver**
* **File & Line Resolution**: Resolves the exact file path and line number where every hook was defined using `debug.getinfo` (e.g. `addons/my_addon/lua/autorun/server/init.lua:42`).
* **Search Filter**: Filter hooks by Event name, Identifier, or Source file path.
* **Opt-in Profiler**: Measures hook call counts, total execution time (ms), average time (ms), and peak spikes (>10ms).
* **Live Hook Suppression**: Temporarily mute a problematic hook without restarting the server or altering files on disk.

### 4. **Network Traffic Sniffer & RPC Test Bench**
* **Inbound Byte & Packet Throughput**: Passively tracks inbound data rates (KB) and packet frequencies across every registered `net.Receive` channel.
* **Net Packet Dispatcher**: Dispatch custom test packets with string payloads directly from the UI to test server-side receivers.

### 5. **Forensic Lua Error Monitor**
* **Automatic Error Deduplication**: Deduplicates server and client Lua errors with frequency counters (`x15`).
* **Interactive Stack Inspection**: Click any error card to view formatted stack traces.
* **Export & Discord Reports**: One-click `COPY DISCORD REPORT` generates ready-to-paste markdown reports, or export JSON snapshots directly to `garrysmod/data/gdt/exports/`.

### 6. **Addon Architecture & Conflict Scanner**
* **Local Addon Discovery**: Scans local `garrysmod/addons/` folders and verifies Lua scripts.
* **File Shadowing & Collision Detector**: Pinpoints duplicate file paths across multiple addons (e.g. when multiple addons attempt to provide the same autorun file).
* **Mounted Workshop Items**: Inspects engine-reported Workshop IDs and mount states.

### 7. **System Diagnostics & Telemetry Dashboard**
* **Rolling Area Charts**: Real-time canvas graphs displaying tickrate (TPS) and frame times.
* **Engine Environment Metadata**: Server hostname, active map, running gamemode, operating system, and uptime.
* **Garbage Collection Benchmark**: Force server-side GC and inspect reclaimed memory.

---

## How to Open In-Game

* **Chat Commands**: `!gdt`, `/gdt`, `!dev`, `/dev`, `!toolkit`, `/toolkit`
* **Console Commands**: `gdt_menu`, `gdt`, or `gdt_studio`
* **Hot Reload**: `gdt_reload` in server or client console
