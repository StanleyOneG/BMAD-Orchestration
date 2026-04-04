# Deferred Work

## Deferred from: code review of update-generate-agents-script (2026-04-04)

- `parseSimpleYaml` doesn't handle YAML block scalars — parser is documented as flat key-value only; no current manifests use block scalars. If future manifests need multi-line values, the parser will need extending.
- `parseSkillMd` frontmatter `---` extraction uses `indexOf` (positional) rather than line-boundary matching — works with all current SKILL.md files produced by BMad installer. Could break if frontmatter values contain `---` substrings.
- `parseSimpleYaml` list items (`- `) are not indentation-checked — any `- ` prefixed line is captured as a list item for the previous key. Safe because the parser only receives flat manifest YAML, not arbitrary content.
- Partial failure exit code with `--target both` — when one platform finds agents and the other doesn't, exit code is 0. Spec says "warn but proceed" for missing dir; similar spirit applies. CI pipelines relying on exit code would miss the partial failure.
