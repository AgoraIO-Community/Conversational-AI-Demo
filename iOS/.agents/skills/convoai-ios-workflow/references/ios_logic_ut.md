# iOS Logic Validation Guide

Use this guide only for `validation_mode = logic`.

## Current Test Boundary

The tracked Xcode project currently contains the `Agent-global` application target but no XCTest target or shared test scheme. A logic or API change cannot be accepted from a build-only result.

Before a logic change can pass, add or restore an appropriate XCTest target and a shared scheme, then run the narrowest test that covers the behavior. Until then, report `blocked` or an approved Product gap and retain the exact missing test-target evidence.

## Available Checks

Use the project to inspect the current target graph:

```bash
xcodebuild -list -project Agent.xcodeproj
```

After CocoaPods has created the workspace, use the `Agent-global` scheme for build or UI validation. This proves compilation or runtime behavior only; it is not logic-test evidence.

```bash
xcodebuild build \
  -workspace Agent.xcworkspace \
  -scheme Agent-global \
  -destination 'generic/platform=iOS Simulator'
```

When a test target is introduced, record its scheme, the exact `-only-testing:` identifier, simulator destination, derived-data path, and the resulting xcresult or log path in the acceptance evidence.
