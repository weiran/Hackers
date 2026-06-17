# Release Process

This document describes the Hackers iOS release workflow. App Store promotion remains manual; automation stops after a validated TestFlight build is uploaded and distributed to TestFlight external testers, including TestFlight beta review when Apple requires it.

## Release Model

Releases are source-controlled and tag-driven:

* A release-prep change updates app-facing metadata and code as needed.
* Every TestFlight build is tagged with a full semver-with-build tag: `v<MARKETING_VERSION>+<CURRENT_PROJECT_VERSION>`.
  * Example: `v5.3.2+159`
* The markdown title/body of the GitHub Release is used as TestFlight "What to Test."
* A release tag exists first, then the protected TestFlight workflow runs and uploads that exact version/build.
* Every TestFlight build is distributed to external testers. If Apple requires beta review for that build, the TestFlight workflow should put it through beta review as part of external distribution.
* Published vs Draft status on GitHub Releases is the only release-state differentiator:
  * draft = built and available internally, not yet marked for App Store
  * published = selected for App Store release candidacy
* The release workflow is `.github/workflows/release-testflight.yml`.

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
* The App Store Connect API key has enough access to read builds, upload builds, update TestFlight metadata, submit for TestFlight beta review when required, and distribute to external testers.
* The match repository contains App Store signing assets for both bundle IDs:
  * `com.weiranzhang.Hackers`
  * `com.weiranzhang.Hackers.ActionExtension`

## Prepare A Release

1. Decide whether this build is a new marketing version (`5.3.2`) or another build for the current marketing version.
2. Update `MARKETING_VERSION` in `Hackers.xcodeproj` for both targets when needed:
   * `Hackers`
   * `HackersActionExtension`
3. Bump `CURRENT_PROJECT_VERSION` for the build you want to create on both targets:
   * this value is the `+N` build-part of the tag
   * this must increase over the previous build for the chosen marketing version
   * example tag values from this point forward:
     * `v5.3.1+158` (last released build)
     * `v5.3.2+158`
     * `v5.3.2+159`
4. Update any app-facing "What's New" content if the build includes visible user changes.
5. Run validation locally when practical:

```bash
./run_tests.sh
```

6. Commit and push the release-prep change to `master` after required checks pass.

## Create Release Notes

Create or update the GitHub Release before triggering TestFlight. The release body becomes the TestFlight "What to Test" text.

Note rules:

* draft releases: generate notes from the previous tag (single-build delta)
* published releases: generate notes from the previous **published** release (cumulative release changelog)

Use concise, user-facing bullets. Example:

```bash
tag=v5.3.2+158

gh release create "$tag" \
  --target master \
  --title "$tag" \
  --notes-file release-notes.txt \
  --draft
```

If the release already exists:

```bash
gh release edit "$tag" --notes-file release-notes.txt
```

For an App Store-released candidate, publish the same release once its notes are complete:

```bash
gh release edit "$tag" --draft=false
```

For App Store releases, release notes should be cumulative since the last **published** release. When the previous published tag is known, you can generate a cumulative body:

```bash
gh release create "$tag" \
  --target master \
  --title "$tag" \
  --generate-notes \
  --notes-start-tag v5.3.1+158 \
  --draft
```

To correct existing draft releases created with the older logic (post-`5.3.1`), you can regenerate notes directly with the same rules:

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

## Trigger TestFlight

Tag format must be `v<MARKETING_VERSION>+<CURRENT_PROJECT_VERSION>`.
The build part is required for every build tag.


When you need another build for the same marketing version, bump `CURRENT_PROJECT_VERSION`, create a new release-prep commit, and tag it with the new value.

When a tag push starts `Release TestFlight`, approve the protected `testflight` deployment in GitHub Actions.

```bash
tag=v5.3.2+158

git tag "$tag" master
git push origin "refs/tags/$tag"
```

Manual dispatch is also supported:

```bash
gh workflow run release-testflight.yml -f release_tag=v5.3.2+158
```

## Build Number Handling

`CURRENT_PROJECT_VERSION` is now explicit in the tag and must match what is built:

* `MARKETING_VERSION` controls the release family (`5.3.2`)
* `CURRENT_PROJECT_VERSION` controls the build build (`158`)

The release lane expects this exact build value in the tag:

* workflow input `release_tag` should include `+N` and `N` must be greater than the prior build for that `MARKETING_VERSION`
* both `Hackers` and `HackersActionExtension` must use that build value before archive
* build numbers are monotonic; do not create tags in descending build order

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
* `Successfully distributed build to External testers`
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
tag=v5.3.2+159

git tag -f "$tag" HEAD
git push --force origin "refs/tags/$tag"
```

6. Approve the new protected TestFlight deployment and monitor it to completion.

Only force-move a release tag during an in-progress failed release recovery. Once a TestFlight build has completed successfully, treat the tag as immutable.

## App Store Promotion

`.github/workflows/release-appstore.yml` is a protected placeholder. It records the guardrail that automatic App Review submission is disabled.

Promote a validated TestFlight build manually in App Store Connect after human review.
