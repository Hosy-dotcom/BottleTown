local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.BottleTown.Config)
local Feedback = game.ReplicatedStorage.BottleTown.Feedback
local Inventory = require(script.Parent.Inventory)
local Bottles = require(script.Parent.Bottles)
local Residents = require(script.Parent.Residents)
local town = workspace.BottleTown

local function addPrompt(part, action, description, distance)
 local prompt = Instance.new("ProximityPrompt")
 prompt.ActionText = action
 prompt.ObjectText = description
 prompt.MaxActivationDistance = distance
 prompt.RequiresLineOfSight = false
 prompt.KeyboardKeyCode = Enum.KeyCode.E
 prompt.Parent = part
 return prompt
end

local function canInteract(player,part,prompt)
 local character = player.Character
 local root = character and character:FindFirstChild("HumanoidRootPart")
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 return root and humanoid and humanoid.Health > 0 and prompt.Enabled
  and part:IsDescendantOf(town) and (root.Position-part.Position).Magnitude <= prompt.MaxActivationDistance+1
end

local discard = Bottles.start(town,function(part,bottle,remove)
 local prompt = addPrompt(part,"Pick up",bottle.name .. (bottle.cents and " · "..Config.Money(bottle.cents) or " · Mythical"),6)
 local claimed = false
 prompt.Triggered:Connect(function(player)
  if claimed or not canInteract(player,part,prompt) then return end
  claimed = true
  local ok,message = Inventory.collect(player,bottle)
  if ok then
   remove()
  else
   claimed = false
  end
  Feedback:FireClient(player,message,ok)
 end)
end)

local station = town["Pfand station"]
local display = station.Display
local displayColor = display.Color
local pulse
local function stationInteraction(model,action,description,callback)
 local part = model.Interaction
 local prompt = addPrompt(part,action,description,8)
 prompt.Triggered:Connect(function(player)
  if not canInteract(player,part,prompt) then return end
  local ok,message = callback(player)
  Feedback:FireClient(player,message,ok)
  if ok and model == station then
   if pulse then pulse:Cancel() end
   display.Color = Color3.fromRGB(255,239,119)
   pulse = TweenService:Create(display,TweenInfo.new(.9),{Color=displayColor})
   pulse:Play()
  end
 end)
end
stationInteraction(station,"Return all bottles","Korn Markt · Pfand",Inventory.redeem)
stationInteraction(town["Equipment shop"],"Upgrade backpack","10 slots · "..Config.Money(Config.UpgradePrice),Inventory.upgrade)
Residents.start(town,discard)