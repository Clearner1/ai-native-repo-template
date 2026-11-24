# Raft Coordination Protocol

> **Scope**: This document applies only to teams that use [Raft](https://raft.bot) for multi-agent collaboration on this repository. If your team does not use Raft, you can safely ignore this file.

---

## 1. Coordinator Role (Optional)

When a team member has been appointed as **architect, lead, or project owner**, that agent also acts as the team's **coordinator**. The coordinator is not a separate role to fill — it is a responsibility that comes with the leadership appointment.

### Coordinator Startup Checklist

On project kickoff the coordinator should:

1. **Ask the human owner** which channel mute level the team should use (see §2).
2. **Configure the team** accordingly (mute channels, follow relevant tasks).
3. **Post a brief orientation** in the project channel so every agent knows the agreed protocol.

### Workflow Guidance

The coordinator watches for workflow anti-patterns and gently redirects:

- **Thread pile-up**: If an agent is stacking sub-tasks inside a thread instead of creating separate Raft tasks, remind them to use `raft task create` so each work item is independently trackable and assignable.
- **Unstructured delegation**: If an agent is assigning work via ad-hoc thread mentions rather than task assignments, suggest they use `raft task assign` for clear ownership.

This is a soft responsibility — coach, don't block.

---

## 2. Channel Mute Strategy

The human owner decides the mute level at project start. The coordinator announces it, and each agent applies the setting individually (e.g., `raft channel mute`). Three levels are available:

| Level | Name | Behavior | Best For |
|:---:|:---|:---|:---|
| 0 | **Open** | No muting. All agents see all channel messages. | Small teams (2–3 agents) |
| 1 | **Task-focused** | Agents mute the project channel but follow their own assigned task threads. New tasks are delivered via direct assignment or coordinator mention. | Medium teams (4–8 agents) |
| 2 | **Directed** | Agents mute the project channel and only act when the coordinator assigns a task to them directly. | Large teams (9+ agents) or noise-sensitive projects |

### Guidelines

- The mute level is a **team-wide default**, not a per-agent setting. Consistency prevents some agents from seeing messages that others miss.
- Regardless of mute level, **direct mentions always pierce mute** — the coordinator (or any teammate) can always reach an agent by name.
- If no coordinator exists (small team, no appointed lead), default to **Level 0**.
- The owner can change the mute level at any time; the coordinator (or any agent, if no coordinator) applies the change.

---

## 3. What This Document Does NOT Cover

These concerns are already handled by existing mechanisms — do not duplicate them here:

| Concern | Covered By |
|:---|:---|
| Branch naming and isolation | AGENTS.md Iron Rule #7 |
| Worktree / branch cleanup after merge | AGENTS.md Iron Rule #8 |
| Git hygiene and selective staging | AGENTS.md Iron Rule #9 |
| Builder ≠ Verifier | AGENTS.md Iron Rule #1 |
| Task claiming and concurrency | Raft's built-in `raft task claim` mechanism |
| PR workflow | PR integration (e.g., Stamp) + repo CI gates |
