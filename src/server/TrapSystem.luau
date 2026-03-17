--[[
    TrapSystem - Server Module
    Handles trap placement requests from clients
]]

local TrapSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BearTrap = require(script.Parent.BearTrap)
local MoneySystem = require(script.Parent.MoneySystem)

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
    -- Check if player can afford trap
    if not MoneySystem.CanAfford(player, MoneySystem.TRAP_COST) then
        print("❌ " .. player.Name .. " cannot afford trap (need " .. MoneySystem.TRAP_COST .. " gold)")
        
        -- Send feedback to client
        local trapFeedbackEvent = ReplicatedStorage:FindFirstChild("TrapFeedback")
        if trapFeedbackEvent then
            trapFeedbackEvent:FireClient(player, "Not enough gold! Need " .. MoneySystem.TRAP_COST .. " gold.")
        end
        return
    end
    
    -- Charge player
    if not MoneySystem.RemoveMoney(player, MoneySystem.TRAP_COST) then
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
