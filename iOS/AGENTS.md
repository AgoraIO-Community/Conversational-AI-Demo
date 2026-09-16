# Agora iOS

See [shared guidance](../AI_WORKFLOW.md). Paths below are relative to iOS unless stated otherwise.

- App target: `Agent-global`. Main business code is under `Scenes/ConvoAI/ConvoAI/ConvoAI/Classes`.
- Common, ConvoAI, IoT and BLEManager are loaded through CocoaPods. Toolkit is the external `agent-client-toolkit-swift` Pod, imported as `AgoraAgentClientToolkit`.
- For affected RTC/RTM, Toolkit, permissions or session code, check callback threads, lifecycle, cleanup and state persistence. Preserve `KeyCenter.swift` and existing local changes.

## Useful commands

From the repository root:

```bash
python3 scripts/validate.py ios --list
python3 scripts/validate.py ios --suite ains
```

`ains` uses `Agent.xcodeproj` / `Agent-globalTests` and tests the app's OnDeviceAins.swift without Pods or an app host. The configured suite currently covers AINS only. For other behavior, use or add relevant tests and update the target, shared scheme and suite mapping as needed.

Choose checks covering the changed behavior. See [validation options](docs/VALIDATION.md) for focused selection, simulator setup and result files. The scripts are local helpers; `cicd/` remains the Jenkins entrypoint.
