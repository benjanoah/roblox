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
local MinionSystem = require(script.MinionSystem)
local ShopSystem = require(script.ShopSystem)

-- Initialize game
SoundSystem.Init()
GameManager.Init()
TrapSystem.Init()
MoneySystem.Init()
MinionSystem.Init()

-- Shop system initialization
local Players = game:GetService("Players")

-- Create RemoteEvents for shop
local getShopDataEvent = Instance.new("RemoteFunction")
getShopDataEvent.Name = "GetShopData"
getShopDataEvent.Parent = ReplicatedStorage

local purchaseUpgradeEvent = Instance.new("RemoteEvent")
purchaseUpgradeEvent.Name = "PurchaseUpgrade"
purchaseUpgradeEvent.Parent = ReplicatedStorage

local shopFeedbackEvent = Instance.new("RemoteEvent")
shopFeedbackEvent.Name = "ShopFeedback"
shopFeedbackEvent.Parent = ReplicatedStorage

local playerDamageEvent = Instance.new("RemoteEvent")
playerDamageEvent.Name = "PlayerDamageUpdate"
playerDamageEvent.Parent = ReplicatedStorage

-- Handle shop data requests
getShopDataEvent.OnServerInvoke = function(player)
    return ShopSystem.GetUpgradesData(player)
end

-- Handle upgrade purchases
purchaseUpgradeEvent.OnServerEvent:Connect(function(player, upgradeType)
    local success, message = ShopSystem.PurchaseUpgrade(player, upgradeType, MoneySystem)
    
    if success then
        shopFeedbackEvent:FireClient(player, "✅ " .. message)
    else
        shopFeedbackEvent:FireClient(player, "❌ " .. message)
    end
end)

-- Initialize shop for new players
Players.PlayerAdded:Connect(function(player)
    ShopSystem.InitPlayer(player)
    
    -- Re-apply upgrades when character spawns
    player.CharacterAdded:Connect(function()
        ShopSystem.ApplyUpgrades(player)
    end)
end)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    ShopSystem.InitPlayer(player)
end

print("✅ Server initialized successfully!")
