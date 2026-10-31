class_name Respawn
extends Node
## Tracks the last reached checkpoint and respawns the player after death.

const DEFAULT_TUNING_PATH: String = "res://data/tuning.tres"

@export var player: Node3D
@export var tuning: TuningData

var active_checkpoint_id: StringName = &"start"

var _spawn_position: Vector3 = Vector3.ZERO
var _respawn_timer: float = -1.0


func _ready() -> void:
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as TuningData
	EventBus.checkpoint_reached.connect(_on_checkpoint_reached)
	EventBus.player_died.connect(_on_player_died)
	_acquire_player()
	if player != null:
		_spawn_position = player.global_position


func _process(delta: float) -> void:
	if _respawn_timer < 0.0:
		return
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		_respawn_timer = -1.0
		_perform_respawn()


func _on_checkpoint_reached(checkpoint_id: StringName) -> void:
	active_checkpoint_id = checkpoint_id
	for node: Node in get_tree().get_nodes_in_group(&"checkpoint"):
		if node is Node3D and node.get(&"checkpoint_id") == checkpoint_id:
			_spawn_position = (node as Node3D).global_position
			return


func _on_player_died(_reason: StringName) -> void:
	_respawn_timer = tuning.respawn_delay if tuning != null else 0.3


func _perform_respawn() -> void:
	if player == null:
		_acquire_player()
	if player != null and player.has_method(&"respawn_at"):
		player.call(&"respawn_at", _spawn_position)
	EventBus.player_respawned.emit(active_checkpoint_id)


func _acquire_player() -> void:
	var node: Node = get_tree().get_first_node_in_group(&"player")
	if node is Node3D:
		player = node as Node3D
