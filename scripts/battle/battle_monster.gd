extends Node2D
class_name BattleMonster

## Runtime representation of one deployed squad monster during a fight.
## Auto-attacks the nearest enemy in its lane; skill is fired by player tap
## via BattleArena when off cooldown.

signal died
signal hp_changed(current: int, max: int)
signal cooldown_changed(remaining: float, total: float)

var instance_ref: MonsterInstance
var lane_index: int = -1

var max_hp: int = 100
var current_hp: int = 100
var atk: int = 10
var def: int = 10
var spd: int = 100

var is_dead: bool = false
var skill_cooldown_total: float = 8.0
var skill_cooldown_remaining: float = 0.0

var _attack_timer: float = 0.0
const BASE_ATTACK_INTERVAL := 1.0

func setup(instance: MonsterInstance) -> void:
	instance_ref = instance
	var stats := instance.get_stats()
	max_hp = stats.hp
	current_hp = max_hp
	atk = stats.atk
	def = stats.def
	spd = stats.spd
	var data := instance.get_data()
	if data != null:
		skill_cooldown_total = data.skill_cooldown_seconds
	hp_changed.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if skill_cooldown_remaining > 0.0:
		skill_cooldown_remaining = max(0.0, skill_cooldown_remaining - delta)
		cooldown_changed.emit(skill_cooldown_remaining, skill_cooldown_total)

	var arena = get_tree().get_first_node_in_group("battle_arena")
	if arena == null:
		return
	var lane: Lane = arena.get_lane(lane_index)
	if lane == null or lane.enemies_in_lane.is_empty():
		return
	var target := _find_nearest_enemy(lane)
	if target == null:
		return
	_attack_timer += delta
	var interval: float = BASE_ATTACK_INTERVAL * (100.0 / max(spd, 1.0))
	if _attack_timer >= interval:
		_attack_timer = 0.0
		target.take_damage(max(1, atk))

func _find_nearest_enemy(lane: Lane) -> Enemy:
	var nearest: Enemy = null
	var nearest_dist := INF
	for e in lane.enemies_in_lane:
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func take_damage(amount: int) -> void:
	if is_dead:
		return
	var mitigated: int = max(1, amount - int(def * 0.5))
	current_hp -= mitigated
	hp_changed.emit(max(current_hp, 0), max_hp)
	if current_hp <= 0:
		is_dead = true
		died.emit()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

## Called when the player taps this monster's portrait in the bottom panel.
func try_trigger_skill() -> bool:
	if is_dead or skill_cooldown_remaining > 0.0:
		return false
	skill_cooldown_remaining = skill_cooldown_total
	_execute_skill()
	return true

func _execute_skill() -> void:
	var data := instance_ref.get_data() if instance_ref != null else null
	if data == null:
		return
	var arena = get_tree().get_first_node_in_group("battle_arena")
	if arena == null:
		return
	var lane: Lane = arena.get_lane(lane_index)
	match data.skill_type:
		"aoe_lane":
			if lane != null:
				for e in lane.enemies_in_lane.duplicate():
					if is_instance_valid(e):
						e.take_damage(int(atk * 0.6))
		"aoe_adjacent":
			for offset in [-1, 0, 1]:
				var adj: Lane = arena.get_lane(lane_index + offset)
				if adj != null:
					for e in adj.enemies_in_lane.duplicate():
						if is_instance_valid(e):
							e.take_damage(int(atk * 0.7))
		"single_target":
			if lane != null:
				var target := _find_nearest_enemy(lane)
				if target != null:
					target.take_damage(int(atk * 1.8))
		"slow":
			if lane != null:
				var target := _find_nearest_enemy(lane)
				if target != null:
					target.apply_slow(0.5, 3000)
		"heal_fence":
			arena.heal_fence(int(max_hp * 0.15))
		"buff_def":
			def = int(def * 1.5)
			get_tree().create_timer(4.0).timeout.connect(func(): def = int(def / 1.5))
