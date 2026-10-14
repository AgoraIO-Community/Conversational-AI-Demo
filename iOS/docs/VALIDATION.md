# iOS validation

Use Python 3.9+ and Xcode 16+ command-line tools. Run from the repository root:

```bash
python3 scripts/validate.py ios --list
python3 scripts/validate.py ios --suite ains --preflight
python3 scripts/validate.py ios --suite ains
python3 scripts/validate.py ios --suite audio_scenario
python3 scripts/validate.py ios --suite environment
```

The standalone suites use `Agent.xcodeproj` / `Agent-globalTests` and do not require Pods. They cover AINS, client audio scenario defaults and environment matching. For other behavior, use or add relevant tests and update the target, shared scheme and suite mapping as needed.

The `environment` suite checks host + RTC App ID matching and remembered dynamic selections without an app host.

The `audio_scenario` suite also decodes selected avatar metadata with optional `scene_bg_img_url` beside `bg_img_url`, confirming the new scene field preserves the avatar's existing scenario behavior. This brand uses remote avatar video and has no local Spatius canvas; the field is retained as metadata and is not forwarded in Agent start parameters.

## Options and results

- `--only-testing <target/class[/method]>` selects tests from the suite's configured scope.
- `--destination <UUID>` or `IOS_SIMULATOR_UDID` selects an available iPhone simulator. Architecture defaults to native; `SIM_ARCH=x86_64` needs a compatible runtime.
- Each test run uses incremental `xcodebuild test` and a fresh xcresult. DerivedData is isolated by checkout, scheme and architecture, with a lock for concurrent access. `--derived-data` overrides its location.
- Output includes the command, results, log and xcresult paths. `--results-dir` or `WORKFLOW_RESULTS_DIR` sets the output parent; otherwise results use unique temporary directories.
- Preflight and build-only do not run tests. Failed commands, invalid results, zero tests and all-skipped tests exit nonzero. Inspect the log to understand failures.

`scripts/workflow.json` maps suites to shared schemes, targets and test classes. Update it with test wiring changes. `python3 scripts/check_workflow.py` checks that mapping. The scripts cover the listed suites; select or add other checks when the task needs them.

Legacy helpers under `iOS/scripts/` forward to the root runner. `ios_test_without_building.sh` now runs current-source incremental tests; `ios_feature_validation.sh --list` lists available suites. These local helpers do not change Jenkins `cicd/`.

## Manual turn controller tests

`python3 scripts/test_manual_eos_ios.py` runs `PushToTalkControllerTests` on the native Swift host, without Pods, an app host or a simulator. It copies the current sources into a temporary Swift package and deletes it afterwards; `--keep` keeps it for debugging. A zero-test result fails the runner.

The tests use a controlled clock and publisher and cover hold, release and the 200 ms tail, the short-hold hint, SOS failure, SOS/EOS ordering, `AGENT_MANUAL_EOS` turn ownership, local resets and forced release. The same source is registered as the `manual_eos` suite in the standalone Xcode target. Settings, call-page wiring, audio and server behavior need device QA.
