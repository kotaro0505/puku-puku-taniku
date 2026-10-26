# Godot AdMob integration

- Upstream: `godot-sdk-integrations/godot-admob`
- Release: `v7.0`
- iOS archive: `AdmobPlugin-iOS-v7.0.zip`
- Archive SHA-256: `96aada90e397e54ecd7c60676a44bc06b5ead17998302b4cf179851e1f90b3cc`
- Bundled Google Mobile Ads iOS SDK (Swift Package): `12.14.0`
- Resolved Google User Messaging Platform SDK: `3.1.0`

Local release hardening:

- The iOS export plist uses Google's scoped ATS exceptions
  (`NSAllowsArbitraryLoadsForMedia` and `NSAllowsArbitraryLoadsInWebContent`)
  instead of a blanket `NSAllowsArbitraryLoads` exception.
- Google Mobile Ads 12.14.0 predates the TFAT
  (`GADRequestConfiguration.ageRestrictedTreatment`) API introduced in 13.3.0.
  This plugin therefore still exposes only legacy TFCD/TFUA values; both remain
  `UNSPECIFIED` because the game currently has no verified age signal.
- The checked-in v7.0 archive is retained byte-for-byte as the reviewed upstream
  baseline. Before every Codemagic iOS export, `scripts/ci/build_admob_plugin.sh`
  checks out upstream commit `4b4ddceab0be81f0dcb12a6313038dba6cf9eacf`,
  applies the minimal local UMP bridge, and rebuilds both XCFramework variants
  against the exact Godot 4.7.2 stable headers and iOS 15.6 deployment target.
- The local native bridge exposes UMP 3.1.0's
  `privacyOptionsRequirementStatus`, `presentPrivacyOptionsForm`, and
  `canRequestAds`, plus a dismissal signal. The build fails before export if the
  pinned source changes, the SDK versions drift, or any bridge symbol is absent.
- This native bridge does not change the Google Mobile Ads SDK version. TFAT is
  therefore deliberately deferred instead of coupling the UMP fix to the
  breaking 12.x-to-13.x SDK migration.

The runtime/editor sources and upstream iOS plugin binaries are vendored, while
the release XCFramework is reproducibly rebuilt and verified on Codemagic's
macOS runner. Application and ad-unit IDs are not stored here; Codemagic
generates the ignored configuration files at build time.
