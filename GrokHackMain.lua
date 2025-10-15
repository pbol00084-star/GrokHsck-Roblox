--[[
	WARNING: For educational purposes only! Use at your own risk!
	ESP with Chams using LinoriaLib (Obsidian fork by deividcomsono)
	made by PizadabolTeam
]]

-- Load LinoriaLib and Addons
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Load Drawing API (fallback for Solara/Nezur/Krnl compatibility)
if not Drawing then
	local drawingLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/UI/Drawing.lua"))() or getgenv().Drawing
	getgenv().Drawing = drawingLib
end
local Drawing = getgenv().Drawing

-- Roblox Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Settings (configurable via UI)
local ESP_ENABLED = false
local BOX_ENABLED = true
local NAME_ENABLED = true
local DIST_ENABLED = true
local HEALTH_ENABLED = true
local CHAMS_ENABLED = true
local BOX_COLOR = Color3.fromRGB(255, 0, 0)
local NAME_COLOR = Color3.fromRGB(255, 255, 255)
local DIST_COLOR = Color3.fromRGB(0, 255, 0)
local CHAMS_COLOR = Color3.fromRGB(0, 255, 255) -- Cyan for chams
local CHAMS_TRANSPARENCY = 0.5 -- Semi-transparent chams
local HEALTH_BAR_WIDTH = 3
local HEALTH_BAR_HEIGHT_FACTOR = 1
local HEALTH_BAR_OFFSET = 6

-- ESP Table
local espObjects = {}

-- Create ESP for Player
local function createESP(player)
	if player == LocalPlayer then return end
	
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
	
	-- Chams (using Drawing API quads for each part)
	local chamsQuads = {}
	
	espObjects[player] = {
		box = box,
		name = nameLabel,
		dist = distLabel,
		healthBarBg = healthBarBg,
		healthBar = healthBar,
		chamsQuads = chamsQuads
	}
end

-- Update ESP and Chams
local function updateESP()
	if not ESP_ENABLED then
		for _, objects in pairs(espObjects) do
			objects.box.Visible = false
			objects.name.Visible = false
			objects.dist.Visible = false
			objects.healthBarBg.Visible = false
			objects.healthBar.Visible = false
			for _, quad in pairs(objects.chamsQuads) do
				quad.Visible = false
			end
		end
		return
	end
	
	for player, objects in pairs(espObjects) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			local rootPart = char.HumanoidRootPart
			local humanoid = char.Humanoid
			local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
			
			if onScreen then
				local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
				local boxSize = Vector2.new(2000 / distance, 3000 / distance)
				local boxPos = Vector2.new(screenPos.X, screenPos.Y)
				
				-- Box
				if BOX_ENABLED then
					objects.box.Size = boxSize
					objects.box.Position = boxPos - (boxSize / 2)
					objects.box.Color = BOX_COLOR
					objects.box.Visible = true
				else
					objects.box.Visible = false
				end
				
				-- Name
				if NAME_ENABLED then
					objects.name.Position = boxPos - Vector2.new(0, boxSize.Y / 2 + 20)
					objects.name.Color = NAME_COLOR
					objects.name.Visible = true
				else
					objects.name.Visible = false
				end
				
				-- Distance
				if DIST_ENABLED then
					objects.dist.Text = math.floor(distance) .. "m"
					objects.dist.Position = objects.name.Position + Vector2.new(0, 20)
					objects.dist.Color = DIST_COLOR
					objects.dist.Visible = true
				else
					objects.dist.Visible = false
				end
				
				-- Health Bar
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
				
				-- Chams
				if CHAMS_ENABLED then
					-- Clear old quads
					for _, quad in pairs(objects.chamsQuads) do
						quad:Remove()
					end
					objects.chamsQuads = {}
					
					-- Draw quads for each part
					for _, part in pairs(char:GetChildren()) do
						if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
							local success, corners = pcall(function()
								local cf = part.CFrame
								local size = part.Size
								local vertices = {
									cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
									cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
									cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
									cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2)
								}
								local screenCorners = {}
								for i, vertex in ipairs(vertices) do
									local screenPos, onScreen = Camera:WorldToViewportPoint(vertex)
									if onScreen then
										screenCorners[i] = Vector2.new(screenPos.X, screenPos.Y)
									else
										return nil
									end
								end
								return screenCorners
							end)
							
							if success and corners then
								local quad = Drawing.new("Quad")
								quad.Visible = true
								quad.Color = CHAMS_COLOR
								quad.Transparency = CHAMS_TRANSPARENCY
								quad.Filled = true
								quad.Thickness = 1
								quad.PointA = corners[1]
								quad.PointB = corners[2]
								quad.PointC = corners[3]
								quad.PointD = corners[4]
								table.insert(objects.chamsQuads, quad)
							end
						end
					end
				else
					for _, quad in pairs(objects.chamsQuads) do
						quad.Visible = false
					end
				end
			else
				objects.box.Visible = false
				objects.name.Visible = false
				objects.dist.Visible = false
				objects.healthBarBg.Visible = false
				objects.healthBar.Visible = false
				for _, quad in pairs(objects.chamsQuads) do
					quad.Visible = false
				end
			end
		else
			objects.box.Visible = false
			objects.name.Visible = false
			objects.dist.Visible = false
			objects.healthBarBg.Visible = false
			objects.healthBar.Visible = false
			for _, quad in pairs(objects.chamsQuads) do
				quad.Visible = false
			end
		end
	end
end

-- Remove ESP
local function removeESP(player)
	if espObjects[player] then
		for _, obj in pairs(espObjects[player]) do
			if type(obj) == "table" then
				for _, quad in pairs(obj) do
					quad:Remove()
				end
			else
				obj:Remove()
			end
		end
		espObjects[player] = nil
	end
end

-- Initialize ESP for Players
for _, player in pairs(Players:GetPlayers()) do
	createESP(player)
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)
RunService.Heartbeat:Connect(updateESP)

-- UI Setup (LinoriaLib)
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "ESP + Chams by Grok (Obsidian)",
	Footer = "version: 1.1",
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("ESP Settings", "user"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ESP Groupbox
local ESPGroupBox = Tabs.Main:AddLeftGroupbox("ESP Controls", "boxes")

-- Toggles for ESP Features
ESPGroupBox:AddToggle("ESPEnabled", {
	Text = "Enable ESP",
	Default = false,
	Tooltip = "Toggle ESP on/off",
	Callback = function(Value)
		ESP_ENABLED = Value
		Library:Notify("ESP " .. (Value and "Enabled" or "Disabled"))
	end,
})

ESPGroupBox:AddToggle("BoxEnabled", {
	Text = "Show Boxes",
	Default = true,
	Tooltip = "Toggle ESP boxes",
	Callback = function(Value)
		BOX_ENABLED = Value
		Library:Notify("Boxes " .. (Value and "Enabled" or "Disabled"))
	end,
})

ESPGroupBox:AddToggle("NameEnabled", {
	Text = "Show Names",
	Default = true,
	Tooltip = "Toggle player names",
	Callback = function(Value)
		NAME_ENABLED = Value
		Library:Notify("Names " .. (Value and "Enabled" or "Disabled"))
	end,
})

ESPGroupBox:AddToggle("DistEnabled", {
	Text = "Show Distance",
	Default = true,
	Tooltip = "Toggle distance display",
	Callback = function(Value)
		DIST_ENABLED = Value
		Library:Notify("Distance " .. (Value and "Enabled" or "Disabled"))
	end,
})

ESPGroupBox:AddToggle("HealthEnabled", {
	Text = "Show Health Bars",
	Default = true,
	Tooltip = "Toggle health bars",
	Callback = function(Value)
		HEALTH_ENABLED = Value
		Library:Notify("Health Bars " .. (Value and "Enabled" or "Disabled"))
	end,
})

ESPGroupBox:AddToggle("ChamsEnabled", {
	Text = "Show Chams",
	Default = true,
	Tooltip = "Toggle chams (highlight through walls)",
	Callback = function(Value)
		CHAMS_ENABLED = Value
		Library:Notify("Chams " .. (Value and "Enabled" or "Disabled"))
	end,
})

-- Color Pickers for Customization
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

ESPGroupBox:AddLabel("Chams Color"):AddColorPicker("ChamsColor", {
	Default = Color3.fromRGB(0, 255, 255),
	Title = "Chams Color",
	Transparency = 0.5,
	Callback = function(Value, Transparency)
		CHAMS_COLOR = Value
		CHAMS_TRANSPARENCY = Transparency or 0.5
		Library:Notify("Chams color changed!")
	end,
})

-- Slider for Health Bar Width
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

-- SaveManager Integration
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("ESP_Settings")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-- ThemeManager Integration
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("ESP_Themes")
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- Keybind to Toggle UI
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Insert then
		Library:Toggle()
	end
end)

Library:Notify("ESP + Chams Script Loaded! Press INSERT to toggle UI.")
print("Оно работает" + "мама вызывай такси!")