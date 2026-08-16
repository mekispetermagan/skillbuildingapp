# Project conventions

- `DA` means the user wants a direct answer. It also implies `NC` and `NA`.
- `NC` means the user wants no code in the response or task output.
- `NA` means no alterations: files and other project state may be inspected and discussed, but must not be modified.
- `MS` means "Does the above make sense?" It implies `DA`, `NC`, and `NA`.
- `FI` means "Do you need further information before starting?" It implies `DA`, `NC`, and `NA`.
- `GA` means "Go ahead." It approves implementation of the recently discussed changes and ends `NA` for that scope.
- `ACP` means "add, commit, and push." It approves staging the relevant changes, committing them, and pushing the commit to the configured remote.

## Architecture

- No logic in UI, no UI in logic.
- Keep widgets stateless for as long as doing so remains natural and maintainable.
- Apply this separation pragmatically, not dogmatically. Prefer Flutter's reliable built-in stateful solutions when they already encapsulate a task appropriately; do not replace them with a fragile stateless widget and separated controller merely to satisfy the rule mechanically.
