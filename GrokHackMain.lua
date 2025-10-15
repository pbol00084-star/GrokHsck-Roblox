--[[
    PizdabolHack
    Author: PizdabolTeam
    Version: 1.3.0 (Uploaded: October 15, 2025)
    WARNING: Educational only! Use at own risk. Violates Roblox ToS.
    NOTICE: Requires executor with 60-80%+ UNC (Unified Naming Convention) for full functionality.
            Recommended executors:
            - PC: Velocity, Solara, JJSploit
            - Mobile: Codex, Krnl, Delta
            Below 60% UNC, features may not work. Use Krnl (90-99%) or Codex (98%) for best results.
]]

-- Load LinoriaLib and Addons (from Obsidian fork)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local success, Library = pcall(loadstring(game:HttpGet(repo .. "Library.lua")))
if not success then
    warn("UI failed to load. Executor may not support loadstring. Use 60%+ UNC executor.")
    return
end
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Load Drawing API (fallback)
if not Drawing then
    local drawingLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/UI/Drawing.lua"))() or getgenv().Drawing
    getgenv().Drawing = drawingLib
end
local Drawing = getgenv().Drawing

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Settings
local ESP_ENABLED = false
local BOX_ENABLED = true
local NAME_ENABLED = true
local DIST_ENABLED = true
local HEALTH_ENABLED = true
local CHAMS_ENABLED = true
local AIMBOT_ENABLED = false
local SILENT_AIM_ENABLED = false
local FOV_ENABLED = false
local AIMBOT_PART = "Head" -- Head or Torso
local AIMBOT_IGNORE_WALLS = true
local AIMBOT_TEAM_CHECK = true
local AIMBOT_SMOOTHNESS = 0.5
local FOV_RADIUS = 100
local BOX_COLOR = Color3.fromRGB(255, 0, 0)
local NAME_COLOR = Color3.fromRGB(255, 255, 255)
local DIST_COLOR = Color3.fromRGB(0, 255, 0)
local CHAMS_FILL_COLOR = Color3.fromRGB(0, 255, 255)
local CHAMS_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local CHAMS_FILL_TRANSPARENCY = 0.5
local CHAMS_OUTLINE_TRANSPARENCY = 0
local HEALTH_BAR_WIDTH = 3
local HEALTH_BAR_HEIGHT_FACTOR = 1
local HEALTH_BAR_OFFSET = 6
local LANGUAGE = "EN" -- "EN" or "RU"
local UNC_PERCENT = 0 -- Будет определено позже

-- Translations
local translations = {
    ["EN"] = {
        ESP = "Enable ESP",
        Boxes = "Show Boxes",
        Names = "Show Names",
        Distance = "Show Distance",
        HealthBars = "Show Health Bars",
        Chams = "Show 3D Chams",
        Aimbot = "Centered Aimbot",
        SilentAim = "Silent Aim",
        TargetPart = "Target Part",
        IgnoreWalls = "Ignore Walls",
        TeamCheck = "Team Check",
        Smoothness = "Aimbot Smoothness",
        FovEnabled = "Enable FOV",
        FovRadius = "FOV Radius",
        Notify = "PizdabolHack Loaded! Press INSERT (PC) or tap (Mobile) for UI. Recommended executors: PC (Velocity, Solara, JJSploit), Mobile (Codex, Krnl, Delta). Requires 60-80%+ UNC. UNC: %d%%. Touch screen or hold RMB to aim."
    },
    ["RU"] = {
        ESP = "Включить ESP",
        Boxes = "Показать коробки",
        Names = "Показать имена",
        Distance = "Показать расстояние",
        HealthBars = "Показать полосы здоровья",
        Chams = "Показать 3D чамсы",
        Aimbot = "Центрированный аимбот",
        SilentAim = "Невидимый аим",
        TargetPart = "Целевая часть",
        IgnoreWalls = "Игнорировать стены",
        TeamCheck = "Проверка команды",
        Smoothness = "Скорость аимбота",
        FovEnabled = "Включить FOV",
        FovRadius = "Радиус FOV",
        Notify = "PizdabolHack загружен! Нажмите INSERT (ПК) или тап (мобильное) для UI. Рекомендуемые executor'ы: ПК (Velocity, Solara, JJSploit), Мобильное (Codex, Krnl, Delta). Требуется 60-80%+ UNC. UNC: %d%%. Тапните или удерживайте RMB для аима."
    }
}

-- ESP Objects
local espObjects = {}
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency = 0.5
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Visible = false

-- Mobile Touch Flag
local isTouchPressed = false
local isSwipeActive = false

-- Silent Aim Target
local silentAimTarget = nil

-- Check UNC
local function checkUNC()
    local success, result = pcall(loadstring(game:HttpGet("https://raw.githubusercontent.com/unified-naming-convention/NamingStandard/main/UNC%20Tester.lua"))())
    return success and math.floor(result * 100) or 0
end
UNC_PERCENT = checkUNC()

-- Create ESP
local function createESP(player)
    if player == LocalPlayer then return end
    if not Drawing then
        Library:Notify("Drawing API not supported. ESP disabled. Use executor with 60%+ UNC.")
        return
    end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Filled = false
    box.Thickness = 2
    box.Color = BOX_COLOR
    box.Transparency = 1
    
    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false
    nameLabel.Size = 16
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Font = 2
    nameLabel.Color = NAME_COLOR
    nameLabel.Text = player.Name
    
    local distLabel = Drawing.new("Text")
    distLabel.Visible = false
    distLabel.Size = 14
    distLabel.Center = true
    distLabel.Outline = true
    distLabel.Font = 2
    distLabel.Color = DIST_COLOR
    distLabel.Text = ""
    
    local healthBarBg = Drawing.new("Square")
    healthBarBg.Visible = false
    healthBarBg.Filled = true
    healthBarBg.Color = Color3.fromRGB(50, 50, 50)
    healthBarBg.Transparency = 0.7
    
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Filled = true
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Transparency = 1
    
    local highlight = Instance.new("Highlight")
    highlight.Enabled = false
    highlight.FillColor = CHAMS_FILL_COLOR
    highlight.OutlineColor = CHAMS_OUTLINE_COLOR
    highlight.FillTransparency = CHAMS_FILL_TRANSPARENCY
    highlight.OutlineTransparency = CHAMS_OUTLINE_TRANSPARENCY
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = nil
    highlight.Parent = game:GetService("CoreGui")
    
    espObjects[player] = {
        box = box, name = nameLabel, dist = distLabel,
        healthBarBg = healthBarBg, healthBar = healthBar,
        highlight = highlight, rootPart = nil, humanoid = nil
    }
end

-- Get Closest Player (centered with FOV)
local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetPart = player.Character:FindFirstChild(AIMBOT_PART)
            if targetPart and espObjects[player] then
                espObjects[player].rootPart = targetPart
                espObjects[player].humanoid = player.Character.Humanoid
                local screenPoint = Camera:WorldToViewportPoint(targetPart.Position)
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                if FOV_ENABLED and distance > FOV_RADIUS then continue end
                local charDistance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                if charDistance < closestDistance then
                    if AIMBOT_TEAM_CHECK and player.Team == LocalPlayer.Team then continue end
                    if not AIMBOT_IGNORE_WALLS then
                        local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
                        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
                        if hit and hit:IsDescendantOf(player.Character) then
                            closestPlayer = player
                            closestDistance = charDistance
                        end
                    else
                        closestPlayer = player
                        closestDistance = charDistance
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Update Aimbot (Centered)
local function updateAimbot(isPressed)
    if not AIMBOT_ENABLED or not isPressed then return end
    local target = getClosestPlayer()
    if target and espObjects[target] and espObjects[target].rootPart then
        local targetPos = espObjects[target].rootPart.Position
        pcall(function()
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, AIMBOT_SMOOTHNESS)
        end)
    end
end

-- Update Silent Aim
local function updateSilentAim(isPressed)
    if not SILENT_AIM_ENABLED or not isPressed then
        silentAimTarget = nil
        return
    end
    local target = getClosestPlayer()
    if target and espObjects[target] and espObjects[target].rootPart then
        silentAimTarget = target
        local targetPos = espObjects[target].rootPart.Position
        local ray = Ray.new(Camera.CFrame.Position, (targetPos - Camera.CFrame.Position).Unit * 1000)
        local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
        if hit and hit:IsDescendantOf(target.Character) then
            if getgenv().Mouse then
                getgenv().Mouse.Hit = CFrame.new(pos)
            else
                Library:Notify("Silent Aim disabled: Mouse API not supported.")
            end
        end
    end
end

-- Touch and Swipe Input
UserInputService.TouchStarted:Connect(function(input)
    isTouchPressed = true
    updateAimbot(true)
    updateSilentAim(true)
end)

UserInputService.TouchEnded:Connect(function(input)
    isTouchPressed = false
    isSwipeActive = false
end)

UserInputService.TouchMoved:Connect(function(input, processed)
    if processed then return end
    if not isSwipeActive and input.Position.X > Camera.ViewportSize.X - 50 then
        isSwipeActive = true
        isTouchPressed = true
        updateAimbot(true)
        updateSilentAim(true)
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isTouchPressed = true
        updateAimbot(true)
        updateSilentAim(true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isTouchPressed = false
    end
end)

-- Update ESP
local function updateESP()
    if not ESP_ENABLED then
        for _, objects in pairs(espObjects) do
            objects.box.Visible = false
            objects.name.Visible = false
            objects.dist.Visible = false
            objects.healthBarBg.Visible = false
            objects.healthBar.Visible = false
            objects.highlight.Enabled = false
            objects.highlight.Adornee = nil
        end
        return
    end
    
    for player, objects in pairs(espObjects) do
        local char = player.Character
        if char and objects.rootPart and objects.humanoid and objects.humanoid.Health > 0 then
            local rootPart = objects.rootPart
            local humanoid = objects.humanoid
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            objects.highlight.Adornee = char
            
            if onScreen then
                local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local boxSize = Vector2.new(2000 / distance, 3000 / distance)
                local boxPos = Vector2.new(screenPos.X, screenPos.Y)
                
                if BOX_ENABLED then
                    objects.box.Size = boxSize
                    objects.box.Position = boxPos - (boxSize / 2)
                    objects.box.Color = BOX_COLOR
                    objects.box.Visible = true
                else
                    objects.box.Visible = false
                end
                
                if NAME_ENABLED then
                    objects.name.Position = boxPos - Vector2.new(0, boxSize.Y / 2 + 20)
                    objects.name.Color = NAME_COLOR
                    objects.name.Visible = true
                else
                    objects.name.Visible = false
                end
                
                if DIST_ENABLED then
                    objects.dist.Text = math.floor(distance) .. "m"
                    objects.dist.Position = objects.name.Position + Vector2.new(0, 20)
                    objects.dist.Color = DIST_COLOR
                    objects.dist.Visible = true
                else
                    objects.dist.Visible = false
                end
                
                if HEALTH_ENABLED then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local healthColor = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    local healthBarHeight = boxSize.Y * HEALTH_BAR_HEIGHT_FACTOR
                    local healthBarPos = boxPos + Vector2.new(boxSize.X / 2 + HEALTH_BAR_OFFSET, -boxSize.Y / 2)
                    
                    objects.healthBarBg.Size = Vector2.new(HEALTH_BAR_WIDTH, healthBarHeight)
                    objects.healthBarBg.Position = healthBarPos
                    objects.healthBarBg.Visible = true
                    
                    objects.healthBar.Size = Vector2.new(HEALTH_BAR_WIDTH, healthBarHeight * healthPercent)
                    objects.healthBar.Position = healthBarPos + Vector2.new(0, healthBarHeight * (1 - healthPercent))
                    objects.healthBar.Color = healthColor
                    objects.healthBar.Visible = true
                else
                    objects.healthBarBg.Visible = false
                    objects.healthBar.Visible = false
                end
                
                if CHAMS_ENABLED then
                    objects.highlight.FillColor = CHAMS_FILL_COLOR
                    objects.highlight.OutlineColor = CHAMS_OUTLINE_COLOR
                    objects.highlight.FillTransparency = CHAMS_FILL_TRANSPARENCY
                    objects.highlight.OutlineTransparency = CHAMS_OUTLINE_TRANSPARENCY
                    objects.highlight.Enabled = true
                else
                    objects.highlight.Enabled = false
                end
            else
                objects.box.Visible = false
                objects.name.Visible = false
                objects.dist.Visible = false
                objects.healthBarBg.Visible = false
                objects.healthBar.Visible = false
                objects.highlight.Enabled = false
            end
        else
            objects.box.Visible = false
            objects.name.Visible = false
            objects.dist.Visible = false
            objects.healthBarBg.Visible = false
            objects.healthBar.Visible = false
            objects.highlight.Enabled = false
            objects.highlight.Adornee = nil
        end
    end
end

-- Remove ESP
local function removeESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            pcall(function()
                if obj:IsA("Highlight") then
                    obj:Destroy()
                elseif obj.Remove then
                    obj:Remove()
                end
            end)
        end
        espObjects[player] = nil
    end
end

-- Init
for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)
RunService.Heartbeat:Connect(function()
    local playerCount = #Players:GetPlayers()
    local waitTime = (playerCount > 15) and 0.1 or 0.05
    task.wait(waitTime)
    updateESP()
end)
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Radius = FOV_RADIUS
    fovCircle.Visible = FOV_ENABLED
end)

-- UI
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local ICON_URL = "https://raw.githubusercontent.com/pbol00084-star/GrokHsck-Roblox/main/Raw/NaviKobykov.jpeg" -- Замени на реальный URL
local Window = Library:CreateWindow({
    Title = "PizdabolHack",
    Footer = "by PizdabolTeam",
    Icon = ICON_URL,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("ESP Settings", "user"),
    Aimbot = Window:AddTab("Aimbot Settings", "aim"),
    Changelog = Window:AddTab("Changelog", "info"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ESP Groupbox
local ESPGroupBox = Tabs.Main:AddLeftGroupbox("ESP Controls", "boxes")

ESPGroupBox:AddToggle("ESPEnabled", {
    Text = translations[LANGUAGE].ESP,
    Default = false,
    Callback = function(Value)
        ESP_ENABLED = Value
        Library:Notify(translations[LANGUAGE].ESP .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

ESPGroupBox:AddToggle("BoxEnabled", {
    Text = translations[LANGUAGE].Boxes,
    Default = true,
    Callback = function(Value)
        BOX_ENABLED = Value
        Library:Notify(translations[LANGUAGE].Boxes .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

ESPGroupBox:AddToggle("NameEnabled", {
    Text = translations[LANGUAGE].Names,
    Default = true,
    Callback = function(Value)
        NAME_ENABLED = Value
        Library:Notify(translations[LANGUAGE].Names .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

ESPGroupBox:AddToggle("DistEnabled", {
    Text = translations[LANGUAGE].Distance,
    Default = true,
    Callback = function(Value)
        DIST_ENABLED = Value
        Library:Notify(translations[LANGUAGE].Distance .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

ESPGroupBox:AddToggle("HealthEnabled", {
    Text = translations[LANGUAGE].HealthBars,
    Default = true,
    Callback = function(Value)
        HEALTH_ENABLED = Value
        Library:Notify(translations[LANGUAGE].HealthBars .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

ESPGroupBox:AddToggle("ChamsEnabled", {
    Text = translations[LANGUAGE].Chams,
    Default = true,
    Callback = function(Value)
        CHAMS_ENABLED = Value
        Library:Notify(translations[LANGUAGE].Chams .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

ESPGroupBox:AddLabel("Box Color"):AddColorPicker("BoxColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Box Color",
    Callback = function(Value)
        BOX_COLOR = Value
        Library:Notify("Box color changed!")
    end,
})

ESPGroupBox:AddLabel("Name Color"):AddColorPicker("NameColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Name Color",
    Callback = function(Value)
        NAME_COLOR = Value
        Library:Notify("Name color changed!")
    end,
})

ESPGroupBox:AddLabel("Distance Color"):AddColorPicker("DistColor", {
    Default = Color3.fromRGB(0, 255, 0),
    Title = "Distance Color",
    Callback = function(Value)
        DIST_COLOR = Value
        Library:Notify("Distance color changed!")
    end,
})

ESPGroupBox:AddLabel("Chams Fill Color"):AddColorPicker("ChamsFillColor", {
    Default = Color3.fromRGB(0, 255, 255),
    Title = "Chams Fill Color",
    Transparency = 0.5,
    Callback = function(Value, Transparency)
        CHAMS_FILL_COLOR = Value
        CHAMS_FILL_TRANSPARENCY = Transparency or 0.5
        Library:Notify("Chams fill color changed!")
    end,
})

ESPGroupBox:AddLabel("Chams Outline Color"):AddColorPick
Default = Color3.fromRGB(255, 255, 255),
    Title = "Chams Outline Color",
    Transparency = 0,
    Callback = function(Value, Transparency)
        CHAMS_OUTLINE_COLOR = Value
        CHAMS_OUTLINE_TRANSPARENCY = Transparency or 0
        Library:Notify("Chams outline color changed!")
    end,
})

ESPGroupBox:AddSlider("HealthBarWidth", {
    Text = "Health Bar Width",
    Default = 3,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        HEALTH_BAR_WIDTH = Value
        Library:Notify("Health bar width set to: " .. Value)
    end,
})

-- Aimbot Groupbox
local AimbotGroupBox = Tabs.Aimbot:AddLeftGroupbox("Aimbot Controls", "aim")

AimbotGroupBox:AddToggle("AimbotEnabled", {
    Text = translations[LANGUAGE].Aimbot,
    Default = false,
    Callback = function(Value)
        AIMBOT_ENABLED = Value
        Library:Notify(translations[LANGUAGE].Aimbot .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

AimbotGroupBox:AddToggle("SilentAimEnabled", {
    Text = translations[LANGUAGE].SilentAim,
    Default = false,
    Callback = function(Value)
        SILENT_AIM_ENABLED = Value
        Library:Notify(translations[LANGUAGE].SilentAim .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

AimbotGroupBox:AddDropdown("AimbotPart", {
    Values = {"Head", "Torso"},
    Default = 1,
    Multi = false,
    Text = translations[LANGUAGE].TargetPart,
    Callback = function(Value)
        AIMBOT_PART = Value
        Library:Notify(translations[LANGUAGE].TargetPart .. " set to: " .. Value)
    end,
})

AimbotGroupBox:AddToggle("AimbotIgnoreWalls", {
    Text = translations[LANGUAGE].IgnoreWalls,
    Default = true,
    Callback = function(Value)
        AIMBOT_IGNORE_WALLS = Value
        Library:Notify(translations[LANGUAGE].IgnoreWalls .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

AimbotGroupBox:AddToggle("AimbotTeamCheck", {
    Text = translations[LANGUAGE].TeamCheck,
    Default = true,
    Callback = function(Value)
        AIMBOT_TEAM_CHECK = Value
        Library:Notify(translations[LANGUAGE].TeamCheck .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

AimbotGroupBox:AddSlider("AimbotSmoothness", {
    Text = translations[LANGUAGE].Smoothness,
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        AIMBOT_SMOOTHNESS = Value
        Library:Notify(translations[LANGUAGE].Smoothness .. " set to: " .. Value)
    end,
})

AimbotGroupBox:AddToggle("FovEnabled", {
    Text = translations[LANGUAGE].FovEnabled,
    Default = false,
    Callback = function(Value)
        FOV_ENABLED = Value
        Library:Notify(translations[LANGUAGE].FovEnabled .. " " .. (Value and "Enabled" or "Disabled"))
    end,
})

AimbotGroupBox:AddSlider("FovRadius", {
    Text = translations[LANGUAGE].FovRadius,
    Default = 100,
    Min = 50,
    Max = 200,
    Callback = function(Value)
        FOV_RADIUS = Value
        Library:Notify(translations[LANGUAGE].FovRadius .. " set to: " .. Value)
    end,
})

-- UI Settings Groupbox
local UISettingsGroupBox = Tabs["UI Settings"]:AddLeftGroupbox("Settings", "settings")

UISettingsGroupBox:AddDropdown("Language", {
    Values = {"EN", "RU"},
    Default = 1,
    Multi = false,
    Text = "Language",
    Callback = function(Value)
        LANGUAGE = Value
        Library:Notify("Language changed to: " .. Value)
        Window:UpdateTitle(translations[Value].Title or "PizdabolHack")
    end,
})

UISettingsGroupBox:AddLabel("UNC: " .. UNC_PERCENT .. "%")

-- Changelog Groupbox
local ChangelogGroupBox = Tabs.Changelog:AddLeftGroupbox("Changelog", "info")

ChangelogGroupBox:AddLabel("v1.3.0 - Enhancements")
ChangelogGroupBox:AddLabel("- Added Aimbot Smoothness slider.")
ChangelogGroupBox:AddLabel("- Added optional FOV with radius slider.")
ChangelogGroupBox:AddLabel("- Added swipe gesture for mobile activation.")
ChangelogGroupBox:AddLabel("- Added language switch (EN/RU).")
ChangelogGroupBox:AddLabel("- Added UNC percentage notification and display in settings.")
ChangelogGroupBox:AddLabel("v1.2.6 - UI Adjustment")
ChangelogGroupBox:AddLabel("- Changed 'Enable Centered Aimbot' to 'Centered Aimbot' in UI.")
ChangelogGroupBox:AddLabel("- Ensured no FOV aim or display (already removed).")
ChangelogGroupBox:AddLabel("v1.2.5 - Title Update")
ChangelogGroupBox:AddLabel("- Removed functional description from title for simplicity.")
ChangelogGroupBox:AddLabel("v1.2.4 - Executor Recommendations")
ChangelogGroupBox:AddLabel("- Added recommended executors: PC (Velocity, Solara, JJSploit), Mobile (Codex, Krnl, Delta).")
ChangelogGroupBox:AddLabel("- Updated UNC notice to 60-80%+.")
ChangelogGroupBox:AddLabel("v1.2.2 - Centered Aimbot")
ChangelogGroupBox:AddLabel("- Fixed ESP functions (boxes, names, etc.).")
ChangelogGroupBox:AddLabel("- Added centered aimbot (auto-targets closest player).")
ChangelogGroupBox:AddLabel("v1.2.1 - Mobile Optimization")
ChangelogGroupBox:AddLabel("- Improved mobile UI compatibility with LinoriaLib.")
ChangelogGroupBox:AddLabel("- Silent Aim with raycast smoothing.")
ChangelogGroupBox:AddLabel("v1.2 - Mobile & Silent Aim Update")
ChangelogGroupBox:AddLabel("- Added Silent Aim (invisible aiming).")
ChangelogGroupBox:AddLabel("- Mobile support (touch activation).")
ChangelogGroupBox:AddLabel("- Fixed visible aimbot bugs.")
ChangelogGroupBox:AddLabel("- Changelog section added.")
ChangelogGroupBox:AddLabel("v1.1 - Aimbot Added")
ChangelogGroupBox:AddLabel("- Aimbot with FOV, part select, etc.")
ChangelogGroupBox:AddLabel("v1.0 - Initial Release")
ChangelogGroupBox:AddLabel("- ESP, 3D Chams, UI.")

-- Save/Theme
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("PizdabolHack_Settings")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("PizdabolHack_Themes")
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- Toggle UI
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        Library:Toggle()
    end
end)

Library:Notify(string.format(translations[LANGUAGE].Notify, UNC_PERCENT))
print("PizdabolHack v1.3.0 by PizdabolTeam Loaded!")