## 房间数据
## 地牢生成时使用该数据放置房间
## room_id 与 real_room 对应，生成装饰后房间
class_name RoomConfig
extends Resource

## 唯一标识
@export var room_id: String = ""
## 房间矩形大小
@export var room_size: Vector2i = Vector2i(8, 8)
## 地形类型数组（一维，长度 w*h）
## 记录基本地形信息，根据 DungeonGrid
@export var cells: Array[int] = []
## 该房间允许出现的层数，[0,1,2]表示三层都出现，为空则设置权重为0
@export var allowed_floor: Array[int] = []
## 随机选取时的权重
@export var weight: float = 1.0
## 允许的最大连接数
@export var allowed_connections: int = 2
