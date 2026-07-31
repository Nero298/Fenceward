extends Control

## World Boss Select: main_menu.gd already blocks entry below 4 deployed
## monsters. This screen shows the current boss config (scheduled window or
## daily-ticket gated — see config comments) and lets the player enter if a
## ticket/window is available.

const WORLD_BOSS_CONFIG_PATH := "res://resources/battle_configs/world_boss/current_boss.tres"

@onready var info_label: Label = $InfoLabel
@onready var enter_button: Button = $EnterButton
@onready var back_button: Button = $BackButton

var _config: BattleConfig

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	enter_button.pressed.connect(_on_enter_pressed)
	_load_config()

func _load_config() -> void:
	if not ResourceLoader.exists(WORLD_BOSS_CONFIG_PATH):
		info_label.text = "No World Boss configured yet.\nAdd a BattleConfig .tres at:\n%s" % WORLD_BOSS_CONFIG_PATH
		enter_button.disabled = true
		return
	_config = load(WORLD_BOSS_CONFIG_PATH)
	var tickets := GameState.world_boss_daily_tickets
	info_label.text = "%s\nTime limit: %.0fs\nDaily tickets remaining: %d" % [
		_config.display_name, _config.boss_time_limit_seconds, tickets
	]
	enter_button.disabled = tickets <= 0

func _on_enter_pressed() -> void:
	if GameState.world_boss_daily_tickets <= 0:
		return
	GameState.world_boss_daily_tickets -= 1
	var battle_scene: PackedScene = load("res://scenes/battle/battle_arena.tscn")
	var arena := battle_scene.instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = arena
	arena.start_battle(_config)
