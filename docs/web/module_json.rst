:github_url: hide

Json
====

Reads and writes JSON that keeps its Godot types. A file carries a version, so an older one still loads after the format moves.

Two classes that do not depend on each other. :ref:`class_FoxJson` converts Godot values to and
from the six types JSON can hold. :ref:`class_FoxJsonFile` reads and writes a versioned file.

Extend :ref:`class_FoxJsonFile` once per format. The subclass names the version it writes and says
how to carry an older file forward when that version changes.

.. code-block:: gdscript

    class_name WorldFile
    extends FoxJsonFile

    func _get_format() -> int:
        return 2

    func _migrate(contents: Dictionary, from_format: int) -> Dictionary:
        if from_format == 1:
            contents["props"] = contents["objects"]
            contents.erase("objects")
        return contents

``_get_format`` counts changes to the shape of the file, not releases of the project. The two move
at different rates, so it is stamped under ``format`` and leaves ``version`` free for a release
string of your own.

Values are converted a field at a time, in both directions. Nothing in ``[2.0, 0.0, -3.0]`` records
that it was a ``Vector3``, so the code asking for a field is what decides its type.

.. code-block:: gdscript

    var file: WorldFile = WorldFile.new()
    file.write("user://world.json", {
        "props": [{
            "kind": "crate",
            "transform": FoxJson.transform_3d_to_array(crate.global_transform),
        }],
    })

.. code-block:: gdscript

    if file.read("user://world.json") == OK:
        var props: Array = file.data["props"]
        for prop: Dictionary in props:
            crate.global_transform = FoxJson.array_to_transform_3d(
                prop["transform"], Transform3D.IDENTITY)

``write`` refuses a value JSON cannot store rather than letting Godot save a ``Vector3`` as the
string ``"(1.0, 2.0, 3.0)"``, which would read back as text. It names the key that stopped it.

The previous file moves into a ``backups`` folder beside it before the new one lands, so a crash
partway through leaves one whole copy either way. A previous file that will not parse is kept
under ``.broken`` rather than taking that slot, which is what makes a bad hand edit recoverable.

.. note::

    ``read`` does not reach for the backup on its own. A file that will not load is reported and
    nothing else happens, so a game can say which line is wrong and offer the older copy.

For a save nobody opens, ``FileAccess.store_var`` is two lines and keeps every Godot type exactly.

.. toctree::
   :maxdepth: 1

   class_foxjson
   class_foxjsonfile
