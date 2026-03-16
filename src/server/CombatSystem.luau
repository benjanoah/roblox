--[[
    CombatSystem.luau
    Handles damage, health, and death for all entities
]]

local CombatSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

-- Track entity health
local EntityHealth = {}

--[[
    Initialize health for an entity
]]
function CombatSystem.InitializeHealth(entity, maxHealth)
    if not entity then 
        warn("⚠️ CombatSystem: nil entity passed to InitializeHealth!")
        return 
    end
    
    EntityHealth[entity] = {
        Current = maxHealth,
        Max = maxHealth
    }
    
    print("💊 Health initialized for " .. entity.Name .. ": " .. maxHealth .. " HP")
    
    -- Create health display (optional, for debugging)
    local humanoid = entity:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = maxHealth
        humanoid.Health = maxHealth
        print("  ✅ Humanoid health set: " .. humanoid.Health .. "/" .. humanoid.MaxHealth)
    else
        warn("  ⚠️ No Humanoid found in " .. entity.Name)
    end
end

--[[
    Deal damage to an entity
]]
function CombatSystem.DealDamage(target, damage, attacker)
    if not target or not EntityHealth[target] then
        return false
    end
    
    EntityHealth[target].Current = math.max(0, EntityHealth[target].Current - damage)
    
    -- Update humanoid health for visual feedback
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = EntityHealth[target].Current
    end
    
    -- Check death
    if EntityHealth[target].Current <= 0 then
        CombatSystem.HandleDeath(target, attacker)
        return true -- Target died
    end
    
    return false -- Target survived
end

--[[
    Handle entity death
]]
function CombatSystem.HandleDeath(entity, killer)
    print(entity.Name .. " died!")
    
    -- Clean up health tracking
    EntityHealth[entity] = nil
    
    -- Death effects
    if entity:FindFirstChild("HumanoidRootPart") then
        -- Ragdoll effect (simple version)
        local humanoid = entity:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
        
        -- Remove after delay
        task.delay(3, function()
            if entity and entity.Parent then
                entity:Destroy()
            end
        end)
    end
end

--[[
    Get current health of entity
]]
function CombatSystem.GetHealth(entity)
    if EntityHealth[entity] then
        return EntityHealth[entity].Current, EntityHealth[entity].Max
    end
    return 0, 0
end

--[[
    Check if entity is alive
]]
function CombatSystem.IsAlive(entity)
    return EntityHealth[entity] and EntityHealth[entity].Current > 0
end

return CombatSystem
