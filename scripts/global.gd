extends Node
## 保存场景的必要引用
class_name Global

static var UI_Layer: CanvasLayer
## 按层排序
static var Particle_Spawner: ParticleSpawner
static var Enemy_Factory: EnemyFactory
static var Bullet_Factory: BulletFactory
static var Floating_Texts: Node ## 挂载所有伤害数字

static var Screen_Hint: ScreenHint

static var Layer_Manager: LayerManager
static var Path_Finder: AstarFindPath ## 由Layer_Manager设置

static var draw_path: Node2D ## 绘制寻路路径，测试用
