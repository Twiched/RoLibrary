-- CustomPathfinding.lua (Client-Side Version)
local CustomPathfinding = { Agents = {} }

-- Configuration
local JUMP_HEIGHT = 7
local CHECK_RADIUS = 5
local WAYPOINT_REACHED_DISTANCE = 2

-- Helper Functions
local function getNeighbors(position)
    local neighbors = {}
    local directions = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1),
        Vector3.new(1, 0, 1),
        Vector3.new(-1, 0, -1),
        Vector3.new(1, 0, -1),
        Vector3.new(-1, 0, 1),
    }
    for _, dir in pairs(directions) do
        table.insert(neighbors, position + dir * CHECK_RADIUS)
    end
    return neighbors
end

local function isObstacle(position)
    local parts = workspace:FindPartsInRegion3(Region3.new(position - Vector3.new(1, 1, 1), position + Vector3.new(1, 1, 1)), nil, math.huge)
    for _, part in pairs(parts) do
        if part.CanCollide and part.Name ~= "Terrain" then
            return true
        end
    end
    return false
end

local function canJump(start, target)
    local heightDifference = target.Y - start.Y
    return heightDifference > 0 and heightDifference <= JUMP_HEIGHT
end

-- Pathfinding Algorithm (A*)
local function aStar(start, goal)
    local openSet = {start}
    local cameFrom = {}
    local gScore = {[start] = 0}
    local fScore = {[start] = (goal - start).Magnitude}

    while #openSet > 0 do
        table.sort(openSet, function(a, b) return fScore[a] < fScore[b] end)
        local current = table.remove(openSet, 1)

        if (current - goal).Magnitude < WAYPOINT_REACHED_DISTANCE then
            local path = {}
            while cameFrom[current] do
                table.insert(path, 1, current)
                current = cameFrom[current]
            end
            table.insert(path, 1, start)
            return path
        end

        for _, neighbor in pairs(getNeighbors(current)) do
            if not isObstacle(neighbor) or canJump(current, neighbor) then
                local tentativeGScore = gScore[current] + (neighbor - current).Magnitude
                if not gScore[neighbor] or tentativeGScore < gScore[neighbor] then
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + (goal - neighbor).Magnitude
                    if not table.find(openSet, neighbor) then
                        table.insert(openSet, neighbor)
                    end
                end
            end
        end
    end
    return nil -- No path found
end

-- Public API Methods
function CustomPathfinding.CreateAgent(agent)
    local self = {
        agent = agent,
        humanoid = agent:FindFirstChildOfClass("Humanoid"),
        path = {},
        currentWaypoint = 1,
        isMoving = false
    }

    function self:ComputeAsync(targetPos)
        local startPos = self.agent.PrimaryPart.Position
        self.path = aStar(startPos, targetPos)
        self.currentWaypoint = 1
        return self.path
    end

    function self:Start()
        self.isMoving = true
        while self.isMoving and self.humanoid do
            if self.currentWaypoint > #self.path then
                self.isMoving = false
                break
            end
            local waypoint = self.path[self.currentWaypoint]
            self.humanoid:MoveTo(waypoint)
            if (self.agent.PrimaryPart.Position - waypoint).Magnitude < WAYPOINT_REACHED_DISTANCE then
                self.currentWaypoint += 1
            end
            wait(0.1)
        end
    end

    function self:GotoPos(targetPos)
        self:ComputeAsync(targetPos)
        self:Start()
    end

    return self
end

return CustomPathfinding
