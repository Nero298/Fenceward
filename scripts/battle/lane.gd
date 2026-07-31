extends Node2D
class_name Lane

## One of the 5 lanes between the spawn edge and the fence. Holds at most one
## deployed monster. If empty or the monster has died, enemies in this lane
## walk on and damage the fence directly — this is the core TD rule.

@export var lane_index: int = 0
@export var fence_x: float = 0.0

var _monster: BattleMonster = null
var enemies_in_lane: Array[Enemy] = []

func set_monster(monster: BattleMonster) -> void:
	_monster = monster
	if monster != null:
		monster.died.connect(_on_monster_died)

func get_active_monster() -> BattleMonster:
	if _monster != null and is_instance_valid(_monster) and not _monster.is_dead:
		return _monster
	return null

func _on_monster_died() -> void:
	# Monster stays referenced but get_active_monster() will now return null,
	# so enemies already engaging it fall through to walking on next physics tick.
	pass

func register_enemy(enemy: Enemy) -> void:
	enemies_in_lane.append(enemy)
	enemy.lane_index = lane_index
	enemy.tree_exited.connect(func(): enemies_in_lane.erase(enemy))
