---
name: shortcut-tickets
description: Use when creating Shortcut tickets, filing bugs, or batch-creating stories from a list. Use when the user mentions Shortcut, filing tickets, or creating stories.
---

# Create Shortcut Tickets

Create one or more Shortcut stories via the REST API using the `SHORTCUT_API_TOKEN` env var.

## Prerequisites

- `SHORTCUT_API_TOKEN` must be set in the environment
- The token determines workspace context automatically (no org header needed)
- API base: `https://api.app.shortcut.com/api/v3`
- Auth header: `Shortcut-Token: $SHORTCUT_API_TOKEN`

## Workflow

### 1. Clarify Tickets

Before creating anything, confirm the list of tickets with the user:
- Parse their request into distinct ticket titles
- Show a numbered list back to them
- Ask if the breakdown is correct
- Resolve any ambiguity (multi-line items that might be one or many tickets)

### 2. Look Up Required IDs

Stories require IDs for epic, iteration, group (team), and workflow state. Use these endpoints:

```bash
# Find epic
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/epics" | python3 -c "
import sys, json
for e in json.load(sys.stdin):
    if 'KEYWORD' in e.get('name','').lower():
        print(f\"ID: {e['id']} | Name: {e['name']}\")"

# Find team
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/groups" | python3 -c "
import sys, json
for g in json.load(sys.stdin):
    if 'KEYWORD' in g.get('name','').lower():
        print(f\"ID: {g['id']} | Name: {g['name']}\")"

# Find latest iteration for a team
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/iterations" | python3 -c "
import sys, json
iters = [i for i in json.load(sys.stdin) if 'TEAM' in i.get('name','').lower()]
iters.sort(key=lambda x: x.get('start_date',''), reverse=True)
for i in iters[:3]:
    print(f\"ID: {i['id']} | {i['name']} | {i.get('status','')}\")"

# Find workflow states
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/workflows" | python3 -c "
import sys, json
for w in json.load(sys.stdin):
    print(f\"Workflow: {w['name']} (ID: {w['id']})\")
    for s in w.get('states',[]):
        print(f\"  {s['name']} (ID: {s['id']}) type={s.get('type','')}\")"
```

**IMPORTANT:** The `/search/epics` endpoint returns `organization2_missing` errors. Use `/epics` with client-side filtering instead.

### 3. Create Stories

Use `curl` (not Python `urllib`) to avoid SSL certificate issues on macOS.

```bash
curl -s -X POST -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/stories" \
  -d '{
    "name": "Ticket title",
    "description": "Details in markdown",
    "epic_id": 123,
    "iteration_id": 456,
    "group_id": "uuid",
    "workflow_state_id": 789,
    "story_type": "bug"
  }' | python3 -c "import sys,json; s=json.load(sys.stdin); print(f'sc-{s[\"id\"]} | {s[\"name\"]} | https://app.shortcut.com/chronosphere/story/{s[\"id\"]}')"
```

Story types: `bug`, `feature`, `chore`

For batch creation, chain multiple curl commands in a single Bash call to avoid round-trips.

### 4. Present Results

After creating all tickets, present them in two formats:

**Table format** for the conversation:

| # | ID | Title | Link |
|---|-----|-------|------|
| 1 | sc-XXXXX | Title | URL |

**Markdown format** ready for Slack:

```
- [sc-XXXXX](https://app.shortcut.com/chronosphere/story/XXXXX) Title
```

## Known Issues

- The `/search/*` endpoints return `organization2_missing` errors even with a valid token. Use list endpoints with client-side filtering.
- Python `urllib` on macOS fails with SSL certificate errors. Always use `curl`.
- The org slug for URLs is `chronosphere` (i.e. `https://app.shortcut.com/chronosphere/story/ID`).
