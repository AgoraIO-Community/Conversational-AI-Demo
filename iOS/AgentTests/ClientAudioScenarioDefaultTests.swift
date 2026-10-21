import XCTest

final class ClientAudioScenarioDefaultTests: XCTestCase {
    func testCustomPrivateAvatarFlagSelectsRtcDefault() throws {
        let preset = try decodePreset(type: "custom_private", supportsAvatar: true)
        let avatarEnabled = AvatarSessionState.isEnabled(
            preset: preset,
            selectedAvatar: nil,
            isOpenSource: false
        )

        XCTAssertTrue(preset.hasConfiguredCustomAvatar)
        XCTAssertTrue(avatarEnabled)
        XCTAssertEqual(AvatarSessionState.vendor(preset: preset, selectedAvatar: nil), "spatius")
        let staleSelection = Avatar(
            vendor: "other-vendor",
            displayVendor: nil,
            avatarId: "old-avatar",
            avatarName: nil,
            thumbImageUrl: nil,
            bgImageUrl: nil
        )
        XCTAssertEqual(AvatarSessionState.vendor(preset: preset, selectedAvatar: staleSelection), "spatius")
        XCTAssertEqual(
            ClientAudioScenarioDefault.resolve(
                isAvatarEnabled: avatarEnabled,
                isIndependent: preset.isIndependent
            ),
            .rtcDefault
        )
    }

    func testCustomPrivateWithoutAvatarFlagSelectsAiClient() throws {
        let preset = try decodePreset(type: "custom_private", supportsAvatar: false)
        let avatarEnabled = AvatarSessionState.isEnabled(
            preset: preset,
            selectedAvatar: nil,
            isOpenSource: false
        )

        XCTAssertFalse(preset.hasConfiguredCustomAvatar)
        XCTAssertFalse(avatarEnabled)
        XCTAssertEqual(
            ClientAudioScenarioDefault.resolve(
                isAvatarEnabled: avatarEnabled,
                isIndependent: preset.isIndependent
            ),
            .aiClient
        )
    }

    func testStandardAvatarCapabilityAloneDoesNotSelectRtcDefault() throws {
        let preset = try decodePreset(type: "standard_avatar", supportsAvatar: true)
        let avatarEnabled = AvatarSessionState.isEnabled(
            preset: preset,
            selectedAvatar: nil,
            isOpenSource: false
        )

        XCTAssertFalse(preset.hasConfiguredCustomAvatar)
        XCTAssertFalse(avatarEnabled)
        XCTAssertNil(AvatarSessionState.vendor(preset: preset, selectedAvatar: nil))
        XCTAssertEqual(
            ClientAudioScenarioDefault.resolve(
                isAvatarEnabled: avatarEnabled,
                isIndependent: preset.isIndependent
            ),
            .aiClient
        )
    }

    func testSelectedAvatarTakesPriorityOverIndependent() {
        XCTAssertEqual(
            ClientAudioScenarioDefault.resolve(isAvatarEnabled: true, isIndependent: true),
            .rtcDefault
        )
        XCTAssertEqual(
            ClientAudioScenarioDefault.resolve(isAvatarEnabled: false, isIndependent: true),
            .chorus
        )
    }

    func testSelectedAvatarEnablesRtcDefaultOutsideOpenSource() throws {
        let preset = try decodePreset(type: "standard_avatar", supportsAvatar: false)
        let json = #"{"vendor":"spatius","avatar_id":"selected-avatar","bg_img_url":"poster.png","scene_bg_img_url":"scene.png"}"#
        let selectedAvatar = try JSONDecoder().decode(Avatar.self, from: Data(json.utf8))
        XCTAssertEqual(selectedAvatar.bgImageUrl, "poster.png")
        XCTAssertEqual(selectedAvatar.sceneBgImageUrl, "scene.png")

        let avatarEnabled = AvatarSessionState.isEnabled(
            preset: preset,
            selectedAvatar: selectedAvatar,
            isOpenSource: false
        )
        XCTAssertTrue(avatarEnabled)
        XCTAssertEqual(AvatarSessionState.vendor(preset: preset, selectedAvatar: selectedAvatar), "spatius")
        XCTAssertEqual(
            ClientAudioScenarioDefault.resolve(isAvatarEnabled: avatarEnabled, isIndependent: false),
            .rtcDefault
        )
    }

    func testOpenSourceNeverEnablesAvatarDespiteOldSelectionOrCustomPreset() throws {
        let customPreset = try decodePreset(type: "custom_private", supportsAvatar: true)
        let selectedAvatar = Avatar(
            vendor: "spatius",
            displayVendor: nil,
            avatarId: "selected-avatar",
            avatarName: nil,
            thumbImageUrl: nil,
            bgImageUrl: nil
        )

        for (preset, avatar) in [(nil, selectedAvatar), (customPreset, nil), (customPreset, selectedAvatar)] as [(AgentPreset?, Avatar?)] {
            let avatarEnabled = AvatarSessionState.isEnabled(
                preset: preset,
                selectedAvatar: avatar,
                isOpenSource: true
            )
            XCTAssertFalse(avatarEnabled)
            XCTAssertEqual(
                ClientAudioScenarioDefault.resolve(isAvatarEnabled: avatarEnabled, isIndependent: false),
                .aiClient
            )
            XCTAssertEqual(
                ClientAudioScenarioDefault.resolve(isAvatarEnabled: avatarEnabled, isIndependent: true),
                .chorus
            )
        }
    }

    func testStartRequestParametersOmitServerAudioScenario() throws {
        for enableMetrics in [true, false] {
            let request: [String: Any] = [
                "convoai_body": [
                    "properties": [
                        "parameters": AgentStartRequestParameters.make(
                            enableMetrics: enableMetrics,
                            enableWords: true
                        )
                    ]
                ]
            ]
            let data = try JSONSerialization.data(withJSONObject: request)
            let serialized = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let body = try XCTUnwrap(serialized["convoai_body"] as? [String: Any])
            let properties = try XCTUnwrap(body["properties"] as? [String: Any])
            let parameters = try XCTUnwrap(properties["parameters"] as? [String: Any])

            XCTAssertFalse(parameters.keys.contains("audio_scenario"))
            XCTAssertEqual(parameters["data_channel"] as? String, "rtm")
            XCTAssertEqual(parameters["enable_metrics"] as? Bool, enableMetrics)
            XCTAssertNotNil(parameters["transcript"])
        }
    }

    private func decodePreset(type: String, supportsAvatar: Bool) throws -> AgentPreset {
        let json = """
        {"preset_type":"\(type)","is_support_avatar":\(supportsAvatar),"avatar_vendor":"spatius"}
        """
        return try JSONDecoder().decode(AgentPreset.self, from: Data(json.utf8))
    }
}
