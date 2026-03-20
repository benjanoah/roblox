--[[
    MinionAI - Server Module
    AI for player-spawned minions that attack heroes
]]

local MinionAI = {}

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local ActiveMinions = {}

-- Random minion names
local MinionNames = {
    "Bob", "John", "Steve", "Dave", "Mike",
    "Jeff", "Carl", "Rick", "Frank", "Tom",
    "Gary", "Barry", "Larry", "Terry", "Jerry",
    "Kevin", "Brian", "Chad", "Brad", "Dan",
    "Stan", "Ron", "Don", "Ben", "Ken"
}

-- Minion stats
MinionAI.HEALTH = 50
MinionAI.DAMAGE = 15
MinionAI.ATTACK_RANGE = 6
MinionAI.ATTACK_COOLDOWN = 2
MinionAI.FOLLOW_DISTANCE = 10
MinionAI.WALK_SPEED = 14

--[[
    Create a minion body (R6 zombie style)
]]
local function CreateMinionBody(position, health, damage)
    -- Use custom stats or defaults
    health = health or MinionAI.HEALTH
    damage = damage or MinionAI.DAMAGE
    
    -- Pick random name
    local randomName = MinionNames[math.random(1, #MinionNames)]
    
    local minion = Instance.new("Model")
    minion.Name = randomName
    
    local color = BrickColor.new("Lime green") -- Groen zombie!
    
    -- HumanoidRootPart (invisible center)
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(1, 1, 0.5)
    hrp.Position = position
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Parent = minion
    
    -- Torso (body)
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(1, 1, 0.5)
    torso.Position = position
    torso.BrickColor = color
    torso.Parent = minion
    
    local torsoWeld = Instance.new("Weld")
    torsoWeld.Part0 = hrp
    torsoWeld.Part1 = torso
    torsoWeld.C0 = CFrame.new(0, 0, 0)
    torsoWeld.Parent = torso
    
    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(0.8, 0.8, 0.8)
    head.Position = position + Vector3.new(0, 1, 0)
    head.BrickColor = color
    head.Parent = minion
    
    local headWeld = Instance.new("Weld")
    headWeld.Part0 = torso
    headWeld.Part1 = head
    headWeld.C0 = CFrame.new(0, 0.9, 0)
    headWeld.Parent = head
    
    -- Eyes (glowing red)
    local leftEye = Instance.new("Part")
    leftEye.Name = "LeftEye"
    leftEye.Size = Vector3.new(0.15, 0.15, 0.1)
    leftEye.BrickColor = BrickColor.new("Really red")
    leftEye.Material = Enum.Material.Neon
    leftEye.Parent = minion
    
    local leftEyeWeld = Instance.new("Weld")
    leftEyeWeld.Part0 = head
    leftEyeWeld.Part1 = leftEye
    leftEyeWeld.C0 = CFrame.new(-0.2, 0.1, -0.41)
    leftEyeWeld.Parent = leftEye
    
    local rightEye = Instance.new("Part")
    rightEye.Name = "RightEye"
    rightEye.Size = Vector3.new(0.15, 0.15, 0.1)
    rightEye.BrickColor = BrickColor.new("Really red")
    rightEye.Material = Enum.Material.Neon
    rightEye.Parent = minion
    
    local rightEyeWeld = Instance.new("Weld")
    rightEyeWeld.Part0 = head
    rightEyeWeld.Part1 = rightEye
    rightEyeWeld.C0 = CFrame.new(0.2, 0.1, -0.41)
    rightEyeWeld.Parent = rightEye
    
    -- Left Arm
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(0.4, 1, 0.4)
    leftArm.Position = position + Vector3.new(-0.7, 0, 0)
    leftArm.BrickColor = color
    leftArm.Parent = minion
    
    local leftArmWeld = Instance.new("Weld")
    leftArmWeld.Part0 = torso
    leftArmWeld.Part1 = leftArm
    leftArmWeld.C0 = CFrame.new(-0.7, 0, 0)
    leftArmWeld.Parent = leftArm
    
    -- Right Arm
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(0.4, 1, 0.4)
    rightArm.Position = position + Vector3.new(0.7, 0, 0)
    rightArm.BrickColor = color
    rightArm.Parent = minion
    
    local rightArmWeld = Instance.new("Weld")
    rightArmWeld.Part0 = torso
    rightArmWeld.Part1 = rightArm
    rightArmWeld.C0 = CFrame.new(0.7, 0, 0)
    rightArmWeld.Parent = rightArm
    
    -- Left Leg
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(0.4, 1, 0.4)
    leftLeg.Position = position + Vector3.new(-0.3, -1, 0)
    leftLeg.BrickColor = color
    leftLeg.Parent = minion
    
    local leftLegWeld = Instance.new("Weld")
    leftLegWeld.Part0 = torso
    leftLegWeld.Part1 = leftLeg
    leftLegWeld.C0 = CFrame.new(-0.3, -1, 0)
    leftLegWeld.Parent = leftLeg
    
    -- Right Leg
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(0.4, 1, 0.4)
    rightLeg.Position = position + Vector3.new(0.3, -1, 0)
    rightLeg.BrickColor = color
    rightLeg.Parent = minion
    
    local rightLegWeld = Instance.new("Weld")
    rightLegWeld.Part0 = torso
    rightLegWeld.Part1 = rightLeg
    rightLegWeld.C0 = CFrame.new(0.3, -1, 0)
    rightLegWeld.Parent = rightLeg
    
    -- Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = health
    humanoid.Health = health
    humanoid.WalkSpeed = MinionAI.WALK_SPEED
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- Hide health bar
    humanoid.Parent = minion
    
    -- Store custom damage in minion
    minion:SetAttribute("Damage", damage)
    
    minion.Parent = workspace
    
    -- Name tag (BillboardGui)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = randomName .. " 👹"
    nameLabel.Parent = billboard
    
    return minion
end

--[[
    Spawn a minion for a player
]]
function MinionAI.SpawnMinion(player, health, damage)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local playerPos = player.Character.HumanoidRootPart.Position
    local spawnPos = playerPos + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
    
    local minion = CreateMinionBody(spawnPos, health, damage)
    
    local minionData = {
        model = minion,
        owner = player,
        target = nil,
        lastAttackTime = 0,
        state = "Follow"
    }
    
    table.insert(ActiveMinions, minionData)
    
    -- Start AI
    MinionAI.StartAI(minionData)
    
    -- Listen for death
    local humanoid = minion:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            print("💀 " .. minion.Name .. " died!")
            MinionAI.RemoveMinion(minionData)
        end)
    end
    
    print("👹 " .. minion.Name .. " spawned for " .. player.Name .. "! Total minions: " .. #ActiveMinions)
    
    return minion
end

--[[
    Start minion AI loop
]]
function MinionAI.StartAI(minionData)
    minionData.aiLoop = task.spawn(function()
        while minionData.model and minionData.model.Parent do
            local minion = minionData.model
            local humanoid = minion:FindFirstChildOfClass("Humanoid")
            local hrp = minion:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not hrp or humanoid.Health <= 0 then
                break
            end
            
            -- Find nearest hero
            local nearestHero = nil
            local nearestDistance = math.huge
            
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name == "Hero" and obj:FindFirstChild("HumanoidRootPart") then
                    local heroHRP = obj.HumanoidRootPart
                    local distance = (hrp.Position - heroHRP.Position).Magnitude
                    
                    if distance < nearestDistance then
                        nearestHero = obj
                        nearestDistance = distance
                    end
                end
            end
            
            -- Attack hero if in range
            if nearestHero and nearestDistance <= MinionAI.ATTACK_RANGE then
                minionData.state = "Attack"
                
                -- Attack if cooldown ready
                local now = tick()
                if now - minionData.lastAttackTime >= MinionAI.ATTACK_COOLDOWN then
                    local heroHumanoid = nearestHero:FindFirstChildOfClass("Humanoid")
                    if heroHumanoid then
                        -- Get custom damage from minion
                        local damage = minion:GetAttribute("Damage") or MinionAI.DAMAGE
                        heroHumanoid:TakeDamage(damage)
                        print("👹💥 " .. minion.Name .. " attacked hero for " .. damage .. " damage!")
                        minionData.lastAttackTime = now
                    end
                end
                
                -- Face hero
                local heroHRP = nearestHero:FindFirstChild("HumanoidRootPart")
                if heroHRP then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(heroHRP.Position.X, hrp.Position.Y, heroHRP.Position.Z))
                end
                
                humanoid:MoveTo(hrp.Position) -- Stop moving
                
            -- Chase hero if nearby but not in range
            elseif nearestHero and nearestDistance <= 30 then
                minionData.state = "Chase"
                local heroHRP = nearestHero:FindFirstChild("HumanoidRootPart")
                if heroHRP then
                    humanoid:MoveTo(heroHRP.Position)
                end
                
            -- Follow owner
            else
                minionData.state = "Follow"
                
                if minionData.owner and minionData.owner.Character and minionData.owner.Character:FindFirstChild("HumanoidRootPart") then
                    local ownerPos = minionData.owner.Character.HumanoidRootPart.Position
                    local distanceToOwner = (hrp.Position - ownerPos).Magnitude
                    
                    if distanceToOwner > MinionAI.FOLLOW_DISTANCE then
                        humanoid:MoveTo(ownerPos)
                    else
                        humanoid:MoveTo(hrp.Position) -- Stop
                    end
                end
            end
            
            task.wait(0.5)
        end
    end)
end

--[[
    Remove minion from active list
]]
function MinionAI.RemoveMinion(minionData)
    for i, data in ipairs(ActiveMinions) do
        if data == minionData then
            table.remove(ActiveMinions, i)
            break
        end
    end
    
    if minionData.model then
        minionData.model:Destroy()
    end
end

--[[
    Get active minions for a player
]]
function MinionAI.GetPlayerMinions(player)
    local count = 0
    for _, data in ipairs(ActiveMinions) do
        if data.owner == player then
            count += 1
        end
    end
    return count
end

--[[
    Cleanup all minions
]]
function MinionAI.CleanupAll()
    for _, data in ipairs(ActiveMinions) do
        if data.model then
            data.model:Destroy()
        end
    end
    ActiveMinions = {}
end

return MinionAI
