local Config = require(game.ReplicatedStorage.BottleTown.Config)
local Bottles = {}
local rng = Random.new()
local zones = {
 {name="Town", spots={
  {-9,23},{9,25},{-8,4},{8,3},{-10,8},{18,8},{-7,31},{-31,12},{27,19},{23,35},
  {-31,-14},{12,-14},{28,-13},{-28,-40},{16,-41},{40,-41},{63,-14},{-59,-14},
  {-2,36},{18,-7},{-19,-5},
 }},
 {name="Park", spots={
  {54,2},{65,16},{57,25},{48,32},{75,14},{66,31},{46,-1},{54,11},{74,23},{42,27},{74,-4},
 }},
 {name="Meadow", spots={
  {-43,17},{-54,10},{-63,16},{-75,10},{-70,24},{-59,30},{-81,23},{-68,37},{-39,8},{-77,32},{-56,21},
 }},
}

local function cylinder(model, name, root, offset, width, length, color, material)
 local part = Instance.new("Part")
 part.Name = name
 part.Shape = Enum.PartType.Cylinder
 part.Size = Vector3.new(length, width, width)
 part.CFrame = root * CFrame.new(0,offset,0) * CFrame.Angles(0,0,math.pi/2)
 part.Color = color
 part.Material = material
 part.Anchored = true
 part.CanCollide = false
 part.CanTouch = false
 part.Parent = model
 return part
end

function Bottles.start(town, bind)
 local folder = Instance.new("Folder",town)
 folder.Name = "Collectible bottles"
 local active = {}
 local count = 0
 local countsBySource = {Resident=0}
 local ambientTarget = 0
 for _,zone in ipairs(zones) do
  countsBySource[zone.name] = 0
  ambientTarget += Config.BottleZoneTargets[zone.name]
 end
 local mythicalSpawned = false
 local nextId = 0

 local function forget(model)
  local entry = active[model]
  if not entry then return end
  active[model] = nil
  count -= 1
  countsBySource[entry.source] -= 1
  entry.unregister()
 end
 folder.ChildRemoved:Connect(forget)

 local function canSpawn(position)
  if count >= Config.ActiveLimit then return false end
  for _,entry in pairs(active) do
   if (entry.position-position).Magnitude < 4 then return false end
  end
  return true
 end

 local function spawn(x,z,source,forcedType)
  local position = Vector2.new(x,z)
  if not canSpawn(position) then return end
  local mythical = not forcedType and not mythicalSpawned and rng:NextInteger(1,1800) == 1
  local kind = mythical and Config.Mythical or (forcedType or Config.Types[rng:NextInteger(1,#Config.Types)])
  if mythical then mythicalSpawned = true end
  local model = Instance.new("Model")
  nextId += 1
  model.Name = string.format("Bottle_%04d",nextId)
  model:SetAttribute("BottleType",kind.name)
  model:SetAttribute("SpawnSource",source)
  local size = kind.size
  local root = CFrame.new(x,.42*size+.16,z) * CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0) * CFrame.Angles(0,0,.22)
  local material = mythical and Enum.Material.Neon or Enum.Material.SmoothPlastic
  local body = cylinder(model,"Body",root,0,.58*size,.78*size,kind.color,material)
  cylinder(model,"Label",root,.03*size,.593*size,.29*size,kind.label,material)
  cylinder(model,"Shoulder",root,.40*size,.46*size,.18*size,kind.color,material)
  cylinder(model,"Neck",root,.53*size,.25*size,.2*size,kind.color,material)
  cylinder(model,"Cap",root,.66*size,.3*size,.13*size,kind.label,material)
  model.PrimaryPart = body
  local highlight = Instance.new("Highlight",model)
  highlight.DepthMode = Enum.HighlightDepthMode.Occluded
  highlight.FillTransparency = mythical and .58 or 1
  highlight.OutlineColor = kind.label
  highlight.OutlineTransparency = .24
  if mythical then
   local light = Instance.new("PointLight",body)
   light.Color = kind.color
   light.Range = 13
   light.Brightness = 2
  end
  local unregister = bind(body,kind,function()
   forget(model)
   model:Destroy()
  end,folder)
  active[model] = {position=position,source=source,unregister=unregister}
  count += 1
  countsBySource[source] += 1
  model.Parent = folder
  return true
 end

 local nextZone = 1
 local function refill(forcedType)
  if count >= Config.ActiveLimit then return end
  for offset = 0,#zones-1 do
   local index = (nextZone+offset-1)%#zones+1
   local zone = zones[index]
   if countsBySource[zone.name] < Config.BottleZoneTargets[zone.name] then
    -- Try each authored spot once so a crowded zone cannot stall a refill.
    local start = rng:NextInteger(1,#zone.spots)
    for step = 0,#zone.spots-1 do
     local spot = zone.spots[(start+step-1)%#zone.spots+1]
     if spawn(spot[1],spot[2],zone.name,forcedType) then
      nextZone = index%#zones+1
      return true
     end
    end
   end
  end
 end

 local startingTypes = {}
 for index = 1,math.min(ambientTarget,Config.ActiveLimit) do
  startingTypes[index] = Config.Types[(index-1)%#Config.Types+1]
 end
 for index = #startingTypes,2,-1 do
  local swap = rng:NextInteger(1,index)
  startingTypes[index],startingTypes[swap] = startingTypes[swap],startingTypes[index]
 end
 for _,kind in ipairs(startingTypes) do
  if not refill(kind) then break end
 end

 task.spawn(function()
  while true do
   task.wait(Config.BottleRefillInterval)
   refill()
  end
 end)
 local function discard(x,z)
  if countsBySource.Resident < Config.ResidentBottleLimit then
   return spawn(x,z,"Resident") == true
  end
  return false
 end
 local function canDiscard(x,z)
  return countsBySource.Resident < Config.ResidentBottleLimit and canSpawn(Vector2.new(x,z))
 end
 return discard,canDiscard
end

return Bottles
