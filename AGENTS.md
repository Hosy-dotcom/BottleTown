
# BottleTown — Roblox Game Development

## Game concept
BottleTown is a multiplayer Roblox bottle-collecting game inspired by the German Pfand system.

Players explore a small town, compete to collect discarded bottles, return eligible bottles to recycling machines, and earn cash.

Players use cash to upgrade their collection equipment, grow a small collection business, and gradually restore the town.

## Core principles
- Bottle collecting must remain the main gameplay activity.
- The world should feel alive, believable, and enjoyable.
- Multiplayer collection must be fair.
- Keep the economy simple, using one cash currency.
- Support PC and mobile gameplay.
- Design systems to support future updates.
- Implement small, testable features instead of large changes.

## Technical rules
- Use Roblox Luau.
- Use modular architecture and clear naming.
- Server-authoritative bottle spawning, pickups, inventory, currency, and purchases.
- Never trust currency or pickup values sent by clients.
- Use ReplicatedStorage for shared modules and RemoteEvents.
- Use Script Sync files as the source of truth for synced scripts.
- Use Roblox Studio MCP for world inspection, object creation, and playtesting.
- Avoid changing synced scripts directly through MCP when local files can be edited.
- Validate functionality using Studio playtests.
- Check Output for errors after implementing features.
- Never publish, delete significant content, or create paid products without approval.

## Development workflow
1. Inspect existing code and game structure.
2. Explain the planned changes.
3. Implement one small feature.
4. Test the feature.
5. Report the results and known issues.
6. Make changes ready for Git review.

## Version 1 scope
- One small town map
- Random bottle spawning
- Simple NPC bottle-discarding behavior
- Shared multiplayer bottle pickups
- Backpack inventory
- Bottle-return station
- Cash economy
- Equipment upgrades
- Basic cleanup contracts
- Personal depot progression
- One mythical collectible bottle

Do not implement features outside this scope unless requested.
