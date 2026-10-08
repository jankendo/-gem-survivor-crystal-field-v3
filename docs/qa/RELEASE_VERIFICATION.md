# Release verification — alpha.2

Canonical PUBLIC repository: `jankendo/-gem-survivor-crystal-field-v3`.
The leading hyphen is intentional. alpha.1 is immutable and not the latest UI build.

`RELEASE_VERSION` selects a new unused prerelease. Final main is frozen, then all
four required main-push workflows must succeed at that exact40-character SHA:
Fast CI, Balance, Performance, Build Windows and iOS Release. `release_gate.py`
queries actual latest runs at that SHA and requires current main equality. Tag
builds export both platforms again from the same immutable source. No workflow
configuration is treated as successful execution evidence.

Godot4.7 -> Windows Release EXE with embedded PCK -> native pack smoke -> ZIP.
Godot4.7 -> macOS Xcode project -> Release/iphoneos/arm64 xcodebuild with signing
allowed/required NO, identity/team empty -> app -> Payload -> unsigned IPA.
Validators require ZIP integrity, exact app/plist/bundle/display/version/build,
Mach-O arm64, PCK, Assets.car, launch assets and icons, absence of provisioning and
Apple distribution identity; actual byte hashes are generated. A Mach-O linker
ad-hoc hash, if present, is not an Apple distribution signature.

Both platform manifests include source repository/SHA, release version, platform,
signing, artifact size/hash and generating workflow. `assemble_release.py` rejects
mixed versions/SHA/bytes. `publish_release.py` first creates or resumes a draft,
uploads the complete five-file set, verifies GitHub sizes/digests, then publishes.
Public releases are never overwritten. Seven Python regressions cover SHA/hash/
version isolation and failed-upload/draft recovery/public immutability.

Expected assets: unsigned IPA, Windows ZIP, SHA256SUMS.txt, RELEASE_MANIFEST.json,
IOS_UNSIGNED_README.md. Public independent verification is executable:

```
python tools/verify_published_release.py v3.0.0-alpha.4 /tmp/alpha2-public
```

This downloads all five actual public browser asset URLs, checks API size/digest,
SHA256SUMS and both source manifests, revalidates both archives and compares current
main/tag/Windows/IPA source equality. Its generated `published-verification.json`
is execution proof with actual SHA and URLs. This checked-in document defines the
procedure and records pre-publication local evidence; it does not claim a future
publication PASS. Actual final runs/public re-download are reported by the release
manifest, GitHub Actions and final delivery report, avoiding a post-build source
commit solely to record its own hash.

Physical installation requires user signing. No certificate/profile/team secret.
No TestFlight/App Store/device-install or human-playtest PASS is inferred.

## alpha.3 release recovery

Actual main3cae956 had all four required workflows green;tag build37703164950
produced validated Windows and unsigned arm64 IPA. Publication stopped at draft
lookup: GitHub's published-only `GET /releases/tags/:tag` returns404 for a draft.
No incomplete public Release was created. Empty draft406253234 was removed;
alpha.2 tag still points to3cae956 and is not moved. Source now uses authenticated
paginated release listing and stable Release ID for draft validation/publication.
First-creation regression reproduces that API contract;12 Python checks PASS.
App build metadata is read from actual export presets instead of hardcoded values.
New alpha.3 /iOS30003 /Windows3.0.0.3 is rebuilt on its new final source SHA;
alpha.2 artifacts are never substituted. Gameplay source/1766 assertions are
unchanged by this release-only repair. Final required CI/public verification must
be executed again at the new SHA; evidence is reported at delivery/manifest.

## alpha.4 authoritative creation/transport recovery

Actual alpha.3 tag37705013424 again built/validated both platforms, but the
new draft was absent from the immediate authenticated list. It stopped before
upload/publication; draft406260273 remains private for the controlled live probe.
Tagsalpha.1/2/3 are never moved. The final publisher no longer re-queries an index
after creation: REST POST returns the authoritative ID/upload URL, files stream
directly to that ID, and ID-based metadata/asset hashes guard publication.
Partial retries skip matching assets; public releases cannot be overwritten.
15 Python checks include an index that never updates, tag/source mismatch,
partial resume and upload-host/public-release protection. Workspace direct upload
received401 (not successful); the same small, automatically cleaned probe runs
under actual Actions token against an unpublished draft via release-protocol.yml.
Probe success must be read from the actual run, never assumed. New alpha.4 builds
with iOS30004/Windows3.0.0.4 and new final SHA; prior binaries are not substituted.
