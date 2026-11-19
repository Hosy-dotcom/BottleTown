return {
 Pfand = {Duration=.8, IdleTimeout=30, IntakeSound="rbxassetid://9120300236", ScanSound="rbxassetid://9118777239", AcceptSound="rbxasset://sounds/electronicpingshort.wav"},
 Pickup = {
  BaseDuration = .9,
  AnimationIds = {},
  SoundIds = {General="rbxassetid://97767769"},
  Volume = .18,
 },
 UpgradePrice = 200,
 ActiveLimit = 16,
 ResidentBottleLimit = 2,
 BottleZoneTargets = {Town=8, Park=3, Meadow=3},
 BottleRefillInterval = 4,
 ResidentScale = 1.75,
 Types = {
  {id="water", name="Water bottle", pickupSound="Plastic", cents=25, color=Color3.fromRGB(85,185,243), label=Color3.fromRGB(240,251,255), size=1},
  {id="reusable", name="Reusable glass", pickupSound="Glass", cents=15, color=Color3.fromRGB(99,193,111), label=Color3.fromRGB(247,219,148), size=1.13},
  {id="amber", name="Amber glass", pickupSound="Glass", cents=8, color=Color3.fromRGB(189,105,46), label=Color3.fromRGB(251,210,114), size=.83},
  {id="soda", name="Soda bottle", pickupSound="Plastic", cents=25, color=Color3.fromRGB(237,104,117), label=Color3.fromRGB(255,232,223), size=1.24},
 },
 Mythical = {name="Linden Star", color=Color3.fromRGB(255,203,77), label=Color3.fromRGB(255,247,193), size=1.35},
 Money = function(cents) return string.format("€%d.%02d", math.floor(cents/100), cents%100) end,
}
