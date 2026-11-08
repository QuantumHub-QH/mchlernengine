--[[
============================================================
   ____ ___  ____  _  _______   _____ __  ______  ____  ______
  / __// _ \/ _  \| |/ /_  __/  /  _/  |/  / _ \/ __ \/ __/  _/
 / _/ / // / , _/| ' /  / /    _/ // /|_/ / ___/ /_/ / _/ _/ /  
/_/   \___/_/|_|/_/|_| /_/    /___/_/  /_/_/   \____/_/  /___/   
                                                                  
   [*] Target      : Roblox Studio Lite (ScottSpiritWalker)
   [*] Executor    : Delta / Android / PC
   [*] Engine      : FORKT Hybrid Engine (Native Asset + SL Bridge)
   [*] Status      : Clean, Keyless & Full Unlocked
============================================================
]]--

-- 1. SERVICES & BASIC SETUP
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- Resolve Safe CoreGui Container
local function getSafeGui()
    if gethui then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = getSafeGui()

-- Studio Lite Remote & Folder Hooks
local StudioLiteFolder = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local ServerFunctions = StudioLiteFolder and StudioLiteFolder:FindFirstChild("ServerFunctions")

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

-- Icons Library
local Icons = {
    ToggleIcon = "rbxassetid://137790966470480",
    Package    = "rbxassetid://128864012857079",
    Folder     = "rbxassetid://88761476236687",
    Dashboard  = "rbxassetid://90838150633173",
    Settings   = "rbxassetid://11956055886",
    Refresh    = "rbxassetid://13492317101",
    File       = "rbxassetid://17109896197",
    Gamepad    = "rbxassetid://115836418226834",
    Check      = "rbxassetid://18349889388",
    Close      = "rbxassetid://126290678159164",
    Bell       = "rbxassetid://14013788454",
    Alert      = "rbxassetid://7634887649"
}

-- Clean Existing UI if Already Running
local existingGui = GuiParent:FindFirstChild("ForktImporter_CleanUI")
if existingGui then
    existingGui:Destroy()
end

-- ============================================================
-- 2. CORE FORKT ENGINE (FILE SCANNER & HYBRID IMPORTER)
-- ============================================================

local Engine = {}

Engine.SearchPaths = {
    "Delta/workspace",
    "delta/workspace",
    "workspace",
    "/sdcard/Delta/workspace",
    "/sdcard/Android/Delta/workspace",
    "Download",
    "Downloads",
    "/sdcard/Download",
    "/sdcard/Downloads",
    "/storage/emulated/0/Download",
    "/storage/emulated/0/Downloads",
    "."
}

local function getBaseFileName(path)
    return path:match("([^/\\]+)$") or path
end

local function getFileType(fileName)
    local lower = fileName:lower()
    if lower:match("%.rbxmx?$") then
        return "MODEL"
    elseif lower:match("%.rbxlx?$") then
        return "PLACE"
    end
    return nil
end

function Engine.ScanFiles()
    local results = {}
    local visited = {}

    if not listfiles then
        warn("[FORKT Engine] listfiles() tidak tersedia pada executor ini.")
        return results
    end

    local function scanDirectory(dir, depth)
        if depth > 4 or visited[dir] then return end
        visited[dir] = true

        local success, files = pcall(listfiles, dir)
        if not success or not files then return end

        for _, filePath in ipairs(files) do
            local name = getBaseFileName(filePath)
            local ftype = getFileType(name)

            if ftype then
                table.insert(results, {
                    name = name,
                    path = filePath,
                    fileType = ftype
                })
            else
                local isDir = (isfolder and isfolder(filePath)) or not name:match("%.[%w]+$")
                if isDir then
                    scanDirectory(filePath, depth + 1)
                end
            end
        end
    end

    for _, root in ipairs(Engine.SearchPaths) do
        local ok = (isfolder and isfolder(root)) or pcall(listfiles, root)
        if ok then
            scanDirectory(root, 0)
        end
    end

    return results
end

-- Register Mesh & Texture IDs to Studio Lite Runtime
local function registerMeshToStudioLite(meshIdStr)
    if not ServerFunctions or not meshIdStr or meshIdStr == "" then return end
    local numId = tonumber(tostring(meshIdStr):match("%d+"))
    if numId then
        pcall(function()
            ServerFunctions:InvokeServer("LoadMeshToRuntimeMeshes", numId)
        end)
    end
end

-- Adapt Object Properties and Tagging for Studio Lite
local function adaptInstanceForStudioLite(instance)
    for _, desc in ipairs(instance:GetDescendants()) do
        if desc:IsA("BasePart") then
            local origAnchored = desc.Anchored
            local origCollide = desc.CanCollide

            if desc:GetAttribute("SL_Anchored") == nil then
                desc:SetAttribute("SL_Anchored", origAnchored)
                desc:SetAttribute("SL_CanCollide", origCollide)
            end

            desc.Anchored = true

            if desc:IsA("MeshPart") then
                registerMeshToStudioLite(desc.MeshId)
                registerMeshToStudioLite(desc.TextureID)
            end
        end
    end
end

-- Main Import Function for .rbxm and .rbxl
function Engine.ImportFile(fileData)
    local filePath = fileData.path
    local isPlace = fileData.fileType == "PLACE"

    if isfile and not isfile(filePath) then
        return false, "File tidak ditemukan di storage HP."
    end

    -- Step 1: Request Roblox Game Engine to Deserialize Asset
    local loadOk, objects = pcall(function()
        local assetUri
        if getcustomasset then
            assetUri = getcustomasset(filePath)
        else
            assetUri = "rbxasset://" .. filePath:gsub("\\", "/")
        end
        return game:GetObjects(assetUri)
    end)

    if not loadOk or not objects or #objects == 0 then
        if isPlace then
            return false, "RBXL terdeteksi tetapi Delta gagal mengembalikan DataModel."
        else
            return false, "Gagal membuat Instance dari file .rbxm."
        end
    end

    -- Step 2: Prepare Target Container
    local cleanName = fileData.name:gsub("%.[^%.]+$", "")
    local importFolder = Instance.new("Folder")
    importFolder.Name = "Imported_" .. cleanName
    importFolder:SetAttribute("FORKT_IMPORTED", true)
    importFolder:SetAttribute("SourcePath", filePath)

    local loadedCount = 0

    -- Step 3: Handle Objects (Model vs DataModel RBXL)
    for _, obj in ipairs(objects) do
        if typeof(obj) == "Instance" then
            if obj:IsA("DataModel") then
                -- Unpack DataModel Services for .rbxl
                local targetServices = {
                    ["Workspace"] = Workspace,
                    ["Lighting"] = game:GetService("Lighting"),
                    ["ReplicatedStorage"] = ReplicatedStorage
                }

                for _, service in ipairs(obj:GetChildren()) do
                    if service.Name == "Workspace" then
                        for _, item in ipairs(service:GetChildren()) do
                            adaptInstanceForStudioLite(item)
                            item.Parent = importFolder
                            loadedCount = loadedCount + 1
                            task.wait(0)
                        end
                    elseif targetServices[service.Name] then
                        for _, item in ipairs(service:GetChildren()) do
                            item.Parent = targetServices[service.Name]
                            loadedCount = loadedCount + 1
                        end
                    end
                end
            else
                -- Normal .rbxm Model / Part
                adaptInstanceForStudioLite(obj)
                obj.Parent = importFolder
                loadedCount = loadedCount + 1
            end
        end
    end

    importFolder.Parent = Workspace
    return true, string.format("Berhasil import %d object ke Workspace!", loadedCount)
end

-- ============================================================
-- 3. USER INTERFACE (FORKT STYLE & FIXED NON-DRAGGABLE TOGGLE)
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ForktImporter_CleanUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

-- Toast Notification Component
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

    -- Slide in
    TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -20, 1, -20)
    }):Play()

    -- Auto dismiss
    task.delay(3, function()
        if toast and toast.Parent then
            local tw = TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 280, 1, -20)
            })
            tw:Play()
            tw.Completed:Connect(function()
                toast:Destroy()
            end)
        end
    end)
end

-- ============================================================
-- TOGGLE BUTTON (DI KIRI, FIXED POSITION, TIDAK BISA DIDRAG)
-- ============================================================
local ToggleButton = Instance.new("ImageButton", ScreenGui)
ToggleButton.Name = "FixedToggleLeft"
ToggleButton.Size = UDim2.fromOffset(46, 46)
ToggleButton.Position = UDim2.new(0, 14, 0.5, -23) -- Tetap di kiri tengah layar
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
ToggleIcon.Image = Icons.ToggleIcon -- Gambar 137790966470480 permintaan user
ToggleIcon.ZIndex = 51

-- Efek Hover / Press Halus (Tanpa Drag)
ToggleButton.MouseEnter:Connect(function()
    TweenService:Create(ToggleStroke, TweenInfo.new(0.2), {Transparency = 0, Color = Colors.PrimaryLight}):Play()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.SurfaceHover}):Play()
end)

ToggleButton.MouseLeave:Connect(function()
    TweenService:Create(ToggleStroke, TweenInfo.new(0.2), {Transparency = 0.3, Color = Colors.Primary}):Play()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Surface}):Play()
end)

-- ============================================================
-- MAIN WINDOW FRAME & RESPONSIVE SCALING
-- ============================================================

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

-- Responsive Scale untuk Mobile Phone
local MainScale = Instance.new("UIScale", MainWindow)
local function updateUiScale()
    local cam = Workspace.CurrentCamera
    if cam and cam.ViewportSize.X > 0 then
        local scaleFactor = math.min(cam.ViewportSize.X / 600, cam.ViewportSize.Y / 420, 1)
        MainScale.Scale = math.clamp(scaleFactor, 0.55, 1)
    end
end
updateUiScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUiScale)
end

-- Hubungkan Toggle Button untuk Buka/Tutup Main Window
ToggleButton.MouseButton1Click:Connect(function()
    MainWindow.Visible = not MainWindow.Visible
    local targetScale = MainWindow.Visible and 1 or 0.8
    local targetRot = MainWindow.Visible and 0 or 360
    TweenService:Create(ToggleIcon, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Rotation = targetRot
    }):Play()
end)

-- Top Close Button di MainWindow
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

-- ============================================================
-- SIDEBAR (LOGO, TABS & QUICK RESCAN)
-- ============================================================

local Sidebar = Instance.new("Frame", MainWindow)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local SidebarStroke = Instance.new("UIStroke", Sidebar)
SidebarStroke.Color = Colors.Primary
SidebarStroke.Transparency = 0.7
SidebarStroke.Thickness = 1

-- Brand Header
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
BrandSub.Text = "Studio Lite Importer"
BrandSub.Font = Enum.Font.GothamMedium
BrandSub.TextSize = 9
BrandSub.TextColor3 = Colors.TextMuted
BrandSub.TextXAlignment = Enum.TextXAlignment.Left

-- Divider
local Divider = Instance.new("Frame", Sidebar)
Divider.Size = UDim2.new(1, -28, 0, 1)
Divider.Position = UDim2.fromOffset(14, 56)
Divider.BackgroundColor3 = Colors.Border
Divider.BorderSizePixel = 0

-- Tab Container
local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.Size = UDim2.new(1, 0, 0, 150)
TabContainer.Position = UDim2.fromOffset(0, 68)
TabContainer.BackgroundTransparency = 1

local TabListLayout = Instance.new("UIListLayout", TabContainer)
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Rescan Assets Button
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

-- ============================================================
-- CONTENT CONTAINER & VIEWS
-- ============================================================

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

-- Stat Counters (Total Assets & Ready)
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
local StatReadyLbl = createStatCard(0.52, "CORE ENGINE", "ONLINE")

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

local btnAll = createFilterButton("ALL", 1, "ALL")
local btnModel = createFilterButton("MODEL (.rbxm)", 2, "MODEL")
local btnPlace = createFilterButton("PLACE (.rbxl)", 3, "PLACE")

-- Asset Scroll List
local AssetScroll = Instance.new("ScrollingFrame", AssetsView)
AssetScroll.Size = UDim2.new(1, 0, 1, -122)
AssetScroll.Position = UDim2.fromOffset(0, 120)
AssetScroll.BackgroundTransparency = 1
AssetScroll.ScrollBarThickness = 3
AssetScroll.ScrollBarImageColor3 = Colors.Primary
AssetScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
AssetScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local ScrollLayout = Instance.new("UIListLayout", AssetScroll)
ScrollLayout.Padding = UDim.new(0, 8)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

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
        local thumb = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        if thumb then AvatarImg.Image = thumb end
    end)
end)

local UserDisplayName = Instance.new("TextLabel", ProfileCard)
UserDisplayName.Size = UDim2.new(1, -80, 0, 20)
UserDisplayName.Position = UDim2.fromOffset(72, 16)
UserDisplayName.BackgroundTransparency = 1
UserDisplayName.Text = LocalPlayer.DisplayName
UserDisplayName.Font = Enum.Font.GothamBold
UserDisplayName.TextSize = 14
UserDisplayName.TextColor3 = Colors.Text
UserDisplayName.TextXAlignment = Enum.TextXAlignment.Left

local UserTag = Instance.new("TextLabel", ProfileCard)
UserTag.Size = UDim2.new(1, -80, 0, 16)
UserTag.Position = UDim2.fromOffset(72, 36)
UserTag.BackgroundTransparency = 1
UserTag.Text = "@" .. LocalPlayer.Name .. " | ID: " .. tostring(LocalPlayer.UserId)
UserTag.Font = Enum.Font.Gotham
UserTag.TextSize = 10
UserTag.TextColor3 = Colors.TextMuted
UserTag.TextXAlignment = Enum.TextXAlignment.Left

-- View 3: Settings & Instructions
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

-- ============================================================
-- TAB NAVIGATION CONTROLLER
-- ============================================================

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

-- Set Default Active Tab
if Tabs["Assets"] then
    Tabs["Assets"].View.Visible = true
    Tabs["Assets"].Bar.Size = UDim2.new(0, 3, 0, 18)
    Tabs["Assets"].Label.TextColor3 = Colors.Text
    Tabs["Assets"].Icon.ImageColor3 = Colors.PrimaryLight
    Tabs["Assets"].Button.BackgroundTransparency = 0.85
    Tabs["Assets"].Button.BackgroundColor3 = Colors.Primary
end

-- ============================================================
-- ASSET ITEM POPULATION & RESCAN CONTROLLER
-- ============================================================

local CurrentScannedFiles = {}

local function renderAssetItem(fileData)
    local itemFrame = Instance.new("Frame", AssetScroll)
    itemFrame.Size = UDim2.new(1, 0, 0, 52)
    itemFrame.BackgroundColor3 = Colors.Surface
    Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 8)

    local iStroke = Instance.new("UIStroke", itemFrame)
    iStroke.Color = Colors.Border
    iStroke.Transparency = 0.7

    itemFrame:SetAttribute("FileType", fileData.fileType)

    local isPlace = fileData.fileType == "PLACE"
    local tagColor = isPlace and Colors.PlaceTag or Colors.ModelTag

    -- Icon
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

    -- Name & Path
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

    -- Import Button
    local importBtn = Instance.new("TextButton", itemFrame)
    importBtn.Size = UDim2.fromOffset(70, 28)
    importBtn.Position = UDim2.new(1, -80, 0.5, -14)
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
            local success, msg = Engine.ImportFile(fileData)
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
end

local function applyFilter(filter)
    CurrentFilter = filter
    for fType, btn in pairs(FilterButtons) do
        local isSelected = (fType == filter)
        TweenService:Create(btn, TweenInfo.new(0.2), {
            TextColor3 = isSelected and Colors.Text or Colors.TextMuted
        }):Play()
    end

    for _, child in ipairs(AssetScroll:GetChildren()) do
        if child:IsA("Frame") and child:GetAttribute("FileType") then
            local ftype = child:GetAttribute("FileType")
            child.Visible = (filter == "ALL") or (ftype == filter)
        end
    end
end

btnAll.MouseButton1Click:Connect(function() applyFilter("ALL") end)
btnModel.MouseButton1Click:Connect(function() applyFilter("MODEL") end)
btnPlace.MouseButton1Click:Connect(function() applyFilter("PLACE") end)

local isScanning = false
local function performScan()
    if isScanning then return end
    isScanning = true
    RescanLbl.Text = "Scanning..."

    -- Bersihkan list lama
    for _, child in ipairs(AssetScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    task.spawn(function()
        local files = Engine.ScanFiles()
        CurrentScannedFiles = files

        for _, fileData in ipairs(files) do
            renderAssetItem(fileData)
            task.wait(0.01)
        end

        applyFilter(CurrentFilter)
        StatTotalLbl.Text = tostring(#files)
        RescanLbl.Text = "Rescan Assets"
        isScanning = false

        if #files > 0 then
            showToast("Scan Selesai", string.format("Ditemukan %d file asset di memori HP.", #files), false)
        else
            showToast("Folder Kosong", "Tidak ada file .rbxm/.rbxl di folder Delta/workspace.", true)
        end
    end)
end

RescanBtn.MouseButton1Click:Connect(performScan)

-- Initial Auto Scan on Startup
task.defer(performScan)
showToast("FORKT Importer", "Engine siap digunakan di Studio Lite!", false)
