local RunService = game:GetService("RunService")
local settings = require(game.ReplicatedStorage.BottleTown.Config).Residents

local jointNames = {"LeftLegJoint","RightLegJoint","LeftArmJoint","RightArmJoint"}
local poseRange = 80
local interval = 1/30
local elapsed = 0
local animated = {}

local function pose(joints,leftLeg,rightLeg,leftArm,rightArm)
 joints[1].Transform = CFrame.Angles(leftLeg,0,0)
 joints[2].Transform = CFrame.Angles(rightLeg,0,0)
 joints[3].Transform = CFrame.Angles(leftArm,0,0)
 joints[4].Transform = CFrame.Angles(rightArm,0,0)
end

RunService.PreSimulation:Connect(function(dt)
 elapsed += dt
 if elapsed < interval then return end
 elapsed %= interval
 local town = workspace:FindFirstChild("BottleTown")
 local folder = town and town:FindFirstChild("Residents")
 local camera = workspace.CurrentCamera
 for model,joints in pairs(animated) do
  if not folder or model.Parent ~= folder or not joints[1].Parent then
   if model:IsDescendantOf(workspace) then pose(joints,0,0,0,0) end
   animated[model] = nil
  end
 end
 if not folder or not camera then return end
 local now = workspace:GetServerTimeNow()

 for _,model in ipairs(folder:GetChildren()) do
  local root = model:FindFirstChild("Root")
  local state = model:GetAttribute("Action")
  local nearby = root and (camera.CFrame.Position-root.Position).Magnitude <= poseRange
  if not nearby or state == "Idle" then
   if animated[model] then
    pose(animated[model],0,0,0,0)
    animated[model] = nil
   end
   continue
  end
  local joints = animated[model]
  if not joints then
   joints = {}
   for index,name in ipairs(jointNames) do joints[index] = root:FindFirstChild(name) end
   if not (joints[1] and joints[2] and joints[3] and joints[4]) then continue end
   animated[model] = joints
  end
  local phase = math.max(0,now-(model:GetAttribute("ActionStartedAt") or now))
  if state == "Walk" then
   local swing = math.sin(phase*9)*.38*math.min(1,phase/.18)
   pose(joints,swing,-swing,-swing,swing)
  elseif state == "Discard" then
   local windup = phase/settings.DiscardReleaseTime
   local followThrough = (settings.DiscardDuration-phase)/(settings.DiscardDuration-settings.DiscardReleaseTime)
   local flick = math.sin(math.pi/2*math.clamp(math.min(windup,followThrough),0,1))^.65
   pose(joints,0,0,-.15*flick,.9*flick)
  end
 end
end)
