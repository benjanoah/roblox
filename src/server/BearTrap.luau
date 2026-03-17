--[[
    BearTrap Module
    Creates and manages individual bear traps
]]

local BearTrap = {}
BearTrap.__index = BearTrap

local Debris = game:GetService("Debris")

function BearTrap.new(position)
    local self = setmetatable({}, BearTrap)
    
    self.isActive = true
    self.isTriggered = false
    self.trapRadius = 2.5 -- Trigger distance
    
    -- Create trap model
    self:CreateModel(position)
    
    -- Start checking for heroes
    self:StartTriggerCheck()
    
    return self
end

function BearTrap:CreateModel(position)
    -- Base plate
    local base = Instance.new("Part")
    base.Name = "TrapBase"
    base.Size = Vector3.new(4, 0.5, 4)
    base.Position = position + Vector3.new(0, 0.25, 0)
    base.Anchored = true
    base.CanCollide = false
    base.Material = Enum.Material.Metal
    base.Color = Color3.fromRGB(80, 80, 80)
    base.Parent = workspace
    
    -- Left jaw
    local leftJaw = Instance.new("Part")
    leftJaw.Name = "LeftJaw"
    leftJaw.Size = Vector3.new(1.5, 0.3, 3.5)
    leftJaw.Position = position + Vector3.new(-1.2, 0.65, 0)
    leftJaw.Anchored = true
    leftJaw.CanCollide = false
    leftJaw.Material = Enum.Material.Metal
    leftJaw.Color = Color3.fromRGB(60, 60, 60)
    leftJaw.Parent = workspace
    
    -- Left teeth (spikes)
    for i = 1, 5 do
        local tooth = Instance.new("Part")
        tooth.Name = "Tooth"
        tooth.Size = Vector3.new(0.3, 1, 0.3)
        tooth.Position = leftJaw.Position + Vector3.new(0.5, 0.5, -1.5 + (i - 1) * 0.8)
        tooth.Anchored = true
        tooth.CanCollide = false
        tooth.Material = Enum.Material.Metal
        tooth.Color = Color3.fromRGB(200, 200, 200)
        tooth.Parent = leftJaw
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = leftJaw
        weld.Part1 = tooth
        weld.Parent = tooth
    end
    
    -- Right jaw
    local rightJaw = Instance.new("Part")
    rightJaw.Name = "RightJaw"
    rightJaw.Size = Vector3.new(1.5, 0.3, 3.5)
    rightJaw.Position = position + Vector3.new(1.2, 0.65, 0)
    rightJaw.Anchored = true
    rightJaw.CanCollide = false
    rightJaw.Material = Enum.Material.Metal
    rightJaw.Color = Color3.fromRGB(60, 60, 60)
    rightJaw.Parent = workspace
    
    -- Right teeth
    for i = 1, 5 do
        local tooth = Instance.new("Part")
        tooth.Name = "Tooth"
        tooth.Size = Vector3.new(0.3, 1, 0.3)
        tooth.Position = rightJaw.Position + Vector3.new(-0.5, 0.5, -1.5 + (i - 1) * 0.8)
        tooth.Anchored = true
        tooth.CanCollide = false
        tooth.Material = Enum.Material.Metal
        tooth.Color = Color3.fromRGB(200, 200, 200)
        tooth.Parent = rightJaw
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = rightJaw
        weld.Part1 = tooth
        weld.Parent = tooth
    end
    
    -- Store references
    self.base = base
    self.leftJaw = leftJaw
    self.rightJaw = rightJaw
    self.position = position
end

function BearTrap:StartTriggerCheck()
    print("🔍 Trap trigger check started at " .. tostring(self.position))
    
    self.checkLoop = task.spawn(function()
        while self.isActive and not self.isTriggered do
            task.wait(0.1) -- Check every 0.1 seconds
            
            -- Find heroes near trap
            local heroCount = 0
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name == "Hero" and obj:FindFirstChild("HumanoidRootPart") then
                    heroCount = heroCount + 1
                    local heroHRP = obj.HumanoidRootPart
                    local distance = (self.position - heroHRP.Position).Magnitude
                    
                    -- Debug: print distance if hero is nearby
                    if distance <= 10 then
                        print("🎯 Hero distance from trap: " .. math.floor(distance) .. " studs (trigger at " .. self.trapRadius .. ")")
                    end
                    
                    if distance <= self.trapRadius then
                        print("💥 TRIGGER! Hero at " .. math.floor(distance) .. " studs")
                        self:Trigger(obj)
                        break
                    end
                end
            end
            
            -- Debug every 5 seconds
            if tick() % 5 < 0.1 then
                print("🪤 Trap active, checking... (" .. heroCount .. " heroes in game)")
            end
        end
    end)
end

function BearTrap:Trigger(hero)
    if self.isTriggered then return end
    self.isTriggered = true
    
    print("🪤 SNAP! Hero caught in bear trap!")
    
    -- Snap animation (close jaws)
    local startLeft = self.leftJaw.Position
    local startRight = self.rightJaw.Position
    local targetPos = self.position + Vector3.new(0, 0.65, 0)
    
    task.spawn(function()
        for t = 0, 1, 0.1 do
            if not self.leftJaw or not self.rightJaw then break end
            
            self.leftJaw.Position = startLeft:Lerp(targetPos, t)
            self.rightJaw.Position = startRight:Lerp(targetPos, t)
            task.wait(0.02)
        end
    end)
    
    -- Damage hero
    local humanoid = hero:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:TakeDamage(25)
        print("💥 25 damage dealt!")
    end
    
    -- Trap hero (freeze in place)
    local heroHRP = hero:FindFirstChild("HumanoidRootPart")
    if heroHRP then
        -- Store original velocity
        local originalVelocity = heroHRP.AssemblyLinearVelocity
        
        -- Anchor hero
        heroHRP.Anchored = true
        
        -- Visual effect (red glow)
        local trapEffect = Instance.new("Part")
        trapEffect.Shape = Enum.PartType.Ball
        trapEffect.Size = Vector3.new(3, 3, 3)
        trapEffect.Position = heroHRP.Position
        trapEffect.Transparency = 0.7
        trapEffect.Color = Color3.fromRGB(255, 0, 0)
        trapEffect.Material = Enum.Material.Neon
        trapEffect.Anchored = true
        trapEffect.CanCollide = false
        trapEffect.Parent = workspace
        
        -- Release after 3 seconds
        task.delay(3, function()
            if heroHRP and heroHRP.Parent then
                heroHRP.Anchored = false
                print("✅ Hero released from trap")
            end
            if trapEffect and trapEffect.Parent then
                trapEffect:Destroy()
            end
        end)
        
        Debris:AddItem(trapEffect, 3)
    end
    
    -- Remove trap after use
    task.delay(0.5, function()
        self:Destroy()
    end)
end

function BearTrap:Destroy()
    self.isActive = false
    
    if self.base then self.base:Destroy() end
    if self.leftJaw then self.leftJaw:Destroy() end
    if self.rightJaw then self.rightJaw:Destroy() end
    
    print("🗑️ Bear trap removed")
end

return BearTrap
