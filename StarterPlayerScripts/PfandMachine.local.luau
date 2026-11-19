local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage:WaitForChild("BottleTown")
local Config = require(Shared:WaitForChild("Config"))
local Presentation = require(script.Parent:WaitForChild("PfandPresentation"))
local player = Players.LocalPlayer
local request = Shared:WaitForChild("PfandRequest")
local state = Shared:WaitForChild("PfandState")
local active

local function close()
 local current = active
 if not current then return end
 active = nil
 ContextActionService:UnbindAction("PfandBack")
 current.view:destroy()
end

local function cancel()
 if active and not active.receipt then request:FireServer("cancel",active.id) end
 close()
end

local function insert(current)
 if active ~= current or not current.selected or current.pending or current.closing then return end
 current.sequence += 1
 local operation = {id=current.sequence,typeId=current.selected.id}
 current.pending = operation
 current.view:render(current.data,current.selected,true,current.selection)
 local function transmit()
  if active ~= current or current.pending ~= operation or current.closing then return end
  request:FireServer("insert",current.id,operation.id,operation.typeId)
  task.delay(1.6,transmit)
 end
 transmit()
end

local function open(data,machine)
 close()
 local current = {id=data.id,sequence=0,data=data}
 active = current
 current.view = Presentation.new(player,machine,{
  select=function(kind,key)
   if active ~= current or current.pending or current.closing then return end
   current.selected = kind
   current.selection = key
   current.view:render(current.data,kind,false,key)
  end,
  insert=function() insert(current) end,
  cancel=cancel,
  finish=function()
   if current.receipt then close() return end
   if current.closing then return end
   current.closing = true
   current.view:queueFinish()
   request:FireServer("finish",current.id)
  end,
 })
 current.view.gamepad = UserInputService:GetLastInputType().Name:match("^Gamepad") ~= nil
 current.view:render(data,nil,false)
 ContextActionService:BindAction("PfandBack",function(_,input)
  if input == Enum.UserInputState.Begin then
   if current.selected and not current.pending then
    current.selected,current.selection = nil,nil
    current.view:clearDrag()
    current.view:render(current.data,nil,false)
   else
    cancel()
   end
  end
  return Enum.ContextActionResult.Sink
 end,false,Enum.KeyCode.ButtonB,Enum.KeyCode.Escape)
end

state.OnClientEvent:Connect(function(data)
 if data.phase == "open" then
  local town = workspace:FindFirstChild("BottleTown")
  local machine = town and town:FindFirstChild("Pfand station")
  local slot = machine and machine:FindFirstChild("Bottle slot")
  if not slot or not slot:FindFirstChild("PfandCamera") or not slot:FindFirstChild("PfandCameraNarrow")
   or not slot:FindFirstChild("PfandReady") or not slot:FindFirstChild("PfandIntake") then
   request:FireServer("cancel",data.id)
   return
  end
  open(data,machine)
  return
 end
 local current = active
 if not current or current.id ~= data.id then return end
 if data.phase == "closed" then close() return end
 if data.phase == "receipt" then
  current.receipt = true
  current.pending = nil
  current.view:showReceipt(data)
  return
 end
 local pending = current.pending
 if not pending or pending.id ~= data.request then return end
 if data.phase == "processing" and not pending.playing then
  pending.playing = true
  current.view:showBottle(current.selected)
  current.view:animate()
 elseif data.phase == "result" then
  current.pending = nil
  current.data = data
  current.view:clearBottle()
  if current.closing then return end
  if not data.message then current.view:playSound(Config.Pfand.AcceptSound) end
  local rejected = current.selection
  current.selected,current.selection = nil,nil
  current.view:render(data,nil,false)
  if data.message then
   current.view.title.Text = data.message
   current.view:rejectBottle(rejected)
  end
 end
end)

player.CharacterRemoving:Connect(cancel)
UserInputService.LastInputTypeChanged:Connect(function(input)
 if not active then return end
 local view = active.view
 view.gamepad = input.Name:match("^Gamepad") ~= nil
 if view.gamepad and GuiService.SelectedObject ~= view.slotButton and not view.screen:IsAncestorOf(GuiService.SelectedObject or view.screen) then
  if active.receipt then GuiService.SelectedObject = view.finish
  else view:render(active.data,active.selected,active.pending ~= nil,active.selection) end
 end
end)

local town = workspace:WaitForChild("BottleTown")
local machine = town:WaitForChild("Pfand station")
machine:WaitForChild("Display")
machine:WaitForChild("Bottle slot")
machine:WaitForChild("Scanner light")
Presentation.attachDisplay(machine)
machine.AncestryChanged:Connect(function()
 if not machine:IsDescendantOf(workspace) then cancel() end
end)
