--[[
    MoneySystem - Server Module
    Manages player currency
]]

local MoneySystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Player money storage
local playerMoney = {}

-- Constants
MoneySystem.START_MONEY = 50
MoneySystem.HERO_KILL_REWARD = 10
MoneySystem.TRAP_COST = 5

function MoneySystem.Init()
    print("💰 MoneySystem initialized")
    
    -- Create RemoteEvent for money updates
    local moneyUpdateEvent = Instance.new("RemoteEvent")
    moneyUpdateEvent.Name = "MoneyUpdate"
    moneyUpdateEvent.Parent = ReplicatedStorage
    
    -- Setup new players
    Players.PlayerAdded:Connect(function(player)
        MoneySystem.SetMoney(player, MoneySystem.START_MONEY)
        print("💵 " .. player.Name .. " started with " .. MoneySystem.START_MONEY .. " gold")
    end)
    
    -- Cleanup on leave
    Players.PlayerRemoving:Connect(function(player)
        playerMoney[player.UserId] = nil
    end)
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        MoneySystem.SetMoney(player, MoneySystem.START_MONEY)
    end
end

function MoneySystem.GetMoney(player)
    return playerMoney[player.UserId] or 0
end

function MoneySystem.SetMoney(player, amount)
    playerMoney[player.UserId] = math.max(0, amount)
    
    -- Notify client
    local moneyUpdateEvent = ReplicatedStorage:FindFirstChild("MoneyUpdate")
    if moneyUpdateEvent then
        moneyUpdateEvent:FireClient(player, playerMoney[player.UserId])
    end
end

function MoneySystem.AddMoney(player, amount)
    local current = MoneySystem.GetMoney(player)
    MoneySystem.SetMoney(player, current + amount)
    print("💰 " .. player.Name .. " gained " .. amount .. " gold (total: " .. MoneySystem.GetMoney(player) .. ")")
end

function MoneySystem.RemoveMoney(player, amount)
    local current = MoneySystem.GetMoney(player)
    if current >= amount then
        MoneySystem.SetMoney(player, current - amount)
        print("💸 " .. player.Name .. " spent " .. amount .. " gold (remaining: " .. MoneySystem.GetMoney(player) .. ")")
        return true
    else
        print("❌ " .. player.Name .. " not enough gold (has " .. current .. ", needs " .. amount .. ")")
        return false
    end
end

function MoneySystem.CanAfford(player, amount)
    return MoneySystem.GetMoney(player) >= amount
end

return MoneySystem
