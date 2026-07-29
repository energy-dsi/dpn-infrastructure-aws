# Contributing

1. Create a focused branch.
2. Run `tofu fmt -check -recursive`.
3. Run `tofu validate` in both the bootstrap and main stack where backend access is available.
4. Run `shellcheck infrastructure/Tofu/scripts/deploy.sh`.
5. Scan for credentials and organization-specific identifiers.
6. Explain architectural or compatibility changes in the pull request.

Do not include real customer configuration in tests, examples, screenshots, issues, or commit history.
