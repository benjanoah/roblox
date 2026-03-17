--[[
    Main Server Entry Point
    Dungeon Boss Simulator
]]

print("🧟 Dungeon Boss Simulator - Server Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to replicate
local maxWait = 10
local waited = 0
while not ReplicatedStorage:FindFirstChild("Shared") and waited < maxWait do
    task.wait(0.1)
    waited += 0.1
end

if not ReplicatedStorage:FindFirstChild("Shared") then
    warn("⚠️ Shared folder not found in ReplicatedStorage!")
    return
end

-- Load game systems
local GameManager = require(script.GameManager)
local CombatSystem = require(script.CombatSystem)
local HeroAI = require(script.HeroAI)
local TrapSystem = require(script.TrapSystem)
local MoneySystem = require(script.MoneySystem)
local SoundSystem = require(script.SoundSystem)

-- Initialize game
SoundSystem.Init()
GameManager.Init()
TrapSystem.Init()
MoneySystem.Init()

print("✅ Server initialized successfully!")
