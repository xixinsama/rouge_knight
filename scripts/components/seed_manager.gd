extends Node

var master_seed: int = 0

# 初始化游戏的主种子
func set_master_seed(new_seed: int):
	master_seed = new_seed
	print("Master Seed Set to: ", master_seed)

# 核心方法：获取一个独立的随机数生成器
# salt (盐): 一个用于区分不同系统的字符串或数字
func get_rng(salt: Variant) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	
	# 将主种子和盐混合，生成一个唯一的子种子
	var unique_seed = hash([master_seed, salt]) 
	
	rng.seed = unique_seed
	return rng
