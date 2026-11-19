local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.BottleTown.Config)
local settings = Config.Residents

local Residents = {}
local rng = Random.new()
local clearance = Vector3.new(3.2,5.15,1.7)
local clearanceOffset = Vector3.new(0,clearance.Y/2+.24,0)
local pathCheckInterval = .1
local lookAhead = 2

local function action(model,name)
 model:SetAttribute("ActionStartedAt",workspace:GetServerTimeNow())
 model:SetAttribute("Action",name)
end

local function connectRig(model)
 local root = model.Root
 model.PrimaryPart = root
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and part ~= root then
   local parent = part.Parent
   local limb = parent == model and part:FindFirstChild("JointPivot")
   local anchor = parent == model and root or parent
   local joint = Instance.new(limb and "Motor6D" or "Weld")
   joint.Name = limb and part.Name.."Joint" or "ResidentWeld"
   joint.Part0 = anchor
   joint.Part1 = part
   local pivot = limb and limb.CFrame or CFrame.identity
   joint.C0 = anchor.CFrame:ToObjectSpace(part.CFrame)*pivot
   joint.C1 = pivot
   joint.Parent = anchor
   part.Anchored = false
  end
 end
end

function Residents.start(town,discard,canDiscard)
 local routes = town.ResidentRoutes
 local folder = Instance.new("Folder")
 folder.Name = "Residents"
 folder.Parent = town
 local templates = ServerStorage.BottleTown.ResidentTemplates:GetChildren()
 table.sort(templates,function(a,b) return a.Name < b.Name end)
 local first = rng:NextInteger(1,#templates)
 local lastDrop = -math.huge

 local excluded = {folder,routes,town["Collectible bottles"]}
 local ray = RaycastParams.new()
 ray.FilterDescendantsInstances = excluded
 ray.RespectCanCollide = true
 local box = OverlapParams.new()
 box.FilterDescendantsInstances = excluded
 local pathOverlap = OverlapParams.new()

 local function obstacle(part)
  return part:IsDescendantOf(town) and (part.CanCollide or part.Name == "Canopy")
 end

 local function canStand(position)
  local floor = workspace:Raycast(position+Vector3.new(0,.21,0),Vector3.new(0,-.65,0),ray)
  if not floor or not floor.Instance.CanCollide then return false end
  local center = CFrame.new(position+clearanceOffset)
  for _,part in ipairs(workspace:GetPartBoundsInBox(center,Vector3.new(3.2,5.15,3.2),box)) do
   if obstacle(part) then return false end
  end
  return true
 end

 local function clearPath(from,displacement,retreating)
  local center = from+clearanceOffset
  local orientation = CFrame.lookAt(center,center+displacement)
  local ignore = table.clone(excluded)
  for _,player in ipairs(Players:GetPlayers()) do
   if player.Character then table.insert(ignore,player.Character) end
  end
  pathOverlap.FilterDescendantsInstances = ignore
  -- Blockcast skips objects already inside its starting volume.
  for _,part in ipairs(workspace:GetPartBoundsInBox(orientation,clearance,pathOverlap)) do
   if part.CanCollide or obstacle(part) then
    -- A retreat can leave an overlap behind, but cannot advance into it.
    if not retreating or (part.Position-center):Dot(displacement) >= 0 then return false end
   end
  end
  local sweep = RaycastParams.new()
  sweep.FilterDescendantsInstances = ignore
  -- Ignore non-solid effects without ignoring the geometry behind them.
  for _ = 1,5 do
   local hit = workspace:Blockcast(orientation,clearance,displacement,sweep)
   if not hit then return true end
   if hit.Instance.CanCollide or obstacle(hit.Instance) then return false end
   sweep:AddToFilter(hit.Instance)
  end
  return false
 end

 local function canDrop(position)
  local floor = workspace:Raycast(position+Vector3.new(0,.4,0),Vector3.new(0,-1,0),ray)
  if not floor or not floor.Instance.CanCollide then return false end
  for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(position+Vector3.new(0,.7,0)),Vector3.new(.8,1,.8),box)) do
   if obstacle(part) then return false end
  end
  return true
 end

 for order = 1,math.clamp(settings.ActiveLimit,0,#templates) do
  local template = templates[(first+order-2)%#templates+1]
  local route = routes[template.Name]:GetChildren()
  table.sort(route,function(a,b) return a.Name < b.Name end)
  local model = template:Clone()
  model:ScaleTo(Config.ResidentScale)
  connectRig(model)
  model:PivotTo(route[1].CFrame)
  model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
  action(model,"Idle")
  model.Parent = folder
  local root = model.Root
  local activeTween
  local thread
  local removed
  local lastResidentDrop = -math.huge
  local home = route[1].CFrame
  local function startTween(target,duration)
   activeTween = TweenService:Create(root,TweenInfo.new(duration,Enum.EasingStyle.Linear),{CFrame=target})
   activeTween:Play()
  end

  local function stopTween()
   if not activeTween then return end
   activeTween:Cancel()
   activeTween:Destroy()
   activeTween = nil
  end

  local function animate(target,duration)
   startTween(target,duration)
   activeTween.Completed:Wait()
   stopTween()
  end

  local function walkTo(position,retreating)
   local from = root.Position
   local displacement = position-from
   local distance = displacement.Magnitude
   if distance < .01 then return true end
   if not canStand(position) or not clearPath(from,displacement,retreating) then return false end

   local facing = CFrame.lookAt(from,position)
   animate(facing,.18)
   if not clearPath(from,displacement.Unit*math.min(distance,lookAhead),retreating) then return false end
   action(model,"Walk")
   startTween(facing+displacement,distance/settings.WalkSpeed)
   while activeTween.PlaybackState == Enum.PlaybackState.Playing do
    task.wait(pathCheckInterval)
    local remaining = position-root.Position
    local distanceLeft = remaining.Magnitude
    if distanceLeft >= .01 and not clearPath(root.Position,remaining.Unit*math.min(distanceLeft,lookAhead),retreating) then
     stopTween()
     action(model,"Idle")
     return false
    end
   end
   stopTween()
   action(model,"Idle")
   return true
  end

  removed = model.AncestryChanged:Connect(function()
   if model.Parent == folder and folder:IsDescendantOf(workspace) then return end
   removed:Disconnect()
   if thread and coroutine.status(thread) ~= "dead" then task.cancel(thread) end
   stopTween()
   if model:IsDescendantOf(workspace) then action(model,"Idle") end
  end)

  thread = task.spawn(function()
   task.wait(order*.9)
   local current,direction = 1,1
   while true do
    local nextIndex = (current+direction-1)%#route+1
    local stop = route[nextIndex]
    if not walkTo(stop.Position) then
     task.wait(2)
     if not walkTo(stop.Position) then
      -- Retreat to the last reached waypoint before changing direction.
      if walkTo(route[current].Position,true) then
       direction = -direction
      else
       task.wait(4)
       if canStand(home.Position) then
        root.CFrame = home
        current,direction = 1,1
       end
      end
      continue
     end
    end

    current = nextIndex
    local pause = stop:FindFirstChild("Pause")
    if pause then
     animate(stop.CFrame,.25)
     task.wait(pause.Value+rng:NextNumber(0,1.5))
     local drop = stop:FindFirstChild("Drop")
     local now = os.clock()
     if drop and now-lastDrop >= settings.SharedDropCooldown
      and now-lastResidentDrop >= settings.DropCooldown and rng:NextNumber() < settings.DropChance
      and canDrop(drop.Value) and canDiscard(drop.Value.X,drop.Value.Z) then
      action(model,"Discard")
      task.wait(settings.DiscardReleaseTime)
      local releaseTime = os.clock()
      if releaseTime-lastDrop >= settings.SharedDropCooldown and canDrop(drop.Value)
       and discard(drop.Value.X,drop.Value.Z) then
       lastDrop,lastResidentDrop = releaseTime,releaseTime
      end
      task.wait(settings.DiscardDuration-settings.DiscardReleaseTime)
      action(model,"Idle")
     end
    end
   end
  end)
 end
end

return Residents
