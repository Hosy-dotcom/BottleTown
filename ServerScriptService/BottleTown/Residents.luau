local Config = require(game.ReplicatedStorage.BottleTown.Config)
local Residents = {}
local rng = Random.new()
local scale = Config.ResidentScale
-- The original standing pose put the sole .14 studs above its route origin.
local standingFootOffset = .14
local routes = {
 {name="Mara", color=Color3.fromRGB(204,108,99), points={{-29,29},{-18,16},{-14,7,true},{-24,-10},{-31,7}}},
 {name="Emil", color=Color3.fromRGB(84,130,153), points={
  {49,-3},{57,1},{58,8},{53,7,true},{56,22},{63,29},{54,22},{54,15},{62,11},{59,2},
 }},
 {name="Ada", color=Color3.fromRGB(153,104,165), points={{-29,19},{-42,20,true},{-58,18},{-53,8},{-37,10}}},
}
local function makePart(model,name,size,color)
 local part = Instance.new("Part")
 part.Name = name
 part.Size = size * scale
 part.Color = color
 part.Anchored = true
 part.CanCollide = false
 part.CanQuery = false
 part.CanTouch = false
 part.Material = Enum.Material.SmoothPlastic
 part.Parent = model
 return part
end

local function offset(x,y,z)
 return CFrame.new(x*scale,y*scale,z*scale)
end

function Residents.start(town, discard)
 local folder = Instance.new("Folder",town)
 folder.Name = "Residents"
 local V = Vector3.new
 for index,route in ipairs(routes) do
  local model = Instance.new("Model",folder)
  model.Name = route.name
  local skin = Color3.fromRGB(238,187,144)
  local pants = Color3.fromRGB(57,64,77)
  local torso = makePart(model,"Coat",V(1.15,1.2,.64),route.color)
  local head = makePart(model,"Head",V(.83,.83,.83),skin)
  head.Shape = Enum.PartType.Ball
  local hair = makePart(model,"Hat",V(.88,.43,.88),pants)
  hair.Shape = Enum.PartType.Ball
  local leftLeg = makePart(model,"Left leg",V(.38,.84,.45),pants)
  local rightLeg = makePart(model,"Right leg",V(.38,.84,.45),pants)
  local leftArm = makePart(model,"Left sleeve",V(.32,.88,.42),route.color)
  local rightArm = makePart(model,"Right sleeve",V(.32,.88,.42),route.color)
  local function pose(facing,phase,walking)
   facing *= offset(0,-standingFootOffset,0)
   local swing = walking and math.sin(phase)*.38 or 0
   torso.CFrame = facing*offset(0,1.65,0)
   head.CFrame = facing*offset(0,2.64,0)
   hair.CFrame = facing*offset(0,2.94,.03)
   leftLeg.CFrame = facing*offset(-.29,.98,0)*CFrame.Angles(swing,0,0)*offset(0,-.42,0)
   rightLeg.CFrame = facing*offset(.29,.98,0)*CFrame.Angles(-swing,0,0)*offset(0,-.42,0)
   leftArm.CFrame = facing*offset(-.75,2.1,0)*CFrame.Angles(-swing,0,0)*offset(0,-.41,0)
   rightArm.CFrame = facing*offset(.75,2.1,0)*CFrame.Angles(swing,0,0)*offset(0,-.41,0)
  end
  local points = route.points
  local function position(point) return V(point[1],.14,point[2]) end
  local from = position(points[1])
  pose(CFrame.lookAt(from,position(points[2])),0,false)
  task.spawn(function()
   task.wait(index)
   local i = 2
   while true do
    local point = points[i]
    local target = position(point)
    local duration = (target-from).Magnitude/4
    local direction = (target-from).Unit
    local startTime = os.clock()
    while os.clock()-startTime < duration do
     local elapsed = os.clock()-startTime
     local current = from:Lerp(target,math.clamp(elapsed/duration,0,1))
     pose(CFrame.lookAt(current,current+direction),elapsed*9,true)
     task.wait(.04)
    end
    pose(CFrame.lookAt(target,target+direction),0,false)
    if point[3] then
     task.wait(1.4)
     if rng:NextNumber() < .65 then discard(point[1]+1.4,point[2]-.9) end
     task.wait(1)
    end
    from = target
    i = i%#points+1
   end
  end)
 end
end

return Residents
