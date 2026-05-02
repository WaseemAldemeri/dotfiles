---
name: brag-doc-generator
description: Analyzes git diffs across waj, waj-db, and whitelabel_v2.0 repos, fetches Linear/Slack context via MCP, and generates high-impact CV bullet points in BRAG_DOC.md.
allowed-tools: [linear_get_issue, slack_search_messages, ls, cat, run_terminal_command]
---

# Brag Document Generator Skill

Use this skill when the user wants to document their recent work across the WAJ ecosystem for their career log, CV, or "Brag Document."

## Workflow

1. **Environment Audit**: 
   - Check the three subdirectories: `waj`, `waj-db`, and `whitelabel_v2.0`.
   - Identify active feature branches (not `main` or `master`) and extract the Linear Issue ID (e.g., WAJ-123).

2. **Multi-Source Context Extraction**:
   - **Linear**: Use `linear_get_issue` to fetch the title, description, and "Why" behind the task.
   - **Slack**: Use `slack_search_messages` to find conversations related to the Issue ID or project keywords. Look for architectural debates, security concerns, or proactive suggestions I made.

3. **Forensic Technical Analysis**:
   - For each active feature branch across the three repos, run `git diff main...HEAD`.
   - Synthesize the code changes with the Slack/Linear context focusing on:
     - **Architectural Patterns**: (e.g., Provider pattern in Flutter, Edge Functions, Decoupling).
     - **Security & Reliability**: (e.g., Webhook refactors, idempotency, error handling).
     - **The "Hard Part"**: Identify the specific engineering challenge I solved (e.g., race conditions, legacy debt).

4. **Output Generation**:
   - Append a new entry to the root `BRAG_DOC.md` using the following format:

### [Linear Title] ([Issue ID]) - [Month, Year]
- **The Context**: (1 sentence on the business problem vs. the technical risk).
- **Engineering Impact**: 
  - (Bullet 1: Architectural win - "Architected X to enable Y")
  - (Bullet 2: Security/Reliability win - "Hardened Z by implementing [Technical Solution]")
  - (Bullet 3: Complexity win - "Solved [The Hard Part] by [How I solved it]")
- **The Rationale**: (Brief mention of the suggestion or concern I raised in Slack/Linear that led to this solution).
- **Repos Involved**: (e.g., waj-db, whitelabel_v2.0)

## Constraints
- Always preserve existing content in `BRAG_DOC.md`; only append.
- Use professional, "FAANG-level" action verbs (Spearheaded, Orchestrated, Optimized, Hardened).
- Focus on the "System Designer" perspective, not just the "Feature Builder."
