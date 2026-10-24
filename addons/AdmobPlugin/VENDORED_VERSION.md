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

The runtime/editor sources and iOS plugin binaries are vendored so release
builds are reproducible. Application and ad-unit IDs are not stored here;
Codemagic generates the ignored configuration files at build time.
