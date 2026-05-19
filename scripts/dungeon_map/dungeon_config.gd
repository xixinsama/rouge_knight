## 地牢生成参数配置 Resource
class_name DungeonConfig
extends Resource

## 地牢网格大小
@export var dungeon_size := Vector2i(300, 160)
## 尝试放置房间的次数
@export var num_room_tries: int = 200
## 房间信息
## 数组总数表示房间数量上限
## 如果有序生成，则会按顺序连接
@export var rooms: Array[RoomConfig] = []
