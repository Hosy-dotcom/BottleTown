local TweenService = game:GetService("TweenService")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Prompts = game:GetService("ProximityPromptService")
local Config = require(game.ReplicatedStorage.BottleTown.Config)

local Presentation = {}
Presentation.__index = Presentation

local dark = Color3.fromRGB(22,37,34)
local light = Color3.fromRGB(242,248,238)
local green = Color3.fromRGB(177,235,161)
local muted = Color3.fromRGB(49,72,65)

local function create(class,parent,properties)
 local object = Instance.new(class)
 for key,value in pairs(properties) do object[key] = value end
 object.Parent = parent
 return object
end

local function label(parent,text,size)
 return create("TextLabel",parent,{
  Text=text,TextSize=size,TextColor3=light,Font=Enum.Font.GothamMedium,
  BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
  Size=UDim2.new(1,0,0,size+8),
 })
end

local function button(parent,text,callback)
 local item = create("TextButton",parent,{
  Text=text,Size=UDim2.new(1,0,0,42),BackgroundColor3=muted,TextColor3=light,
  Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0,Selectable=true,
 })
 create("UICorner",item,{CornerRadius=UDim.new(0,7)})
 item.Activated:Connect(callback)
 return item
end

local function bottleModel(parent,kind,frame)
 local model = create("Model",parent,{Name="PfandPreview"})
 local isCan = kind.shape == "Can"
 local glass = kind.pickupSound == "Glass"
 local function cylinder(name,offset,length,width,color,material,transparency)
  return create("Part",model,{
   Name=name,CFrame=frame*CFrame.new(offset*kind.size,0,0),Size=Vector3.new(length,width,width)*kind.size,
   Color=color,Material=material or Enum.Material.SmoothPlastic,Transparency=transparency or 0,
   Shape=Enum.PartType.Cylinder,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
  })
 end
 if isCan then
  local silver = Color3.fromRGB(191,196,198)
  model.PrimaryPart = cylinder("Can",0,.77,.52,kind.color,Enum.Material.Metal)
  cylinder("Label",0,.47,.53,kind.label)
  for _,endOffset in ipairs({-.37,.37}) do
   cylinder("Rim",endOffset,.045,.55,silver,Enum.Material.Metal)
  end
 else
  model.PrimaryPart = cylinder("Body",0,.72,.5,kind.color,
   glass and Enum.Material.Glass or Enum.Material.SmoothPlastic,glass and .2 or .08)
  cylinder("Label",-.02,.25,.515,kind.label)
  cylinder("Shoulder",.37,.16,.4,kind.color)
  cylinder("Neck",.51,.19,.25,kind.color)
  cylinder("Cap",.63,.10,.28,kind.label)
 end
 return model
end

local function bottleViewport(parent,kind)
 local view = create("ViewportFrame",parent,{
  Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Ambient=Color3.fromRGB(172,182,177),
  LightColor=Color3.fromRGB(255,248,229),LightDirection=Vector3.new(-1,-2,-3),
 })
 local camera = create("Camera",view,{
  CFrame=CFrame.lookAt(Vector3.new(2.2,1.2,3.6),Vector3.new(0,.12,0)),FieldOfView=28,
 })
 view.CurrentCamera = camera
 bottleModel(view,kind,CFrame.Angles(0,0,math.pi/2))
 return view
end

local function inside(point,position,size,padding)
 return point.X >= position.X-padding and point.X <= position.X+size.X+padding
  and point.Y >= position.Y-padding and point.Y <= position.Y+size.Y+padding
end

function Presentation.attachDisplay(machine)
 local display = machine.Display
 local gui = create("SurfaceGui",display,{
  Name="PfandDisplay",Face=Enum.NormalId.Front,CanvasSize=Vector2.new(320,200),
 })
 local screen = create("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=dark,BorderSizePixel=0})
 local text = create("TextLabel",screen,{
  Size=UDim2.new(1,-20,1,-12),Position=UDim2.fromOffset(10,6),BackgroundTransparency=1,
  TextColor3=green,TextScaled=true,Font=Enum.Font.GothamBold,
 })
 local function refresh()
  local status = machine:GetAttribute("PfandStatus") or "Bereit"
  local caption = status == "Flasche wird geprüft" and "SCAN" or status == "Flasche wählen" and "BEREIT" or status:upper()
  text.Text = string.format("%s\n%d  ·  %s",caption,machine:GetAttribute("PfandCount") or 0,
   Config.Money(machine:GetAttribute("PfandTotal") or 0))
  machine["Scanner light"].Color = status == "Flasche wird geprüft" and green or muted
 end
 for _,name in ipairs({"PfandStatus","PfandCount","PfandTotal"}) do
  machine:GetAttributeChangedSignal(name):Connect(refresh)
 end
 refresh()
end

function Presentation.new(player,machine,callbacks)
 local self = setmetatable({},Presentation)
 self.machine = machine
 self.player = player
 self.camera = workspace.CurrentCamera
 self.oldFocus = GuiService.SelectedObject
 self.oldCamera = {CameraType=self.camera.CameraType,CameraSubject=self.camera.CameraSubject,
  CFrame=self.camera.CFrame,Focus=self.camera.Focus,FieldOfView=self.camera.FieldOfView}
 self.oldPrompts = Prompts.Enabled
 self.callbacks = callbacks
 self.hud = player.PlayerGui:FindFirstChild("BottleTownHUD")
 if self.hud then
  self.hudEnabled = self.hud.Enabled
  self.hud.Enabled = false
 end
 self.visibility = {}
 self.visibilityConnections = {}
 local function hide(part)
  if part:IsA("BasePart") and self.visibility[part] == nil then
   self.visibility[part] = part.LocalTransparencyModifier
   part.LocalTransparencyModifier = 1
  end
 end
 for _,other in ipairs(game:GetService("Players"):GetPlayers()) do
  local character = other.Character
  if character then
   table.insert(self.visibilityConnections,character.DescendantAdded:Connect(hide))
   for _,part in ipairs(character:GetDescendants()) do hide(part) end
  end
 end
 self.screen = create("ScreenGui",player.PlayerGui,{Name="PfandSession",ResetOnSpawn=false,DisplayOrder=12})
 self.panel = create("Frame",self.screen,{BackgroundColor3=dark,BorderSizePixel=0})
 create("UICorner",self.panel,{CornerRadius=UDim.new(0,12)})
 create("UIPadding",self.panel,{PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12),
  PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)})
 create("UIListLayout",self.panel,{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
 self.title = label(self.panel,"KORN MARKT  /  PFAND",14)
 self.list = create("Frame",self.panel,{Name="BottleTray",BackgroundTransparency=1})
 self.finish = button(self.panel,"Finish",callbacks.finish)
 self.title.LayoutOrder = 1
 self.list.LayoutOrder = 3
 self.finish.LayoutOrder = 4
 self.tiles = {}
 self.exit = button(self.screen,"Close",callbacks.cancel)
 self.exit.Size = UDim2.fromOffset(62,44)
 self.exit.TextSize = 13
 self.exit.AnchorPoint = Vector2.new(1,0)
 self.exit.Position = UDim2.new(1,-8,0,52)
 self.exit.ZIndex = 2
 self.exit.Selectable = false
 self.slotScreen = create("ScreenGui",player.PlayerGui,{
  Name="PfandSlot",ResetOnSpawn=false,DisplayOrder=11,ScreenInsets=Enum.ScreenInsets.None,
 })
 self.dragScreen = create("ScreenGui",player.PlayerGui,{
  Name="PfandDrag",ResetOnSpawn=false,DisplayOrder=13,ScreenInsets=Enum.ScreenInsets.None,
 })
 self.slotButton = create("TextButton",self.slotScreen,{
  Name="Insertion slot",Text="",BackgroundTransparency=1,Selectable=true,Visible=false,
 })
 self.slotButton.Activated:Connect(callbacks.insert)
 create("UICorner",self.slotButton,{CornerRadius=UDim.new(0,8)})
 self.slotStroke = create("UIStroke",self.slotButton,{Color=green,Thickness=2,Enabled=false,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
 self.inputConnections = {
  Input.InputChanged:Connect(function(input) self:movePointer(input) end),
  Input.InputEnded:Connect(function(input) self:releasePointer(input) end),
  Input.WindowFocusReleased:Connect(function() self:clearDrag() end),
 }
 self.sound = create("Sound",machine["Bottle slot"],{Volume=.22})
 local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if humanoid then
  self.movement = {humanoid=humanoid,speed=humanoid.WalkSpeed,jumping=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)}
  humanoid.WalkSpeed = 0
  humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
 end
 Prompts.Enabled = false
 self.camera.CameraType = Enum.CameraType.Scriptable
 self:frame()
 self.resize = self.camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:frame() end)
 return self
end

function Presentation:layoutTray()
 local viewport = self.camera.ViewportSize
 local width = math.min(viewport.X-20,640,math.max(235,#self.tiles*68+28))
 self.panel.AnchorPoint = Vector2.new(.5,1)
 self.panel.Position = UDim2.new(.5,0,1,-8)
 if self.receipt then
  self.panel.Size = UDim2.fromOffset(math.min(viewport.X-20,340),235)
  self.list.Size = UDim2.new(1,0,0,108)
  return
 end
 local count = math.max(#self.tiles,1)
 local columns = math.min(count,math.max(1,math.floor((width-22)/53)))
 local rows = math.ceil(count/columns)
 local height = viewport.Y < 475 and 48 or 60
 self.panel.Size = UDim2.fromOffset(width,rows*(height+4)+91)
 self.list.Size = UDim2.new(1,0,0,rows*(height+4))
 local tileWidth = math.min(64,math.floor((width-28)/columns)-4)
 for index,tile in ipairs(self.tiles) do
  local row = math.floor((index-1)/columns)
  local inRow = math.min(columns,count-row*columns)
  local column = (index-1)%columns
  tile.button.Size = UDim2.fromOffset(tileWidth,height)
  tile.button.Position = UDim2.new(.5,(column-inRow/2)*(tileWidth+4)+2,0,row*(height+4))
 end
end

function Presentation:frame()
 local camera = self.camera
 local viewport = camera.ViewportSize
 self:clearDrag()
 self:layoutTray()
 if self.receipt then return end
 self.slotButton.Visible = false
 local slot = self.machine["Bottle slot"]
 local marker = viewport.X/viewport.Y < .9 and slot.PfandCameraNarrow or slot.PfandCamera
 local from = marker.WorldPosition
 local target = CFrame.lookAt(from,from-slot.CFrame.LookVector)
 camera.Focus = slot.CFrame
 if self.cameraTween then self.cameraTween:Cancel() end
 self.cameraTween = TweenService:Create(camera,TweenInfo.new(.35,Enum.EasingStyle.Quad),{CFrame=target,FieldOfView=49})
 self.cameraTween:Play()
 self.cameraTween.Completed:Once(function(status)
  if status ~= Enum.PlaybackState.Completed or not self.slotButton.Parent then return end
  local point,visible = camera:WorldToScreenPoint(slot.Position)
  local edge = camera:WorldToScreenPoint(slot.Position+Vector3.new(1,0,0))
  self.slotButton.AnchorPoint = Vector2.new(.5,.5)
  local pos = Vector2.new(point.X,point.Y)-self.slotScreen.AbsolutePosition
  self.slotButton.Position = UDim2.fromOffset(pos.X,pos.Y)
  local width = math.max(52,math.abs(edge.X-point.X)*2+22)
  self.slotButton.Size = UDim2.fromOffset(width,math.max(48,(width-22)*.66+22))
  self.slotButton.Visible = visible
  self:updateFocus()
 end)
end

function Presentation:clearBottle()
 if self.insertion then self.insertion:Cancel() self.insertion = nil end
 if self.preview then self.preview:Destroy() self.preview = nil end
end

function Presentation:showBottle(kind)
 self:clearBottle()
 if not kind then return end
 local slot = self.machine["Bottle slot"]
 local frame = slot.PfandReady.WorldCFrame*CFrame.Angles(0,-math.pi/2,0)
 self.preview = bottleModel(workspace,kind,frame)
end

function Presentation:playSound(id)
 self.sound:Stop()
 self.sound.SoundId = id
 self.sound:Play()
end

function Presentation:animate()
 if not self.preview then return end
 local model = self.preview
 local driver = create("CFrameValue",model,{Value=model:GetPivot()})
 driver.Changed:Connect(function(value) model:PivotTo(value) end)
 local destination = self.machine["Bottle slot"].PfandIntake.WorldCFrame*CFrame.Angles(0,-math.pi/2,0)
 self.insertion = TweenService:Create(driver,TweenInfo.new(Config.Pfand.Duration,Enum.EasingStyle.Quad),{Value=destination})
 self.insertion:Play()
 self:playSound(Config.Pfand.IntakeSound)
 task.delay(.32,function()
  if self.preview == model then self:playSound(Config.Pfand.ScanSound) end
 end)
end

function Presentation:updateFocus()
 if not self.gamepad or self.receipt then return end
 if self.busy or self.finishing then
  GuiService.SelectedObject = self.exit
 elseif self.selected and self.slotButton.Visible then
  GuiService.SelectedObject = self.slotButton
 else
  GuiService.SelectedObject = self.tiles[1] and self.tiles[1].button or self.finish
 end
end

function Presentation:clearDrag()
 self.pointer = nil
 if self.ghost then self.ghost:Destroy() self.ghost = nil end
 if self.slotStroke then
  self.slotStroke.Thickness = 2
  self.slotStroke.Enabled = self.selected ~= nil and not self.busy
 end
end

function Presentation:pointerPosition(input)
 if input.UserInputType == Enum.UserInputType.Touch then
  return Vector2.new(input.Position.X,input.Position.Y)-self.dragScreen.AbsolutePosition
 end
 return Input:GetMouseLocation()
end

function Presentation:overSlot(point)
 local slot = self.slotButton
 if not slot.Visible then return false end
 local origin = self.slotScreen.AbsolutePosition
 return inside(point,slot.AbsolutePosition-origin,slot.AbsoluteSize,0)
  and not inside(point,self.panel.AbsolutePosition-origin,self.panel.AbsoluteSize,0)
  and not inside(point,self.exit.AbsolutePosition-origin,self.exit.AbsoluteSize,0)
end

function Presentation:showGhost(kind,point)
 self.ghost = create("Frame",self.dragScreen,{
  BackgroundTransparency=1,Size=UDim2.fromOffset(82,82),AnchorPoint=Vector2.new(.5,.5),
  Position=UDim2.fromOffset(point.X,point.Y),
 })
 bottleViewport(self.ghost,kind)
end

function Presentation:rejectBottle(key)
 for _,tile in ipairs(self.tiles) do
  if tile.key == key and self.slotButton.Visible then
   self:clearDrag()
   local point = self.slotButton.AbsolutePosition+self.slotButton.AbsoluteSize/2-self.dragScreen.AbsolutePosition
   self:showGhost(tile.kind,point)
   self:returnGhost(tile)
   return
  end
 end
end

function Presentation:movePointer(input)
 local press = self.pointer
 if not press or (press.touch and input ~= press.input)
  or (not press.touch and input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
 local point = self:pointerPosition(input)
 if not self.ghost and (point-press.start).Magnitude < 9 then return end
 if not self.ghost then self:showGhost(press.tile.kind,point) end
 self.ghost.Position = UDim2.fromOffset(point.X,point.Y)
 self.slotStroke.Enabled = true
 self.slotStroke.Thickness = self:overSlot(point) and 4 or 2
end

function Presentation:returnGhost(tile)
 self.slotStroke.Thickness = 2
 self.slotStroke.Enabled = self.selected ~= nil
 local ghost = self.ghost
 if not ghost then return end
 local point = tile.button.AbsolutePosition+tile.button.AbsoluteSize/2-self.dragScreen.AbsolutePosition
 local tween = TweenService:Create(ghost,TweenInfo.new(.18,Enum.EasingStyle.Quad),{
  Position=UDim2.fromOffset(point.X,point.Y),
 })
 tween.Completed:Once(function()
  if self.ghost == ghost and not self.pointer then self:clearDrag() end
 end)
 tween:Play()
end

function Presentation:releasePointer(input)
 local press = self.pointer
 if not press or input ~= press.input then return end
 self.pointer = nil
 local point = self:pointerPosition(input)
 if self.ghost then
  if input.UserInputState ~= Enum.UserInputState.Cancel and self:overSlot(point) then
   self:clearDrag()
   self.callbacks.select(press.tile.kind,press.tile.key)
   self.callbacks.insert()
  else
   self:returnGhost(press.tile)
  end
 elseif input.UserInputState ~= Enum.UserInputState.Cancel
  and inside(point,press.tile.button.AbsolutePosition-self.dragScreen.AbsolutePosition,press.tile.button.AbsoluteSize,0) then
  self.callbacks.select(press.tile.kind,press.tile.key)
 end
end

function Presentation:render(data,selected,busy,selection)
 self.selected = selected
 self.busy = busy
 self.exit.Selectable = busy or self.finishing == true
 self.title.Text = busy and "Scanning…" or selected and "Bottle selected · use the slot" or "PFAND"
 self.slotStroke.Enabled = selected ~= nil and not busy
 self.slotButton.Interactable = selected ~= nil and not busy
 self.slotButton.Selectable = self.slotButton.Interactable
 if self.counts ~= data.counts then
  self:clearDrag()
  self.counts = data.counts
  for _,tile in ipairs(self.tiles) do tile.button:Destroy() end
  table.clear(self.tiles)
  for _,kind in ipairs(Config.Types) do
   for index = 1,data.counts[kind.id] or 0 do
    local tile = {kind=kind,key=kind.id.."/"..index}
    tile.button = button(self.list,"",function(input)
     if input and input.UserInputType.Name:match("^Gamepad") and not self.busy then
      self.callbacks.select(kind,tile.key)
     end
    end)
    tile.button.Name = tile.key
    tile.button.AutoButtonColor = false
    bottleViewport(tile.button,kind)
    tile.button.InputBegan:Connect(function(input)
     local touch = input.UserInputType == Enum.UserInputType.Touch
     if self.busy or self.pointer or (not touch and input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
     self:clearDrag()
     self.pointer = {input=input,touch=touch,start=self:pointerPosition(input),tile=tile}
    end)
    tile.button.MouseEnter:Connect(function()
     if not self.busy and not tile.selected then tile.button.BackgroundColor3 = Color3.fromRGB(66,94,83) end
    end)
    tile.button.MouseLeave:Connect(function()
     if not tile.selected then tile.button.BackgroundColor3 = muted end
    end)
    table.insert(self.tiles,tile)
   end
  end
  self:layoutTray()
 end
 for _,tile in ipairs(self.tiles) do
  tile.selected = tile.key == selection
  tile.button.BackgroundColor3 = tile.selected and green or muted
  tile.button.Interactable = not busy
  tile.button.Selectable = not busy
 end
 if #self.tiles == 0 then self.title.Text = "Tray empty" end
 self.finish.BackgroundColor3 = #self.tiles == 0 and green or muted
 self.finish.TextColor3 = #self.tiles == 0 and dark or light
 self:updateFocus()
end

function Presentation:releaseCamera()
 if not self.oldCamera then return end
 if self.cameraTween then self.cameraTween:Cancel() end
 local old = self.oldCamera
 local character = self.player.Character
 local subject = old.CameraSubject
 if not subject or not subject:IsDescendantOf(workspace) then
  subject = character and character:FindFirstChildOfClass("Humanoid")
 end
 if subject then self.camera.CameraSubject = subject end
 self.camera.CFrame = old.CFrame
 self.camera.Focus = old.Focus
 self.camera.FieldOfView = old.FieldOfView
 self.camera.CameraType = old.CameraType
 self.oldCamera = nil
 Prompts.Enabled = self.oldPrompts
 if self.hud and self.hud.Parent then self.hud.Enabled = self.hudEnabled end
 for _,connection in ipairs(self.visibilityConnections) do connection:Disconnect() end
 table.clear(self.visibilityConnections)
 for part,transparency in pairs(self.visibility) do
  if part.Parent then part.LocalTransparencyModifier = transparency end
 end
 table.clear(self.visibility)
 local movement = self.movement
 if movement and movement.humanoid.Parent then
  if movement.humanoid.WalkSpeed == 0 then movement.humanoid.WalkSpeed = movement.speed end
  movement.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,movement.jumping)
 end
 self.movement = nil
 if self.oldFocus and self.oldFocus.Parent then GuiService.SelectedObject = self.oldFocus
 else GuiService.SelectedObject = nil end
end

function Presentation:queueFinish()
 self.finishing = true
 self.finish.Text = self.busy and "Finishing after scan…" or "Finishing…"
 self.finish.Interactable = false
 self.finish.Selectable = false
 self.exit.Selectable = true
 self:updateFocus()
end

function Presentation:showReceipt(data)
 self.receipt = true
 self:clearDrag()
 self:clearBottle()
 self.slotButton.Visible = false
 self.panel.Visible = false
 self.finish.Parent = self.screen
 self.finish.AnchorPoint = Vector2.new(.5,1)
 self.finish.Position = UDim2.new(.5,0,1,-12)
 self.finish.Size = UDim2.fromOffset(102,42)
 self.finish.BackgroundColor3 = muted
 self.finish.TextColor3 = light
 self.finish.Text = "Done"
 self.finish.Interactable = true
 self.finish.Selectable = true
 self.exit.Selectable = false
 if self.gamepad then GuiService.SelectedObject = self.finish end

 local slot = self.machine["Bottle slot"]
 local mouth = slot.CFrame*CFrame.new(0,-.9,-.15)
 local paper = create("Part",workspace,{
  Name="Pfand receipt",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
  CastShadow=false,Color=Color3.fromRGB(248,240,216),Material=Enum.Material.SmoothPlastic,
  Size=Vector3.new(1.2,.05,.018),CFrame=mouth*CFrame.new(0,-.025,-.015),
 })
 self.paper = paper
 local surface = create("SurfaceGui",paper,{
  Face=Enum.NormalId.Front,CanvasSize=Vector2.new(360,480),LightInfluence=0,
 })
 local ink = Color3.fromRGB(42,36,31)
 local function printLine(text,y,height,size,bold)
  return create("TextLabel",surface,{
   Position=UDim2.fromOffset(24,y),Size=UDim2.fromOffset(312,height),
   BackgroundTransparency=1,Text=text,TextColor3=ink,TextSize=size,
   Font=bold and Enum.Font.Code or Enum.Font.RobotoMono,
   TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
  })
 end
 printLine("KORN MARKT",26,44,34,true)
 printLine("PFANDBON",72,36,23,true)
 printLine("--------------------------------",116,25,16,false)
 local y = 151
 for _,kind in ipairs(Config.Types) do
  local count = data.lines[kind.id]
  if count then
   local line = string.format("%dx %-15s %s",count,kind.name,Config.Money(count*kind.cents))
   printLine(line,y,26,17,false)
   y += 30
  end
 end
 if data.returned == 0 then printLine("No bottles returned",y,26,17,false) end
 printLine("--------------------------------",287,25,16,false)
 printLine(string.format("%d returned",data.returned),326,30,20,false)
 printLine("TOTAL  "..Config.Money(data.total),369,52,32,true)
 printLine("Danke!",435,27,18,false)

 local height = 1.6
 local printTween = TweenService:Create(paper,TweenInfo.new(.48,Enum.EasingStyle.Linear),{
  Size=Vector3.new(1.2,height,.018),CFrame=mouth*CFrame.new(0,-height/2,-.015),
 })
 self.paperTween = printTween
 printTween.Completed:Once(function(status)
  if status ~= Enum.PlaybackState.Completed or self.paper ~= paper then return end
  local camera = self.camera.CFrame
  local center = camera.Position+camera.LookVector*2.8+camera.UpVector*.07
  self.paperTween = TweenService:Create(paper,TweenInfo.new(.35,Enum.EasingStyle.Quad),{
   CFrame=CFrame.lookAt(center,center-camera.LookVector,camera.UpVector),
  })
  self.paperTween:Play()
 end)
 self:playSound(Config.Pfand.IntakeSound)
 printTween:Play()
end

function Presentation:destroy()
 if self.paperTween then self.paperTween:Cancel() end
 if self.paper then self.paper:Destroy() self.paper = nil end
 self:clearDrag()
 for _,connection in ipairs(self.inputConnections) do connection:Disconnect() end
 self.resize:Disconnect()
 self:releaseCamera()
 self:clearBottle()
 self.sound:Destroy()
 if GuiService.SelectedObject and (GuiService.SelectedObject == self.slotButton or self.screen:IsAncestorOf(GuiService.SelectedObject)) then
  GuiService.SelectedObject = self.oldFocus and self.oldFocus.Parent and self.oldFocus or nil
 end
 self.dragScreen:Destroy()
 self.slotScreen:Destroy()
 self.screen:Destroy()
end

return Presentation
