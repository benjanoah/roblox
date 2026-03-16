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
        AnimationBlend = 0, -- Smooth blend between idle and walk (0=idle, 1=walk)
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

        -- Check if actually moving (velocity-based, more reliable than MoveDirection)
        local velocity = hrp.AssemblyLinearVelocity
        local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude -- Ignore Y (jumping/falling)
        
        -- Smooth blend: gradually fade animation in/out to avoid jerky motion
        local targetBlend = speed > 0.5 and 1 or 0 -- Target: 1=walking, 0=idle
        local blendSpeed = 5 -- How fast to transition
        animData.AnimationBlend = animData.AnimationBlend + (targetBlend - animData.AnimationBlend) * blendSpeed * deltaTime
        
        -- Always update animation time when blend > 0
        if animData.AnimationBlend > 0.01 then
            animData.Time += deltaTime * 4 -- Animation speed (4 = natural walk pace)
            
            -- Sine wave for leg swing (opposite phases) - Natural walking motion
            local leftSwing = math.sin(animData.Time) * 0.6 * animData.AnimationBlend
            local rightSwing = math.sin(animData.Time + math.pi) * 0.6 * animData.AnimationBlend
            
            -- Negative rotation because of 180° body flip
            leftHip.C0 = animData.LeftOriginal * CFrame.Angles(-leftSwing, 0, 0)
            rightHip.C0 = animData.RightOriginal * CFrame.Angles(-rightSwing, 0, 0)
            
            -- Arm swing (opposite to legs for natural walking)
            if animData.LeftArmWeld and animData.RightArmWeld then
                local armSwing = 0.4 * animData.AnimationBlend
                animData.LeftArmWeld.C0 = animData.LeftArmOriginal * CFrame.Angles(-rightSwing * armSwing, 0, 0)
                animData.RightArmWeld.C0 = animData.RightArmOriginal * CFrame.Angles(-leftSwing * armSwing, 0, 0)
            end
        else
            -- Fully idle
            leftHip.C0 = animData.LeftOriginal
            rightHip.C0 = animData.RightOriginal
            if animData.LeftArmWeld then animData.LeftArmWeld.C0 = animData.LeftArmOriginal end
            if animData.RightArmWeld then animData.RightArmWeld.C0 = animData.RightArmOriginal end
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
