#test
## Versioning
We follow Semantic Versioning `MAJOR.MINOR.PATCH` or simply put as `BREAKINGCHANGE.FEATURE.FIX`:

`MAJOR` for changes that will break existing code using the module.

`MINOR` for new features that don't affect existing functionality.

`PATCH` for non-functional changes.

Every release is tagged in Git as `vX.Y.Z` (e.g. v1.2.2).

## Commit Conventions
We enforce Conventional Commits to drive automated tooling:

Features: use `feat(scope): description`

Bug fixes: use `fix(scope): description`

Breaking changes: include a `!` after the type or a `BREAKING CHANGE:` footer, e.g.

```
feat(api)!: remove deprecated endpoint
```
 OR
```
feat(api): remove deprecated endpoint

with a footer:
BREAKING CHANGE: remove deprecated endpoint
```

## Changelog
We keep a single CHANGELOG.md in the repo root.
History of past releases lives under dated version headings once released.

## Release Script
All release tasks are automated via the `scripts/release.sh` helper:

It validates branch & working tree, bump version, overwrites VERSION in `package.json`, auto-generate changelog entries, commits both files and creates a Git tag vX.Y.Z.

To make sure it's executable run , `chmod +x scripts/release.sh`

### How It Works
- Open a PR against main, get it reviewed and merged.
- Run Release Script; `./scripts/release.sh X.Y.Z`
- After the script completes, manually run `git push origin main vX.Y.Z` and create the GitHub Release at: https://github.com/oaknational/oak-terraform-modules/releases/. This gives us an opportunity to review before pushing
- At release time, you have to change "Unreleased" to the version number and add a new "Unreleased" header at the top.