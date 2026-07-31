extends Resource
class_name WaveDefinition

## One wave's spawn table within a Stage/Dungeon.

@export var enemy_archetype: String = "walker" # walker, rusher, tank, ranged, miniboss
@export var count: int = 5
@export var spawn_interval_seconds: float = 1.2
@export var start_delay_seconds: float = 0.0

## Base enemy stats before difficulty scaling is applied by the stage number
@export var base_hp: int = 100
@export var base_atk: int = 15
@export var base_spd: int = 60
@export var base_money_drop: int = 5
