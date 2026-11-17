return {
 UpgradePrice = 200,
 ActiveLimit = 24,
 Types = {
  {name="Water bottle", cents=25, color=Color3.fromRGB(85,185,243), label=Color3.fromRGB(240,251,255), size=1},
  {name="Reusable glass", cents=15, color=Color3.fromRGB(99,193,111), label=Color3.fromRGB(247,219,148), size=1.13},
  {name="Amber glass", cents=8, color=Color3.fromRGB(189,105,46), label=Color3.fromRGB(251,210,114), size=.83},
  {name="Soda bottle", cents=25, color=Color3.fromRGB(237,104,117), label=Color3.fromRGB(255,232,223), size=1.24},
 },
 Mythical = {name="Linden Star", color=Color3.fromRGB(255,203,77), label=Color3.fromRGB(255,247,193), size=1.35},
 Money = function(cents) return string.format("€%d.%02d", math.floor(cents/100), cents%100) end,
}