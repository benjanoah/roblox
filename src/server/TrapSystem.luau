--[[
    TrapSystem - Server Module
    Handles trap placement requests from clients
]]

local TrapSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BearTrap = require(script.Parent.BearTrap)

-- Active traps in the game
local activeTraps = {}

function TrapSystem.Init()
    print("🪤 TrapSystem initialized")
    
    -- Create RemoteEvent for client->server communication
    local placeTrapEvent = Instance.new("RemoteEvent")
    placeTrapEvent.Name = "PlaceTrap"
    placeTrapEvent.Parent = ReplicatedStorage
    
    -- Listen for trap placement requests
    placeTrapEvent.OnServerEvent:Connect(function(player, position)
        TrapSystem.PlaceTrap(player, position)
    end)
end

function TrapSystem.PlaceTrap(player, position)
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
