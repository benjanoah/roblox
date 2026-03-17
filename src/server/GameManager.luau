--[[
    GameManager.luau
    Main game loop and state management
]]

local GameManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HeroAI = require(script.Parent.HeroAI)
local CombatSystem = require(script.Parent.CombatSystem)

local GameState = "Waiting" -- Waiting, PrepTime, Active, Ended
local PrepTimeRemaining = 60 -- 60 seconds prep time

--[[
    Start the game
]]
function GameManager.StartGame()
    print("🎮 Starting Dungeon Boss Simulator!")
    
    GameState = "PrepTime"
    PrepTimeRemaining = 60
    
    -- Initialize player as zombie
    GameManager.SetupPlayer()
    
    -- Create PrepTime RemoteEvent
    local prepTimeEvent = ReplicatedStorage:FindFirstChild("PrepTimeUpdate")
    if not prepTimeEvent then
        prepTimeEvent = Instance.new("RemoteEvent")
        prepTimeEvent.Name = "PrepTimeUpdate"
        prepTimeEvent.Parent = ReplicatedStorage
    end
    
    -- Prep time countdown
    task.spawn(function()
        while PrepTimeRemaining > 0 and GameState == "PrepTime" do
            -- Send to all clients
            for _, player in ipairs(Players:GetPlayers()) do
                prepTimeEvent:FireClient(player, PrepTimeRemaining)
            end
            
            if PrepTimeRemaining % 10 == 0 or PrepTimeRemaining <= 5 then
                print("⏱️ Prep time: " .. PrepTimeRemaining .. " seconds")
            end
            
            task.wait(1)
            PrepTimeRemaining -= 1
        end
        
        -- Prep time over, start main game
        if GameState == "PrepTime" then
            print("🚨 Prep time over! Heroes incoming!")
            GameState = "Active"
            
            -- Notify clients
            for _, player in ipairs(Players:GetPlayers()) do
                prepTimeEvent:FireClient(player, 0)
            end
            
            -- Start hero spawning
            task.spawn(function()
                GameManager.HeroSpawnLoop()
            end)
            
            -- Start game timer
            task.spawn(function()
                GameManager.GameTimer()
            end)
        end
    end)
end

--[[
    Setup player as zombie boss
]]
function GameManager.SetupPlayer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = GameConfig.Zombie.WalkSpeed
                CombatSystem.InitializeHealth(player.Character, GameConfig.Zombie.Health)
                
                -- Give zombie appearance (optional)
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.BrickColor = BrickColor.new("Dark green")
                end
            end
        end
    end
end

--[[
    Hero spawn loop (only during Active state)
]]
function GameManager.HeroSpawnLoop()
    -- Wait for Active state (after prep time)
    while GameState ~= "Active" do
        task.wait(0.5)
    end
    
    while GameState == "Active" do
        local heroSpawn = workspace:FindFirstChild("HeroSpawn")
        
        if heroSpawn then
            local activeHeroes = HeroAI.GetActiveHeroes()
            
            -- Only spawn if under max heroes
            if #activeHeroes < GameConfig.Hero.MaxHeroes then
                local hero = HeroAI.SpawnHero(heroSpawn.Position + Vector3.new(
                    math.random(-5, 5),
                    5,
                    math.random(-5, 5)
                ))
                
                -- Initialize hero health
                CombatSystem.InitializeHealth(hero, GameConfig.Hero.Health)
                
                print("🗡️ Hero spawned! Total heroes: " .. (#activeHeroes + 1))
            end
        else
            warn("⚠️ HeroSpawn not found in workspace! Add a Part named 'HeroSpawn'")
        end
        
        task.wait(GameConfig.Hero.SpawnInterval)
    end
end

--[[
    Game timer
]]
function GameManager.GameTimer()
    local timeRemaining = GameConfig.Game.RoundDuration
    
    while GameState == "Active" and timeRemaining > 0 do
        task.wait(1)
        timeRemaining -= 1
        
        -- TODO: Update UI with time
        if timeRemaining % 30 == 0 then
            print("⏱️ Time remaining: " .. timeRemaining .. " seconds")
        end
    end
    
    if GameState == "Active" then
        GameManager.EndGame("TimeUp")
    end
end

--[[
    End the game
]]
function GameManager.EndGame(reason)
    GameState = "Ended"
    
    if reason == "TimeUp" then
        print("✅ YOU WIN! You defended the treasure!")
    elseif reason == "HeroEscaped" then
        print("❌ GAME OVER! A hero escaped with the treasure!")
    elseif reason == "PlayerDied" then
        print("💀 GAME OVER! You died!")
    end
    
    -- Clean up
    HeroAI.CleanupAll()
    
    -- Reset after delay
    task.wait(5)
    GameManager.StartGame()
end

--[[
    Initialize on server start
]]
function GameManager.Init()
    print("📦 GameManager initialized")
    
    -- Wait for first player
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            if GameState == "Waiting" then
                task.wait(2) -- Wait for character to fully load
                GameManager.StartGame()
            else
                -- Rejoin mid-game
                GameManager.SetupPlayer()
            end
        end)
    end)
end

return GameManager
