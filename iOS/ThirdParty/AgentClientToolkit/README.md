# Toolkit 2.10.1 with Agora RTM 2.3.0

The published Toolkit binary is unchanged. Its published podspec still names
`AgoraRtm/RtmKit >= 2.2.3`; RTM 2.3.0 is published as `Agora-Rtm/RtmKit`.
The local podspec changes only that dependency so CocoaPods resolves one RTM
binary with Agora RTC 4.6.4. Update or remove this override when the upstream
Toolkit podspec names the new package.
