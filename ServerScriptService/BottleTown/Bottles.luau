local Config = require(game.ReplicatedStorage.BottleTown.Config)
local Bottles = {}
local rng = Random.new()
local spots = {
 {-9,23},{9,25},{-8,4},{8,3},{-10,8},{18,8},{-7,31},{-31,12},{27,19},{23,35},
 {-31,-14},{12,-14},{28,-13},{-28,-40},{16,-41},{40,-41},{63,-14},{-59,-14},
 {54,2},{65,16},{57,25},{48,32},{75,14},{66,31},{46,-1},{54,11},{74,23},
 {-43,17},{-54,10},{-63,16},{-75,10},{-70,24},{-59,30},{-81,23},{-68,37},
 {-39,8},{42,27},{74,-4},{-77,32},{-56,21},{-2,36},{18,-7},{-19,-5},
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
 local mythicalSpawned = false
 local nextId = 0

 local function spawn(x,z,source,forcedType)
  if count >= Config.ActiveLimit then return end
  for _,position in pairs(active) do
   if (position-Vector2.new(x,z)).Magnitude < 4 then return end
  end
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
  active[model] = Vector2.new(x,z)
  count += 1
  bind(body,kind,function()
   active[model] = nil
   count -= 1
   model:Destroy()
  end)
  model.Parent = folder
 end

 local order = table.clone(spots)
 for index = #order,2,-1 do
  local swap = rng:NextInteger(1,index)
  order[index],order[swap] = order[swap],order[index]
 end
 for index = 1,20 do
  local spot = order[index]
  spawn(spot[1],spot[2],"Town",Config.Types[(index-1)%#Config.Types+1])
 end
 task.spawn(function()
  while true do
   task.wait(4)
   if count < Config.ActiveLimit-2 then
    for _ = 1,5 do
     local oldCount = count
     local spot = spots[rng:NextInteger(1,#spots)]
     spawn(spot[1],spot[2],"Town")
     if count > oldCount then break end
    end
   end
  end
 end)
 return function(x,z) spawn(x,z,"Resident") end
end

return Bottles