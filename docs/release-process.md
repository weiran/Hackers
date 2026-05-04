# Release Process

This document describes the Hackers iOS TestFlight release workflow. App Store submission is intentionally manual and protected; the automated release path stops after a validated TestFlight build is uploaded and distributed to internal testers.

## Release Model

Releases are source-controlled and tag-driven:

* A release-prep change updates the app version and any user-facing release content.
* A GitHub Release stores the TestFlight "What to Test" notes.
* The `vX.Y.Z` tag triggers the protected TestFlight workflow.
* Fastlane resolves the next valid App Store Connect build number, signs the app and action extension with match, archives, uploads, waits for processing, applies the changelog, and distributes to internal testers.

The release workflow is `.github/workflows/release-testflight.yml`.

## Prerequisites

Before starting a release, confirm:

* `master` is green for required checks: `lint`, `build`, and `test`.
* The `testflight` GitHub Environment exists and requires approval.
* The `testflight` environment has these secrets:
  * `APP_STORE_CONNECT_API_KEY_ID`
  * `APP_STORE_CONNECT_ISSUER_ID`
  * `APP_STORE_CONNECT_API_KEY_P8`
  * `MATCH_GIT_URL`
  * `MATCH_PASSWORD`
  * `MATCH_GIT_BASIC_AUTHORIZATION` or equivalent match repo access
* The App Store Connect API key has enough access to read builds, upload builds, update TestFlight metadata, and distribute to testers.
* The match repository contains App Store signing assets for both bundle IDs:
  * `com.weiranzhang.Hackers`
  * `com.weiranzhang.Hackers.ActionExtension`

## Prepare A Release

1. Decide the next marketing version, for example `5.3.1`.
2. Update `MARKETING_VERSION` in `Hackers.xcodeproj` for both targets:
   * `Hackers`
   * `HackersActionExtension`
3. Update any app-facing "What's New" content if the release includes visible user changes.
4. Run validation locally when practical:

```bash
./run_tests.sh
```

5. Commit and push the release-prep change to `master` after required checks pass.

## Create Release Notes

Create or update the GitHub Release before triggering TestFlight. The release body becomes the TestFlight "What to Test" text.

Use concise, user-facing bullets. Example:

```bash
gh release create v5.3.1 \
  --target master \
  --title "5.3.1" \
  --notes-file release-notes.txt
```

If the release already exists:

```bash
gh release edit v5.3.1 --notes-file release-notes.txt
```

## Trigger TestFlight

Tag format must be `vX.Y.Z`, and the tag version must match `MARKETING_VERSION`.

```bash
git tag v5.3.1 master
git push origin refs/tags/v5.3.1
```

The tag push starts `Release TestFlight`. Approve the protected `testflight` deployment in GitHub Actions.

Manual dispatch is also supported:

```bash
gh workflow run release-testflight.yml -f release_tag=v5.3.1
```

## Build Number Handling

Do not manually bump `CURRENT_PROJECT_VERSION` just to release.

The `ios beta` fastlane lane queries App Store Connect for the current `MARKETING_VERSION`:

* latest TestFlight build number
* latest App Store build number

It then uses:

* `latest + 1` when a previous build exists for that marketing version
* otherwise `max(source-controlled CURRENT_PROJECT_VERSION, 1)`

The resolved build number is applied to both `Hackers` and `HackersActionExtension` before archive.

## Monitor Release

Watch the workflow:

```bash
gh run list --workflow release-testflight.yml --limit 5
gh run watch <run-id> --exit-status
```

Expected successful log milestones:

* `Archive Succeeded`
* `Successfully exported and signed the ipa file`
* `Successfully uploaded package to App Store Connect`
* `Successfully finished processing the build`
* `Successfully set the changelog for build`
* `Successfully distributed build to Internal testers`
* `Uploaded Hackers X.Y.Z (N) to TestFlight`

The workflow uploads release artifacts for 90 days:

* `.ipa`
* `.xcarchive`
* `.dSYM`
* release `.xcresult`
* xcodebuild logs
* simulator diagnostics
* `build-number.txt`
* `what-to-test.txt`

## Verify In App Store Connect

After the workflow succeeds, confirm the build appears in App Store Connect/TestFlight and is valid. A direct API check should show the released version, resolved build number, and `VALID` processing state.

The GitHub workflow summary also records the tag and uploaded build number.

## Failure Handling

If the release fails:

1. Do not delete secrets or signing assets without confirming the error.
2. Inspect the failed job logs and uploaded `testflight-artifacts`.
3. Fix the release automation or project signing issue on `master`.
4. Push the fix.
5. Move the release tag to the fixed commit only if the failed tag did not produce a usable TestFlight build:

```bash
git tag -f v5.3.1 HEAD
git push --force origin refs/tags/v5.3.1
```

6. Approve the new protected TestFlight deployment and monitor it to completion.

Only force-move a release tag during an in-progress failed release recovery. Once a TestFlight build has completed successfully, treat the tag as immutable.

## App Store Promotion

`.github/workflows/release-appstore.yml` is a protected placeholder. It records the guardrail that automatic App Review submission is disabled.

Promote a validated TestFlight build manually in App Store Connect after human review.
