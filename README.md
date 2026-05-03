# rouge_knight

肉鸽骑士（暂名）

该项目基于MIT协议永久开源，以供学习

[项目策划案](https://docs.qq.com/sheet/DZXdHUUxoVVBMZnRC)

该文档中包含所有素材的引用

## 主场景结构 (`scenes/main.tscn`)

根节点为 `Main`（Node2D），挂载 `main.gd`，在 `_ready()` 中初始化所有全局引用。

```
Main (Node2D) [main.gd]
├── UI (CanvasLayer)
│   ├── ScreenHint (TextureRect) [screen_hint.gd]          — 全屏遮罩提示
│   ├── TextureProgressBar                                 — 底部红色进度条
│   ├── TextureProgressBar2                                — 底部黄色进度条（默认隐藏）
│   ├── TextureProgressBar4                                — 居中宽进度条（默认隐藏）
│   ├── TextureProgressBar3                                — 底部额外进度条
│   └── UICrosshair (AnimatedSprite2D) [ui_crosshair.gd]   — UI 准星动画
│
├── WorldEnvironment           — 开启 glow 后处理
├── CanvasModulate             — 全局暗灰色调 (0.8, 0.8, 0.8)
│   └── DirectionalLight2D     — 深蓝色平行光
│
├── ParticleSpawner (Node) [particle_spawner.gd]           — 粒子特效生成器
├── BulletFactory (Node) [bullet_factory.gd]               — 子弹对象池工厂
│   ├── Bullet  [fire_ball_bullets.tscn]
│   ├── Bullet2 [fire_ball_bullets.tscn]
│   ├── Bullet3 [fire_ball_bullets.tscn]
│   └── Bullet4 [fire_ball_bullets.tscn]
│
├── FloatingTexts (Node)       — 唯一名 %FloatingTexts，浮动伤害数字容器
├── PathDrawer (Node2D) [draw_path.gd]                     — 唯一名 %PathDrawer，调试寻路绘制
│
├── LayerManager (Node) [layer_manager.gd]                 — 管理多层地图切换
│   all_layers = [Map, Map2, Map3]
│
├── Map (TileMapLayer, scale=2x) [navigate_map.gd]         — 第一层地图
│   ├── DungeonGenerator [dungeon_generator.gd]            — 程序化地牢生成
│   ├── AstarFindPath [astar_find_path.gd]                 — A* 寻路
│   └── LayerDoor [layer_door.tscn]                        — 层间传送门
│
├── Map2 (TileMapLayer) [navigate_map.gd]                  — 第二层地图
│   ├── DungeonGenerator [dungeon_generator.gd]
│   ├── AstarFindPath [astar_find_path.gd]
│   └── LayerDoor2 [layer_door.tscn]
│
├── Map3 (TileMapLayer) [navigate_map.gd]                  — 第三层地图
│   ├── DungeonGenerator [dungeon_generator.gd]
│   └── AstarFindPath [astar_find_path.gd]
│
├── 演示用Player (CharacterBody2D) [character_body_test.gd]
│   collision_layer=2, collision_mask=129
│   ├── Sprite2D                — 角色精灵 4×10 帧，挂载阴影 shader
│   ├── Sprite2D2               — 辅助精灵 4×11 帧
│   ├── CollisionShape2D        — 物理碰撞
│   ├── HurtboxComponent (Area2D) [hurtbox_component.gd]
│   │   collision_layer=32, collision_mask=16
│   │   └── CollisionShape2D
│   ├── HealthComponent (Node) [health_component.gd]       — 生命值
│   └── PointLight2D            — 玩家点光源
│
├── GodotEnemy [GodotEnemy.tscn]                           — 演示敌人实例
│   speed=300, acceleration=300
│
├── CameraController (Camera2D) [camera_controller.gd]
│   target = 演示用Player, zoom 1x~4x, follow_speed=608
│   └── CameraCrosshair (AnimatedSprite2D) [camera_crosshair.gd]
│
├── player弹反 (Area2D) [hitbox_component.gd]              — 玩家弹反判定区
│   collision_layer=8, collision_mask=144
│   └── CollisionShape2D
│
└── enemy弹反 (Area2D) [hitbox_component.gd]               — 敌人弹反判定区
	collision_layer=16, collision_mask=136
	└── CollisionShape2D
```

### 关键设计要点

- **全局注册**：`main.gd` 在 `_ready()` 中将 `FloatingTexts`、`BulletFactory`、`ParticleSpawner`、`UI_Layer`、`ScreenHint`、`PathDrawer`、`LayerManager` 写入 `Global` 单例，其他模块通过 `Global` 访问。
- **多层地图**：Map/Map2/Map3 各为一个 TileMapLayer，由 `LayerManager` 统一管理可见性与切换，每层独立挂载 `DungeonGenerator` 和 `AstarFindPath`。
- **碰撞层划分**：Player collision_layer=2，Hurtbox=32，player弹反=8，enemy弹反=16。弹反 mask 在 136~144 之间交叉匹配。
- **对象池**：`BulletFactory` 预加载 4 个 `fire_ball_bullets` 实例，通过对象池复用。
