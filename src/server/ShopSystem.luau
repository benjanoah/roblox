--[[
    ShopSystem.luau
    Handle shop upgrades and player stats
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopSystem = {}

-- Player upgrade stats (persistent during game)
local playerUpgrades = {}

-- Upgrade definitions
local UPGRADES = {
    Damage = {
        Name = "💪 Damage Boost",
        Description = "+5 melee damage",
        BaseCost = 30,
        CostIncrease = 20, -- Each level costs +20 more
        MaxLevel = 5,
        Effect = function(player, level)
            -- Send damage update to client
            local newDamage = 25 + (level * 5) -- Base 25 + 5 per level
            local damageEvent = ReplicatedStorage:FindFirstChild("PlayerDamageUpdate")
            if damageEvent then
                damageEvent:FireClient(player, newDamage)
            end
        end
    },
    
    Health = {
        Name = "❤️ Max Health",
        Description = "+50 max HP",
        BaseCost = 40,
        CostIncrease = 30,
        MaxLevel = 5,
        Effect = function(player, level)
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.MaxHealth = 200 + (level * 50)
                    humanoid.Health = humanoid.MaxHealth -- Full heal on purchase
                end
            end
        end
    },
    
    Speed = {
        Name = "⚡ Movement Speed",
        Description = "+2 walk speed",
        BaseCost = 25,
        CostIncrease = 15,
        MaxLevel = 5,
        Effect = function(player, level)
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 18 + (level * 2)
                end
            end
        end
    },
    
    TrapDiscount = {
        Name = "🪤 Trap Discount",
        Description = "-1 gold per trap",
        BaseCost = 50,
        CostIncrease = 25,
        MaxLevel = 3, -- Max -3 gold (min 2 gold per trap)
        Effect = function(player, level)
            -- Trap cost is handled in TrapSystem
            return math.max(5 - level, 2) -- Min 2 gold per trap
        end
    },
    
    MinionBoost = {
        Name = "👹 Minion Power",
        Description = "+25 minion HP, +5 damage",
        BaseCost = 60,
        CostIncrease = 40,
        MaxLevel = 3,
        Effect = function(player, level)
            -- Minion stats handled in MinionSystem
            return {
                Health = 50 + (level * 25),
                Damage = 15 + (level * 5)
            }
        end
    }
}

--[[
    Initialize player upgrades
]]
function ShopSystem.InitPlayer(player)
    playerUpgrades[player.UserId] = {
        Damage = 0,
        Health = 0,
        Speed = 0,
        TrapDiscount = 0,
        MinionBoost = 0
    }
    
    print("🏪 Shop initialized for " .. player.Name)
end

--[[
    Get player's upgrade level
]]
function ShopSystem.GetUpgradeLevel(player, upgradeType)
    if not playerUpgrades[player.UserId] then
        ShopSystem.InitPlayer(player)
    end
    
    return playerUpgrades[player.UserId][upgradeType] or 0
end

--[[
    Get upgrade cost
]]
function ShopSystem.GetUpgradeCost(upgradeType, currentLevel)
    local upgrade = UPGRADES[upgradeType]
    if not upgrade then return 0 end
    
    return upgrade.BaseCost + (currentLevel * upgrade.CostIncrease)
end

--[[
    Purchase upgrade
]]
function ShopSystem.PurchaseUpgrade(player, upgradeType, MoneySystem)
    local upgrade = UPGRADES[upgradeType]
    if not upgrade then
        return false, "Invalid upgrade"
    end
    
    -- Get current level
    local currentLevel = ShopSystem.GetUpgradeLevel(player, upgradeType)
    
    -- Check max level
    if currentLevel >= upgrade.MaxLevel then
        return false, "Max level reached!"
    end
    
    -- Calculate cost
    local cost = ShopSystem.GetUpgradeCost(upgradeType, currentLevel)
    
    -- Check if player can afford
    local currentMoney = MoneySystem.GetMoney(player)
    if currentMoney < cost then
        return false, "Not enough gold! Need " .. cost .. " gold"
    end
    
    -- Deduct money
    MoneySystem.AddMoney(player, -cost)
    
    -- Increase level
    local newLevel = currentLevel + 1
    playerUpgrades[player.UserId][upgradeType] = newLevel
    
    -- Apply effect
    if upgrade.Effect then
        upgrade.Effect(player, newLevel)
    end
    
    print("✅ " .. player.Name .. " bought " .. upgrade.Name .. " (Level " .. newLevel .. ")")
    
    return true, "Purchased " .. upgrade.Name .. " Level " .. newLevel
end

--[[
    Get all upgrades data for UI
]]
function ShopSystem.GetUpgradesData(player)
    local data = {}
    
    for upgradeType, upgrade in pairs(UPGRADES) do
        local currentLevel = ShopSystem.GetUpgradeLevel(player, upgradeType)
        local cost = ShopSystem.GetUpgradeCost(upgradeType, currentLevel)
        
        table.insert(data, {
            Type = upgradeType,
            Name = upgrade.Name,
            Description = upgrade.Description,
            CurrentLevel = currentLevel,
            MaxLevel = upgrade.MaxLevel,
            Cost = cost,
            MaxedOut = currentLevel >= upgrade.MaxLevel
        })
    end
    
    return data
end

--[[
    Apply all upgrades when player spawns
]]
function ShopSystem.ApplyUpgrades(player)
    task.wait(0.5) -- Wait for character to fully load
    
    -- Re-apply all purchased upgrades
    for upgradeType, level in pairs(playerUpgrades[player.UserId] or {}) do
        if level > 0 then
            local upgrade = UPGRADES[upgradeType]
            if upgrade and upgrade.Effect then
                upgrade.Effect(player, level)
            end
        end
    end
    
    print("🔄 Applied upgrades for " .. player.Name)
end

return ShopSystem
