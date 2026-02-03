# Commit Changes

Create a git commit for the current changes.

## Instructions

1. Run `git status` to see all untracked and modified files (never use -uall flag)
2. Run `git diff` to see staged and unstaged changes
3. Run `git log --oneline -5` to see recent commit message style

4. Analyze changes and draft a commit message:
   - Use conventional commit prefixes: feat:, fix:, refactor:, docs:, chore:, test:
   - First line: concise summary (50 chars or less if possible)
   - If needed, add blank line then bullet points for details
   - Focus on "why" not "what"

5. Stage relevant files with `git add`

6. Create the commit using HEREDOC format:
```bash
git commit -m "$(cat <<'EOF'
<type>: <summary>

- Detail 1
- Detail 2
EOF
)"
```

## Rules

- NEVER add Co-Authored-By lines or any AI/Claude attribution
- NEVER use --no-verify or skip hooks unless explicitly requested
- NEVER amend commits that have been pushed
- Do not commit files containing secrets (.env, credentials, etc.)
- If no changes to commit, inform the user instead of creating empty commit
