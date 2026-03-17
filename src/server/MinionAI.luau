--[[
    MinionAI - Server Module
    AI for player-spawned minions that attack heroes
]]

local MinionAI = {}

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local ActiveMinions = {}

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
local function CreateMinionBody(position)
    local minion = Instance.new("Model")
    minion.Name = "Minion"
    
    -- HumanoidRootPart
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(1.5, 1.5, 1)
    hrp.Position = position
    hrp.BrickColor = BrickColor.new("Bright red")
    hrp.Material = Enum.Material.Neon
    hrp.Parent = minion
    
    -- Head (small demon head)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 0.8, 0.8)
    head.Position = position + Vector3.new(0, 1.2, 0)
    head.BrickColor = BrickColor.new("Crimson")
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
    leftEye.BrickColor = BrickColor.new("Lime green")
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
    rightEye.BrickColor = BrickColor.new("Lime green")
    rightEye.Material = Enum.Material.Neon
    rightEye.Parent = minion
    
    local rightEyeWeld = Instance.new("Weld")
    rightEyeWeld.Part0 = head
    rightEyeWeld.Part1 = rightEye
    rightEyeWeld.C0 = CFrame.new(0.3, 0, -0.4)
    rightEyeWeld.Parent = rightEye
    
    -- Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = MinionAI.HEALTH
    humanoid.Health = MinionAI.HEALTH
    humanoid.WalkSpeed = MinionAI.WALK_SPEED
    humanoid.Parent = minion
    
    minion.Parent = workspace
    
    return minion
end

--[[
    Spawn a minion for a player
]]
function MinionAI.SpawnMinion(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local playerPos = player.Character.HumanoidRootPart.Position
    local spawnPos = playerPos + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
    
    local minion = CreateMinionBody(spawnPos)
    
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
            print("💀 Minion died!")
            MinionAI.RemoveMinion(minionData)
        end)
    end
    
    print("👹 Minion spawned for " .. player.Name .. "! Total minions: " .. #ActiveMinions)
    
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
                        heroHumanoid:TakeDamage(MinionAI.DAMAGE)
                        print("👹💥 Minion attacked hero for " .. MinionAI.DAMAGE .. " damage!")
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
