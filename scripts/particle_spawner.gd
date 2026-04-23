extends Node
## 保存一些常用的场景临时粒子效果
class_name ParticleSpawner

const BLOOD = preload("res://scenes/particles/blood.tscn")

func emit_particle_scene(flag: int, global_pos: Vector2, particle_rotation: float):
	match flag:
		0:
			var blood: GPUParticles2D = BLOOD.instantiate()
			blood.finished.connect(blood.queue_free)
			self.add_child(blood)
			blood.global_position = global_pos
			blood.rotation = particle_rotation
			blood.emitting = true
