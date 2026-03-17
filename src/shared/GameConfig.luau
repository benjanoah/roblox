--[[
    GameConfig.luau
    Central configuration for Dungeon Boss Simulator
]]

local GameConfig = {}

-- Hero Settings
GameConfig.Hero = {
    Health = 100,
    WalkSpeed = 16,
    RunSpeed = 24, -- When carrying treasure
    Damage = 10,
    AttackCooldown = 1.5, -- seconds
    SpawnInterval = 10, -- seconds between hero spawns
    MaxHeroes = 5, -- Max heroes alive at once
}

-- Zombie (Player) Settings
GameConfig.Zombie = {
    Health = 200,
    WalkSpeed = 18,
    Damage = 25,
    AttackCooldown = 1.0,
    AttackRange = 8, -- studs
}

-- Game Settings
GameConfig.Game = {
    RoundDuration = 300, -- 5 minutes
    TreasureValue = 100, -- Points for defending
    WinCondition = "DefendTreasure", -- or "KillAllHeroes"
}

-- Wave Settings
GameConfig.Waves = {
    PrepTime = 20, -- Seconds between waves
    WaveBonus = 25, -- Gold bonus for completing a wave
    
    -- Wave definitions (heroes count, spawn interval)
    {HeroCount = 3, SpawnInterval = 10}, -- Wave 1: 3 heroes, slow
    {HeroCount = 5, SpawnInterval = 8},  -- Wave 2: 5 heroes
    {HeroCount = 8, SpawnInterval = 6},  -- Wave 3: 8 heroes, faster
    {HeroCount = 10, SpawnInterval = 5}, -- Wave 4: 10 heroes
    {HeroCount = 12, SpawnInterval = 4}, -- Wave 5: 12 heroes, very fast
    -- After wave 5, keep scaling: +2 heroes, -0.5s interval (min 2s)
}

return GameConfig
