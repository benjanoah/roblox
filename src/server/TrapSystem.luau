--[[
    TrapSystem - Server Module
    Handles trap placement requests from clients
]]

local TrapSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BearTrap = require(script.Parent.BearTrap)
local MoneySystem = require(script.Parent.MoneySystem)
local ShopSystem = require(script.Parent.ShopSystem)

-- Active traps in the game
local activeTraps = {}

function TrapSystem.Init()
    print("🪤 TrapSystem initialized")
    
    -- Create RemoteEvent for client->server communication
    local placeTrapEvent = Instance.new("RemoteEvent")
    placeTrapEvent.Name = "PlaceTrap"
    placeTrapEvent.Parent = ReplicatedStorage
    
    -- Create RemoteEvent for trap placement feedback
    local trapFeedbackEvent = Instance.new("RemoteEvent")
    trapFeedbackEvent.Name = "TrapFeedback"
    trapFeedbackEvent.Parent = ReplicatedStorage
    
    -- Listen for trap placement requests
    placeTrapEvent.OnServerEvent:Connect(function(player, position)
        TrapSystem.PlaceTrap(player, position)
    end)
end

function TrapSystem.PlaceTrap(player, position)
    -- Calculate trap cost with discount
    local discountLevel = ShopSystem.GetUpgradeLevel(player, "TrapDiscount")
    local trapCost = math.max(5 - discountLevel, 2) -- Base 5, min 2 gold
    
    -- Check if player can afford trap
    if not MoneySystem.CanAfford(player, trapCost) then
        print("❌ " .. player.Name .. " cannot afford trap (need " .. trapCost .. " gold)")
        
        -- Send feedback to client
        local trapFeedbackEvent = ReplicatedStorage:FindFirstChild("TrapFeedback")
        if trapFeedbackEvent then
            trapFeedbackEvent:FireClient(player, "Not enough gold! Need " .. trapCost .. " gold.")
        end
        return
    end
    
    -- Charge player
    if not MoneySystem.RemoveMoney(player, trapCost) then
        return
    end
    
    -- Validate position (make sure it's on the ground)
    if position.Y < 0.5 then
        position = Vector3.new(position.X, 0.5, position.Z)
    end
    
    print("🪤 Placing bear trap at " .. tostring(position))
    
    -- Create new trap
    local trap = BearTrap.new(position)
    table.insert(activeTraps, trap)
    
    -- Cleanup dead traps
    activeTraps = table.create(#activeTraps)
    for _, t in ipairs(activeTraps) do
        if t.isActive then
            table.insert(activeTraps, t)
        end
    end
end

return TrapSystem
