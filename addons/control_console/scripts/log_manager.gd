extends Node
## Console log manager — autoload singleton.
## Collects [INFO], [WARNING], [ERROR] logs from anywhere in the game.
## Access via: LogManager.info("msg"), LogManager.warn("msg"), LogManager.error("msg")

enum LogType {
	INFO = 0,
	WARNING = 1,
	ERROR = 2
}

class LogEntry:
	var type: LogType
	var message: String
	var time: String
	var physics_frame: int
	var process_frame: int

	func _init(p_type: LogType, p_message: String) -> void:
		type = p_type
		message = p_message
		time = Time.get_datetime_string_from_system()
		physics_frame = Engine.get_physics_frames()
		process_frame = Engine.get_process_frames()

	func _to_string() -> String:
		var type_str: String = ["INFO", "WARNING", "ERROR"][type]
		return "[%s] %s [pf:%d|phf:%d] %s" % [type_str, time, process_frame, physics_frame, message]

var _logs: Array = []
var _auto_save: bool = true
var _log_file: String = "logs/console.log"

signal new_log(entry: LogEntry)

func info(msg: String) -> void:
	_add(LogType.INFO, msg)

func warn(msg: String) -> void:
	_add(LogType.WARNING, msg)

func error(msg: String) -> void:
	_add(LogType.ERROR, msg)

func _add(type: LogType, msg: String) -> void:
	var entry := LogEntry.new(type, msg)
	_logs.append(entry)
	new_log.emit(entry)
	if _auto_save:
		_append_file(entry)

func configure(auto_save: bool, log_path: String) -> void:
	_auto_save = auto_save
	_log_file = log_path

func get_logs(filter_type: int = -1, max_count: int = 200, min_pf: int = -1, max_pf: int = -1, min_phf: int = -1, max_phf: int = -1) -> Array:
	var result: Array = []
	var start := maxi(0, _logs.size() - max_count)
	for i in range(start, _logs.size()):
		var entry: LogEntry = _logs[i]
		if filter_type != -1 and entry.type != filter_type:
			continue
		if min_pf >= 0 and entry.process_frame < min_pf:
			continue
		if max_pf >= 0 and entry.process_frame > max_pf:
			continue
		if min_phf >= 0 and entry.physics_frame < min_phf:
			continue
		if max_phf >= 0 and entry.physics_frame > max_phf:
			continue
		result.append(entry)
	return result

func clear_logs() -> void:
	_logs.clear()

func _append_file(entry: LogEntry) -> void:
	var dir := _log_file.get_base_dir()
	var full_dir := "user://" + dir
	if not DirAccess.dir_exists_absolute(full_dir):
		DirAccess.make_dir_recursive_absolute(full_dir)
	var f := FileAccess.open("user://" + _log_file, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open("user://" + _log_file, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(entry._to_string())
		f.close()
