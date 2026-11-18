local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.BottleTown.Config)
local Inventory = {}
local profiles = {}

local function update(player, profile)
 player:SetAttribute("BottleCount", #profile.bottles)
 player:SetAttribute("BagCapacity", profile.capacity)
 player:SetAttribute("CashCents", profile.cash)
 player:SetAttribute("LindenStars", profile.stars)
end

local function join(player)
 if profiles[player] then return end
 local profile = {bottles={}, capacity=5, cash=0, stars=0}
 profiles[player] = profile
 update(player, profile)
end

Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(player) profiles[player] = nil end)
for _,player in ipairs(Players:GetPlayers()) do join(player) end

function Inventory.canCollect(player, bottle)
 local profile = profiles[player]
 if not profile then return false, "" end
 if bottle.cents and #profile.bottles >= profile.capacity then
  return false, "Backpack full! Return your bottles at Korn Markt."
 end
 return true
end

function Inventory.collect(player, bottle)
 local ok,message = Inventory.canCollect(player,bottle)
 if not ok then return false,message end
 local profile = profiles[player]
 if not bottle.cents then
  profile.stars += 1
  update(player, profile)
  return true, "You found the Linden Star! Added to your collection."
 end
 table.insert(profile.bottles, bottle)
 update(player, profile)
 return true, "Collected " .. bottle.name .. " · " .. Config.Money(bottle.cents)
end

function Inventory.redeem(player)
 local profile = profiles[player]
 if not profile then return false, "" end
 local count = #profile.bottles
 if count == 0 then return false, "Collect deposit bottles before returning." end
 local amount = 0
 for _,bottle in ipairs(profile.bottles) do amount += bottle.cents end
 table.clear(profile.bottles)
 profile.cash += amount
 update(player, profile)
 return true, "+" .. Config.Money(amount) .. " · Returned " .. count .. (count == 1 and " bottle" or " bottles")
end

function Inventory.upgrade(player)
 local profile = profiles[player]
 if not profile then return false, "" end
 if profile.capacity == 10 then return false, "You already have the 10-bottle backpack." end
 if profile.cash < Config.UpgradePrice then return false, "The 10-bottle bag costs " .. Config.Money(Config.UpgradePrice) .. "." end
 profile.cash -= Config.UpgradePrice
 profile.capacity = 10
 update(player, profile)
 return true, "Backpack upgraded! You can now carry 10 bottles."
end

return Inventory