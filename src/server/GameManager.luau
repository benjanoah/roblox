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

local GameState = "Waiting" -- Waiting, PrepTime, WaveActive, WaveComplete, Ended
local PrepTimeRemaining = 60 -- 60 seconds initial prep time
local CurrentWave = 0
local HeroesSpawnedThisWave = 0
local HeroesKilledThisWave = 0

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
        
        -- Prep time over, start wave system
        if GameState == "PrepTime" then
            print("🚨 Initial prep time over! Starting wave system!")
            
            -- Notify clients
            for _, player in ipairs(Players:GetPlayers()) do
                prepTimeEvent:FireClient(player, 0)
            end
            
            -- Start wave system
            task.spawn(function()
                GameManager.WaveSystem()
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
    Wave System - manages waves of heroes
]]
function GameManager.WaveSystem()
    -- Create WaveUpdate RemoteEvent
    local waveUpdateEvent = ReplicatedStorage:FindFirstChild("WaveUpdate")
    if not waveUpdateEvent then
        waveUpdateEvent = Instance.new("RemoteEvent")
        waveUpdateEvent.Name = "WaveUpdate"
        waveUpdateEvent.Parent = ReplicatedStorage
    end
    
    local MoneySystem = require(script.Parent.MoneySystem)
    
    while GameState ~= "Ended" do
        -- Start next wave
        CurrentWave += 1
        HeroesSpawnedThisWave = 0
        HeroesKilledThisWave = 0
        GameState = "WaveActive"
        
        -- Get wave config
        local waveConfig = GameConfig.Waves[CurrentWave]
        if not waveConfig then
            -- Scale beyond defined waves
            local lastWave = GameConfig.Waves[#GameConfig.Waves]
            waveConfig = {
                HeroCount = lastWave.HeroCount + (CurrentWave - #GameConfig.Waves) * 2,
                SpawnInterval = math.max(2, lastWave.SpawnInterval - (CurrentWave - #GameConfig.Waves) * 0.5)
            }
        end
        
        print("🌊 WAVE " .. CurrentWave .. " START! (" .. waveConfig.HeroCount .. " heroes, " .. waveConfig.SpawnInterval .. "s interval)")
        
        -- Play wave start sound (quieter)
        local SoundSystem = require(script.Parent.SoundSystem)
        SoundSystem.PlaySoundGlobal("WaveStart", 0.3, 1)
        
        -- Notify clients
        for _, player in ipairs(Players:GetPlayers()) do
            waveUpdateEvent:FireClient(player, CurrentWave, "start", waveConfig.HeroCount)
        end
        
        -- Spawn heroes for this wave
        task.spawn(function()
            GameManager.SpawnWaveHeroes(waveConfig)
        end)
        
        -- Wait for wave to complete (all heroes killed)
        while GameState == "WaveActive" do
            task.wait(1)
            
            -- Check if wave is complete
            local activeHeroes = HeroAI.GetActiveHeroes()
            if HeroesSpawnedThisWave >= waveConfig.HeroCount and #activeHeroes == 0 then
                GameState = "WaveComplete"
            end
        end
        
        if GameState == "WaveComplete" then
            print("✅ WAVE " .. CurrentWave .. " COMPLETE!")
            
            -- Play victory sound (quieter)
            local SoundSystem = require(script.Parent.SoundSystem)
            SoundSystem.PlaySoundGlobal("WaveComplete", 0.4, 1)
            
            -- Give wave bonus to all players
            for _, player in ipairs(Players:GetPlayers()) do
                MoneySystem.AddMoney(player, GameConfig.Waves.WaveBonus)
                waveUpdateEvent:FireClient(player, CurrentWave, "complete", GameConfig.Waves.WaveBonus)
            end
            
            -- Prep time for next wave
            print("⏱️ " .. GameConfig.Waves.PrepTime .. " second prep time before Wave " .. (CurrentWave + 1))
            
            for i = GameConfig.Waves.PrepTime, 1, -1 do
                for _, player in ipairs(Players:GetPlayers()) do
                    waveUpdateEvent:FireClient(player, CurrentWave, "prep", i)
                end
                task.wait(1)
            end
        end
    end
end

--[[
    Spawn heroes for a wave
]]
function GameManager.SpawnWaveHeroes(waveConfig)
    local heroSpawn = workspace:FindFirstChild("HeroSpawn")
    
    if not heroSpawn then
        warn("⚠️ HeroSpawn not found in workspace!")
        return
    end
    
    while HeroesSpawnedThisWave < waveConfig.HeroCount and GameState == "WaveActive" do
        local hero = HeroAI.SpawnHero(heroSpawn.Position + Vector3.new(
            math.random(-5, 5),
            5,
            math.random(-5, 5)
        ))
        
        -- Initialize hero health
        CombatSystem.InitializeHealth(hero, GameConfig.Hero.Health)
        
        HeroesSpawnedThisWave += 1
        print("🗡️ Hero " .. HeroesSpawnedThisWave .. "/" .. waveConfig.HeroCount .. " spawned!")
        
        task.wait(waveConfig.SpawnInterval)
    end
end

-- Track hero kills for wave completion
function GameManager.OnHeroKilled()
    if GameState == "WaveActive" then
        HeroesKilledThisWave += 1
    end
end

-- Export for other modules
GameManager.OnHeroKilled = GameManager.OnHeroKilled

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
