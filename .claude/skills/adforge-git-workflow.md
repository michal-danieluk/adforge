# Skill: Git Workflow for AdForge

## Philosophy
Git is your **time machine** and **safety net**. Commit often, push daily.

## Rules (Non-Negotiable)

### Rule 1: Commit After Every Meaningful Change
**"Meaningful" = 15-30 minutes of work OR completing a substep.**

Examples:
- ✅ Generated scaffold → Commit.
- ✅ Added validation to model → Commit.
- ✅ Styled form with Tailwind → Commit.
- ✅ Fixed bug in nested form → Commit.
- ❌ Changed 1 line of CSS → Wait, batch with other changes.

### Rule 2: Write Descriptive Messages
**Format:** `[Action] [What] [Why (if not obvious)]`

**Good:**
```bash
git commit -m "Add BrandColor model with primary flag validation"
git commit -m "Fix nested form not saving colors due to missing strong params"
git commit -m "Refactor Brand show view to display colors in grid layout"
```

**Bad:**
```bash
git commit -m "updates"
git commit -m "fix bug"
git commit -m "changes"
```

### Rule 3: Push to Remote 2x Per Day Minimum
- **Morning:** After completing first task.
- **Evening:** Before ending work session.

**Why:** Backup + allows human to review progress.

### Rule 4: Pull Before Starting New Task
```bash
git pull origin main
```

Prevents merge conflicts if human made changes.

---

## Standard Workflow

### Starting a New Task
```bash
git pull origin main
git status  # Ensure working directory clean
```

### During Work
```bash
# After every substep (20-30 min):
git add .
git status  # Review what you're committing
git commit -m "Descriptive message"
```

### End of Work Session
```bash
git push origin main
```

### If Stuck for 30+ Minutes
```bash
git add .
git commit -m "WIP: Stuck on [problem description]"
git push origin main
```

Then ask human for help.

---

## Commit Message Templates

### Feature Addition
```
Add [feature name]
- Detail 1
- Detail 2
```

Example:
```
Add dynamic nested form for BrandColors
- Use Stimulus controller for add/remove buttons
- Validate exactly one primary color
```

### Bug Fix
```
Fix [problem description]

Root cause: [explanation]
Solution: [what you changed]
```

Example:
```
Fix nested form not saving BrandColors

Root cause: Missing strong params whitelist
Solution: Added brand_colors_attributes to permitted params
```

### Refactoring
```
Refactor [component] to [improvement]
```

Example:
```
Refactor Brand form to use partials for color fields
```

---

## Branching Strategy (Not for MVP)

**In MVP: Work directly on `main` branch.**

Why?
- Faster iteration.
- No PR review overhead.
- Human reviews commits directly.

**Later (post-MVP):** Use feature branches + PRs.

---

## Emergency: Undo Last Commit

### If Not Pushed Yet
```bash
git reset --soft HEAD~1  # Keep changes in working directory
# OR
git reset --hard HEAD~1  # Discard changes (dangerous!)
```

### If Already Pushed
```bash
# DON'T use reset. Instead:
git revert HEAD  # Creates new commit that undoes last one
git push origin main
```

---

## Checking Commit History
```bash
git log --oneline --graph --decorate --all
# OR
git log --oneline -10  # Last 10 commits
```

---

## Checklist Before Every Commit
- [ ] `git status` – Review staged files.
- [ ] `git diff` – Check what actually changed.
- [ ] Commit message is descriptive (not "wip" or "fix").
- [ ] Code runs without errors (`rails s` works).

## Checklist Before Every Push
- [ ] All tests pass (`rails test`).
- [ ] No commented-out code left behind.
- [ ] No `binding.pry` or `debugger` statements.

---

**Use this workflow for every coding session.**
