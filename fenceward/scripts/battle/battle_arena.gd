extends Node2D

## BattleArena — THE single reusable battle scene, per the architecture note in
## the design spec: Stages, Dungeons, and the World Boss all instance this one
## scene with a different BattleConfig. Do not fork separate battle scenes.
##
## This script is intended to be the scene's root script (autoload access
## pattern below assumes it registers itself as a scene-local singleton via
## the `BattleArena` global name — set this scene's root script's class_name
## or reference it directly; see notes at bottom of file for wiring).

signal battle_won(three_star: bool)
signal battle_lost
signal fence_hp_changed(current: int, max: int)
signal wave_changed(current_wave: int, total_waves: int)
signal boss_hp_changed(current: int, max: int)
signal boss_time_remaining(seconds: float)

const ENEMY_SCENE := preload("res://scenes/battle/enemy.tscn")

@export var lanes: Array[NodePath] = []
@export var enemy_spawn_point: Node2D
@export var fence_max_hp: int = 1000

var _lanes: Array[Lane] = []
var _battle_monsters: Array[BattleMonster] = []
var config: BattleConfig

var fence_current_hp: int = 1000
var took_no_fence_damage: bool = true # for 3-star tracking

var _current_wave_index: int = 0
var _enemies_remaining_in_battle: int = 0
var _wave_active: bool = false
var _speed_multiplier: float = 1.0
var _paused: bool = false

# Boss-fight state
var boss_current_hp: int = 0
var boss_max_hp: int = 0
var boss_time_remaining_sec: float = 0.0
var _boss_active: bool = false
var _boss_special_timer: float = 0.0

func _ready() -> void:
	add_to_group("battle_arena")
	for path in lanes:
		_lanes.append(get_node(path) as Lane)
	fence_current_hp = fence_max_hp

## Static-style accessor so Enemy/Lane/BattleMonster (which are not autoloads,
## since a scene can only have one active BattleArena instance at a time) can
## reach the current arena without a direct node reference. Call as
## BattleArenaRef.get_current(tree).
static func get_current(tree: SceneTree):
	return tree.get_first_node_in_group("battle_arena")

## Entry point: call this after instancing the scene, passing the config that
## determines whether this is a Stage, Dungeon, or World Boss fight.
func start_battle(battle_config: BattleConfig) -> void:
	config = battle_config
	if GameState.squad_size() < config.min_squad_size:
		push_error("BattleArena: squad size %d below required minimum %d" % [GameState.squad_size(), config.min_squad_size])
		battle_lost.emit()
		return
	_deploy_squad()
	if config.is_boss_fight:
		_start_boss_fight()
	else:
		_start_wave_fight()

func _deploy_squad() -> void:
	var squad := GameState.get_squad_monsters()
	for i in range(_lanes.size()):
		if i < squad.size():
			var bm := BattleMonster.new()
			bm.setup(squad[i])
			bm.lane_index = i
			_lanes[i].set_monster(bm)
			_lanes[i].add_child(bm)
			_battle_monsters.append(bm)

func get_lane(index: int) -> Lane:
	if index < 0 or index >= _lanes.size():
		return null
	return _lanes[index]

func heal_fence(amount: int) -> void:
	fence_current_hp = min(fence_max_hp, fence_current_hp + amount)
	fence_hp_changed.emit(fence_current_hp, fence_max_hp)

func _damage_fence(amount: int) -> void:
	fence_current_hp -= amount
	took_no_fence_damage = false
	fence_hp_changed.emit(max(fence_current_hp, 0), fence_max_hp)
	if fence_current_hp <= 0:
		_end_battle(false)

# ---- Standard Stage/Dungeon wave flow ----

func _start_wave_fight() -> void:
	_current_wave_index = 0
	wave_changed.emit(_current_wave_index + 1, config.wave_definitions.size())
	_spawn_wave(config.wave_definitions[_current_wave_index])

func _spawn_wave(wave: WaveDefinition) -> void:
	_wave_active = true
	_enemies_remaining_in_battle = wave.count
	for i in range(wave.count):
		var t := wave.start_delay_seconds + i * wave.spawn_interval_seconds
		get_tree().create_timer(t / _speed_multiplier).timeout.connect(func(): _spawn_enemy(wave))

func _spawn_enemy(wave: WaveDefinition) -> void:
	if _lanes.is_empty():
		return
	var lane_idx := randi() % _lanes.size()
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.archetype = wave.enemy_archetype
	var difficulty_mult := 1.0 + 0.12 * GameState.unlocked_stage_index
	enemy.max_hp = int(wave.base_hp * difficulty_mult)
	enemy.atk = int(wave.base_atk * difficulty_mult)
	enemy.spd = wave.base_spd
	enemy.money_drop = wave.base_money_drop
	enemy.is_ranged = (wave.enemy_archetype == "ranged")
	if wave.enemy_archetype == "rusher":
		enemy.spd = int(enemy.spd * 1.6)
		enemy.max_hp = int(enemy.max_hp * 0.6)
	elif wave.enemy_archetype == "tank":
		enemy.spd = int(enemy.spd * 0.6)
		enemy.max_hp = int(enemy.max_hp * 2.2)
	elif wave.enemy_archetype == "miniboss":
		enemy.max_hp = int(enemy.max_hp * 5.0)
		enemy.atk = int(enemy.atk * 1.5)

	enemy_spawn_point.add_child(enemy)
	enemy.global_position = enemy_spawn_point.global_position + Vector2(0, lane_idx * 80)
	_lanes[lane_idx].register_enemy(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_fence.connect(_on_enemy_reached_fence)

func _on_enemy_died(_enemy: Enemy, money_drop: int) -> void:
	GameState.add_money(money_drop)
	_enemies_remaining_in_battle -= 1
	_check_wave_complete()

func _on_enemy_reached_fence(enemy: Enemy) -> void:
	_damage_fence(enemy.atk * 3) # a breached enemy deals a burst hit to the fence
	_enemies_remaining_in_battle -= 1
	_check_wave_complete()

func _check_wave_complete() -> void:
	if _enemies_remaining_in_battle > 0 or not _wave_active:
		return
	_wave_active = false
	_current_wave_index += 1
	if _current_wave_index >= config.wave_definitions.size():
		_end_battle(true)
	else:
		wave_changed.emit(_current_wave_index + 1, config.wave_definitions.size())
		_spawn_wave(config.wave_definitions[_current_wave_index])

# ---- World Boss flow ----

func _start_boss_fight() -> void:
	_boss_active = true
	boss_max_hp = config.boss_hp_pool
	boss_current_hp = boss_max_hp
	boss_time_remaining_sec = config.boss_time_limit_seconds
	boss_hp_changed.emit(boss_current_hp, boss_max_hp)
	boss_time_remaining.emit(boss_time_remaining_sec)
	# Boss is a single entity targetable from any lane; spawned in lane 2 (center) for visuals only.
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.archetype = "worldboss"
	enemy.max_hp = boss_max_hp
	enemy.atk = int(boss_max_hp / 400.0)
	enemy.spd = 0 # boss doesn't approach; it stands and fights
	enemy_spawn_point.add_child(enemy)
	var center := int(_lanes.size() / 2)
	enemy.global_position = enemy_spawn_point.global_position
	for l in _lanes:
		l.register_enemy(enemy)
	enemy.died.connect(func(_e, _m): _on_boss_defeated())

func _physics_process(delta: float) -> void:
	if _paused or not _boss_active:
		return
	var scaled_delta := delta * _speed_multiplier
	boss_time_remaining_sec -= scaled_delta
	boss_time_remaining.emit(max(boss_time_remaining_sec, 0.0))
	if boss_time_remaining_sec <= 0.0:
		_boss_active = false
		_end_boss_battle_timeout()

func _on_boss_defeated() -> void:
	_boss_active = false
	_end_battle(true)

func _end_boss_battle_timeout() -> void:
	# Failure: no chest, but grant a small consolation reward proportional to damage dealt.
	var damage_dealt := boss_max_hp - boss_current_hp
	var consolation := int((float(damage_dealt) / float(boss_max_hp)) * config.reward_money * 0.5)
	GameState.add_money(consolation)
	battle_lost.emit()

# ---- Shared end-of-battle ----

func _end_battle(won: bool) -> void:
	if won:
		var three_star := took_no_fence_damage
		var money_mult := config.three_star_money_bonus_mult if three_star else 1.0
		GameState.add_money(int(config.reward_money * money_mult))
		if config.reward_material_id != "":
			GameState.add_material(config.reward_material_id, config.reward_material_amount)
		if randf() < config.reward_ball_chance:
			GameState.add_balls(1)
		if config.is_boss_fight:
			_open_world_boss_chest()
		battle_won.emit(three_star)
	else:
		battle_lost.emit()
	SaveSystem.save_game()

func _open_world_boss_chest() -> void:
	var roll := randf() * 100.0
	var cumulative := 0.0
	for entry in config.chest_table:
		cumulative += entry.weight
		if roll <= cumulative:
			match entry.type:
				"balls":
					GameState.add_balls(entry.amount)
				"money":
					GameState.add_money(entry.amount)
				"monster":
					var species: String = entry.species_id if entry.species_id != "" else config.boss_species_id
					if species != "":
						GameState.add_monster(species)
			return

# ---- Player controls ----

func set_speed_multiplier(mult: float) -> void:
	_speed_multiplier = mult
	Engine.time_scale = mult

func set_paused(paused: bool) -> void:
	_paused = paused
	get_tree().paused = paused

func trigger_monster_skill(lane_index: int) -> void:
	if lane_index < 0 or lane_index >= _battle_monsters.size():
		return
	_battle_monsters[lane_index].try_trigger_skill()

# NOTE ON WIRING: this script should be attached to the BattleArena.tscn root
# node, and other battle scripts (Enemy, Lane, BattleMonster) reference it via
# a scene-unique group or by walking up to the scene root cast to this type —
# e.g. `get_tree().get_first_node_in_group("battle_arena")`. Add this node to
# the "battle_arena" group in the editor, or in _ready(): add_to_group("battle_arena").
