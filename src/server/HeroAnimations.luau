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
    Play grabbing animation (crouch down, grab treasure)
]]
function HeroAnimations.PlayGrabAnimation(hero)
    local humanoid = hero:FindFirstChildOfClass("Humanoid")
    local hrp = hero:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- Find joints
    local leftHip = hrp:FindFirstChild("Left Hip")
    local rightHip = hrp:FindFirstChild("Right Hip")
    local leftArm = hero:FindFirstChild("Left Arm")
    local rightArm = hero:FindFirstChild("Right Arm")
    
    if not leftHip or not rightHip then return end
    
    -- Store originals
    local leftHipOriginal = leftHip.C0
    local rightHipOriginal = rightHip.C0
    
    local leftArmWeld = leftArm and leftArm:FindFirstChildOfClass("Weld")
    local rightArmWeld = rightArm and rightArm:FindFirstChildOfClass("Weld")
    local leftArmOriginal = leftArmWeld and leftArmWeld.C0
    local rightArmOriginal = rightArmWeld and rightArmWeld.C0
    
    -- Stop walking
    local originalSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 0
    
    -- Create progress bar UI (BillboardGui above head)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GrabProgress"
    billboard.Size = UDim2.new(4, 0, 0.5, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0) -- Above head
    billboard.AlwaysOnTop = true
    billboard.Parent = hrp
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    background.BorderSizePixel = 2
    background.Parent = billboard
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0) -- Start at 0%
    progressBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Gold color
    progressBar.BorderSizePixel = 0
    progressBar.Parent = background
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "📦 Grabbing..."
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = background
    
    -- Animation coroutine
    task.spawn(function()
        local animTime = 0
        local grabDuration = 1.5 -- 1.5 seconds total
        
        while animTime < grabDuration do
            task.wait(0.03)
            animTime += 0.03
            
            local progress = animTime / grabDuration
            
            -- Update progress bar
            progressBar.Size = UDim2.new(progress, 0, 1, 0)
            label.Text = "📦 " .. math.floor(progress * 100) .. "%"
            
            if progress < 0.5 then
                -- Phase 1: Crouch down (0 -> 0.5)
                local crouchProgress = progress * 2 -- 0 to 1
                local crouchAngle = math.sin(crouchProgress * math.pi * 0.5) * 0.8 -- Smooth ease
                
                -- Bend legs
                leftHip.C0 = leftHipOriginal * CFrame.Angles(crouchAngle, 0, 0)
                rightHip.C0 = rightHipOriginal * CFrame.Angles(crouchAngle, 0, 0)
                
                -- Arms down
                if leftArmWeld and rightArmWeld then
                    leftArmWeld.C0 = leftArmOriginal * CFrame.Angles(crouchAngle * 1.5, 0, 0)
                    rightArmWeld.C0 = rightArmOriginal * CFrame.Angles(crouchAngle * 1.5, 0, 0)
                end
            else
                -- Phase 2: Stand back up (0.5 -> 1.0)
                local standProgress = (progress - 0.5) * 2 -- 0 to 1
                local standAngle = (1 - math.sin(standProgress * math.pi * 0.5)) * 0.8
                
                -- Unbend legs
                leftHip.C0 = leftHipOriginal * CFrame.Angles(standAngle, 0, 0)
                rightHip.C0 = rightHipOriginal * CFrame.Angles(standAngle, 0, 0)
                
                -- Arms up
                if leftArmWeld and rightArmWeld then
                    leftArmWeld.C0 = leftArmOriginal * CFrame.Angles(standAngle * 1.5, 0, 0)
                    rightArmWeld.C0 = rightArmOriginal * CFrame.Angles(standAngle * 1.5, 0, 0)
                end
            end
        end
        
        -- Reset to original
        leftHip.C0 = leftHipOriginal
        rightHip.C0 = rightHipOriginal
        if leftArmWeld then leftArmWeld.C0 = leftArmOriginal end
        if rightArmWeld then rightArmWeld.C0 = rightArmOriginal end
        
        -- Complete! Update bar
        progressBar.Size = UDim2.new(1, 0, 1, 0)
        progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green = complete
        label.Text = "✅ Grabbed!"
        
        task.wait(0.5) -- Show complete message briefly
        
        -- Remove progress bar
        billboard:Destroy()
        
        -- Restore walk speed
        humanoid.WalkSpeed = originalSpeed
    end)
    
    return grabDuration -- Return animation duration
end

--[[
    Clean up all animations
]]
function HeroAnimations.CleanupAll()
    ActiveAnimations = {}
end

return HeroAnimations
