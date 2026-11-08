--[[
============================================================
   ____ ___  ____  _  _______   _____ __  ______  ____  ______
  / __// _ \/ _  \| |/ /_  __/  /  _/  |/  / _ \/ __ \/ __/  _/
 / _/ / // / , _/| ' /  / /    _/ // /|_/ / ___/ /_/ / _/ _/ /  
/_/   \___/_/|_|/_/|_| /_/    /___/_/  /_/_/   \____/_/  /___/   
                                                                  
   [*] Target      : Roblox Studio Lite (ScottSpiritWalker)
   [*] Executor    : Delta (Android / PC)
   [*] Insert Core : FORKT Engine v3.8 PRO (Native 1:1 Port)
   [*] Scan Core   : MCHLERN Responsive File Scanner
   [*] UI & Toggle : FORKT Theme + Fixed Non-Draggable Left Toggle
============================================================
]]--

-- 1. SERVICES & BASIC SETUP
local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local CoreGui            = game:GetService("CoreGui")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local LP = Players.LocalPlayer
if not LP then
    pcall(function() LP = Players.PlayerAdded:Wait() end)
    LP = LP or Players.LocalPlayer
end

-- Resolve Safe CoreGui Container
local function getSafeGui()
    if gethui then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    local okCore = pcall(function() return CoreGui.Name end)
    if okCore then return CoreGui end
    return LP and (LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 5))
end

local GuiParent = getSafeGui()

-- Executor Functions
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local clipFn      = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local customAsset = getcustomasset or getsynasset or nil
local listfilesFn = listfiles or nil

-- Memory Source Code Registry (FORKT & MCHLERN)
_G.FORKT_RAW_SOURCES = _G.FORKT_RAW_SOURCES or {}

-- Studio Lite Remote & Folder Hooks
local slFolder    = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local serverFuncs = slFolder and slFolder:FindFirstChild("ServerFunctions")

-- Theme Color Palette (FORKT Violet-Dark Aesthetic)
local Colors = {
    Background    = Color3.fromRGB(15, 12, 20),
    Sidebar       = Color3.fromRGB(20, 15, 28),
    Surface       = Color3.fromRGB(24, 18, 34),
    SurfaceHover  = Color3.fromRGB(34, 25, 48),
    Border        = Color3.fromRGB(56, 42, 78),
    Primary       = Color3.fromRGB(157, 78, 221),
    PrimaryLight  = Color3.fromRGB(199, 125, 255),
    PrimaryDark   = Color3.fromRGB(104, 57, 158),
    Text          = Color3.fromRGB(245, 240, 255),
    TextMuted     = Color3.fromRGB(155, 145, 175),
    Success       = Color3.fromRGB(65, 205, 125),
    Error         = Color3.fromRGB(235, 75, 95),
    ModelTag      = Color3.fromRGB(80, 200, 120),
    PlaceTag      = Color3.fromRGB(199, 125, 255)
}

local Icons = {
    ToggleIcon = "rbxassetid://137790966470480", -- Toggle icon user
    Package    = "rbxassetid://128864012857079",
    Folder     = "rbxassetid://88761476236687",
    Dashboard  = "rbxassetid://90838150633173",
    Settings   = "rbxassetid://11956055886",
    Refresh    = "rbxassetid://13492317101",
    File       = "rbxassetid://17109896197",
    Gamepad    = "rbxassetid://115836418226834",
    Check      = "rbxassetid://18349889388",
    Alert      = "rbxassetid://7634887649"
}

-- Clean Existing UI if Already Running
local existingGui = GuiParent:FindFirstChild("ForktImporter_CleanUI")
if existingGui then
    existingGui:Destroy()
end

-- =====================================================
-- 2. MCHLERN RESPONSIVE FILE SCANNER (MENEMUKAN ASET DI DELTA)
-- =====================================================
local SCAN_PATHS = {
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "/sdcard/Delta/workspace",
    "/sdcard/Android/Delta/workspace",
    "Download",
    "Downloads",
    "/sdcard/Download",
    "/sdcard/Downloads",
    "/storage/emulated/0/Download",
    "/storage/emulated/0/Downloads",
    "../workspace",
    "."
}

local function safeReadFile(p)
    if not readfile then return nil end
    local ok, d = pcall(readfile, p)
    return ok and d or nil
end

local function safeListFiles(p)
    if not listfilesFn then return nil end
    local ok, f = pcall(listfilesFn, p)
    return ok and f or nil
end

local function getFileName(p)
    return p:match("([^/\\]+)$") or p
end

local function getAllAssetFiles()
    local result = {}
    local seen = {}
    if not listfilesFn then return result end
    local lastYield = os.clock()

    local function scanDeep(folder, depth)
        if depth > 4 or seen[folder] then return end
        seen[folder] = true
        local files = safeListFiles(folder)
        if not files then return end

        for _, path in ipairs(files) do
            if os.clock() - lastYield > 0.015 then
                task.wait()
                lastYield = os.clock()
            end
            local lp = path:lower()
            local isModel = (lp:sub(-5) == ".rbxm" or lp:sub(-6) == ".rbxmx")
            local isPlace = (lp:sub(-5) == ".rbxl" or lp:sub(-6) == ".rbxlx")

            if (isModel or isPlace) and not seen[path] then
                seen[path] = true
                table.insert(result, {
                    name     = getFileName(path),
                    path     = path,
                    fileType = isModel and "MODEL" or "PLACE"
                })
            elseif not lp:match("%.[%a%d]+$") then
                scanDeep(path, depth + 1)
            end
        end
    end

    for _, p in ipairs(SCAN_PATHS) do
        if safeListFiles(p) then
            scanDeep(p, 0)
        end
    end

    return result
end

-- =====================================================
-- 2.5 DUAL DECOMPRESSION ENGINE (LZ4 + ZSTD PRO)
-- =====================================================

local bit32 = bit32 or {
    band   = function(a, b) return a & b end,
    rshift = function(a, n) return a >> n end,
    lshift = function(a, n) return a << n end,
    bor    = function(a, b) return a | b end,
}
local band, rshift, lshift, bor = bit32.band, bit32.rshift, bit32.lshift, bit32.bor
local string_byte = string.byte
local string_char = string.char
local table_concat = table.concat

local CHAR_MAP = table.create and table.create(256) or {}
for i = 0, 255 do
    CHAR_MAP[i] = string_char(i)
end

-- Little Endian Uint32 Reader (100% Portable)
local function readU32LE(str, idx)
    local b1, b2, b3, b4 = string_byte(str, idx, idx + 3)
    if not b4 then return 0 end
    return b1 + lshift(b2, 8) + lshift(b3, 16) + lshift(b4, 24)
end

-- [ENGINE 1: LZ4 BLOCK DECOMPRESSOR] (Pure Luau high performance)
local function decompressLZ4(data)
    if not data or #data == 0 then return "" end
    local out = {}
    local outNext = 1
    local dataLen = #data
    local pos = 1

    while pos <= dataLen do
        local token = string_byte(data, pos)
        pos = pos + 1

        -- Literals
        local literalCount = rshift(token, 4)
        if literalCount == 15 then
            repeat
                local lenPart = string_byte(data, pos)
                pos = pos + 1
                literalCount = literalCount + lenPart
            until lenPart < 255
        end

        for i = 0, literalCount - 1 do
            out[outNext + i] = CHAR_MAP[string_byte(data, pos + i)]
        end
        outNext = outNext + literalCount
        pos = pos + literalCount

        if pos > dataLen then break end

        -- Match
        local matchLength = band(token, 15)
        local offsetA, offsetB = string_byte(data, pos, pos + 1)
        local matchOffset = offsetA + lshift(offsetB, 8)
        pos = pos + 2

        if matchLength == 15 then
            repeat
                local lenPart = string_byte(data, pos)
                pos = pos + 1
                matchLength = matchLength + lenPart
            until lenPart < 255
        end
        matchLength = matchLength + 4

        for i = 0, matchLength - 1 do
            out[outNext + i] = out[outNext - matchOffset + i]
        end
        outNext = outNext + matchLength
    end

    return table_concat(out)
end

-- Base64 Encoder for ZSTD Native Bridge
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function toBase64(data)
    local out = {}
    local len = #data
    for i = 1, len, 3 do
        local a = string_byte(data, i)
        local b = (i + 1 <= len) and string_byte(data, i + 1) or 0
        local c = (i + 2 <= len) and string_byte(data, i + 2) or 0
        local n = bor(lshift(a, 16), lshift(b, 8), c)

        local c1 = band(rshift(n, 18), 63)
        local c2 = band(rshift(n, 12), 63)
        local c3 = band(rshift(n, 6), 63)
        local c4 = band(n, 63)

        table.insert(out, B64_CHARS:sub(c1 + 1, c1 + 1))
        table.insert(out, B64_CHARS:sub(c2 + 1, c2 + 1))
        table.insert(out, (i + 1 <= len) and B64_CHARS:sub(c3 + 1, c3 + 1) or "=")
        table.insert(out, (i + 2 <= len) and B64_CHARS:sub(c4 + 1, c4 + 1) or "=")
    end
    return table_concat(out)
end

-- [ENGINE 2: ZSTD DECOMPRESSOR] (Roblox Native C++ Bridge via HttpService JSON buffer)
local function decompressZSTD(payload)
    if not payload or #payload == 0 then return "" end
    local ok, res = pcall(function()
        local b64 = toBase64(payload)
        local json = '{"m": null, "t": "buffer", "zbase64": "' .. b64 .. '"}'
        local decoded = HttpService:JSONDecode(json)
        if typeof(decoded) == "buffer" and buffer and buffer.tostring then
            return buffer.tostring(decoded)
        end
        return tostring(decoded)
    end)
    if ok and res and #res > 0 then
        return res
    end
    return payload
end

-- [DUAL CHUNK DECOMPRESSOR] Auto-detects ZSTD (0xFD2FB528) vs LZ4
local function decompressChunk(payload, uncompLen)
    if not payload or #payload == 0 then return "" end
    -- Zstandard Magic Number: 0xFD2FB528 (\x28\xb5\x2f\xfd)
    if #payload >= 4 and payload:sub(1, 4) == "\x28\xb5\x2f\xfd" then
        local okZ, resZ = pcall(decompressZSTD, payload)
        if okZ and resZ and #resZ > 0 then
            return resZ
        end
    end

    -- Default: LZ4 Block Decompressor
    local okL, resL = pcall(decompressLZ4, payload)
    if okL and resL and #resL > 0 then
        return resL
    end
    return payload
end

-- [BINARY CHUNK SCRIPT RECOVERY] Unpacks raw <roblox! binary file PROP chunks
local function parseBinarySources(raw)
    local sources = {}
    local classNames = {} -- class_id -> list of instance names

    if not raw or #raw < 32 or raw:sub(1, 8) ~= "<roblox!" then
        return sources
    end

    local pos = 33 -- Skip header (16) + class/instance counts (8) + reserved (8)
    local rawLen = #raw

    while pos + 16 <= rawLen do
        local cname = raw:sub(pos, pos + 3)
        local c_len = readU32LE(raw, pos + 4)
        local u_len = readU32LE(raw, pos + 8)
        pos = pos + 16

        if pos + c_len - 1 > rawLen then break end
        local payload = raw:sub(pos, pos + c_len - 1)
        pos = pos + c_len

        if cname == "PROP" then
            local decomp = (c_len > 0) and decompressChunk(payload, u_len) or payload
            if #decomp >= 8 then
                local class_id = readU32LE(decomp, 1)
                local p_len = readU32LE(decomp, 5)
                local p_name = decomp:sub(9, 9 + p_len - 1)

                if p_name == "Name" then
                    classNames[class_id] = classNames[class_id] or {}
                    local offset = 9 + p_len + 1 -- skip p_type byte
                    while offset + 4 <= #decomp do
                        local s_len = readU32LE(decomp, offset)
                        offset = offset + 4
                        if offset + s_len - 1 <= #decomp and s_len > 0 then
                            local str = decomp:sub(offset, offset + s_len - 1)
                            table.insert(classNames[class_id], str)
                            offset = offset + s_len
                        else
                            break
                        end
                    end
                elseif p_name == "Source" then
                    local offset = 9 + p_len + 1 -- skip p_type byte
                    local idx = 1
                    local namesForClass = classNames[class_id] or {}
                    while offset + 4 <= #decomp do
                        local s_len = readU32LE(decomp, offset)
                        offset = offset + 4
                        if offset + s_len - 1 <= #decomp and s_len > 0 then
                            local str = decomp:sub(offset, offset + s_len - 1)
                            offset = offset + s_len

                            local instName = namesForClass[idx]
                            if instName then
                                sources[instName] = str
                                sources["Script:" .. instName] = str
                                sources["LocalScript:" .. instName] = str
                                sources["ModuleScript:" .. instName] = str
                            end
                            sources["SRC_INDEX_" .. idx] = str
                            idx = idx + 1
                        else
                            break
                        end
                    end
                end
            end
        elseif cname == "END\0" then
            break
        end
    end

    return sources
end

-- =====================================================
-- 3. FORKT ENGINE INSERTION CORE (PORTED 1:1 DARI FORKT v3.8)
-- =====================================================

-- [A] Helper sanitize file name (transformValue7 FORKT)
local function sanitizeName(raw)
    raw = tostring(raw or "Imported")
    raw = raw:gsub('[\\/:*?"<>|]', "_")
    raw = raw:gsub("^%s+", ""):gsub("%s+$", "")
    return #raw > 0 and raw or "Imported"
end

-- [B] Folder Creator with FORKT_RBXL_IMPORT attribute (createFolder FORKT)
local function createForktFolder(fileData)
    local base = sanitizeName(getFileName(fileData.path):gsub("%.[^%.]+$", ""))
    local current = base
    local dup = 1
    while Workspace:FindFirstChild(current) do
        dup = dup + 1
        current = base .. "_" .. tostring(dup)
    end

    local folder = Instance.new("Folder")
    folder.Name = current
    folder.Parent = Workspace
    folder:SetAttribute("FORKT_RBXL_IMPORT", true)
    folder:SetAttribute("SourceFile", tostring(fileData.path))
    return folder
end

-- [C] Safe Parenting (runProtected12 FORKT)
local function runProtected12(inst, target)
    local function tryOp()
        inst.Parent = target
    end
    if typeof(inst) ~= "Instance" or typeof(target) ~= "Instance" then
        return false
    else
        return pcall(tryOp) and inst.Parent == target
    end
end

-- [D] Mesh ID Runtime Extractor & Loader (extractDigits FORKT)
local function extractDigitsAndLoad(idValue)
    if not serverFuncs or not idValue or idValue == "" then return end
    local strId = tostring(idValue):match("%d+")
    if strId and tonumber(strId) then
        pcall(function()
            serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(strId))
        end)
    end
end

-- [E] Item Setup: SL_Anchored, MeshPart & SL_CodeTextBox (runProtected11 FORKT)
local function runProtected11(rootInst, rawSources)
    if typeof(rootInst) ~= "Instance" then return end

    local descs = {}
    local ok, res = pcall(function() return rootInst:GetDescendants() end)
    if ok and res then
        descs = res
    end
    table.insert(descs, 1, rootInst)

    for j, c in ipairs(descs) do
        if typeof(c) == "Instance" then
            -- 1. BasePart Anchoring & Attributes (FORKT Style)
            if c:IsA("BasePart") then
                local origAnchor = c.Anchored
                local origCollide = c.CanCollide
                c.Anchored = true
                if c:GetAttribute("SL_Anchored") == nil then
                    c:SetAttribute("SL_Anchored", origAnchor)
                    c:SetAttribute("SL_CanCollide", origCollide)
                end
                if c:IsA("MeshPart") then
                    extractDigitsAndLoad(c.MeshId)
                    extractDigitsAndLoad(c.TextureID)
                end
            end

            -- 2. Script Code Injection to Studio Lite Editor (FORKT runProtected10)
            if c:IsA("LuaSourceContainer") then
                local key = c.ClassName .. ":" .. c.Name
                local src = rawSources and (rawSources[key] or rawSources[c.Name])
                if not src and rawSources then
                    for k, v in pairs(rawSources) do
                        if k:find(c.Name, 1, true) then src = v; break end
                    end
                end
                if not src then
                    pcall(function() src = c.Source end)
                end

                if src and #src > 0 then
                    _G.FORKT_RAW_SOURCES[c.ClassName .. c.Name] = src
                    local tb = c:FindFirstChild("SL_CodeTextBox")
                    if tb then
                        tb.Text = src
                    end
                    if c.ClassName == "ModuleScript" then
                        local ro = c:FindFirstChild("SL_1ReadOnly")
                        if ro then
                            pcall(function() ro.Text = src; ro.ContentText = src end)
                        end
                    end
                end
            end

            -- Throttling Heartbeat tiap 100 objek persis FORKT
            if j % 100 == 0 then
                RunService.Heartbeat:Wait()
            end
        end
    end
end

-- [F] Service Children Distributor (runProtected13 FORKT)
local function runProtected13(sourceService, targetService, rawSources)
    if typeof(sourceService) ~= "Instance" or typeof(targetService) ~= "Instance" then
        return 0
    end
    local ok, children = pcall(function() return sourceService:GetChildren() end)
    if not ok or type(children) ~= "table" then return 0 end

    local count = 0
    for i, child in ipairs(children) do
        if typeof(child) == "Instance" then
            runProtected12(child, targetService)
            runProtected11(child, rawSources)
            count = count + 1
        end
        if i % 100 == 0 then
            RunService.Heartbeat:Wait()
        end
    end
    return count
end

-- [G] FORKT Service Mapping Table (ba table dari FORKT)
local ForktServiceMap = {
    Workspace           = Workspace,
    workspace           = Workspace,
    ReplicatedStorage   = ReplicatedStorage,
    ReplicatedFirst     = game:GetService("ReplicatedFirst"),
    StarterGui          = game:GetService("StarterGui"),
    StarterPack         = game:GetService("StarterPack"),
    StarterPlayer       = game:GetService("StarterPlayer"),
    Lighting            = game:GetService("Lighting"),
    SoundService        = game:GetService("SoundService"),
    ServerScriptService = _G.sss or ReplicatedStorage,
    ServerStorage       = _G.ss or ReplicatedStorage,
    Teams               = game:GetService("Teams"),
    Chat                = game:GetService("Chat")
}

-- [H] DataModel & Objects Unpacker (runProtected14 FORKT)
local function runProtected14(objects, placeFolder, rawSources)
    local totalLoaded = 0
    for _, d in ipairs(objects) do
        if typeof(d) == "Instance" then
            if d:IsA("DataModel") then
                -- RBXL Mode: Unpack DataModel per service
                for _, service in ipairs(d:GetChildren()) do
                    local isWs = (service.Name == "Workspace" or service.Name == "workspace")
                    local target = isWs and placeFolder or ForktServiceMap[service.Name]
                    if target then
                        totalLoaded = totalLoaded + runProtected13(service, target, rawSources)
                    else
                        runProtected12(service, placeFolder)
                        runProtected11(service, rawSources)
                        totalLoaded = totalLoaded + 1
                    end
                    task.wait()
                end
            else
                -- Model / Part Mode
                runProtected12(d, placeFolder)
                runProtected11(d, rawSources)
                totalLoaded = totalLoaded + 1
                task.wait(0)
            end
        end
    end
    return totalLoaded
end

-- [I] Core FORKT Import Function (runProtected16 FORKT)
local function runForktImport(fileData)
    local raw = safeReadFile(fileData.path)
    if not raw or #raw == 0 then
        return false, "readfile gagal"
    end

    local isPlace = fileData.fileType == "PLACE"
    local formatType = (fileData.path:lower():match("%.rbxlx?$") and "XML") or "BINARY"

    -- Dual Engine Source Extraction (XML + Binary LZ4/ZSTD Chunk Decompression)
    local rawSources = {}
    local detectedEngine = "XML"

    -- 1. XML Source extraction (untuk format XML .rbxmx / .rbxlx)
    for name, code in raw:gmatch('<string name="Name">([^<]+)</string>.-<ProtectedString name="Source"><%!%[CDATA%[(.-)%]%]></ProtectedString>') do
        rawSources[name] = code
    end

    -- 2. Dual Engine Binary Chunk Decompressor (LZ4 + ZSTD untuk format Binary <roblox!)
    if raw:sub(1, 8) == "<roblox!" then
        detectedEngine = "BINARY (LZ4/ZSTD)"
        local binSources = parseBinarySources(raw)
        for k, v in pairs(binSources) do
            if not rawSources[k] then
                rawSources[k] = v
            end
        end
    end

    -- URL Candidate array (getcustomasset + rbxasset)
    local candidateURLs = {}
    if customAsset then
        local okAsset, ca = pcall(customAsset, fileData.path)
        if okAsset and ca then
            table.insert(candidateURLs, ca)
        end
    end
    table.insert(candidateURLs, "rbxasset://" .. tostring(fileData.path):gsub("\\", "/"))

    local loadedObjs = nil
    -- 2 attempts dengan jeda 0.25s persis logic FORKT (while h <= 2 do)
    for attempt = 1, 2 do
        for _, url in ipairs(candidateURLs) do
            local ok, res = pcall(function() return game:GetObjects(url) end)
            if ok and res and #res > 0 then
                loadedObjs = res
                break
            end
        end
        if loadedObjs then break end
        task.wait(0.25)
    end

    -- Fallback writefile temporary jika executor butuh path lokal
    if not loadedObjs and raw and writefile and customAsset then
        pcall(function()
            local tmpName = "forkt_tmp_" .. fileData.name
            writefile(tmpName, raw)
            local tmpUrl = customAsset(tmpName)
            if tmpUrl then
                local ok2, res2 = pcall(function() return game:GetObjects(tmpUrl) end)
                if ok2 and res2 and #res2 > 0 then loadedObjs = res2 end
            end
            pcall(function() if delfile then delfile(tmpName) end end)
        end)
    end

    if not loadedObjs or #loadedObjs == 0 then
        if isPlace then
            return false, "RBXL terdeteksi tetapi executor tidak mengembalikan Instance dari game:GetObjects(). Pastikan Delta mendukung getcustomasset untuk file .rbxl."
        else
            return false, "Delta gagal membuat Instance dari file ini. Coba pastikan file valid dan getcustomasset/game:GetObjects mendukung format tersebut."
        end
    end

    -- Buat folder pembungkus & distribusikan (createFolder + runProtected14)
    local placeFolder = createForktFolder(fileData)
    local totalLoaded = runProtected14(loadedObjs, placeFolder, rawSources)

    if totalLoaded <= 0 then
        return false, "0 objects loaded"
    end

    return true, string.format("%d object(s) loaded [%s | %s]", totalLoaded, formatType, detectedEngine)
end

-- =====================================================
-- 4. GUI CREATION (FORKT AESTHETIC & NON-DRAGGABLE LEFT TOGGLE)
-- =====================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ForktImporter_CleanUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

-- Toast Notification Helper
local function showToast(title, desc, isErr)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.fromOffset(260, 56)
    toast.AnchorPoint = Vector2.new(1, 1)
    toast.Position = UDim2.new(1, 280, 1, -20)
    toast.BackgroundColor3 = Color3.fromRGB(18, 14, 26)
    toast.BorderSizePixel = 0
    toast.ZIndex = 100
    toast.Parent = ScreenGui

    local stroke = Instance.new("UIStroke", toast)
    stroke.Color = isErr and Colors.Error or Colors.Primary
    stroke.Thickness = 1.2
    stroke.Transparency = 0.3
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)

    local iconBg = Instance.new("Frame", toast)
    iconBg.Size = UDim2.fromOffset(34, 34)
    iconBg.Position = UDim2.fromOffset(12, 11)
    iconBg.BackgroundColor3 = isErr and Colors.Error or Colors.Primary
    iconBg.BackgroundTransparency = 0.8
    iconBg.BorderSizePixel = 0
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)

    local icon = Instance.new("ImageLabel", iconBg)
    icon.Size = UDim2.fromOffset(18, 18)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = isErr and Icons.Alert or Icons.Check
    icon.ImageColor3 = isErr and Colors.Error or Colors.PrimaryLight

    local lblTitle = Instance.new("TextLabel", toast)
    lblTitle.Size = UDim2.new(1, -60, 0, 18)
    lblTitle.Position = UDim2.fromOffset(54, 10)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = title
    lblTitle.Font = Enum.Font.GothamBold
    lblTitle.TextSize = 12
    lblTitle.TextColor3 = Colors.Text
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left

    local lblDesc = Instance.new("TextLabel", toast)
    lblDesc.Size = UDim2.new(1, -60, 0, 20)
    lblDesc.Position = UDim2.fromOffset(54, 28)
    lblDesc.BackgroundTransparency = 1
    lblDesc.Text = desc
    lblDesc.Font = Enum.Font.Gotham
    lblDesc.TextSize = 10
    lblDesc.TextColor3 = Colors.TextMuted
    lblDesc.TextXAlignment = Enum.TextXAlignment.Left

    TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -20, 1, -20)
    }):Play()

    task.delay(3, function()
        if toast and toast.Parent then
            local tw = TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 280, 1, -20)
            })
            tw:Play()
            tw.Completed:Connect(function() toast:Destroy() end)
        end
    end)
end

-- =====================================================
-- TOGGLE BUTTON (DI KIRI LAYAR, KUNCI PERMANEN - GAK BISA DIDRAG)
-- =====================================================
local ToggleButton = Instance.new("ImageButton", ScreenGui)
ToggleButton.Name = "FixedLeftToggle"
ToggleButton.Size = UDim2.fromOffset(46, 46)
ToggleButton.Position = UDim2.new(0, 14, 0.5, -23) -- Posisi paten di sisi kiri
ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
ToggleButton.BackgroundColor3 = Colors.Surface
ToggleButton.BorderSizePixel = 0
ToggleButton.ZIndex = 50
ToggleButton.Active = true
ToggleButton.AutoButtonColor = false

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)

local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = Colors.Primary
ToggleStroke.Thickness = 1.4
ToggleStroke.Transparency = 0.3

local ToggleIcon = Instance.new("ImageLabel", ToggleButton)
ToggleIcon.Size = UDim2.fromOffset(28, 28)
ToggleIcon.Position = UDim2.fromScale(0.5, 0.5)
ToggleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.Image = Icons.ToggleIcon -- Asset 137790966470480
ToggleIcon.ZIndex = 51

-- =====================================================
-- MAIN WINDOW FRAME & RESPONSIVE SCALING
-- =====================================================
local MainWindow = Instance.new("Frame", ScreenGui)
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.fromOffset(560, 380)
MainWindow.Position = UDim2.fromScale(0.5, 0.5)
MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
MainWindow.BackgroundColor3 = Colors.Background
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Visible = true

Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainWindow)
MainStroke.Color = Colors.Primary
MainStroke.Thickness = 1.4
MainStroke.Transparency = 0.4

-- Responsive Scale
local MainScale = Instance.new("UIScale", MainWindow)
local function updateUiScale()
    local cam = Workspace.CurrentCamera
    if cam and cam.ViewportSize.X > 0 then
        local sf = math.min(cam.ViewportSize.X / 600, cam.ViewportSize.Y / 420, 1)
        MainScale.Scale = math.clamp(sf, 0.55, 1)
    end
end
updateUiScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUiScale)
end

ToggleButton.MouseButton1Click:Connect(function()
    MainWindow.Visible = not MainWindow.Visible
    TweenService:Create(ToggleIcon, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Rotation = MainWindow.Visible and 0 or 360
    }):Play()
end)

local CloseBtn = Instance.new("TextButton", MainWindow)
CloseBtn.Size = UDim2.fromOffset(26, 26)
CloseBtn.Position = UDim2.new(1, -36, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(32, 24, 46)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = Colors.TextMuted
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = false
end)

-- =====================================================
-- SIDEBAR
-- =====================================================
local Sidebar = Instance.new("Frame", MainWindow)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local SidebarStroke = Instance.new("UIStroke", Sidebar)
SidebarStroke.Color = Colors.Primary
SidebarStroke.Transparency = 0.7
SidebarStroke.Thickness = 1

local BrandIcon = Instance.new("ImageLabel", Sidebar)
BrandIcon.Size = UDim2.fromOffset(28, 28)
BrandIcon.Position = UDim2.fromOffset(16, 16)
BrandIcon.BackgroundTransparency = 1
BrandIcon.Image = Icons.Package
BrandIcon.ImageColor3 = Colors.PrimaryLight

local BrandTitle = Instance.new("TextLabel", Sidebar)
BrandTitle.Size = UDim2.new(1, -55, 0, 16)
BrandTitle.Position = UDim2.fromOffset(50, 15)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Text = "FORKT ENGINE"
BrandTitle.Font = Enum.Font.GothamBold
BrandTitle.TextSize = 13
BrandTitle.TextColor3 = Colors.Text
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left

local BrandSub = Instance.new("TextLabel", Sidebar)
BrandSub.Size = UDim2.new(1, -55, 0, 14)
BrandSub.Position = UDim2.fromOffset(50, 31)
BrandSub.BackgroundTransparency = 1
BrandSub.Text = "Studio Lite v3.8 PRO"
BrandSub.Font = Enum.Font.GothamMedium
BrandSub.TextSize = 9
BrandSub.TextColor3 = Colors.TextMuted
BrandSub.TextXAlignment = Enum.TextXAlignment.Left

local Divider = Instance.new("Frame", Sidebar)
Divider.Size = UDim2.new(1, -28, 0, 1)
Divider.Position = UDim2.fromOffset(14, 56)
Divider.BackgroundColor3 = Colors.Border
Divider.BorderSizePixel = 0

local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.Size = UDim2.new(1, 0, 0, 150)
TabContainer.Position = UDim2.fromOffset(0, 68)
TabContainer.BackgroundTransparency = 1

local TabListLayout = Instance.new("UIListLayout", TabContainer)
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local RescanBtn = Instance.new("TextButton", Sidebar)
RescanBtn.Size = UDim2.new(1, -28, 0, 36)
RescanBtn.Position = UDim2.new(0, 14, 1, -48)
RescanBtn.BackgroundColor3 = Color3.fromRGB(26, 18, 38)
RescanBtn.Text = ""
Instance.new("UICorner", RescanBtn).CornerRadius = UDim.new(0, 8)

local RescanStroke = Instance.new("UIStroke", RescanBtn)
RescanStroke.Color = Colors.Primary
RescanStroke.Transparency = 0.5

local RescanIcon = Instance.new("ImageLabel", RescanBtn)
RescanIcon.Size = UDim2.fromOffset(16, 16)
RescanIcon.Position = UDim2.new(0, 14, 0.5, -8)
RescanIcon.BackgroundTransparency = 1
RescanIcon.Image = Icons.Refresh
RescanIcon.ImageColor3 = Colors.PrimaryLight

local RescanLbl = Instance.new("TextLabel", RescanBtn)
RescanLbl.Size = UDim2.new(1, -44, 1, 0)
RescanLbl.Position = UDim2.fromOffset(40, 0)
RescanLbl.BackgroundTransparency = 1
RescanLbl.Text = "Rescan Assets"
RescanLbl.Font = Enum.Font.GothamBold
RescanLbl.TextSize = 11
RescanLbl.TextColor3 = Colors.Text
RescanLbl.TextXAlignment = Enum.TextXAlignment.Left

-- =====================================================
-- CONTENT CONTAINER & VIEWS
-- =====================================================
local ContentContainer = Instance.new("Frame", MainWindow)
ContentContainer.Size = UDim2.new(1, -180, 1, 0)
ContentContainer.Position = UDim2.new(0, 180, 0, 0)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ClipsDescendants = true

-- View 1: Assets Dashboard
local AssetsView = Instance.new("Frame", ContentContainer)
AssetsView.Size = UDim2.fromScale(1, 1)
AssetsView.BackgroundTransparency = 1
AssetsView.Visible = true

local AssetsPadding = Instance.new("UIPadding", AssetsView)
AssetsPadding.PaddingLeft = UDim.new(0, 20)
AssetsPadding.PaddingRight = UDim.new(0, 20)
AssetsPadding.PaddingTop = UDim.new(0, 18)
AssetsPadding.PaddingBottom = UDim.new(0, 16)

local HeaderTitle = Instance.new("TextLabel", AssetsView)
HeaderTitle.Size = UDim2.new(1, 0, 0, 20)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "Assets Dashboard"
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 16
HeaderTitle.TextColor3 = Colors.Text
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Stats
local StatsFrame = Instance.new("Frame", AssetsView)
StatsFrame.Size = UDim2.new(1, 0, 0, 48)
StatsFrame.Position = UDim2.fromOffset(0, 28)
StatsFrame.BackgroundTransparency = 1

local function createStatCard(posX, label, defVal)
    local card = Instance.new("Frame", StatsFrame)
    card.Size = UDim2.new(0.48, 0, 1, 0)
    card.Position = UDim2.new(posX, 0, 0, 0)
    card.BackgroundColor3 = Colors.Surface
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local cStroke = Instance.new("UIStroke", card)
    cStroke.Color = Colors.Primary
    cStroke.Transparency = 0.6

    local valLbl = Instance.new("TextLabel", card)
    valLbl.Size = UDim2.new(1, -16, 0, 20)
    valLbl.Position = UDim2.fromOffset(12, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = defVal
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 16
    valLbl.TextColor3 = Colors.PrimaryLight
    valLbl.TextXAlignment = Enum.TextXAlignment.Left

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size = UDim2.new(1, -16, 0, 14)
    titleLbl.Position = UDim2.fromOffset(12, 26)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = label
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 9
    titleLbl.TextColor3 = Colors.TextMuted
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    return valLbl
end

local StatTotalLbl = createStatCard(0, "TOTAL ASSETS", "0")
local StatReadyLbl = createStatCard(0.52, "DECOMPRESSOR", "LZ4 + ZSTD PRO")

-- Filter Bar (ALL, MODEL, PLACE)
local CurrentFilter = "ALL"
local FilterFrame = Instance.new("Frame", AssetsView)
FilterFrame.Size = UDim2.new(1, 0, 0, 28)
FilterFrame.Position = UDim2.fromOffset(0, 84)
FilterFrame.BackgroundColor3 = Color3.fromRGB(18, 14, 25)
Instance.new("UICorner", FilterFrame).CornerRadius = UDim.new(1, 0)

local FilterStroke = Instance.new("UIStroke", FilterFrame)
FilterStroke.Color = Colors.Border
FilterStroke.Transparency = 0.5

local FilterButtons = {}
local function createFilterButton(text, index, filterType)
    local btn = Instance.new("TextButton", FilterFrame)
    btn.Size = UDim2.new(0.333, 0, 1, 0)
    btn.Position = UDim2.new((index - 1) * 0.333, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = index == 1 and Colors.Text or Colors.TextMuted
    FilterButtons[filterType] = btn
    return btn
end

local btnAll   = createFilterButton("ALL", 1, "ALL")
local btnModel = createFilterButton("MODEL (.rbxm)", 2, "MODEL")
local btnPlace = createFilterButton("PLACE (.rbxl)", 3, "PLACE")

-- Asset Scroll List (CanvasSize Real-Time Update)
local AssetScroll = Instance.new("ScrollingFrame", AssetsView)
AssetScroll.Size = UDim2.new(1, 0, 1, -122)
AssetScroll.Position = UDim2.fromOffset(0, 120)
AssetScroll.BackgroundTransparency = 1
AssetScroll.ScrollBarThickness = 3
AssetScroll.ScrollBarImageColor3 = Colors.Primary
AssetScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local ScrollLayout = Instance.new("UIListLayout", AssetScroll)
ScrollLayout.Padding = UDim.new(0, 8)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    AssetScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 25)
end)

-- View 2: System Info
local InfoView = Instance.new("Frame", ContentContainer)
InfoView.Size = UDim2.fromScale(1, 1)
InfoView.BackgroundTransparency = 1
InfoView.Visible = false

local InfoPadding = Instance.new("UIPadding", InfoView)
InfoPadding.PaddingLeft = UDim.new(0, 20)
InfoPadding.PaddingRight = UDim.new(0, 20)
InfoPadding.PaddingTop = UDim.new(0, 20)

local InfoTitle = Instance.new("TextLabel", InfoView)
InfoTitle.Size = UDim2.new(1, 0, 0, 22)
InfoTitle.BackgroundTransparency = 1
InfoTitle.Text = "System Profile"
InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextSize = 16
InfoTitle.TextColor3 = Colors.Text
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left

local ProfileCard = Instance.new("Frame", InfoView)
ProfileCard.Size = UDim2.new(1, 0, 0, 76)
ProfileCard.Position = UDim2.fromOffset(0, 34)
ProfileCard.BackgroundColor3 = Colors.Surface
Instance.new("UICorner", ProfileCard).CornerRadius = UDim.new(0, 10)
local pStroke = Instance.new("UIStroke", ProfileCard)
pStroke.Color = Colors.Primary
pStroke.Transparency = 0.6

local AvatarImg = Instance.new("ImageLabel", ProfileCard)
AvatarImg.Size = UDim2.fromOffset(48, 48)
AvatarImg.Position = UDim2.fromOffset(14, 14)
AvatarImg.BackgroundColor3 = Colors.Sidebar
AvatarImg.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    pcall(function()
        local thumb = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        if thumb then AvatarImg.Image = thumb end
    end)
end)

local UserDisplayName = Instance.new("TextLabel", ProfileCard)
UserDisplayName.Size = UDim2.new(1, -80, 0, 20)
UserDisplayName.Position = UDim2.fromOffset(72, 16)
UserDisplayName.BackgroundTransparency = 1
UserDisplayName.Text = LP.DisplayName
UserDisplayName.Font = Enum.Font.GothamBold
UserDisplayName.TextSize = 14
UserDisplayName.TextColor3 = Colors.Text
UserDisplayName.TextXAlignment = Enum.TextXAlignment.Left

local UserTag = Instance.new("TextLabel", ProfileCard)
UserTag.Size = UDim2.new(1, -80, 0, 16)
UserTag.Position = UDim2.fromOffset(72, 36)
UserTag.BackgroundTransparency = 1
UserTag.Text = "@" .. LP.Name .. " | ID: " .. tostring(LP.UserId)
UserTag.Font = Enum.Font.Gotham
UserTag.TextSize = 10
UserTag.TextColor3 = Colors.TextMuted
UserTag.TextXAlignment = Enum.TextXAlignment.Left

local EngineCard = Instance.new("Frame", InfoView)
EngineCard.Size = UDim2.new(1, 0, 0, 115)
EngineCard.Position = UDim2.fromOffset(0, 120)
EngineCard.BackgroundColor3 = Colors.Surface
Instance.new("UICorner", EngineCard).CornerRadius = UDim.new(0, 10)
local eStroke = Instance.new("UIStroke", EngineCard)
eStroke.Color = Colors.Primary
eStroke.Transparency = 0.6

local EngineTitle = Instance.new("TextLabel", EngineCard)
EngineTitle.Size = UDim2.new(1, -24, 0, 20)
EngineTitle.Position = UDim2.fromOffset(14, 10)
EngineTitle.BackgroundTransparency = 1
EngineTitle.Text = "DECOMPRESSION & IMPORT SPECIFICATIONS"
EngineTitle.Font = Enum.Font.GothamBold
EngineTitle.TextSize = 11
EngineTitle.TextColor3 = Colors.PrimaryLight
EngineTitle.TextXAlignment = Enum.TextXAlignment.Left

local EngineDesc = Instance.new("TextLabel", EngineCard)
EngineDesc.Size = UDim2.new(1, -24, 0, 75)
EngineDesc.Position = UDim2.fromOffset(14, 32)
EngineDesc.BackgroundTransparency = 1
EngineDesc.Text = "• Core Insert: FORKT v3.8 PRO Native Architecture\n• Scanner: MCHLERN Engine (Multi-Path Throttling)\n• Decompressor 1: LZ4 Pure Luau Block Engine\n• Decompressor 2: ZSTD (Zstandard) Native C++ Bridge\n• Script Recovery: Dual Layer (XML + Binary Chunk Parser)"
EngineDesc.Font = Enum.Font.GothamMedium
EngineDesc.TextSize = 10
EngineDesc.TextColor3 = Colors.TextMuted
EngineDesc.TextXAlignment = Enum.TextXAlignment.Left
EngineDesc.TextYAlignment = Enum.TextYAlignment.Top

-- View 3: Settings
local SettingsView = Instance.new("Frame", ContentContainer)
SettingsView.Size = UDim2.fromScale(1, 1)
SettingsView.BackgroundTransparency = 1
SettingsView.Visible = false

local SetPadding = Instance.new("UIPadding", SettingsView)
SetPadding.PaddingLeft = UDim.new(0, 20)
SetPadding.PaddingRight = UDim.new(0, 20)
SetPadding.PaddingTop = UDim.new(0, 20)

local SetTitle = Instance.new("TextLabel", SettingsView)
SetTitle.Size = UDim2.new(1, 0, 0, 22)
SetTitle.BackgroundTransparency = 1
SetTitle.Text = "Panduan Folder Delta"
SetTitle.Font = Enum.Font.GothamBold
SetTitle.TextSize = 16
SetTitle.TextColor3 = Colors.Text
SetTitle.TextXAlignment = Enum.TextXAlignment.Left

local HelpCard = Instance.new("Frame", SettingsView)
HelpCard.Size = UDim2.new(1, 0, 0, 130)
HelpCard.Position = UDim2.fromOffset(0, 34)
HelpCard.BackgroundColor3 = Colors.Surface
Instance.new("UICorner", HelpCard).CornerRadius = UDim.new(0, 10)
local hStroke = Instance.new("UIStroke", HelpCard)
hStroke.Color = Colors.Primary
hStroke.Transparency = 0.6

local HelpText = Instance.new("TextLabel", HelpCard)
HelpText.Size = UDim2.new(1, -24, 1, -24)
HelpText.Position = UDim2.fromOffset(12, 12)
HelpText.BackgroundTransparency = 1
HelpText.Text = "1. Taruh file .rbxm atau .rbxl di folder:\n   Penyimpanan Internal > Delta > workspace\n   (atau folder Download HP kamu)\n\n2. Klik tombol 'Rescan Assets' di sidebar kiri.\n3. Tekan tombol IMPORT pada file yang ingin kamu pasang."
HelpText.Font = Enum.Font.GothamMedium
HelpText.TextSize = 11
HelpText.TextColor3 = Colors.TextMuted
HelpText.TextXAlignment = Enum.TextXAlignment.Left
HelpText.TextYAlignment = Enum.TextYAlignment.Top
HelpText.TextWrapped = true

-- =====================================================
-- TAB NAVIGATION CONTROLLER
-- =====================================================
local Tabs = {}
local function createTabButton(name, iconId, targetView)
    local tabBtn = Instance.new("TextButton", TabContainer)
    tabBtn.Size = UDim2.new(1, -28, 0, 36)
    tabBtn.BackgroundColor3 = Colors.Sidebar
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = ""
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

    local activeBar = Instance.new("Frame", tabBtn)
    activeBar.Size = UDim2.new(0, 3, 0, 0)
    activeBar.Position = UDim2.new(0, 0, 0.5, 0)
    activeBar.AnchorPoint = Vector2.new(0, 0.5)
    activeBar.BackgroundColor3 = Colors.PrimaryLight
    activeBar.BorderSizePixel = 0
    Instance.new("UICorner", activeBar).CornerRadius = UDim.new(1, 0)

    local tabIcon = Instance.new("ImageLabel", tabBtn)
    tabIcon.Size = UDim2.fromOffset(16, 16)
    tabIcon.Position = UDim2.new(0, 14, 0.5, -8)
    tabIcon.BackgroundTransparency = 1
    tabIcon.Image = iconId
    tabIcon.ImageColor3 = Colors.TextMuted

    local tabLbl = Instance.new("TextLabel", tabBtn)
    tabLbl.Size = UDim2.new(1, -44, 1, 0)
    tabLbl.Position = UDim2.fromOffset(40, 0)
    tabLbl.BackgroundTransparency = 1
    tabLbl.Text = name
    tabLbl.Font = Enum.Font.GothamMedium
    tabLbl.TextSize = 11
    tabLbl.TextColor3 = Colors.TextMuted
    tabLbl.TextXAlignment = Enum.TextXAlignment.Left

    Tabs[name] = {
        Button = tabBtn,
        Icon = tabIcon,
        Label = tabLbl,
        Bar = activeBar,
        View = targetView
    }

    tabBtn.MouseButton1Click:Connect(function()
        for tabName, tabData in pairs(Tabs) do
            local isActive = (tabName == name)
            tabData.View.Visible = isActive

            TweenService:Create(tabData.Bar, TweenInfo.new(0.25), {
                Size = isActive and UDim2.new(0, 3, 0, 18) or UDim2.new(0, 3, 0, 0),
                BackgroundTransparency = isActive and 0 or 1
            }):Play()

            TweenService:Create(tabData.Button, TweenInfo.new(0.2), {
                BackgroundTransparency = isActive and 0.85 or 1,
                BackgroundColor3 = Colors.Primary
            }):Play()

            TweenService:Create(tabData.Label, TweenInfo.new(0.2), {
                TextColor3 = isActive and Colors.Text or Colors.TextMuted
            }):Play()

            TweenService:Create(tabData.Icon, TweenInfo.new(0.2), {
                ImageColor3 = isActive and Colors.PrimaryLight or Colors.TextMuted
            }):Play()
        end
    end)
end

createTabButton("Assets", Icons.Folder, AssetsView)
createTabButton("System Info", Icons.Dashboard, InfoView)
createTabButton("Settings", Icons.Settings, SettingsView)

if Tabs["Assets"] then
    Tabs["Assets"].View.Visible = true
    Tabs["Assets"].Bar.Size = UDim2.new(0, 3, 0, 18)
    Tabs["Assets"].Label.TextColor3 = Colors.Text
    Tabs["Assets"].Icon.ImageColor3 = Colors.PrimaryLight
    Tabs["Assets"].Button.BackgroundTransparency = 0.85
    Tabs["Assets"].Button.BackgroundColor3 = Colors.Primary
end

-- =====================================================
-- ASSET ITEM POPULATION (100% RESPONSIF)
-- =====================================================
local renderedCards = {}

local function renderAssetItem(fileData)
    local itemFrame = Instance.new("Frame", AssetScroll)
    itemFrame.Size = UDim2.new(1, -6, 0, 52)
    itemFrame.BackgroundColor3 = Colors.Surface
    Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 8)

    local iStroke = Instance.new("UIStroke", itemFrame)
    iStroke.Color = Colors.Border
    iStroke.Transparency = 0.7

    itemFrame:SetAttribute("FileType", fileData.fileType)

    local isPlace = fileData.fileType == "PLACE"
    local tagColor = isPlace and Colors.PlaceTag or Colors.ModelTag

    -- Tag Icon Box
    local iconBox = Instance.new("Frame", itemFrame)
    iconBox.Size = UDim2.fromOffset(34, 34)
    iconBox.Position = UDim2.fromOffset(10, 9)
    iconBox.BackgroundColor3 = tagColor
    iconBox.BackgroundTransparency = 0.85
    Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 6)

    local icon = Instance.new("ImageLabel", iconBox)
    icon.Size = UDim2.fromOffset(16, 16)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = isPlace and Icons.Gamepad or Icons.File
    icon.ImageColor3 = tagColor

    -- Label Nama & Path
    local nameLbl = Instance.new("TextLabel", itemFrame)
    nameLbl.Size = UDim2.new(1, -150, 0, 16)
    nameLbl.Position = UDim2.fromOffset(52, 10)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = fileData.name
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextColor3 = Colors.Text
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local pathLbl = Instance.new("TextLabel", itemFrame)
    pathLbl.Size = UDim2.new(1, -150, 0, 14)
    pathLbl.Position = UDim2.fromOffset(52, 26)
    pathLbl.BackgroundTransparency = 1
    pathLbl.Text = fileData.path
    pathLbl.Font = Enum.Font.Gotham
    pathLbl.TextSize = 9
    pathLbl.TextColor3 = Colors.TextMuted
    pathLbl.TextXAlignment = Enum.TextXAlignment.Left
    pathLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Import Button (Menggunakan runForktImport 1:1 FORKT Engine)
    local importBtn = Instance.new("TextButton", itemFrame)
    importBtn.Size = UDim2.fromOffset(70, 28)
    importBtn.Position = UDim2.new(1, -78, 0.5, -14)
    importBtn.BackgroundColor3 = Colors.Primary
    importBtn.Text = "IMPORT"
    importBtn.Font = Enum.Font.GothamBold
    importBtn.TextSize = 10
    importBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", importBtn).CornerRadius = UDim.new(0, 6)

    importBtn.MouseButton1Click:Connect(function()
        if importBtn.Text == "LOADING" then return end
        importBtn.Text = "LOADING"
        importBtn.BackgroundColor3 = Colors.PrimaryDark

        task.spawn(function()
            local success, msg = runForktImport(fileData)
            if success then
                importBtn.Text = "DONE"
                importBtn.BackgroundColor3 = Colors.Success
                showToast("Import Sukses", msg, false)
            else
                importBtn.Text = "FAIL"
                importBtn.BackgroundColor3 = Colors.Error
                showToast("Import Gagal", msg, true)
            end

            task.wait(2)
            if importBtn and importBtn.Parent then
                importBtn.Text = "IMPORT"
                importBtn.BackgroundColor3 = Colors.Primary
            end
        end)
    end)

    table.insert(renderedCards, { card = itemFrame, ftype = fileData.fileType })
    return itemFrame
end

local function applyFilter(filter)
    CurrentFilter = filter
    for fType, btn in pairs(FilterButtons) do
        local isSelected = (fType == filter)
        TweenService:Create(btn, TweenInfo.new(0.2), {
            TextColor3 = isSelected and Colors.Text or Colors.TextMuted
        }):Play()
    end

    for _, item in ipairs(renderedCards) do
        local visible = (filter == "ALL") or (item.ftype == filter)
        item.card.Visible = visible
    end
    AssetScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 25)
end

btnAll.MouseButton1Click:Connect(function() applyFilter("ALL") end)
btnModel.MouseButton1Click:Connect(function() applyFilter("MODEL") end)
btnPlace.MouseButton1Click:Connect(function() applyFilter("PLACE") end)

local isScanning = false
local function performScan()
    if isScanning then return end
    isScanning = true
    RescanLbl.Text = "Scanning..."

    for _, child in ipairs(AssetScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    renderedCards = {}

    task.spawn(function()
        local files = getAllAssetFiles()

        for _, fileData in ipairs(files) do
            renderAssetItem(fileData)
            task.wait(0.01)
        end

        AssetScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 25)
        applyFilter(CurrentFilter)
        StatTotalLbl.Text = tostring(#files)
        RescanLbl.Text = "Rescan Assets"
        isScanning = false

        if #files > 0 then
            showToast("Scan Selesai", string.format("Ditemukan %d file asset di memori HP.", #files), false)
        else
            showToast("Folder Kosong", "Taruh file di Delta/workspace atau Download.", true)
        end
    end)
end

RescanBtn.MouseButton1Click:Connect(performScan)

-- Initial Auto Scan on Startup
task.defer(performScan)
showToast("FORKT Importer", "Engine FORKT v3.8 PRO siap digunakan di Studio Lite!", false)
