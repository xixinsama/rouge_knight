extends CommandScript
## Example command script — shows how to create custom console commands.
##
## Usage:
##   1. Add ConsoleUI scene to your game scene.
##   2. Assign this script to ConsoleUI.command_script in the inspector.
##   3. Run the game, press backtick (`·`) and try:
##      /heal 100
##      /god
##      /spawn slime
##      /logtest

func _get_command_info() -> Dictionary:
	return {
		"heal":    "Heal the player by N HP. Usage: /heal <amount>",
		"god":     "Toggle god mode. Usage: /god",
		"spawn":   "Spawn an enemy. Usage: /spawn <enemy_name>",
		"logtest": "Write sample log entries to test /log filtering.",
	}

func cmd_heal(args: String) -> String:
	var amount := 50
	if not args.is_empty() and args.is_valid_int():
		amount = args.to_int()
	LogManager.info("Player healed by %d HP" % amount)
	return "[OK] Healed %d HP" % amount

func cmd_god(_args: String) -> String:
	LogManager.warn("God mode toggled (example — hook your own logic)")
	return "[OK] God mode toggled"

func cmd_spawn(args: String) -> String:
	if args.is_empty():
		return "[!] Usage: /spawn <enemy_name>"
	LogManager.info("Spawning enemy: %s" % args)
	return "[OK] Spawned enemy: %s" % args

func cmd_logtest(_args: String) -> String:
	LogManager.info("This is an INFO message")
	LogManager.warn("This is a WARNING message")
	LogManager.error("This is an ERROR message")
	return "[OK] 3 sample logs written — use /log to view, /log WARN to filter."
