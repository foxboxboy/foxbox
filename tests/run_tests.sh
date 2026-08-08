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

# this script lives in tests/, so the project root is one level up
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Running --script skips the import pass, so without a class cache every class_name in the
# project is unknown and every suite fails to parse. A fresh clone always hits this.
if [ ! -f "$PROJECT_ROOT/.godot/global_script_class_cache.cfg" ]; then
	echo "No class cache yet, running a one-time import pass..."
	"$GODOT" --headless --path "$PROJECT_ROOT" --editor --quit >/dev/null 2>&1
fi

"$GODOT" --headless --path "$PROJECT_ROOT" --script "res://tests/run_all.gd" "$@"
exit $?
