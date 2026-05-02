---
name: draft-pr
description: Fetches Linear context and git diffs to generate a short, high-level Markdown PR description in a copy-paste block.
argument-hint: [optional context]
---
# Draft PR

When this skill is invoked, follow these steps to generate a concise PR description:

1. **Context Gathering:**
   - Run `git branch --show-current` to get the current branch name.
   - Extract the Linear issue ID from the branch name.
   - Use the Linear MCP to fetch the ticket title and description for background context.
   - **Note:** Do NOT include the ticket link or ID in the final output.

2. **Code Analysis:**
   - Run `git rev-parse --abbrev-ref @{-1}` for the base branch.
   - Run `git diff @{-1}...HEAD` to identify the key changes.

3. **Output Generation:**
   - Generate a short and punchy PR description.
   - **Format:**
     - A brief "Description" paragraph (1-2 sentences) explaining the goal of the PR.
     - An "Overview" bulleted list (3-4 points) highlighting the main changes without being overly technical.
   - Wrap the entire output in a single Markdown code block (using ```markdown) for easy copying.

4. **CRITICAL:** Do NOT execute any `gh` commands. Just output the suggested text.
