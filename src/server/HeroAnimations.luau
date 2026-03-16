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
    
    if not humanoid or not hrp then 
        warn("⚠️ No humanoid or HRP found for walk animation!")
        return 
    end
    
    -- Find leg joints (Motor6D)
    local leftHip = hrp:FindFirstChild("Left Hip")
    local rightHip = hrp:FindFirstChild("Right Hip")
    
    print("🔍 Animation setup - LeftHip:", leftHip, "RightHip:", rightHip)
    
    -- Find arms (Weld, but we can still animate)
    local leftArm = hero:FindFirstChild("Left Arm")
    local rightArm = hero:FindFirstChild("Right Arm")
    
    if not leftHip or not rightHip then 
        warn("⚠️ Motor6D joints not found! Can't animate.")
        return 
    end
    
    print("✅ Starting walk animation for hero")
    
    -- Store original C0 positions
    local leftHipOriginal = leftHip.C0
    local rightHipOriginal = rightHip.C0
    
    local leftArmWeld = leftArm and leftArm:FindFirstChildOfClass("Weld")
    local rightArmWeld = rightArm and rightArm:FindFirstChildOfClass("Weld")
    local leftArmOriginal = leftArmWeld and leftArmWeld.C0
    local rightArmOriginal = rightArmWeld and rightArmWeld.C0
    
    -- Animation state
    local animData = {
        Hero = hero,
        Time = 0,
        LeftHip = leftHip,
        RightHip = rightHip,
        LeftArmWeld = leftArmWeld,
        RightArmWeld = rightArmWeld,
        LeftOriginal = leftHipOriginal,
        RightOriginal = rightHipOriginal,
        LeftArmOriginal = leftArmOriginal,
        RightArmOriginal = rightArmOriginal,
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
        
        -- Animate ALWAYS while hero is alive (they're always pathfinding)
        animData.Time += deltaTime * 6 -- Faster animation speed
        
        -- Sine wave for leg swing (opposite phases) - BIGGER swing
        local leftSwing = math.sin(animData.Time) * 0.8
        local rightSwing = math.sin(animData.Time + math.pi) * 0.8
        
        -- Check if actually moving (for debug)
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0.1 then
            
        -- Apply rotation to legs (swing back and forth)
        leftHip.C0 = animData.LeftOriginal * CFrame.Angles(leftSwing, 0, 0)
        rightHip.C0 = animData.RightOriginal * CFrame.Angles(rightSwing, 0, 0)
        
        -- Arm swing (opposite to legs for natural walking)
        if animData.LeftArmWeld and animData.RightArmWeld then
            local armSwing = 0.3
            animData.LeftArmWeld.C0 = animData.LeftArmOriginal * CFrame.Angles(rightSwing * armSwing, 0, 0)
            animData.RightArmWeld.C0 = animData.RightArmOriginal * CFrame.Angles(leftSwing * armSwing, 0, 0)
        end
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
