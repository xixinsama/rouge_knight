# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

RougeKnight (肉鸽骑士) — 2D俯视角轻战斗肉鸽游戏，专注于战斗设计和肉鸽中的地图生成

The project is MIT-licensed for learning purposes.

使用最新版godot制作

All logic is GDScript.

## Architecture

### Autoloads (global singletons)

- `GameConst` — screen size constant (1920×1080)
- `InputTest` — detects last input device (keyboard vs gamepad), emits `input_type_changed`
- `SceneLoader` — threaded `ResourceLoader` that shows a loading screen then calls `change_scene_to_packed`
- `Global` — 在global.gd文件中静态定义了mian场景中许多经常被引用的节点，如果需要使用则在mian场景主脚本中赋值，方便调用

### Manual wiring via Global class

`scripts/global.gd` defines a `Global` class with static vars. `main.gd:_ready()` populates them with scene node references. Other scripts access `Global.Floating_Texts`, `Global.Bullet_Factory`, `Global.Path_Finder`, `Global.Layer_Manager`, etc. This is the hub — no autoload for these.

### Physics layers (2D)


| Layer | Name           | Usage             |
| ----- | -------------- | ----------------- |
| 1     | world          | terrain / walls   |
| 2     | player_entity  | player body       |
| 3     | enemy_entity   | enemy body        |
| 4     | player_attack  | player hitboxes   |
| 5     | enemy_attack   | enemy hitboxes    |
| 6     | player_hurtbox | player hurtbox    |
| 7     | enemy_hurtbox  | enemy hurtbox     |
| 8     | object_entity  | objects           |
| 9     | player_parry   | player parry area |

### Core component system

Entities are composed of reusable Node children (not Resources):

- **`HealthComponent`** — HP, `take_damage()`, `heal()`, invincibility frames after hit, signals `damaged`/`died`/`healed`
- **`HurtboxComponent`** (Area2D) — receives damage on `area_entered`, forwards to its `HealthComponent`
- **`HitboxComponent`** (Area2D) — deals damage, has an `active` toggle. Also handles **bullet parry**: when a `Bullet` enters an active HitboxComponent that has `parry_owner` set, the bullet reverses direction and switches ownership
- **`StatusComponent`** — applies `StatusEffect` resources (BURN with tick damage, SLOW with speed multiplier, FREEZE to stop movement)
- **`StaminaComponent`** — WIP stamina placeholder

### Bullet system (data-driven + object pool)

`BulletData` and `StatusEffect` are **Resources** (`.gd` inheriting `Resource`), designed for `.tres` files and editor inspection. The `Bullet` class is an Area2D with `_process`-based movement (accelerates from initial to max speed, rotates toward velocity). `BulletFactory` is a Node that maintains a dictionary pool (`String scene_path → Array[Bullet]`), preloads instances via `preload_pool()`, and spawns/returns them.

Key interaction: bullets parry when entering a parry-area `HitboxComponent`. Status-effect bullets (BURN/SLOW/FREEZE) carry the effect for the receiver to apply.

### Enemy system (component-based, config-driven)

`BaseEnemy` (CharacterBody2D) is the root. It assembles child components:

- **`EnemyStateMachine`** — states: IDLE → CHASE → ATTACK → (back to CHASE). Also STORED (frozen when off-screen layer) and FLEE.
- **`EnemyMovement`** — modes: IDLE, CHASE (with A* pathfinding or direct), FLEE, CHARGE, WANDER. Has local obstacle avoidance (raycast fan) and stuck recovery.
- **`EnemyDetection`** — radius-based player detection with signals `player_detected`/`player_lost`.
- **`EnemyAttack`** (base) / `EnemyAttackMelee` / `EnemyAttackRanged` / `EnemyAttackContact` — polymorphic attack implementations.

`EnemyConfig` is a Resource exported with fields for all behavioral params. Config `.tres` files live in `scenes/enemies/configs/`. `EnemyFactory` spawns enemies given a config and position. The `BaseEnemy._apply_config()` routes config values to individual components.

### Dungeon & navigation

- **3 tile-map layers** (Map/Map2/Map3), each a separate `TileMapLayer` with its own `DungeonGenerator` (WIP procedural generation) and `AstarFindPath` (A* on used cell rect, solid cells = atlas coords with alternative tile == 1).
- **`LayerManager`** — switches between layers with scale+fade tweens. Exposes `current_path_finder` to `Global.Path_Finder` so enemies always pathfind on the active layer.
- **`LayerDoor`** — triggers `LayerManager.switch_layer()` on dash input when player is in range.

### Scene flow

`main_menu.tscn` → (seed input) → `SceneLoader.load_scene("res://scenes/main.tscn")` → threaded load with `loading_screen.tscn` fade animation.

## Key conventions

- **@onready var** references to `$ChildName` are used throughout for node access in `_ready()`.
- **`call_deferred()`** is used for toggling collision/monitoring properties to avoid physics callbacks during setup.
- **Object pooling** is used for bullets; planned but not yet implemented for floating text.
- **MIT license**, permanent open source.

## Editor plugin

Only one: `res://addons/script-ide/` (script-ide).
