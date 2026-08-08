#!/usr/bin/env bash
# Runs the FoxFabric test suite headless and forwards the exit code.
#
#   ./run_tests.sh                 run everything
#   ./run_tests.sh --suite=effect  run one module
#   ./run_tests.sh --seed=12345    reproduce a specific random run
#
# Set FOXFABRIC_GODOT to your Godot binary if it is not on PATH.
set -u

GODOT="${FOXFABRIC_GODOT:-$(command -v godot || true)}"

if [ -z "$GODOT" ] || [ ! -x "$GODOT" ]; then
	echo "Could not find Godot."
	echo 'Set it with:  export FOXFABRIC_GODOT=/path/to/godot'
	exit 2
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$GODOT" --headless --path "$PROJECT_ROOT" --script "res://tests/run_all.gd" "$@"
exit $?
