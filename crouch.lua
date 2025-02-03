local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local tiltAngle = CFrame.Angles(0, 0, math.rad(-10))

local camera = workspace.CurrentCamera
local originalCameraCFrame = camera.CFrame 

local slideAnim = script:WaitForChild("SlidingAnim")
local success, playAnim = pcall(function()
	return humanoid:LoadAnimation(slideAnim)
end)
if not success then
	warn("Failed to load slide animation!")
	return
end
playAnim.Priority = Enum.AnimationPriority.Action4

local function createAnimation(id)
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	return humanoid:LoadAnimation(animation)
end

local crouchIdleTrack = createAnimation("rbxassetid://99082690524814") -- Crouch idle animation
local crouchWalkTrack = createAnimation("rbxassetid://139548314498660") -- Crouch walk animation
crouchIdleTrack.Priority = Enum.AnimationPriority.Action3
crouchWalkTrack.Priority = Enum.AnimationPriority.Action4

local IsSlidingBool = script:WaitForChild("IsSliding")
local isCrouching, isSliding, canSlide = false, false, true
local slide, slideStopped = nil, false
local CKey = Enum.KeyCode.C

local normalWalkSpeed, crouchWalkSpeed = 10, 5
local normalHipHeight, crouchHipHeight = humanoid.HipHeight, humanoid.HipHeight / 2
local slideVelocityMultiplier, slideDuration = 1.25, 0.75

humanoid.UseJumpPower = true
humanoid.WalkSpeed = normalWalkSpeed

-- Slide helper functions
local function slideVector(Directionvector, SurfaceNormal)
	return Directionvector + SurfaceNormal * math.abs(SurfaceNormal:Dot(Directionvector))
end

local function reflectNormal(Directionvector, SurfaceNormal)
	return Directionvector - (2 * Directionvector:Dot(SurfaceNormal) * SurfaceNormal)
end

local function resetSlide()
	humanoid.WalkSpeed = script.Parent:WaitForChild("Sprint").Sprinting.Value and 20 or normalWalkSpeed
	script.SlideSound:Stop()
	playAnim:Stop()
	IsSlidingBool.Value, isSliding, canSlide = false, false, true
	slide:Destroy()
	slide = nil
	canSlide = false
	task.wait(0.5)
	canSlide = true

	-- Reset camera tilt
	local tiltResetTween = TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(camera.CFrame.Position) * CFrame.Angles(0, 0, 0)})
	tiltResetTween:Play()
end

local function initiateSlide()
	if humanoid.FloorMaterial == Enum.Material.Air or not canSlide or isSliding or humanoid.MoveDirection.Magnitude == 0 then return end

	canSlide, isSliding, slideStopped = false, true, false
	playAnim:Play(0.2)
	script.SlideSound:Play()

	local surfaceNormal = character.HumanoidRootPart.Position.Y > 0 and Vector3.new(0, 1, 0) or Vector3.new(0, 0, 1) -- Adjust for floor or walls

	slide = Instance.new("BodyVelocity")
	slide.MaxForce = Vector3.new(1, 0, 1) * 30000
	slide.Velocity = character.HumanoidRootPart.CFrame.LookVector * (humanoid.WalkSpeed * slideVelocityMultiplier + 30)
	slide.Parent = character.HumanoidRootPart
	IsSlidingBool.Value = true

	local tiltTween = TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(camera.CFrame.Position) * tiltAngle})
	tiltTween:Play()

	local elapsedTime = 0
	while elapsedTime < slideDuration and not slideStopped do
		task.wait(0.05)
		elapsedTime += 0.05

		local direction = humanoid.MoveDirection.Unit
		if direction.Magnitude > 0 and slide then
			slide.Velocity = slideVector(direction * (humanoid.WalkSpeed * slideVelocityMultiplier + 30), surfaceNormal) 
			slide.Velocity *= math.max(1 - (elapsedTime / slideDuration), 0.2) 
		else
			if not slide then return end
			slide.Velocity *= math.max(1 - (elapsedTime / slideDuration), 0.1)
		end
	end

	resetSlide()
end


local function startCrouching()
	isCrouching = true
	script:WaitForChild("CrouchSound"):Play()
	humanoid.WalkSpeed = crouchWalkSpeed
	humanoid.HipHeight = crouchHipHeight
	crouchIdleTrack:Play(0.2) 
	script.Parent:WaitForChild("Sprint").Disabled = true
	script.IsCrouch.Value = true
	humanoid.Running:Connect(function(speed)
		if speed > 0 and isCrouching then
			if not crouchWalkTrack.IsPlaying then
				crouchWalkTrack:Play(0.2)
			end
		else
			if crouchWalkTrack.IsPlaying then
				crouchWalkTrack:Stop(0.2)
			end
		end
	end)
end

local function stopCrouching()
	isCrouching = false
	humanoid.HipHeight = normalHipHeight
	humanoid.WalkSpeed = script.Parent:WaitForChild("Sprint").Sprinting.Value and 20 or normalWalkSpeed
	crouchIdleTrack:Stop(0.2)
	crouchWalkTrack:Stop(0.2)
	script.Parent:WaitForChild("Sprint").Disabled = false
	script.IsCrouch.Value = false
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == CKey then
		if script.Parent:WaitForChild("Sprint").Sprinting.Value then
			initiateSlide()
		else
			startCrouching()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == CKey then
		if isSliding then
			resetSlide()
		else
			stopCrouching()
		end
	end
end)


player.PlayerGui:WaitForChild("MobileButtons").CrouchButton.Activated:Connect(function()
	if script.Parent:WaitForChild("Sprint").Sprinting.Value then
		initiateSlide()
	elseif isCrouching then
		stopCrouching()
	else
		startCrouching()
	end
end)

game:GetService("RunService").Heartbeat:Connect(function()
	player.PlayerGui:WaitForChild("MobileButtons").CrouchButton.ButtonText.Text = script.Parent:WaitForChild("Sprint").Sprinting.Value and "Slide" or "Crouch"
end)
