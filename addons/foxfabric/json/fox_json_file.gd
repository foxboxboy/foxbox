@abstract
class_name FoxJSONFile
extends FoxRefCounted
## A JSON file on disk, stamped with its format and written whole or not at all.
##
## Extend [FoxJSONFile] once per file format. The subclass names the format it writes and says how
## to carry an older file forward.
## [codeblock]
## class_name WorldFile
## extends FoxJSONFile
##
## func _get_format() -> int:
##     return 3
##
## func _migrate(contents: Dictionary, from_format: int) -> Dictionary:
##     if from_format == 2:
##         contents["props"] = contents["objects"]
##         contents.erase("objects")
##     return contents
## [/codeblock]
## Every [method write] moves the previous file into a [constant BACKUP_FOLDER] folder beside it
## before the new one lands, so a crash partway through leaves one whole file either way. A
## previous file that will not parse goes under [constant BROKEN_SUFFIX] rather than taking the
## backup slot from a whole one, which keeps a bad hand edit recoverable.
## [br][br]
## Nothing reaches for the backup on its own. See [method read].
## [br][br]
## Values go in as they will be stored. [method write] refuses anything JSON cannot hold, because
## Godot turns a [Vector3] into a debug string that reads back as text. Convert the composite types
## with [FoxJSON].
## [br][br]
## One of these belongs to one thread. [member data] and the last error live on the object, so two
## threads sharing an instance overwrite each other's answers. Two instances are free to write the
## same path from different threads: each builds a scratch file named after itself before moving it
## into place, so neither can land in the other's.




#region Signals

## Emitted when [method read] opened a file in an older format and carried it forward.
signal migrated(from_format: int)

#endregion




#region Variables

## Folder [method write] keeps the previous copy in, beside the file itself.
const BACKUP_FOLDER: String = "backups"

## [method write] adds this to a previous copy it could not parse, keeping it apart from the whole
## one.
const BROKEN_SUFFIX: String = ".broken"

## Key [method write] stamps the format under, replacing one already in the contents. It stays in
## [member data] as an [int], holding the format the file was saved at rather than the one its
## contents have moved on to.
## [codeblock]
## if file.read(path) == OK and file.data[FoxJSONFile.FORMAT_KEY] < 2:
##     file.write(path, file.data)
## [/codeblock]
## This counts changes to the shape of the file, not releases of the project. The two move at
## different rates, and a release string is ordinary data that can sit in the contents under any
## name you like.
const FORMAT_KEY: String = "format"

## Suffix of the file [method write] builds before moving it into place.
const TEMP_SUFFIX: String = ".tmp"

## The contents of the last successful [method read]. A read that fails leaves whatever was there
## before it, so the returned [enum Error] says whether this is current.
## [br][br]
## Every number in it is a [float], because JSON has one number type. A count written as
## [code]3[/code] reads back as [code]3.0[/code], and a dictionary read back does not compare equal
## to the one written. Assigning into a typed [int] converts it. [constant FORMAT_KEY] alone stays
## an [int].
var data: Dictionary

var _error_code: Error = OK
var _error_message: String = ""
var _error_line: int = 0

#endregion




#region Reading and writing

## Reads [param path] into [member data] and returns [constant OK].
## [br][br]
## This never reaches for the backup on its own. It reports a file that will not load and does
## nothing else, because what to do about it belongs to the game: a world editor names the line and
## offers the older copy, and only the game knows whether there is a screen to say it on.
## [codeblock]
## if file.read(path) != OK:
##     $LoadFailedDialog.dialog_text = "%s\nLine %d" % [
##         file.get_error_message(), file.get_error_line()]
##     $LoadFailedDialog.popup_centered()
##     await $LoadFailedDialog.confirmed
##     file.read(FoxJSONFile.get_backup_path(path))
## [/codeblock]
## Runs [code skip-lint]_migrate[/code] once per step when the file is in an older format than this
## subclass writes, and emits [signal migrated] after.
## [br][br]
## Returns [constant ERR_FILE_NOT_FOUND] when nothing is there, [constant ERR_PARSE_ERROR] when the
## text is not JSON, [constant ERR_INVALID_DATA] when it carries no usable
## [constant FORMAT_KEY], and [constant ERR_FILE_UNRECOGNIZED] when its format is newer than this
## one reads. [method get_error_message] says which.
func read(path: String) -> Error:
	_clear_error()

	var contents: Variant = _load(path)
	if contents == null:
		return _error_code

	return _adopt(contents)


## Writes [param contents] to [param path], replacing what was there, and returns [constant OK].
## [br][br]
## Sets [constant FORMAT_KEY] to what this subclass writes, replacing one already in
## [param contents], so a dictionary that came from [method read] goes straight back.
## [br][br]
## Returns [constant ERR_INVALID_DATA] without touching the file when [param contents] holds a
## value JSON cannot store. [method get_error_message] names the key.
## [br][br]
## Also pushes a failure to the debugger, the way [method ResourceSaver.save] does, so a caller who
## drops the returned [enum Error] still sees it. [method read] stays quiet, because a missing file
## on a first run is ordinary.
func write(path: String, contents: Dictionary) -> Error:
	var result: Error = _write(path, contents)
	if result != OK:
		push_error("FoxJSONFile: %s" % _error_message)
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
## no-error answer are the same number. This one counts from 1 to tell them apart.
func get_error_line() -> int:
	return _error_line

#endregion




#region Private

# Everything write does. Split out so one place decides whether a failure is pushed, rather than
# every early return remembering to.
func _write(path: String, contents: Dictionary) -> Error:
	_clear_error()

	# A number under this key is the one a read handed back, and replacing it is the point. Anything
	# else is the caller's own field, and quietly writing over it would lose it without a word.
	if contents.has(FORMAT_KEY):
		var existing: Variant = contents[FORMAT_KEY]
		if typeof(existing) != TYPE_INT and typeof(existing) != TYPE_FLOAT:
			return _fail(ERR_INVALID_DATA, '"%s" holds a %s, and the file needs that key' % [
				FORMAT_KEY, type_string(typeof(existing)),
			])

	var problem: String = FoxJSON.find_unsupported(contents)
	if not problem.is_empty():
		return _fail(ERR_INVALID_DATA, problem)

	var payload: Dictionary = contents.duplicate()
	payload[FORMAT_KEY] = _get_format()

	var folder: String = path.get_base_dir()
	if not folder.is_empty() and not DirAccess.dir_exists_absolute(folder):
		var made: Error = DirAccess.make_dir_recursive_absolute(folder)
		if made != OK:
			return _fail(made, "%s could not be created" % folder)

	# Named for this write alone. Two saves running at once would otherwise stream into one file
	# and rename the mixture into place, which is what stops saving being moved to a thread. The
	# instance id carries the uniqueness; the clock only separates two writes from one object.
	var temp: String = "%s.%d.%d%s" % [
		path, get_instance_id(), Time.get_ticks_usec(), TEMP_SUFFIX,
	]
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return _fail(FileAccess.get_open_error(), "%s could not be opened for writing" % temp)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	# Worked out before the file moves, so a failure further down knows what to put back.
	var previous: String = ""
	if FileAccess.file_exists(path):
		previous = get_backup_path(path)
		if not _is_readable(path):
			previous += BROKEN_SUFFIX

	var rotated: Error = _rotate(path, previous)
	if rotated != OK:
		DirAccess.remove_absolute(temp)
		return rotated

	var moved: Error = DirAccess.rename_absolute(temp, path)
	if moved != OK:
		DirAccess.remove_absolute(temp)
		# Nothing took its place, so the file moved aside a moment ago goes back. Leaving the path
		# empty reads as a lost save, when what is there is the one that was already working.
		if not previous.is_empty():
			DirAccess.rename_absolute(previous, path)
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


# Pulls the format out, migrates, and takes the result as data.
func _adopt(contents: Dictionary) -> Error:
	if not contents.has(FORMAT_KEY):
		return _fail(ERR_INVALID_DATA, 'The file carries no "%s"' % FORMAT_KEY)

	var stamp: Variant = contents[FORMAT_KEY]
	if typeof(stamp) != TYPE_FLOAT and typeof(stamp) != TYPE_INT:
		return _fail(ERR_INVALID_DATA, '"%s" is a %s, and a format is a whole number' % [
			FORMAT_KEY, type_string(typeof(stamp)),
		])

	# Checked before the assignment below, which would otherwise take 1.5 as 1 and migrate the file
	# as though it were the format before the one it claims.
	var number: float = stamp
	if number != floorf(number):
		return _fail(ERR_INVALID_DATA, '"%s" is %s, and a format is a whole number' % [
			FORMAT_KEY, number,
		])

	var from_format: int = number
	var current: int = _get_format()
	if from_format > current:
		return _fail(ERR_FILE_UNRECOGNIZED, "The file is format %d, and this reads up to %d" % [
			from_format, current,
		])

	if from_format < current:
		for step: int in range(from_format, current):
			contents = _migrate(contents, step)

	# Set rather than left alone, because a migration that builds a new dictionary instead of
	# editing this one drops the key, and reading has to hand back the format either way. Writing
	# it as an int also spares the caller the float every other number in here comes back as.
	contents[FORMAT_KEY] = from_format

	data = contents
	if from_format < current:
		migrated.emit(from_format)
	return OK


# Moves the file already at path to destination, which is empty when there is nothing there to
# move. The caller works destination out rather than this deciding, so the same answer is available
# afterwards if the write fails and the move has to be undone.
func _rotate(path: String, destination: String) -> Error:
	if destination.is_empty():
		return OK

	var folder: String = destination.get_base_dir()
	if not DirAccess.dir_exists_absolute(folder):
		var made: Error = DirAccess.make_dir_recursive_absolute(folder)
		if made != OK:
			return _fail(made, "%s could not be created" % folder)

	var moved: Error = DirAccess.rename_absolute(path, destination)
	if moved != OK:
		return _fail(moved, "%s could not be moved to %s" % [path, destination])
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

## Returns the format this subclass writes. Raise it whenever the shape of the file
## changes, and carry older files forward from the one below it.
@abstract
func _get_format() -> int


## Returns [param contents] carried forward from [param from_format] to the format above it.
## [br][br]
## Called once per step, so a file at 1 opened by a subclass at 4 reaches
## [code skip-lint]_migrate[/code] three times, with [param from_format] 1, then 2, then 3. Each
## case handles one step and the earlier ones never need revisiting.
## [br][br]
## [param contents] arrives with [constant FORMAT_KEY] still in it, holding the format the file was
## saved at. Leave it alone: the next [method write] replaces it.
## [br][br]
## The file on disk is untouched. Only what [method read] hands back changes.
@warning_ignore("unused_parameter")
func _migrate(contents: Dictionary, from_format: int) -> Dictionary:
	return contents

#endregion
