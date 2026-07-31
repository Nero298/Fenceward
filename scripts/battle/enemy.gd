extends Node2D
class_name Enemy

## Runtime enemy unit. Archetype behavior (Walker/Rusher/Tank/Ranged/Mini-boss)
## is driven by exported stats set at spawn time, not by subclassing —
## keeps the archetype list data-driven and easy to extend via WaveDefinition.

signal died(enemy: Enemy, money_drop: int)
signal reached_fence(enemy: Enemy)

@export var archetype: String = "walker"
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var atk: int = 15
@export var spd: int = 60          # movement speed AND attack-speed driver
@export var money_drop: int = 5
@export var is_ranged: bool = false
@export var ranged_distance: float = 150.0

var lane_index: int = -1
var slowed_until_ms: int = 0
var slow_factor: float = 1.0

var _attack_timer: float = 0.0
const BASE_ATTACK_INTERVAL := 1.0 # seconds between attacks at spd=100 baseline

func _ready() -> void:
	current_hp = max_hp

func _physics_process(delta: float) -> void:
	var arena = get_tree().get_first_node_in_group("battle_arena")
	if arena == null:
		return
	var lane: Lane = arena.get_lane(lane_index)
	if lane == null:
		return
	var effective_spd := spd * slow_factor
	var target_monster := lane.get_active_monster()

	if target_monster != null:
		var dist_to_monster: float = global_position.distance_to(target_monster.global_position)
		var in_range: bool = (is_ranged and dist_to_monster <= ranged_distance) or (not is_ranged and dist_to_monster <= 40.0)
		if in_range:
			_attack_timer += delta
			var interval: float = BASE_ATTACK_INTERVAL * (100.0 / max(effective_spd, 1.0))
			if _attack_timer >= interval:
				_attack_timer = 0.0
				target_monster.take_damage(atk)
			return
		else:
			global_position.x -= effective_spd * delta
			return

	# No monster in lane (dead or never assigned): walk on and hit the fence.
	global_position.x -= effective_spd * delta
	if global_position.x <= lane.fence_x:
		reached_fence.emit(self)
		queue_free()

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		died.emit(self, money_drop)
		queue_free()

func apply_slow(factor: float, duration_ms: int) -> void:
	slow_factor = min(slow_factor, factor)
	slowed_until_ms = Time.get_ticks_msec() + duration_ms
