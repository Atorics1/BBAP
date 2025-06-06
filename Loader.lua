local WorkSpace = game:FindService("Workspace")
local Ball = WorkSpace:WaitForChild("Balls")
local Players = game:FindService("Players")
local LocalPlayer = Players:GetChildren()[1]
--- MADE BY ATORICS
local MAX_DISTANCE = 120  -- Reduced max distance for more precise detection
local recentClicks = {}
local AutoClash = { clickThreshold = 2, timeWindow = 0.4 }  -- Trigger clash mode with fewer clicks and quicker window
local ClashMode = false
local ParryTime = 0.25  -- Shortened parry time window for quicker reactions
local Clicked = false
local PlayerClicked = false
local Framework = {}
local dotProductThreshold = 0.90  -- Adjusted anti-curve threshold for stricter alignment

function Framework.GetCameraPosition()
    return LocalPlayer and LocalPlayer.Character:WaitForChild("HumanoidRootPart", 1e9).CFrame.Position
end

function Framework.Targeted()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Highlight")
end

function Framework.GetCurrentBall()
    return Ball and Ball:GetChildren()[1]
end

function Framework.Parry()
    mouse1click()
    table.insert(recentClicks, tick())
end

-- Anti-curve function to check if the ball is moving straight enough towards the player
local function isBallMovingStraight(ballPos, ballVelocity, playerPos)
    if not playerPos then return false end
    
    local directionToPlayer = {
        x = playerPos.x - ballPos.x,
        y = playerPos.y - ballPos.y,
        z = playerPos.z - ballPos.z
    }

    local magnitude = math.sqrt(directionToPlayer.x ^ 2 + directionToPlayer.y ^ 2 + directionToPlayer.z ^ 2)
    directionToPlayer.x = directionToPlayer.x / magnitude
    directionToPlayer.y = directionToPlayer.y / magnitude
    directionToPlayer.z = directionToPlayer.z / magnitude
    
    local velocityMagnitude = math.sqrt(ballVelocity.x ^ 2 + ballVelocity.y ^ 2 + ballVelocity.z ^ 2)
    local normalizedVelocity = {
        x = ballVelocity.x / velocityMagnitude,
        y = ballVelocity.y / velocityMagnitude,
        z = ballVelocity.z / velocityMagnitude
    }

    -- Calculate dot product and check if it's straight enough (increased threshold)
    local dotProduct = directionToPlayer.x * normalizedVelocity.x + directionToPlayer.y * normalizedVelocity.y + directionToPlayer.z * normalizedVelocity.z
    return dotProduct > dotProductThreshold  -- Adjusted threshold for stricter alignment
end

local function HandleClicks()
    while true do
        while #recentClicks > 0 and recentClicks[1] < tick() - AutoClash.timeWindow do
            table.remove(recentClicks, 1)
        end

        if #recentClicks >= AutoClash.clickThreshold then
            ClashMode = true
        else
            ClashMode = false
        end

        if isleftpressed() then
            if not PlayerClicked then
                table.insert(recentClicks, tick())
                PlayerClicked = true  -- Prevent double-clicking
            end
        else
            PlayerClicked = false
        end
        wait()
    end
end

local function AutoParryThread()
    while true do
        local FoundBall = Framework:GetCurrentBall()
        if FoundBall then
            local CamPos = Framework:GetCameraPosition()
            local Distance = CamPos and math.sqrt((FoundBall.CFrame.Position.x - CamPos.x)^2 + (FoundBall.CFrame.Position.y - CamPos.y)^2 + (FoundBall.CFrame.Position.z - CamPos.z)^2) or 1e9
            local Velocity = math.sqrt(FoundBall.Velocity.x^2 + FoundBall.Velocity.y^2 + FoundBall.Velocity.z^2)
            local TimeToReach = Distance / Velocity
            local MovingTowardsPlayer = isBallMovingStraight(FoundBall.CFrame.Position, FoundBall.Velocity, CamPos)  -- <-- Updated this line
            if Framework:Targeted() and TimeToReach <= ParryTime and Distance <= MAX_DISTANCE and MovingTowardsPlayer then
                if ClashMode then
                    if not Clicked then  -- Only parry if it wasn't clicked recently
                        Framework:Parry()
                        Clicked = true
                    end
                else
                    if not Clicked then
                        Framework:Parry()
                        Clicked = true
                    end
                end
            else
                Clicked = false
            end
        end
        wait()
    end
end

spawn(AutoParryThread)
spawn(HandleClicks)

warn("Blade Ball AP Loaded. -Created By Atorics")
