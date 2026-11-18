---
name: bottletown-dev
description: Implement and maintain BottleTown Roblox features using project context and focused source inspection. Use for BottleTown gameplay, Luau, Studio, Script Sync, and development workflow tasks.
---

# BottleTown development

1. Read [AGENTS.md](../../../AGENTS.md) and the relevant sections of [PROJECT_CONTEXT.md](../../../docs/PROJECT_CONTEXT.md).
2. Read [CURRENT_STATE.md](../../../docs/CURRENT_STATE.md) for completed work, open issues, and the approved iteration.
3. Identify the smallest set of scripts and other files needed for the request.
4. Inspect those files and their necessary dependencies. If documentation conflicts with code, verify the current behavior and follow the code as evidence.
5. Check Git status before modifying files and preserve unrelated changes.
6. Use Roblox Studio MCP only for task-relevant inspection, authorized object work, or gameplay verification. Inspect only the necessary objects.
7. Reuse existing systems. Edit synced scripts in their tracked Luau files and keep one runnable implementation per system.
8. Explain the planned change and implement one focused, testable iteration within the approved scope.
9. Run relevant checks. For gameplay changes, playtest the affected flow in Studio and review Output.
10. Report the changes, tests, any skipped checks, and known issues. Leave the work ready for Git Manager review. Preserve user approval requirements for commits, publishing, significant deletions, and paid products.
11. Update CURRENT_STATE.md once the iteration is successfully completed and approved. Record verified outcomes and remaining work.

Use [Architecture_Audit.md](../../../docs/Architecture_Audit.md) for historical findings and design background when relevant. Reserve full architecture audits for explicit requests and major architecture changes that require them.
