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

return GameConfig
