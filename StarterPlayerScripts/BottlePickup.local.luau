local Players = game:GetService("Players")
local Prompts = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Shared = game.ReplicatedStorage:WaitForChild("BottleTown")
local Settings = require(Shared:WaitForChild("Config")).Pickup
local player = Players.LocalPlayer
local active
local nextId = 0
local requests = Shared:WaitForChild("PickupRequest")
local cachedCharacter
local track
local reach
local resetPose
local restorePose
local releasedAt
local sound = Instance.new("Sound")
sound.Volume = Settings.Volume
sound.Parent = SoundService

local function clearPose()
 if not reach then return end
 restorePose()
 reach:Disconnect()
 resetPose:Disconnect()
 reach,resetPose,restorePose,releasedAt = nil,nil,nil,nil
end

local function endHold(immediate)
 active = nil
 if track then track:Stop(.12) end
 if immediate then
  clearPose()
 elseif reach and not releasedAt then
  releasedAt = os.clock()
 end
end

local function preview(character,rig)
 local isR15 = rig == "R15"
 local shoulder = character:FindFirstChild(isR15 and "RightShoulder" or "Right Shoulder",true)
 local joints = {{joint=shoulder,angle=.48}}
 if isR15 then
  table.insert(joints,{joint=character:FindFirstChild("Waist",true),angle=-.43})
  table.insert(joints,{joint=character:FindFirstChild("RightElbow",true),angle=-.16})
  table.insert(joints,{joint=character:FindFirstChild("Neck",true),angle=-.08})
 end
 local start = os.clock()
 local function restore()
  for _,entry in ipairs(joints) do
   if entry.base and entry.joint.Parent then entry.joint.Transform = entry.base end
   entry.base = nil
  end
 end
 resetPose = RunService.PreAnimation:Connect(restore)
 reach = RunService.PreSimulation:Connect(function()
  local now = os.clock()
  local weight = math.min(1,((releasedAt or now)-start)/.25)
  weight = weight*weight*(3-2*weight)
  if releasedAt then
   weight *= math.max(0,1-(now-releasedAt)/.12)
   if weight <= 0 then clearPose() return end
  end
  for _,entry in ipairs(joints) do
   local joint = entry.joint
   if joint and (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) and joint.Parent then
    entry.base = joint.Transform
    joint.Transform *= CFrame.Angles(entry.angle*weight,0,0)
   end
  end
 end)
 return restore
end

Prompts.PromptButtonHoldBegan:Connect(function(prompt)
 if not prompt:GetAttribute("BottlePickup") then return end
 if active then requests:FireServer("cancel",active.id) end
 endHold(true)
 nextId += 1
 active = {prompt=prompt,id=nextId}
 requests:FireServer("begin",nextId,prompt)
 local character = player.Character
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 if not humanoid then return end
 if cachedCharacter ~= character then
  if track then track:Destroy() track = nil end
  cachedCharacter = character
  local animator = humanoid:FindFirstChildOfClass("Animator")
  local id = Settings.AnimationIds[humanoid.RigType.Name]
  if animator and id then
   local clip = Instance.new("Animation")
   clip.AnimationId = id
   local ok,loaded = pcall(animator.LoadAnimation,animator,clip)
   clip:Destroy()
   if ok then track = loaded track.Priority = Enum.AnimationPriority.Action end
  end
 end
 if track then track:Play(.12) else restorePose = preview(character,humanoid.RigType.Name) end
end)

local function cancelActive()
 if not active then return end
 requests:FireServer("cancel",active.id)
 endHold()
end

Prompts.PromptButtonHoldEnded:Connect(function(prompt)
 local attempt = active
 if not attempt or attempt.prompt ~= prompt then return end
 -- Native completion can emit HoldEnded and Triggered in the same update.
 task.defer(function()
  if active == attempt then cancelActive() end
 end)
end)
Prompts.PromptHidden:Connect(function(prompt)
 if active and active.prompt == prompt then cancelActive() end
end)
Prompts.PromptTriggered:Connect(function(prompt)
 if not active or active.prompt ~= prompt then return end
 requests:FireServer("finish",active.id)
 endHold()
end)
player.CharacterRemoving:Connect(function()
 cancelActive()
 endHold(true)
 if track then track:Destroy() track = nil end
 cachedCharacter = nil
end)
Shared:WaitForChild("Feedback").OnClientEvent:Connect(function(_,_,payload)
 if not payload or payload.kind ~= "pickup" then return end
 if active and active.id == payload.attemptId then endHold() end
 if payload.state == "success" then
  local id = Settings.SoundIds[payload.sound] or Settings.SoundIds.General
  if id then sound.SoundId = id sound:Play() end
 end
end)
