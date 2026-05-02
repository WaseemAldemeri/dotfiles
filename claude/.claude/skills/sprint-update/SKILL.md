---
name: sprint-update
description: Updates the "Sprint to October" Notion dashboard with weight, workouts, study progress, or phase changes from natural language.
argument-hint: <natural language update, e.g. "weight 84kg" or "finished chapter 6 Replication">
---
# Sprint Update

When this skill is invoked, parse the user's message and update the correct Notion database.

## Notion Database References

- **Weekly Progress & Health** — data source: `collection://155e2721-297f-42a9-8e3f-72fe0894f2aa`
- **Study Roadmap** — data source: `collection://1832f730-cb7f-46dd-a8e2-4e2a886e03a2`

## Steps

1. **Parse the user's input.** Identify which fields are being updated:
   - **Weight** — any mention of weight with a number (e.g. "weight 84kg", "84.5 kg today")
   - **Workouts** — any mention of workouts completed (e.g. "3 workouts this week" → "3/4")
   - **Phase** — any mention of switching phase (e.g. "starting AWS" → "Phase 2: AWS")
   - **DDIA chapter** — any mention of reading/finishing a chapter (e.g. "finished Replication", "reading chapter 8")
   - The user may provide multiple updates in one message. Handle all of them.

2. **For Weight, Workouts, or Phase updates:**
   a. Use the Notion `search` tool to find this week's row in the Weekly Progress & Health database. Search within `data_source_url: "collection://155e2721-297f-42a9-8e3f-72fe0894f2aa"` for the current week number or date.
   b. If **no row exists** for the current week:
      - Get today's date.
      - Determine the week number (e.g. "Week 1", "Week 2", etc.) by calculating weeks since 2026-03-22 (sprint start date). Week 1 starts on 2026-03-22.
      - Create a new row with the `notion-create-pages` tool:
        - Parent: `data_source_id: "155e2721-297f-42a9-8e3f-72fe0894f2aa"`
        - Set `"Week"` to the week label (e.g. "Week 1")
        - Set `"date:Start Date:start"` to today's date (YYYY-MM-DD format)
        - Set `"date:Start Date:is_datetime"` to `0`
   c. Update the row using `notion-update-page` with the relevant properties:
      - Weight → `"Weight [kg]"` (number)
      - Workouts → `"Workouts Completed"` (one of: "0/4", "1/4", "2/4", "3/4", "4/4")
      - Phase → `"Phase"` (one of: "Phase 1: DDIA", "Phase 2: AWS")

3. **For DDIA chapter updates:**
   a. Use the Notion `search` tool to find the chapter in the Study Roadmap database. Search within `data_source_url: "collection://1832f730-cb7f-46dd-a8e2-4e2a886e03a2"` for the chapter name.
   b. Fetch the page to get its current properties.
   c. Update the page's `"Status"` property:
      - If the user says "finished", "completed", "done" → set to `"Done"`
      - If the user says "reading", "started", "working on" → set to `"In progress"`
   d. If the user provides a completion date, set `"date:Target Completion:start"` to that date.

4. **Confirm** what was updated. Be concise — one line per update. Example:
   > Updated Week 3: Weight → 84 kg, Workouts → 3/4
   > Study Roadmap: "Replication" → Done
