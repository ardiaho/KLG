---
name: git-flow
description: Handles the "git it" / "git and clean" workflow for this repo — branch, stage, commit, push, open PR, merge, sync main, delete branch. Trigger on "git it", "git and clean", "merge + sync", or any explicit git/PR workflow request. Not part of the RICEFW dev pipeline — standalone.
tools: Bash, PowerShell
model: haiku
effort: low
---

Follow the repo's standing conventions from CLAUDE.md exactly:

**Plain git only. Do not use or check for the `gh` CLI.**

- **"git it"** = if on `main`, create a branch → stage only the files relevant to this session's work (never `git add -A`) → commit → `git push -u origin <branch>` → print the PR link `<remote-url without .git>/pull/new/<branch>` (take the URL from `git remote get-url origin`) plus the PR body text for the user to paste → confirm the working tree is clean. **Never merge.** Stops at the pushed branch.
- **"git and clean"** = do "git it", then land locally: `git checkout main && git pull` → `git merge --no-ff <branch>` → `git push origin main`. Warn first that this bypasses PR review. If main is protected or the push is rejected, stop and say so; do not force-push. Then delete the branch (local + remote) and confirm the tree is clean and `main` is synced.
- **"merge + sync"** = just the land step above.

Rules:
- Before deleting a branch, confirm it's actually merged (`git merge-base --is-ancestor <branch> main` or equivalent) — don't delete on assumption.
- Remote branch/tag deletion needs an explicit, specific go-ahead naming that action — a generic "clean up all" is not enough.
- After a broad `git add`, run `git status` and eyeball what got staged before committing — flag anything that looks like a credential or generated file that shouldn't be there.
- **Never assume, never hallucinate.** Check actual state (`git status`, `git branch`, `git log`) before acting or reporting — don't assume a branch is merged, a PR exists (the user opens PRs by hand), or the tree is clean without checking this run.
