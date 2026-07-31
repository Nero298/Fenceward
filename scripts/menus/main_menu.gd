extends Control

## Splash/Main Menu. Loads save on boot, then routes to Squad Builder, Stage
## Select, Dungeon Select, World Boss (gated), Shop, or Settings.

func _ready() -> void:
	SaveSystem.load_game()

func _on_squad_builder_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/squad_builder.tscn")

func _on_stage_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/stage_select.tscn")

func _on_dungeon_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/dungeon_select.tscn")

func _on_world_boss_pressed() -> void:
	if GameState.squad_size() < 4:
		# Block entry per spec: World Boss requires >= 4 deployed monsters.
		$InsufficientSquadPopup.popup_centered()
		return
	get_tree().change_scene_to_file("res://scenes/menus/world_boss_select.tscn")

func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/shop.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/settings.tscn")
