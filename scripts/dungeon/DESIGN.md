# 基于 Rooms-and-Mazes 的立体三层地牢生成器 设计文档

## 文档信息


| 项目             | 内容                                              |
| ---------------- | ------------------------------------------------- |
| **目标引擎**     | Godot 4.6.2 (GDScript)                           |
| **参考算法**     | Bob Nystrom 的 Rooms-and-Mazes 程序化地牢生成算法 |
| **核心数据结构** | 二维网格数组 + 区域系统 (Region system)           |

## 1. 算法概述

本生成器基于 Rooms-and-Mazes 算法的核心理念：**先放置房间，再用迷宫填充空白区域，最后通过生成树算法将所有区域连接为连通地牢**。在此基础上进行以下扩展以适应三层立体地牢需求：

1. **多层级生成**：为三层地牢每层独立生成平面布局，再通过楼梯和虚空洞进行垂直连接
2. **区块化布局**：将每层划分为 3×3 ~ 5×5 的区块，每个区块为 32×32 瓦片的独立单元
3. **房间模板系统**：策划可预先设计房间模板，生成时从模板库中选取并放置
4. **近线性流程**：通过上锁的门控制玩家的探索路径，需要穿梭三层寻找钥匙以推进进度
5. **地形多样性**：支持通路、墙、各种类型的门、虚空等多种地形属性
6. 房间无环面感知，而迷宫具有环面感知

## 2. 核心设计

### 2.1 整体架构

```
数据层：
地牢基础数据 dungeon_config -> 包含多个 -> 房间数据 room_template

管理层：
dungeon_manager
根据 地牢基础数据 生成 地牢数据 dungeon_data
将 dungeon_data 分发对应 tile_map_layer

tile_map_layer 负责摆放网格
将房间数据映射到具体房间场景，tile_map_layer再次摆放房间

显示层：
layer_manager —— 控制切换层的显示
```

- **DungeonManager**：总控脚本，负责协调三层的生成、楼梯互连、钥匙与门的管理
- **LevelGenerator**：对每一层执行 Rooms-and-Mazes 算法的核心逻辑
- **RegionManager**：管理区域（Region）的创建、合并与追踪，维护区域连通性
- **TilePlacer**：负责将方块数据写入 Godot 的 TileMapLayer，解析不同地形类型的 Tile 索引
- **RoomLibrary**：存储和管理策划设计的所有房间模板及元数据

### 2.2 运行流程概览

```
1. 开始生成地牢
2. 随机决定每层的区块尺寸 (3×3 到 5×5 之间)
3. FOR 每层 (Level 1, 2, 3)：
	a. 创建该层的 BlockGrid (尺寸由第 2 步决定)
	b. 在每个区块的 32×32 网格上运行 Rooms-and-Mazes 生成方格数据
	c. 放置房间 (该层的 Block → Room 映射)
	d. 处理该层的地形类型 (墙/门/虚空 等)
	e. 将方块数据写入该层的 TileMapLayer
4. 处理三层之间的竖直连接 (楼梯、虚空洞)
5. 选择关键门并分配钥匙位置
6. 验证地牢可通关性 (可达性检查)
7. 输出最终地牢
```

## 3. 数据结构定义

### 3.1 基础方块类型 (Cell)

每个 32×32 方块有独立的类型和属性。与原算法不同，这里不仅是“墙”与“走廊”的二元区分，而是一个扩展的地形类型系统。

**方块地形类型：**


| 类型枚举             | 瓦片表现          | 说明                             |
| -------------------- | ----------------- | -------------------------------- |
| `CELL_FLOOR`         | 通路（空地）      | 玩家可行走的普通地面             |
| `CELL_WALL`          | 墙                | 普通障碍物                       |
| `CELL_DOOR_NORMAL`   | 门（普通）        | 可自由通过的门                   |
| `CELL_DOOR_LOCKED`   | 门（上锁）        | 需要对应钥匙才能打开的门         |
| `CELL_DOOR_BARRED`   | 门（禁止破坏）    | 不可被破坏的门，用于剧情阻挡     |
| `CELL_VOID_INTERNAL` | 虚空（隐藏/内部） | 踩上去会让玩家掉落到下一层并受伤 |
| `CELL_VOID_EXTERNAL` | 虚空（外部/普通） | 碰撞体，不可通行，类似深渊边界   |
| `CELL_STAIRS_UP`     | 楼梯（上行）      | 通往上一层的楼梯                 |
| `CELL_STAIRS_DOWN`   | 楼梯（下行）      | 通往下一层的楼梯                 |
| `CELL_PLACEHOLDER`   | 占位              | 暂未使用的格子，生成阶段填充     |

**方块数据结构伪代码：**

```
# 方块数据结构
class Cell:
	var type: int        # 枚举，对应上表
	var region_id: int   # 区域 ID (-1 表示未分配/墙)
	var is_carved: bool  # 是否已被雕刻 (迷宫填充)
	var is_dead_end: bool# 是否是死胡同
	var is_connector: bool# 是否可作为区域连接点

	# 门相关属性
	var lock_id: int     # 锁的 ID (仅 DOOR_LOCKED 有效，用于匹配钥匙)
	var is_broken: bool  # 是否已被破坏/打开

	# 栅格坐标
	var block_x: int     # 区块 X 坐标
	var block_y: int     # 区块 Y 坐标
	var local_x: int     # 方块内部的局部 X 坐标 (0-31)
	var local_y: int     # 方块内部的局部 Y 坐标 (0-31)
```

### 3.2 区块 (Block)

一个区块是 32×32 方块的容器，是房间放置和迷宫生成的基本单元。

```
class Block:
	var block_x: int                    # 区块在该层中的 X 坐标
	var block_y: int                    # 区块在该层中的 Y 坐标
	var cells: Array[Array[Cell]]       # 32×32 的 Cell 数组
	var room_template_id: String        # 挂载的房间模板 ID (可为空)
	var region_id: int                  # 该区块所属的区域 ID
```

### 3.3 区域 (Region)

区域是 Rooms-and-Mazes 算法中的核心概念，当两个区域的边界相邻时会产生连接点，通过打开连接点将多个区域合并以实现整个地牢的连通性。

```
class Region:
	var id: int                         # 唯一标识
	var cells: Array[Vector2i]          # 区域包含的所有 Cell 坐标
	var edge_connectors: Array[Connector] # 该区域边界上的可连接点
	var is_main: bool                   # 是否已被合并到主区域
```

### 3.4 连接点 (Connector)

```
class Connector:
	var pos: Vector2i                  # 连接点在地图上的全局坐标
	var region_a: int                  # 相邻区域 A
	var region_b: int                  # 相邻区域 B
	var is_connected: bool             # 是否已经被打通
```

### 3.5 层 (Level)

```
class DungeonLevel:
	var level_index: int                        # 0/1/2 (代表第一/二/三层)
	var blocks: Array[Array[Block]]             # 该层的区块网格
	var block_count_x: int                      # 区块列数 (3~5)
	var block_count_y: int                      # 区块行数 (3~5)
	var tilemap: TileMapLayer                   # 该层的 TileMap 节点引用
	var block_room_map: Dictionary              # Block坐标 → 房间模板ID 的映射
	var stairs_down_positions: Array[Vector2i]  # 该层下行楼梯位置
	var stairs_up_positions: Array[Vector2i]    # 该层上行楼梯位置
	var void_internal_positions: Array[Vector2i]# 该层内部虚空位置
```

### 3.6 房间模板 (RoomTemplate)

```
class RoomTemplate:
	var id: String                      # 唯一标识，如 "treasure_room_01"
	var cells: Array[Array[int]]        # 32×32 的地形类型数组
	var size: Vector2i                  # 应该固定为 (32, 32)
	var connector_positions: Array[ConnectPoint] # 该房间对外连接点的位置
	var tags: Array[String]             # 标签，如 ["treasure", "combat", "boss"]
	var is_entry: bool                  # 是否为入口房间
	var is_exit: bool                   # 是否为出口房间
	var is_key_room: bool               # 是否包含钥匙
	var is_boss_room: bool              # 是否为 Boss 房间
	var min_floor: int                  # 该房间允许出现的最低层 (用于难度控制，1-3)
	var max_floor: int                  # 该房间允许出现的最高层
	var weight: float                   # 随机选取时的权重
	var allowed_connections: int        # 允许的最大连接数
```

### 3.7 地牢总体数据结构

```
class DungeonData:
	var levels: Array[DungeonLevel]     # 3 层
	var seed: int                       # 随机种子
	var key_door_pairs: Array[KeyDoorPair] # 钥匙-门配对列表

class KeyDoorPair:
	var key_room_block: Vector2i        # 含有钥匙的房间所在区块
	var key_level: int                  # 钥匙所在的层
	var door_block: Vector2i            # 对应的上锁门所在区块
	var door_level: int                 # 门上锁的层
	var lock_id: int                    # 锁的 ID
```

## 4. 生成流程（核心算法）

### 4.1 阶段一：层与区块初始化

**输入**：随机种子
**输出**：三层 DungeonLevel 对象，每层已有区块网格，但方块数据全为 CELL_PLACEHOLDER。

1. 对每层随机决定区块列数 `block_count_x` 和行数 `block_count_y`，范围 [3, 5]
2. 创建 `DungeonLevel` 并初始化 `blocks` 二维数组
3. 每个 Block 内创建 32×32 的 `Cell` 二维数组，初始化为 `CELL_PLACEHOLDER`
4. 为该层创建对应的 TileMapLayer 节点，配置好 TileSet

### 4.2 阶段二：房间放置

在原算法（先放房间再填迷宫）的基础上，这里需要将整个 32×32 的区块与策划设计的房间模板绑定。

**步骤**：

1. **首房间放置**：随机选择一个区块（通常从中央附近开始），从策划设计的房间模板中随机选择一个作为**入口房间**（`is_entry = true`），放置到该区块。将该区块的 32×32 Cell 数组完整替换为模板数据，设置该区块的 `room_template_id`。
2. **后续房间放置**:

   - 为每个层随机决定放置房间的数量。通常房间数应控制在区块总数的 40%~70%
   - 每次从 RoomLibrary 中**基于权重随机选取模板**，注意 **5.2 房间选取策略**中的约束
   - 检查目标区块是否已被占用，若发生冲突则跳过并重试，最多重试 `max_attempts` 次（默认 20 次）
   - 放置成功后将该区块的 Cell 数组替换为模板数据并记录映射
3. **特殊房间配置**:

   - 确保每层至少有一个房间标记为 `is_key_room`
   - Boss 房间优先放置在第三层（`level_index = 2`）且深度最远的区块
   - 出口房间放置在第三层

### 4.3 阶段三：迷宫填充（雕刻走廊）

对每个区块中未被房间占用的空间，通过迷宫雕刻进行填充。

**步骤**：

1. 遍历每个区块的 32×32 Cell 数组，找到所有类型为 `CELL_PLACEHOLDER` 的 Cell
2. 对相邻的未占用空间进行**递归回溯迷宫算法**或**随机洪水填充**，生成的 Cell 属于同一个区域（region），分配相同的 `region_id`
3. 雕刻出的走廊类型为 `CELL_FLOOR`
4. 每个区块独立进行迷宫填充，保证迷宫区域不穿越房间边界，确保房间的完整性

**死胡同处理**：

根据参数 `dead_end_removal_ratio`（默认 0.6），随机移除一定比例的死胡同。死胡同定义为仅有一侧连通（三面是墙）的 Cell。反雕刻时将该 Cell 从 `CELL_FLOOR` 重置为 `CELL_WALL`，这会使得与之相邻的唯一走廊块变为新的死胡同，形成连锁移除效应，从而简化迷宫结构。

### 4.4 阶段四：区域连通

这是整个算法中实现地牢连通的核心步骤。

**输入**：区域数据（Regions）
**输出**：连通的地牢（spanning tree + 少量循环连接）

**步骤**：

1. **生成所有区域列表**：遍历每个区块的所有 Cell，按 `region_id` 分组，统计出本层所有独立的区域（包含房间内部和迷宫区域）
2. **寻找连接点**：遍历所有区域边界，收集毗邻方块为墙（`CELL_WALL`）且左右两侧各属于不同区域的 Cell，生成连接器对象 `Connector`
3. **构建生成树（Spanning Tree）**：

   - 随机选择一个区域作为主区域，将其 `is_main` 设为 `true`
   - 收集主区域边界上的所有连接器
   - 随机选择一个连接器并将其打通，类型设为 `CELL_DOOR_NORMAL`
   - 将连接的两个区域合并到主区域中（用 Flood Fill 重新标记 region_id）
   - 移除掉该连接器所连两区域之间其余的多余连接器
   - 重复以上步骤直到所有区域合并为一个主区域
4. **打破完美性**：在移除多余连接器时，以概率 `extra_connection_chance`（默认 2%）保留额外的连接器并进行雕刻，使得地牢中存在循环路径。可调参数用以控制连通复杂度
5. **死胡同反雕刻**：在连通完成后，再次处理未能通向房间的走廊死胡同。只保留连通至少一个房间的走廊段（此时已有区域信息可准确判断），其余死胡同重置为 `CELL_WALL`

### 4.5 阶段五：地形类型处理

将抽象的方块数据转换为相应的地形瓦片并记录属性。

**实现要点**：


| 地形类型              | 碰撞类型                       | 说明                                            |
| --------------------- | ------------------------------ | ----------------------------------------------- |
| `CELL_FLOOR`          | 无碰撞                         | 玩家可行走，设置为 Navigation Region 的可通行层 |
| `CELL_WALL`           | 静态碰撞体 2D                  | 不可通行                                        |
| `CELL_DOOR_NORMAL`    | Area2D（可通行）/ 按需改为碰撞 | 玩家可自由进出                                  |
| `CELL_DOOR_LOCKED`    | 静态碰撞体（被锁时）           | 上锁状态不可通行，解锁后变为 FLOOR              |
| `CELL_DOOR_BARRED`    | 静态碰撞体（永久）             | 始终不可破坏                                    |
| `CELL_VOID_INTERNAL`  | Area2D（掉落触发）             | 玩家进入时触发掉落事件，切换到下一层并受伤害    |
| `CELL_VOID_EXTERNAL`  | 静态碰撞体                     | 不可通行，表现为深渊边界                        |
| `CELL_STAIRS_UP/DOWN` | Area2D（传送触发）             | 玩家进入时切换到对应层                          |

**TileMapLayer 的使用**：

使用 `set_cell(Vector2i(local_x, local_y), source_id, atlas_coords)` 在运行时将区块的方格数据写入 TileMapLayer。每个地形类型对应 TileSet 中的一个图块源（Source）和图集坐标（Atlas Coordinates）。

**内部虚空的处理**：

内部虚空的位置需要在生成时记录并存储到 `void_internal_positions`。该虚空上不应是可通行的地板图块，而应是一个有坠落触发器（Area2D）功能的分层瓦片。玩家进入时传送到下一层的对应位置并扣减生命值。

### 4.6 阶段六：楼梯放置与垂直连接

三层之间通过楼梯进行垂直连接，形成循环结构（第三层向上回到第一层）。

**规则**：

- 每层至少放置 **1~2 个上行楼梯** 和 **1~2 个下行楼梯**
- 楼梯放置在已生成的房间区块内的空闲 Cell 上（FLOOR 类型，非门）
- **向上**的楼梯：从 Layer 0 → Layer 1，Layer 1 → Layer 2，Layer 2 → Layer 0（循环）
- **向下**的楼梯：从 Layer 0 → Layer 2，Layer 2 → Layer 1，Layer 1 → Layer 0（循环）
- 每对楼梯的位置记录在对应层的 `stairs_down_positions` 和 `stairs_up_positions` 中
- 楼梯之间的对应关系存储在一个 `Dictionary` 类 `stairs_map` 中，键为该层坐标，值为目标层坐标

### 4.7 阶段七：钥匙与上锁的门

**近线性流程的实现**：通过在不同层之间设置需要钥匙才能打开的门，强制玩家在三层之间穿梭探索，逐步解锁新的区域。

**生成步骤**：

1. **分析区域可达性**：在三层全部生成完成后，分析当前连通状态下哪些区域已被连通、哪些仍被锁阻挡
2. **选择关键阻挡点**：在主干路线上的两个房间之间，选择 1~3 个连通走廊（`CELL_FLOOR`），将它们改为 `CELL_DOOR_LOCKED`，分配唯一的 `lock_id`
3. **放置对应钥匙**：

   - 钥匙房间（`is_key_room = true`）中放置对应的钥匙物品
   - 至少有一个钥匙房间在**不同层**，确保玩家需要穿梭楼层才能获取钥匙
   - 记录 `KeyDoorPair { key_room, key_level, door_block, door_level, lock_id }`
4. **验证流程可行性**：运行可达性测试，确保：

   - 玩家从入口房间出发可以到达至少一把钥匙所在房间
   - 拿到该钥匙后可以打开对应的门并继续前进
   - 最终可以到达出口房间
   - 不存在死锁情况（即玩家不需要经过必须打开的门才能拿到对应的钥匙）
5. **调整策略**：如果可达性测试失败，则重新选择门的位置或调整钥匙房间的放置，直到生成一个可行的地牢为止

### 4.8 阶段八：房间实例化

在生成并验证完所有地牢数据后，根据 Block → 房间模板的映射，将策划设计的实际房间场景实例化。

**实现方式**：

1. **读取映射表**：从 `block_room_map` 中获取每个区块对应的房间模板 ID
2. **实例化场景**：使用 `RoomLibrary.get_template(id)` 获取模板数据，实例化对应的 PackedScene（`.tscn` 文件）
3. **放置位置**：根据区块坐标计算实例化的 Word 位置，`position = Vector2(block_x * 32 * TILE_SIZE, block_y * 32 * TILE_SIZE)`
4. **特殊处理**：
   - 房间模板中的连接点需要对外开放（将与迷宫走廊连接的边缘门打开）
   - 内部虚空所在区块需要额外添加坠落检测逻辑
   - 有锁的门的区块需要挂载上锁逻辑及状态管理

## 5. 房间模板系统

### 5.1 模板设计

策划需要在 Godot 编辑器中设计每个具体的房间场景，导出为 `.tscn` 文件或纯数据文件（JSON/Resource），然后注册到 RoomLibrary 中。

**模板包含内容**：

- 32×32 的方格地形数据
- 连接点位置（至少 1 个，最多 4 个，代表房间的入口/出口方向）
- 房间具体内容（敌人、宝箱、装饰物等，作为子节点）
- 元数据标签

### 5.2 房间选取策略

在生成阶段放置房间时，并不是完全随机选取模板，需要遵循以下策略：

1. **层级约束**：部分房间有 `min_floor` 和 `max_floor` 限制，保证低层只有简单房间，高层才会放 Boss 房间等
2. **连接约束**：房间的 `allowed_connections` 值决定了该房间能与多少个迷宫走廊相连（通常在 1~2 之间），走廊连接数超过该值的房间将不会放置
3. **权重选取**：尊重策划配置的 `weight` 值进行加权随机
4. **非重叠性**：同一个房间模板在一层内不应出现两次，除非特殊标记
5. **保证多样性**：确保 Boss 房间、钥匙房间、入口房间等特殊房间至少各有一个

### 5.3 连接点处理

房间模板中的连接点（`connector_positions`）指明了房间可以与外部迷宫走廊连接的位置。在区域连通阶段，优先在这些连接点位置生成门（类型为 `CELL_DOOR_NORMAL` 或 `CELL_DOOR_LOCKED`）。

如果一个房间有两个以上的连接点，但 `allowed_connections` 为 1，那么多余的连接点将保持为墙（`CELL_WALL`），不对外开放。

## 6. Godot 实现要点

### 6.1 场景结构

```
Dungeon (Node2D)
├── DungeonManager (Node, 挂载 DungeonManager.gd)
├── Level0 (Node2D)
│   ├── TileMapLayer (地板与墙的瓦片)
│   ├── Objects (Node2D, 门、楼梯、虚空等)
│   └── Rooms (Node2D, 放置实例化的房间场景)
├── Level1 (Node2D)
│   ├── TileMapLayer
│   ├── Objects
│   └── Rooms
└── Level2 (Node2D)
	├── TileMapLayer
	├── Objects
	└── Rooms
```

### 6.2 TileMapLayer 与 TileSet 配置

- 使用单一 TileSet 资源，包含所有地形类型的图块
- 每个地形类型在 TileSet 中分配独立的 Source ID 和 Atlas Coordinates
- 使用 `tile_map_layer.set_cell()` 在运行时写入

**TileSet 的 Source ID 分配示例**：


| Source ID | 地形类型           |
| --------- | ------------------ |
| 0         | CELL_FLOOR         |
| 1         | CELL_WALL          |
| 2         | CELL_DOOR_NORMAL   |
| 3         | CELL_DOOR_LOCKED   |
| 4         | CELL_DOOR_BARRED   |
| 5         | CELL_VOID_INTERNAL |
| 6         | CELL_VOID_EXTERNAL |
| 7         | CELL_STAIRS_UP     |
| 8         | CELL_STAIRS_DOWN   |

### 6.3 随机种子管理

- 使用 Godot 的 `seed()` 函数初始化随机数生成器
- 种子值存储于 `DungeonData.seed`，确保相同种子生成相同地牢
- 每层生成时使用派生种子：`seed + level_index * 1000`，保证各层独立但可复现

### 6.4 性能优化建议

- 只在玩家进入新层时生成该层（延迟加载），而非一次性生成全部三层
- 使用 `set_cells_terrain_connect()` 或 `set_cells_terrain_path()` 替代逐 Cell 调用 `set_cell()` 以提高 TileMap 更新性能（Godot 4.x 中可用）
- 使用 `call_deferred()` 分散生成逻辑到多帧，避免生成阶段卡顿

## 7. 参数配置


| 参数名                    | 类型  | 默认值 | 说明                             |
| ------------------------- | ----- | ------ | -------------------------------- |
| `min_blocks`              | int   | 3      | 每层最小区块数（行列）           |
| `max_blocks`              | int   | 5      | 每层最大区块数（行列）           |
| `block_size`              | int   | 32     | 每个区块的瓦片大小（像素）       |
| `room_density`            | float | 0.6    | 房间占区块的比例（0.4~0.7）      |
| `extra_connection_chance` | float | 0.02   | 额外连接点的概率（打破完美迷宫） |
| `dead_end_removal_ratio`  | float | 0.6    | 死胡同移除比例（0.0~1.0）        |
| `max_room_attempts`       | int   | 20     | 放置房间的最大重试次数           |
| `num_key_door_pairs`      | int   | 3      | 钥匙-门配对数量                  |
| `min_stairs_per_level`    | int   | 1      | 每层最小楼梯数量                 |
| `max_stairs_per_level`    | int   | 2      | 每层最大楼梯数量                 |
| `void_damage`             | int   | 10     | 玩家坠入虚空时受到的伤害值       |
| `seed`                    | int   | 随机   | 生成种子                         |

## 8. 附加功能建议

### 8.1 迷你地图

生成过程中已知所有 Cell 类型，可快速渲染出简化的迷你地图，在 UI 中展示。

### 8.2 调试可视化

在编辑器中添加可视化工具，显示：

- 各区块的区域 ID 颜色分布
- 连接点的位置和高亮
- 关键门的位置标记
- 死胡同的标注

### 8.3 可通行性验证组件

独立的测试流程验证地牢的可通行性：

- 从入口房间开始 BFS 遍历所有可通行的 Cell
- 逐步“获取钥匙”并解锁对应的门，扩展可通行范围
- 检查出口房间是否最终可达

## 9. 测试建议


| 测试项     | 方法                                 | 预期                        |
| ---------- | ------------------------------------ | --------------------------- |
| 连通性     | BFS 从入口遍历所有可通行区域         | 出口房间可达                |
| 钥匙逻辑   | 模拟玩家逐步收集钥匙、开锁、推进流程 | 最终可达出口                |
| 虚空伤害   | 玩家触碰 CELL_VOID_INTERNAL          | 传送到下一层并扣血          |
| 楼梯循环   | 第三层向上走到第一层                 | 正确传送                    |
| 区块随机   | 多次生成，统计区块尺寸分布           | 3×3 到 5×5 范围内均匀分布 |
| 死胡同清除 | 统计生成后死胡同数量与原始数量之比   | 接近参数设定的比例          |
| 门类型正确 | 遍历地牢，检查门的瓦片类型           | 与 Cell 枚举值一致          |

> 每次生成日志中应记录生成所用的种子值，以便复现和调试问题。
