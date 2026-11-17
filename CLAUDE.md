# Toasty

WoW: Forever addon by cnhermey: camping status icons (Bag, Buffs, Rest, 5% XP)
and tooltips for camp objects. Follow the `wow-forever-addon-dev` skill's
conventions.

## Releasing (automatic)

Every update ships as a release, and GitHub builds it, not Claude: sessions
can't create releases or push tags.

1. Bump `## Version: X.Y.Z` in `Toasty.toc` and the README title
   `# Toasty (vX.Y.Z)` (patch for fixes, minor for features).
2. Add `## X.Y.Z (YYYY-MM-DD)` at the top of `CHANGELOG.md` with bullets
   written for players. This section becomes the release notes.
3. Commit and push to `main`. `.github/workflows/release.yml` then zips the
   addon as `Toasty/` and creates release `vX.Y.Z` with `Toasty-vX.Y.Z.zip`.
   It skips a version that already has a release.
4. Copy the changed files into the player's AddOns folder too, as usual.

After pushing, check the run:
`gh api repos/cnhermey/toasty/actions/runs --jq '.workflow_runs[0] | {status, conclusion, html_url}'`
and the release: `gh api repos/cnhermey/toasty/releases/latest --jq '{tag_name, html_url}'`.

Files that shouldn't be in the zip go in `.gitattributes` as `export-ignore`.
