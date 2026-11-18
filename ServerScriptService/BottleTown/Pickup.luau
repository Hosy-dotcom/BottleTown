local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.BottleTown
local Config = require(Shared.Config)
local Inventory = require(script.Parent.Inventory)

local Pickup = {}
local registered = {}
local pending = {}
local lastId = {}
local lastRejection = {}
local monitor
local complete
local requests = Instance.new("RemoteEvent")
requests.Name = "PickupRequest"

local function durationForPlayer(_player)
 return Config.Pickup.BaseDuration
end

local function valid(player,entry,character)
 local root = character and character:FindFirstChild("HumanoidRootPart")
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 return player.Character == character and root and humanoid and humanoid.Health > 0
  and registered[entry.prompt] == entry and entry.prompt.Enabled
  and entry.prompt.Parent == entry.part and entry.part.Parent == entry.model
  and entry.model.Parent == entry.folder and entry.folder:IsDescendantOf(workspace)
  and (root.Position-entry.part.Position).Magnitude <= entry.prompt.MaxActivationDistance+1
end

local function clear(player,state,message)
 local attempt = pending[player]
 if not attempt then return end
 pending[player] = nil
 if not next(pending) and monitor then
  monitor:Disconnect()
  monitor = nil
 end
 if state then
  local entry = attempt.entry
  Shared.Feedback:FireClient(player,message or "",state=="success",{
   kind="pickup",state=state,attemptId=attempt.id,
   sound=state=="success" and (entry.bottle.pickupSound or "General") or nil,
  })
 end
end

local function scan()
 local now = os.clock()
 for player,attempt in pairs(pending) do
  if now > attempt.deadline or not valid(player,attempt.entry,attempt.character) then
   clear(player,"cancel")
  elseif attempt.completing and now >= attempt.ready then
   complete(player,attempt)
  end
 end
end

complete = function(player,attempt)
 if pending[player] ~= attempt then return end
 local entry = attempt.entry
 local now = os.clock()
 if now < attempt.ready or now > attempt.deadline or entry.claimed
  or not valid(player,entry,attempt.character) then
  clear(player,"cancel")
  return
 end
 entry.claimed = true
 local ok,message = Inventory.collect(player,entry.bottle)
 if not ok then
  entry.claimed = false
  clear(player,"cancel",message)
  return
 end
 clear(player,"success",message)
 entry.remove()
end

requests.OnServerEvent:Connect(function(player,action,id,prompt)
 if type(id) ~= "number" or id < 1 or id > 2^31 or id%1 ~= 0 then return end
 local attempt = pending[player]
 if action == "cancel" or action == "finish" then
  if not attempt or attempt.id ~= id then return end
  if action == "cancel" then
   clear(player,"cancel")
  else
   attempt.completing = true
  end
  return
 end
 if action ~= "begin" or typeof(prompt) ~= "Instance" or id <= (lastId[player] or 0) then return end
 local entry = registered[prompt]
 if not entry then return end
 lastId[player] = id
 clear(player)
 local character = player.Character
 if not valid(player,entry,character) then return end
 local now = os.clock()
 local ok,message = Inventory.canCollect(player,entry.bottle)
 if not ok then
  local show = now-(lastRejection[player] or -math.huge) >= .25
  if show then lastRejection[player] = now end
  Shared.Feedback:FireClient(player,show and message or "",false,{kind="pickup",state="cancel",attemptId=id})
  return
 end
 local duration = durationForPlayer(player)
 pending[player] = {id=id,entry=entry,character=character,ready=now+duration,deadline=now+duration+2}
 if not monitor then monitor = RunService.Heartbeat:Connect(scan) end
end)
requests.Parent = Shared

Players.PlayerRemoving:Connect(function(player)
 clear(player)
 lastId[player] = nil
 lastRejection[player] = nil
end)

function Pickup.register(prompt,part,bottle,remove,folder)
 prompt.HoldDuration = Config.Pickup.BaseDuration
 prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
 prompt:SetAttribute("BottlePickup",true)
 local entry = {prompt=prompt,part=part,model=part.Parent,bottle=bottle,remove=remove,folder=folder}
 registered[prompt] = entry
 return function()
  registered[prompt] = nil
  for player,attempt in pairs(pending) do
   if attempt.entry == entry then clear(player,"cancel") end
  end
 end
end

return Pickup
