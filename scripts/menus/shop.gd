extends Control

## Shop: Ball-cost summon pool (gacha) pulling from MonsterDB, plus a
## placeholder for real-money Money purchases (IAP wiring is store-specific
## and out of scope for this scaffold — see result_label note).

const SUMMON_BALL_COST := 5

@onready var result_label: Label = $ResultLabel
@onready var summon_button: Button = $SummonButton
@onready var back_button: Button = $BackButton
@onready var balls_label: Label = $BallsLabel

func _ready() -> void:
	summon_button.pressed.connect(_on_summon_pressed)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	GameState.currency_changed.connect(_refresh_balls_label)
	_refresh_balls_label()

func _refresh_balls_label() -> void:
	balls_label.text = "Balls: %d" % GameState.balls

func _on_summon_pressed() -> void:
	if not GameState.spend_balls(SUMMON_BALL_COST):
		result_label.text = "Not enough Balls (need %d)." % SUMMON_BALL_COST
		return
	# Simple weighted rarity roll; tune odds in one place here.
	var roll := randf()
	var rarity := "Common"
	if roll > 0.97:
		rarity = "Epic"
	elif roll > 0.80:
		rarity = "Rare"
	var species_id := MonsterDB.get_random_species_id(rarity)
	if species_id == "":
		species_id = MonsterDB.get_random_species_id("") # fallback if that rarity has no entries yet
	var m := GameState.add_monster(species_id)
	var data := m.get_data()
	result_label.text = "You got: %s (%s)!" % [data.get_stage_name(0) if data else species_id, rarity]
	SaveSystem.save_game()
