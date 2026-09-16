# iOS validation

Use Python 3.9+ and Xcode 16+ command-line tools. Run from the repository root:

```bash
python3 scripts/validate.py ios --list
python3 scripts/validate.py ios --suite ains --preflight
python3 scripts/validate.py ios --suite ains
```

Standalone AINS uses `Agent.xcodeproj` / `Agent-globalTests` and does not require Pods. The configured suite currently covers AINS only. For other behavior, use or add relevant tests and update the target, shared scheme and suite mapping as needed.

## Options and results

- `--only-testing <target/class[/method]>` selects tests from the suite's configured scope.
- `--destination <UUID>` or `IOS_SIMULATOR_UDID` selects an available iPhone simulator. Architecture defaults to native; `SIM_ARCH=x86_64` needs a compatible runtime.
- Each test run uses incremental `xcodebuild test` and a fresh xcresult. DerivedData is isolated by checkout, scheme and architecture, with a lock for concurrent access. `--derived-data` overrides its location.
- Output includes the command, results, log and xcresult paths. `--results-dir` or `WORKFLOW_RESULTS_DIR` sets the output parent; otherwise results use unique temporary directories.
- Preflight and build-only do not run tests. Failed commands, invalid results, zero tests and all-skipped tests exit nonzero. Inspect the log to understand failures.

`scripts/workflow.json` maps suites to shared schemes, targets and test classes. Update it with test wiring changes. `python3 scripts/check_workflow.py` checks that mapping. The scripts cover the listed suites; select or add other checks when the task needs them.

Legacy helpers under `iOS/scripts/` forward to the root runner. `ios_test_without_building.sh` now runs current-source incremental tests; `ios_feature_validation.sh --list` lists available suites. These local helpers do not change Jenkins `cicd/`.
