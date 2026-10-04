local Stage1Config = {
	STAGE_ID = 1,
	STAGE_NAME = "Stage 1: Arrecife Seguro",
	STAGE_DESCRIPTION = "Aguas cálidas y poco profundas. Recolecta materiales y repara el submarino de descenso.",
	
	-- Dimensiones de este mapa
	WATER_LEVEL = 18,
	SEABED_Y = -35,
	MAP_BOUNDS = {
		MinX = -130,
		MaxX = 130,
		MinZ = -130,
		MaxZ = 130,
	},

	-- Oxigeno base
	DEFAULT_MAX_OXYGEN = 45,
	OXYGEN_DEPLETION_RATE = 1,
	OXYGEN_REFILL_RATE = 25,
	DROWN_DAMAGE_AMOUNT = 12,

	-- Minerales exclusivos de Stage 1
	MINERALS = {
		Carbon = {
			Name = "Carbón",
			Color = Color3.fromRGB(35, 35, 40),
			Material = Enum.Material.Basalt,
			Shape = "Rock",
			RespawnTime = 10,
			HoldDuration = 0.4,
			SpawnCount = 10,
			Icon = "⬛",
		},
		Titanium = {
			Name = "Titanio",
			Color = Color3.fromRGB(175, 180, 190),
			Material = Enum.Material.Slate,
			Shape = "Rock",
			RespawnTime = 10,
			HoldDuration = 0.4,
			SpawnCount = 14,
			Icon = "🪨",
		},
		Copper = {
			Name = "Cobre",
			Color = Color3.fromRGB(225, 120, 60),
			Material = Enum.Material.CorrodedMetal,
			Shape = "Rock",
			RespawnTime = 12,
			HoldDuration = 0.5,
			SpawnCount = 10,
			Icon = "🔶",
		},
		Quartz = {
			Name = "Cuarzo",
			Color = Color3.fromRGB(220, 245, 255),
			Material = Enum.Material.Glass,
			Shape = "Crystal",
			GlowColor = Color3.fromRGB(180, 235, 255),
			RespawnTime = 14,
			HoldDuration = 0.5,
			SpawnCount = 10,
			Icon = "💠",
		},
		Lead = {
			Name = "Plomo",
			Color = Color3.fromRGB(85, 90, 100),
			Material = Enum.Material.DiamondPlate,
			Shape = "Rock",
			RespawnTime = 16,
			HoldDuration = 0.6,
			SpawnCount = 6,
			Icon = "🪙",
		},
	},

	-- Requisitos para desbloquear la transicion a Stage 2
	STAGE2_GATE_REQUIREMENTS = {
		Titanium = 5,
		Copper = 3,
		Quartz = 2,
	},

	-- ID de Place en Roblox para TeleportService (0 por ahora si es local o placeholder)
	STAGE2_PLACE_ID = 0,
}

return Stage1Config
