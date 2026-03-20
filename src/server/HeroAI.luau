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
local HeroAnimations = require(script.Parent.HeroAnimations)
local MoneySystem = require(script.Parent.MoneySystem)
local SoundSystem = require(script.Parent.SoundSystem)

local ActiveHeroes = {}

--[[
    Create a basic R6-style humanoid character
]]
local function CreateHeroBody(position)
    local hero = Instance.new("Model")
    hero.Name = "Hero"
    
    -- HumanoidRootPart (center of character) - Minion size!
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(1, 1, 0.5)
    hrp.Position = position
    hrp.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0) -- Face forward!
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Parent = hero
    
    -- Head - Minion size!
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(0.8, 0.8, 0.8)
    head.Position = position + Vector3.new(0, 1, 0)
    head.BrickColor = BrickColor.new("Light orange")
    head.TopSurface = Enum.SurfaceType.Smooth
    head.BottomSurface = Enum.SurfaceType.Smooth
    head.Parent = hero
    
    local headWeld = Instance.new("Weld")
    headWeld.Part0 = hrp
    headWeld.Part1 = head
    headWeld.C0 = CFrame.new(0, 0.9, 0)
    headWeld.Parent = head
    
    -- Torso - Minion size!
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(1, 1, 0.5)
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
    
    -- Left Leg - Minion size!
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(0.4, 1, 0.4)
    leftLeg.Position = position + Vector3.new(-0.3, -1, 0)
    leftLeg.BrickColor = BrickColor.new("Bright green")
    leftLeg.TopSurface = Enum.SurfaceType.Smooth
    leftLeg.BottomSurface = Enum.SurfaceType.Smooth
    leftLeg.Parent = hero
    
    local leftLegWeld = Instance.new("Motor6D")
    leftLegWeld.Name = "Left Hip"
    leftLegWeld.Part0 = torso
    leftLegWeld.Part1 = leftLeg
    leftLegWeld.C0 = CFrame.new(-0.3, -0.5, 0)
    leftLegWeld.C1 = CFrame.new(0, 0.5, 0)
    leftLegWeld.Parent = torso
    
    -- Right Leg - Minion size!
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(0.4, 1, 0.4)
    rightLeg.Position = position + Vector3.new(0.3, -1, 0)
    rightLeg.BrickColor = BrickColor.new("Bright green")
    rightLeg.TopSurface = Enum.SurfaceType.Smooth
    rightLeg.BottomSurface = Enum.SurfaceType.Smooth
    rightLeg.Parent = hero
    
    local rightLegWeld = Instance.new("Motor6D")
    rightLegWeld.Name = "Right Hip"
    rightLegWeld.Part0 = torso
    rightLegWeld.Part1 = rightLeg
    rightLegWeld.C0 = CFrame.new(0.3, -0.5, 0)
    rightLegWeld.C1 = CFrame.new(0, 0.5, 0)
    rightLegWeld.Parent = torso
    
    -- Left Arm - Minion size!
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(0.4, 1, 0.4)
    leftArm.Position = position + Vector3.new(-0.7, 0, 0)
    leftArm.BrickColor = BrickColor.new("Light orange")
    leftArm.TopSurface = Enum.SurfaceType.Smooth
    leftArm.BottomSurface = Enum.SurfaceType.Smooth
    leftArm.Parent = hero
    
    local leftShoulder = Instance.new("Motor6D")
    leftShoulder.Name = "Left Shoulder"
    leftShoulder.Part0 = torso
    leftShoulder.Part1 = leftArm
    leftShoulder.C0 = CFrame.new(-0.5, 0.4, 0)
    leftShoulder.C1 = CFrame.new(0, 0.5, 0)
    leftShoulder.Parent = torso
    
    -- Right Arm - Minion size!
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(0.4, 1, 0.4)
    rightArm.Position = position + Vector3.new(0.7, 0, 0)
    rightArm.BrickColor = BrickColor.new("Light orange")
    rightArm.TopSurface = Enum.SurfaceType.Smooth
    rightArm.BottomSurface = Enum.SurfaceType.Smooth
    rightArm.Parent = hero
    
    local rightShoulder = Instance.new("Motor6D")
    rightShoulder.Name = "Right Shoulder"
    rightShoulder.Part0 = torso
    rightShoulder.Part1 = rightArm
    rightShoulder.C0 = CFrame.new(0.5, 0.4, 0)
    rightShoulder.C1 = CFrame.new(0, 0.5, 0)
    rightShoulder.Parent = torso
    
    -- Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = GameConfig.Hero.Health
    humanoid.Health = GameConfig.Hero.Health
    humanoid.WalkSpeed = GameConfig.Hero.WalkSpeed
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = hero
    
    -- Body Colors (knight theme)
    local bodyColors = Instance.new("BodyColors")
    bodyColors.HeadColor = BrickColor.new("Medium stone grey") -- Metal skin
    bodyColors.TorsoColor = BrickColor.new("Dark stone grey")  -- Armor
    bodyColors.LeftArmColor = BrickColor.new("Medium stone grey")
    bodyColors.RightArmColor = BrickColor.new("Medium stone grey")
    bodyColors.LeftLegColor = BrickColor.new("Dark stone grey") -- Boots
    bodyColors.RightLegColor = BrickColor.new("Dark stone grey")
    bodyColors.Parent = hero
    
    -- KNIGHT OUTFIT (scaled to minion size) --
    
    -- Helmet (on head)
    local helmet = Instance.new("Part")
    helmet.Name = "Helmet"
    helmet.Size = Vector3.new(0.9, 0.9, 0.9) -- Minion size
    helmet.Position = head.Position
    helmet.BrickColor = BrickColor.new("Silver")
    helmet.Material = Enum.Material.Metal
    helmet.TopSurface = Enum.SurfaceType.Smooth
    helmet.BottomSurface = Enum.SurfaceType.Smooth
    helmet.Parent = hero
    
    local helmetWeld = Instance.new("Weld")
    helmetWeld.Part0 = head
    helmetWeld.Part1 = helmet
    helmetWeld.C0 = CFrame.new(0, 0, 0)
    helmetWeld.Parent = helmet
    
    -- Visor (front of helmet)
    local visor = Instance.new("Part")
    visor.Name = "Visor"
    visor.Size = Vector3.new(0.6, 0.15, 0.05)
    visor.Position = head.Position + Vector3.new(0, 0, -0.45)
    visor.BrickColor = BrickColor.new("Really black")
    visor.Material = Enum.Material.Glass
    visor.TopSurface = Enum.SurfaceType.Smooth
    visor.BottomSurface = Enum.SurfaceType.Smooth
    visor.Parent = hero
    
    local visorWeld = Instance.new("Weld")
    visorWeld.Part0 = helmet
    visorWeld.Part1 = visor
    visorWeld.C0 = CFrame.new(0, 0, -0.45)
    visorWeld.Parent = visor
    
    -- Chestplate (over torso)
    local chestplate = Instance.new("Part")
    chestplate.Name = "Chestplate"
    chestplate.Size = Vector3.new(1.1, 1.1, 0.55)
    chestplate.Position = torso.Position
    chestplate.BrickColor = BrickColor.new("Silver")
    chestplate.Material = Enum.Material.Metal
    chestplate.TopSurface = Enum.SurfaceType.Smooth
    chestplate.BottomSurface = Enum.SurfaceType.Smooth
    chestplate.Parent = hero
    
    local chestplateWeld = Instance.new("Weld")
    chestplateWeld.Part0 = torso
    chestplateWeld.Part1 = chestplate
    chestplateWeld.C0 = CFrame.new(0, 0, 0)
    chestplateWeld.Parent = chestplate
    
    -- Blue emblem on chest
    local emblem = Instance.new("Part")
    emblem.Name = "Emblem"
    emblem.Size = Vector3.new(0.4, 0.4, 0.05)
    emblem.Position = torso.Position + Vector3.new(0, 0.15, -0.3)
    emblem.BrickColor = BrickColor.new("Bright blue")
    emblem.Material = Enum.Material.Neon
    emblem.TopSurface = Enum.SurfaceType.Smooth
    emblem.BottomSurface = Enum.SurfaceType.Smooth
    emblem.Parent = hero
    
    local emblemWeld = Instance.new("Weld")
    emblemWeld.Part0 = chestplate
    emblemWeld.Part1 = emblem
    emblemWeld.C0 = CFrame.new(0, 0.15, -0.3)
    emblemWeld.Parent = emblem
    
    -- Shield (on left arm) - Minion size!
    local shield = Instance.new("Part")
    shield.Name = "Shield"
    shield.Size = Vector3.new(0.15, 1, 0.75)
    shield.Position = leftArm.Position + Vector3.new(-0.25, 0, 0)
    shield.BrickColor = BrickColor.new("Silver")
    shield.Material = Enum.Material.Metal
    shield.TopSurface = Enum.SurfaceType.Smooth
    shield.BottomSurface = Enum.SurfaceType.Smooth
    shield.Parent = hero
    
    local shieldWeld = Instance.new("Weld")
    shieldWeld.Part0 = leftArm
    shieldWeld.Part1 = shield
    shieldWeld.C0 = CFrame.new(-0.25, 0, 0)
    shieldWeld.Parent = shield
    
    -- Shield emblem (blue cross) - Minion size!
    local shieldEmblem = Instance.new("Part")
    shieldEmblem.Name = "ShieldEmblem"
    shieldEmblem.Size = Vector3.new(0.05, 0.75, 0.15)
    shieldEmblem.Position = shield.Position + Vector3.new(-0.1, 0, 0)
    shieldEmblem.BrickColor = BrickColor.new("Bright blue")
    shieldEmblem.Material = Enum.Material.Neon
    shieldEmblem.TopSurface = Enum.SurfaceType.Smooth
    shieldEmblem.BottomSurface = Enum.SurfaceType.Smooth
    shieldEmblem.Parent = hero
    
    local shieldEmblemWeld = Instance.new("Weld")
    shieldEmblemWeld.Part0 = shield
    shieldEmblemWeld.Part1 = shieldEmblem
    shieldEmblemWeld.C0 = CFrame.new(-0.1, 0, 0)
    shieldEmblemWeld.Parent = shieldEmblem
    
    -- Sword (in right hand) - Minion size!
    local sword = Instance.new("Part")
    sword.Name = "Sword"
    sword.Size = Vector3.new(0.1, 1.5, 0.25)
    sword.Position = rightArm.Position + Vector3.new(0, -0.5, -0.75)
    sword.BrickColor = BrickColor.new("Silver")
    sword.Material = Enum.Material.Metal
    sword.TopSurface = Enum.SurfaceType.Smooth
    sword.BottomSurface = Enum.SurfaceType.Smooth
    sword.Parent = hero
    
    -- Weld sword to hand, pointing forward with handle at hand
    local swordWeld = Instance.new("Weld")
    swordWeld.Part0 = rightArm
    swordWeld.Part1 = sword
    swordWeld.C0 = CFrame.new(0, -0.5, -0.75) * CFrame.Angles(math.rad(90), 0, 0)
    swordWeld.Parent = sword
    
    -- Sword handle (brown, at top of blade where hand grips) - Minion size!
    local swordHandle = Instance.new("Part")
    swordHandle.Name = "SwordHandle"
    swordHandle.Size = Vector3.new(0.15, 0.4, 0.15)
    swordHandle.Position = sword.Position + Vector3.new(0, 0.75, 0)
    swordHandle.BrickColor = BrickColor.new("Dark orange")
    swordHandle.Material = Enum.Material.Wood
    swordHandle.TopSurface = Enum.SurfaceType.Smooth
    swordHandle.BottomSurface = Enum.SurfaceType.Smooth
    swordHandle.Parent = hero
    
    local handleWeld = Instance.new("Weld")
    handleWeld.Part0 = sword
    handleWeld.Part1 = swordHandle
    handleWeld.C0 = CFrame.new(0, 0.75, 0)
    handleWeld.Parent = swordHandle
    
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
    
    print("✅ Hero created: " .. hero.Name .. " | Humanoid: " .. tostring(hero:FindFirstChildOfClass("Humanoid")))
    
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
    
    -- Start walk animation
    HeroAnimations.StartWalkCycle(hero)
    
    -- Listen for death to clean up
    local humanoid = hero:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            print("💀 Hero died! Cleaning up...")
            
            -- Play death sound (quieter)
            local heroPos = hero:FindFirstChild("HumanoidRootPart")
            if heroPos then
                SoundSystem.PlaySoundAtPosition("HeroDeath", heroPos.Position, 0.2, 1)
            end
            
            -- Give money to all players (in single player, just the one player)
            for _, player in ipairs(Players:GetPlayers()) do
                MoneySystem.AddMoney(player, MoneySystem.HERO_KILL_REWARD)
            end
            
            -- Notify GameManager (for wave tracking)
            local GameManager = require(script.Parent.GameManager)
            GameManager.OnHeroKilled()
            
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
                -- Calculate position NEXT TO treasure (not on top of it!)
                local treasurePos = treasure.Position
                local offset = Vector3.new(
                    math.random(-4, 4), -- Random position around treasure
                    0,
                    math.random(-4, 4)
                )
                -- Ensure minimum distance of 3 studs
                if offset.Magnitude < 3 then
                    offset = offset.Unit * 3
                end
                local targetPos = treasurePos + offset
                
                HeroAI.MoveToTarget(hero, targetPos)
                
                -- Check if reached treasure area (within 6 studs)
                local hrp = hero:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - treasurePos).Magnitude < 6 then
                    -- Face the treasure before grabbing
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(treasurePos.X, hrp.Position.Y, treasurePos.Z))
                    heroData.State = "StealTreasure"
                end
            end
            
        elseif heroData.State == "StealTreasure" then
            print("📦 Hero grabbed treasure! Running to exit!")
            heroData.HasTreasure = true
            if humanoid then
                humanoid.WalkSpeed = GameConfig.Hero.RunSpeed
            end
            heroData.State = "Escape"
            
        elseif heroData.State == "Escape" then
            local exit = workspace:FindFirstChild("Exit")
            if exit then
                HeroAI.MoveToTarget(hero, exit.Position)
                
                -- Check if reached exit
                local hrp = hero:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - exit.Position).Magnitude < 5 then
                    heroData.State = "Escaped"
                    print("⚠️ HERO ESCAPED WITH TREASURE!")
                    
                    -- Damage player for letting knight escape!
                    local Players = game:GetService("Players")
                    local SoundSystem = require(script.Parent.SoundSystem)
                    
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player.Character then
                            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                humanoid:TakeDamage(50)
                                print("💔 " .. player.Name .. " lost 50 HP! (Knight escaped)")
                                
                                -- Play warning sound
                                SoundSystem.PlaySoundGlobal("HeroDeath", 0.5, 0.8)
                            end
                        end
                    end
                    
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
    
    -- Check if already close to target (avoid unnecessary pathfinding)
    if (hrp.Position - targetPosition).Magnitude < 8 then
        humanoid:MoveTo(targetPosition)
        return
    end
    
    -- Create path with better settings
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = false,
        WaypointSpacing = 4, -- Fewer waypoints = smoother movement
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(hrp.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        -- Start from waypoint 2 (skip current position)
        for i = 2, #waypoints do
            if humanoid.Health <= 0 or not hero.Parent then break end
            
            local waypoint = waypoints[i]
            humanoid:MoveTo(waypoint.Position)
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            -- Wait for hero to reach waypoint with timeout
            local moveConnection
            local reached = false
            
            moveConnection = humanoid.MoveToFinished:Connect(function(didReach)
                reached = true
            end)
            
            -- Timeout after 2 seconds OR if close enough
            local startTime = tick()
            while not reached and tick() - startTime < 2 do
                task.wait(0.1)
                
                -- If close to waypoint, consider it reached
                if (hrp.Position - waypoint.Position).Magnitude < 4 then
                    reached = true
                    break
                end
                
                -- If stuck (not moving), break out
                if hrp.AssemblyLinearVelocity.Magnitude < 0.5 and tick() - startTime > 0.5 then
                    break
                end
            end
            
            moveConnection:Disconnect()
            
            -- If stuck for real, try direct path
            if not reached and i < #waypoints - 1 then
                -- Skip to next waypoint
                continue
            end
        end
    else
        -- Fallback: move directly (no obstacles)
        humanoid:MoveTo(targetPosition)
        task.wait(1) -- Give it time to try
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
