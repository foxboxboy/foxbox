@abstract
class_name FoxJsonFile
extends FoxRefCounted
## A JSON file on disk, versioned and written whole or not at all.
##
## [FoxJsonFile] is inherited once per file format. A subclass names the version it writes and
## says how to carry an older file forward.
## [codeblock]
## class_name FoxavasWorldFile
## extends FoxJsonFile
##
## func _get_version() -> int:
##     return 3
## [/codeblock]
## Every write moves the previous file into a [code]backups[/code] folder beside it before the new
## one lands, so a crash partway through leaves one whole file either way. A read falls back to
## that copy and emits [signal recovered].
## [br][br]
## Values go in as they will be stored. A write refuses anything JSON cannot hold, because Godot
## turns a [Vector3] into a debug string that reads back as text. Convert the composite types with
## [FoxJson].


## Emitted when a read opened a file from an older version and carried it forward.
signal migrated(from_version: int)

## Emitted when a read could not use the file and fell back to the backup.
signal recovered()


## Folder the previous copy is kept in, beside the file itself.
const BACKUP_FOLDER: String = "backups"


## The contents of the last successful read.
var data: Dictionary


#region Abstract Methods

## Returns the format version this subclass writes. Raise it whenever the shape of the file
## changes, and carry older files forward from the version below it.
@abstract
func _get_version() -> int

#endregion
