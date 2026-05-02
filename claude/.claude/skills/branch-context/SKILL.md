---
name: branch-context
description: Compares the current branch with the previous branch, reads new/changed files, and summarizes the architectural and logical changes.
argument-hint: [optional context]
---
# Branch Context

When this skill is invoked, you must act as a context engine for the current Git branch. Follow these exact steps:

1. Run `git rev-parse --abbrev-ref @{-1}` or determine the base branch (e.g., main).
2. Run `git diff @{-1}...HEAD` to see the changes.
3. Identify any newly created files and read their contents using `cat`.
4. Provide a concise summary of what this branch is trying to achieve architecturally and logically. 
5. Do not make any code changes.

