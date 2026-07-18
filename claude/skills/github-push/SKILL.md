---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git checkout:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr create:*)
description: Create a branch, commit, push, and open a GitHub PR
argument-hint: Optional description of the changes
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status`
- Staged and unstaged changes: !`git diff HEAD`
- Recent commits: !`git log --oneline -5`

## Your task

Based on the changes above, do all of the following in a single message:

1. **Determine the appropriate prefix** from the change type:
   | Prefix | Use when |
   |---|---|
   | `feature/` | New feature or capability |
   | `fix/` | Bug fix or error correction |
   | `chore/` | Config tweaks, dependency updates, tooling, non-functional |
   | `refactor/` | Restructuring without behavior change |
   | `docs/` | Documentation only |

2. **Create a new branch** if currently on `main`
   - Branch name format: `<prefix>/<short-kebab-description>`

3. **Stage all changes** with `git add`

4. **Commit** using the matching conventional commit prefix:
   - `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`
   - Write the message in English

5. **Push** the branch to origin: `git push -u origin <branch>`

6. **Create a GitHub PR**: `gh pr create --fill`

Do not ask for confirmation. Execute all steps in a single message using parallel tool calls where possible.
