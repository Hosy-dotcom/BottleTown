local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local shared = game.ReplicatedStorage:WaitForChild("BottleTown")
local Config = require(shared:WaitForChild("Config"))
local player = Players.LocalPlayer
local ink = Color3.fromRGB(31,54,51)
local cream = Color3.fromRGB(255,245,221)
local mint = Color3.fromRGB(174,228,192)
local peach = Color3.fromRGB(255,189,148)

local screen = Instance.new("ScreenGui")
screen.Name = "BottleTownHUD"
screen.ResetOnSpawn = false
screen.Parent = player:WaitForChild("PlayerGui")

local function panel(name,parent,position,size,color)
 local frame = Instance.new("Frame")
 frame.Name = name
 frame.Position = position
 frame.Size = size
 frame.BackgroundColor3 = color
 frame.BorderSizePixel = 0
 frame.Parent = parent
 local corner = Instance.new("UICorner",frame)
 corner.CornerRadius = UDim.new(0,12)
 return frame
end

local function text(parent,name,content,size,position,dimensions,color,bold)
 local label = Instance.new("TextLabel")
 label.Name = name
 label.BackgroundTransparency = 1
 label.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
 label.TextSize = size
 label.TextColor3 = color
 label.TextXAlignment = Enum.TextXAlignment.Left
 label.Position = position
 label.Size = dimensions
 label.Text = content
 label.Parent = parent
 return label
end

local card = panel("Backpack and cash",screen,UDim2.fromOffset(14,12),UDim2.fromOffset(206,84),ink)
text(card,"Town","BOTTLETOWN",12,UDim2.fromOffset(13,7),UDim2.fromOffset(170,18),mint,true)
local stats = text(card,"Inventory","",17,UDim2.fromOffset(13,29),UDim2.fromOffset(182,24),cream,true)
local cash = text(card,"Cash","",15,UDim2.fromOffset(13,55),UDim2.fromOffset(182,20),mint,true)
local progress = panel("Capacity track",card,UDim2.fromOffset(13,77),UDim2.fromOffset(180,3),Color3.fromRGB(74,102,93))
local fill = panel("Capacity fill",progress,UDim2.fromOffset(0,0),UDim2.fromScale(0,1),mint)

local notice = panel("Town guide",screen,UDim2.new(.5,0,0,108),UDim2.new(1,-28,0,66),ink)
notice.AnchorPoint = Vector2.new(.5,0)
local limit = Instance.new("UISizeConstraint",notice)
limit.MaxSize = Vector2.new(392,66)
local message = text(notice,"Message","",14,UDim2.fromOffset(13,5),UDim2.new(1,-26,1,-10),cream,true)
message.TextWrapped = true
message.TextXAlignment = Enum.TextXAlignment.Center
local generation = 0
local function show(content,color,seconds)
 generation += 1
 local token = generation
 message.Text = content
 message.TextColor3 = color
 notice.Visible = true
 task.delay(seconds,function()
  if generation == token then notice.Visible = false end
 end)
end

local function refresh()
 local count = player:GetAttribute("BottleCount") or 0
 local capacity = player:GetAttribute("BagCapacity") or 5
 local stars = player:GetAttribute("LindenStars") or 0
 stats.Text = string.format("Backpack  %d / %d",count,capacity)
 cash.Text = Config.Money(player:GetAttribute("CashCents") or 0) .. (stars > 0 and "    •    Stars "..stars or "")
 fill.BackgroundColor3 = count == capacity and peach or mint
 TweenService:Create(fill,TweenInfo.new(.16),{Size=UDim2.fromScale(count/capacity,1)}):Play()
end
for _,attribute in ipairs({"BottleCount","BagCapacity","CashCents","LindenStars"}) do
 player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()
show("Explore the square, park and meadow. Hold E, Button X, or the bottle prompt to collect, then return bottles at Korn Markt’s green Pfand machine.",cream,14)
shared:WaitForChild("Feedback").OnClientEvent:Connect(function(content,success,payload)
 if success and payload and payload.kind == "pickup" then
  fill.BackgroundColor3 = cream
  TweenService:Create(fill,TweenInfo.new(.25),{BackgroundColor3 = (player:GetAttribute("BottleCount") or 0) >= (player:GetAttribute("BagCapacity") or 5) and peach or mint}):Play()
 end
 if content ~= "" then show(content,success and mint or peach,4) end
end)