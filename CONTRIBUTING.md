# Contributing

## Pull requests

1. Create a focused branch from the current `main` branch.
2. Run the checks in `docs/development.md` and include generated interface
   changes when applicable.
3. Open a pull request against `main` with a concise description and validation
   results.

## Merge requirements

A pull request must meet all of these requirements before it is merged:

- The Windows, Linux, and macOS validation checks pass.
- At least one project reviewer leaves an explicit `LGTM` on the pull request.
- The pull request author cannot supply the required `LGTM`.

Maintainers merge approved pull requests with GitHub's **Squash and merge**
method, then delete the merged head branch.
