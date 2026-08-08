Tests: A self-contained suite covering every FoxFabric module except character. No addon or
install is required, so a fresh clone can run it immediately.

IN THE EDITOR

Open tests/test_runner.tscn and press F6. Results appear on screen and in the Output panel.

Select the TestRunner node to filter in the inspector:
    Suite Filter    leave blank for everything, or type "effect" for one module
    Random Seed     change it to shuffle the randomised cases


FROM THE COMMAND LINE

For CI, or when you do not want to open the editor:

    godot --headless --path . --script res://tests/run_all.gd
    godot --headless --path . --script res://tests/run_all.gd --suite=effect
    godot --headless --path . --script res://tests/run_all.gd --seed=12345

Exits 0 when everything passes and 1 when anything fails, so CI can gate on it. The wrapper
scripts next to this file do the same thing and locate Godot for you:

    ./tests/run_tests.sh                 or .\tests\run_tests.ps1
    ./tests/run_tests.sh --suite=effect

They need FOXFABRIC_GODOT set, or a "godot" on PATH. On Windows, set it once with:

    [Environment]::SetEnvironmentVariable("FOXFABRIC_GODOT", "C:\path\to\Godot_console.exe", "User")


LAYOUT

    fox_test.gd          base class every suite extends
    fox_test_runner.gd   discovery, execution and report formatting
    run_all.gd           command line entry point (SceneTree)
    test_runner.tscn     editor entry point, press F6
    test_runner.gd       script behind that scene
    test_<module>.gd     the suites themselves


WRITING A TEST

Drop a test_<module>.gd in this folder. The runner finds it automatically.

    extends "res://tests/fox_test.gd"

    func run() -> void:
        suite = "my_module"
        case("some behaviour")
        eq(2 + 2, 4, "arithmetic still works")

Helpers on the base class:
    case(label)                 groups the checks that follow
    check(condition, label)     passes when condition is true
    eq(actual, expected, label) passes when the two are equal
    almost(a, b, label, eps)    float comparison
    track(node)                 adds a node to the tree and frees it afterwards
    rng                         seeded RandomNumberGenerator, same seed every run

Nodes must be created through track() so their _ready and _enter_tree actually fire. The
runner does its work on the first frame rather than in _initialize, because nodes added
before the tree is live never receive tree callbacks at all.


EXPECTED NOISE

Some tests deliberately drive failure paths, so the following appear during a passing run and
are not problems:

    FoxEffectManager: Could not load blueprint for ID 'saved'
    FoxSocket3D: Attempted to attach '...' but socket '...' already has an attachment!
    FoxStateMachine transition failed: The target state 'DoesNotExist' does not exist.
    FoxStateMachine get_state failed: The target state 'DoesNotExist' does not exist.
    Capture not registered: 'signal_debugger'      (the SignalVisualizer autoload shutting down)
    ObjectDB instances were leaked at exit         (objects still referenced when the process ends)

Read the PASS/FAIL report at the bottom, not the warnings above it.


WHAT IS NOT COVERED

The character module, which is mid-refactor.

Anything needing real physics frames. Overlap based delivery (FoxHitArea3D.fire, the raycast
and shapecast deliverers) is tested by calling the delivery path directly rather than waiting
for the physics server, so collision layer and mask behaviour is not verified here.
