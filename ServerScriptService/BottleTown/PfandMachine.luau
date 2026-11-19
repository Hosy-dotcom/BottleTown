local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.BottleTown
local Config = require(Shared.Config)
local Inventory = require(script.Parent.Inventory)

local PfandMachine = {}

function PfandMachine.start(machine,prompt)
 local anchor = prompt.Parent
 machine.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
 local request = Instance.new("RemoteEvent")
 request.Name = "PfandRequest"
 local state = Instance.new("RemoteEvent")
 state.Name = "PfandState"
 local session
 local serial = 0
 local paced = {}

 local function send(current,phase,operation,message)
  if current.player.Parent ~= Players then return end
  state:FireClient(current.player,{
   id=current.id, phase=phase, request=operation and operation.id,
   typeId=operation and operation.typeId, message=message,
   counts=Inventory.depositCounts(current.player),
   returned=current.returned, total=current.total, lines=current.lines,
  })
 end

 local function display(status)
  machine:SetAttribute("PfandStatus",status)
  machine:SetAttribute("PfandCount",session and session.returned or 0)
  machine:SetAttribute("PfandTotal",session and session.total or 0)
 end

 local function reachable(player,character)
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  return player.Character == character and humanoid and humanoid.Health > 0 and root
   and prompt.Enabled and machine:IsDescendantOf(workspace) and anchor.Parent == machine and prompt.Parent == anchor
   and (root.Position-anchor.Position).Magnitude <= prompt.MaxActivationDistance+1
 end

 local function close(current,receipt,message)
  if session ~= current then return end
  session = nil
  current.pending = nil
  display("Bereit")
  send(current,receipt and "receipt" or "closed",nil,message)
  if message and current.player.Parent == Players then
   Shared.Feedback:FireClient(current.player,message,false)
  end
 end

 prompt.Triggered:Connect(function(player)
  if not reachable(player,player.Character) then return end
  local now = os.clock()
  if now-(paced[player] or -math.huge) < .45 then return end
  paced[player] = now
  if session then
   if session.player ~= player then Shared.Feedback:FireClient(player,"Machine in use",false) end
   return
  end
  if not next(Inventory.depositCounts(player)) then
   Shared.Feedback:FireClient(player,"No deposit bottles",false)
   return
  end
  serial += 1
  local current = {id=serial,player=player,character=player.Character,used=now,
   returned=0,total=0,lines={},highest=0,outcomes={}}
  session = current
  display("Flasche wählen")
  send(current,"open")
  task.spawn(function()
   while session == current do
    task.wait(.15)
    if session ~= current then return end
    if not reachable(player,current.character) then
     close(current,false,"Pfand session ended")
    elseif os.clock()-current.used >= Config.Pfand.IdleTimeout then
     close(current,false,"Pfand session timed out")
    end
   end
  end)
 end)

 request.OnServerEvent:Connect(function(player,action,id,sequence,typeId)
  local current = session
  if not current or current.player ~= player or current.id ~= id then return end
  if not reachable(player,current.character) then close(current,false) return end
  if action == "cancel" then close(current,false) return end
  if action == "finish" then
   if current.pending then
    current.finishRequested = true
   else
    close(current,true)
   end
   return
  end
  if action ~= "insert" or type(sequence) ~= "number" or sequence%1 ~= 0
   or sequence < 1 or sequence > 2^31 or type(typeId) ~= "string" or #typeId > 32 then return end

  local now = os.clock()
  if now-(current.lastRequest or -math.huge) < .12 then return end
  current.lastRequest = now
  local previous = current.outcomes[sequence]
  if previous then send(current,"result",previous,previous.message) return end
  if current.pending and current.pending.id == sequence then
   send(current,"processing",current.pending)
   return
  end
  if sequence <= current.highest or current.pending then return end
  current.highest = sequence
  local operation = {id=sequence,typeId=typeId}
  local function record(message)
   operation.message = message
   current.outcomes[sequence] = operation
   for older in pairs(current.outcomes) do
    if older <= sequence-12 then current.outcomes[older] = nil end
   end
   send(current,"result",operation,message)
  end
  if not Inventory.depositCounts(player)[typeId] then record("Bottle unavailable") return end
  current.used = now
  current.pending = operation
  display("Flasche wird geprüft")
  send(current,"processing",operation)
  task.delay(Config.Pfand.Duration,function()
   if session ~= current or current.pending ~= operation then return end
   if not reachable(player,current.character) then close(current,false) return end
   current.pending = nil
   local cents = Inventory.redeemOne(player,typeId)
   if cents then
    current.returned += 1
    current.total += cents
    current.lines[typeId] = (current.lines[typeId] or 0)+1
   end
   current.used = os.clock()
   display(cents and "Angenommen" or "Flasche wählen")
   local message = not cents and "Bottle unavailable" or nil
   record(message)
   if current.finishRequested then close(current,true) end
  end)
 end)

 Players.PlayerRemoving:Connect(function(player)
  paced[player] = nil
  if session and session.player == player then close(session,false) end
 end)
 display("Bereit")
 state.Parent = Shared
 request.Parent = Shared
end

return PfandMachine
