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
python tools/verify_published_release.py v3.0.0-alpha.2 /tmp/alpha2-public
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
