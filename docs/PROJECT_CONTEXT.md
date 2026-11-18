# BottleTown project context

BottleTown is a multiplayer Roblox game inspired by German Pfand. Players compete for discarded bottles in a small town, redeem eligible bottles for cash, and buy equipment upgrades. Bottle collection is the core loop. The project targets PC and mobile.

## Architecture and source map

The server owns bottle population, claims, inventory, cash, and purchases. The client handles input, HUD, and pickup effects. Read [CURRENT_STATE.md](CURRENT_STATE.md) for feature status and [AGENTS.md](../AGENTS.md) for project rules.

- [Game.legacy.luau](../ServerScriptService/BottleTown/Game.legacy.luau) boots the server, binds bottle prompts to Pickup, binds station and shop prompts to Inventory, and starts Residents with the drop callback provided by Bottles.
- [Bottles.luau](../ServerScriptService/BottleTown/Bottles.luau) builds world bottles and owns the active registry, zone refill, resident drop budget, mythical roll, and removal. It registers each prompt through Game and unregisters it on removal.
- [Pickup.luau](../ServerScriptService/BottleTown/Pickup.luau) owns prompt registration, per-player timed attempts, character and distance validation, and exclusive claims. It commits through Inventory and invokes the Bottles removal callback.
- [Inventory.luau](../ServerScriptService/BottleTown/Inventory.luau) owns session profiles, collection eligibility, redeem-all, backpack purchases, and replicated display attributes.
- [Residents.luau](../ServerScriptService/BottleTown/Residents.luau) creates scaled procedural residents and moves them on authored routes. It requests drops through Bottles and has no economy dependency.
- [Config.luau](../ReplicatedStorage/BottleTown/Config.luau) supplies shared bottle definitions, pickup settings, population settings, resident scale, upgrade price, and cash formatting.
- [BottlePickup.local.luau](../StarterPlayerScripts/BottlePickup.local.luau) translates native bottle prompt events into server requests and handles local reach poses and confirmed pickup audio. [BottleTownHUD.local.luau](../StarterPlayerScripts/BottleTownHUD.local.luau) displays inventory, cash, and feedback.

## Network and world contracts

- `ReplicatedStorage.BottleTown.PickupRequest` is created by Pickup at runtime. The client sends `begin` with an attempt ID and prompt reference, then `finish` or `cancel` with the attempt ID. The server resolves the registered bottle and checks timing and eligibility. Item values and cash stay server-owned.
- The place supplies `ReplicatedStorage.BottleTown.Feedback`. The server sends message text, success, and optional pickup metadata (`kind`, `state`, `attemptId`, and optional `sound`). The HUD reads server-set Player attributes `BottleCount`, `BagCapacity`, `CashCents`, and `LindenStars`. Station and shop actions use server-side native prompt events.
- Game expects `Workspace.BottleTown`, `Pfand station.Interaction`, `Pfand station.Display`, and `Equipment shop.Interaction`, with station and shop models under the town. Pickup expects a living Humanoid and HumanoidRootPart. Spawn positions and resident routes assume authored coordinates and a mostly flat map.
- Preserve the non-yielding claim and award path. Profiles are session-only. There is no common player/NPC rig or scale policy. Prompts currently allow interaction through geometry within range.

## Studio and Script Sync

Edit tracked Luau files through Script Sync. The local `StarterPlayerScripts/` directory maps to `StarterPlayer.StarterPlayerScripts`. Server and shared folders map under their namesake services. [BottleTown.rbxlx](../BottleTown.rbxlx) is the saved place snapshot for world objects, settings, and embedded scripts. When saving an implementation checkpoint, verify Studio is on the intended place and the embedded scripts match the tracked Luau. Keep a single runnable implementation per system.

Use Studio MCP for task-relevant world inspection, authorized object work, and gameplay playtests. Confirm the intended Studio instance before acting. Test the affected flow and read Output after implementation. For a focused code or documentation task, open only the dependencies needed to verify the change. [Architecture_Audit.md](Architecture_Audit.md) describes the original prototype and remains useful for historical findings and design tradeoffs.
