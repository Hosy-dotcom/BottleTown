# BottleTown current state

## Phase and active iteration

**Phase:** Playable Version 1 prototype with follow-up gameplay iterations. This snapshot is based on tracked source and Git history through `1edb64b`.

**Active iteration:** Development workflow documentation and the project skill are ready for Git Manager review. No next gameplay iteration is recorded as approved in the repository.

## Completed gameplay iterations

- `34478f2` built the playable town and the collect, redeem, and upgrade loop with resident drops, a HUD, and the mythical Linden Star.
- `cf08ba2` added zone targets for ambient bottles, capped active resident drops, scaled resident models, and adjusted Emil’s route. The architecture audit in that commit documents the preceding prototype.
- `1edb64b` added timed pickup, server-side timing and range checks, capacity checks, a client reach pose, and confirmed pickup sound and HUD feedback.

## Implemented baseline

- Town, Park, and Meadow target 8, 3, and 3 ambient bottles. Resident drops have a separate limit of 2 within the global cap of 16. The bottle registry cleans up when a model leaves its folder.
- Players hold E, gamepad X, or the touch prompt for a base 0.9 seconds. The server arbitrates contested pickups. With no configured animation IDs, the client uses a procedural reach pose. Sound categories fall back to the configured generic cue.
- Players start with a five-slot bag. Korn Markt redeems all eligible bottles at once for cash in integer cents. The equipment shop sells a ten-slot bag for €2.00. The Linden Star is counted separately from deposits.

## Open constraints and verification

- Inventory, cash, upgrades, and stars reset when the player leaves the server. The shop upgrade changes capacity only, and pickup duration is still fixed.
- Spawn heights and resident routes are fixed. Resident scaling is independent of Roblox player avatar scaling. Pickup and station prompts allow through-geometry interactions within range.
- Source and place parity are checked for this documentation update. No new multiplayer or touch playtest, audio playback, or avatar-fit verification was performed during the update.

## Next feature candidates

The audit proposes interactive bottle-by-bottle Pfand returns, equipment-driven pickup duration, visible backpack fullness, and a shared player/NPC scale policy. Their order awaits gameplay approval. Basic cleanup contracts and personal depot progression remain in Version 1 scope without an implementation in the current source.

Keep economy and pickup decisions server-owned, use one cash currency, and focus each approved iteration on one testable change. Follow the [project approval and Studio rules](../AGENTS.md).
