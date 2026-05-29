extends Resource
## 记录一层地牢的所有信息
class_name DungeonData

@export var room_config: RoomConfig
## 房间左上角位置
@export var room_position: Vector2i
## 房间旋转(0到3，顺时针)
@export var room_rotate: int = 0
