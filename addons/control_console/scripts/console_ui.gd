extends CanvasLayer
class_name ConsoleUI
## Developer console overlay. Toggle with backtick (`·`), type /help for commands.
## Drop this scene into any game scene to get a fully functional console.

## When true the console is completely disabled.
@export var disabled: bool = false:
	set(v):
		disabled = v
		if v and _panel:
			_hide()

## A CommandScript subclass (.gd file) that defines custom /commands.
@export var command_script: Script:
	set(v):
		command_script = v
		_load_commands()

## Optional ConsoleConfig resource for appearance/behavior overrides.
@export var config: ConsoleConfig

# ── UI nodes ────────────────────────────────────────────────────────────
@onready var _panel: Panel = $ConsolePanel
@onready var _scroll: ScrollContainer = $ConsolePanel/MarginContainer/VBoxContainer/ScrollContainer
@onready var _output: RichTextLabel = $ConsolePanel/MarginContainer/VBoxContainer/ScrollContainer/RichTextLabel
@onready var _input: LineEdit = $ConsolePanel/MarginContainer/VBoxContainer/HBoxContainer/LineEdit

# ── State ───────────────────────────────────────────────────────────────
var _instance: CommandScript
var _callables: Dictionary = {}   # {cmd_name: Callable}
var _history: Array[String] = []
var _history_idx: int = -1
var _saved_input: String = ""
var _toggle_key: Key = KEY_QUOTELEFT

# ── Lifecycle ───────────────────────────────────────────────────────────

func _ready() -> void:
	if disabled:
		return

	process_mode = Node.PROCESS_MODE_ALWAYS

	if config:
		_toggle_key = config.toggle_key

	_input.text_submitted.connect(_on_submit)
	_input.gui_input.connect(_on_input_key)
	_load_commands()
	_connect_logs()
	_hide()

# ── Input handling ──────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == _toggle_key:
			_toggle()
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_ESCAPE or event.keycode == _toggle_key) and _panel.visible:
			_hide()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	if _panel.visible:
		_hide()
	else:
		_show()

func _show() -> void:
	_panel.show()
	_input.grab_focus()
	_input.clear()
	# await get_tree().process_frame
	if _scroll.get_v_scroll_bar():
		_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value - _scroll.get_v_scroll_bar().page

func _hide() -> void:
	_panel.hide()
	_input.release_focus()

# ── Command execution ───────────────────────────────────────────────────

func _on_submit(text: String) -> void:
	if text.is_empty():
		return

	_write(Color.LIME_GREEN, "> %s" % text)
	_add_history(text)

	var stripped := text.strip_edges()
	if stripped.begins_with("/"):
		_dispatch(stripped)
	else:
		_write(Color.YELLOW, "[!] Commands start with /. Type /help for available commands.")

	_input.clear()
	_history_idx = -1

func _dispatch(raw: String) -> void:
	var body := raw.trim_prefix("/")
	var space := body.find(" ")
	var cmd := body if space == -1 else body.substr(0, space)
	var args := "" if space == -1 else body.substr(space + 1)
	cmd = cmd.to_lower().strip_edges()

	if _callables.has(cmd):
		var result = _callables[cmd].call(args)
		if result is String and not result.is_empty():
			_write(Color.WHITE, result)
	else:
		_write(Color.RED, "[X] Unknown command: /%s — type /help" % cmd)

# ── History ─────────────────────────────────────────────────────────────

func _add_history(text: String) -> void:
	var max_hist := config.max_history if config else 50
	_history.push_back(text)
	if _history.size() > max_hist:
		_history.pop_front()

func _on_input_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_UP:    _step_history(-1); get_viewport().set_input_as_handled()
		KEY_DOWN:  _step_history(1);  get_viewport().set_input_as_handled()
		KEY_TAB:   _autocomplete();   get_viewport().set_input_as_handled()
		KEY_ESCAPE: _hide();          get_viewport().set_input_as_handled()

func _step_history(dir: int) -> void:
	if _history.is_empty():
		return

	if _history_idx == -1:
		_saved_input = _input.text
		_history_idx = _history.size()

	_history_idx = clampi(_history_idx + dir, 0, _history.size())

	if _history_idx == _history.size():
		_input.text = _saved_input
		_history_idx = -1
	else:
		_input.text = _history[_history_idx]
	_input.caret_column = _input.text.length()

func _autocomplete() -> void:
	var text := _input.text
	if not text.begins_with("/"):
		return

	var partial := text.trim_prefix("/")
	var matches: Array[String] = []
	for cmd in _callables.keys():
		if cmd.begins_with(partial):
			matches.append(cmd)

	if matches.size() == 1:
		_input.text = "/" + matches[0] + " "
		_input.caret_column = _input.text.length()
	elif matches.size() > 1:
		_write(Color.LIME_GREEN, "> %s" % text)
		_write(Color.DIM_GRAY, "  " + "  ".join(matches))

# ── Output ──────────────────────────────────────────────────────────────

func _write(color: Color, text: String) -> void:
	_output.push_color(color)
	_output.add_text(text + "\n")
	_output.pop()

	await get_tree().physics_frame ## 固定等两物理帧只是为了保险起见
	await get_tree().physics_frame
	# 使用 Tween 动画滚动到底部
	scroll_to_bottom_animated(0.2)

var scroll_tween: Tween
func scroll_to_bottom_animated(duration: float = 0.2) -> void:
	var v_scroll = _scroll.get_v_scroll_bar()
	if not v_scroll:
		return

	# 获取正确的底部位置
	var target = v_scroll.max_value - v_scroll.page
	#print(target)
	target = maxf(target, 0.0)   # 避免负值（内容不足一页时）

	# 创建 Tween 并动画滚动
	if scroll_tween: scroll_tween.kill()
	scroll_tween = create_tween()
	scroll_tween.tween_property(_scroll, "scroll_vertical", target, duration)

## Public helper — command methods can call this to print to the console.
func print_line(text: String, color: Color = Color.WHITE) -> void:
	_write(color, text)

# ── Command loading ─────────────────────────────────────────────────────

func _load_commands() -> void:
	_instance = null
	_callables.clear()

	if command_script:
		_instance = command_script.new()
		if _instance:
			for cmd in _instance.get_commands().keys():
				_callables[cmd] = Callable(_instance, "cmd_" + cmd)

	_register_builtins()

func _register_builtins() -> void:
	_callables["help"] = Callable(self, "_cmd_help")
	_callables["log"] = Callable(self, "_cmd_log")
	_callables["clear"] = Callable(self, "_cmd_clear")

# ── Log integration ─────────────────────────────────────────────────────

func _connect_logs() -> void:
	var lm := _get_lm()
	if lm:
		lm.new_log.connect(_on_log)
		if config:
			lm.configure(config.log_file_enabled, config.log_file_path)

func _format_entry(entry) -> String:
	var show_frame := config and config.show_frame_info
	if show_frame:
		return entry._to_string()
	var type_str: String = ["INFO", "WARNING", "ERROR"][entry.type]
	return "[%s] %s %s" % [type_str, entry.time, entry.message]

func _on_log(entry) -> void:
	if not _panel.visible:
		return
	var colors := [Color.WHITE, Color.YELLOW, Color.ORANGE_RED]
	var c: Color = colors[entry.type] if entry.type < colors.size() else Color.WHITE
	_write(c, _format_entry(entry))

func _get_lm() -> Node:
	var rt := get_tree().root if get_tree() else null
	if rt and rt.has_node("LogManager"):
		return rt.get_node("LogManager")
	return null

# ── Built-in commands ───────────────────────────────────────────────────

func _cmd_help(_args: String) -> String:
	var builtins := {
		"help":  "Show this help message.",
		"log":   "Show recent logs. Usage: /log [INFO|WARN|ERROR] [count] [pf>N] [pf<N] [phf>N] [phf<N]",
		"clear": "Clear the console output.",
	}

	var lines: Array[String] = ["──── Available Commands ────"]
	var sorted: Array = []
	for cmd in _callables.keys():
		sorted.append(cmd)
	sorted.sort()

	for cmd in sorted:
		var desc := builtins.get(cmd, "")
		if desc.is_empty() and _instance:
			desc = _instance._get_command_info().get(cmd, "")
		var line := "  /%s" % cmd
		if not desc.is_empty():
			line += "  —  " + desc
		lines.append(line)

	return "\n".join(lines)

func _parse_frame_filters(parts: Array) -> Dictionary:
	## Returns {min_pf, max_pf, min_phf, max_phf} from /log filter arguments.
	var filters := {
		min_pf = -1, max_pf = -1,
		min_phf = -1, max_phf = -1,
	}
	for p in parts:
		var part: String = p.strip_edges()
		if part.begins_with("pf>="):
			filters.min_pf = part.trim_prefix("pf>=").to_int()
		elif part.begins_with("pf<="):
			filters.max_pf = part.trim_prefix("pf<=").to_int()
		elif part.begins_with("pf>"):
			filters.min_pf = part.trim_prefix("pf>").to_int()
		elif part.begins_with("pf<"):
			filters.max_pf = part.trim_prefix("pf<").to_int()
		elif part.begins_with("phf>="):
			filters.min_phf = part.trim_prefix("phf>=").to_int()
		elif part.begins_with("phf<="):
			filters.max_phf = part.trim_prefix("phf<=").to_int()
		elif part.begins_with("phf>"):
			filters.min_phf = part.trim_prefix("phf>").to_int()
		elif part.begins_with("phf<"):
			filters.max_phf = part.trim_prefix("phf<").to_int()
	return filters

func _cmd_log(args: String) -> String:
	var lm := _get_lm()
	if not lm:
		return "[!] LogManager autoload not registered. Enable the plugin first."

	var filter_type := -1
	var count := 20
	var max_display := config.max_log_display if config else 200
	var min_pf := -1
	var max_pf := -1
	var min_phf := -1
	var max_phf := -1

	var all_parts: Array = []
	for part in args.split(" "):
		all_parts.append(part)

	var frame_filters := _parse_frame_filters(all_parts)
	min_pf = frame_filters.min_pf
	max_pf = frame_filters.max_pf
	min_phf = frame_filters.min_phf
	max_phf = frame_filters.max_phf

	for part in all_parts:
		var p: String = part.to_upper().strip_edges()
		if p == "INFO":    filter_type = 0
		elif p == "WARN" or p == "WARNING": filter_type = 1
		elif p == "ERROR": filter_type = 2
		elif p.is_valid_int():
			count = clampi(p.to_int(), 1, max_display)

	var logs: Array = lm.get_logs(filter_type, count, min_pf, max_pf, min_phf, max_phf)
	if logs.is_empty():
		return "[i] No logs."

	var active_filters: Array[String] = []
	if filter_type != -1: active_filters.append(["INFO","WARN","ERROR"][filter_type])
	if min_pf >= 0: active_filters.append("pf>=%d" % min_pf)
	if max_pf >= 0: active_filters.append("pf<=%d" % max_pf)
	if min_phf >= 0: active_filters.append("phf>=%d" % min_phf)
	if max_phf >= 0: active_filters.append("phf<=%d" % max_phf)
	var header := "──── Logs (%d)" % logs.size()
	if not active_filters.is_empty():
		header += " (%s)" % ", ".join(active_filters)
	header += " ────"

	var lines: Array[String] = [header]
	var show_frame := config and config.show_frame_info
	for entry in logs:
		if show_frame:
			var t: String = ["INFO", "WARN", "ERROR"][entry.type]
			lines.append("  [%s] %s [pf:%d|phf:%d] %s" % [t, entry.time, entry.process_frame, entry.physics_frame, entry.message])
		else:
			var t: String = ["INFO", "WARN", "ERROR"][entry.type]
			lines.append("  [%s] %s" % [t, entry.message])
	return "\n".join(lines)

func _cmd_clear(_args: String) -> String:
	_output.clear()
	return ""
