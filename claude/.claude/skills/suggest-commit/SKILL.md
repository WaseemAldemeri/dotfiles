---
name: suggest-commit
description: Analyzes only staged files in the current directory and generates a concise, bulleted commit message without actually committing.
argument-hint: [optional context]
---
# Suggest Commit

When this skill is invoked, look strictly at the staged changes to suggest a commit message.

1. Run `git status` to identify which files are currently staged for commit.
2. Run `git diff --cached` to read the actual code changes. Do NOT run a standard `git diff` or look at unstaged files.
3. Generate a concise commit message based ONLY on the staged changes.
4. Format: A short, imperative subject line, a blank line, and bullet points explaining what was changed and why.
5. **CRITICAL:** Do NOT execute any commit commands. Just output the suggested text.
