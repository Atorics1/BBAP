local WorkSpace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BallFolder = WorkSpace:WaitForChild("Balls")
local LocalPlayer = Players.LocalPlayer
local MAX_DISTANCE = 150
local ParryTime = 0.45 -- slightly tighter
local recentClicks = {}
local AutoClash = { clickThreshold = 3, timeWindow = 0.5 }
local ClashMode = false
local Clicked = false
local PlayerClicked = false

-- utils
local function getCameraPos()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position
end

local function isTargeted()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Highlight")
end

local function getCurrentBall()
    return BallFolder:GetChildren()[1]
end

local function parry()
    mouse1click()
    table.insert(recentClicks, tick())
end

local function isBallHeadingToPlayer(ballPos, ballVel, playerPos)
    if not playerPos then return false end

    local dirToPlayer = (playerPos - ballPos).Unit
    local velUnit = ballVel.Magnitude > 0 and ballVel.Unit or Vector3.zero
    return dirToPlayer:Dot(velUnit) > 0.25
end

-- check recent clicks
task.spawn(function()
    while true do
        local now = tick()
        while #recentClicks > 0 and recentClicks[1] < now - AutoClash.timeWindow do
            table.remove(recentClicks, 1)
        end

        ClashMode = #recentClicks >= AutoClash.clickThreshold

        if isleftpressed() then
            if not PlayerClicked then
                table.insert(recentClicks, now)
                PlayerClicked = true
            end
        else
            PlayerClicked = false
        end

        task.wait(0.01)
    end
end)

-- parry check (runs every frame, faster than wait())
RunService.RenderStepped:Connect(function()
    local ball = getCurrentBall()
    local camPos = getCameraPos()

    if not ball or not camPos then return end

    local distance = (ball.Position - camPos).Magnitude
    local velocity = ball.Velocity.Magnitude
    local timeToReach = velocity > 0 and distance / velocity or 1e9
    local movingToPlayer = isBallHeadingToPlayer(ball.Position, ball.Velocity, camPos)

    if isTargeted() and timeToReach <= ParryTime and distance <= MAX_DISTANCE and movingToPlayer then
        if ClashMode or not Clicked then
            parry()
            Clicked = true
        end
    else
        Clicked = false
    end
end)

warn("✅ Blade Ball AutoParry Loaded (Optimized)")
