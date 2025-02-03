local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local shiftKey = Enum.KeyCode.LeftShift
local isSprinting = false

local walkSpeedNormal = 10
local walkSpeedSprint = 20 

local sprintAnimation = Instance.new("Animation")
sprintAnimation.AnimationId = "rbxassetid://138587596826485"
local sprintTrack = humanoid:LoadAnimation(sprintAnimation)

sprintTrack.Priority = Enum.AnimationPriority.Action4

local cd = false

local function startSprinting()
	if humanoid:GetState() == Enum.HumanoidStateType.Swimming or isSprinting or humanoid.WalkSpeed ~= 10 or cd then return end
	isSprinting = true
	if script:FindFirstChild("Sprinting") then
		script.Sprinting.Value = true
	end
	sprintTrack:Play(0.5)
	humanoid.WalkSpeed = walkSpeedSprint
end

local function stopSprinting()
	if not isSprinting then return end
	isSprinting = false
	if script:FindFirstChild("Sprinting") then
		script.Sprinting.Value = false
	end
	humanoid.WalkSpeed = walkSpeedNormal
	sprintTrack:Stop(0.5)
	cd = true
	task.wait(0.5)
	cd = false
end

game.ReplicatedStorage:WaitForChild("Events").StopSprint.Event:Connect(function()
	stopSprinting()
end)

local db = false

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if db or gameProcessed or humanoid.MoveDirection.Magnitude == 0 then return end
	if input.KeyCode == shiftKey then
		startSprinting()
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == shiftKey and not gameProcessed then
		stopSprinting()
	end
end)

player.PlayerGui:WaitForChild("MobileButtons").SprintButton.Activated:Connect(function()
	if db or humanoid.MoveDirection.Magnitude == 0 then return end
	if isSprinting then
		stopSprinting()
	else
		startSprinting()
	end
end)

humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
	local moveDirection = humanoid.MoveDirection
	local lookVector = character.PrimaryPart.CFrame.LookVector

	if moveDirection.Magnitude == 0 or moveDirection:Dot(lookVector) < -0.9 then
		if isSprinting then
			stopSprinting()
		end
	end
end)
