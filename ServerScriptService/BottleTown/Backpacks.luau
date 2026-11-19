local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.BottleTown.Config).BackpackVisuals

local Inventory = require(script.Parent.Inventory)

local Backpacks = {}
local accessoryName = "BottleTown Backpack"
local referenceTorso = Vector2.new(2,1.67)

local function addBottle(parent,handle,kind,offset,scale)
 local model = Instance.new("Model")
 model.Name = kind.id
 model.Parent = parent
 local size = math.clamp(kind.size,.84,1.10)*scale
 local shape = kind.shape
 local isCan = shape == "Can"
 local glass = shape == "Glass"
 local width = isCan and .245 or glass and .212 or .228
 local material = isCan and Enum.Material.Metal or glass and Enum.Material.Glass or Enum.Material.SmoothPlastic
 local function cylinder(name,height,length,diameter,color,surface,alpha)
  local part = Instance.new("Part")
  part.Name = name
  part.Shape = Enum.PartType.Cylinder
  part.Size = Vector3.new(length,diameter,diameter)*size
  part.Color = color
  part.Material = surface or material
  part.Transparency = alpha or 0
  part.Massless = true
  part.CanCollide = false
  part.CanTouch = false
  part.CanQuery = false
  local relative = offset*CFrame.new(0,height*size,0)*CFrame.Angles(0,0,math.pi/2)
  part.CFrame = handle.CFrame*relative
  part.Parent = model
  local weld = Instance.new("Weld")
  weld.C0 = relative
  weld.Part0 = handle
  weld.Part1 = part
  weld.Parent = part
 end
 cylinder("Body",0,isCan and .39 or .41,width,kind.color,nil,glass and .15 or 0)
 cylinder("Label",-.035,.13,width+.003,kind.label,Enum.Material.SmoothPlastic)
 if isCan then
  local rim = Color3.fromRGB(188,194,198)
  for _,height in ipairs({-.195,.195}) do
   cylinder("Rim",height,.028,width+.008,rim)
  end
 else
  cylinder("Shoulder",.213,.065,width*.72,kind.color,nil,glass and .15 or 0)
  cylinder("Neck",glass and .283 or .256,glass and .123 or .068,width*(glass and .44 or .54),kind.color)
  cylinder("Cap",glass and .347 or .298,.042,width*.61,kind.label,Enum.Material.SmoothPlastic)
 end
 return model
end

local function clearance(character,torso)
 local offset = 0
 for _,item in ipairs(character:GetChildren()) do
  if item:IsA("Accessory") and item.Name ~= accessoryName then
   local handle = item:FindFirstChild("Handle")
   if handle and handle:IsA("BasePart") and handle:FindFirstChild("BodyBackAttachment") then
    local extent = torso.CFrame:PointToObjectSpace(handle.Position).Z+handle.Size.Z/2-torso.Size.Z/2
    offset = math.max(offset,math.clamp(extent,0,.18))
   end
  end
 end
 return offset
end

local function fit(template,humanoid,torso,back,scale,offset,style)
 local assembly = template:Clone()
 assembly:ScaleTo(scale)
 local accessory = assembly.Accessory
 local handle = accessory.Handle
 local attachment = handle.BodyBackAttachment
 attachment.Position = Vector3.new(0,0,-offset)
 local anchor = back and back.CFrame or CFrame.new(0,-torso.Size.Y*.125,torso.Size.Z/2)
 local origin = handle.CFrame
 local target = torso.CFrame*anchor*attachment.CFrame:Inverse()

 for _,part in ipairs(accessory:GetDescendants()) do
  if part:IsA("BasePart") then
   local relative = origin:ToObjectSpace(part.CFrame)
   part.CFrame = target*relative
   part.Anchored = false
   part.Massless = true
   part.CanCollide = false
   part.CanTouch = false
   part.CanQuery = false
   if style[part.Name] then part.Color = style[part.Name] end
   if part.Name == "Window" then part.Transparency = style.WindowTransparency end
   if part ~= handle then
    local weld = Instance.new("Weld")
    weld.C0 = relative
    weld.Part0 = handle
    weld.Part1 = part
    weld.Parent = part
   end
  end
 end

 accessory.Name = accessoryName
 if back then humanoid:AddAccessory(accessory) end
 local weld = handle:FindFirstChild("AccessoryWeld")
 if not weld or weld.Part1 ~= torso then
  if weld then weld:Destroy() end
  accessory.Parent = humanoid.Parent
  local manual = Instance.new("Weld")
  manual.Name = "BackpackFitWeld"
  manual.Part0 = handle
  manual.Part1 = torso
  manual.C0 = attachment.CFrame
  manual.C1 = anchor
  manual.Parent = handle
 end
 assembly:Destroy()
 return accessory
end

function Backpacks.start()
 local templates = ServerStorage.BottleTown.BackpackTemplates
 local players = {}
 local function added(player)
  if players[player] then return end
  local state = {style=Config.DefaultStyle,connections={}}
  players[player] = state

  local function detach()
   local old = state.character
   state.character = nil
   if not old then return end
   for _,connection in ipairs(old.connections) do connection:Disconnect() end
   if old.accessory then old.accessory:Destroy() end
  end

  local function changed(character)
   if state.character and state.character.model == character then return end
   detach()
   local view = {model=character,connections={}}
   state.character = view
   local humanoid = character:WaitForChild("Humanoid",8)
   if not humanoid then return end
   local torso = character:WaitForChild(humanoid.RigType == Enum.HumanoidRigType.R15 and "UpperTorso" or "Torso",8)
   if not torso or state.character ~= view then return end
   local function refresh()
    view.queued = false
    if state.character ~= view or humanoid.Health <= 0 then return end
    local capacity = player:GetAttribute("BagCapacity")
    local template = capacity and templates:FindFirstChild(Config.TemplatesByCapacity[capacity] or "Starter")
    if not template then return end
    local back = torso:FindFirstChild("BodyBackAttachment")
    local scale = math.clamp(math.min(torso.Size.X/referenceTorso.X,torso.Size.Y/referenceTorso.Y),.6,1.3)
    local offset = clearance(character,torso)
    if not view.accessory or view.accessory.Parent ~= character or view.template ~= template
     or view.scale ~= scale or view.offset ~= offset or view.back ~= back then
     -- Fit before removing the visible bag so a failed rebuild can't strip it.
     local replacement = fit(template,humanoid,torso,back,scale,offset,Config.Styles[state.style])
     if view.accessory then view.accessory:Destroy() end
     view.accessory,view.bottles = replacement,{}
     view.template,view.scale,view.offset,view.back = template,scale,offset,back
    end
    local contents = Inventory.backpackContents(player)
    local accessory = view.accessory
    local handle = accessory.Handle
    for index = #view.bottles, #contents+1,-1 do
     view.bottles[index].model:Destroy()
     view.bottles[index] = nil
    end
    for index,kind in ipairs(contents) do
     local bottle = view.bottles[index]
     if not bottle or bottle.kind ~= kind then
      if bottle then bottle.model:Destroy() end
      local mount = handle["Bottle"..index]
      view.bottles[index] = {
       kind=kind,model=addBottle(accessory.Bottles,handle,kind,mount.CFrame,scale),
      }
     end
    end
   end
   local function queue()
    if view.queued then return end
    view.queued = true
    task.defer(refresh)
   end
   view.queue = queue
   table.insert(view.connections,torso:GetPropertyChangedSignal("Size"):Connect(queue))
   table.insert(view.connections,player:GetAttributeChangedSignal("BottleCount"):Connect(queue))
   table.insert(view.connections,player:GetAttributeChangedSignal("BagCapacity"):Connect(queue))
   queue()
  end

  state.cleanup = detach
  state.connections = {
   player.CharacterAdded:Connect(changed),
   player.CharacterRemoving:Connect(function(character)
    if state.character and state.character.model == character then detach() end
   end),
   player.CharacterAppearanceLoaded:Connect(function(character)
    local view = state.character
    if view and view.model == character and view.queue then view.queue() end
   end),
  }
  if player.Character then task.spawn(changed,player.Character) end
 end

 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player)
  local state = players[player]
  if not state then return end
  players[player] = nil
  state.cleanup()
  for _,connection in ipairs(state.connections) do connection:Disconnect() end
 end)
 for _,player in ipairs(Players:GetPlayers()) do added(player) end
end

return Backpacks
