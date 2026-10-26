# Godot AdMob integration

- Upstream: `godot-sdk-integrations/godot-admob`
- Release: `v7.0`
- iOS archive: `AdmobPlugin-iOS-v7.0.zip`
- Archive SHA-256: `96aada90e397e54ecd7c60676a44bc06b5ead17998302b4cf179851e1f90b3cc`
- Bundled Google Mobile Ads iOS SDK (Swift Package): `12.14.0`

Local release hardening:

- The iOS export plist uses Google's scoped ATS exceptions
  (`NSAllowsArbitraryLoadsForMedia` and `NSAllowsArbitraryLoadsInWebContent`)
  instead of a blanket `NSAllowsArbitraryLoads` exception.
- Google Mobile Ads 12.14.0 predates the TFAT
  (`GADRequestConfiguration.ageRestrictedTreatment`) API introduced in 13.3.0.
  This plugin therefore still exposes only legacy TFCD/TFUA values; both remain
  `UNSPECIFIED` because the game currently has no verified age signal.
- The v7.0 iOS binary supports the initial UMP consent form, but does not expose
  `privacyOptionsRequirementStatus`, `presentPrivacyOptionsForm`, or
  `canRequestAds`. The local GDScript wrapper detects the complete future bridge
  contract and fails closed, so the privacy-settings entry point remains hidden
  until a compatible native binary is supplied and tested.

The runtime/editor sources and iOS plugin binaries are vendored so release
builds are reproducible. Application and ad-unit IDs are not stored here;
Codemagic generates the ignored configuration files at build time.
