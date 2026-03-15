--[[
    HeroAI.luau
    AI behavior for hero NPCs
    State machine: Spawn -> SeekTreasure -> StealTreasure -> Escape -> Win
]]

local HeroAI = {}

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local ActiveHeroes = {}

--[[
    Spawn a hero NPC
]]
function HeroAI.SpawnHero(spawnPosition)
    -- Create basic R15 NPC
    local hero = Instance.new("Model")
    hero.Name = "Hero"
    
    -- Create humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = hero
    humanoid.WalkSpeed = GameConfig.Hero.WalkSpeed
    
    -- Create HumanoidRootPart
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Position = spawnPosition
    hrp.Anchored = false
    hrp.CanCollide = true
    hrp.Parent = hero
    
    -- Create visible body (simple block for now)
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.BrickColor = BrickColor.new("Bright blue")
    torso.TopSurface = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.Parent = hero
    
    -- Weld torso to HRP
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = torso
    weld.Parent = hrp
    
    -- Add to workspace
    hero.Parent = workspace
    
    -- Initialize state
    local heroData = {
        Model = hero,
        State = "SeekTreasure",
        HasTreasure = false,
        Target = nil,
    }
    
    table.insert(ActiveHeroes, heroData)
    
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
    local humanoid = hero:FindFirstChildOfClass("Humanoid")
    
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
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(hrp.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        for _, waypoint in ipairs(waypoints) do
            if humanoid.Health <= 0 then break end
            
            humanoid:MoveTo(waypoint.Position)
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            -- Wait for hero to reach waypoint or timeout
            local timeout = humanoid.MoveToFinished:Wait(2)
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
