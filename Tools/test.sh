#!/bin/bash
# Run Loadout's tests on ONE simulator, serially.
#
# Why this script exists: xcodebuild's defaults clone the destination per test
# target and run them in parallel. On this project that spawned enough clones to
# push load average past 170, lag the machine, and make the UI-test runner fail
# to launch with a bare "RequestDenied by SBMainWorkspace" — which reads like a
# code failure and isn't one. The UI tests also share a single simulator by
# design (they reset profile, library and orientation per class), so clones
# would leak state between them even on a machine that could take the load.
#
#   Tools/test.sh                        # everything
#   Tools/test.sh unit                   # LoadoutTests only
#   Tools/test.sh ui                     # LoadoutUITests only
#   Tools/test.sh ui ConfigureItemUITests  # one UI class
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${LOADOUT_SIM:-iPhone 16 Pro Test}"
SUITE="${1:-all}"
CLASS="${2:-}"

case "$SUITE" in
  unit) ONLY=(-only-testing:LoadoutTests) ;;
  ui)   ONLY=(-only-testing:LoadoutUITests${CLASS:+/$CLASS}) ;;
  all)  ONLY=() ;;
  *)    ONLY=(-only-testing:"$SUITE") ;;
esac

# A stale CoreSimulatorService is the other half of the launch failure; a
# shutdown between runs costs a second and removes the whole class of problem.
xcrun simctl shutdown all 2>/dev/null || true

# Keep the concise progress stream without hiding xcodebuild's result. With
# `grep ... || true`, a red test run exited zero, which made this verification
# command unsafe to use in CI or before a commit.
set +e
xcodebuild test \
  -project Loadout.xcodeproj \
  -scheme Loadout \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  -maximum-parallel-testing-workers 1 \
  ${ONLY[@]+"${ONLY[@]}"} \
  ${3+"${@:3}"} 2>&1 | grep -E "Test Case.*(passed|failed)|Assertion Failure|error:|\*\* TEST"
test_status=${PIPESTATUS[0]}
set -e
exit "$test_status"
