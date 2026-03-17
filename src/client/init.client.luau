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

-- Trap placement
local lastTrapPlacement = 0
local trapPlacementCooldown = 2.0 -- seconds
local placeTrapEvent = ReplicatedStorage:WaitForChild("PlaceTrap")
local trapFeedbackEvent = ReplicatedStorage:WaitForChild("TrapFeedback")

-- Trap preview
local trapPreview = nil

-- Listen for trap placement feedback
trapFeedbackEvent.OnClientEvent:Connect(function(message)
    print("⚠️ " .. message)
end)

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
        end
    end
end

--[[
    Place Bear Trap
]]
local function PlaceTrap()
    local now = tick()
    if now - lastTrapPlacement < trapPlacementCooldown then
        local remaining = math.ceil(trapPlacementCooldown - (now - lastTrapPlacement))
        print("⏳ Trap cooldown: " .. remaining .. "s")
        return
    end
    
    -- Get mouse target position
    local targetPos = mouse.Hit.Position
    
    -- Place trap on ground level
    local trapPosition = Vector3.new(targetPos.X, 0.5, targetPos.Z)
    
    -- Send to server
    placeTrapEvent:FireServer(trapPosition)
    
    lastTrapPlacement = now
    print("🪤 Trap placed at " .. tostring(trapPosition))
end

--[[
    Update trap preview (green circle where trap will be placed)
]]
local function UpdateTrapPreview()
    if not trapPreview then
        trapPreview = Instance.new("Part")
        trapPreview.Name = "TrapPreview"
        trapPreview.Size = Vector3.new(4, 0.2, 4)
        trapPreview.Transparency = 0.7
        trapPreview.Color = Color3.fromRGB(0, 255, 0)
        trapPreview.Material = Enum.Material.Neon
        trapPreview.Anchored = true
        trapPreview.CanCollide = false
        trapPreview.Parent = workspace
    end
    
    -- Update position to follow mouse
    local targetPos = mouse.Hit.Position
    trapPreview.Position = Vector3.new(targetPos.X, 0.6, targetPos.Z)
end

-- Update preview every frame
game:GetService("RunService").Heartbeat:Connect(function()
    UpdateTrapPreview()
end)

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
    
    -- T key = Place trap
    if input.KeyCode == Enum.KeyCode.T then
        PlaceTrap()
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

-- Money label
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0, 200, 0, 50)
moneyLabel.Position = UDim2.new(0, 10, 0, 70)
moneyLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
moneyLabel.BackgroundTransparency = 0.5
moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
moneyLabel.TextScaled = true
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.Parent = screenGui

-- Current money
local currentMoney = 0

-- Update health UI
humanoid.HealthChanged:Connect(function(health)
    healthLabel.Text = "❤️ HP: " .. math.floor(health) .. " / " .. humanoid.MaxHealth
end)

healthLabel.Text = "❤️ HP: " .. humanoid.Health .. " / " .. humanoid.MaxHealth

-- Update money UI
local function UpdateMoneyUI()
    moneyLabel.Text = "💰 Gold: " .. currentMoney
end

-- Listen for money updates from server
local moneyUpdateEvent = ReplicatedStorage:WaitForChild("MoneyUpdate")
moneyUpdateEvent.OnClientEvent:Connect(function(newAmount)
    currentMoney = newAmount
    UpdateMoneyUI()
end)

UpdateMoneyUI()

-- Prep time timer (big center screen)
local prepTimeLabel = Instance.new("TextLabel")
prepTimeLabel.Size = UDim2.new(0, 400, 0, 100)
prepTimeLabel.Position = UDim2.new(0.5, -200, 0.3, -50)
prepTimeLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
prepTimeLabel.BackgroundTransparency = 0.3
prepTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
prepTimeLabel.TextSize = 48
prepTimeLabel.Font = Enum.Font.GothamBold
prepTimeLabel.Text = "Prep Time: 60"
prepTimeLabel.Visible = false
prepTimeLabel.Parent = screenGui

-- Wave label (top center)
local waveLabel = Instance.new("TextLabel")
waveLabel.Size = UDim2.new(0, 300, 0, 60)
waveLabel.Position = UDim2.new(0.5, -150, 0, 10)
waveLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
waveLabel.BackgroundTransparency = 0.3
waveLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
waveLabel.TextSize = 36
waveLabel.Font = Enum.Font.GothamBold
waveLabel.Text = "🌊 Wave 1"
waveLabel.Visible = false
waveLabel.Parent = screenGui

-- Listen for prep time updates
local prepTimeEvent = ReplicatedStorage:WaitForChild("PrepTimeUpdate")
prepTimeEvent.OnClientEvent:Connect(function(timeRemaining)
    if timeRemaining > 0 then
        prepTimeLabel.Visible = true
        prepTimeLabel.Text = "⏱️ Initial Prep: " .. timeRemaining
        
        -- Flash when almost over
        if timeRemaining <= 5 then
            prepTimeLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        else
            prepTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    else
        -- Hide prep timer when waves start
        prepTimeLabel.Text = "🚨 WAVE 1 INCOMING!"
        prepTimeLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        task.wait(2)
        prepTimeLabel.Visible = false
    end
end)

-- Listen for wave updates
local waveUpdateEvent = ReplicatedStorage:WaitForChild("WaveUpdate")
waveUpdateEvent.OnClientEvent:Connect(function(waveNumber, status, data)
    if status == "start" then
        waveLabel.Text = "🌊 Wave " .. waveNumber
        waveLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        waveLabel.Visible = true
        
        prepTimeLabel.Text = "🗡️ " .. data .. " Heroes Incoming!"
        prepTimeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        prepTimeLabel.Visible = true
        task.wait(3)
        prepTimeLabel.Visible = false
        
    elseif status == "complete" then
        prepTimeLabel.Text = "✅ WAVE " .. waveNumber .. " COMPLETE!\n+💰 " .. data .. " Gold Bonus"
        prepTimeLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        prepTimeLabel.TextSize = 36
        prepTimeLabel.Visible = true
        task.wait(3)
        prepTimeLabel.TextSize = 48
        
    elseif status == "prep" then
        prepTimeLabel.Text = "⏱️ Next Wave: " .. data .. "s"
        prepTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        prepTimeLabel.Visible = true
    end
end)

print("✅ Client initialized! Controls:")
print("   🖱️ Left Click = Melee Attack")
print("   ⌨️ Space = Melee Attack")
print("   🪤 T = Place Bear Trap")
