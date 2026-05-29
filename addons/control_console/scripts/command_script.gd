extends Resource
class_name CommandScript
## Base class for user-defined console command scripts.
## Extend this class and define methods starting with `cmd_` — they become
## "/" console commands automatically.
## Override _get_command_info() to provide help text for /help.

## Override to return {command_name: "description"} for /help display.
func _get_command_info() -> Dictionary:
	return {}

## Returns {command_name: description} by scanning cmd_* methods.
func get_commands() -> Dictionary:
	var info := _get_command_info()
	var base := CommandScript.new()
	var base_names: Array[String] = []
	for m in base.get_method_list():
		base_names.append(m["name"])

	var commands: Dictionary = {}
	for m in get_method_list():
		var name: String = m["name"]
		if name.begins_with("cmd_") and name not in base_names:
			var cmd := name.trim_prefix("cmd_")
			commands[cmd] = info.get(cmd, "")
	return commands
