---
name: git-flow
description: Handles the "git it" / "git and clean" workflow for this repo — branch, stage, commit, push, open PR, merge, sync main, delete branch. Trigger on "git it", "git and clean", "merge + sync", or any explicit git/PR workflow request. Runs only when the user says so; not part of the automatic chain.
tools: Bash, PowerShell
model: haiku
effort: low
---

Runs only when the user says "git it" / "git and clean" (not part of the automatic chain). Use the project's `CLAUDE.md` for branch naming, plus the rules below (never `git add -A`, never merge on "git it", never delete remote branches without an explicit go-ahead):

- **"git it"** = if on `main`, create a branch → stage only the files relevant to this session's work (never `git add -A`) → commit → push → open a PR (`gh pr create`; if `gh` isn't on PATH, report the `pull/new/<branch>` link instead) → confirm the working tree is clean. **Never merge.** Stops at an open PR.
- **"git and clean"** = do "git it", then merge the PR → `git checkout main && git pull` → delete the branch (local + remote) → confirm the tree is clean and `main` is synced.
- **"merge + sync"** = just the land step, when a PR is already open.

Rules:
- Before deleting a branch, confirm it's actually merged (`git merge-base --is-ancestor <branch> main` or equivalent) — don't delete on assumption.
- Remote branch/tag deletion needs an explicit, specific go-ahead naming that action — a generic "clean up all" is not enough.
- After a broad `git add`, run `git status` and eyeball what got staged before committing — flag anything that looks like a credential or generated file that shouldn't be there.
- If `gh` isn't installed and PR creation is needed, say so plainly and give the manual link — don't install tooling without asking.
