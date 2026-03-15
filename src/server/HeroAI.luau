--[[
    HeroAI.luau
    AI behavior for hero NPCs
    State machine: Spawn -> SeekTreasure -> StealTreasure -> Escape -> Win
]]

local HeroAI = {}

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local ActiveHeroes = {}

--[[
    Create a basic R6-style humanoid character
]]
local function CreateHeroBody(position)
    local hero = Instance.new("Model")
    hero.Name = "Hero"
    
    -- HumanoidRootPart (center of character)
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Position = position
    hrp.BrickColor = BrickColor.new("Bright blue")
    hrp.TopSurface = Enum.SurfaceType.Smooth
    hrp.BottomSurface = Enum.SurfaceType.Smooth
    hrp.Parent = hero
    
    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.Position = position + Vector3.new(0, 1.5, 0)
    head.BrickColor = BrickColor.new("Light orange")
    head.TopSurface = Enum.SurfaceType.Smooth
    head.BottomSurface = Enum.SurfaceType.Smooth
    head.Parent = hero
    
    local headWeld = Instance.new("Weld")
    headWeld.Part0 = hrp
    headWeld.Part1 = head
    headWeld.C0 = CFrame.new(0, 1.5, 0)
    headWeld.Parent = head
    
    -- Torso
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Position = position
    torso.BrickColor = BrickColor.new("Bright blue")
    torso.TopSurface = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.Parent = hero
    
    local torsoWeld = Instance.new("Weld")
    torsoWeld.Part0 = hrp
    torsoWeld.Part1 = torso
    torsoWeld.C0 = CFrame.new(0, 0, 0)
    torsoWeld.Parent = torso
    
    -- Left Leg
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Position = position + Vector3.new(-0.5, -2, 0)
    leftLeg.BrickColor = BrickColor.new("Bright green")
    leftLeg.TopSurface = Enum.SurfaceType.Smooth
    leftLeg.BottomSurface = Enum.SurfaceType.Smooth
    leftLeg.Parent = hero
    
    local leftLegWeld = Instance.new("Motor6D")
    leftLegWeld.Name = "Left Hip"
    leftLegWeld.Part0 = hrp
    leftLegWeld.Part1 = leftLeg
    leftLegWeld.C0 = CFrame.new(-0.5, -1, 0)
    leftLegWeld.C1 = CFrame.new(0, 1, 0)
    leftLegWeld.Parent = hrp
    
    -- Right Leg
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Position = position + Vector3.new(0.5, -2, 0)
    rightLeg.BrickColor = BrickColor.new("Bright green")
    rightLeg.TopSurface = Enum.SurfaceType.Smooth
    rightLeg.BottomSurface = Enum.SurfaceType.Smooth
    rightLeg.Parent = hero
    
    local rightLegWeld = Instance.new("Motor6D")
    rightLegWeld.Name = "Right Hip"
    rightLegWeld.Part0 = hrp
    rightLegWeld.Part1 = rightLeg
    rightLegWeld.C0 = CFrame.new(0.5, -1, 0)
    rightLegWeld.C1 = CFrame.new(0, 1, 0)
    rightLegWeld.Parent = hrp
    
    -- Left Arm
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Position = position + Vector3.new(-1.5, 0, 0)
    leftArm.BrickColor = BrickColor.new("Light orange")
    leftArm.TopSurface = Enum.SurfaceType.Smooth
    leftArm.BottomSurface = Enum.SurfaceType.Smooth
    leftArm.Parent = hero
    
    local leftArmWeld = Instance.new("Weld")
    leftArmWeld.Part0 = hrp
    leftArmWeld.Part1 = leftArm
    leftArmWeld.C0 = CFrame.new(-1.5, 0, 0)
    leftArmWeld.Parent = leftArm
    
    -- Right Arm
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Position = position + Vector3.new(1.5, 0, 0)
    rightArm.BrickColor = BrickColor.new("Light orange")
    rightArm.TopSurface = Enum.SurfaceType.Smooth
    rightArm.BottomSurface = Enum.SurfaceType.Smooth
    rightArm.Parent = hero
    
    local rightArmWeld = Instance.new("Weld")
    rightArmWeld.Part0 = hrp
    rightArmWeld.Part1 = rightArm
    rightArmWeld.C0 = CFrame.new(1.5, 0, 0)
    rightArmWeld.Parent = rightArm
    
    -- Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = GameConfig.Hero.Health
    humanoid.Health = GameConfig.Hero.Health
    humanoid.WalkSpeed = GameConfig.Hero.WalkSpeed
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = hero
    
    -- Body Colors (optional, makes it look nicer)
    local bodyColors = Instance.new("BodyColors")
    bodyColors.HeadColor = BrickColor.new("Light orange")
    bodyColors.TorsoColor = BrickColor.new("Bright blue")
    bodyColors.LeftArmColor = BrickColor.new("Light orange")
    bodyColors.RightArmColor = BrickColor.new("Light orange")
    bodyColors.LeftLegColor = BrickColor.new("Bright green")
    bodyColors.RightLegColor = BrickColor.new("Bright green")
    bodyColors.Parent = hero
    
    return hero
end

--[[
    Spawn a hero NPC
]]
function HeroAI.SpawnHero(spawnPosition)
    local hero = CreateHeroBody(spawnPosition + Vector3.new(
        math.random(-5, 5),
        3, -- Spawn slightly above ground
        math.random(-5, 5)
    ))
    
    hero.Parent = workspace
    
    -- Wait for character to fully load
    task.wait(0.1)
    
    -- Initialize state
    local heroData = {
        Model = hero,
        State = "SeekTreasure",
        HasTreasure = false,
        Target = nil,
    }
    
    table.insert(ActiveHeroes, heroData)
    
    -- Listen for death to clean up
    local humanoid = hero:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            print("💀 Hero died! Cleaning up...")
            -- Remove from active heroes IMMEDIATELY
            for i, data in ipairs(ActiveHeroes) do
                if data == heroData then
                    table.remove(ActiveHeroes, i)
                    print("✅ Removed from ActiveHeroes list. Total: " .. #ActiveHeroes)
                    break
                end
            end
            
            -- Fade out and destroy
            local hrp = hero:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = true -- Prevent physics glitches
            end
            
            -- Make transparent
            for _, part in ipairs(hero:GetDescendants()) do
                if part:IsA("BasePart") then
                    task.spawn(function()
                        for i = 0, 1, 0.1 do
                            part.Transparency = i
                            task.wait(0.05)
                        end
                    end)
                end
            end
            
            -- Force destroy after 1 second
            task.delay(1, function()
                hero:Destroy()
                print("🗑️ Hero destroyed!")
            end)
        end)
    end
    
    -- Start AI loop
    task.spawn(function()
        HeroAI.RunAI(heroData)
    end)
    
    return hero
end

--[[
    Main AI loop
]]
function HeroAI.RunAI(heroData)
    local hero = heroData.Model
    local humanoid = hero:WaitForChild("Humanoid", 5)
    
    if not humanoid then
        warn("Hero spawned without Humanoid!")
        return
    end
    
    while hero.Parent and humanoid.Health > 0 do
        -- State machine
        if heroData.State == "SeekTreasure" then
            local treasure = workspace:FindFirstChild("Treasure")
            if treasure then
                HeroAI.MoveToTarget(hero, treasure.Position)
                
                -- Check if reached treasure
                local hrp = hero:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - treasure.Position).Magnitude < 5 then
                    heroData.State = "StealTreasure"
                end
            end
            
        elseif heroData.State == "StealTreasure" then
            print(hero.Name .. " is stealing treasure!")
            heroData.HasTreasure = true
            humanoid.WalkSpeed = GameConfig.Hero.RunSpeed
            heroData.State = "Escape"
            
        elseif heroData.State == "Escape" then
            local exit = workspace:FindFirstChild("Exit")
            if exit then
                HeroAI.MoveToTarget(hero, exit.Position)
                
                -- Check if reached exit
                local hrp = hero:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - exit.Position).Magnitude < 5 then
                    heroData.State = "Escaped"
                    print("⚠️ HERO ESCAPED WITH TREASURE! GAME OVER!")
                    -- TODO: Trigger game over
                    hero:Destroy()
                end
            end
        end
        
        task.wait(0.5) -- AI update rate
    end
    
    -- Clean up when hero dies
    for i, data in ipairs(ActiveHeroes) do
        if data == heroData then
            table.remove(ActiveHeroes, i)
            break
        end
    end
end

--[[
    Move hero to target position using pathfinding
]]
function HeroAI.MoveToTarget(hero, targetPosition)
    local humanoid = hero:FindFirstChildOfClass("Humanoid")
    local hrp = hero:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- Simple pathfinding
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = false,
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(hrp.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        for i, waypoint in ipairs(waypoints) do
            if humanoid.Health <= 0 or not hero.Parent then break end
            
            humanoid:MoveTo(waypoint.Position)
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            -- Wait for hero to reach waypoint or timeout
            local reached = humanoid.MoveToFinished:Wait(3)
            
            -- If stuck, try next waypoint
            if not reached then
                print("Hero stuck, skipping to next waypoint")
            end
        end
    else
        -- Fallback: move directly
        humanoid:MoveTo(targetPosition)
    end
end

--[[
    Get all active heroes
]]
function HeroAI.GetActiveHeroes()
    return ActiveHeroes
end

--[[
    Clean up all heroes
]]
function HeroAI.CleanupAll()
    for _, heroData in ipairs(ActiveHeroes) do
        if heroData.Model then
            heroData.Model:Destroy()
        end
    end
    ActiveHeroes = {}
end

return HeroAI
