# Toasty

WoW: Forever addon by cnhermey: camping status icons (Bag, Buffs, Rest, 5% XP)
and tooltips for camp objects. Listed as "Toasty Buffs" (CurseForge 1813597);
the addon folder, TOC and globals are `ToastyBuffs` (the `Toasty` folder name
belongs to another Forever addon, Toasty Toasts). Player's install:
`C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\ToastyBuffs\`. Follow the `wow-forever-addon-dev` skill's
conventions.

## Releasing (automatic)

Every update ships as a release, and GitHub builds it, not Claude: sessions
can't create releases or push tags.

1. Bump `## Version: X.Y.Z` in `ToastyBuffs.toc` and the README title
   `# Toasty (vX.Y.Z)` (patch for fixes, minor for features).
2. Add `## X.Y.Z (YYYY-MM-DD)` at the top of `CHANGELOG.md` with bullets
   written for players. This section becomes the release notes.
3. Commit and push to `main`. `.github/workflows/release.yml` then zips the
   addon as `ToastyBuffs/` and creates release `vX.Y.Z` with `ToastyBuffs-vX.Y.Z.zip`.
   It skips a version that already has a release.
4. Copy the changed files into the player's AddOns folder too, as usual.

After pushing, check the run:
`gh api repos/cnhermey/toasty/actions/runs --jq '.workflow_runs[0] | {status, conclusion, html_url}'`
and the release: `gh api repos/cnhermey/toasty/releases/latest --jq '{tag_name, html_url}'`.

The same workflow uploads the zip to CurseForge (Forever, game version
1.60.1) once `CF_API_KEY` is a repository secret and ToastyBuffs.toc has
`## X-Curse-Project-ID: <id>`; until then that step skips. To resend the
current version to CurseForge only: Actions → Release → Run workflow with
"Upload to CurseForge" ticked (or `gh api -X POST
repos/cnhermey/toasty/actions/workflows/release.yml/dispatches -f ref=main
-F 'inputs[curseforge]=true'`). Listing text and logo: `.github/curseforge.md`,
`.github/curseforge-logo.png`.

Files that shouldn't be in the zip go in `.gitattributes` as `export-ignore`.
