extends CanvasLayer

## Attach to the HUD node in battle_arena.tscn. Wires the top bar / bottom
## panel controls that were laid out in the scene to the BattleArena signals
## and GameState currency signals, and forwards monster-slot taps to
## BattleArena.trigger_monster_skill(lane_index).

@onready var wave_label: Label = $TopBar/WaveLabel
@onready var money_label: Label = $TopBar/MoneyLabel
@onready var balls_label: Label = $TopBar/BallsLabel
@onready var pause_button: Button = $TopBar/PauseButton
@onready var speed_button: Button = $TopBar/SpeedButton
@onready var monster_slots: Array[Button] = [
	$BottomPanel/MonsterSlot0, $BottomPanel/MonsterSlot1, $BottomPanel/MonsterSlot2,
	$BottomPanel/MonsterSlot3, $BottomPanel/MonsterSlot4
]

var _is_paused: bool = false
var _speed_is_2x: bool = false

func _ready() -> void:
	var arena := get_parent()
	arena.wave_changed.connect(_on_wave_changed)
	arena.fence_hp_changed.connect(_on_fence_hp_changed)
	GameState.currency_changed.connect(_refresh_currency)
	_refresh_currency()

	pause_button.pressed.connect(func():
		_is_paused = not _is_paused
		arena.set_paused(_is_paused)
		pause_button.text = "Resume" if _is_paused else "Pause"
	)
	speed_button.pressed.connect(func():
		_speed_is_2x = not _speed_is_2x
		arena.set_speed_multiplier(2.0 if _speed_is_2x else 1.0)
		speed_button.text = "2x" if _speed_is_2x else "1x"
	)
	for i in range(monster_slots.size()):
		var lane_idx := i
		monster_slots[i].pressed.connect(func(): arena.trigger_monster_skill(lane_idx))

func _refresh_currency() -> void:
	money_label.text = "Money: %d" % GameState.money
	balls_label.text = "Balls: %d" % GameState.balls

func _on_wave_changed(current: int, total: int) -> void:
	wave_label.text = "Wave %d/%d" % [current, total]

func _on_fence_hp_changed(current: int, max_hp: int) -> void:
	# Damage-state visual thresholds at ~66%/~33%, per the design spec's fence
	# cracking states. Hook actual sprite swaps here once fence art exists.
	pass
