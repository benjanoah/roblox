--[[
    HeroAnimations.luau
    Walk cycle animations for hero knights
]]

local HeroAnimations = {}

local RunService = game:GetService("RunService")

local ActiveAnimations = {}

--[[
    Start walk animation for a hero
]]
function HeroAnimations.StartWalkCycle(hero)
    local humanoid = hero:FindFirstChildOfClass("Humanoid")
    local hrp = hero:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- Find leg joints (Motor6D)
    local leftHip = hrp:FindFirstChild("Left Hip")
    local rightHip = hrp:FindFirstChild("Right Hip")
    
    if not leftHip or not rightHip then return end
    
    -- Store original C0 positions
    local leftHipOriginal = leftHip.C0
    local rightHipOriginal = rightHip.C0
    
    -- Animation state
    local animData = {
        Hero = hero,
        Time = 0,
        LeftHip = leftHip,
        RightHip = rightHip,
        LeftOriginal = leftHipOriginal,
        RightOriginal = rightHipOriginal,
    }
    
    table.insert(ActiveAnimations, animData)
    
    -- Animation loop
    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        -- Check if hero still exists and is alive
        if not hero.Parent or humanoid.Health <= 0 then
            connection:Disconnect()
            -- Reset legs to original position
            if leftHip then leftHip.C0 = leftHipOriginal end
            if rightHip then rightHip.C0 = rightHipOriginal end
            -- Remove from active list
            for i, data in ipairs(ActiveAnimations) do
                if data == animData then
                    table.remove(ActiveAnimations, i)
                    break
                end
            end
            return
        end
        
        -- Only animate if moving
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0.1 then
            animData.Time += deltaTime * 4 -- Animation speed
            
            -- Sine wave for leg swing (opposite phases)
            local leftSwing = math.sin(animData.Time) * 0.5
            local rightSwing = math.sin(animData.Time + math.pi) * 0.5
            
            -- Apply rotation to legs (swing back and forth)
            leftHip.C0 = leftHipOriginal * CFrame.Angles(leftSwing, 0, 0)
            rightHip.C0 = rightHipOriginal * CFrame.Angles(rightSwing, 0, 0)
        else
            -- Reset to idle position
            leftHip.C0 = leftHipOriginal
            rightHip.C0 = rightHipOriginal
        end
    end)
end

--[[
    Clean up all animations
]]
function HeroAnimations.CleanupAll()
    ActiveAnimations = {}
end

return HeroAnimations
