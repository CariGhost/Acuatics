local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local ItemCollectedRemote = RemotesFolder:WaitForChild("ItemCollected")
local SystemMsgRemote = RemotesFolder:WaitForChild("SystemMessage")

--------------------------------------------------------------------------------
-- 1. CREACION DE LA INTERFAZ DE USUARIO (HUD)
--------------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SubnauticaHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- 1.1 Barra de Oxigeno
local oxygenCard = Instance.new("Frame")
oxygenCard.Name = "OxygenCard"
oxygenCard.Size = UDim2.new(0, 260, 0, 52)
oxygenCard.Position = UDim2.new(0, 30, 1, -85)
oxygenCard.BackgroundColor3 = Color3.fromRGB(15, 23, 35)
oxygenCard.BackgroundTransparency = 0.35
oxygenCard.BorderSizePixel = 0
oxygenCard.Parent = screenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 10)
cardCorner.Parent = oxygenCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(45, 120, 180)
cardStroke.Thickness = 1.5
cardStroke.Transparency = 0.4
cardStroke.Parent = oxygenCard

local o2Label = Instance.new("TextLabel")
o2Label.Name = "O2Title"
o2Label.Size = UDim2.new(0, 55, 0, 24)
o2Label.Position = UDim2.new(0, 12, 0, 6)
o2Label.BackgroundTransparency = 1
o2Label.Font = Enum.Font.GothamBold
o2Label.Text = "🫧 O₂"
o2Label.TextColor3 = Color3.fromRGB(80, 200, 255)
o2Label.TextSize = 17
o2Label.TextXAlignment = Enum.TextXAlignment.Left
o2Label.Parent = oxygenCard

local o2Value = Instance.new("TextLabel")
o2Value.Name = "O2Value"
o2Value.Size = UDim2.new(0, 120, 0, 24)
o2Value.Position = UDim2.new(1, -132, 0, 6)
o2Value.BackgroundTransparency = 1
o2Value.Font = Enum.Font.GothamMedium
o2Value.Text = "45 / 45s"
o2Value.TextColor3 = Color3.fromRGB(220, 240, 255)
o2Value.TextSize = 14
o2Value.TextXAlignment = Enum.TextXAlignment.Right
o2Value.Parent = oxygenCard

local barBackground = Instance.new("Frame")
barBackground.Name = "BarBackground"
barBackground.Size = UDim2.new(1, -24, 0, 10)
barBackground.Position = UDim2.new(0, 12, 0, 32)
barBackground.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
barBackground.BorderSizePixel = 0
barBackground.Parent = oxygenCard

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(0, 5)
barBgCorner.Parent = barBackground

local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 190, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBackground

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(0, 5)
barFillCorner.Parent = barFill

-- 1.2 Panel de Inventario Dinamico (Solo items poseidos > 0)
local invCard = Instance.new("Frame")
invCard.Name = "InventoryCard"
invCard.Size = UDim2.new(0, 220, 0, 0)
invCard.Position = UDim2.new(1, -240, 0, 25)
invCard.BackgroundColor3 = Color3.fromRGB(15, 23, 35)
invCard.BackgroundTransparency = 0.35
invCard.BorderSizePixel = 0
invCard.Visible = false
invCard.AutomaticSize = Enum.AutomaticSize.Y
invCard.Parent = screenGui

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 10)
invCorner.Parent = invCard

local invStroke = Instance.new("UIStroke")
invStroke.Color = Color3.fromRGB(50, 80, 110)
invStroke.Thickness = 1
invStroke.Transparency = 0.5
invStroke.Parent = invCard

local invTitle = Instance.new("TextLabel")
invTitle.Name = "Title"
invTitle.Size = UDim2.new(1, -20, 0, 24)
invTitle.Position = UDim2.new(0, 10, 0, 6)
invTitle.BackgroundTransparency = 1
invTitle.Font = Enum.Font.GothamBold
invTitle.Text = "🎒 INVENTARIO"
invTitle.TextColor3 = Color3.fromRGB(160, 210, 240)
invTitle.TextSize = 12
invTitle.TextXAlignment = Enum.TextXAlignment.Left
invTitle.Parent = invCard

local listContainer = Instance.new("Frame")
listContainer.Name = "List"
listContainer.Size = UDim2.new(1, -16, 0, 0)
listContainer.Position = UDim2.new(0, 8, 0, 32)
listContainer.BackgroundTransparency = 1
listContainer.AutomaticSize = Enum.AutomaticSize.Y
listContainer.Parent = invCard

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listContainer

local paddingBottom = Instance.new("UIPadding")
paddingBottom.PaddingBottom = UDim.new(0, 8)
paddingBottom.Parent = invCard

local itemRows = {}

-- 1.3 Notificaciones y Mensajes de Sistema
local notifyContainer = Instance.new("Frame")
notifyContainer.Name = "NotifyContainer"
notifyContainer.Size = UDim2.new(0, 280, 0, 180)
notifyContainer.Position = UDim2.new(0.5, -140, 0.65, 0)
notifyContainer.BackgroundTransparency = 1
notifyContainer.Parent = screenGui

local function showToast(text, textColor, bgColor)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(1, 0, 0, 34)
	toast.Position = UDim2.new(0, 0, 1, 0)
	toast.BackgroundTransparency = 0.35
	toast.BackgroundColor3 = bgColor or Color3.fromRGB(10, 30, 45)
	toast.Font = Enum.Font.GothamBold
	toast.Text = text
	toast.TextColor3 = textColor or Color3.fromRGB(90, 255, 190)
	toast.TextSize = 13
	toast.Parent = notifyContainer

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 6)
	toastCorner.Parent = toast

	local tweenInfo = TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(toast, tweenInfo, {
		Position = UDim2.new(0, 0, 0, -25),
		TextTransparency = 1,
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		toast:Destroy()
	end)
end

ItemCollectedRemote.OnClientEvent:Connect(function(mineralKey, itemName, amount, icon)
	showToast(string.format("%s +%d %s", icon or "📦", amount, itemName), Color3.fromRGB(90, 255, 190))
end)

SystemMsgRemote.OnClientEvent:Connect(function(message, color)
	showToast(message, color or Color3.fromRGB(255, 230, 100), Color3.fromRGB(20, 25, 35))
end)

--------------------------------------------------------------------------------
-- 2. LOGICA REACTIVA DE INVENTARIO Y OXIGENO
--------------------------------------------------------------------------------

local function updateInventory()
	local totalHeld = 0

	for mineralKey, data in pairs(Config.MINERALS) do
		local count = player:GetAttribute(mineralKey) or 0

		if count > 0 then
			totalHeld = totalHeld + count

			if not itemRows[mineralKey] then
				local row = Instance.new("Frame")
				row.Name = mineralKey .. "Row"
				row.Size = UDim2.new(1, 0, 0, 24)
				row.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
				row.BackgroundTransparency = 0.4
				row.BorderSizePixel = 0
				row.Parent = listContainer

				local rowCorner = Instance.new("UICorner")
				rowCorner.CornerRadius = UDim.new(0, 5)
				rowCorner.Parent = row

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "NameLabel"
				nameLabel.Size = UDim2.new(0.68, 0, 1, 0)
				nameLabel.Position = UDim2.new(0, 8, 0, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.Gotham
				nameLabel.Text = string.format("%s %s", data.Icon or "•", data.Name)
				nameLabel.TextColor3 = data.Color or Color3.fromRGB(220, 230, 240)
				nameLabel.TextSize = 12
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Parent = row

				local countLabel = Instance.new("TextLabel")
				countLabel.Name = "CountLabel"
				countLabel.Size = UDim2.new(0.3, -8, 1, 0)
				countLabel.Position = UDim2.new(0.7, 0, 0, 0)
				countLabel.BackgroundTransparency = 1
				countLabel.Font = Enum.Font.GothamBold
				countLabel.Text = string.format("x%d", count)
				countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				countLabel.TextSize = 12
				countLabel.TextXAlignment = Enum.TextXAlignment.Right
				countLabel.Parent = row

				itemRows[mineralKey] = { row = row, countLabel = countLabel }
			else
				itemRows[mineralKey].countLabel.Text = string.format("x%d", count)
			end
		else
			if itemRows[mineralKey] then
				itemRows[mineralKey].row:Destroy()
				itemRows[mineralKey] = nil
			end
		end
	end

	invCard.Visible = (totalHeld > 0)
end

for mineralKey in pairs(Config.MINERALS) do
	player:GetAttributeChangedSignal(mineralKey):Connect(updateInventory)
end
updateInventory()

-- Bucle de renderizado para barra de oxigeno
local flashTimer = 0
RunService.RenderStepped:Connect(function(dt)
	local ox = player:GetAttribute("Oxygen") or Config.DEFAULT_MAX_OXYGEN
	local maxOx = player:GetAttribute("MaxOxygen") or Config.DEFAULT_MAX_OXYGEN
	local ratio = math.clamp(ox / maxOx, 0, 1)

	o2Value.Text = string.format("%d / %ds", math.ceil(ox), math.ceil(maxOx))
	barFill.Size = UDim2.new(ratio, 0, 1, 0)

	if ox <= 10 then
		flashTimer = flashTimer + (dt * 6)
		local flash = math.abs(math.sin(flashTimer))
		barFill.BackgroundColor3 = Color3.fromRGB(255, 40 + math.floor(flash * 80), 40)
		cardStroke.Color = Color3.fromRGB(255, 50, 50)
	elseif ox <= 20 then
		barFill.BackgroundColor3 = Color3.fromRGB(255, 180, 40)
		cardStroke.Color = Color3.fromRGB(240, 170, 30)
	else
		barFill.BackgroundColor3 = Color3.fromRGB(0, 190, 255)
		cardStroke.Color = Color3.fromRGB(45, 120, 180)
	end
end)

--------------------------------------------------------------------------------
-- 3. ATMOSFERA SUBMARINA TROPICAL (STAGE 1)
--------------------------------------------------------------------------------

local underwaterEffect = Instance.new("ColorCorrectionEffect")
underwaterEffect.Name = "UnderwaterColorCorrection"
underwaterEffect.Enabled = false
underwaterEffect.TintColor = Color3.fromRGB(175, 230, 255)
underwaterEffect.Brightness = -0.02
underwaterEffect.Contrast = 0.08
underwaterEffect.Parent = Lighting

local camera = Workspace.CurrentCamera
Lighting.FogStart = 0
Lighting.FogEnd = 240
Lighting.FogColor = Color3.fromRGB(25, 90, 140)

RunService.RenderStepped:Connect(function()
	if camera then
		local isUnder = camera.CFrame.Position.Y < Config.WATER_LEVEL
		underwaterEffect.Enabled = isUnder
	end
end)

print("[SubnauticaStages] Cliente de Mapa 1 listo.")
