--[[
    MinionSystem - Server Module
    Handles minion spawning requests from clients
]]

local MinionSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MinionAI = require(script.Parent.MinionAI)
local MoneySystem = require(script.Parent.MoneySystem)
local ShopSystem = require(script.Parent.ShopSystem)

-- Constants
MinionSystem.MINION_COST = 20
MinionSystem.MAX_MINIONS = 3

function MinionSystem.Init()
    print("👹 MinionSystem initialized")
    
    -- Create RemoteEvent
    local spawnMinionEvent = Instance.new("RemoteEvent")
    spawnMinionEvent.Name = "SpawnMinion"
    spawnMinionEvent.Parent = ReplicatedStorage
    
    local minionFeedbackEvent = Instance.new("RemoteEvent")
    minionFeedbackEvent.Name = "MinionFeedback"
    minionFeedbackEvent.Parent = ReplicatedStorage
    
    -- Listen for spawn requests
    spawnMinionEvent.OnServerEvent:Connect(function(player)
        MinionSystem.SpawnMinion(player)
    end)
end

function MinionSystem.SpawnMinion(player)
    -- Check minion limit
    local currentMinions = MinionAI.GetPlayerMinions(player)
    if currentMinions >= MinionSystem.MAX_MINIONS then
        print("❌ " .. player.Name .. " has max minions (" .. MinionSystem.MAX_MINIONS .. ")")
        
        local feedbackEvent = ReplicatedStorage:FindFirstChild("MinionFeedback")
        if feedbackEvent then
            feedbackEvent:FireClient(player, "Max " .. MinionSystem.MAX_MINIONS .. " minions!")
        end
        return
    end
    
    -- Check if player can afford
    if not MoneySystem.CanAfford(player, MinionSystem.MINION_COST) then
        print("❌ " .. player.Name .. " cannot afford minion (need " .. MinionSystem.MINION_COST .. " gold)")
        
        local feedbackEvent = ReplicatedStorage:FindFirstChild("MinionFeedback")
        if feedbackEvent then
            feedbackEvent:FireClient(player, "Need " .. MinionSystem.MINION_COST .. " gold!")
        end
        return
    end
    
    -- Charge player
    if not MoneySystem.RemoveMoney(player, MinionSystem.MINION_COST) then
        return
    end
    
    -- Get minion upgrade stats
    local boostLevel = ShopSystem.GetUpgradeLevel(player, "MinionBoost")
    local minionHealth = 50 + (boostLevel * 25)
    local minionDamage = 15 + (boostLevel * 5)
    
    -- Spawn minion with upgraded stats
    local minion = MinionAI.SpawnMinion(player, minionHealth, minionDamage)
    
    if minion then
        print("✅ " .. player.Name .. " spawned a minion! (HP:" .. minionHealth .. ", DMG:" .. minionDamage .. ")")
    end
end

return MinionSystem
