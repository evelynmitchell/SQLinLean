# Session Summary Command

Create or update a session summary file to document the work session.

## File Location

Create summaries in: `Summary/summary{YYYYMMDD}.{n}.md`
- `YYYYMMDD` is today's date
- `{n}` is a sequence number (1, 2, 3...) for multiple sessions on the same day
- Example: `Summary/summary20260118.1.md`

## Instructions

1. **Check for existing summaries today:**
   - Look in `Summary/` directory for files matching today's date
   - Increment the sequence number for a new session, or update the existing one if continuing

2. **Create/Update the summary file with these sections:**

```markdown
# Session Summary - {YYYY-MM-DD} #{n}

## Goal
{Brief description of what we set out to accomplish}

## Planning
{Key decisions made, approaches considered, architecture discussions}

## Work Completed
{List of subtasks accomplished with brief descriptions}

## Commits & PRs
{List of commits made with hashes and messages}
{Any PRs created with links}

## Reflections

### What went well
- {Positive outcomes, efficient approaches, good decisions}

### What could be improved
- {Challenges encountered, inefficiencies, things to do differently}

### Potential skills to create
- {Recurring patterns that could become /commands}
- {Workflows that could be automated}

## Next Steps
{What remains to be done, follow-up items}
```

3. **Update throughout the session:**
   - Add commits as they're made
   - Update "Work Completed" after each subtask
   - Fill in reflections before ending the session

## When to Use

- At session start: Create the file with Goal and initial Planning
- During session: Update Work Completed and Commits as progress is made
- At session end: Complete Reflections and Next Steps

## Example

User: `/session-summary`
Claude: Creates or updates `Summary/summary20260118.1.md` with current session state.
