local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Remotes
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Remotes"
	RemotesFolder.Parent = ReplicatedStorage
end

local ItemCollectedRemote = RemotesFolder:FindFirstChild("ItemCollected")
if not ItemCollectedRemote then
	ItemCollectedRemote = Instance.new("RemoteEvent")
	ItemCollectedRemote.Name = "ItemCollected"
	ItemCollectedRemote.Parent = RemotesFolder
end

local SystemMsgRemote = RemotesFolder:FindFirstChild("SystemMessage")
if not SystemMsgRemote then
	SystemMsgRemote = Instance.new("RemoteEvent")
	SystemMsgRemote.Name = "SystemMessage"
	SystemMsgRemote.Parent = RemotesFolder
end

--------------------------------------------------------------------------------
-- 1. SANEAMIENTO Y LIMPIEZA DE WORKSPACE
--------------------------------------------------------------------------------

local function sanitizeWorkspace()
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("BasePart") and (obj.Name == "Baseplate" or obj:IsA("SpawnLocation")) then
			obj:Destroy()
		end
	end
end

--------------------------------------------------------------------------------
-- 2. ILUMINACION Y AGUA SUBMARINA
--------------------------------------------------------------------------------

local function setupLightingAndWater()
	local terrain = Workspace.Terrain
	pcall(function()
		terrain.WaterColor = Color3.fromRGB(18, 128, 175)
		terrain.WaterTransparency = 0.85
		terrain.WaterReflectance = 0.08
		terrain.WaterWaveSize = 0.15
		terrain.WaterWaveSpeed = 10
	end)

	Lighting.ClockTime = 14
	Lighting.Brightness = 2.4
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 120, 160)
	Lighting.Ambient = Color3.fromRGB(35, 65, 95)
	Lighting.GeographicLatitude = 20

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if not sunRays then
		sunRays = Instance.new("SunRaysEffect")
		sunRays.Parent = Lighting
	end
	sunRays.Intensity = 0.35
	sunRays.Spread = 0.85

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.5
	bloom.Size = 22
	bloom.Threshold = 1.1

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(150, 215, 255)
	atmosphere.Decay = Color3.fromRGB(40, 120, 180)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.0
end

--------------------------------------------------------------------------------
-- 3. GESTION DEL SUBMARINO 3D
--------------------------------------------------------------------------------

local function bindSubmarineInteraction(subModel)
	if subModel:FindFirstChild("Stage2Bound") then return end
	local boundTag = Instance.new("BoolValue")
	boundTag.Name = "Stage2Bound"
	boundTag.Parent = subModel

	for _, desc in ipairs(subModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
		end
	end

	local mainPart = subModel.PrimaryPart
	if not mainPart then
		for _, desc in ipairs(subModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				mainPart = desc
				break
			end
		end
		if mainPart then
			subModel.PrimaryPart = mainPart
		end
	end
	if not mainPart then return end

	-- Si esta fuera del area de juego, reubicarlo en la fosa
	if (mainPart.Position - Vector3.new(0, 0, 0)).Magnitude > 180 or mainPart.Position.Y > Config.WATER_LEVEL then
		subModel:PivotTo(CFrame.new(45, -26, 45) * CFrame.Angles(0, math.rad(-45), 0))
	end

	local beacon = mainPart:FindFirstChild("StatusBeacon")
	if not beacon then
		beacon = Instance.new("PointLight")
		beacon.Name = "StatusBeacon"
		beacon.Color = Color3.fromRGB(255, 160, 30)
		beacon.Brightness = 2.5
		beacon.Range = 25
		beacon.Parent = mainPart
	end

	local prompt = mainPart:FindFirstChild("TransitionPrompt") or subModel:FindFirstChild("TransitionPrompt", true)
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TransitionPrompt"
		prompt.ObjectText = "Submarino Seamoth (Stage 2)"
		prompt.ActionText = "Reparar (5 Titanio, 3 Cobre, 2 Cuarzo)"
		prompt.HoldDuration = 1.5
		prompt.MaxActivationDistance = 20
		prompt.RequiresLineOfSight = false
		prompt.Parent = mainPart
	end

	prompt.Triggered:Connect(function(player)
		local isUnlocked = player:GetAttribute("Stage2Unlocked") or false
		if isUnlocked then
			SystemMsgRemote:FireClient(player, "Iniciando descenso hacia Stage 2...", Color3.fromRGB(80, 255, 180))
			if Config.STAGE2_PLACE_ID > 0 then
				pcall(function()
					TeleportService:Teleport(Config.STAGE2_PLACE_ID, player)
				end)
			else
				SystemMsgRemote:FireClient(player, "[Mapa 2] Submarino listo para vincular Place ID.", Color3.fromRGB(255, 220, 80))
			end
			return
		end

		local hasTitanium = (player:GetAttribute("Titanium") or 0) >= Config.STAGE2_GATE_REQUIREMENTS.Titanium
		local hasCopper = (player:GetAttribute("Copper") or 0) >= Config.STAGE2_GATE_REQUIREMENTS.Copper
		local hasQuartz = (player:GetAttribute("Quartz") or 0) >= Config.STAGE2_GATE_REQUIREMENTS.Quartz

		if hasTitanium and hasCopper and hasQuartz then
			player:SetAttribute("Titanium", player:GetAttribute("Titanium") - Config.STAGE2_GATE_REQUIREMENTS.Titanium)
			player:SetAttribute("Copper", player:GetAttribute("Copper") - Config.STAGE2_GATE_REQUIREMENTS.Copper)
			player:SetAttribute("Quartz", player:GetAttribute("Quartz") - Config.STAGE2_GATE_REQUIREMENTS.Quartz)

			player:SetAttribute("Stage2Unlocked", true)
			prompt.ActionText = "Abordar hacia Stage 2"
			prompt.HoldDuration = 0.5
			beacon.Color = Color3.fromRGB(80, 255, 120)
			SystemMsgRemote:FireClient(player, "¡Submarino reparado! Listo para descender.", Color3.fromRGB(100, 255, 150))
		else
			SystemMsgRemote:FireClient(player, "Faltan recursos: 5 Titanio, 3 Cobre, 2 Cuarzo.", Color3.fromRGB(255, 100, 100))
		end
	end)
end

local function locateAndBindSubmarine()
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child.Name ~= "Stage1_Map" then
			local lowerName = string.lower(child.Name)
			if string.find(lowerName, "sub") or string.find(lowerName, "seamoth") or string.find(lowerName, "gate") then
				bindSubmarineInteraction(child)
				return child
			end
		end
	end
	return nil
end

Workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child.Name ~= "Stage1_Map" then
		local lowerName = string.lower(child.Name)
		if string.find(lowerName, "sub") or string.find(lowerName, "seamoth") or string.find(lowerName, "gate") then
			task.wait(0.3)
			bindSubmarineInteraction(child)
		end
	end
end)

--------------------------------------------------------------------------------
-- 4. CONSTRUCCION DEL MAPA (GRAN LIFEPOD 05 SEGURO + AGUA + BIOMAS)
--------------------------------------------------------------------------------

local function buildEnvironment()
	sanitizeWorkspace()
	setupLightingAndWater()

	local mapFolder = Workspace:FindFirstChild("Stage1_Map")
	if mapFolder then mapFolder:Destroy() end

	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Stage1_Map"
	mapFolder.Parent = Workspace

	local bounds = Config.MAP_BOUNDS
	local totalWidth = bounds.MaxX - bounds.MinX + 40
	local totalDepth = Config.WATER_LEVEL - (-65)
	local waterCenterY = (Config.WATER_LEVEL + (-65)) / 2

	-- 4.1 CONSTRUCCION DEL GRAN LIFEPOD 05 (AMPLIO, SEGURO CON BARANDILLAS)
	local lifepod = Instance.new("Model")
	lifepod.Name = "Lifepod_05"
	lifepod.Parent = mapFolder

	-- Gran cubierta central de 40x40 studs
	local deck = Instance.new("Part")
	deck.Name = "Deck"
	deck.Size = Vector3.new(40, 3, 40)
	deck.Position = Vector3.new(0, Config.WATER_LEVEL + 1.5, 0)
	deck.Anchored = true
	deck.CanCollide = true
	deck.Material = Enum.Material.DiamondPlate
	deck.Color = Color3.fromRGB(225, 230, 235)
	deck.Parent = lifepod

	-- Flotadores perimetrales naranjas
	for _, off in ipairs({ { -21, 0, 4, 42 }, { 21, 0, 4, 42 }, { 0, -21, 42, 4 } }) do
		local pontoon = Instance.new("Part")
		pontoon.Name = "Pontoon"
		pontoon.Size = Vector3.new(off[3], 4, off[4])
		pontoon.Position = Vector3.new(off[1], Config.WATER_LEVEL + 1.2, off[2])
		pontoon.Anchored = true
		pontoon.CanCollide = true
		pontoon.Material = Enum.Material.SmoothPlastic
		pontoon.Color = Color3.fromRGB(245, 130, 30)
		pontoon.Parent = lifepod
	end

	-- Barandillas / Muros de seguridad altos (5 studs) en 3 lados para no caerse
	local function createSafetyWall(pos, size)
		local wall = Instance.new("Part")
		wall.Name = "SafetyWall"
		wall.Size = size
		wall.Position = pos
		wall.Anchored = true
		wall.CanCollide = true
		wall.Material = Enum.Material.Metal
		wall.Color = Color3.fromRGB(180, 190, 200)
		wall.Transparency = 0.3
		wall.Parent = lifepod
	end
	createSafetyWall(Vector3.new(-20, Config.WATER_LEVEL + 5.5, 0), Vector3.new(1.5, 5, 40))
	createSafetyWall(Vector3.new(20, Config.WATER_LEVEL + 5.5, 0), Vector3.new(1.5, 5, 40))
	createSafetyWall(Vector3.new(0, Config.WATER_LEVEL + 5.5, -20), Vector3.new(40, 5, 1.5))

	-- Cabina del Lifepod techada
	local cabin = Instance.new("Part")
	cabin.Name = "Cabin"
	cabin.Size = Vector3.new(18, 7, 16)
	cabin.Position = Vector3.new(0, Config.WATER_LEVEL + 6.5, -9)
	cabin.Anchored = true
	cabin.CanCollide = true
	cabin.Material = Enum.Material.SmoothPlastic
	cabin.Color = Color3.fromRGB(240, 245, 250)
	cabin.Parent = lifepod

	-- SpawnLocation amplio y seguro en el centro de la cubierta
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "PlayerSpawn"
	spawnLoc.Size = Vector3.new(24, 1, 24)
	spawnLoc.Position = deck.Position + Vector3.new(0, 1.5, 5)
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.CanCollide = true
	spawnLoc.Transparency = 1
	spawnLoc.Parent = lifepod

	-- Rampa / Muelle amplio para tirarse al agua (en el lado abierto Z+)
	local ramp = Instance.new("WedgePart")
	ramp.Name = "DiveRamp"
	ramp.Size = Vector3.new(14, 8, 18)
	ramp.CFrame = CFrame.new(0, Config.WATER_LEVEL - 1.5, 26) * CFrame.Angles(0, math.rad(180), 0)
	ramp.Anchored = true
	ramp.CanCollide = true
	ramp.Material = Enum.Material.DiamondPlate
	ramp.Color = Color3.fromRGB(245, 140, 40)
	ramp.Parent = lifepod

	-- Foco baliza
	local podLight = Instance.new("PointLight")
	podLight.Color = Color3.fromRGB(120, 220, 255)
	podLight.Brightness = 3.0
	podLight.Range = 40
	podLight.Parent = deck

	-- 4.2 GENERACION DE AGUA Y FONDO MARINO NATIVO
	Workspace.Terrain:FillBlock(CFrame.new(0, waterCenterY, 0), Vector3.new(totalWidth + 20, totalDepth, totalWidth + 20), Enum.Material.Water)
	Workspace.Terrain:FillBlock(CFrame.new(0, -42, 0), Vector3.new(totalWidth + 20, 16, totalWidth + 20), Enum.Material.Sand)

	local rng = Random.new(2026)
	for _ = 1, 50 do
		local bx = rng:NextNumber(bounds.MinX + 15, bounds.MaxX - 15)
		local bz = rng:NextNumber(bounds.MinZ + 15, bounds.MaxZ - 15)
		local bRadius = rng:NextNumber(14, 26)
		local bY = -34 + rng:NextNumber(-4, 12)
		local mat = (rng:NextInteger(1, 3) == 1) and Enum.Material.Sandstone or Enum.Material.Sand

		Workspace.Terrain:FillBall(Vector3.new(bx, bY, bz), bRadius, mat)
	end

	-- Muros de contención
	local wallThickness = 14
	local wallHeight = totalDepth + 10
	Workspace.Terrain:FillBlock(CFrame.new(bounds.MinX - 5, waterCenterY, 0), Vector3.new(wallThickness, wallHeight, totalWidth + 20), Enum.Material.Rock)
	Workspace.Terrain:FillBlock(CFrame.new(bounds.MaxX + 5, waterCenterY, 0), Vector3.new(wallThickness, wallHeight, totalWidth + 20), Enum.Material.Rock)
	Workspace.Terrain:FillBlock(CFrame.new(0, waterCenterY, bounds.MinZ - 5), Vector3.new(totalWidth + 20, wallHeight, wallThickness), Enum.Material.Rock)
	Workspace.Terrain:FillBlock(CFrame.new(0, waterCenterY, bounds.MaxZ + 5), Vector3.new(totalWidth + 20, wallHeight, wallThickness), Enum.Material.Rock)

	-- 4.3 FLORA Y ARRECIFES 3D
	local floraFolder = Instance.new("Folder")
	floraFolder.Name = "FloraAndReefs"
	floraFolder.Parent = mapFolder

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { Workspace.Terrain }
	raycastParams.IgnoreWater = true

	-- Creepvines con racimos de luz
	local function createVine(rootPos, vHeight)
		local vine = Instance.new("Model")
		vine.Name = "Creepvine"
		vine.Parent = floraFolder

		local segs = math.floor(vHeight / 4)
		local cur = rootPos
		local ang = rng:NextNumber(0, math.pi * 2)

		for s = 1, segs do
			local nxt = cur + Vector3.new(math.sin(ang + s) * 0.8, 4.2, math.cos(ang + s) * 0.8)
			local stem = Instance.new("Part")
			stem.Size = Vector3.new(1.1, 4.4, 1.1)
			stem.CFrame = CFrame.new((cur + nxt) / 2, nxt) * CFrame.Angles(math.rad(90), 0, 0)
			stem.Anchored = true
			stem.CanCollide = false
			stem.Material = Enum.Material.SmoothPlastic
			stem.Color = Color3.fromRGB(45, 125, 45)
			stem.Parent = vine

			local leaf = Instance.new("Part")
			leaf.Size = Vector3.new(3.2, 0.4, 1.4)
			leaf.Position = stem.Position
			leaf.Orientation = Vector3.new(rng:NextNumber(-20, 20), rng:NextNumber(0, 360), rng:NextNumber(-20, 20))
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.Material = Enum.Material.SmoothPlastic
			leaf.Color = Color3.fromRGB(65, 160, 55)
			leaf.Parent = vine

			if s == math.floor(segs * 0.7) then
				local seed = Instance.new("Part")
				seed.Shape = Enum.PartType.Ball
				seed.Size = Vector3.new(2.2, 2.2, 2.2)
				seed.Position = stem.Position + Vector3.new(0.8, 0, 0)
				seed.Anchored = true
				seed.CanCollide = false
				seed.Material = Enum.Material.Neon
				seed.Color = Color3.fromRGB(255, 195, 40)
				seed.Parent = vine

				local sl = Instance.new("PointLight")
				sl.Color = Color3.fromRGB(255, 200, 50)
				sl.Brightness = 2.0
				sl.Range = 16
				sl.Parent = seed
			end
			cur = nxt
		end
	end

	for _ = 1, 28 do
		local vx = rng:NextNumber(bounds.MinX + 20, bounds.MaxX - 20)
		local vz = rng:NextNumber(bounds.MinZ + 20, bounds.MaxZ - 20)
		local ray = Workspace:Raycast(Vector3.new(vx, Config.WATER_LEVEL + 5, vz), Vector3.new(0, -80, 0), raycastParams)
		if ray and ray.Position.Y < -14 then
			createVine(ray.Position, math.clamp(Config.WATER_LEVEL - ray.Position.Y - 5, 12, 26))
		end
	end

	-- Hongos Ácidos
	for _ = 1, 18 do
		local mx = rng:NextNumber(bounds.MinX + 15, bounds.MaxX - 15)
		local mz = rng:NextNumber(bounds.MinZ + 15, bounds.MaxZ - 15)
		local ray = Workspace:Raycast(Vector3.new(mx, Config.WATER_LEVEL + 5, mz), Vector3.new(0, -80, 0), raycastParams)
		if ray then
			local shrooms = Instance.new("Model")
			shrooms.Name = "AcidMushrooms"
			shrooms.Parent = floraFolder

			for i = 1, rng:NextInteger(3, 6) do
				local spos = ray.Position + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
				local stem = Instance.new("Part")
				stem.Size = Vector3.new(0.6, 1.2, 0.6)
				stem.Position = spos + Vector3.new(0, 0.6, 0)
				stem.Anchored = true
				stem.CanCollide = false
				stem.Material = Enum.Material.SmoothPlastic
				stem.Color = Color3.fromRGB(180, 190, 200)
				stem.Parent = shrooms

				local cap = Instance.new("Part")
				cap.Shape = Enum.PartType.Ball
				cap.Size = Vector3.new(1.8, 0.9, 1.8)
				cap.Position = spos + Vector3.new(0, 1.3, 0)
				cap.Anchored = true
				cap.CanCollide = false
				cap.Material = Enum.Material.Neon
				cap.Color = Color3.fromRGB(190, 60, 215)
				cap.Parent = shrooms

				if i == 1 then
					local light = Instance.new("PointLight")
					light.Color = Color3.fromRGB(210, 80, 240)
					light.Brightness = 1.4
					light.Range = 10
					light.Parent = cap
				end
			end
		end
	end

	-- Table Corals
	for _ = 1, 24 do
		local cx = rng:NextNumber(bounds.MinX + 15, bounds.MaxX - 15)
		local cz = rng:NextNumber(bounds.MinZ + 15, bounds.MaxZ - 15)
		local ray = Workspace:Raycast(Vector3.new(cx, Config.WATER_LEVEL + 5, cz), Vector3.new(0, -80, 0), raycastParams)
		if ray then
			local shelf = Instance.new("Part")
			shelf.Name = "TableCoral"
			shelf.Shape = Enum.PartType.Cylinder
			shelf.Size = Vector3.new(0.5, rng:NextNumber(3, 5), rng:NextNumber(3, 5))
			shelf.CFrame = CFrame.new(ray.Position + (ray.Normal * 1.0), ray.Position + (ray.Normal * 2.0)) * CFrame.Angles(0, 0, math.rad(90))
			shelf.Anchored = true
			shelf.CanCollide = false
			shelf.Material = Enum.Material.Neon
			shelf.Color = (rng:NextInteger(1, 2) == 1) and Color3.fromRGB(240, 90, 70) or Color3.fromRGB(70, 210, 230)
			shelf.Parent = floraFolder
		end
	end

	-- Vincular Submarino
	locateAndBindSubmarine()
end

--------------------------------------------------------------------------------
-- 5. GENERACION DE MINERALES
--------------------------------------------------------------------------------

local function createMineralModel(mineralKey, data, position, rng)
	local model = Instance.new("Model")
	model.Name = mineralKey .. "_Node"

	local baseRock = Instance.new("Part")
	baseRock.Name = "BaseRock"
	baseRock.Size = Vector3.new(2.4, 1.2, 2.4)
	baseRock.Position = position
	baseRock.Orientation = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(0, 360), rng:NextNumber(-8, 8))
	baseRock.Anchored = true
	baseRock.CanCollide = true
	baseRock.Material = Enum.Material.Basalt
	baseRock.Color = Color3.fromRGB(40, 45, 50)
	baseRock.Parent = model
	model.PrimaryPart = baseRock

	if data.Shape == "Crystal" then
		for c = 1, 3 do
			local crystal = Instance.new("Part")
			crystal.Name = "CrystalSpike"
			crystal.Size = Vector3.new(0.65, 2.2 + rng:NextNumber(0, 0.6), 0.65)
			crystal.Material = data.Material
			crystal.Color = data.Color
			crystal.Anchored = true
			crystal.CanCollide = false

			local offset = Vector3.new(rng:NextNumber(-0.5, 0.5), 0.8, rng:NextNumber(-0.5, 0.5))
			local angles = CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), math.rad(rng:NextNumber(0, 360)), math.rad(rng:NextNumber(-20, 20)))
			crystal.CFrame = CFrame.new(position + offset) * angles
			crystal.Parent = model
		end
	else
		for v = 1, 2 do
			local vein = Instance.new("Part")
			vein.Name = "OreVein"
			vein.Size = Vector3.new(1.3, 1.0, 1.3)
			vein.Position = position + Vector3.new(rng:NextNumber(-0.4, 0.4), 0.5, rng:NextNumber(-0.4, 0.4))
			vein.Orientation = Vector3.new(rng:NextNumber(-20, 20), rng:NextNumber(0, 360), rng:NextNumber(-20, 20))
			vein.Material = data.Material
			vein.Color = data.Color
			vein.Anchored = true
			vein.CanCollide = false
			vein.Parent = model
		end
	end

	if data.GlowColor then
		local light = Instance.new("PointLight")
		light.Name = "Glow"
		light.Color = data.GlowColor
		light.Brightness = 1.8
		light.Range = 10
		light.Parent = baseRock
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = string.format("%s %s", data.Icon or "", data.Name)
	prompt.ActionText = "Picar / Recoger"
	prompt.HoldDuration = data.HoldDuration
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = baseRock

	return model, prompt
end

local function setModelActive(model, active)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = active and 0 or 1
			if part.Name == "BaseRock" then
				part.CanCollide = active
			end
		elseif part:IsA("PointLight") then
			part.Enabled = active
		end
	end
end

local function spawnMineralNodes()
	local nodesFolder = Workspace:FindFirstChild("ResourceNodes")
	if nodesFolder then nodesFolder:Destroy() end

	nodesFolder = Instance.new("Folder")
	nodesFolder.Name = "ResourceNodes"
	nodesFolder.Parent = Workspace

	local bounds = Config.MAP_BOUNDS
	local rng = Random.new()

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { Workspace.Terrain, Workspace:FindFirstChild("Stage1_Map") }
	raycastParams.IgnoreWater = true

	for mineralKey, data in pairs(Config.MINERALS) do
		local count = data.SpawnCount or 8
		for i = 1, count do
			local posX = rng:NextNumber(bounds.MinX + 15, bounds.MaxX - 15)
			local posZ = rng:NextNumber(bounds.MinZ + 15, bounds.MaxZ - 15)

			local rayOrigin = Vector3.new(posX, Config.WATER_LEVEL + 5, posZ)
			local rayDir = Vector3.new(0, -90, 0)
			local result = Workspace:Raycast(rayOrigin, rayDir, raycastParams)

			local finalY = result and (result.Position.Y + 0.6) or -34

			local nodeModel, prompt = createMineralModel(mineralKey, data, Vector3.new(posX, finalY, posZ), rng)
			nodeModel.Parent = nodesFolder

			prompt.Triggered:Connect(function(player)
				local char = player.Character
				if not char then return end
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not hrp or (hrp.Position - nodeModel.PrimaryPart.Position).Magnitude > 18 then return end

				prompt.Enabled = false
				setModelActive(nodeModel, false)

				local current = player:GetAttribute(mineralKey) or 0
				player:SetAttribute(mineralKey, current + 1)

				ItemCollectedRemote:FireClient(player, mineralKey, data.Name, 1, data.Icon or "📦")

				task.delay(data.RespawnTime, function()
					if nodeModel and nodeModel.Parent then
						setModelActive(nodeModel, true)
						prompt.Enabled = true
					end
				end)
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- 6. JUGADORES, R15, SPAWN FORZADO Y OXIGENO
--------------------------------------------------------------------------------

local function enforceStandardAvatar(char)
	local humanoid = char:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	task.defer(function()
		local desc = humanoid:FindFirstChildOfClass("HumanoidDescription")
		if desc then
			desc.BodyTypeScale = 0
			desc.ProportionScale = 0
			desc.WidthScale = 1
			desc.HeightScale = 1
			desc.DepthScale = 1
			desc.HeadScale = 1
			pcall(function()
				humanoid:ApplyDescription(desc)
			end)
		end
	end)
end

local function onPlayerAdded(player)
	player:SetAttribute("Oxygen", Config.DEFAULT_MAX_OXYGEN)
	player:SetAttribute("MaxOxygen", Config.DEFAULT_MAX_OXYGEN)
	player:SetAttribute("Stage2Unlocked", false)

	for mineralKey in pairs(Config.MINERALS) do
		player:SetAttribute(mineralKey, 0)
	end

	player.CharacterAdded:Connect(function(char)
		player:SetAttribute("Oxygen", player:GetAttribute("MaxOxygen") or Config.DEFAULT_MAX_OXYGEN)
		enforceStandardAvatar(char)

		-- Forzar posicion sobre la cubierta amplia del Lifepod
		task.defer(function()
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = CFrame.new(0, Config.WATER_LEVEL + 4, 5)
			end
		end)
	end)

	if player.Character then
		enforceStandardAvatar(player.Character)
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(0, Config.WATER_LEVEL + 4, 5)
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Bucle de Oxigeno
local OXYGEN_TICK = 0.1
task.spawn(function()
	while true do
		task.wait(OXYGEN_TICK)

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if not char then continue end

			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local head = char:FindFirstChild("Head")
			if not humanoid or humanoid.Health <= 0 or not head then continue end

			local currentOx = player:GetAttribute("Oxygen") or Config.DEFAULT_MAX_OXYGEN
			local maxOx = player:GetAttribute("MaxOxygen") or Config.DEFAULT_MAX_OXYGEN
			local isSubmerged = head.Position.Y < Config.WATER_LEVEL

			if isSubmerged then
				currentOx = math.max(0, currentOx - (Config.OXYGEN_DEPLETION_RATE * OXYGEN_TICK))
				if currentOx <= 0 then
					humanoid:TakeDamage(Config.DROWN_DAMAGE_AMOUNT * OXYGEN_TICK)
				end
			else
				currentOx = math.min(maxOx, currentOx + (Config.OXYGEN_REFILL_RATE * OXYGEN_TICK))
			end

			player:SetAttribute("Oxygen", math.floor(currentOx * 10) / 10)
		end
	end
end)

-- Iniciar Mapa
buildEnvironment()
spawnMineralNodes()
print("[SubnauticaStages] Servidor inicializado con éxito: Lifepod 40x40 protegido, Océano y Submarino listos.")
