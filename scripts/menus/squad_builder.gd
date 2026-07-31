extends Control

## Squad Builder: shows the player's Collection and lets them assign up to 5
## monsters into lane slots (GameState.squad_instance_ids). Simplified to
## tap-to-assign rather than true drag-and-drop for this scaffold — swap in
## Control drag/drop (get_drag_data / can_drop_data) later if desired.

@onready var collection_list: ItemList = $HBox/CollectionPanel/CollectionList
@onready var slot_buttons: Array[Button] = [
	$HBox/SquadPanel/Slots/Slot0, $HBox/SquadPanel/Slots/Slot1, $HBox/SquadPanel/Slots/Slot2,
	$HBox/SquadPanel/Slots/Slot3, $HBox/SquadPanel/Slots/Slot4
]
@onready var back_button: Button = $BackButton

var _selected_slot: int = -1

func _ready() -> void:
	_refresh_collection_list()
	_refresh_slots()
	for i in range(slot_buttons.size()):
		var idx := i
		slot_buttons[i].pressed.connect(func(): _select_slot(idx))
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	collection_list.item_selected.connect(_on_collection_item_selected)

func _refresh_collection_list() -> void:
	collection_list.clear()
	for m in GameState.collection:
		var data := m.get_data()
		var label := "%s Lv.%d" % [data.get_stage_name(m.evolution_stage) if data else m.species_id, m.level]
		collection_list.add_item(label)

func _refresh_slots() -> void:
	for i in range(slot_buttons.size()):
		var id := GameState.squad_instance_ids[i]
		if id == "":
			slot_buttons[i].text = "Empty Slot %d" % (i + 1)
		else:
			var m := GameState.find_instance(id)
			var data := m.get_data() if m else null
			slot_buttons[i].text = data.get_stage_name(m.evolution_stage) if data else id

func _select_slot(index: int) -> void:
	_selected_slot = index

func _on_collection_item_selected(index: int) -> void:
	if _selected_slot < 0:
		return
	var m := GameState.collection[index]
	GameState.set_squad_slot(_selected_slot, m.instance_id)
	_refresh_slots()
