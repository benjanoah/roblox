--[[
    Main Client Entry Point
    Player controls and UI
]]

print("🎮 Dungeon Boss Simulator - Client Starting...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Attack cooldown
local lastAttack = 0
local attackCooldown = 1.0 -- seconds

--[[
    Melee attack (punch)
]]
local function MeleeAttack()
    local now = tick()
    if now - lastAttack < attackCooldown then
        return -- Still on cooldown
    end
    
    lastAttack = now
    
    -- Find nearby enemies in range
    local attackRange = 8
    local attackDamage = 25
    
    -- Find the CLOSEST hero within range (not just the first one!)
    local closestHero = nil
    local closestDistance = attackRange
    
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Hero" and obj:FindFirstChild("HumanoidRootPart") then
            local heroHRP = obj.HumanoidRootPart
            local distance = (humanoidRootPart.Position - heroHRP.Position).Magnitude
            
            if distance <= closestDistance then
                closestHero = obj
                closestDistance = distance
            end
        end
    end
    
    -- Attack the closest hero
    if closestHero then
        local heroHumanoid = closestHero:FindFirstChildOfClass("Humanoid")
        if heroHumanoid then
            heroHumanoid:TakeDamage(attackDamage)
            print("💥 Hit " .. closestHero.Name .. " for " .. attackDamage .. " damage! (Distance: " .. math.floor(closestDistance) .. " studs)")
            
            -- Visual feedback
            local heroHRP = closestHero:FindFirstChild("HumanoidRootPart")
            if heroHRP then
                local hitEffect = Instance.new("Part")
                hitEffect.Shape = Enum.PartType.Ball
                hitEffect.Size = Vector3.new(2, 2, 2)
                hitEffect.Position = heroHRP.Position
                hitEffect.BrickColor = BrickColor.new("Bright red")
                hitEffect.Material = Enum.Material.Neon
                hitEffect.Anchored = true
                hitEffect.CanCollide = false
                hitEffect.Parent = workspace
                
                game:GetService("Debris"):AddItem(hitEffect, 0.3)
            end
        end
    end
end

--[[
    Input handling
]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Left mouse click = melee attack
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MeleeAttack()
    end
    
    -- Keyboard shortcut (M1 alternative)
    if input.KeyCode == Enum.KeyCode.Space then
        MeleeAttack()
    end
end)

-- Simple UI feedback
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local healthLabel = Instance.new("TextLabel")
healthLabel.Size = UDim2.new(0, 200, 0, 50)
healthLabel.Position = UDim2.new(0, 10, 0, 10)
healthLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
healthLabel.BackgroundTransparency = 0.5
healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
healthLabel.TextScaled = true
healthLabel.Font = Enum.Font.GothamBold
healthLabel.Parent = screenGui

-- Update health UI
humanoid.HealthChanged:Connect(function(health)
    healthLabel.Text = "❤️ HP: " .. math.floor(health) .. " / " .. humanoid.MaxHealth
end)

healthLabel.Text = "❤️ HP: " .. humanoid.Health .. " / " .. humanoid.MaxHealth

print("✅ Client initialized! Controls:")
print("   🖱️ Left Click = Melee Attack")
print("   ⌨️ Space = Melee Attack")
