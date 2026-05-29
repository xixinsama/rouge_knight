extends Resource
class_name ConsoleConfig
## Console appearance and behavior configuration.

## Key to toggle console visibility (default: backtick/tilde)
@export var toggle_key: Key = KEY_QUOTELEFT

## Maximum number of log entries displayed by /log
@export var max_log_display: int = 200

## Maximum command history entries
@export var max_history: int = 50

## Show physics/process frame numbers in console panel display.
## Frame info is always recorded in the log file regardless of this setting.
@export var show_frame_info: bool = false

## Whether LogManager auto-saves logs to file
@export var log_file_enabled: bool = true

## Log file path relative to user://
@export var log_file_path: String = "logs/console.log"
