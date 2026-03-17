--[[
    SoundSystem - Server Module
    Manages game sounds and audio feedback
]]

local SoundSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Sound IDs (Roblox built-in sounds)
SoundSystem.Sounds = {
    TrapSnap = "rbxasset://sounds/metal_hit.mp3",
    HeroDeath = "rbxasset://sounds/uuhhh.mp3",
    MeleeHit = "rbxasset://sounds/hit.mp3",
    MoneyEarned = "rbxasset://sounds/electronicpingshort.wav",
    WaveComplete = "rbxasset://sounds/victory.mp3",
    WaveStart = "rbxasset://sounds/action_get_up.mp3",
}

function SoundSystem.Init()
    print("🔊 SoundSystem initialized")
    
    -- Create RemoteEvent for client sound triggers
    local playSoundEvent = Instance.new("RemoteEvent")
    playSoundEvent.Name = "PlaySound"
    playSoundEvent.Parent = ReplicatedStorage
end

--[[
    Play a sound at a specific position in the world
]]
function SoundSystem.PlaySoundAtPosition(soundName, position, volume, pitch)
    volume = volume or 0.3 -- Lower default volume (background sounds)
    pitch = pitch or 1
    
    local soundId = SoundSystem.Sounds[soundName]
    if not soundId then
        warn("⚠️ Sound not found: " .. tostring(soundName))
        return
    end
    
    -- Create sound part at position
    local soundPart = Instance.new("Part")
    soundPart.Name = "SoundPart"
    soundPart.Size = Vector3.new(1, 1, 1)
    soundPart.Position = position
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Transparency = 1
    soundPart.Parent = workspace
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.PlaybackSpeed = pitch
    sound.Parent = soundPart
    
    sound:Play()
    
    -- Clean up after sound finishes
    game:GetService("Debris"):AddItem(soundPart, sound.TimeLength / pitch + 0.5)
end

--[[
    Play a sound for all players (2D, not positional)
]]
function SoundSystem.PlaySoundGlobal(soundName, volume, pitch)
    volume = volume or 0.3 -- Lower default volume (background sounds)
    pitch = pitch or 1
    
    local soundId = SoundSystem.Sounds[soundName]
    if not soundId then
        warn("⚠️ Sound not found: " .. tostring(soundName))
        return
    end
    
    -- Send to all clients
    local playSoundEvent = ReplicatedStorage:FindFirstChild("PlaySound")
    if playSoundEvent then
        playSoundEvent:FireAllClients(soundName, volume, pitch)
    end
end

return SoundSystem
