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
##
## func _migrate(contents: Dictionary, from_version: int) -> Dictionary:
##     if from_version == 2:
##         contents["props"] = contents["objects"]
##         contents.erase("objects")
##     return contents
## [/codeblock]
## Every [method write] moves the previous file into a [constant BACKUP_FOLDER] folder beside it
## before the new one lands, so a crash partway through leaves one whole file either way. A
## previous file that will not parse is kept under [constant BROKEN_SUFFIX] instead of taking the
## backup slot from a whole one, which is what makes a bad hand edit recoverable.
## [br][br]
## Nothing reaches for the backup on its own. See [method read].
## [br][br]
## Values go in as they will be stored. [method write] refuses anything JSON cannot hold, because
## Godot turns a [Vector3] into a debug string that reads back as text. Convert the composite types
## with [FoxJson].




#region Signals

## Emitted when [method read] opened a file from an older version and carried it forward.
signal migrated(from_version: int)

#endregion




#region Variables

## Folder the previous copy is kept in, beside the file itself.
const BACKUP_FOLDER: String = "backups"

## Added to the name of a previous copy that could not be parsed, so it is kept apart from the
## whole one.
const BROKEN_SUFFIX: String = ".broken"

## Key [method write] stamps the format version under. A dictionary handed to [method write] may
## not already use it.
## [br][br]
## This counts changes to the shape of the file, not releases of the project. The two move at
## different rates, and a release string is ordinary data that can sit in the contents under any
## name you like.
const FORMAT_KEY: String = "format"

## Suffix of the file [method write] builds before moving it into place.
const TEMP_SUFFIX: String = ".tmp"

## The contents of the last successful [method read]. A read that fails leaves whatever was there
## before it, so the returned [enum Error] is what says whether this is current.
## [br][br]
## Every number in it is a [float], because JSON has one number type. A count written as
## [code]3[/code] reads back as [code]3.0[/code], and a dictionary read back does not compare equal
## to the one written. Assigning into a typed [int] converts it.
var data: Dictionary

var _error_code: Error = OK
var _error_message: String = ""
var _error_line: int = 0

#endregion




#region Reading and writing

## Reads [param path] into [member data] and returns [constant OK].
## [br][br]
## The backup is never reached for on its own. A file that will not load is reported and nothing
## else happens, because what to do about it belongs to the game: a world editor wants to say which
## line is wrong and offer the older copy, and only the game knows whether there is a screen to say
## it on.
## [codeblock]
## if file.read(path) != OK:
##     var answer: bool = await ask("%s could not be read.\nLine %d: %s\n\nLoad the backup?"
##         % [path, file.get_error_line(), file.get_error_message()])
##     if answer:
##         file.read(FoxJsonFile.get_backup_path(path))
## [/codeblock]
## Runs [code skip-lint]_migrate[/code] once per version when the file is older than this subclass
## writes, and emits [signal migrated] after.
## [br][br]
## Returns [constant ERR_FILE_NOT_FOUND] when nothing is there, [constant ERR_PARSE_ERROR] when the
## text is not JSON, [constant ERR_INVALID_DATA] when it carries no usable
## [constant FORMAT_KEY], and [constant ERR_FILE_UNRECOGNIZED] when it was written by a newer
## version than this one reads. [method get_error_message] says which.
func read(path: String) -> Error:
	_clear_error()

	var contents: Variant = _load(path)
	if contents == null:
		return _error_code

	return _adopt(contents)


## Writes [param contents] to [param path], replacing what was there, and returns [constant OK].
## [br][br]
## Returns [constant ERR_INVALID_DATA] without touching the file when [param contents] already uses
## [constant FORMAT_KEY], or holds a value JSON cannot store. [method get_error_message] names the
## key in both cases.
## [br][br]
## A failure is also pushed to the debugger, the way [method ResourceSaver.save] reports one. A save
## that does not happen is never a normal outcome, and a caller that drops the returned
## [enum Error] would otherwise see nothing at all. [method read] stays quiet by comparison, because
## a missing file on a first run is ordinary.
func write(path: String, contents: Dictionary) -> Error:
	var result: Error = _write(path, contents)
	if result != OK:
		push_error("FoxJsonFile: %s" % _error_message)
	return result


## Returns the path [method write] keeps the previous copy of [param path] at.
static func get_backup_path(path: String) -> String:
	return path.get_base_dir().path_join(BACKUP_FOLDER).path_join(path.get_file())

#endregion




#region Errors

## Returns why the last [method read] or [method write] failed, or an empty string.
func get_error_message() -> String:
	return _error_message


## Returns the line the last [method read] failed to parse, counting from 1. Returns 0 when nothing
## failed and after every [method write], neither of which has a line to point at.
## [br][br]
## [method JSON.get_error_line] counts from 0 and returns 0 on success, so its first line and its
## no-error answer are the same number. This one is shifted by one to tell them apart.
func get_error_line() -> int:
	return _error_line

#endregion




#region Private

# Everything write does. Split out so one place decides whether a failure is pushed, rather than
# every early return remembering to.
func _write(path: String, contents: Dictionary) -> Error:
	_clear_error()

	if contents.has(FORMAT_KEY):
		return _fail(ERR_INVALID_DATA, '"%s" is stamped by the file and cannot be written into it'
			% FORMAT_KEY)

	var problem: String = FoxJson.find_unsupported(contents)
	if not problem.is_empty():
		return _fail(ERR_INVALID_DATA, problem)

	var payload: Dictionary = contents.duplicate()
	payload[FORMAT_KEY] = _get_version()

	var folder: String = path.get_base_dir()
	if not folder.is_empty() and not DirAccess.dir_exists_absolute(folder):
		var made: Error = DirAccess.make_dir_recursive_absolute(folder)
		if made != OK:
			return _fail(made, "%s could not be created" % folder)

	var temp: String = path + TEMP_SUFFIX
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return _fail(FileAccess.get_open_error(), "%s could not be opened for writing" % temp)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	var rotated: Error = _rotate(path)
	if rotated != OK:
		DirAccess.remove_absolute(temp)
		return rotated

	var moved: Error = DirAccess.rename_absolute(temp, path)
	if moved != OK:
		# The previous file is already in the backup folder by now, which is where a caller can
		# reach for it. Leaving the half-written one behind would serve nobody.
		DirAccess.remove_absolute(temp)
		return _fail(moved, "%s could not be moved into place" % temp)

	return OK


# Returns the parsed object, or null with the error recorded. Null covers every way this fails,
# because an empty file and a missing one both leave nothing to hand back.
func _load(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_fail(ERR_FILE_NOT_FOUND, "%s is not there" % path)
		return null

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail(FileAccess.get_open_error(), "%s could not be opened" % path)
		return null
	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		# JSON counts lines from zero and returns zero when it succeeded, so the first line and no
		# error are the same number. Counting from one keeps zero free to mean nothing failed.
		_error_line = json.get_error_line() + 1
		_fail(ERR_PARSE_ERROR, "%s is not valid JSON: %s" % [path, json.get_error_message()])
		return null

	if typeof(json.data) != TYPE_DICTIONARY:
		_fail(ERR_INVALID_DATA, "%s holds a %s at the top level, not an object" % [
			path, type_string(typeof(json.data)),
		])
		return null

	return json.data


# Pulls the version out, migrates, and takes the result as data.
func _adopt(contents: Dictionary) -> Error:
	if not contents.has(FORMAT_KEY):
		return _fail(ERR_INVALID_DATA, 'The file carries no "%s"' % FORMAT_KEY)

	var stamp: Variant = contents[FORMAT_KEY]
	if typeof(stamp) != TYPE_FLOAT and typeof(stamp) != TYPE_INT:
		return _fail(ERR_INVALID_DATA, '"%s" is a %s, and a version is a whole number' % [
			FORMAT_KEY, type_string(typeof(stamp)),
		])

	var from_version: int = stamp
	var current: int = _get_version()
	if from_version > current:
		return _fail(ERR_FILE_UNRECOGNIZED, "The file is version %d, and this reads up to %d" % [
			from_version, current,
		])

	# Stripped before _migrate runs, so a subclass never has to work around a key it did not write.
	contents.erase(FORMAT_KEY)

	if from_version < current:
		for step: int in range(from_version, current):
			contents = _migrate(contents, step)

	data = contents
	if from_version < current:
		migrated.emit(from_version)
	return OK


# Moves the file already at path into the backup folder. One that cannot be parsed is put aside
# under BROKEN_SUFFIX rather than taking the slot from a whole copy, which is checked here rather
# than remembered from an earlier read: the file may have been broken by something other than this
# object, or by nothing that ran this session at all.
func _rotate(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return OK

	var backup: String = get_backup_path(path)
	if not _is_readable(path):
		backup += BROKEN_SUFFIX

	var folder: String = backup.get_base_dir()
	if not DirAccess.dir_exists_absolute(folder):
		var made: Error = DirAccess.make_dir_recursive_absolute(folder)
		if made != OK:
			return _fail(made, "%s could not be created" % folder)

	var moved: Error = DirAccess.rename_absolute(path, backup)
	if moved != OK:
		return _fail(moved, "%s could not be moved to %s" % [path, backup])
	return OK


# Whether the file at path is JSON this class could read back. Uses its own parser so a check made
# during a write leaves the error from that write alone.
func _is_readable(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	return json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY


func _clear_error() -> void:
	_error_code = OK
	_error_message = ""
	_error_line = 0


func _fail(code: Error, message: String) -> Error:
	_error_code = code
	_error_message = message
	return code

#endregion




#region Virtual Methods

## Returns the format version this subclass writes. Raise it whenever the shape of the file
## changes, and carry older files forward from the version below it.
@abstract
func _get_version() -> int


## Returns [param contents] carried forward from [param from_version] to the version above it.
## [br][br]
## Called once per step, so a file at 1 opened by a subclass at 4 reaches
## [code skip-lint]_migrate[/code] three times, with [param from_version] 1, then 2, then 3. Each
## case handles one step and the earlier ones never need revisiting.
## [br][br]
## The file on disk is untouched. Only what [method read] hands back changes.
@warning_ignore("unused_parameter")
func _migrate(contents: Dictionary, from_version: int) -> Dictionary:
	return contents

#endregion
