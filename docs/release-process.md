# Release Process

This document describes the Hackers iOS release workflow. TestFlight upload and App Store submission are automated through protected GitHub Actions workflows; human review and protected environment approval remain required.

## Release Model

Releases are source-controlled and tag-driven:

* A release-prep change updates app-facing metadata and code as needed.
* Every TestFlight build is tagged with a full semver-with-build tag: `v<MARKETING_VERSION>+<CURRENT_PROJECT_VERSION>`.
  * Example: `v5.3.2+160`
* `MARKETING_VERSION` controls the release family, for example `5.3.2`.
* `CURRENT_PROJECT_VERSION` controls the App Store Connect build number, for example `160`.
* The GitHub Release title/body is used as TestFlight "What to Test."
* App Store release notes are separate public-facing customer copy. They must not be copied from GitHub Release notes, TestFlight notes, generated changelog output, pull request links, or `Full Changelog` links.
* Published vs draft GitHub Release status is the release-state differentiator:
  * draft = built and available internally, not yet marked for App Store candidacy
  * published = selected for App Store release candidacy
* TestFlight upload uses `.github/workflows/release-testflight.yml`.
* App Store submission uses `.github/workflows/release-appstore.yml`.

## Prerequisites

Before starting a release, confirm:

* `master` is green for required checks: `lint`, `build`, `test`, and `ui smoke`.
* The `testflight` GitHub Environment exists and requires approval.
* The `testflight` environment has these secrets:
  * `APP_STORE_CONNECT_API_KEY_ID`
  * `APP_STORE_CONNECT_ISSUER_ID`
  * `APP_STORE_CONNECT_API_KEY_P8`
  * `MATCH_GIT_URL`
  * `MATCH_PASSWORD`
  * `MATCH_GIT_BASIC_AUTHORIZATION` or equivalent match repo access
* The App Store Connect API key can read builds, upload builds, update TestFlight metadata, submit for TestFlight beta review when required, distribute to external testers, and submit App Store builds for review.
* The match repository contains App Store signing assets for both bundle IDs:
  * `com.weiranzhang.Hackers`
  * `com.weiranzhang.Hackers.ActionExtension`

## Release Checklist

1. Decide whether this is a new marketing version or another build for the current marketing version.
2. Update `MARKETING_VERSION` for both targets when needed.
3. Bump `CURRENT_PROJECT_VERSION` for both targets to the build number that will appear after `+` in the release tag.
4. Update app-facing "What's New" content when the build includes user-visible changes.
5. Draft custom App Store release notes when this build is intended for App Store submission.
6. Run local validation when practical.
7. Commit and push the release-prep change to `master` after required checks pass.
8. Tag the exact release build as `vX.Y.Z+N`.
9. Trigger or let the TestFlight workflow run, approve the protected `testflight` deployment, and monitor it.
10. Verify the processed build in App Store Connect/TestFlight.
11. Publish the GitHub Release only when selecting that build as an App Store candidate.
12. Trigger the App Store workflow with custom public release notes after human review.

## Prepare A Release

Update `MARKETING_VERSION` in `Hackers.xcodeproj` for both targets when needed:

* `Hackers`
* `HackersActionExtension`

Bump `CURRENT_PROJECT_VERSION` for both targets before tagging. This value must:

* match the `+N` build part of the tag
* be greater than the previous App Store Connect build for that marketing version
* stay monotonic for that marketing version

Example tag sequence:

* `v5.3.2+158`
* `v5.3.2+159`
* `v5.3.2+160`

Run validation locally when practical:

```bash
./run_tests.sh
./run_ui_tests.sh smoke
```

Commit and push the release-prep change to `master` after required checks pass.

## Tag And Trigger TestFlight

Tag format must be `v<MARKETING_VERSION>+<CURRENT_PROJECT_VERSION>`.

```bash
tag=v5.3.2+160

git tag "$tag" master
git push origin "refs/tags/$tag"
```

When the tag push starts `Release TestFlight`, approve the protected `testflight` deployment in GitHub Actions.

Manual dispatch is also supported:

```bash
gh workflow run release-testflight.yml -f release_tag=v5.3.2+160
```

When you need another build for the same marketing version, bump `CURRENT_PROJECT_VERSION`, create a new release-prep commit, and tag the new commit with the new `+N` value.

## TestFlight Release Notes

The TestFlight workflow resolves `artifacts/release/what-to-test.txt` before upload and creates or updates the GitHub Release for the tag. Draft releases use generated notes from the previous tag. Published releases use generated notes from the previous published release, which makes the candidate changelog cumulative.

Normal workflow-created notes are generated from GitHub release notes. Review and edit the GitHub Release body after the workflow prepares it if the generated text needs cleanup before broader TestFlight or App Store candidacy. Edits made before a TestFlight workflow run can be replaced by the workflow's generated notes.

If you need to create or replace notes manually outside the normal workflow path, use concise user-facing bullets and keep the title aligned with the tag without the leading `v`:

```bash
tag=v5.3.2+160

gh release create "$tag" \
  --target "$tag" \
  --title "${tag#v}" \
  --notes-file release-notes.txt \
  --draft
```

If the release already exists:

```bash
gh release edit "$tag" --title "${tag#v}" --notes-file release-notes.txt
```

For an App Store candidate, publish the same GitHub Release once its TestFlight notes are complete:

```bash
gh release edit "$tag" --draft=false
```

## Monitor TestFlight

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
* `Successfully distributed build to External testers`
* `Uploaded Hackers X.Y.Z (N) to TestFlight`

The workflow uploads `testflight-artifacts` for 90 days:

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

The GitHub workflow summary records the tag and uploaded build number.

## Write App Store Release Notes

App Store release notes are not the GitHub Release body and are not TestFlight "What to Test" text. Treat them as final public product copy for App Store customers.

Rules:

* Write the App Store notes specifically for the public App Store listing.
* Summarize user-visible changes in plain language.
* Keep the notes concise and useful to someone deciding whether to update.
* Do not include GitHub compare links, `Full Changelog` links, pull request links, issue links, commit hashes, generated changelog sections, markdown headings, or tester instructions.
* Do not paste the GitHub Release body or TestFlight notes into App Store Connect without rewriting them for this audience.

The App Store workflow accepts the exact release notes through the `app_store_release_notes` input and validates them before submission. The fastlane lane also rejects common GitHub/TestFlight-only content before calling App Store Connect.

The current fastlane submission sends release notes for the `en-GB` locale. Keep this intentional and update fastlane and this document together if the App Store localization changes.

## Submit To App Store Review

Promote a validated TestFlight build only after human review of the selected build and the final custom App Store release notes.

```bash
gh workflow run release-appstore.yml \
  -f release_tag=v5.3.2+160 \
  -f app_store_release_notes='Improves feed browsing and fixes issues reported by readers.'
```

Optional inputs:

* `build_number`: only use when explicitly selecting a processed App Store Connect build; it must match the `+N` value in the tag.
* `skip_app_version_update`: skip creating or updating the App Store version.
* `cancel_pending_version`: pending App Store version to cancel before submission.
* `cancel_only`: cancel the pending version without submitting a build.

The workflow runs through the protected `testflight` environment and submits the processed build for App Review. Do not submit if the final notes are copied from GitHub/TestFlight content or contain links back to GitHub.

## Failure Handling

If a release fails:

1. Do not delete secrets or signing assets without confirming the error.
2. Inspect the failed job logs and uploaded `testflight-artifacts`.
3. Fix the release automation or project signing issue on `master`.
4. Push the fix.
5. Move the release tag to the fixed commit only if the failed tag did not produce a usable TestFlight build.
6. Approve the new protected TestFlight deployment and monitor it to completion.

Only force-move a release tag during in-progress failed release recovery. Once a TestFlight build has completed successfully, treat the tag as immutable.

## Appendix: Recovery Commands

Force-move a failed release tag only before a usable TestFlight build exists:

```bash
tag=v5.3.2+160

git tag -f "$tag" HEAD
git push --force origin "refs/tags/$tag"
```

To correct existing draft releases created with older note-generation logic, regenerate draft notes directly:

```bash
GITHUB_REPOSITORY=weiran/Hackers

for tag in $(gh release list --json tagName,isDraft --limit 200 --jq '.[] | select(.isDraft == true).tagName'); do
  case "$tag" in
    v5.3.1*|v5.3.2*) ;;
    *)
      continue
      ;;
  esac

  previous_tag=$(git tag --sort=-creatordate --list 'v*' |
    awk -v TAG="$tag" 'BEGIN {seen=0} $0==TAG {seen=1; next} seen {print; exit}')

  if [ -z "$previous_tag" ]; then
    payload=$(jq -nc --arg t "$tag" '{tag_name:$t}')
  else
    payload=$(jq -nc --arg t "$tag" --arg p "$previous_tag" '{tag_name:$t, previous_tag_name:$p}')
  fi

  notes_file=$(mktemp)
  printf '%s' "$payload" |
    gh api --method POST https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/generate-notes --input - --jq .body > "$notes_file"

  gh release edit "$tag" --title "${tag#v}" --notes-file "$notes_file"
  rm "$notes_file"
done
```
