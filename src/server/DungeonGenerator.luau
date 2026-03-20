--[[
    DungeonGenerator.luau
    Procedural dungeon generation system
]]

local DungeonGenerator = {}

-- Grid settings
local GRID_SIZE = 100 -- 100x100 studs
local CELL_SIZE = 4 -- Each grid cell = 4 studs
local GRID_WIDTH = GRID_SIZE / CELL_SIZE -- 25 cells
local GRID_HEIGHT = GRID_SIZE / CELL_SIZE -- 25 cells

-- Room settings
local MIN_ROOM_SIZE = 3 -- Min 3x3 cells
local MAX_ROOM_SIZE = 7 -- Max 7x7 cells
local NUM_ROOMS = 8 -- Number of rooms to generate

-- Materials
local FLOOR_COLOR = Color3.fromRGB(60, 60, 60)
local WALL_COLOR = Color3.fromRGB(40, 40, 40)
local WALL_HEIGHT = 6

-- Grid (0 = empty, 1 = floor, 2 = wall)
local grid = {}

-- Room data
local rooms = {}

--[[
    Initialize empty grid
]]
local function InitGrid()
    grid = {}
    for x = 1, GRID_WIDTH do
        grid[x] = {}
        for y = 1, GRID_HEIGHT do
            grid[x][y] = 0
        end
    end
end

--[[
    Check if room fits in grid
]]
local function CanPlaceRoom(x, y, width, height)
    if x < 1 or y < 1 or x + width > GRID_WIDTH or y + height > GRID_HEIGHT then
        return false
    end
    
    -- Check if area is empty (with 1 cell padding)
    for rx = x - 1, x + width do
        for ry = y - 1, y + height do
            if rx >= 1 and ry >= 1 and rx <= GRID_WIDTH and ry <= GRID_HEIGHT then
                if grid[rx][ry] ~= 0 then
                    return false
                end
            end
        end
    end
    
    return true
end

--[[
    Place a room in the grid
]]
local function PlaceRoom(x, y, width, height)
    for rx = x, x + width - 1 do
        for ry = y, y + height - 1 do
            grid[rx][ry] = 1 -- Floor
        end
    end
    
    table.insert(rooms, {
        x = x,
        y = y,
        width = width,
        height = height,
        centerX = x + math.floor(width / 2),
        centerY = y + math.floor(height / 2)
    })
end

--[[
    Generate random rooms
]]
local function GenerateRooms()
    rooms = {}
    
    for i = 1, NUM_ROOMS do
        local placed = false
        local attempts = 0
        
        while not placed and attempts < 100 do
            local width = math.random(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
            local height = math.random(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
            local x = math.random(2, GRID_WIDTH - width - 1)
            local y = math.random(2, GRID_HEIGHT - height - 1)
            
            if CanPlaceRoom(x, y, width, height) then
                PlaceRoom(x, y, width, height)
                placed = true
            end
            
            attempts = attempts + 1
        end
    end
    
    print("🏛️ Generated " .. #rooms .. " rooms")
end

--[[
    Create horizontal corridor
]]
local function CreateHorizontalCorridor(x1, x2, y)
    local startX = math.min(x1, x2)
    local endX = math.max(x1, x2)
    
    for x = startX, endX do
        if x >= 1 and x <= GRID_WIDTH and y >= 1 and y <= GRID_HEIGHT then
            if grid[x][y] == 0 then
                grid[x][y] = 1 -- Floor
            end
        end
    end
end

--[[
    Create vertical corridor
]]
local function CreateVerticalCorridor(y1, y2, x)
    local startY = math.min(y1, y2)
    local endY = math.max(y1, y2)
    
    for y = startY, endY do
        if x >= 1 and x <= GRID_WIDTH and y >= 1 and y <= GRID_HEIGHT then
            if grid[x][y] == 0 then
                grid[x][y] = 1 -- Floor
            end
        end
    end
end

--[[
    Connect rooms with corridors
]]
local function ConnectRooms()
    for i = 1, #rooms - 1 do
        local roomA = rooms[i]
        local roomB = rooms[i + 1]
        
        -- L-shaped corridor
        if math.random() > 0.5 then
            -- Horizontal then vertical
            CreateHorizontalCorridor(roomA.centerX, roomB.centerX, roomA.centerY)
            CreateVerticalCorridor(roomA.centerY, roomB.centerY, roomB.centerX)
        else
            -- Vertical then horizontal
            CreateVerticalCorridor(roomA.centerY, roomB.centerY, roomA.centerX)
            CreateHorizontalCorridor(roomA.centerX, roomB.centerX, roomB.centerY)
        end
    end
    
    print("🚪 Connected rooms with corridors")
end

--[[
    Place walls around floors
]]
local function PlaceWalls()
    local wallGrid = {}
    for x = 1, GRID_WIDTH do
        wallGrid[x] = {}
        for y = 1, GRID_HEIGHT do
            wallGrid[x][y] = grid[x][y]
        end
    end
    
    for x = 1, GRID_WIDTH do
        for y = 1, GRID_HEIGHT do
            if grid[x][y] == 1 then -- If floor
                -- Check adjacent cells for walls
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        local nx = x + dx
                        local ny = y + dy
                        
                        if nx >= 1 and nx <= GRID_WIDTH and ny >= 1 and ny <= GRID_HEIGHT then
                            if grid[nx][ny] == 0 then -- Empty space
                                wallGrid[nx][ny] = 2 -- Wall
                            end
                        end
                    end
                end
            end
        end
    end
    
    grid = wallGrid
    print("🧱 Placed walls")
end

--[[
    Build dungeon in workspace
]]
local function BuildDungeon()
    -- Clear old dungeon and map
    local oldDungeon = workspace:FindFirstChild("Dungeon")
    if oldDungeon then
        oldDungeon:Destroy()
    end
    
    local oldFloor = workspace:FindFirstChild("Floor")
    if oldFloor then
        oldFloor:Destroy()
    end
    
    local oldHeroSpawn = workspace:FindFirstChild("HeroSpawn")
    if oldHeroSpawn then
        oldHeroSpawn:Destroy()
    end
    
    local oldTreasure = workspace:FindFirstChild("Treasure")
    if oldTreasure then
        oldTreasure:Destroy()
    end
    
    local oldExit = workspace:FindFirstChild("Exit")
    if oldExit then
        oldExit:Destroy()
    end
    
    local dungeon = Instance.new("Folder")
    dungeon.Name = "Dungeon"
    dungeon.Parent = workspace
    
    local floorFolder = Instance.new("Folder")
    floorFolder.Name = "Floor"
    floorFolder.Parent = dungeon
    
    local wallFolder = Instance.new("Folder")
    wallFolder.Name = "Walls"
    wallFolder.Parent = dungeon
    
    -- Build from grid
    for x = 1, GRID_WIDTH do
        for y = 1, GRID_HEIGHT do
            local cellType = grid[x][y]
            
            if cellType == 1 then -- Floor
                local floor = Instance.new("Part")
                floor.Name = "Floor"
                floor.Size = Vector3.new(CELL_SIZE, 0.5, CELL_SIZE)
                floor.Position = Vector3.new(x * CELL_SIZE - GRID_SIZE/2, 0, y * CELL_SIZE - GRID_SIZE/2)
                floor.Anchored = true
                floor.Color = FLOOR_COLOR
                floor.Material = Enum.Material.Slate
                floor.Parent = floorFolder
                
            elseif cellType == 2 then -- Wall
                local wall = Instance.new("Part")
                wall.Name = "Wall"
                wall.Size = Vector3.new(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
                wall.Position = Vector3.new(x * CELL_SIZE - GRID_SIZE/2, WALL_HEIGHT/2, y * CELL_SIZE - GRID_SIZE/2)
                wall.Anchored = true
                wall.Color = WALL_COLOR
                wall.Material = Enum.Material.Brick
                wall.Parent = wallFolder
            end
        end
    end
    
    -- Place Treasure in center of first room (player spawn)
    if #rooms > 0 then
        local room = rooms[1]
        local treasure = Instance.new("Part")
        treasure.Name = "Treasure"
        treasure.Size = Vector3.new(3, 3, 3)
        treasure.Position = Vector3.new(
            room.centerX * CELL_SIZE - GRID_SIZE/2,
            2,
            room.centerY * CELL_SIZE - GRID_SIZE/2
        )
        treasure.Anchored = true
        treasure.Color = Color3.fromRGB(255, 215, 0) -- Gold
        treasure.Material = Enum.Material.Neon
        treasure.Parent = dungeon
        
        print("💎 Treasure placed in center room")
    end
    
    -- Place Exit in a random far room
    if #rooms >= 3 then
        local exitRoom = rooms[#rooms] -- Last room (furthest)
        local exit = Instance.new("Part")
        exit.Name = "Exit"
        exit.Size = Vector3.new(4, 0.5, 4)
        exit.Position = Vector3.new(
            exitRoom.centerX * CELL_SIZE - GRID_SIZE/2,
            0.5,
            exitRoom.centerY * CELL_SIZE - GRID_SIZE/2
        )
        exit.Anchored = true
        exit.Color = Color3.fromRGB(0, 255, 0) -- Green
        exit.Material = Enum.Material.Neon
        exit.Transparency = 0.5
        exit.Parent = dungeon
        
        print("🚪 Exit placed in far room")
    end
    
    print("🏗️ Dungeon built in workspace!")
end

--[[
    Get player spawn position (center of first room)
]]
function DungeonGenerator.GetPlayerSpawn()
    if #rooms > 0 then
        local room = rooms[1]
        local worldX = room.centerX * CELL_SIZE - GRID_SIZE/2
        local worldZ = room.centerY * CELL_SIZE - GRID_SIZE/2
        return Vector3.new(worldX, 3, worldZ)
    end
    
    return Vector3.new(0, 3, 0) -- Fallback
end

--[[
    Get random hero spawn positions
]]
function DungeonGenerator.GetHeroSpawns(count)
    local spawns = {}
    
    -- Use rooms 2+ for hero spawns
    for i = 1, count do
        local roomIndex = math.random(2, math.max(2, #rooms))
        local room = rooms[roomIndex]
        
        -- Random position within room
        local rx = math.random(room.x, room.x + room.width - 1)
        local ry = math.random(room.y, room.y + room.height - 1)
        
        local worldX = rx * CELL_SIZE - GRID_SIZE/2
        local worldZ = ry * CELL_SIZE - GRID_SIZE/2
        
        table.insert(spawns, Vector3.new(worldX, 3, worldZ))
    end
    
    return spawns
end

--[[
    Generate complete dungeon
]]
function DungeonGenerator.Generate()
    print("🎲 Generating random dungeon...")
    
    InitGrid()
    GenerateRooms()
    ConnectRooms()
    PlaceWalls()
    BuildDungeon()
    
    print("✅ Dungeon generation complete!")
    return true
end

return DungeonGenerator
