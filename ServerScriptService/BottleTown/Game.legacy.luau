local Config = require(game.ReplicatedStorage.BottleTown.Config)
local Feedback = game.ReplicatedStorage.BottleTown.Feedback
local Inventory = require(script.Parent.Inventory)
local Bottles = require(script.Parent.Bottles)
local Residents = require(script.Parent.Residents)
local Pickup = require(script.Parent.Pickup)
local PfandMachine = require(script.Parent.PfandMachine)
local Backpacks = require(script.Parent.Backpacks)
local town = workspace.BottleTown
Backpacks.start()

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

local discard = Bottles.start(town,function(part,bottle,remove,folder)
 local prompt = addPrompt(part,"Pick up",bottle.name .. (bottle.cents and " · "..Config.Money(bottle.cents) or " · Mythical"),6)
 return Pickup.register(prompt,part,bottle,remove,folder)
end)

local station = town["Pfand station"]
PfandMachine.start(station,addPrompt(station.Interaction,"Return bottles","Korn Markt · Pfand",8))

local shop = town["Equipment shop"].Interaction
local shopPrompt = addPrompt(shop,"Upgrade backpack","10 slots · "..Config.Money(Config.UpgradePrice),8)
shopPrompt.Triggered:Connect(function(player)
 if not canInteract(player,shop,shopPrompt) then return end
 local ok,message = Inventory.upgrade(player)
 Feedback:FireClient(player,message,ok)
end)
Residents.start(town,discard)