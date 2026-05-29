extends Node
class_name AttackComponent

signal attack_started(segment_index: int)
signal attack_phase_changed(phase: int)   # 0=windup,1=active,2=recovery
signal attack_hit(hurtbox: HurtboxComponent, damage: int, impact_level: int)
signal attack_finished()

@export var stats: StatsComponent
@export var stamina: StaminaComponent
@export var hitbox: HitboxComponent
@export var animation_player: AnimationPlayer
@export var weapon_data: WeaponData = WeaponData.new()
@export var impact_config: ImpactConfig = ImpactConfig.new()

## 攻速倍率（buff用，1.0为基准）
var attack_speed_mult: float = 1.0

## 内部状态
enum Phase { INACTIVE, WINDUP, ACTIVE, RECOVERY }
var current_phase = Phase.INACTIVE
var phase_timer: float = 0.0
var is_attacking: bool = false
var current_combo_index: int = -1
var combo_input_queued: bool = false
var hit_targets_this_attack: Array[HurtboxComponent] = []

## 攻击冷却
var attack_cooldown: float = 0.0
var can_attack: bool = true

## 差合窗口（弹反）
@export var counter_window_enabled: bool = false
var counter_window_active: bool = false

func _physics_process(delta):
	# 冷却更新
	if attack_cooldown > 0:
		attack_cooldown -= delta
		can_attack = attack_cooldown <= 0.0
	
	if not is_attacking: return
	
	phase_timer += delta
	
	match current_phase:
		Phase.WINDUP:
			if phase_timer >= get_current_windup():
				enter_phase(Phase.ACTIVE)
		Phase.ACTIVE:
			if phase_timer >= get_current_active():
				enter_phase(Phase.RECOVERY)
		Phase.RECOVERY:
			# 连击输入缓冲检查
			if combo_input_queued and combo_input_window_open():
				start_next_combo_segment()
				return
			if phase_timer >= get_current_recovery():
				end_attack()

func request_attack() -> bool:
	"""外部调用（按键），尝试开始攻击或缓冲连击"""
	if is_attacking:
		if current_combo_index >= 0 and combo_input_window_open():
			combo_input_queued = true
			return true
		else:
			return false
	if not can_attack: return false
	
	# 从第一段开始
	start_attack()
	return true

func start_attack():
	# 确定使用哪一段的数据（0或连击）
	current_combo_index = 0
	apply_segment(current_combo_index)
	attack_cooldown = 1.0 / (weapon_data.attacks_per_second * attack_speed_mult)
	can_attack = false
	hit_targets_this_attack.clear()
	combo_input_queued = false
	is_attacking = true
	enter_phase(Phase.WINDUP)
	attack_started.emit(current_combo_index)

func start_next_combo_segment():
	current_combo_index += 1
	apply_segment(current_combo_index)
	hit_targets_this_attack.clear()
	combo_input_queued = false
	phase_timer = 0.0
	enter_phase(Phase.WINDUP)
	attack_started.emit(current_combo_index)

func apply_segment(index: int):
	var seg = get_segment(index)
	if animation_player and seg.animation_name:
		animation_player.play(seg.animation_name, -1, attack_speed_mult)

func enter_phase(new_phase: Phase):
	current_phase = new_phase
	phase_timer = 0.0
	attack_phase_changed.emit(new_phase)
	
	match new_phase:
		Phase.WINDUP:
			hitbox.active = false
			counter_window_active = false
		Phase.ACTIVE:
			hitbox.active = true
			# 连接 hit 信号（确保只连一次，可另加标志）
			if not hitbox.hit.is_connected(_on_hitbox_hit):
				hitbox.hit.connect(_on_hitbox_hit)
			# 差合窗口（如果该武器允许弹反）
			counter_window_active = counter_window_enabled
		Phase.RECOVERY:
			hitbox.active = false
			counter_window_active = false
			if hitbox.hit.is_connected(_on_hitbox_hit):
				hitbox.hit.disconnect(_on_hitbox_hit)

func end_attack():
	is_attacking = false
	current_phase = Phase.INACTIVE
	current_combo_index = -1
	hitbox.active = false
	counter_window_active = false
	if hitbox.hit.is_connected(_on_hitbox_hit):
		hitbox.hit.disconnect(_on_hitbox_hit)
	attack_finished.emit()

func _on_hitbox_hit(hurtbox: HurtboxComponent):
	if hurtbox in hit_targets_this_attack: return
	hit_targets_this_attack.append(hurtbox)
	
	# 伤害计算
	var base_dmg = stats.base_damage * get_current_damage_multiplier()
	# 暴击判断
	var is_crit = randf() < stats.crit_rate
	var final_dmg = base_dmg * (stats.crit_damage_multiplier if is_crit else 1.0)
	
	# 造成伤害（通过hurtbox关联的health）
	if hurtbox.health_component:
		hurtbox.health_component.take_damage(final_dmg)
	
	# 冲击力处理（可由专门的系统处理，这里简单发出信号）
	var impact_lvl = get_current_impact_level()
	attack_hit.emit(hurtbox, final_dmg, impact_lvl)

func get_current_windup() -> float:   return get_segment(current_combo_index).windup_time / attack_speed_mult
func get_current_active() -> float:   return get_segment(current_combo_index).active_time / attack_speed_mult
func get_current_recovery() -> float: return get_segment(current_combo_index).recovery_time / attack_speed_mult
func get_current_damage_multiplier(): return get_segment(current_combo_index).damage_multiplier
func get_current_impact_level():       return get_segment(current_combo_index).impact_level

func combo_input_window_open() -> bool:
	# 连击窗口：当前在恢复阶段，且计时小于 combo_input_window
	if current_phase != Phase.RECOVERY: return false
	return phase_timer <= get_segment(current_combo_index).combo_input_window

func get_segment(index: int) -> ComboSegment:
	if weapon_data.combo_segments.size() > index and index >= 0:
		return weapon_data.combo_segments[index]
	# 默认使用武器基础数据
	var def = ComboSegment.new()
	def.windup_time = weapon_data.windup_time
	def.active_time = weapon_data.active_time
	def.recovery_time = weapon_data.recovery_time
	def.damage_multiplier = weapon_data.damage_multiplier
	def.impact_level = weapon_data.impact_level
	def.animation_name = weapon_data.animation_name
	return def
