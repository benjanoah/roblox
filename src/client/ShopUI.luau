--[[
    ShopUI.luau
    Shop interface for upgrades
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local screenGui = player:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")

local ShopUI = {}

local shopFrame = nil
local isShopOpen = false

-- Events
local getShopDataEvent = ReplicatedStorage:WaitForChild("GetShopData")
local purchaseUpgradeEvent = ReplicatedStorage:WaitForChild("PurchaseUpgrade")
local shopFeedbackEvent = ReplicatedStorage:WaitForChild("ShopFeedback")

--[[
    Create shop UI
]]
function ShopUI.CreateUI()
    -- Main shop frame (center of screen)
    shopFrame = Instance.new("Frame")
    shopFrame.Name = "ShopFrame"
    shopFrame.Size = UDim2.new(0, 600, 0, 500)
    shopFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    shopFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    shopFrame.BorderSizePixel = 2
    shopFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
    shopFrame.Visible = false
    shopFrame.Parent = screenGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 60)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextSize = 32
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "🏪 UPGRADE SHOP"
    titleLabel.Parent = shopFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 50, 0, 50)
    closeButton.Position = UDim2.new(1, -55, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 28
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "✖"
    closeButton.Parent = shopFrame
    
    closeButton.MouseButton1Click:Connect(function()
        ShopUI.Close()
    end)
    
    -- Scrolling frame for upgrades
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "UpgradesScroll"
    scrollFrame.Size = UDim2.new(1, -20, 1, -80)
    scrollFrame.Position = UDim2.new(0, 10, 0, 70)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = shopFrame
    
    return scrollFrame
end

--[[
    Create upgrade button
]]
local function CreateUpgradeButton(upgradeData, index, scrollFrame)
    local button = Instance.new("TextButton")
    button.Name = "Upgrade_" .. upgradeData.Type
    button.Size = UDim2.new(1, -10, 0, 80)
    button.Position = UDim2.new(0, 5, 0, (index - 1) * 90)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.BorderSizePixel = 2
    button.BorderColor3 = Color3.fromRGB(100, 100, 100)
    button.Parent = scrollFrame
    
    -- Check if maxed out
    if upgradeData.MaxedOut then
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        button.BorderColor3 = Color3.fromRGB(0, 150, 0)
    end
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.6, 0, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 20
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = upgradeData.Name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = button
    
    -- Description label
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.6, 0, 0, 20)
    descLabel.Position = UDim2.new(0, 10, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextSize = 14
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = upgradeData.Description
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = button
    
    -- Level label
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(0.6, 0, 0, 20)
    levelLabel.Position = UDim2.new(0, 10, 0, 55)
    levelLabel.BackgroundTransparency = 1
    levelLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    levelLabel.TextSize = 12
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.Text = "Level: " .. upgradeData.CurrentLevel .. " / " .. upgradeData.MaxLevel
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = button
    
    -- Cost/Buy button
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(0.35, 0, 0, 60)
    buyButton.Position = UDim2.new(0.62, 0, 0, 10)
    buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.TextSize = 18
    buyButton.Font = Enum.Font.GothamBold
    buyButton.Parent = button
    
    if upgradeData.MaxedOut then
        buyButton.Text = "✅ MAX"
        buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        buyButton.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        buyButton.Text = "BUY\n💰 " .. upgradeData.Cost
        
        buyButton.MouseButton1Click:Connect(function()
            -- Purchase upgrade
            purchaseUpgradeEvent:FireServer(upgradeData.Type)
            
            -- Refresh shop after purchase
            task.wait(0.2)
            ShopUI.Refresh()
        end)
    end
    
    return button
end

--[[
    Refresh shop data
]]
function ShopUI.Refresh()
    if not shopFrame then return end
    
    local scrollFrame = shopFrame:FindFirstChild("UpgradesScroll")
    if not scrollFrame then return end
    
    -- Clear existing buttons
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Request shop data from server
    local upgradesData = getShopDataEvent:InvokeServer()
    
    -- Create upgrade buttons
    for index, upgradeData in ipairs(upgradesData) do
        CreateUpgradeButton(upgradeData, index, scrollFrame)
    end
    
    -- Update scroll canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #upgradesData * 90)
end

--[[
    Open shop
]]
function ShopUI.Open()
    if isShopOpen then return end
    
    if not shopFrame then
        local scrollFrame = ShopUI.CreateUI()
    end
    
    ShopUI.Refresh()
    shopFrame.Visible = true
    isShopOpen = true
    
    print("🏪 Shop opened")
end

--[[
    Close shop
]]
function ShopUI.Close()
    if not isShopOpen then return end
    
    shopFrame.Visible = false
    isShopOpen = false
    
    print("🏪 Shop closed")
end

--[[
    Toggle shop
]]
function ShopUI.Toggle()
    if isShopOpen then
        ShopUI.Close()
    else
        ShopUI.Open()
    end
end

-- Listen for shop feedback
shopFeedbackEvent.OnClientEvent:Connect(function(message)
    print("🏪 " .. message)
end)

return ShopUI
