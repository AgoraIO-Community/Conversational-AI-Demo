# Toolkit 2.11.0 with Agora RTM 2.3.0

This local podspec downloads the official Toolkit 2.11.0 binary and verifies
its published SHA-256 checksum. Its published podspec still names
`AgoraRtm/RtmKit >= 2.2.3`; RTM 2.3.0 is published as `Agora-Rtm/RtmKit`.
The local podspec changes only that dependency so CocoaPods resolves one RTM
binary with Agora RTC 4.6.4. Update or remove this override when the upstream
Toolkit podspec names the new package.

Upstream specification:
https://download.agora.io/cocoapods/Specs/0/9/0/agent-client-toolkit-swift/2.11.0/agent-client-toolkit-swift.podspec.json
