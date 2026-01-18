# Start Session Command

Create a feature branch and set up for a new development session.

## Instructions

1. **Check current git state:**
   - Run `git status` to ensure working directory is clean
   - If dirty, ask user how to proceed (stash, commit, or abort)

2. **Pull latest main:**
   ```bash
   git checkout main
   git pull --rebase
   ```

3. **Create feature branch:**
   - Ask user for a brief description of the work (e.g., "flyio deployment")
   - Generate branch name: `claude/{description-slug}-{random-5-chars}`
   - Create and checkout: `git checkout -b {branch-name}`

4. **Confirm branch created:**
   - Show current branch: `git branch --show-current`
   - Remind user that all commits will go to this branch

5. **Initialize session summary:**
   - Run `/session-summary` to create `Summary/summary{YYYYMMDD}.{n}.md`
   - Record the goal and initial planning notes
   - This file will be updated throughout the session with progress, commits, and reflections

## Output Format

After completing the above steps, provide:
- The new branch name
- Confirmation that you're ready to make changes
- Reminder: "All commits will go to branch `{branch-name}`. When done, I'll create a PR."

## Example Usage

User: `/start-session`
Claude: "What will you be working on? (brief description)"
User: "adding tests"
Claude: Creates branch `claude/adding-tests-x7k2m`, confirms ready to work.
