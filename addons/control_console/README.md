# Control Console

一个 Godot 4 开发者命令控制台插件。按 **`·`** (反引号键) 呼出，可在任意场景中使用，用于快速调试与测试。

## 快速开始

1. 在项目设置 → 插件中启用 **Control Console**（插件会自动注册 `LogManager` 单例）
2. 将 `res://addons/control_console/scenes/console_ui.tscn` 拖入你的游戏场景
3. 运行游戏，按 `` ` `` 键打开控制台
4. 输入 `/help` 查看所有可用命令

## 文件结构

```
addons/control_console/
├── control_console.gd              # EditorPlugin，注册 LogManager 为 autoload
├── plugin.cfg                      # 插件元数据
├── README.md
├── scripts/
│   ├── console_ui.gd               # 控制台 UI（CanvasLayer），所有核心逻辑
│   ├── console_config.gd           # ConsoleConfig Resource，外观/行为配置
│   ├── command_script.gd           # CommandScript 基类，用户继承以添加自定义命令
│   └── log_manager.gd              # LogManager autoload，全局日志采集
├── scenes/
│   └── console_ui.tscn             # 控制台场景（拖入游戏场景即可使用）
└── examples/
	└── example_commands.gd         # 示例命令脚本
```

## 控制台功能

### 基础操作

| 操作 | 说明 |
|------|------|
| `` ` `` | 切换控制台 开/关 |
| `Esc` | 关闭控制台 |
| `↑` / `↓` | 浏览命令历史 |
| `Tab` | 自动补全命令 |
| `Enter` | 执行命令 |

### 内置命令

| 命令 | 说明 |
|------|------|
| `/help` | 显示所有可用命令及描述 |
| `/log [INFO\|WARN\|ERROR] [数量]` | 查看最近的日志，支持按类型过滤 |
| `/clear` | 清空控制台输出 |

## 自定义命令

创建继承 `CommandScript` 的脚本，以 `cmd_` 前缀定义方法，并重写 `_get_command_info()` 提供帮助文本：

```gdscript
extends CommandScript

func _get_command_info() -> Dictionary:
	return {
		"heal": "回复玩家生命值。用法: /heal <数值>",
		"god":  "切换无敌模式。用法: /god",
	}

func cmd_heal(args: String) -> String:
	var amount := args.to_int() if args.is_valid_int() else 50
	# 在此处调用你的游戏逻辑
	LogManager.info("玩家回复了 %d 点生命" % amount)
	return "[OK] 回复 %d HP" % amount

func cmd_god(_args: String) -> String:
	LogManager.warn("无敌模式已切换")
	return "[OK] 无敌模式已切换"
```

然后将该脚本赋值给 `ConsoleUI` 节点的 `command_script` 导出变量即可。

### 命令方法约定

- 方法名 `cmd_xxx` → 控制台命令 `/xxx`
- 参数 `args: String` → 命令后的所有文本，自行解析
- 返回值 `String` → 显示在控制台中的结果（可选，返回空字符串则不显示）
- 通过 `LogManager` 单例记录日志

## 日志系统

`LogManager` 是插件自动注册的 autoload 单例，可在任意脚本中直接调用：

```gdscript
LogManager.info("玩家生成于 %s" % position)
LogManager.warn("血量低于 20%")
LogManager.error("无法加载资源: %s" % path)
```

- 日志自动缓冲在内存中，通过 `/log` 查看
- 支持类型过滤：`/log WARN`、`/log ERROR 50`
- 默认自动保存明文日志到 `user://logs/console.log`
- 日志格式：`[INFO] 2026-05-24 14:30:00 消息内容`

## 配置

创建 `ConsoleConfig` 资源（`.tres`），设置对应属性后赋值给 `ConsoleUI` 的 `config` 导出变量：

```gdscript
extends Resource
class_name ConsoleConfig

@export var toggle_key: Key = KEY_QUOTELEFT   # 切换键
@export var max_log_display: int = 200         # /log 最大显示条数
@export var max_history: int = 50              # 命令历史最大条数
@export var log_file_enabled: bool = true      # 是否自动保存日志文件
@export var log_file_path: String = "logs/console.log"  # 日志文件路径
```

## ConsoleUI 导出变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `disabled` | `bool` | 设为 `true` 完全禁用控制台 |
| `command_script` | `Script` | 自定义命令脚本（需继承 `CommandScript`） |
| `config` | `ConsoleConfig` | 可选的配置文件 |

## 许可

MIT — 与项目本体一致。
