# Project conventions

- `DA` means the user wants a direct answer.
- `NC` means the user wants no code in the response or task output.
- `NA` means no alterations: files and other project state may be inspected and discussed, but must not be modified.

## Architecture

- No logic in UI, no UI in logic.
- Keep widgets stateless for as long as doing so remains natural and maintainable.
- Apply this separation pragmatically, not dogmatically. Prefer Flutter's reliable built-in stateful solutions when they already encapsulate a task appropriately; do not replace them with a fragile stateless widget and separated controller merely to satisfy the rule mechanically.
