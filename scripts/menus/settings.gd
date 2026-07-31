extends Control

@onready var back_button: Button = $BackButton
@onready var reset_button: Button = $ResetSaveButton
@onready var confirm_dialog: ConfirmationDialog = $ResetConfirmDialog

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	reset_button.pressed.connect(func(): confirm_dialog.popup_centered())
	confirm_dialog.confirmed.connect(_on_reset_confirmed)

func _on_reset_confirmed() -> void:
	SaveSystem.delete_save()
	get_tree().reload_current_scene()
