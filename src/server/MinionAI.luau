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
    Create a minion body
]]
local function CreateMinionBody(position, health, damage)
    -- Use custom stats or defaults
    health = health or MinionAI.HEALTH
    damage = damage or MinionAI.DAMAGE
    
    -- Pick random name
    local randomName = MinionNames[math.random(1, #MinionNames)]
    
    local minion = Instance.new("Model")
    minion.Name = randomName
    
    -- HumanoidRootPart
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(1.5, 1.5, 1)
    hrp.Position = position
    hrp.BrickColor = BrickColor.new("Lime green") -- Groen body
    hrp.Material = Enum.Material.Neon
    hrp.Parent = minion
    
    -- Head (small demon head)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 0.8, 0.8)
    head.Position = position + Vector3.new(0, 1.2, 0)
    head.BrickColor = BrickColor.new("Lime green") -- Groen hoofd
    head.Parent = minion
    
    local headWeld = Instance.new("Weld")
    headWeld.Part0 = hrp
    headWeld.Part1 = head
    headWeld.C0 = CFrame.new(0, 1.2, 0)
    headWeld.Parent = head
    
    -- Eyes (glowing)
    local leftEye = Instance.new("Part")
    leftEye.Name = "LeftEye"
    leftEye.Size = Vector3.new(0.2, 0.2, 0.1)
    leftEye.Position = head.Position + Vector3.new(-0.3, 0, -0.4)
    leftEye.BrickColor = BrickColor.new("Really red") -- Rode ogen
    leftEye.Material = Enum.Material.Neon
    leftEye.Parent = minion
    
    local leftEyeWeld = Instance.new("Weld")
    leftEyeWeld.Part0 = head
    leftEyeWeld.Part1 = leftEye
    leftEyeWeld.C0 = CFrame.new(-0.3, 0, -0.4)
    leftEyeWeld.Parent = leftEye
    
    local rightEye = Instance.new("Part")
    rightEye.Name = "RightEye"
    rightEye.Size = Vector3.new(0.2, 0.2, 0.1)
    rightEye.Position = head.Position + Vector3.new(0.3, 0, -0.4)
    rightEye.BrickColor = BrickColor.new("Really red") -- Rode ogen
    rightEye.Material = Enum.Material.Neon
    rightEye.Parent = minion
    
    local rightEyeWeld = Instance.new("Weld")
    rightEyeWeld.Part0 = head
    rightEyeWeld.Part1 = rightEye
    rightEyeWeld.C0 = CFrame.new(0.3, 0, -0.4)
    rightEyeWeld.Parent = rightEye
    
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
